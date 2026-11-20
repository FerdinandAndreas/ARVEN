import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppDecorations {
  // Reusable Neomorphic Raised Shadow ("Efek Timbul")
  static List<BoxShadow> get raisedShadow => [
        const BoxShadow(
          color: AppColors.shadowLight,
          offset: Offset(-5, -5),
          blurRadius: 12,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: AppColors.shadowDark.withValues(alpha: 0.65),
          offset: const Offset(6, 6),
          blurRadius: 14,
          spreadRadius: 0,
        ),
      ];

  // Subtle raised shadow for smaller buttons, pills, chips
  static List<BoxShadow> get softRaisedShadow => [
        const BoxShadow(
          color: AppColors.shadowLight,
          offset: Offset(-3, -3),
          blurRadius: 8,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: AppColors.shadowDark.withValues(alpha: 0.5),
          offset: const Offset(4, 4),
          blurRadius: 10,
          spreadRadius: 0,
        ),
      ];

  // Glowing Royal Blue Button Shadow (Reference Image #1)
  static List<BoxShadow> get blueGlowShadow => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.38),
          offset: const Offset(0, 8),
          blurRadius: 20,
          spreadRadius: 1,
        ),
      ];

  // Glowing Purple / Indigo Shadow for active timeline pill (Reference Image #2)
  static List<BoxShadow> get purpleGlowShadow => [
        BoxShadow(
          color: AppColors.indigoAccent.withValues(alpha: 0.4),
          offset: const Offset(0, 6),
          blurRadius: 16,
          spreadRadius: 0,
        ),
      ];

  // Neomorphic Raised Card ("Timbul")
  static BoxDecoration raisedCard({
    double radius = 22,
    Color color = AppColors.surfaceWhite,
    Border? border,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: border ?? Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1.2),
      boxShadow: raisedShadow,
    );
  }

  // Neomorphic Raised Squircle for Icon Containers (Reference Image #1 social icons)
  static BoxDecoration squircleIcon({
    double radius = 18,
    Color color = AppColors.surfaceWhite,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.2),
      boxShadow: raisedShadow,
    );
  }

  // Neomorphic Pill (Input Fields, Chips, Filter Tabs)
  static BoxDecoration raisedPill({
    Color color = AppColors.surfaceWhite,
    bool isSelected = false,
  }) {
    if (isSelected) {
      return BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.purpleAccent, AppColors.indigoAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: purpleGlowShadow,
      );
    }

    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.2),
      boxShadow: softRaisedShadow,
    );
  }

  // Hero Card Blue Gradient (Reference Image #2 Weather Card)
  static BoxDecoration heroCardDecoration({double radius = 26}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [
          Color(0xFF5CA3FE),
          Color(0xFF3882F6),
          Color(0xFF1D5CFF),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF2563EB).withValues(alpha: 0.35),
          offset: const Offset(0, 12),
          blurRadius: 24,
          spreadRadius: 1,
        ),
      ],
    );
  }

  // Primary Action Pill Gradient Button (Reference Image #1 Login Button)
  static BoxDecoration primaryButtonDecoration({double radius = 28}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [
          Color(0xFF3B82F6),
          Color(0xFF2563EB),
          Color(0xFF1D4ED8),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: blueGlowShadow,
    );
  }
}
