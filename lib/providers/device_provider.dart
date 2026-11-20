import 'dart:async';
import 'package:flutter/material.dart';
import '../core/services/device_service.dart';
import '../models/device_data_model.dart';

class DeviceProvider extends ChangeNotifier {
  final DeviceService _deviceService = DeviceService();
  final String deviceId = 'arven_device_01';

  late DeviceData _deviceData;
  StreamSubscription<DeviceData>? _subscription;
  StreamSubscription<List<IrrigationHistoryItem>>? _historySubscription;
  List<IrrigationHistoryItem> _historyList = [];
  bool _isSyncing = true;
  String? _errorMessage;

  DeviceData get deviceData => _deviceData;
  List<IrrigationHistoryItem> get historyList => _historyList;
  bool get isSyncing => _isSyncing;
  String? get errorMessage => _errorMessage;

  DeviceProvider() {
    // Inisialisasi data langsung agar Dashboard tidak pernah blank / loading lama saat dibuka
    _deviceData = DeviceData.fromMap(deviceId, null);
    _init();
  }

  void _init() {
    // 1. Dengarkan stream status perangkat secara reaktif
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

    // 2. Dengarkan stream log riwayat penyiraman langsung dari Firebase
    _historySubscription = _deviceService.streamHistory(deviceId).listen(
      (logs) {
        _historyList = logs;
        notifyListeners();
      },
      onError: (_) {},
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
    int durationSec = 0;
    if (!active && _deviceData.pumpState.lastStarted != null) {
      final elapsed = DateTime.now().difference(_deviceData.pumpState.lastStarted!).inSeconds;
      durationSec = elapsed > 0 ? elapsed : 1;
    }

    // Update lokal instan agar UI langsung berubah tanpa menunggu round-trip Firebase
    _deviceData = DeviceData(
      deviceId: _deviceData.deviceId,
      status: _deviceData.status,
      sensors: _deviceData.sensors,
      pumpState: PumpState(
        active: active,
        currentMode: _deviceData.pumpState.currentMode,
        lastStarted: active ? DateTime.now() : null,
        lastDurationSec: active ? 0 : durationSec,
      ),
      activeMode: _deviceData.activeMode,
      manualCommand: active,
      settings: _deviceData.settings,
    );
    notifyListeners();

    try {
      await _deviceService.setManualPumpCommand(
        deviceId,
        active,
        durationSec: durationSec,
        currentSoil: _deviceData.sensors.soilMoisture,
      );
    } catch (e) {
      _errorMessage = 'Gagal mengirim perintah pompa: $e';
      notifyListeners();
    }
  }

  // Paksa matikan pompa kapan saja (darurat / reset manual)
  Future<void> forceTurnOffPump() async {
    await toggleManualPump(false);
  }

  // Reset total seluruh riwayat dan statistik (untuk pre-launch atau reset berkala)
  Future<void> resetAllStatistics() async {
    try {
      _deviceData = DeviceData(
        deviceId: _deviceData.deviceId,
        status: _deviceData.status,
        sensors: _deviceData.sensors,
        pumpState: PumpState(
          active: false,
          currentMode: _deviceData.pumpState.currentMode,
          lastStarted: null,
          lastDurationSec: 0,
        ),
        activeMode: _deviceData.activeMode,
        manualCommand: false,
        settings: _deviceData.settings,
      );
      _historyList = [];
      notifyListeners();

      await _deviceService.resetAllDeviceStatistics(deviceId);
    } catch (e) {
      _errorMessage = 'Gagal mereset statistik: $e';
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
    _historySubscription?.cancel();
    super.dispose();
  }
}
