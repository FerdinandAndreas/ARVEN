import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_decorations.dart';
import '../../../models/device_data_model.dart';

class ScheduleCard extends StatelessWidget {
  final DeviceSchedule schedule;
  final VoidCallback onManageTap;

  const ScheduleCard({
    super.key,
    required this.schedule,
    required this.onManageTap,
  });

  String _formatDuration(int totalSeconds) {
    if (totalSeconds < 60) {
      return '${totalSeconds}s';
    }
    final minutes = totalSeconds ~/ 60;
    final remainingSeconds = totalSeconds % 60;
    if (remainingSeconds == 0) {
      return '$minutes Menit';
    }
    return '${minutes}m ${remainingSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.raisedCard(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Jadwal Penyiraman Harian',
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
              InkWell(
                onTap: onManageTap,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 54, minHeight: 36),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.badgeInfoBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Kelola',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Schedule Session 1: Pagi
          _buildScheduleItem(
            icon: Icons.wb_sunny_rounded,
            title: 'Sesi Pagi',
            timeRange: '${schedule.time1} (${_formatDuration(schedule.durationSec)})',
            recurrence: 'Setiap hari, penyegaran perakaran',
          ),
          const SizedBox(height: 10),

          // Schedule Session 2: Sore
          _buildScheduleItem(
            icon: Icons.nightlight_round,
            title: 'Sesi Sore',
            timeRange: '${schedule.time2} (${_formatDuration(schedule.durationSec)})',
            recurrence: 'Setiap hari, retensi kelembapan',
          ),

          // Schedule Session 3 (if frequency = 3)
          if (schedule.frequency == 3) ...[
            const SizedBox(height: 10),
            _buildScheduleItem(
              icon: Icons.wb_twilight_rounded,
              title: 'Sesi Siang',
              timeRange: '${schedule.time3} (${_formatDuration(schedule.durationSec)})',
              recurrence: 'Setiap hari, pendinginan suhu',
            ),
          ],

          const SizedBox(height: 16),

          // Configuration Action Button
          GestureDetector(
            onTap: onManageTap,
            child: Container(
              height: 46,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder, width: 1.2),
                boxShadow: AppDecorations.softRaisedShadow,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.tune_rounded, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Konfigurasi Jadwal & Durasi',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
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

  Widget _buildScheduleItem({
    required IconData icon,
    required String title,
    required String timeRange,
    required String recurrence,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white, width: 1.2),
        boxShadow: AppDecorations.softRaisedShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: AppDecorations.squircleIcon(radius: 10),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        timeRange,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  recurrence,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.badgeSuccessBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Aktif',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.badgeSuccessText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
