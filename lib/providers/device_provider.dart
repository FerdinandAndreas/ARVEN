import 'dart:async';
import 'package:flutter/material.dart';
import '../core/services/device_service.dart';
import '../models/device_data_model.dart';

/// Menggabungkan data historis (menitan + jam) dengan buffer live dalam rentang waktu [range],
/// lalu melakukan agregasi bucket pada rentang multi-hari agar kurva tetap rapi.
List<SensorLogPoint> buildTrendSeries({
  required List<SensorLogPoint> minuteLogs,
  required List<SensorLogPoint> hourlyLogs,
  required List<SensorLogPoint> liveBuffer,
  required TrendRange range,
  required int nowMs,
}) {
  final int cutoffMs = nowMs - range.duration.inMilliseconds;
  final Map<int, SensorLogPoint> mergedByTimestamp = <int, SensorLogPoint>{};

  for (final p in hourlyLogs) {
    if (p.timestamp >= cutoffMs && p.timestamp <= nowMs + 60000) {
      mergedByTimestamp[p.timestamp] = p;
    }
  }

  for (final p in minuteLogs) {
    if (p.timestamp >= cutoffMs && p.timestamp <= nowMs + 60000) {
      mergedByTimestamp[p.timestamp] = p;
    }
  }

  if (range == TrendRange.oneHour) {
    for (final p in liveBuffer) {
      if (p.timestamp >= cutoffMs && p.timestamp <= nowMs + 60000) {
        mergedByTimestamp[p.timestamp] = p;
      }
    }
  } else if (liveBuffer.isNotEmpty) {
    final latestLive = liveBuffer.last;
    if (latestLive.timestamp >= cutoffMs && latestLive.timestamp <= nowMs + 60000) {
      mergedByTimestamp[latestLive.timestamp] = latestLive;
    }
  }

  final List<SensorLogPoint> sorted = mergedByTimestamp.values.toList()
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  if (sorted.isEmpty) return sorted;

  final int? bucketMs = switch (range) {
    TrendRange.oneHour => null,
    TrendRange.twentyFourHours => sorted.length > 96 ? 15 * 60000 : null,
    TrendRange.threeDays => sorted.length > 72 ? 60 * 60000 : null,
    TrendRange.sevenDays => sorted.length > 72 ? 3 * 3600000 : null,
    TrendRange.thirtyDays => sorted.length > 72 ? 12 * 3600000 : null,
  };

  if (bucketMs == null) {
    return sorted;
  }

  final Map<int, List<SensorLogPoint>> buckets = <int, List<SensorLogPoint>>{};
  for (final point in sorted) {
    final int bucketKey = point.timestamp ~/ bucketMs;
    buckets.putIfAbsent(bucketKey, () => <SensorLogPoint>[]).add(point);
  }

  final List<SensorLogPoint> aggregated = <SensorLogPoint>[];
  final sortedKeys = buckets.keys.toList()..sort();
  for (final key in sortedKeys) {
    final group = buckets[key]!;
    double sumSoil = 0;
    double sumTemp = 0;
    double sumHumid = 0;
    int sumTime = 0;
    bool anyRain = false;

    for (final item in group) {
      sumSoil += item.soilMoisture;
      sumTemp += item.temperature;
      sumHumid += item.humidity;
      sumTime += item.timestamp;
      if (item.rain) anyRain = true;
    }

    final int count = group.length;
    aggregated.add(
      SensorLogPoint(
        timestamp: sumTime ~/ count,
        soilMoisture: sumSoil / count,
        temperature: sumTemp / count,
        humidity: sumHumid / count,
        rain: anyRain,
      ),
    );
  }

  return aggregated;
}

class DeviceProvider extends ChangeNotifier {
  final DeviceService _deviceService = DeviceService();
  final String deviceId = 'arven_device_01';

  // Epoch ms >= 14 Nov 2023 menandakan waktu NTP valid (bukan millis uptime ESP32)
  static const int _minValidEpochMs = 1700000000000;
  static const int _maxLiveBufferPoints = 720;

  late DeviceData _deviceData;
  StreamSubscription<DeviceData>? _subscription;
  StreamSubscription<List<IrrigationHistoryItem>>? _historySubscription;
  StreamSubscription<List<SensorLogPoint>>? _sensorLogsSubscription;
  StreamSubscription<List<SensorLogPoint>>? _hourlyLogsSubscription;

  List<IrrigationHistoryItem> _historyList = [];
  List<SensorLogPoint> _sensorLogs = [];
  List<SensorLogPoint> _hourlyLogs = [];
  final List<SensorLogPoint> _liveSensorBuffer = [];

  TrendRange _selectedTrendRange = TrendRange.twentyFourHours;
  bool _isSyncing = true;
  bool _isLoadingTrend = true;
  String? _errorMessage;
  String? _trendError;

  int _lastRecordedMinuteBucket = -1;
  int _lastRecordedHourBucket = -1;
  int _lastLiveBufferTimestamp = -1;

  DeviceData get deviceData => _deviceData;
  List<IrrigationHistoryItem> get historyList => _historyList;
  TrendRange get selectedTrendRange => _selectedTrendRange;
  bool get isSyncing => _isSyncing;
  bool get isLoadingTrend => _isLoadingTrend;
  String? get errorMessage => _errorMessage;
  String? get trendError => _trendError;

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
        _captureLiveSensorPoint(data);
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

