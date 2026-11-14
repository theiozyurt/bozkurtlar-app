import 'dart:async';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

final serviceId = Uuid.parse('6e400001-b5a3-f393-e0a9-e50e24dcca9e');
final txId = Uuid.parse('6e400003-b5a3-f393-e0a9-e50e24dcca9e');

class BleLink {
  FlutterReactiveBle? _ble;
  FlutterReactiveBle get ble => _ble ??= FlutterReactiveBle();
  StreamSubscription<DiscoveredDevice>? _scan;
  StreamSubscription<ConnectionStateUpdate>? _connection;
  StreamSubscription<List<int>>? _notification;
  Timer? _scanTimeout;
  int _generation = 0;

  Future<void> scan({
    required void Function(DiscoveredDevice) onDevice,
    required void Function(String) onError,
    required VoidCallback onDone,
  }) async {
    if (kIsWeb) {
      throw StateError(
        'Bluetooth bağlantısı Android/iPhone uygulamasında kullanılabilir. Tarayıcıda demo modunu deneyebilirsiniz.',
      );
    }
    await stopScan();
    var legacyAndroid = false;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
      legacyAndroid = sdk < 31;
      final permissions = legacyAndroid
          ? [Permission.locationWhenInUse]
          : [Permission.bluetoothScan, Permission.bluetoothConnect];
      final statuses = await permissions.request();
      if (statuses.values.any((s) => !s.isGranted)) {
        // Kalıcı reddedildiyse Android pencereyi bir daha göstermez; ayarları aç.
        if (statuses.values.any((s) => s.isPermanentlyDenied)) {
          unawaited(openAppSettings());
        }
        throw StateError(
          legacyAndroid
              ? 'Bluetooth taraması için Konum izni gerekli. Açılan ayarlardan Bozkurtlar için Konum iznini verin.'
              : 'Yakındaki cihazlar izni gerekli. Açılan ayarlardan Bozkurtlar için bu izni verin.',
        );
      }
    }
    // Önbellekteki duruma güvenme: izin/Bluetooth yeni açıldıysa durumun
    // "ready" olması birkaç saniye sürebilir.
    final status = await _awaitReady();
    if (status != BleStatus.ready) {
      throw StateError(_statusMessage(status, legacyAndroid));
    }
    _scan = ble
        .scanForDevices(
          withServices: [serviceId],
          scanMode: ScanMode.lowLatency,
        )
        .listen(
          onDevice,
          onError: (Object e) {
            onError('Cihaz taraması başarısız: $e');
            unawaited(stopScan());
            onDone();
          },
        );
    _scanTimeout = Timer(const Duration(seconds: 12), () {
      unawaited(stopScan());
      onDone();
    });
  }

  Future<BleStatus> _awaitReady() async {
    var last = ble.status;
    try {
      return await ble.statusStream
          .map((s) => last = s)
          .firstWhere((s) => s == BleStatus.ready)
          .timeout(const Duration(seconds: 8));
    } on TimeoutException {
      return last;
    }
  }

  String _statusMessage(BleStatus status, bool legacyAndroid) {
    switch (status) {
      case BleStatus.poweredOff:
        return 'Bluetooth kapalı görünüyor. Bluetooth’u açıp tekrar deneyin.';
      case BleStatus.locationServicesDisabled:
        return 'Telefonun Konum servisi kapalı. Bu Android sürümünde Bluetooth taraması için Konum’u (GPS) açmanız gerekiyor.';
      case BleStatus.unauthorized:
        return legacyAndroid
            ? 'Konum izni verilmemiş. Ayarlar → Uygulamalar → Bozkurtlar → İzinler’den Konum iznini açın.'
            : 'Yakındaki cihazlar izni verilmemiş. Ayarlar → Uygulamalar → Bozkurtlar → İzinler’den açın.';
      case BleStatus.unsupported:
        return 'Bu telefon Bluetooth Low Energy desteklemiyor.';
      default:
        return 'Bluetooth durumu okunamadı (${status.name}). Bluetooth’u kapatıp açarak tekrar deneyin.';
    }
  }

  Future<void> stopScan() async {
    _scanTimeout?.cancel();
    _scanTimeout = null;
    await _scan?.cancel();
    _scan = null;
  }

  Future<void> connect(
    String deviceId, {
    required void Function(List<int>) onBytes,
    required VoidCallback onConnected,
    required void Function(String?) onDisconnected,
  }) async {
    await disconnect();
    final generation = _generation;
    _connection = ble
        .connectToAdvertisingDevice(
          id: deviceId,
          withServices: [serviceId],
          prescanDuration: const Duration(seconds: 3),
          servicesWithCharacteristicsToDiscover: {
            serviceId: [txId],
          },
          connectionTimeout: const Duration(seconds: 12),
        )
        .listen(
          (update) async {
            if (generation != _generation) return;
            if (update.connectionState == DeviceConnectionState.connected) {
              final characteristic = QualifiedCharacteristic(
                serviceId: serviceId,
                characteristicId: txId,
                deviceId: deviceId,
              );
              await _notification?.cancel();
              if (generation != _generation) return;
              _notification = ble
                  .subscribeToCharacteristic(characteristic)
                  .listen(
                    onBytes,
                    onError: (Object e) {
                      if (generation == _generation) {
                        onDisconnected('Veri akışı kesildi: $e');
                        unawaited(disconnect());
                      }
                    },
                  );
              onConnected();
            } else if (update.connectionState ==
                DeviceConnectionState.disconnected) {
              final failure = update.failure;
              onDisconnected(
                failure == null
                    ? null
                    : 'Bluetooth bağlantısı kesildi: ${failure.message}',
              );
            }
          },
          onError: (Object e) {
            if (generation == _generation) {
              onDisconnected('Bağlantı kurulamadı: $e');
            }
          },
        );
  }

  Future<void> disconnect() async {
    _generation++;
    await stopScan();
    await _notification?.cancel();
    _notification = null;
    await _connection?.cancel();
    _connection = null;
  }
}
