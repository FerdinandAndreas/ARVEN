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
  // Spesifikasi pompa DC mini: 600 L/jam (~0.1667 L/detik)
  static const double flowRateLph = 600.0;
  static const double flowRateLps = flowRateLph / 3600.0;
  static const double dailyTargetLiters = 40.0;

  // Warna teks sekunder di atas gradient hero (#2563EB -> #1D4ED8) agar rasio kontras >= 4.75:1
  static const Color _heroCaptionColor = Color(0xFFEFF6FF);

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
    if (oldWidget.device.pumpState.active != widget.device.pumpState.active ||
        oldWidget.device.pumpState.lastStarted != widget.device.pumpState.lastStarted) {
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
      _liveTimer = Timer.periodic(const Duration(seconds: 1), (_) {
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

  double _calculateLiters(int totalSeconds) => totalSeconds * flowRateLps;

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

  String _formatModeLabel(String mode) {
    switch (mode) {
      case 'auto_moisture':
        return 'Otomatis';
      case 'scheduled':
        return 'Terjadwal';
      default:
        return 'Manual';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pump = widget.device.pumpState;
    final bool isPumpActive = pump.active;

    // Hitung akumulasi penyiraman mulai pukul 00:00 waktu perangkat
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

    final double targetPercent = (totalWaterToday / dailyTargetLiters).clamp(0.0, 1.0);
    final int todaySessions = todayLogs.length + (isPumpActive ? 1 : 0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final bool isCompact = width < 360;
        final bool isNarrowSpec = width < 440;
        final bool isTablet = width >= 780;
        final double hPadding = isCompact ? 14 : (isTablet ? 24 : 20);

        final Widget leftColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLiveFlowHeroCard(isPumpActive, isCompact),
            SizedBox(height: isCompact ? 14 : 18),
            _buildDailySummaryCard(
              totalWaterToday: totalWaterToday,
              totalSecondsToday: totalSecondsToday,
              todaySessions: todaySessions,
              targetPercent: targetPercent,
              isCompact: isCompact,
              isNarrowSpec: isNarrowSpec,
            ),
          ],
        );

        final Widget logSection = _buildIrrigationExecutionLog(isCompact);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(hPadding, 10, hPadding, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPageHeader(isPumpActive, isCompact),
              SizedBox(height: isCompact ? 14 : 18),
              if (isTablet)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: leftColumn),
                    const SizedBox(width: 18),
                    Expanded(flex: 6, child: logSection),
                  ],
                )
              else ...[
                leftColumn,
                const SizedBox(height: 18),
                logSection,
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageHeader(bool isPumpActive, bool isCompact) {
    final Color badgeBg = isPumpActive ? AppColors.badgeInfoBg : AppColors.surfaceWhite;
    final Color badgeTextColor = isPumpActive ? AppColors.primaryDark : AppColors.textSecondary;
    final Color badgeBorder = isPumpActive ? AppColors.primary.withValues(alpha: 0.28) : AppColors.cardBorder;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monitoring Irigasi',
                style: TextStyle(
                  fontSize: isCompact ? 18 : 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Debit aliran pompa 600 L/jam dan catatan eksekusi harian',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Semantics(
          label: isPumpActive ? 'Status pompa sedang menyiram' : 'Status pompa siaga',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: badgeBorder, width: 1.0),
            ),
            child: Text(
              isPumpActive ? 'MENYIRAM' : 'STANDBY',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
                color: badgeTextColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveFlowHeroCard(bool isPumpActive, bool isCompact) {
    final double liveLiters = _calculateLiters(_liveElapsedSeconds);
    final String activeModeLabel = _formatModeLabel(widget.device.activeMode);

    if (isPumpActive) {
      // Gunakan gradient primary -> primaryDark (bukan warna muda #5CA3FE) agar kontras teks putih >= 5.17:1 di seluruh area
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(isCompact ? 16 : 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppDecorations.blueGlowShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.0),
                  ),
                  child: const Icon(
                    Icons.water_drop_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pompa Sedang Menyiram',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Mode $activeModeLabel aktif mengalirkan air',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _heroCaptionColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.28), width: 1.0),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.speed_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 5),
                      Text(
                        '10 L/mnt',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _buildHeroMetricColumn(
                    label: 'Air Keluar Sesi Ini',
                    value: '+${_formatVolume(liveLiters)}',
                    isCompact: isCompact,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHeroMetricColumn(
                    label: 'Durasi Berjalan',
                    value: _formatDuration(_liveElapsedSeconds),
                    isCompact: isCompact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Semantics(
              button: true,
              label: 'Hentikan pompa sekarang',
              child: Material(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () {
                    widget.deviceProvider.forceTurnOffPump();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Pompa berhasil dimatikan dan disinkronkan ke Firebase.'),
                        backgroundColor: AppColors.badgeDangerText,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 46),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.0),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.stop_rounded, color: Colors.white, size: 19),
                        SizedBox(width: 6),
                        Text(
                          'Hentikan Pompa Sekarang',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final int lastDur = widget.device.pumpState.lastDurationSec;
    final double lastLit = _calculateLiters(lastDur > 0 ? lastDur : 0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: AppDecorations.raisedCard(radius: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.badgeInfoBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder, width: 1.0),
            ),
            child: const Icon(
              Icons.water_drop_outlined,
              color: AppColors.primaryDark,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Aliran Air: 0 L/jam',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.cardBorder, width: 0.8),
                      ),
                      child: Text(
                        'Mode $activeModeLabel',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  lastDur > 0
                      ? 'Sesi terakhir mengalirkan ${_formatVolume(lastLit)} dalam ${_formatDuration(lastDur)}.'
                      : 'Pompa dalam keadaan mati dan siap menyiram sesuai mode aktif.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMetricColumn({
    required String label,
    required String value,
    required bool isCompact,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: _heroCaptionColor,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontSize: isCompact ? 24 : 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailySummaryCard({
    required double totalWaterToday,
    required int totalSecondsToday,
    required int todaySessions,
    required double targetPercent,
    required bool isCompact,
    required bool isNarrowSpec,
  }) {
    final bool targetMet = targetPercent >= 1.0;
    final bool rainDelayEnabled = widget.device.settings.rainDelayEnabled;
    final String rainLabel = rainDelayEnabled ? 'Aktif' : 'Nonaktif';

    final Widget durationTile = _buildSpecTile(
      icon: Icons.timer_outlined,
      iconColor: AppColors.primaryDark,
      label: 'Durasi Aktif',
      value: _formatDuration(totalSecondsToday),
    );
    final Widget flowTile = _buildSpecTile(
      icon: Icons.speed_rounded,
      iconColor: AppColors.primaryDark,
      label: 'Kapasitas Debit',
      value: '600 L/jam',
    );
    final IconData rainIcon = rainDelayEnabled ? Icons.umbrella_rounded : Icons.umbrella_outlined;
    final Color rainIconColor = rainDelayEnabled ? AppColors.badgeSuccessText : AppColors.textSecondary;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: AppDecorations.raisedCard(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.badgeInfoBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder, width: 1.0),
                ),
                child: const Icon(
                  Icons.water_drop_rounded,
                  color: AppColors.primaryDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Konsumsi Air Hari Ini',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _formatVolume(totalWaterToday),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: todaySessions > 0 ? AppColors.badgeInfoBg : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: todaySessions > 0 ? AppColors.primary.withValues(alpha: 0.25) : AppColors.cardBorder,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '$todaySessions sesi',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: todaySessions > 0 ? AppColors.primaryDark : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress terhadap batas referensi harian 40 L
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Target Harian (${_formatVolume(dailyTargetLiters)})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: targetMet ? AppColors.badgeSuccessBg : AppColors.badgeInfoBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${(targetPercent * 100).toStringAsFixed(0)}% tercapai',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: targetMet ? AppColors.badgeSuccessText : AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: targetPercent,
              minHeight: 7,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(
                targetMet ? AppColors.badgeSuccessText : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 14),

          if (isNarrowSpec)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(child: durationTile),
                    const SizedBox(width: 10),
                    Expanded(child: flowTile),
                  ],
                ),
                const SizedBox(height: 10),
                _buildSpecTile(
                  icon: rainIcon,
                  iconColor: rainIconColor,
                  label: 'Proteksi Sensor Hujan',
                  value: '$rainLabel (Tunda siram otomatis saat hujan)',
                  isHorizontal: true,
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(child: durationTile),
                const SizedBox(width: 10),
                Expanded(child: flowTile),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSpecTile(
                    icon: rainIcon,
                    iconColor: rainIconColor,
                    label: 'Proteksi Hujan',
                    value: rainLabel,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSpecTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool isHorizontal = false,
  }) {
    final Widget iconBox = Icon(icon, color: iconColor, size: 19);

    if (isHorizontal) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder, width: 0.9),
        ),
        child: Row(
          children: [
            iconBox,
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 0.9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          iconBox,
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildIrrigationExecutionLog(bool isCompact) {
    final historyList = widget.deviceProvider.historyList;
    final bool isSyncing = widget.deviceProvider.isSyncing;
    final String? errorMessage = widget.deviceProvider.errorMessage;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: AppDecorations.raisedCard(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Riwayat Eksekusi Penyiraman',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (historyList.isNotEmpty) ...[
                Semantics(
                  button: true,
                  label: 'Reset semua log penyiraman',
                  child: Material(
                    color: AppColors.badgeDangerBg,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: _showResetConfirmationDialog,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        alignment: Alignment.center,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 15, color: AppColors.badgeDangerText),
                            SizedBox(width: 4),
                            Text(
                              'Reset',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.badgeDangerText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder, width: 0.9),
                ),
                child: Text(
                  '${historyList.length} log',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (errorMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.badgeDangerBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.badgeDangerText.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.badgeDangerText),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gagal Memuat Data Perangkat',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.badgeDangerText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$errorMessage. Periksa koneksi internet Anda lalu tarik layar ke bawah untuk memuat ulang.',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.badgeDangerText,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (isSyncing && historyList.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28, horizontal: 12),
              child: Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Menyelaraskan riwayat penyiraman...',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (historyList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 12),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder, width: 0.9),
                      ),
                      child: const Icon(
                        Icons.history_toggle_off_rounded,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 12),
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
                      'Catatan volume air dan durasi akan muncul otomatis setelah pompa selesai menjalankan satu siklus siram.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...historyList.take(20).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == historyList.length - 1 || index == 19;

              return _buildLogItem(item, isLast);
            }),
        ],
      ),
    );
  }

  Widget _buildLogItem(IrrigationHistoryItem item, bool isLast) {
    final date = DateTime.fromMillisecondsSinceEpoch(item.timestamp);
    final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} WIB';

    Color statusBg = AppColors.badgeSuccessBg;
    Color statusColor = AppColors.badgeSuccessText;
    Widget statusGlyph = const Icon(Icons.check_rounded, size: 15, color: AppColors.badgeSuccessText);

    if (item.status.contains('Cut-Off') || item.status.contains('Dihentikan')) {
      statusBg = AppColors.badgeInfoBg;
      statusColor = AppColors.primaryDark;
      statusGlyph = const Icon(Icons.stop_rounded, size: 15, color: AppColors.primaryDark);
    } else if (item.status.contains('Hujan')) {
      statusBg = AppColors.badgeWarningBg;
      statusColor = AppColors.badgeWarningText;
      statusGlyph = const Icon(
        Icons.grain_rounded,
        color: AppColors.badgeWarningText,
        size: 16,
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: statusGlyph),
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
                        const SizedBox(width: 8),
                        Text(
                          timeStr,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_formatVolume(item.waterLiters)} • ${_formatDuration(item.durationSec)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.status,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (item.soilBefore > 0 || item.soilAfter > 0) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Kelembapan tanah: ${item.soilBefore.toStringAsFixed(0)}% \u2192 ${item.soilAfter.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 11.5,
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
        if (!isLast) const Divider(color: AppColors.divider, height: 12),
      ],
    );
  }

  void _showResetConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.badgeDangerText),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Reset Semua Statistik?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        content: const Text(
          'Tindakan ini akan mengosongkan riwayat penyiraman di Firebase dan mengembalikan akumulasi air ke 0.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(64, 44)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(96, 44),
              backgroundColor: AppColors.badgeDangerText,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              widget.deviceProvider.resetAllStatistics();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Statistik dan riwayat penyiraman berhasil di-reset.'),
                  backgroundColor: AppColors.badgeDangerText,
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
