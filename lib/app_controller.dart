import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'ble_link.dart';
import 'domain.dart';
import 'storage.dart';

class AppController extends ChangeNotifier {
  final LocalStore store;
  final BleLink link;
  AppController({LocalStore? store, BleLink? link})
    : store = store ?? LocalStore(),
      link = link ?? BleLink();
  AppSettings settings = const AppSettings();
  List<Sample> samples = [];
  List<Sample> _liveHistory = [];
  List<Map<String, dynamic>> research = [];
  final devices = <String, DiscoveredDevice>{};
  final decoder = FrameDecoder();
  bool ready = false,
      demo = false,
      connected = false,
      connecting = false,
      scanning = false,
      syncing = false;
  String? deviceId, message;
  int storedCount = 0;
  Timer? _clock, _demoTimer;
  int _demoTick = 0, _demoOn = 0, _demoCritical = 0, _demoStarts = 0;
  bool _demoPump = false;
  Future<void> _writes = Future.value();
  bool _disposed = false;
  int _modeGeneration = 0;
  Sample? get latest => samples.isEmpty ? null : samples.last;
  bool get stale =>
      !demo &&
      (!connected ||
          latest == null ||
          DateTime.now().difference(latest!.receivedAt).inSeconds > 5);
  AppSettings get effectiveSettings => demo
      ? const AppSettings(dryRaw: 300, wetRaw: 1100, litersPerMinute: 1.5)
      : settings;

  Future<void> initialize() async {
    try {
      await store.open();
      settings = await store.settings();
      _liveHistory = await store.history();
      samples = List.of(_liveHistory);
      storedCount = await store.count();
      final content = await rootBundle.loadString('assets/research.json');
      research = (jsonDecode(content) as List).cast<Map<String, dynamic>>();
    } catch (e) {
      message = 'Yerel kayıt açılamadı: $e';
    }
    ready = true;
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => _changed());
    _changed();
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  void dismissMessage() {
    message = null;
    _changed();
  }

  Future<void> scan() async {
    if (scanning || connecting) return;
    message = null;
    devices.clear();
    scanning = true;
    _changed();
    try {
      await link.scan(
        onDevice: (device) {
          devices[device.id] = device;
          _changed();
        },
        onError: (error) {
          message = error;
          scanning = false;
          _changed();
        },
        onDone: () {
          scanning = false;
          _changed();
        },
      );
    } catch (e) {
      scanning = false;
      message = e.toString().replaceFirst('Bad state: ', '');
      _changed();
    }
  }

  Future<void> connect(DiscoveredDevice device) async {
    _modeGeneration++;
    await link.stopScan();
    scanning = false;
    connecting = true;
    connected = false;
    _demoTimer?.cancel();
    demo = false;
    samples = [];
    decoder.reset();
    deviceId = device.id;
    message = null;
    _changed();
    try {
      await link.connect(
        device.id,
        onBytes: _receive,
        onConnected: () {
          connecting = false;
          connected = true;
          _changed();
        },
        onDisconnected: (error) {
          connecting = false;
          connected = false;
          message = error ?? 'Kart bağlantısı kesildi. Son ölçüm saklandı.';
          _changed();
        },
      );
    } catch (e) {
      connecting = false;
      connected = false;
      message = 'Bağlantı kurulamadı: $e';
      _changed();
    }
  }

  void _receive(List<int> bytes) {
    final generation = _modeGeneration;
    for (final packet in decoder.add(bytes)) {
      final previous = latest;
      if (previous != null &&
          previous.telemetry.boot == packet.boot &&
          packet.seq <= previous.telemetry.seq) {
        continue;
      }
      final sample = Sample(
        deviceId: deviceId!,
        source: 'live',
        receivedAt: DateTime.now(),
        telemetry: packet,
      );
      samples.add(sample);
      _liveHistory.add(sample);
      if (samples.length > 3000) samples.removeAt(0);
      if (_liveHistory.length > 3000) _liveHistory.removeAt(0);
      _writes = _writes
          .then((_) async {
            await store.save(sample);
            storedCount = await store.count();
          })
          .catchError((Object e) {
            if (generation == _modeGeneration) {
              message = 'Ölçüm kaydedilemedi: $e';
            }
          });
    }
    _changed();
  }

  Future<void> disconnect() async {
    _modeGeneration++;
    await link.disconnect();
    connecting = false;
    scanning = false;
    connected = false;
    _changed();
  }

