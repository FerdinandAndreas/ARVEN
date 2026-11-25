import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_decorations.dart';
import '../../../models/device_data_model.dart';

/// Kartu terstruktur telemetri lingkungan dengan hierarki kelembapan tanah sebagai metrik utama
/// dan strip 3 sensor pendukung (suhu udara, kelembapan udara, deteksi hujan).
class EnvironmentConditionsCard extends StatelessWidget {
  final DeviceData device;

  const EnvironmentConditionsCard({
    super.key,
    required this.device,
  });

  @override
  Widget build(BuildContext context) {
    final s = device.sensors;
    final int minThreshold = device.settings.moistureThreshold;
    final int maxThreshold = device.settings.moistureThresholdMax;
    final bool rainDelayEnabled = device.settings.rainDelayEnabled;

    // 1. Evaluasi kelembapan tanah terhadap rentang ambang batas
    final String soilBadge;
    final Color soilBadgeBg;
    final Color soilBadgeText;
    final Color soilProgressColor;
    final String soilRangeNote;

    if (s.soilMoisture < minThreshold) {
      soilBadge = 'Kering';
      soilBadgeBg = AppColors.badgeDangerBg;
      soilBadgeText = AppColors.badgeDangerText;
      soilProgressColor = AppColors.badgeDangerText;
      soilRangeNote = 'Di bawah batas min. $minThreshold%';
    } else if (s.soilMoisture > maxThreshold) {
      soilBadge = 'Basah';
      soilBadgeBg = AppColors.badgeInfoBg;
      soilBadgeText = AppColors.primaryDark;
      soilProgressColor = AppColors.primary;
      soilRangeNote = 'Di atas batas maks. $maxThreshold%';
    } else {
      soilBadge = 'Ideal';
      soilBadgeBg = AppColors.badgeSuccessBg;
      soilBadgeText = AppColors.badgeSuccessText;
      soilProgressColor = AppColors.badgeSuccessText;
      soilRangeNote = 'Target optimal $minThreshold% - $maxThreshold%';
    }

    // 2. Evaluasi suhu udara
    final bool isTempIdeal = s.temperature >= 20.0 && s.temperature <= device.settings.maxTemperatureLimit;
    final String tempStatus = isTempIdeal
        ? 'Normal'
        : (s.temperature > device.settings.maxTemperatureLimit ? 'Tinggi' : 'Rendah');
    final Color tempStatusBg = isTempIdeal
        ? AppColors.badgeSuccessBg
        : (s.temperature > device.settings.maxTemperatureLimit ? AppColors.badgeWarningBg : AppColors.badgeInfoBg);
    final Color tempStatusText = isTempIdeal
        ? AppColors.badgeSuccessText
        : (s.temperature > device.settings.maxTemperatureLimit ? AppColors.badgeWarningText : AppColors.primaryDark);

    // 3. Evaluasi kelembapan udara
    final bool isHumidNormal = s.humidity >= 50.0 && s.humidity <= 85.0;
    final String humidStatus = isHumidNormal ? 'Normal' : (s.humidity > 85.0 ? 'Lembap' : 'Rendah');
    final Color humidStatusBg = isHumidNormal
        ? AppColors.badgeSuccessBg
        : (s.humidity > 85.0 ? AppColors.badgeInfoBg : AppColors.badgeWarningBg);
    final Color humidStatusText = isHumidNormal
        ? AppColors.badgeSuccessText
        : (s.humidity > 85.0 ? AppColors.primaryDark : AppColors.badgeWarningText);

    // 4. Evaluasi deteksi hujan (hindari kata "Kering" agar tidak rancu dengan kelembapan tanah)
    final String rainValue = s.rain ? 'Hujan' : 'Cerah';
    final String rainStatus = s.rain
        ? (rainDelayEnabled ? 'Siram Ditunda' : 'Terdeteksi')
        : 'Tidak Hujan';
    final Color rainStatusBg = s.rain ? AppColors.badgeWarningBg : AppColors.badgeSuccessBg;
    final Color rainStatusText = s.rain ? AppColors.badgeWarningText : AppColors.badgeSuccessText;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final bool isCompact = width < 340;
        final bool isNarrowStrip = width < 400;

        final Widget tempTile = _EnvironmentSubTile(
          icon: Icons.thermostat_rounded,
          iconColor: AppColors.primaryDark,
          label: 'Suhu Udara',
          value: '${s.temperature.toStringAsFixed(1)} °C',
          statusText: tempStatus,
          statusBg: tempStatusBg,
          statusColor: tempStatusText,
        );

        final Widget humidTile = _EnvironmentSubTile(
          icon: Icons.cloud_outlined,
          iconColor: AppColors.primaryDark,
          label: 'Kelembapan Udara',
          value: '${s.humidity.toStringAsFixed(0)}%',
          statusText: humidStatus,
          statusBg: humidStatusBg,
          statusColor: humidStatusText,
        );

        final Widget rainTile = _EnvironmentSubTile(
          icon: s.rain ? Icons.grain_rounded : Icons.wb_sunny_rounded,
          iconColor: s.rain ? AppColors.badgeWarningText : AppColors.primaryDark,
          label: 'Deteksi Hujan',
          value: rainValue,
          statusText: rainStatus,
          statusBg: rainStatusBg,
          statusColor: rainStatusText,
          isHorizontal: isNarrowStrip,
        );

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isCompact ? 16 : 20),
          decoration: AppDecorations.raisedCard(radius: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Metrik Utama: Kelembapan Tanah
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
                          'Kelembapan Tanah',
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
                            '${s.soilMoisture.toStringAsFixed(0)}%',
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
                      color: soilBadgeBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      soilBadge,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: soilBadgeText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Progress bar posisi kelembapan terhadap ambang batas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ambang siram: $minThreshold% - $maxThreshold%',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      soilRangeNote,
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: soilBadgeText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (s.soilMoisture / 100.0).clamp(0.0, 1.0),
                  minHeight: 7,
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(soilProgressColor),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 14),

              // Strip 3 Sensor Lingkungan Pendukung
              if (isNarrowStrip)
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: tempTile),
                        const SizedBox(width: 10),
                        Expanded(child: humidTile),
                      ],
                    ),
                    const SizedBox(height: 10),
                    rainTile,
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(child: tempTile),
                    const SizedBox(width: 10),
                    Expanded(child: humidTile),
                    const SizedBox(width: 10),
                    Expanded(child: rainTile),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _EnvironmentSubTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String statusText;
  final Color statusBg;
  final Color statusColor;
  final bool isHorizontal;

  const _EnvironmentSubTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.statusText,
    required this.statusBg,
    required this.statusColor,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    final Widget iconWidget = Icon(icon, color: iconColor, size: 19);

    final Widget statusChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: statusBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: statusColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

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
            iconWidget,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            statusChip,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              iconWidget,
              const SizedBox(width: 6),
              Flexible(child: statusChip),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
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
}
