import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_decorations.dart';

class SensorCard extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final Color? iconBgColor;
  final String title;
  final String value;
  final String badgeText;
  final Color badgeBgColor;
  final Color badgeTextColor;
  final String? subtitle;
  final double? progressPercent;
  final Color? progressColor;
  final Widget? customTrailing;

  const SensorCard({
    super.key,
    required this.icon,
    this.iconColor,
    this.iconBgColor,
    required this.title,
    required this.value,
    required this.badgeText,
    required this.badgeBgColor,
    required this.badgeTextColor,
    this.subtitle,
    this.progressPercent,
    this.progressColor,
    this.customTrailing,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveIconColor = iconColor ?? AppColors.primary;
    final Color effectiveIconBg = iconBgColor ?? effectiveIconColor.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: AppDecorations.raisedCard(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Soft circular icon & 2-line title that never truncates
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: effectiveIconBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: effectiveIconColor.withValues(alpha: 0.15),
                    width: 1.0,
                  ),
                ),
                child: Icon(
                  icon,
                  color: effectiveIconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Telemetry Value: Big bold clean typography
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Status Badge Pill: Soft background, high contrast, clean curves
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
            decoration: BoxDecoration(
              color: badgeBgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: badgeTextColor.withValues(alpha: 0.18),
                width: 0.8,
              ),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: badgeTextColor,
                letterSpacing: 0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Optional Footer (rendered only if explicitly provided)
          if (subtitle != null || progressPercent != null || customTrailing != null) ...[
            const SizedBox(height: 8),
            if (subtitle != null)
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (progressPercent != null) ...[
              const SizedBox(height: 5),
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
              ),
            ] else if (customTrailing != null) ...[
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: customTrailing!,
              ),
            ],
          ],
        ],
      ),
    );
  }
}