    // 3. Dengarkan log time-series sensor dari Firebase sesuai rentang tren aktif
    _subscribeSensorLogs(_selectedTrendRange);

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

  void _captureLiveSensorPoint(DeviceData data) {
    final sensors = data.sensors;
    final int? rawMs = sensors.updatedAt?.millisecondsSinceEpoch;
    if (rawMs == null) return;

    int? pointMs;
    if (rawMs >= _minValidEpochMs) {
      pointMs = rawMs;
    } else if (data.status.online) {
      // Fallback ke jam perangkat hanya jika ESP32 online tetapi NTP belum sinkron
      pointMs = DateTime.now().millisecondsSinceEpoch;
    }

    if (pointMs == null) return;

    final point = SensorLogPoint(
      timestamp: pointMs,
      soilMoisture: sensors.soilMoisture,
      temperature: sensors.temperature,
      humidity: sensors.humidity,
      rain: sensors.rain,
    );

    // Simpan ke buffer memori untuk pembaruan real-time 5 detik di rentang 1 Jam
    if (pointMs > _lastLiveBufferTimestamp) {
      _lastLiveBufferTimestamp = pointMs;
      _liveSensorBuffer.add(point);
      final int oneHourAgo = DateTime.now().millisecondsSinceEpoch - const Duration(hours: 1).inMilliseconds;
      _liveSensorBuffer.removeWhere((p) => p.timestamp < oneHourAgo);
      if (_liveSensorBuffer.length > _maxLiveBufferPoints) {
        _liveSensorBuffer.removeRange(0, _liveSensorBuffer.length - _maxLiveBufferPoints);
      }
    }

    // Catat ke Firebase setiap pergantian menit dan pergantian jam untuk data segar
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final bool isFreshReading = data.status.online || (nowMs - pointMs).abs() <= 300000;
    if (!isFreshReading) return;

    final int minuteBucket = pointMs ~/ 60000;
    if (minuteBucket > _lastRecordedMinuteBucket) {
      _lastRecordedMinuteBucket = minuteBucket;
      _deviceService.recordSensorLogPoint(deviceId, point).catchError((_) {});
    }

    final int hourBucket = pointMs ~/ 3600000;
    if (hourBucket > _lastRecordedHourBucket) {
      _lastRecordedHourBucket = hourBucket;
      _deviceService.recordSensorHourlyLogPoint(deviceId, point).catchError((_) {});
    }
  }

  void _subscribeSensorLogs(TrendRange range) {
    _sensorLogsSubscription?.cancel();
    _hourlyLogsSubscription?.cancel();
    _isLoadingTrend = true;
    _trendError = null;

    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final int cutoffMs = nowMs - range.duration.inMilliseconds;

    if (range == TrendRange.oneHour || range == TrendRange.twentyFourHours) {
      _hourlyLogs = [];
      final int limit = range == TrendRange.oneHour ? 120 : 1500;
      _sensorLogsSubscription = _deviceService
          .streamSensorLogs(deviceId, startAfterMs: cutoffMs, limit: limit)
          .listen(
        (logs) {
          _sensorLogs = logs;
          _isLoadingTrend = false;
          _trendError = null;
          notifyListeners();
        },
        onError: (error) {
          _trendError = 'Gagal memuat riwayat sensor: $error';
          _isLoadingTrend = false;
          notifyListeners();
        },
      );
    } else {
      // Rentang multi-hari (3 Hari - 30 Hari): gabungkan log per jam penuh + log menitan hari ini
      final int recentCutoffMs = nowMs - const Duration(hours: 24).inMilliseconds;
      _hourlyLogsSubscription = _deviceService
          .streamSensorHourlyLogs(deviceId, startAfterMs: cutoffMs, limit: 800)
          .listen(
        (logs) {
          _hourlyLogs = logs;
          _isLoadingTrend = false;
          _trendError = null;
          notifyListeners();
        },
        onError: (error) {
          _trendError = 'Gagal memuat riwayat sensor: $error';
          _isLoadingTrend = false;
          notifyListeners();
        },
      );

      _sensorLogsSubscription = _deviceService
          .streamSensorLogs(deviceId, startAfterMs: recentCutoffMs, limit: 1500)
          .listen(
        (logs) {
          _sensorLogs = logs;
          notifyListeners();
        },
        onError: (_) {},
      );
    }
  }

  void setTrendRange(TrendRange range) {
    if (_selectedTrendRange == range) return;
    _selectedTrendRange = range;
    _subscribeSensorLogs(range);
    notifyListeners();
  }

  List<SensorLogPoint> getTrendPoints([TrendRange? rangeOverride]) {
    final TrendRange range = rangeOverride ?? _selectedTrendRange;
    return buildTrendSeries(
      minuteLogs: _sensorLogs,
      hourlyLogs: _hourlyLogs,
      liveBuffer: _liveSensorBuffer,
      range: range,
      nowMs: DateTime.now().millisecondsSinceEpoch,
    );
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
    _sensorLogsSubscription?.cancel();
    _hourlyLogsSubscription?.cancel();
    super.dispose();
  }
}
