import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_decorations.dart';
import '../../../models/device_data_model.dart';
import '../../../providers/device_provider.dart';

class PumpStatusCard extends StatelessWidget {
  final DeviceData device;
  final DeviceProvider provider;

  const PumpStatusCard({
    super.key,
    required this.device,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final pump = device.pumpState;
    final isPumpActive = pump.active;
    final activeMode = device.activeMode;
    final safetyTimeout = device.settings.manualSafetyTimeoutMin;

    String modeLabel = 'Otomatis (Sensor)';
    if (activeMode == 'manual') {
      modeLabel = 'Manual (Bebas Operator)';
    } else if (activeMode == 'scheduled') {
      modeLabel = 'Terjadwal';
    }

    String nextScheduleInfo = 'Berdasarkan ambang kelembapan';
    if (activeMode == 'scheduled') {
      nextScheduleInfo = '${device.settings.schedule.time1} & ${device.settings.schedule.time2}';
    } else if (activeMode == 'manual') {
      nextScheduleInfo = 'Sesuai instruksi operator';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: isPumpActive
          ? BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.primaryLight, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                ...AppDecorations.raisedShadow,
              ],
            )
          : AppDecorations.raisedCard(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with flexible text to prevent overflow
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Status Aktuator Irigasi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPumpActive ? AppColors.badgeSuccessBg : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isPumpActive
                        ? AppColors.badgeSuccessText.withValues(alpha: 0.3)
                        : AppColors.cardBorder,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isPumpActive ? AppColors.success : AppColors.textLight,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isPumpActive ? 'Aktif Menyiram' : 'Mode Siaga',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isPumpActive
                            ? AppColors.badgeSuccessText
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Primary State Container
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: isPumpActive
                    ? BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppDecorations.blueGlowShadow,
                      )
                    : AppDecorations.squircleIcon(radius: 16),
                child: Icon(
                  isPumpActive ? Icons.water_rounded : Icons.power_settings_new_rounded,
                  color: isPumpActive ? Colors.white : AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPumpActive ? 'Pompa Sedang Menyiram' : 'Pompa Air Siaga (Standby)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isPumpActive ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isPumpActive
                          ? 'Katup irigasi terbuka, mendistribusikan air perakaran'
                          : 'Sistem standby, memonitor trigger ambang batas & jadwal',
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
          const SizedBox(height: 16),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 14),

          // Telemetry details with responsive flex
          _buildDetailRow('Mode Operasi', modeLabel),
          const SizedBox(height: 8),
          _buildDetailRow(
            'Aktivitas Terakhir',
            '${pump.lastDurationSec}s (${_formatLastStarted(pump.lastStarted)})',
          ),
          const SizedBox(height: 8),
          _buildDetailRow('Penyiraman Berikutnya', nextScheduleInfo),
          const SizedBox(height: 8),
          _buildDetailRow('Batas Pengaman Manual', '$safetyTimeout Menit (Auto Cut-Off)'),

          const SizedBox(height: 18),

          // Action Buttons: Nyalakan Pompa & Hentikan Pompa (Disabled saat bukan mode manual)
          Builder(
            builder: (context) {
              final bool isManual = activeMode == 'manual';

              return Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: GestureDetector(
                      onTap: (isManual && !isPumpActive)
                          ? () {
                              provider.toggleManualPump(true);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Perintah pompa manual ON dikirim (Auto cut-off aman: $safetyTimeout menit).'),
                                  backgroundColor: AppColors.primary,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 48,
                        decoration: (isManual && !isPumpActive)
                            ? AppDecorations.primaryButtonDecoration(radius: 14)
                            : BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                              ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.play_arrow_rounded,
                              color: (isManual && !isPumpActive) ? Colors.white : const Color(0xFF94A3B8),
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Nyalakan Pompa',
                                style: TextStyle(
                                  color: (isManual && !isPumpActive) ? Colors.white : const Color(0xFF94A3B8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 5,
                    child: GestureDetector(
                      onTap: (isManual && isPumpActive)
                          ? () {
                              provider.toggleManualPump(false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Perintah stop pompa manual dikirim ke sistem.'),
                                  backgroundColor: AppColors.danger,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 48,
                        decoration: (isManual && isPumpActive)
                            ? BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                                    offset: const Offset(0, 4),
                                    blurRadius: 12,
                                    spreadRadius: 0,
                                  ),
                                ],
                              )
                            : BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                              ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.stop_rounded,
                              color: (isManual && isPumpActive) ? Colors.white : const Color(0xFF94A3B8),
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Hentikan Pompa',
                                style: TextStyle(
                                  color: (isManual && isPumpActive) ? Colors.white : const Color(0xFF94A3B8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),

          // Safety Hint Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder, width: 0.8),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Operasi manual bebas waktu. Fitur keselamatan akan mematikan pompa otomatis jika lupa setelah $safetyTimeout menit.',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatLastStarted(DateTime? dt) {
    if (dt == null) return 'Hari ini';
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
