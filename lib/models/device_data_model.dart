class DeviceStatus {
  final bool online;
  final DateTime? lastSeen;

  DeviceStatus({
    required this.online,
    this.lastSeen,
  });

  factory DeviceStatus.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return DeviceStatus(online: false);
    final rawLastSeen = map['last_seen'];
    DateTime? parsedLastSeen;
    if (rawLastSeen is int) {
      parsedLastSeen = DateTime.fromMillisecondsSinceEpoch(rawLastSeen);
    }
    return DeviceStatus(
      online: map['online'] == true,
      lastSeen: parsedLastSeen,
    );
  }
}

class SensorData {
  final double soilMoisture;
  final double temperature;
  final double humidity;
  final bool rain;
  final DateTime? updatedAt;

  SensorData({
    required this.soilMoisture,
    required this.temperature,
    required this.humidity,
    required this.rain,
    this.updatedAt,
  });

  factory SensorData.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) {
      return SensorData(
        soilMoisture: 0.0,
        temperature: 0.0,
        humidity: 0.0,
        rain: false,
      );
    }

    final rawUpdatedAt = map['updated_at'];
    DateTime? parsedUpdatedAt;
    if (rawUpdatedAt is int) {
      parsedUpdatedAt = DateTime.fromMillisecondsSinceEpoch(rawUpdatedAt);
    }

    return SensorData(
      soilMoisture: (map['soil_moisture'] as num?)?.toDouble() ?? 0.0,
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (map['humidity'] as num?)?.toDouble() ?? 0.0,
      rain: map['rain'] == true,
      updatedAt: parsedUpdatedAt,
    );
  }
}

class PumpState {
  final bool active;
  final String currentMode; // 'manual', 'auto_moisture', 'scheduled'
  final DateTime? lastStarted;
  final int lastDurationSec;

  PumpState({
    required this.active,
    required this.currentMode,
    this.lastStarted,
    this.lastDurationSec = 15,
  });

  factory PumpState.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) {
      return PumpState(active: false, currentMode: 'manual');
    }

    final rawStarted = map['last_started'];
    DateTime? parsedStarted;
    if (rawStarted is int) {
      parsedStarted = DateTime.fromMillisecondsSinceEpoch(rawStarted);
    }

    return PumpState(
      active: map['active'] == true,
      currentMode: map['current_mode']?.toString() ?? 'manual',
      lastStarted: parsedStarted,
      lastDurationSec: (map['last_duration_sec'] as num?)?.toInt() ?? 15,
    );
  }
}

class DeviceSchedule {
  final int frequency; // 2, 3, atau 4 kali
  final String time1; // misal '07:00' (Pagi)
  final String time2; // misal '12:00' (Siang) atau '16:30' (Sore)
  final String time3; // misal '16:30' (Sore)
  final String time4; // misal '20:00' (Malam)
  final int durationSec; // lama pompa per sesi

  DeviceSchedule({
    this.frequency = 2,
    this.time1 = '07:00',
    this.time2 = '16:30',
    this.time3 = '12:00',
    this.time4 = '20:00',
    this.durationSec = 20,
  });

  factory DeviceSchedule.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return DeviceSchedule();
    return DeviceSchedule(
      frequency: (map['frequency'] as num?)?.toInt() ?? 2,
      time1: map['time_1']?.toString() ?? '07:00',
      time2: map['time_2']?.toString() ?? '16:30',
      time3: map['time_3']?.toString() ?? '12:00',
      time4: map['time_4']?.toString() ?? '20:00',
      durationSec: (map['duration_sec'] as num?)?.toInt() ?? 20,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'frequency': frequency,
      'time_1': time1,
      'time_2': time2,
      'time_3': time3,
      'time_4': time4,
      'duration_sec': durationSec,
    };
  }
}

class DeviceSettings {
  final int moistureThreshold; // % kelembapan minimum pemicu pompa aktif (<= min)
  final int moistureThresholdMax; // % kelembapan maksimum pompa otomatis mati (>= max)
  final int wateringDurationSec; // durasi batas cadangan siram otomatis
  final int soakIntervalMin; // jeda anti-chattering (menit, legacy)
  final int soakIntervalSec; // jeda anti-chattering (detik)
  final double maxTemperatureLimit; // batas suhu aman DHT22
  final bool rainDelayEnabled;
  final int manualSafetyTimeoutMin; // batas waktu keamanan cut-off manual jika lupa (menit, legacy)
  final int manualSafetyTimeoutSec; // batas waktu keamanan cut-off manual (detik)
  final DeviceSchedule schedule;

  DeviceSettings({
    this.moistureThreshold = 40,
    this.moistureThresholdMax = 85,
    this.wateringDurationSec = 15,
    this.soakIntervalMin = 20,
    int? soakIntervalSec,
    this.maxTemperatureLimit = 35.0,
    this.rainDelayEnabled = true,
    this.manualSafetyTimeoutMin = 5,
    int? manualSafetyTimeoutSec,
    DeviceSchedule? schedule,
  })  : soakIntervalSec = soakIntervalSec ?? (soakIntervalMin * 60),
        manualSafetyTimeoutSec = manualSafetyTimeoutSec ?? (manualSafetyTimeoutMin * 60),
        schedule = schedule ?? DeviceSchedule();

