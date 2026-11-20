import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_decorations.dart';
import '../../../models/device_data_model.dart';
import '../../../providers/device_provider.dart';

class ControlTabView extends StatefulWidget {
  final DeviceData device;
  final DeviceProvider deviceProvider;
  final VoidCallback? onOpenFullSettings;

  const ControlTabView({
    super.key,
    required this.device,
    required this.deviceProvider,
    this.onOpenFullSettings,
  });

  @override
  State<ControlTabView> createState() => _ControlTabViewState();
}

class _ControlTabViewState extends State<ControlTabView> {
  // Mode Otomatis
  late double _moistureMin;
  late double _moistureMax;
  late double _soakIntervalSec; // disimpan dalam detik
  late bool _rainDelay;

  // Mode Terjadwal (Pagi, Siang, Sore, Malam)
  late int _scheduleFrequency; // 2, 3, atau 4
  late TimeOfDay _timePagi;
  late TimeOfDay _timeSiang;
  late TimeOfDay _timeSore;
  late TimeOfDay _timeMalam;
  late double _scheduledDurationSec;

  // Mode Manual
  late double _manualSafetyTimeoutSec; // disimpan dalam detik

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final s = widget.device.settings;
    _moistureMin = s.moistureThreshold.toDouble().clamp(10.0, 70.0);
    _moistureMax = s.moistureThresholdMax.toDouble().clamp(_moistureMin + 5.0, 95.0);
    _soakIntervalSec = s.soakIntervalSec.toDouble().clamp(5.0, 7200.0);
    _rainDelay = s.rainDelayEnabled;
    _manualSafetyTimeoutSec = s.manualSafetyTimeoutSec.toDouble().clamp(5.0, 3600.0);

    final sc = s.schedule;
    _scheduleFrequency = sc.frequency.clamp(2, 4);

    _timePagi = _parseTime(sc.time1, const TimeOfDay(hour: 7, minute: 0));

    // Handle parsing for Siang, Sore, and Malam
    if (sc.frequency == 2) {
      _timeSore = _parseTime(sc.time2, const TimeOfDay(hour: 16, minute: 30));
      _timeSiang = _parseTime(sc.time3, const TimeOfDay(hour: 12, minute: 0));
    } else {
      final t2 = _parseTime(sc.time2, const TimeOfDay(hour: 12, minute: 0));
      final t3 = _parseTime(sc.time3, const TimeOfDay(hour: 16, minute: 30));
      if (t2.hour > t3.hour) {
        _timeSiang = t3;
        _timeSore = t2;
      } else {
        _timeSiang = t2;
        _timeSore = t3;
      }
    }

