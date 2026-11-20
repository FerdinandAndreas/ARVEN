import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_decorations.dart';

class PlantConditionCard extends StatelessWidget {
  final double soilMoisture;
  final double temperature;
  final bool isRaining;

  const PlantConditionCard({
    super.key,
    required this.soilMoisture,
    required this.temperature,
    required this.isRaining,
  });

  @override
  Widget build(BuildContext context) {
    final bool isHealthy = soilMoisture >= 35 && soilMoisture <= 80 && temperature <= 34;

    final String conditionTitle = isHealthy ? 'Kondisi Optimal' : 'Perlu Penyesuaian';
    final Color conditionColor = isHealthy ? AppColors.badgeSuccessText : AppColors.badgeWarningText;
    final Color conditionBg = isHealthy ? AppColors.badgeSuccessBg : AppColors.badgeWarningBg;

    final String description = isHealthy
        ? 'Tingkat kelembapan tanah dan suhu udara berada dalam rentang ideal untuk fotosintesis dan serapan nutrisi.'
        : 'Kelembapan tanah atau temperatur membutuhkan perhatian irigasi untuk menjaga vigor perakaran.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.raisedCard(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: conditionBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: conditionColor.withValues(alpha: 0.25),
                    width: 1.0,
                  ),
                ),
                child: Icon(Icons.eco_rounded, color: conditionColor, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Status Kesehatan Tanaman',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: conditionBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isHealthy ? 'Vigor Prima' : 'Evaluasi',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: conditionColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            conditionTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: conditionColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
