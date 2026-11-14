import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:bozkurtlar/domain.dart';

Telemetry packet() => const Telemetry(
  boot: 97,
  seq: 1,
  raw: 820,
  uptimeMs: 120000,
  onMs: 60000,
  criticalMs: 65000,
  starts: 2,
  pump: true,
  critical: true,
  armed: true,
);

void main() {
  test('reassembles all 1–23 byte BLE notification sizes', () {
    final data = utf8.encode('${jsonEncode(packet().toJson())}\n');
    for (int chunk = 1; chunk <= 23; chunk++) {
      final decoder = FrameDecoder();
      final out = <Telemetry>[];
      for (int i = 0; i < data.length; i += chunk) {
        out.addAll(decoder.add(data.sublist(i, min(i + chunk, data.length))));
      }
      expect(out.single.raw, 820);
      expect(out.single.onMs, 60000);
      expect(decoder.rejected, 0);
    }
  });
  test('recovers after a malformed or oversized frame', () {
    final decoder = FrameDecoder();
    decoder.add(utf8.encode('${'x' * 5000}\n{bad}\n'));
    final out = decoder.add(utf8.encode('${jsonEncode(packet().toJson())}\n'));
    expect(out.single.seq, 1);
    expect(decoder.rejected, 2);
  });
  test('rejects impossible ADC readings and counter values', () {
    expect(
      () => Telemetry.fromJson({...packet().toJson(), 'raw': 4096}),
      throwsFormatException,
    );
    expect(
      () => Telemetry.fromJson({...packet().toJson(), 'on_ms': 120001}),
      throwsFormatException,
    );
    expect(
      () => Telemetry.fromJson({...packet().toJson(), 'pump': 1}),
      throwsFormatException,
    );
    expect(
      () => Telemetry.fromJson({...packet().toJson(), 'threshold_off': 800}),
      throwsFormatException,
    );
    expect(
      () => Telemetry.fromJson({...packet().toJson(), 'v': 9}),
      throwsFormatException,
    );
  });
  test('does not invent percentages or liters without calibration', () {
    const settings = AppSettings();
    expect(settings.percent(700), isNull);
    expect(settings.liters(60000), isNull);
  });
  test('supports reversed sensors and bounded percentages', () {
    const settings = AppSettings(
      dryRaw: 1000,
      wetRaw: 200,
      litersPerMinute: 1.5,
    );
    expect(settings.percent(600), 50);
    expect(settings.percent(100), 100);
    expect(settings.percent(1200), 0);
    expect(settings.liters(120000), 3);
  });
  test('keeps CSV sources explicit and UTC timestamps', () {
    final csv = samplesCsv([
      Sample(
        deviceId: 'test',
        source: 'demo',
        receivedAt: DateTime.utc(2026, 11, 14),
        telemetry: packet(),
      ),
    ]);
    expect(csv, contains('"demo"'));
    expect(csv, contains('2026-11-14T00:00:00.000Z'));
  });
  test('server token is not serialized to device preferences', () {
    expect(
      const AppSettings(apiToken: 'secret').toJson().toString(),
      isNot(contains('secret')),
    );
  });
}
