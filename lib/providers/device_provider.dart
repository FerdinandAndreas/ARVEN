import 'dart:async';
import 'package:flutter/material.dart';
import '../core/services/device_service.dart';
import '../models/device_data_model.dart';

class DeviceProvider extends ChangeNotifier {
  final DeviceService _deviceService = DeviceService();
  final String deviceId = 'arven_device_01';

  late DeviceData _deviceData;
  StreamSubscription<DeviceData>? _subscription;
  bool _isSyncing = true;
  String? _errorMessage;

  DeviceData get deviceData => _deviceData;
  bool get isSyncing => _isSyncing;
  String? get errorMessage => _errorMessage;

  DeviceProvider() {
    // Inisialisasi data langsung agar Dashboard tidak pernah blank / loading lama saat dibuka
    _deviceData = DeviceData.fromMap(deviceId, null);
    _init();
  }

  void _init() {
    // Langsung dengarkan stream database secara reaktif
    _subscription = _deviceService.streamDevice(deviceId).listen(
      (data) {
        _deviceData = data;
        _isSyncing = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        _isSyncing = false;
        notifyListeners();
      },
    );

    // Jalankan seeding data awal di background
    _deviceService.seedInitialDataIfEmpty(deviceId);

    // Selesaikan status sinkronisasi setelah 1.5 detik jika tidak ada error
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (_isSyncing) {
        _isSyncing = false;
        notifyListeners();
      }
    });
  }

  // Mengubah mode operasional: 'manual', 'auto_moisture', atau 'scheduled'
  Future<void> setWateringMode(String mode) async {
    try {
      await _deviceService.setWateringMode(deviceId, mode);
    } catch (e) {
      _errorMessage = 'Gagal mengganti mode: $e';
      notifyListeners();
    }
  }

  // Menyalakan / mematikan pompa manual
  Future<void> toggleManualPump(bool active) async {
    try {
      await _deviceService.setManualPumpCommand(deviceId, active);
    } catch (e) {
      _errorMessage = 'Gagal mengirim perintah pompa: $e';
      notifyListeners();
    }
  }

  // Memperbarui konfigurasi sistem
  Future<void> updateSettings(DeviceSettings settings) async {
    try {
      await _deviceService.updateSettings(deviceId, settings);
    } catch (e) {
      _errorMessage = 'Gagal menyimpan pengaturan: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
