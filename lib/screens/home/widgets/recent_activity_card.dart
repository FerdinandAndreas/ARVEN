import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_decorations.dart';
import '../../../models/device_data_model.dart';

/// Kartu log aktivitas penyiraman terkini yang membaca langsung riwayat nyata dari Firebase.
class RecentActivityCard extends StatelessWidget {
  final List<IrrigationHistoryItem> historyList;
  final bool isSyncing;

  const RecentActivityCard({
    super.key,
    required this.historyList,
    this.isSyncing = false,
  });

  String _formatDuration(int totalSec) {
    if (totalSec < 60) return '$totalSec dtk';
    final int m = totalSec ~/ 60;
    final int s = totalSec % 60;
    return s == 0 ? '$m mnt' : '$m mnt $s dtk';
  }

  String _formatVolume(double liters) {
    if (liters < 1.0) {
      return '${(liters * 1000).toStringAsFixed(0)} mL';
    }
    return '${liters.toStringAsFixed(1)} L';
  }

  Color _statusColor(String status) {
    if (status.contains('Cut-Off') || status.contains('Dihentikan')) {
      return AppColors.primaryDark;
    }
    if (status.contains('Hujan')) {
      return AppColors.badgeWarningText;
    }
    return AppColors.badgeSuccessText;
  }

  @override
  Widget build(BuildContext context) {
    final recentItems = historyList.take(5).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.raisedCard(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Log Aktivitas Terkini',
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
                  color: AppColors.badgeInfoBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${historyList.length} Riwayat',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (isSyncing && recentItems.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Memuat riwayat aktivitas perangkat...',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
              ),
            )
          else if (recentItems.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder, width: 0.9),
              ),
              child: const Text(
                'Belum ada aktivitas penyiraman tercatat. Log akan muncul otomatis saat pompa selesai beroperasi.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            )
          else
            ...recentItems.asMap().entries.map((entry) {
              final int index = entry.key;
              final item = entry.value;
              final bool isLast = index == recentItems.length - 1;
              final Color dotColor = _statusColor(item.status);
              final dt = DateTime.fromMillisecondsSinceEpoch(item.timestamp);
              final String timeText = DateFormat('dd/MM HH:mm').format(dt);
              final String detailText =
                  'Durasi ${_formatDuration(item.durationSec)}, ${_formatVolume(item.waterLiters)} (${item.status})';

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 5),
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 14),
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
                                    timeText,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                detailText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Divider(color: AppColors.divider, height: 1),
                    ),
                ],
              );
            }),
        ],
      ),
    );
  }
}
