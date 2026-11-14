import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'domain.dart';

class LocalStore {
  final String? databasePath;
  LocalStore({this.databasePath});
  SharedPreferencesAsync? _preferences;
  SharedPreferencesAsync get _prefs =>
      _preferences ??= SharedPreferencesAsync();
  Database? _db;
  Future<void> open() async {
    if (kIsWeb) {
      return; // Browser is a demo/design preview, native stores SQLite.
    }
    _db = await openDatabase(
      databasePath ?? p.join(await getDatabasesPath(), 'bozkurtlar_v1.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE samples (id TEXT PRIMARY KEY, source TEXT NOT NULL, received_at TEXT NOT NULL, payload TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE INDEX samples_source_time ON samples(source, received_at)',
        );
      },
    );
  }

  Future<AppSettings> settings() async {
    final value = await _prefs.getString('settings_v1');
    try {
      return value == null
          ? const AppSettings()
          : AppSettings.fromJson(jsonDecode(value));
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) =>
      _prefs.setString('settings_v1', jsonEncode(settings.toJson()));
  Future<void> save(Sample sample) async {
    if (_db == null || sample.source != 'live') return;
    await _db!.insert('samples', {
      'id': sample.id,
      'source': sample.source,
      'received_at': sample.receivedAt.toUtc().toIso8601String(),
      'payload': jsonEncode(sample.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<Sample>> history({
    int limit = 3000,
    int offset = 0,
    DateTime? until,
  }) async {
    if (_db == null) return [];
    final rows = await _db!.query(
      'samples',
      where: until == null ? 'source = ?' : 'source = ? AND received_at <= ?',
      whereArgs: ['live', if (until != null) until.toUtc().toIso8601String()],
      orderBy: 'received_at DESC',
      limit: limit,
      offset: offset,
    );
    return rows
        .map((r) => Sample.fromJson(jsonDecode(r['payload'] as String)))
        .toList()
        .reversed
        .toList();
  }

  Future<int> count() async {
    if (_db == null) return 0;
    return Sqflite.firstIntValue(
          await _db!.rawQuery('SELECT COUNT(*) FROM samples WHERE source = ?', [
            'live',
          ]),
        ) ??
        0;
  }

  Future<List<Sample>> allLive() async {
    if (_db == null) return [];
    final rows = await _db!.query(
      'samples',
      where: 'source = ?',
      whereArgs: ['live'],
      orderBy: 'received_at ASC',
    );
    return rows
        .map((r) => Sample.fromJson(jsonDecode(r['payload'] as String)))
        .toList();
  }

  Future<void> close() async => _db?.close();
}