  Future<void> startDemo({DateTime? at}) async {
    await disconnect();
    _demoTimer?.cancel();
    demo = true;
    message = null;
    samples = [];
    _demoTick = 0;
    _demoOn = 0;
    _demoCritical = 0;
    _demoStarts = 0;
    _demoPump = false;
    final now = at ?? DateTime.now();
    for (int i = 0; i < 96; i++) {
      _addDemo(now.subtract(Duration(seconds: (95 - i) * 15)), 15000);
    }
    _demoTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _addDemo(DateTime.now(), 1000);
      _changed();
    });
    _changed();
  }

  void _addDemo(DateTime at, int stepMs) {
    final raw = (735 + 260 * sin(_demoTick / 9) + 32 * sin(_demoTick / 2.7))
        .round();
    final wasOn = _demoPump;
    if (!_demoPump && raw >= 700) _demoPump = true;
    if (_demoPump && raw <= 650) _demoPump = false;
    if (_demoPump && !wasOn) _demoStarts++;
    if (_demoPump) _demoOn += stepMs;
    if (raw >= 700) _demoCritical += stepMs;
    final uptime = (_demoTick < 96
        ? (_demoTick + 1) * 15000
        : 1440000 + (_demoTick - 95) * 1000);
    samples.add(
      Sample(
        deviceId: 'BOZKURTLAR-DEMO',
        source: 'demo',
        receivedAt: at,
        telemetry: Telemetry(
          boot: 100,
          seq: _demoTick,
          raw: raw,
          uptimeMs: uptime,
          onMs: _demoOn,
          criticalMs: _demoCritical,
          starts: _demoStarts,
          pump: _demoPump,
          critical: raw >= 700,
          armed: true,
        ),
      ),
    );
    _demoTick++;
    if (samples.length > 3000) samples.removeAt(0);
  }

  void stopDemo() {
    _demoTimer?.cancel();
    demo = false;
    samples = List.of(_liveHistory);
    message = null;
    _changed();
  }

  Future<void> saveSettings(AppSettings value) async {
    await store.saveSettings(value);
    settings = value;
    message = 'Ayarlar telefona kaydedildi. Kartın pompa eşikleri değişmedi.';
    _changed();
  }

  Future<void> exportCsv() async {
    try {
      await _writes;
      final rows = demo ? samples : await store.allLive();
      if (rows.isEmpty) {
        message = 'Dışa aktarılacak kayıt yok.';
        _changed();
        return;
      }
      final filename =
          'bozkurtlar-${demo ? 'DEMO' : 'olcum'}-${DateTime.now().millisecondsSinceEpoch}.csv';
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              Uint8List.fromList(utf8.encode('\uFEFF${samplesCsv(rows)}')),
              mimeType: 'text/csv',
              name: filename,
            ),
          ],
          fileNameOverrides: [filename],
          title: 'Bozkurtlar ölçüm kayıtları',
        ),
      );
    } catch (e) {
      message = 'CSV paylaşılamadı: $e';
      _changed();
    }
  }

  Future<void> sync() async {
    if (syncing) return;
    if (demo) {
      message = 'Demo verileri sunucuya gönderilmez.';
      _changed();
      return;
    }
    final uri = Uri.tryParse(settings.apiUrl.trim());
    final local =
        uri != null &&
        ['localhost', '127.0.0.1', '10.0.2.2'].contains(uri.host);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.userInfo.isNotEmpty ||
        (uri.scheme != 'https' &&
            !(kDebugMode && local && uri.scheme == 'http'))) {
      message =
          'Ayarlar ekranına HTTPS sunucu adresi girin. Yerel HTTP yalnızca geliştirmede desteklenir.';
      _changed();
      return;
    }
    if (settings.apiToken.trim().isEmpty) {
      message = 'Bu oturum için sunucu erişim anahtarını girin.';
      _changed();
      return;
    }
    syncing = true;
    _changed();
    try {
      await _writes;
      final rows = await store.allLive();
      if (rows.isEmpty) {
        message = 'Gönderilecek gerçek ölçüm yok.';
        return;
      }
      for (var i = 0; i < rows.length; i += 250) {
        final response = await http
            .post(
              uri.resolve('/v1/samples'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ${settings.apiToken}',
              },
              body: jsonEncode({
                'samples': rows
                    .sublist(i, min(i + 250, rows.length))
                    .map((s) => s.toJson())
                    .toList(),
              }),
            )
            .timeout(const Duration(seconds: 15));
        if (response.statusCode != 200) {
          throw StateError('Sunucu yanıtı: ${response.statusCode}');
        }
      }
      message =
          '${rows.length} kayıt arşivle eşitlendi. Yinelenen kayıtlar bir kez tutulur.';
    } catch (e) {
      message = 'Arşive ulaşılamadı. Telefonda kayıtlarınız duruyor. $e';
    } finally {
      syncing = false;
      _changed();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _clock?.cancel();
    _demoTimer?.cancel();
    unawaited(link.disconnect());
    unawaited(_writes.whenComplete(store.close));
    super.dispose();
  }
}