  factory DeviceSettings.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return DeviceSettings();
    final sMin = (map['soak_interval_min'] as num?)?.toInt() ?? 20;
    final sSec = (map['soak_interval_sec'] as num?)?.toInt() ?? (sMin * 60);

    final mMin = (map['manual_safety_timeout_min'] as num?)?.toInt() ?? 5;
    final mSec = (map['manual_safety_timeout_sec'] as num?)?.toInt() ?? (mMin * 60);

    return DeviceSettings(
      moistureThreshold: (map['moisture_threshold'] as num?)?.toInt() ?? 40,
      moistureThresholdMax: (map['moisture_threshold_max'] as num?)?.toInt() ?? 85,
      wateringDurationSec: (map['watering_duration_sec'] as num?)?.toInt() ?? 15,
      soakIntervalMin: (sSec / 60).ceil(),
      soakIntervalSec: sSec,
      maxTemperatureLimit: (map['max_temperature_limit'] as num?)?.toDouble() ?? 35.0,
      rainDelayEnabled: map['rain_delay_enabled'] != false,
      manualSafetyTimeoutMin: (mSec / 60).ceil(),
      manualSafetyTimeoutSec: mSec,
      schedule: DeviceSchedule.fromMap(map['schedule'] as Map<dynamic, dynamic>?),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'moisture_threshold': moistureThreshold,
      'moisture_threshold_max': moistureThresholdMax,
      'watering_duration_sec': wateringDurationSec,
      'soak_interval_min': (soakIntervalSec / 60).ceil(),
      'soak_interval_sec': soakIntervalSec,
      'max_temperature_limit': maxTemperatureLimit,
      'rain_delay_enabled': rainDelayEnabled,
      'manual_safety_timeout_min': (manualSafetyTimeoutSec / 60).ceil(),
      'manual_safety_timeout_sec': manualSafetyTimeoutSec,
      'schedule': schedule.toMap(),
    };
  }
}

class DeviceData {
  final String deviceId;
  final DeviceStatus status;
  final SensorData sensors;
  final PumpState pumpState;
  final String activeMode; // 'manual', 'auto_moisture', 'scheduled'
  final bool manualCommand;
  final DeviceSettings settings;

  DeviceData({
    required this.deviceId,
    required this.status,
    required this.sensors,
    required this.pumpState,
    required this.activeMode,
    required this.manualCommand,
    required this.settings,
  });

  factory DeviceData.fromMap(String id, Map<dynamic, dynamic>? map) {
    if (map == null) {
      return DeviceData(
        deviceId: id,
        status: DeviceStatus(online: false),
        sensors: SensorData(soilMoisture: 0, temperature: 0, humidity: 0, rain: false),
        pumpState: PumpState(active: false, currentMode: 'manual'),
        activeMode: 'manual',
        manualCommand: false,
        settings: DeviceSettings(),
      );
    }

    final controlMap = map['control'] as Map<dynamic, dynamic>?;
    final mode = controlMap?['mode']?.toString() ?? 'manual';
    final manualCmd = controlMap?['pump_manual_command'] == true;

    return DeviceData(
      deviceId: id,
      status: DeviceStatus.fromMap(map['status'] as Map<dynamic, dynamic>?),
      sensors: SensorData.fromMap(map['sensors'] as Map<dynamic, dynamic>?),
      pumpState: PumpState.fromMap(map['pump_state'] as Map<dynamic, dynamic>?),
      activeMode: mode,
      manualCommand: manualCmd,
      settings: DeviceSettings.fromMap(map['settings'] as Map<dynamic, dynamic>?),
    );
  }
}

class IrrigationHistoryItem {
  final String id;
  final int timestamp;
  final String title;
  final String mode; // 'manual', 'scheduled', 'auto_moisture'
  final int durationSec;
  final double waterLiters;
  final double soilBefore;
  final double soilAfter;
  final String status; // 'Selesai', 'Auto Cut-Off', 'Dihentikan Manual', 'Tunda Hujan'

  IrrigationHistoryItem({
    required this.id,
    required this.timestamp,
    required this.title,
    required this.mode,
    required this.durationSec,
    required this.waterLiters,
    required this.soilBefore,
    required this.soilAfter,
    required this.status,
  });

  factory IrrigationHistoryItem.fromMap(String id, Map<dynamic, dynamic>? map) {
    if (map == null) {
      return IrrigationHistoryItem(
        id: id,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        title: 'Penyiraman',
        mode: 'manual',
        durationSec: 0,
        waterLiters: 0.0,
        soilBefore: 0.0,
        soilAfter: 0.0,
        status: 'Selesai',
      );
    }
    return IrrigationHistoryItem(
      id: id,
      timestamp: (map['timestamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      title: map['title']?.toString() ?? 'Penyiraman',
      mode: map['mode']?.toString() ?? 'manual',
      durationSec: (map['duration_sec'] as num?)?.toInt() ?? 0,
      waterLiters: (map['water_liters'] as num?)?.toDouble() ?? 0.0,
      soilBefore: (map['soil_before'] as num?)?.toDouble() ?? 0.0,
      soilAfter: (map['soil_after'] as num?)?.toDouble() ?? 0.0,
      status: map['status']?.toString() ?? 'Selesai',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp,
      'title': title,
      'mode': mode,
      'duration_sec': durationSec,
      'water_liters': waterLiters,
      'soil_before': soilBefore,
      'soil_after': soilAfter,
      'status': status,
    };
  }
}
