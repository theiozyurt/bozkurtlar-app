import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bozkurtlar/domain.dart';
import 'package:bozkurtlar/storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  test(
    'live history survives closing and reopening the device database',
    () async {
      final dir = await Directory.systemTemp.createTemp('bozkurtlar-storage-');
      final path = '${dir.path}/history.sqlite3';
      final sample = Sample(
        deviceId: 'board-1',
        source: 'live',
        receivedAt: DateTime.utc(2026, 11, 14),
        telemetry: const Telemetry(
          boot: 10,
          seq: 1,
          raw: 800,
          uptimeMs: 2000,
          onMs: 1000,
          criticalMs: 1000,
          starts: 1,
          pump: true,
          critical: true,
          armed: true,
        ),
      );
      final first = LocalStore(databasePath: path);
      await first.open();
      await first.save(sample);
      await first.save(sample); // Replay must not duplicate a measurement.
      await first.save(
        Sample(
          deviceId: 'demo',
          source: 'demo',
          receivedAt: sample.receivedAt,
          telemetry: sample.telemetry,
        ),
      );
      expect(await first.count(), 1);
      await first.close();
      final second = LocalStore(databasePath: path);
      await second.open();
      final rows = await second.history();
      expect(rows.single.telemetry.raw, 800);
      expect(rows.single.receivedAt, sample.receivedAt);
      expect(rows.single.source, 'live');
      // A restarted board has a new boot ID; sequence one is a new measurement.
      await second.save(
        Sample(
          deviceId: 'board-1',
          source: 'live',
          receivedAt: sample.receivedAt.add(const Duration(seconds: 1)),
          telemetry: const Telemetry(
            boot: 11,
            seq: 1,
            raw: 300,
            uptimeMs: 1000,
            onMs: 0,
            criticalMs: 0,
            starts: 0,
            pump: false,
            critical: false,
            armed: true,
          ),
        ),
      );
      expect(await second.count(), 2);
      expect(
        (await second.history(limit: 1, offset: 1)).single.telemetry.boot,
        10,
      );
      expect((await second.allLive()).length, 2);
      await second.close();
      await dir.delete(recursive: true);
    },
  );
}
