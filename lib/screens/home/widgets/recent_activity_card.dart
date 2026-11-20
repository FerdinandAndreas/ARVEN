import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_decorations.dart';

class ActivityItem {
  final String title;
  final String time;
  final String description;
  final Color dotColor;

  const ActivityItem({
    required this.title,
    required this.time,
    required this.description,
    required this.dotColor,
  });
}

class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({super.key});

  @override
  Widget build(BuildContext context) {
    final List<ActivityItem> activities = [
      const ActivityItem(
        title: 'Penyiraman otomatis selesai',
        time: '12:45',
        description: 'Durasi 15 detik, kelembapan tanah naik ke 66%',
        dotColor: AppColors.primary,
      ),
      const ActivityItem(
        title: 'Sinkronisasi data sensor',
        time: '12:43',
        description: 'Mikroklimat tanah dan temperatur berhasil sinkron',
        dotColor: AppColors.primaryLight,
      ),
      const ActivityItem(
        title: 'Evaluasi ambang batas',
        time: '08:12',
        description: 'Sistem aktif dalam mode otomatis kelembapan tanah',
        dotColor: AppColors.warning,
      ),
      const ActivityItem(
        title: 'Penyiraman terjadwal pagi',
        time: '06:30',
        description: 'Durasi 20 detik berhasil dieksekusi pompa',
        dotColor: AppColors.success,
      ),
    ];

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
                child: const Text(
                  'Telemetri Riwayat',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Items Column (without ListView overhead)
          ...activities.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == activities.length - 1;

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
                          color: item.dotColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: item.dotColor.withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
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
                                  item.time,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.description,
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
