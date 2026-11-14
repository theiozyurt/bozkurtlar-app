from copy import deepcopy
import json
from pathlib import Path
import tempfile
import threading
import unittest
from urllib.error import HTTPError
from urllib.request import Request, urlopen
from server import make_server

TOKEN = "test-token-only-01234567890123456789"


def sample():
    return {"id": "board:10:1", "device_id": "board", "source": "live", "received_at": "2026-11-14T12:00:00Z",
            "telemetry": {"v": 1, "boot": 10, "seq": 1, "raw": 820, "uptime_ms": 2000,
                          "on_ms": 1000, "critical_ms": 1200, "starts": 1, "pump": True,
                          "critical": True, "armed": True, "rising": True, "threshold_on": 700, "threshold_off": 650}}


class ArchiveTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.server = make_server("127.0.0.1", 0, Path(self.temp.name)/"archive.db", TOKEN)
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        self.base = f"http://127.0.0.1:{self.server.server_port}"

    def tearDown(self):
        self.server.shutdown(); self.server.server_close(); self.thread.join(); self.temp.cleanup()

    def call(self, path, payload=None, auth=True):
        req = Request(self.base+path, data=None if payload is None else json.dumps(payload).encode(),
                      headers={"Content-Type": "application/json", **({"Authorization": f"Bearer {TOKEN}"} if auth else {})})
        try:
            with urlopen(req, timeout=5) as response:
                return response.status, json.load(response)
        except HTTPError as error:
            with error:
                return error.code, json.load(error)

    def test_archive_is_idempotent_and_readable(self):
        payload = {"samples": [sample()]}
        self.assertEqual(self.call("/v1/samples", payload)[1]["inserted"], 1)
        self.assertEqual(self.call("/v1/samples", payload)[1]["inserted"], 0)
        code, body = self.call("/v1/samples")
        self.assertEqual(code, 200); self.assertEqual(body["total"], 1)
        self.assertEqual(body["samples"][0]["telemetry"]["raw"], 820)

    def test_rejects_unauthorized_reads_and_writes(self):
        self.assertEqual(self.call("/v1/samples", auth=False)[0], 401)
        self.assertEqual(self.call("/v1/samples", {"samples": [sample()]}, auth=False)[0], 401)

    def test_demo_batch_rejection_is_atomic(self):
        demo = deepcopy(sample()); demo["source"] = "demo"
        self.assertEqual(self.call("/v1/samples", {"samples": [sample(), demo]})[0], 400)
        self.assertEqual(self.call("/v1/samples")[1]["total"], 0)

    def test_rejects_invalid_measurements(self):
        for changes in ({"raw": 5000}, {"on_ms": 3000}, {"raw": True}, {"v": 3}, {"pump": "true"}):
            bad = sample(); bad["telemetry"].update(changes)
            self.assertEqual(self.call("/v1/samples", {"samples": [bad]})[0], 400)

    def test_public_health_is_available(self):
        self.assertEqual(self.call("/health", auth=False)[1]["status"], "ok")


if __name__ == "__main__":
    unittest.main()
