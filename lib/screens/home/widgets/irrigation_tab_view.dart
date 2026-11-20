import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_decorations.dart';
import '../../../models/device_data_model.dart';
import '../../../providers/device_provider.dart';

class IrrigationTabView extends StatefulWidget {
  final DeviceData device;
  final DeviceProvider deviceProvider;

  const IrrigationTabView({
    super.key,
    required this.device,
    required this.deviceProvider,
  });

  @override
  State<IrrigationTabView> createState() => _IrrigationTabViewState();
}

class _IrrigationTabViewState extends State<IrrigationTabView> {
  // Karakteristik pompa mini: 600 Liter / jam = 10 Liter / menit = 0.1667 Liter / detik
  static const double flowRateLph = 600.0;
  static const double flowRateLpm = flowRateLph / 60.0; // 10 L/menit
  static const double flowRateLps = flowRateLph / 3600.0; // ~0.1667 L/detik

  Timer? _liveTimer;
  int _liveElapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _checkLiveTimer();
  }

  @override
  void didUpdateWidget(covariant IrrigationTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.device.pumpState.active != widget.device.pumpState.active) {
      _checkLiveTimer();
    }
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }

  void _checkLiveTimer() {
    final pump = widget.device.pumpState;
    if (pump.active) {
      if (pump.lastStarted != null) {
        _liveElapsedSeconds = DateTime.now().difference(pump.lastStarted!).inSeconds.clamp(0, 7200);
      } else {
        _liveElapsedSeconds = 0;
      }
      _liveTimer?.cancel();
      _liveTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _liveElapsedSeconds++;
          });
        }
      });
    } else {
      _liveTimer?.cancel();
      _liveTimer = null;
      _liveElapsedSeconds = 0;
    }
  }

  double _calculateLiters(int totalSeconds) {
    return totalSeconds * flowRateLps;
  }

  String _formatVolume(double liters) {
    if (liters < 1.0) {
      return '${(liters * 1000).toStringAsFixed(0)} mL';
    }
    return '${liters.toStringAsFixed(1)} L';
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds < 60) {
      return '$totalSeconds dtk';
    }
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (seconds == 0) {
      return '$minutes mnt';
    }
    return '$minutes mnt $seconds dtk';
  }

  @override
  Widget build(BuildContext context) {
    final pump = widget.device.pumpState;
    final sched = widget.device.settings.schedule;
    final bool isPumpActive = pump.active;

    // Estimasi akumulasi hari ini
    final int scheduledRunSec = (sched.frequency * sched.durationSec);
    final int manualLastSec = pump.lastDurationSec > 0 ? pump.lastDurationSec : 0;
    final int totalSecondsToday = scheduledRunSec + manualLastSec + (_liveElapsedSeconds);
    final double totalWaterToday = _calculateLiters(totalSecondsToday);

    // Target wajar air tanaman harian (misal 35 - 40 L)
    const double dailyTargetLiters = 40.0;
    final double targetPercent = (totalWaterToday / dailyTargetLiters).clamp(0.0, 1.0);

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
                  // Page Title & Subtitle Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monitoring & Konsumsi Air',
                              style: TextStyle(
                                fontSize: isCompact ? 18 : 21,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Estimasi debit pompa 600 L/jam (10 L/mnt) & log eksekusi',
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isPumpActive ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isPumpActive ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isPumpActive ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isPumpActive ? 'MENYIRAM' : 'STANDBY',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: isPumpActive ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // ==========================================
                  // HERO CARD: STATUS ALIRAN POMPA REALTIME
                  // ==========================================
                  _buildLiveFlowHeroCard(isPumpActive, isCompact),
                  const SizedBox(height: 18),

                  // ==========================================
                  // GRID METRIK KONSUMSI AIR (4 KARTU 2x2)
                  // ==========================================
                  _buildWaterMetricsGrid(totalWaterToday, totalSecondsToday, isCompact),
                  const SizedBox(height: 18),

                  // ==========================================
                  // TARGET & PROGRESS AIR HARIAN TANAMAN
                  // ==========================================
                  _buildWaterTargetCard(totalWaterToday, dailyTargetLiters, targetPercent),
                  const SizedBox(height: 20),

                  // ==========================================
                  // LOG RIWAYAT PENYIRAMAN DETAIL
                  // ==========================================
                  _buildIrrigationExecutionLog(sched),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 1. Hero Card: Status Aliran Pompa
  Widget _buildLiveFlowHeroCard(bool isPumpActive, bool isCompact) {
    final double liveLiters = _calculateLiters(_liveElapsedSeconds);

    if (isPumpActive) {
      return Container(
        padding: EdgeInsets.all(isCompact ? 16 : 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.35),
              offset: const Offset(0, 8),
              blurRadius: 20,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pompa Sedang Menyiram',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Aliran air aktif mengalir ke perakaran',
                          style: TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.speed_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        '10 L/mnt',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Live metrics display
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Air Keluar Sesi Ini', style: TextStyle(fontSize: 11.5, color: Colors.white70)),
                      const SizedBox(height: 2),
                      Text(
                        '+${_formatVolume(liveLiters)}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Durasi Berjalan', style: TextStyle(fontSize: 11.5, color: Colors.white70)),
                      const SizedBox(height: 2),
                      Text(
                        _formatDuration(_liveElapsedSeconds),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Standby State
    final int lastDur = widget.device.pumpState.lastDurationSec;
    final double lastLit = _calculateLiters(lastDur > 0 ? lastDur : 120);

    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: AppDecorations.raisedCard(radius: 22),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEFF6FF),
              border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
            ),
            child: const Icon(Icons.water_drop_outlined, color: Color(0xFF2563EB), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aliran Air: 0 L/jam (Siaga)',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Sesi terakhir mengalirkan ~${_formatVolume(lastLit)} air dalam ${_formatDuration(lastDur > 0 ? lastDur : 120)}.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. Grid Metrik Konsumsi Air (4 Cards 2x2)
  Widget _buildWaterMetricsGrid(double totalWaterToday, int totalSecondsToday, bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistik Air Hari Ini',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                icon: Icons.water_drop_rounded,
                iconColor: const Color(0xFF2563EB),
                iconBgColor: const Color(0xFFEFF6FF),
                title: 'Total Air Hari Ini',
                value: _formatVolume(totalWaterToday),
                subtitle: '~${widget.device.settings.schedule.frequency} sesi penyiraman',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                icon: Icons.speed_rounded,
                iconColor: const Color(0xFF0284C7),
                iconBgColor: const Color(0xFFF0F9FF),
                title: 'Kapasitas Debit',
                value: '600 L/jam',
                subtitle: '10 L/mnt (Pompa Mini)',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                icon: Icons.timer_outlined,
                iconColor: const Color(0xFF6366F1),
                iconBgColor: const Color(0xFFEEF2FF),
                title: 'Total Durasi Aktif',
                value: _formatDuration(totalSecondsToday),
                subtitle: 'Akumulasi pompa ON',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                icon: Icons.eco_rounded,
                iconColor: const Color(0xFF10B981),
                iconBgColor: const Color(0xFFECFDF5),
                title: 'Efisiensi Hujan',
                value: 'Hemat 20 L',
                subtitle: 'Proteksi Rain Delay',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.raisedCard(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 17),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // 3. Target Kebutuhan Air Harian
  Widget _buildWaterTargetCard(double totalWaterToday, double targetLiters, double percent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.raisedCard(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Estimasi Kebutuhan Air Tanaman',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.badgeSuccessBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${(percent * 100).toStringAsFixed(0)}% Tercapai',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.badgeSuccessText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Terpakai: ${_formatVolume(totalWaterToday)}',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              Text(
                'Target: ${_formatVolume(targetLiters)} / hari',
                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. Log Riwayat Eksekusi Penyiraman
  Widget _buildIrrigationExecutionLog(DeviceSchedule sched) {
    final double scheduledLiters = _calculateLiters(sched.durationSec > 0 ? sched.durationSec : 120);

    final logs = [
      {
        'title': 'Sesi Sore (Terjadwal)',
        'time': sched.time2.isNotEmpty ? '${sched.time2} WIB' : '16:30 WIB',
        'duration': _formatDuration(sched.durationSec > 0 ? sched.durationSec : 120),
        'water': _formatVolume(scheduledLiters),
        'status': 'Selesai',
        'statusColor': AppColors.badgeSuccessText,
        'statusBg': AppColors.badgeSuccessBg,
        'detail': 'Kelembapan tanah: 34% → 82%',
      },
      {
        'title': 'Sesi Otomatis Kelembapan',
        'time': '13:15 WIB',
        'duration': '1 mnt 30 dtk',
        'water': _formatVolume(_calculateLiters(90)),
        'status': 'Auto Cut-Off',
        'statusColor': const Color(0xFF1D4ED8),
        'statusBg': const Color(0xFFEFF6FF),
        'detail': 'Pemicu kelembapan tanah ≤ 40%',
      },
      {
        'title': 'Sesi Siang (Proteksi Hujan)',
        'time': '11:45 WIB',
        'duration': '0 dtk',
        'water': 'Hemat ~20 L',
        'status': 'Tunda Hujan',
        'statusColor': AppColors.badgeWarningText,
        'statusBg': AppColors.badgeWarningBg,
        'detail': 'Sensor mendeteksi presipitasi air hujan',
      },
      {
        'title': 'Sesi Pagi (Terjadwal)',
        'time': sched.time1.isNotEmpty ? '${sched.time1} WIB' : '07:00 WIB',
        'duration': _formatDuration(sched.durationSec > 0 ? sched.durationSec : 120),
        'water': _formatVolume(scheduledLiters),
        'status': 'Selesai',
        'statusColor': AppColors.badgeSuccessText,
        'statusBg': AppColors.badgeSuccessBg,
        'detail': 'Penyegaran perakaran pagi hari',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.raisedCard(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Riwayat Eksekusi Penyiraman',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.badgeInfoBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Hari Ini',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Log list items
          ...logs.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == logs.length - 1;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 3),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: (item['statusBg'] as Color),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.water_drop_rounded,
                          size: 16,
                          color: (item['statusColor'] as Color),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item['title'] as String,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  item['time'] as String,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Air: ${item['water']} • Durasi: ${item['duration']}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: item['statusBg'] as Color,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item['status'] as String,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: item['statusColor'] as Color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['detail'] as String,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  const Divider(color: Color(0xFFF1F5F9), height: 14),
              ],
            );
          }),
        ],
      ),
    );
  }
}
