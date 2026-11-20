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
  Future<void> setManualPumpCommand(String deviceId, bool active) async {
    final ref = _db.ref('devices/$deviceId/control/pump_manual_command');
    await ref.set(active);
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
            'last_started': now - 3600000,
            'last_duration_sec': 15,
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
