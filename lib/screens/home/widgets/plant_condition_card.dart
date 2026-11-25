import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_decorations.dart';

/// Kartu evaluasi kesehatan tanaman berbasis ambang kelembapan tanah, suhu udara, dan hujan aktual.
class PlantConditionCard extends StatelessWidget {
  final double soilMoisture;
  final double temperature;
  final bool isRaining;
  final double? humidity;
  final int moistureThreshold;
  final int moistureThresholdMax;
  final double maxTemperatureLimit;
  final bool rainDelayEnabled;

  const PlantConditionCard({
    super.key,
    required this.soilMoisture,
    required this.temperature,
    required this.isRaining,
    this.humidity,
    this.moistureThreshold = 40,
    this.moistureThresholdMax = 85,
    this.maxTemperatureLimit = 35.0,
    this.rainDelayEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSoilDry = soilMoisture < moistureThreshold;
    final bool isSoilWet = soilMoisture > moistureThresholdMax;
    final bool isTempHigh = temperature > maxTemperatureLimit;
    final bool isTempLow = temperature < 18.0;
    final bool isRainHold = isRaining && rainDelayEnabled;

    final String badgeText;
    final String conditionTitle;
    final String diagnosisText;
    final Color statusColor;
    final Color statusBg;

    if (isSoilDry) {
      badgeText = 'Perlu Siram';
      conditionTitle = 'Tanah Terlalu Kering';
      statusColor = AppColors.badgeDangerText;
      statusBg = AppColors.badgeDangerBg;
      diagnosisText = isRainHold
          ? 'Kelembapan tanah ${soilMoisture.toStringAsFixed(0)}% di bawah ambang $moistureThreshold%, namun penyiraman otomatis ditahan karena hujan.'
          : 'Kelembapan tanah ${soilMoisture.toStringAsFixed(0)}% berada di bawah batas minimum $moistureThreshold%. Suhu ${temperature.toStringAsFixed(1)} °C.';
    } else if (isTempHigh) {
      badgeText = 'Suhu Tinggi';
      conditionTitle = 'Risiko Stres Termal';
      statusColor = AppColors.badgeWarningText;
      statusBg = AppColors.badgeWarningBg;
      diagnosisText =
          'Suhu udara ${temperature.toStringAsFixed(1)} °C melebihi batas aman ${maxTemperatureLimit.toStringAsFixed(0)} °C. Kelembapan tanah saat ini ${soilMoisture.toStringAsFixed(0)}%.';
    } else if (isRainHold) {
      badgeText = 'Tunda Hujan';
      conditionTitle = 'Irigasi Ditahan Alami';
      statusColor = AppColors.badgeWarningText;
      statusBg = AppColors.badgeWarningBg;
      diagnosisText =
          'Sensor mendeteksi hujan sehingga siklus siram otomatis ditunda. Kelembapan tanah tercatat ${soilMoisture.toStringAsFixed(0)}%.';
    } else if (isSoilWet) {
      badgeText = 'Kadar Air Tinggi';
      conditionTitle = 'Media Tanam Cukup Basah';
      statusColor = AppColors.primaryDark;
      statusBg = AppColors.badgeInfoBg;
      diagnosisText =
          'Kelembapan tanah ${soilMoisture.toStringAsFixed(0)}% melampaui batas target $moistureThresholdMax%. Pompa ditahan agar perakaran tidak tergenang.';
    } else if (isTempLow) {
      badgeText = 'Suhu Rendah';
      conditionTitle = 'Lingkungan Cukup Dingin';
      statusColor = AppColors.primaryDark;
      statusBg = AppColors.badgeInfoBg;
      diagnosisText =
          'Suhu udara ${temperature.toStringAsFixed(1)} °C di bawah rentang hangat ideal (18 - ${maxTemperatureLimit.toStringAsFixed(0)} °C), kelembapan tanah ${soilMoisture.toStringAsFixed(0)}%.';
    } else {
      badgeText = 'Optimal';
      conditionTitle = 'Kondisi Tanaman Ideal';
      statusColor = AppColors.badgeSuccessText;
      statusBg = AppColors.badgeSuccessBg;
      final String humidPart = humidity != null ? ' dan kelembapan udara ${humidity!.toStringAsFixed(0)}%' : '';
      diagnosisText =
          'Kelembapan tanah ${soilMoisture.toStringAsFixed(0)}% (target $moistureThreshold% - $moistureThresholdMax%), suhu ${temperature.toStringAsFixed(1)} °C$humidPart mendukung serapan nutrisi.';
    }

    // 3 indikator faktor agronomi ringkas di bagian bawah
    final String soilFactorVal = isSoilDry ? 'Kering' : (isSoilWet ? 'Basah' : 'Ideal');
    final Color soilFactorColor = isSoilDry
        ? AppColors.badgeDangerText
        : (isSoilWet ? AppColors.primaryDark : AppColors.badgeSuccessText);

    final String tempFactorVal = isTempHigh ? 'Panas' : (isTempLow ? 'Dingin' : 'Aman');
    final Color tempFactorColor = isTempHigh
        ? AppColors.badgeWarningText
        : (isTempLow ? AppColors.primaryDark : AppColors.badgeSuccessText);

    final String weatherFactorVal = isRaining ? 'Hujan' : 'Cerah';
    final Color weatherFactorColor = isRaining ? AppColors.badgeWarningText : AppColors.badgeSuccessText;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.raisedCard(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.25),
                    width: 1.0,
                  ),
                ),
                child: Icon(
                  Icons.eco_rounded,
                  color: statusColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Status Kesehatan Tanaman',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            conditionTitle,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            diagnosisText,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFactorChip(
                  label: 'Media Tanam',
                  value: soilFactorVal,
                  valueColor: soilFactorColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFactorChip(
                  label: 'Suhu Mikro',
                  value: tempFactorVal,
                  valueColor: tempFactorColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFactorChip(
                  label: 'Cuaca',
                  value: weatherFactorVal,
                  valueColor: weatherFactorColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFactorChip({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder, width: 0.9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
