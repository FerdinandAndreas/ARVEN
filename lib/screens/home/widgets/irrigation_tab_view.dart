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
  // Karakteristik pompa mini: 600 Liter / jam (~0.1667 Liter / detik)
  static const double flowRateLph = 600.0;
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
    final bool isPumpActive = pump.active;

    // Filter riwayat hari ini dari tengah malam
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final todayLogs = widget.deviceProvider.historyList.where((item) => item.timestamp >= startOfToday).toList();

    int totalSecondsToday = 0;
    double totalWaterToday = 0.0;
    for (final log in todayLogs) {
      totalSecondsToday += log.durationSec;
      totalWaterToday += log.waterLiters;
    }

    if (isPumpActive) {
      totalSecondsToday += _liveElapsedSeconds;
      totalWaterToday += _calculateLiters(_liveElapsedSeconds);
    }

    // Target wajar air tanaman harian (40 L)
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
                  _buildWaterMetricsGrid(
                    totalWaterToday,
                    totalSecondsToday,
                    todayLogs.length + (isPumpActive ? 1 : 0),
                    isCompact,
                  ),
                  const SizedBox(height: 18),

                  // ==========================================
                  // TARGET & PROGRESS AIR HARIAN TANAMAN
                  // ==========================================
                  _buildWaterTargetCard(totalWaterToday, dailyTargetLiters, targetPercent),
                  const SizedBox(height: 20),

                  // ==========================================
                  // LOG RIWAYAT PENYIRAMAN DETAIL
                  // ==========================================
                  _buildIrrigationExecutionLog(),
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
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () {
                widget.deviceProvider.toggleManualPump(false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Pompa berhasil dimatikan & disinkronkan ke Firebase.'),
                    backgroundColor: AppColors.danger,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.stop_circle_outlined, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Hentikan Pompa Sekarang',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Standby State
    final int lastDur = widget.device.pumpState.lastDurationSec;
    final double lastLit = _calculateLiters(lastDur > 0 ? lastDur : 0);

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
                  lastDur > 0
                      ? 'Sesi terakhir mengalirkan ~${_formatVolume(lastLit)} air dalam ${_formatDuration(lastDur)}.'
                      : 'Sistem siap menyiram. Pompa dalam keadaan mati (0 L/jam).',
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
  Widget _buildWaterMetricsGrid(double totalWaterToday, int totalSecondsToday, int todaySessions, bool isCompact) {
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
                subtitle: '$todaySessions sesi penyiraman',
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
                subtitle: totalSecondsToday > 0 ? 'Akumulasi pompa ON' : 'Belum aktif hari ini',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                icon: Icons.eco_rounded,
                iconColor: const Color(0xFF10B981),
                iconBgColor: const Color(0xFFECFDF5),
                title: 'Proteksi Hujan',
                value: widget.device.settings.rainDelayEnabled ? 'Aktif' : 'Nonaktif',
                subtitle: 'Tunda saat hujan',
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

  // 4. Log Riwayat Eksekusi Penyiraman (Data Nyata dari Firebase Realtime Database)
  Widget _buildIrrigationExecutionLog() {
    final historyList = widget.deviceProvider.historyList;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.raisedCard(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.history_rounded, size: 18, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'Riwayat Eksekusi Penyiraman',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (historyList.isNotEmpty)
                    GestureDetector(
                      onTap: () => _showResetConfirmationDialog(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.delete_sweep_rounded, size: 13, color: AppColors.danger),
                            SizedBox(width: 4),
                            Text(
                              'Reset Log',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.badgeInfoBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${historyList.length} Log',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tampilkan Empty State jika belum ada riwayat penyiraman di Firebase
          if (historyList.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.history_toggle_off_rounded, size: 24, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Belum Ada Riwayat Penyiraman',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Riwayat akan otomatis tercatat di Firebase saat pompa selesai menyiram tanaman.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            )
          else
            ...historyList.take(20).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == historyList.length - 1 || index == 19;

              final date = DateTime.fromMillisecondsSinceEpoch(item.timestamp);
              final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} WIB';

              Color statusBg = AppColors.badgeSuccessBg;
              Color statusColor = AppColors.badgeSuccessText;
              if (item.status.contains('Cut-Off') || item.status.contains('Dihentikan')) {
                statusBg = const Color(0xFFEFF6FF);
                statusColor = const Color(0xFF1D4ED8);
              } else if (item.status.contains('Hujan')) {
                statusBg = AppColors.badgeWarningBg;
                statusColor = AppColors.badgeWarningText;
              }

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
                            color: statusBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.water_drop_rounded,
                            size: 16,
                            color: statusColor,
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
                                      item.title,
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
                                    timeStr,
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
                                    'Air: ${_formatVolume(item.waterLiters)} • Durasi: ${_formatDuration(item.durationSec)}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item.status,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (item.soilBefore > 0 || item.soilAfter > 0) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Kelembapan tanah: ${item.soilBefore.toStringAsFixed(0)}% → ${item.soilAfter.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
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

  void _showResetConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger),
            SizedBox(width: 8),
            Text('Reset Semua Statistik?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Text(
          'Tindakan ini akan mengosongkan riwayat penyiraman di Firebase dan mengembalikan akumulasi air ke 0.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              widget.deviceProvider.resetAllStatistics();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Seluruh statistik dan riwayat Firebase berhasil di-reset ke 0.'),
                  backgroundColor: AppColors.danger,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            child: const Text('Reset Sekarang', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
