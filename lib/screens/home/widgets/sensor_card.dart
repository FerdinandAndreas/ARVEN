import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_decorations.dart';

class SensorCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String badgeText;
  final Color badgeBgColor;
  final Color badgeTextColor;
  final String subtitle;
  final double? progressPercent;
  final Color? progressColor;
  final Widget? customTrailing;

  const SensorCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.badgeText,
    required this.badgeBgColor,
    required this.badgeTextColor,
    required this.subtitle,
    this.progressPercent,
    this.progressColor,
    this.customTrailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: AppDecorations.raisedCard(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header Row: Squircle Icon & Metric Name (Flexible)
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: AppDecorations.squircleIcon(radius: 10),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Center: Large Telemetry Value & Status Badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: badgeTextColor.withValues(alpha: 0.2),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: badgeTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Footer: Reference Subtitle & Progress Indicator
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              if (progressPercent != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressPercent!.clamp(0.0, 1.0),
                    minHeight: 4.5,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progressColor ?? AppColors.primary,
                    ),
                  ),
                )
              else if (customTrailing != null)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: customTrailing!,
                )
              else
                const SizedBox(height: 4.5),
            ],
          ),
        ],
      ),
    );
  }
}
