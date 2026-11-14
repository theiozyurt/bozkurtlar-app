"""Optional local archive. Python 3.10+, standard library only. No pump control."""
import argparse
from datetime import datetime
import hmac
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os
from pathlib import Path
import sqlite3
from urllib.parse import parse_qs, urlparse

MAX_BODY = 1_048_576


def validate_sample(sample):
    if not isinstance(sample, dict) or sample.get("source") != "live":
        raise ValueError("Only live samples are accepted")
    device = sample.get("device_id")
    if not isinstance(device, str) or not 1 <= len(device) <= 160:
        raise ValueError("Invalid device_id")
    at = sample.get("received_at")
    if not isinstance(at, str) or len(at) > 50:
        raise ValueError("Invalid received_at")
    parsed = datetime.fromisoformat(at.replace("Z", "+00:00"))
    if parsed.tzinfo is None:
        raise ValueError("received_at requires a timezone")
    telemetry = sample.get("telemetry")
    if not isinstance(telemetry, dict) or type(telemetry.get("v")) is not int or telemetry["v"] != 1:
        raise ValueError("Unsupported protocol")
    for key, maximum in [("boot", 2**32-1), ("seq", 2**32-1), ("raw", 4095),
                         ("uptime_ms", 2**53-1), ("on_ms", 2**53-1),
                         ("critical_ms", 2**53-1), ("starts", 2**32-1),
                         ("threshold_on", 4095), ("threshold_off", 4095)]:
        value = telemetry.get(key)
        if type(value) is not int or not 0 <= value <= maximum:
            raise ValueError(f"Invalid {key}")
    for key in ("pump", "critical", "armed", "rising"):
        if type(telemetry.get(key)) is not bool:
            raise ValueError(f"Invalid {key}")
    if max(telemetry["on_ms"], telemetry["critical_ms"]) > telemetry["uptime_ms"]:
        raise ValueError("Counters exceed uptime")
    if telemetry["rising"] and telemetry["threshold_off"] >= telemetry["threshold_on"]:
        raise ValueError("Invalid hysteresis")
    if not telemetry["rising"] and telemetry["threshold_off"] <= telemetry["threshold_on"]:
        raise ValueError("Invalid hysteresis")
    expected_id = f'{device}:{telemetry["boot"]}:{telemetry["seq"]}'
    if sample.get("id") != expected_id:
        raise ValueError("Invalid sample identity")
    return {"id": expected_id, "source": "live", "device_id": device,
            "received_at": parsed.isoformat(), "telemetry": telemetry}


def make_server(host, port, database, token):
    if len(token) < 24:
        raise ValueError("BOZKURTLAR_API_TOKEN must contain at least 24 characters")
    database = str(database)
    with sqlite3.connect(database) as db:
        db.execute("PRAGMA journal_mode=WAL")
        db.execute("CREATE TABLE IF NOT EXISTS samples (id TEXT PRIMARY KEY, device_id TEXT NOT NULL, received_at TEXT NOT NULL, payload TEXT NOT NULL)")
        db.execute("CREATE INDEX IF NOT EXISTS samples_time ON samples(received_at)")

    class Handler(BaseHTTPRequestHandler):
        server_version = "BozkurtlarArchive/1"

        def send_json(self, status, payload):
            data = json.dumps(payload, ensure_ascii=False, allow_nan=False).encode()
            self.send_response(status)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Cache-Control", "no-store")
            self.send_header("X-Content-Type-Options", "nosniff")
            self.end_headers()
            self.wfile.write(data)

        def authorized(self):
            supplied = self.headers.get("Authorization", "")
            if not hmac.compare_digest(supplied.encode(), f"Bearer {token}".encode()):
                self.send_json(401, {"error": "Unauthorized"})
                return False
            return True

        def do_GET(self):
            route = urlparse(self.path)
            if route.path == "/health":
                self.send_json(200, {"status": "ok", "version": 1})
                return
            if not self.authorized():
                return
            if route.path == "/v1/research":
                source = Path(__file__).parent.parent / "assets/research.json"
                self.send_json(200, json.loads(source.read_text()))
            elif route.path == "/v1/samples":
                try:
                    query = parse_qs(route.query)
                    limit = min(500, max(1, int(query.get("limit", [100])[0])))
                    offset = max(0, int(query.get("offset", [0])[0]))
                except ValueError:
                    self.send_json(400, {"error": "Invalid pagination"})
                    return
                with sqlite3.connect(database) as db:
                    rows = db.execute("SELECT payload FROM samples ORDER BY received_at, id LIMIT ? OFFSET ?", (limit, offset)).fetchall()
                    count = db.execute("SELECT count(*) FROM samples").fetchone()[0]
                self.send_json(200, {"total": count, "samples": [json.loads(r[0]) for r in rows]})
            else:
                self.send_json(404, {"error": "Not found"})

        def do_POST(self):
            if not self.authorized():
                return
            if urlparse(self.path).path != "/v1/samples":
                self.send_json(404, {"error": "Not found"})
                return
            try:
                length = int(self.headers.get("Content-Length", "0"))
                if not 0 < length <= MAX_BODY:
                    self.send_json(413, {"error": "Invalid body size"})
                    return
                self.connection.settimeout(10)
                if self.headers.get_content_type() != "application/json":
                    self.send_json(415, {"error": "application/json required"})
                    return
                payload = json.loads(self.rfile.read(length))
                if not isinstance(payload, dict):
                    raise ValueError("Object required")
                batch = payload.get("samples")
                if not isinstance(batch, list) or not 1 <= len(batch) <= 500:
                    raise ValueError("Batch must contain 1–500 samples")
                rows = [validate_sample(s) for s in batch]
                with sqlite3.connect(database) as db:
                    before = db.total_changes
                    db.executemany("INSERT OR IGNORE INTO samples VALUES (?, ?, ?, ?)",
                                   [(s["id"], s["device_id"], s["received_at"], json.dumps(s, allow_nan=False)) for s in rows])
                    inserted = db.total_changes - before
                self.send_json(200, {"accepted": len(rows), "inserted": inserted, "duplicates": len(rows)-inserted})
            except (ValueError, TypeError, UnicodeDecodeError):
                self.send_json(400, {"error": "Invalid sample batch"})
            except TimeoutError:
                self.send_json(408, {"error": "Request timed out"})

    return ThreadingHTTPServer((host, port), Handler)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8080)
    parser.add_argument("--database", default=str(Path(__file__).with_name("archive.sqlite3")))
    args = parser.parse_args()
    server = make_server(args.host, args.port, args.database, os.environ.get("BOZKURTLAR_API_TOKEN", ""))
    print(f"Bozkurtlar archive: http://{args.host}:{args.port}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
