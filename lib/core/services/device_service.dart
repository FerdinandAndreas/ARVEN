import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../../models/device_data_model.dart';

class DeviceService {
  static const String rtdbUrl = 'https://arven-iot-default-rtdb.asia-southeast1.firebasedatabase.app';

  late final FirebaseDatabase _db;

  DeviceService() {
    _db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: rtdbUrl,
    );

    // Aktifkan cache offline lokal di disk HP agar saat dibuka langsung instan (0 detik)
    if (!kIsWeb) {
      try {
        _db.setPersistenceEnabled(true);
        _db.setPersistenceCacheSizeBytes(10000000); // Cache lokal 10 MB
      } catch (_) {}
    }
  }

  // Stream data perangkat secara real-time
  Stream<DeviceData> streamDevice(String deviceId) {
    final ref = _db.ref('devices/$deviceId');
    if (!kIsWeb) {
      try {
        ref.keepSynced(true); // Selalu sinkronkan cache lokal secara otomatis
      } catch (_) {}
    }

    return ref.onValue.map((event) {
      final value = event.snapshot.value;
      if (value is Map<dynamic, dynamic>) {
        return DeviceData.fromMap(deviceId, value);
      }
      return DeviceData.fromMap(deviceId, null);
    });
  }

  // Mengubah mode penyiraman ('manual', 'auto_moisture', 'scheduled')
  Future<void> setWateringMode(String deviceId, String mode) async {
    final ref = _db.ref('devices/$deviceId/control/mode');
    await ref.set(mode);
  }

  // Mengubah status sakelar pompa manual (true = ON, false = OFF)
  Future<void> setManualPumpCommand(String deviceId, bool active, {int durationSec = 0, double currentSoil = 0.0}) async {
    final ref = _db.ref('devices/$deviceId');
    final updates = <String, dynamic>{
      'control/pump_manual_command': active,
      'pump_state/active': active,
    };
    if (!active) {
      updates['pump_state/last_duration_sec'] = durationSec;
      // Jika pompa dimatikan setelah berjalan > 0 detik, catat riwayat manual ke Firebase
      if (durationSec > 0) {
        final double waterLiters = durationSec * (600.0 / 3600.0);
        final historyRef = _db.ref('devices/$deviceId/history').push();
        await historyRef.set({
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'title': 'Penyiraman Manual',
          'mode': 'manual',
          'duration_sec': durationSec,
          'water_liters': double.parse(waterLiters.toStringAsFixed(2)),
          'soil_before': currentSoil,
          'soil_after': currentSoil,
          'status': 'Dihentikan Manual',
        });
      }
    } else {
      updates['pump_state/last_started'] = DateTime.now().millisecondsSinceEpoch;
    }
    await ref.update(updates);
  }

  // Stream riwayat penyiraman (terbaru di atas)
  Stream<List<IrrigationHistoryItem>> streamHistory(String deviceId) {
    final ref = _db.ref('devices/$deviceId/history');
    return ref.limitToLast(50).onValue.map((event) {
      final value = event.snapshot.value;
      if (value is Map<dynamic, dynamic>) {
        final list = <IrrigationHistoryItem>[];
        value.forEach((key, val) {
          if (val is Map<dynamic, dynamic>) {
            list.add(IrrigationHistoryItem.fromMap(key.toString(), val));
          }
        });
        list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return list;
      }
      return <IrrigationHistoryItem>[];
    });
  }

  // Catat riwayat penyiraman baru ke Firebase
  Future<void> logIrrigationHistory(String deviceId, IrrigationHistoryItem item) async {
    final ref = _db.ref('devices/$deviceId/history').push();
    await ref.set(item.toMap());
  }

  // Paksa reset status pompa ke OFF di Firebase Realtime Database
  Future<void> resetPumpToOff(String deviceId) async {
    final ref = _db.ref('devices/$deviceId');
    await ref.update({
      'control/pump_manual_command': false,
      'pump_state/active': false,
      'pump_state/last_duration_sec': 0,
      'pump_state/last_started': 0,
    });
  }

  // Reset total seluruh statistik & bersihkan data riwayat di Firebase
  Future<void> resetAllDeviceStatistics(String deviceId) async {
    final ref = _db.ref('devices/$deviceId');
    await ref.update({
      'pump_state/active': false,
      'pump_state/last_started': 0,
      'pump_state/last_duration_sec': 0,
      'control/pump_manual_command': false,
      'history': null,
    });
  }

  // Memperbarui pengaturan sistem (ambang kelembapan, durasi, jeda, jadwal)
  Future<void> updateSettings(String deviceId, DeviceSettings settings) async {
    final ref = _db.ref('devices/$deviceId/settings');
    await ref.update(settings.toMap());
  }

  // Menginisialisasi data awal di Realtime Database jika node masih kosong
  Future<void> seedInitialDataIfEmpty(String deviceId) async {
    try {
      final ref = _db.ref('devices/$deviceId');
      final snapshot = await ref.get().timeout(const Duration(seconds: 3));
      if (!snapshot.exists) {
        final now = DateTime.now().millisecondsSinceEpoch;
        await ref.set({
          'status': {
            'online': true,
            'last_seen': now,
          },
          'sensors': {
            'soil_moisture': 42.0,
            'temperature': 28.5,
            'humidity': 65.0,
            'rain': false,
            'updated_at': now,
          },
          'control': {
            'mode': 'auto_moisture',
            'pump_manual_command': false,
          },
          'pump_state': {
            'active': false,
            'current_mode': 'auto_moisture',
            'last_started': 0,
            'last_duration_sec': 0,
          },
          'settings': {
            'moisture_threshold': 40,
            'moisture_threshold_max': 85,
            'watering_duration_sec': 15,
            'soak_interval_min': 20,
            'max_temperature_limit': 35.0,
            'rain_delay_enabled': true,
            'manual_safety_timeout_min': 5,
            'schedule': {
              'frequency': 2,
              'time_1': '07:00',
              'time_2': '16:30',
              'time_3': '12:00',
              'duration_sec': 20,
            },
          },
        });
      }
    } catch (_) {}
  }
}
