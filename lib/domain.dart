import 'dart:convert';

/// Same newline-delimited protocol as firmware/bozkurtlar/bozkurtlar.ino.
class Telemetry {
  final int boot,
      seq,
      raw,
      uptimeMs,
      onMs,
      criticalMs,
      starts,
      thresholdOn,
      thresholdOff;
  final bool pump, critical, armed, rising;
  const Telemetry({
    required this.boot,
    required this.seq,
    required this.raw,
    required this.uptimeMs,
    required this.onMs,
    required this.criticalMs,
    required this.starts,
    required this.pump,
    required this.critical,
    required this.armed,
    this.thresholdOn = 700,
    this.thresholdOff = 650,
    this.rising = true,
  });

  factory Telemetry.fromJson(Map<String, dynamic> j) {
    int integer(String key, int max) {
      final value = j[key];
      if (value is! int || value < 0 || value > max) {
        throw FormatException('Geçersiz alan: $key');
      }
      return value;
    }

    bool boolean(String key) {
      if (j[key] is! bool) throw FormatException('Geçersiz alan: $key');
      return j[key] as bool;
    }

    if (j['v'] != 1) throw const FormatException('Desteklenmeyen protokol');
    final uptime = integer('uptime_ms', 9007199254740991);
    final on = integer('on_ms', uptime);
    final critical = integer('critical_ms', uptime);
    final rising = boolean('rising');
    final thresholdOn = integer('threshold_on', 4095);
    final thresholdOff = integer('threshold_off', 4095);
    if ((rising && thresholdOff >= thresholdOn) ||
        (!rising && thresholdOff <= thresholdOn)) {
      throw const FormatException('Geçersiz eşik sırası');
    }
    return Telemetry(
      boot: integer('boot', 4294967295),
      seq: integer('seq', 4294967295),
      raw: integer('raw', 4095),
      uptimeMs: uptime,
      onMs: on,
      criticalMs: critical,
      starts: integer('starts', 4294967295),
      pump: boolean('pump'),
      critical: boolean('critical'),
      armed: boolean('armed'),
      rising: rising,
      thresholdOn: thresholdOn,
      thresholdOff: thresholdOff,
    );
  }
  /// Kartın röle yönü ters: kartın "pump" bildirdiği an pompa aslında kapalı.
  /// Karttan gelen canlı veride komutu ve açık kalma süresini ters çevirir.
  Telemetry pumpInverted() => Telemetry(
    boot: boot,
    seq: seq,
    raw: raw,
    uptimeMs: uptimeMs,
    onMs: uptimeMs - onMs,
    criticalMs: criticalMs,
    starts: starts,
    pump: !pump,
    critical: critical,
    armed: armed,
    rising: rising,
    thresholdOn: thresholdOn,
    thresholdOff: thresholdOff,
  );

  Map<String, dynamic> toJson() => {
    'v': 1,
    'boot': boot,
    'seq': seq,
    'raw': raw,
    'uptime_ms': uptimeMs,
    'on_ms': onMs,
    'critical_ms': criticalMs,
    'starts': starts,
    'pump': pump,
    'critical': critical,
    'armed': armed,
    'rising': rising,
    'threshold_on': thresholdOn,
    'threshold_off': thresholdOff,
  };
}

/// BLE notifications may split JSON anywhere, including UTF-8 boundaries.
class FrameDecoder {
  final List<int> _buffer = [];
  bool _discarding = false;
  int rejected = 0;
  List<Telemetry> add(List<int> bytes) {
    final result = <Telemetry>[];
    for (final byte in bytes) {
      if (byte == 10) {
        if (!_discarding && _buffer.isNotEmpty) {
          try {
            result.add(
              Telemetry.fromJson(
                jsonDecode(utf8.decode(_buffer)) as Map<String, dynamic>,
              ).pumpInverted(),
            );
          } catch (_) {
            rejected++;
          }
        }
        _buffer.clear();
        _discarding = false;
      } else if (!_discarding) {
        _buffer.add(byte);
        if (_buffer.length > 4096) {
          rejected++;
          _buffer.clear();
          _discarding = true;
        }
      }
    }
    return result;
  }

  void reset() {
    _buffer.clear();
    _discarding = false;
  }
}

class Sample {
  final String deviceId, source;
  final DateTime receivedAt;
  final Telemetry telemetry;
  const Sample({
    required this.deviceId,
    required this.source,
    required this.receivedAt,
    required this.telemetry,
  });
  String get id => '$deviceId:${telemetry.boot}:${telemetry.seq}';
  Map<String, dynamic> toJson() => {
    'id': id,
    'device_id': deviceId,
    'source': source,
    'received_at': receivedAt.toUtc().toIso8601String(),
    'telemetry': telemetry.toJson(),
  };
  factory Sample.fromJson(Map<String, dynamic> j) => Sample(
    deviceId: j['device_id'] as String,
    source: j['source'] as String,
    receivedAt: DateTime.parse(j['received_at'] as String),
    telemetry: Telemetry.fromJson(j['telemetry'] as Map<String, dynamic>),
  );
}

class AppSettings {
  final int? dryRaw, wetRaw;
  final double? litersPerMinute;
  final String apiUrl, apiToken;
  const AppSettings({
    this.dryRaw,
    this.wetRaw,
    this.litersPerMinute,
    this.apiUrl = '',
    this.apiToken = '',
  });
  bool get calibrated => dryRaw != null && wetRaw != null && dryRaw != wetRaw;
  double? percent(int raw) => calibrated
      ? (((raw - dryRaw!) / (wetRaw! - dryRaw!)) * 100).clamp(0.0, 100.0)
      : null;
  double? liters(int onMs) =>
      litersPerMinute == null ? null : onMs / 60000 * litersPerMinute!;
  Map<String, dynamic> toJson() => {
    'dry': dryRaw,
    'wet': wetRaw,
    'flow': litersPerMinute,
    'api_url': apiUrl,
  };
  // API credentials are session-only and deliberately not written to preferences.
  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
    dryRaw: j['dry'] as int?,
    wetRaw: j['wet'] as int?,
    litersPerMinute: (j['flow'] as num?)?.toDouble(),
    apiUrl: j['api_url'] as String? ?? '',
  );
}

String durationText(int ms) {
  final seconds = ms ~/ 1000;
  if (seconds < 60) return '$seconds sn';
  if (seconds < 3600) return '${seconds ~/ 60} dk ${seconds % 60} sn';
  return '${seconds ~/ 3600} sa ${(seconds % 3600) ~/ 60} dk';
}

String samplesCsv(List<Sample> samples) {
  String cell(Object value) => '"${value.toString().replaceAll('"', '""')}"';
  return [
    'source,device_id,boot,seq,received_at_utc,raw,pump_command,critical,armed,uptime_ms,pump_on_ms,critical_ms,starts',
    ...samples.map(
      (s) => [
        s.source,
        s.deviceId,
        s.telemetry.boot,
        s.telemetry.seq,
        s.receivedAt.toUtc().toIso8601String(),
        s.telemetry.raw,
        s.telemetry.pump,
        s.telemetry.critical,
        s.telemetry.armed,
        s.telemetry.uptimeMs,
        s.telemetry.onMs,
        s.telemetry.criticalMs,
        s.telemetry.starts,
      ].map(cell).join(','),
    ),
  ].join('\n');
}