    _timeMalam = _parseTime(sc.time4, const TimeOfDay(hour: 20, minute: 0));
    _scheduledDurationSec = sc.durationSec.toDouble().clamp(5.0, 3600.0);
  }

  TimeOfDay _parseTime(String timeStr, TimeOfDay fallback) {
    try {
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    } catch (_) {}
    return fallback;
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds < 60) {
      return '$totalSeconds Detik';
    }
    final minutes = totalSeconds ~/ 60;
    final remainingSeconds = totalSeconds % 60;
    if (remainingSeconds == 0) {
      return '$minutes Menit';
    }
    return '$minutes Menit $remainingSeconds Detik';
  }

  Future<void> _pickTime(String sessionType) async {
    final TimeOfDay initial = sessionType == 'pagi'
        ? _timePagi
        : sessionType == 'siang'
            ? _timeSiang
            : sessionType == 'sore'
                ? _timeSore
                : _timeMalam;

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (sessionType == 'pagi') _timePagi = picked;
        if (sessionType == 'siang') _timeSiang = picked;
        if (sessionType == 'sore') _timeSore = picked;
        if (sessionType == 'malam') _timeMalam = picked;
      });
    }
  }

  // 1. Dialog Ketik Durasi Penyiraman Terjadwal (Menit & Detik)
  void _showCustomDurationDialog() {
    final minutesController = TextEditingController(
      text: (_scheduledDurationSec.round() ~/ 60).toString(),
    );
    final secondsController = TextEditingController(
      text: (_scheduledDurationSec.round() % 60).toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Row(
            children: [
              Icon(Icons.timer_outlined, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ketik Durasi Penyiraman',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tentukan lama pompa menyala pada setiap sesi terjadwal:',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Menit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: minutesController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '0',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.cardBorder),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Detik', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: secondsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '0',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.cardBorder),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final int m = int.tryParse(minutesController.text.trim()) ?? 0;
                final int s = int.tryParse(secondsController.text.trim()) ?? 0;
                final int total = (m * 60) + s;

                if (total >= 5 && total <= 3600) {
                  setState(() {
                    _scheduledDurationSec = total.toDouble();
                  });
                  Navigator.pop(ctx);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Durasi minimal 5 detik dan maksimal 60 menit.'),
                      backgroundColor: AppColors.danger,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
              child: const Text('Terapkan'),
            ),
          ],
        );
      },
    );
  }

  // 2. Dialog Ketik Jeda Peresapan Air (Menit & Detik)
  void _showCustomSoakIntervalDialog() {
    final minutesController = TextEditingController(
      text: (_soakIntervalSec.round() ~/ 60).toString(),
    );
    final secondsController = TextEditingController(
      text: (_soakIntervalSec.round() % 60).toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Row(
            children: [
              Icon(Icons.hourglass_top_rounded, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ketik Jeda Peresapan Air',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Waktu tunggu peresapan air ke akar sebelum evaluasi kelembapan sensor:',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Menit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: minutesController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '0',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.cardBorder),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Detik', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: secondsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '0',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.cardBorder),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text('Preset Cepat:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildQuickPresetChip('15 Detik', 0, 15, minutesController, secondsController),
                  _buildQuickPresetChip('30 Detik', 0, 30, minutesController, secondsController),
                  _buildQuickPresetChip('1 Menit', 1, 0, minutesController, secondsController),
                  _buildQuickPresetChip('2 Menit', 2, 0, minutesController, secondsController),
                  _buildQuickPresetChip('5 Menit', 5, 0, minutesController, secondsController),
                  _buildQuickPresetChip('10 Menit', 10, 0, minutesController, secondsController),
                  _buildQuickPresetChip('15 Menit', 15, 0, minutesController, secondsController),
                  _buildQuickPresetChip('30 Menit', 30, 0, minutesController, secondsController),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final int m = int.tryParse(minutesController.text.trim()) ?? 0;
                final int s = int.tryParse(secondsController.text.trim()) ?? 0;
                final int totalSec = (m * 60) + s;

                if (totalSec >= 5 && totalSec <= 7200) {
                  setState(() {
                    _soakIntervalSec = totalSec.toDouble();
                  });
                  Navigator.pop(ctx);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Jeda peresapan minimal 5 detik dan maksimal 120 menit.'),
                      backgroundColor: AppColors.danger,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
              child: const Text('Terapkan'),
            ),
          ],
        );
      },
    );
  }

  // 3. Dialog Ketik Batas Pengaman Auto Cut-Off (Menit & Detik)
  void _showCustomSafetyTimeoutDialog() {
    final minutesController = TextEditingController(
      text: (_manualSafetyTimeoutSec.round() ~/ 60).toString(),
    );
    final secondsController = TextEditingController(
      text: (_manualSafetyTimeoutSec.round() % 60).toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppColors.warning, size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ketik Batas Pengaman Cut-Off',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Batas waktu pompa manual menyala sebelum otomatis dimatikan sistem jika lupa:',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Menit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: minutesController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '0',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.cardBorder),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Detik', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: secondsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '0',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.cardBorder),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text('Preset Cepat:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildQuickPresetChip('30 Detik', 0, 30, minutesController, secondsController),
                  _buildQuickPresetChip('1 Menit', 1, 0, minutesController, secondsController),
                  _buildQuickPresetChip('2 Menit', 2, 0, minutesController, secondsController),
                  _buildQuickPresetChip('5 Menit', 5, 0, minutesController, secondsController),
                  _buildQuickPresetChip('10 Menit', 10, 0, minutesController, secondsController),
                  _buildQuickPresetChip('15 Menit', 15, 0, minutesController, secondsController),
                  _buildQuickPresetChip('30 Menit', 30, 0, minutesController, secondsController),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final int m = int.tryParse(minutesController.text.trim()) ?? 0;
                final int s = int.tryParse(secondsController.text.trim()) ?? 0;
                final int totalSec = (m * 60) + s;

                if (totalSec >= 5 && totalSec <= 3600) {
                  setState(() {
                    _manualSafetyTimeoutSec = totalSec.toDouble();
                  });
                  Navigator.pop(ctx);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Batas cut-off minimal 5 detik dan maksimal 60 menit.'),
                      backgroundColor: AppColors.danger,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
              child: const Text('Terapkan'),
            ),
          ],
        );
      },
    );
  }

  // 4. Dialog Ketik Rentang Target Kelembapan (%)
  void _showCustomMoistureRangeDialog() {
    final minController = TextEditingController(text: _moistureMin.round().toString());
    final maxController = TextEditingController(text: _moistureMax.round().toString());

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Row(
            children: [
              Icon(Icons.water_drop_rounded, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ketik Rentang Kelembapan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tentukan batas pemicu pompa ON dan batas target pompa OFF dalam %:',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Min (Pompa ON)',
                        suffixText: '%',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.cardBorder),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: maxController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Max (Pompa OFF)',
                        suffixText: '%',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.cardBorder),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final int mn = int.tryParse(minController.text.trim()) ?? 0;
                final int mx = int.tryParse(maxController.text.trim()) ?? 0;

                if (mn >= 10 && mx <= 95 && mx >= mn + 5) {
                  setState(() {
                    _moistureMin = mn.toDouble();
                    _moistureMax = mx.toDouble();
                  });
                  Navigator.pop(ctx);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Batas Max harus lebih besar minimal 5% dari Min (rentang 10% - 95%).'),
                      backgroundColor: AppColors.danger,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
              child: const Text('Terapkan'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickPresetChip(String label, int minutes, int seconds, TextEditingController minCtrl, TextEditingController secCtrl) {
    return InkWell(
      onTap: () {
        minCtrl.text = minutes.toString();
        secCtrl.text = seconds.toString();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.badgeInfoBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
      ),
    );
  }

  void _saveSettings() {
    final s = widget.device.settings;

    final String t1 = _formatTime(_timePagi);
    final String t2 = _scheduleFrequency == 2 ? _formatTime(_timeSore) : _formatTime(_timeSiang);
    final String t3 = _scheduleFrequency == 2 ? _formatTime(_timeSiang) : _formatTime(_timeSore);
    final String t4 = _formatTime(_timeMalam);

    final newSettings = DeviceSettings(
      moistureThreshold: _moistureMin.round(),
      moistureThresholdMax: _moistureMax.round(),
      wateringDurationSec: s.wateringDurationSec,
      soakIntervalMin: (_soakIntervalSec / 60).ceil(),
      soakIntervalSec: _soakIntervalSec.round(),
      maxTemperatureLimit: s.maxTemperatureLimit,
      rainDelayEnabled: _rainDelay,
      manualSafetyTimeoutMin: (_manualSafetyTimeoutSec / 60).ceil(),
      manualSafetyTimeoutSec: _manualSafetyTimeoutSec.round(),
      schedule: DeviceSchedule(
        frequency: _scheduleFrequency,
        time1: t1,
        time2: t2,
        time3: t3,
        time4: t4,
        durationSec: _scheduledDurationSec.round(),
      ),
    );

    widget.deviceProvider.updateSettings(newSettings);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Konfigurasi parameter berhasil disimpan ke ESP32.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 360;
        final double hPadding = isCompact ? 14 : (constraints.maxWidth >= 780 ? 24 : 18);

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Title & Subtitle Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Konfigurasi Parameter Irigasi',
                              style: TextStyle(
                                fontSize: isCompact ? 18 : 21,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Otomasi kelembapan tanah, jadwal, dan proteksi manual',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Muat ulang data perangkat',
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _loadSettings();
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Parameter dimuat ulang dari memori perangkat.'),
                                backgroundColor: AppColors.primary,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: AppDecorations.squircleIcon(radius: 11),
                            child: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // ==========================================
                  // 1. PARAMETER MODE OTOMATIS (MIN & MAX)
                  // ==========================================
                  _buildSectionHeader('Mode Otomatis (Sensor Kelembapan)', Icons.water_drop_rounded),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppDecorations.raisedCard(radius: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Rentang Target Kelembapan',
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            // Clickable Badge to Type Directly
                            GestureDetector(
                              onTap: _showCustomMoistureRangeDialog,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.badgeInfoBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                  boxShadow: AppDecorations.softRaisedShadow,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${_moistureMin.round()}%  -  ${_moistureMax.round()}%',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Pompa otomatis MENYALA saat kelembapan tanah turun di bawah batas minimum, dan otomatis MATI saat tanah mencapai batas maksimum target.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                        ),
                        const SizedBox(height: 14),

                        // Indikator Badge Status Min & Max (Pink & Green Boxes)
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.badgeDangerBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Pemicu Pompa ON',
                                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.badgeDangerText),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '≤ ${_moistureMin.round()}% (Kering)',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.badgeDangerText),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.badgeSuccessBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Target Pompa OFF',
                                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.badgeSuccessText),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '≥ ${_moistureMax.round()}% (Basah)',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.badgeSuccessText),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Dual RangeSlider
                        RangeSlider(
                          values: RangeValues(_moistureMin, _moistureMax),
                          min: 15.0,
                          max: 95.0,
                          divisions: 16,
                          activeColor: AppColors.primary,
                          inactiveColor: AppColors.secondary.withValues(alpha: 0.4),
                          labels: RangeLabels('${_moistureMin.round()}%', '${_moistureMax.round()}%'),
                          onChanged: (RangeValues values) {
                            if (values.end - values.start >= 10) {
                              setState(() {
                                _moistureMin = values.start;
                                _moistureMax = values.end;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Jeda Peresapan Air (Soak Time) Card with Seconds & Minutes Control
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppDecorations.raisedCard(radius: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Jeda Peresapan Air (Soak Time)',
                                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Clickable Badge Button with Edit Icon
                            GestureDetector(
                              onTap: _showCustomSoakIntervalDialog,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: AppDecorations.softRaisedShadow,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatDuration(_soakIntervalSec.round()),
                                      style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 13),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.edit_note_rounded, color: Colors.white, size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Waktu tunggu air meresap ke perakaran sebelum sensor dievaluasi kembali, mencegah pompa menyala mati berulang.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 10),

                        // Preset Chips Cepat (Termasuk Detik & Menit)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _buildPresetChip('15 Detik', 15, _soakIntervalSec.round(), (v) => setState(() => _soakIntervalSec = v.toDouble())),
                              _buildPresetChip('30 Detik', 30, _soakIntervalSec.round(), (v) => setState(() => _soakIntervalSec = v.toDouble())),
                              _buildPresetChip('1 Menit', 60, _soakIntervalSec.round(), (v) => setState(() => _soakIntervalSec = v.toDouble())),
                              _buildPresetChip('2 Menit', 120, _soakIntervalSec.round(), (v) => setState(() => _soakIntervalSec = v.toDouble())),
                              _buildPresetChip('5 Menit', 300, _soakIntervalSec.round(), (v) => setState(() => _soakIntervalSec = v.toDouble())),
                              _buildPresetChip('10 Menit', 600, _soakIntervalSec.round(), (v) => setState(() => _soakIntervalSec = v.toDouble())),
                              _buildPresetChip('15 Menit', 900, _soakIntervalSec.round(), (v) => setState(() => _soakIntervalSec = v.toDouble())),
                              _buildPresetChip('30 Menit', 1800, _soakIntervalSec.round(), (v) => setState(() => _soakIntervalSec = v.toDouble())),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),

                        Slider(
                          value: _soakIntervalSec.clamp(5.0, 3600.0),
                          min: 5,
                          max: 3600,
                          divisions: 71,
                          activeColor: AppColors.primary,
                          inactiveColor: AppColors.secondary.withValues(alpha: 0.4),
                          onChanged: (val) => setState(() => _soakIntervalSec = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ==========================================
                  // 2. PARAMETER MODE TERJADWAL
                  // ==========================================
                  _buildSectionHeader('Mode Terjadwal (Waktu & Durasi Menit/Detik)', Icons.alarm_rounded),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppDecorations.raisedCard(radius: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Frekuensi Sesi Header + Tambah Sesi Icon Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Frekuensi Sesi Penyiraman',
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            if (_scheduleFrequency < 4)
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _scheduleFrequency++;
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.badgeInfoBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                    boxShadow: AppDecorations.softRaisedShadow,
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                                      SizedBox(width: 2),
                                      Text(
                                        'Tambah Sesi',
                                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Frequency Chips (2 Kali, 3 Kali, 4 Kali)
                        Row(
                          children: [
                            Expanded(child: _buildFrequencyChip('2 Kali', 2)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildFrequencyChip('3 Kali', 3)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildFrequencyChip('4 Kali', 4)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 1. Sesi Pagi
                        _buildTimePickerTile(
                          'Sesi Pagi',
                          _formatTime(_timePagi),
                          Icons.wb_sunny_rounded,
                          () => _pickTime('pagi'),
                        ),

                        // 2. Sesi Siang (Ditampilkan jika frekuensi >= 3)
                        if (_scheduleFrequency >= 3) ...[
                          const SizedBox(height: 10),
                          _buildTimePickerTile(
                            'Sesi Siang',
                            _formatTime(_timeSiang),
                            Icons.light_mode_rounded,
                            () => _pickTime('siang'),
                          ),
                        ],

                        // 3. Sesi Sore (Selalu ditampilkan)
                        const SizedBox(height: 10),
                        _buildTimePickerTile(
                          'Sesi Sore',
                          _formatTime(_timeSore),
                          Icons.wb_twilight_rounded,
                          () => _pickTime('sore'),
                        ),

                        // 4. Sesi Malam (Ditampilkan jika frekuensi >= 4)
                        if (_scheduleFrequency >= 4) ...[
                          const SizedBox(height: 10),
                          _buildTimePickerTile(
                            'Sesi Malam',
                            _formatTime(_timeMalam),
                            Icons.nightlight_round,
                            () => _pickTime('malam'),
                          ),
                        ],

                        const SizedBox(height: 18),

                        // Durasi Siram Terjadwal (Slider + Input/Ketik)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Durasi Penyiraman Terjadwal',
                                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Clickable Badge Button with Edit Icon
                            GestureDetector(
                              onTap: _showCustomDurationDialog,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: AppDecorations.softRaisedShadow,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatDuration(_scheduledDurationSec.round()),
                                      style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 13),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.edit_note_rounded, color: Colors.white, size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Geser slider di bawah atau ketuk tombol di atas untuk mengetik langsung menit & detik sesuai kebutuhan tanaman.',
                          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 10),

                        // Preset Chips Cepat
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _buildPresetChip('30 Detik', 30, _scheduledDurationSec.round(), (v) => setState(() => _scheduledDurationSec = v.toDouble())),
                              _buildPresetChip('1 Menit', 60, _scheduledDurationSec.round(), (v) => setState(() => _scheduledDurationSec = v.toDouble())),
                              _buildPresetChip('2 Menit', 120, _scheduledDurationSec.round(), (v) => setState(() => _scheduledDurationSec = v.toDouble())),
                              _buildPresetChip('5 Menit', 300, _scheduledDurationSec.round(), (v) => setState(() => _scheduledDurationSec = v.toDouble())),
                              _buildPresetChip('10 Menit', 600, _scheduledDurationSec.round(), (v) => setState(() => _scheduledDurationSec = v.toDouble())),
                              _buildPresetChip('15 Menit', 900, _scheduledDurationSec.round(), (v) => setState(() => _scheduledDurationSec = v.toDouble())),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Slider Adaptif (10 Detik - 30 Menit / 1800 Detik)
                        Slider(
                          value: _scheduledDurationSec.clamp(10.0, 1800.0),
                          min: 10,
                          max: 1800,
                          divisions: 36,
                          activeColor: AppColors.primary,
                          inactiveColor: AppColors.secondary.withValues(alpha: 0.4),
                          onChanged: (val) {
                            setState(() {
                              _scheduledDurationSec = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ==========================================
                  // 3. PARAMETER MODE MANUAL (BEBAS + AUTO CUT-OFF)
                  // ==========================================
                  _buildSectionHeader('Mode Manual (Batas Pengaman Auto Cut-Off)', Icons.touch_app_rounded),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppDecorations.raisedCard(radius: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Batas Pengaman Auto Cut-Off',
                                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Clickable Badge Button with Edit Icon
                            GestureDetector(
                              onTap: _showCustomSafetyTimeoutDialog,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.warning,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: AppDecorations.softRaisedShadow,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatDuration(_manualSafetyTimeoutSec.round()),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.edit_note_rounded, color: Colors.white, size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Dalam mode manual, Anda bebas menyalakan dan mematikan pompa kapan saja. Namun jika pompa dibiarkan menyala, sistem akan otomatis mematikannya setelah batas waktu ini untuk mengantisipasi jika Anda lupa.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                        ),
                        const SizedBox(height: 12),

                        // Preset Chips Menit & Detik Pengaman
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _buildPresetChip('30 Detik', 30, _manualSafetyTimeoutSec.round(), (v) => setState(() => _manualSafetyTimeoutSec = v.toDouble())),
                              _buildPresetChip('1 Menit', 60, _manualSafetyTimeoutSec.round(), (v) => setState(() => _manualSafetyTimeoutSec = v.toDouble())),
                              _buildPresetChip('2 Menit', 120, _manualSafetyTimeoutSec.round(), (v) => setState(() => _manualSafetyTimeoutSec = v.toDouble())),
                              _buildPresetChip('5 Menit', 300, _manualSafetyTimeoutSec.round(), (v) => setState(() => _manualSafetyTimeoutSec = v.toDouble())),
                              _buildPresetChip('10 Menit', 600, _manualSafetyTimeoutSec.round(), (v) => setState(() => _manualSafetyTimeoutSec = v.toDouble())),
                              _buildPresetChip('15 Menit', 900, _manualSafetyTimeoutSec.round(), (v) => setState(() => _manualSafetyTimeoutSec = v.toDouble())),
                              _buildPresetChip('30 Menit', 1800, _manualSafetyTimeoutSec.round(), (v) => setState(() => _manualSafetyTimeoutSec = v.toDouble())),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        Slider(
                          value: _manualSafetyTimeoutSec.clamp(10.0, 3600.0),
                          min: 10,
                          max: 3600,
                          divisions: 71,
                          activeColor: AppColors.warning,
                          inactiveColor: AppColors.secondary.withValues(alpha: 0.4),
                          onChanged: (val) => setState(() => _manualSafetyTimeoutSec = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Rain Delay Switch
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: AppDecorations.raisedCard(radius: 18),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Proteksi Hujan (Rain Delay)',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      subtitle: const Text(
                        'Tunda penyiraman otomatis jika sensor presipitasi mendeteksi air hujan.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.primary,
                      value: _rainDelay,
                      onChanged: (val) => setState(() => _rainDelay = val),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bottom Save Button
                  GestureDetector(
                    onTap: _saveSettings,
                    child: Container(
                      height: 52,
                      width: double.infinity,
                      decoration: AppDecorations.primaryButtonDecoration(radius: 26),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Simpan Konfigurasi Parameter',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: AppDecorations.squircleIcon(radius: 8),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip(String label, int targetSeconds, int currentSeconds, ValueChanged<int> onSelect) {
    final bool isSelected = currentSeconds == targetSeconds;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => onSelect(targetSeconds),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
            ),
            boxShadow: AppDecorations.softRaisedShadow,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrequencyChip(String label, int value) {
    final isSelected = _scheduleFrequency == value;
    return GestureDetector(
      onTap: () => setState(() => _scheduleFrequency = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: isSelected
            ? AppDecorations.primaryButtonDecoration(radius: 12)
            : BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: AppDecorations.softRaisedShadow,
              ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimePickerTile(String label, String formattedTime, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white),
          boxShadow: AppDecorations.softRaisedShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formattedTime,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.edit_calendar_rounded, size: 18, color: AppColors.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
