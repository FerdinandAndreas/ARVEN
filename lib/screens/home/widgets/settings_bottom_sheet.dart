import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_decorations.dart';
import '../../../models/device_data_model.dart';
import '../../../providers/device_provider.dart';

class SettingsBottomSheet extends StatefulWidget {
  final DeviceSettings currentSettings;

  const SettingsBottomSheet({super.key, required this.currentSettings});

  @override
  State<SettingsBottomSheet> createState() => _SettingsBottomSheetState();
}

class _SettingsBottomSheetState extends State<SettingsBottomSheet> {
  // Mode Otomatis: Batas Minimum (Menyala) & Batas Maksimum (Mati)
  late double _moistureMin;
  late double _moistureMax;
  late double _soakInterval;
  late bool _rainDelay;

  // Mode Terjadwal
  late int _scheduleFrequency;
  late TimeOfDay _time1;
  late TimeOfDay _time2;
  late TimeOfDay _time3;
  late double _scheduledDurationSec; // dalam detik (bisa menit-menit)

  // Mode Manual: Batas Waktu Pengaman (Auto Cut-off jika lupa)
  late double _manualSafetyTimeoutMin;

  @override
  void initState() {
    super.initState();
    final s = widget.currentSettings;

    _moistureMin = s.moistureThreshold.toDouble().clamp(10.0, 70.0);
    _moistureMax = s.moistureThresholdMax.toDouble().clamp(_moistureMin + 5.0, 95.0);
    _soakInterval = s.soakIntervalMin.toDouble();
    _rainDelay = s.rainDelayEnabled;
    _manualSafetyTimeoutMin = s.manualSafetyTimeoutMin.toDouble().clamp(1.0, 60.0);

    final sc = s.schedule;
    _scheduleFrequency = sc.frequency;
    _time1 = _parseTime(sc.time1, const TimeOfDay(hour: 7, minute: 0));
    _time2 = _parseTime(sc.time2, const TimeOfDay(hour: 16, minute: 30));
    _time3 = _parseTime(sc.time3, const TimeOfDay(hour: 12, minute: 0));
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

  Future<void> _pickTime(int scheduleIndex) async {
    final TimeOfDay initial = scheduleIndex == 1
        ? _time1
        : scheduleIndex == 2
            ? _time2
            : _time3;

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
        if (scheduleIndex == 1) _time1 = picked;
        if (scheduleIndex == 2) _time2 = picked;
        if (scheduleIndex == 3) _time3 = picked;
      });
    }
  }

  // Dialog untuk mengetik langsung durasi dalam Menit & Detik
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
          title: const Text(
            'Ketik Durasi Penyiraman',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tentukan lama pompa menyala pada sesi terjadwal:',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Menit',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
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
                        const Text(
                          'Detik',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
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

  void _saveSettings() {
    final newSettings = DeviceSettings(
      moistureThreshold: _moistureMin.round(),
      moistureThresholdMax: _moistureMax.round(),
      wateringDurationSec: widget.currentSettings.wateringDurationSec,
      soakIntervalMin: _soakInterval.round(),
      maxTemperatureLimit: widget.currentSettings.maxTemperatureLimit,
      rainDelayEnabled: _rainDelay,
      manualSafetyTimeoutMin: _manualSafetyTimeoutMin.round(),
      schedule: DeviceSchedule(
        frequency: _scheduleFrequency,
        time1: _formatTime(_time1),
        time2: _formatTime(_time2),
        time3: _formatTime(_time3),
        durationSec: _scheduledDurationSec.round(),
      ),
    );

    Provider.of<DeviceProvider>(context, listen: false).updateSettings(newSettings);
    Navigator.pop(context);
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
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final double sheetHeight = isLandscape
        ? mediaQuery.size.height * 0.95
        : mediaQuery.size.height * 0.90;
    final bool isCompact = mediaQuery.size.width < 360;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Container(
          height: sheetHeight,
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 16 : 22,
            vertical: 16,
          ),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Konfigurasi Parameter Irigasi',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Otomasi kelembapan tanah, jadwal, dan proteksi manual',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: AppDecorations.squircleIcon(radius: 10),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                      tooltip: 'Tutup',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 12),

              // Scrollable Parameter List
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
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
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.badgeInfoBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_moistureMin.round()}%  -  ${_moistureMax.round()}%',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
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

                          // Indikator Badge Status Min & Max
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

                          // Dual RangeSlider Geser
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

                    // Jeda Peresapan Air (Soak Interval)
                    _buildParameterCard(
                      title: 'Jeda Peresapan Air (Soak Time)',
                      valueString: '${_soakInterval.round()} Menit',
                      description: 'Waktu tunggu air meresap ke perakaran sebelum sensor dievaluasi kembali, mencegah pompa menyala mati berulang.',
                      slider: Slider(
                        value: _soakInterval,
                        min: 5,
                        max: 60,
                        divisions: 11,
                        activeColor: AppColors.primary,
                        inactiveColor: AppColors.secondary.withValues(alpha: 0.4),
                        onChanged: (val) => setState(() => _soakInterval = val),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ==========================================
                    // 2. PARAMETER MODE TERJADWAL
                    // ==========================================
                    _buildSectionHeader('Mode Terjadwal (Waktu & Durasi Menit)', Icons.alarm_rounded),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppDecorations.raisedCard(radius: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Frekuensi Sesi Penyiraman',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: _buildFrequencyChip('2 Kali Sehari', 2)),
                              const SizedBox(width: 10),
                              Expanded(child: _buildFrequencyChip('3 Kali Sehari', 3)),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _buildTimePickerTile('Sesi Pagi', _formatTime(_time1), () => _pickTime(1)),
                          const SizedBox(height: 10),
                          _buildTimePickerTile('Sesi Sore', _formatTime(_time2), () => _pickTime(2)),
                          if (_scheduleFrequency == 3) ...[
                            const SizedBox(height: 10),
                            _buildTimePickerTile('Sesi Siang', _formatTime(_time3), () => _pickTime(3)),
                          ],

                          const SizedBox(height: 18),

                          // Durasi Siram Terjadwal (Slider + Input/Ketik)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text(
                                  'Durasi Penyiraman Terjadwal',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
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
                                _buildDurationPresetChip('30 Detik', 30),
                                _buildDurationPresetChip('1 Menit', 60),
                                _buildDurationPresetChip('2 Menit', 120),
                                _buildDurationPresetChip('5 Menit', 300),
                                _buildDurationPresetChip('10 Menit', 600),
                                _buildDurationPresetChip('15 Menit', 900),
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
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.badgeWarningBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_manualSafetyTimeoutMin.round()} Menit',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.badgeWarningText),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Dalam mode manual, Anda bebas menyalakan dan mematikan pompa kapan saja. Namun jika pompa dibiarkan menyala, sistem akan otomatis mematikannya setelah batas menit ini untuk mengantisipasi jika Anda lupa.',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                          ),
                          const SizedBox(height: 12),

                          // Preset Chips Menit Pengaman
                          Row(
                            children: [
                              _buildSafetyPresetChip(2),
                              const SizedBox(width: 6),
                              _buildSafetyPresetChip(5),
                              const SizedBox(width: 6),
                              _buildSafetyPresetChip(10),
                              const SizedBox(width: 6),
                              _buildSafetyPresetChip(15),
                              const SizedBox(width: 6),
                              _buildSafetyPresetChip(30),
                            ],
                          ),
                          const SizedBox(height: 8),

                          Slider(
                            value: _manualSafetyTimeoutMin,
                            min: 1,
                            max: 30,
                            divisions: 29,
                            activeColor: AppColors.warning,
                            inactiveColor: AppColors.secondary.withValues(alpha: 0.4),
                            onChanged: (val) => setState(() => _manualSafetyTimeoutMin = val),
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
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
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
                  ],
                ),
              ),

              // Save Button
              GestureDetector(
                onTap: _saveSettings,
                child: Container(
                  height: 52,
                  width: double.infinity,
                  decoration: AppDecorations.primaryButtonDecoration(radius: 26),
                  alignment: Alignment.center,
                  child: const Text(
                    'Simpan Konfigurasi Parameter',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
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

  Widget _buildParameterCard({
    required String title,
    required String valueString,
    required String description,
    required Widget slider,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.raisedCard(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.badgeInfoBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  valueString,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          slider,
        ],
      ),
    );
  }

  Widget _buildDurationPresetChip(String label, int seconds) {
    final bool isSelected = _scheduledDurationSec.round() == seconds;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _scheduledDurationSec = seconds.toDouble();
          });
        },
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

  Widget _buildSafetyPresetChip(int minutes) {
    final bool isSelected = _manualSafetyTimeoutMin.round() == minutes;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _manualSafetyTimeoutMin = minutes.toDouble();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.warning : AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.warning : AppColors.cardBorder,
            ),
            boxShadow: AppDecorations.softRaisedShadow,
          ),
          child: Center(
            child: Text(
              '${minutes}m',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
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

  Widget _buildTimePickerTile(String label, String formattedTime, VoidCallback onTap) {
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
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
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
