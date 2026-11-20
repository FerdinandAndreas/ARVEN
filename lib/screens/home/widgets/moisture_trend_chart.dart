import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_decorations.dart';

class MoistureTrendChart extends StatelessWidget {
  final double currentMoisture;

  const MoistureTrendChart({
    super.key,
    required this.currentMoisture,
  });

  @override
  Widget build(BuildContext context) {
    // 24h curve influenced by real telemetry reading
    final List<FlSpot> spots = [
      const FlSpot(0, 58),
      const FlSpot(4, 52),
      const FlSpot(8, 44),
      const FlSpot(12, 38),
      FlSpot(14, currentMoisture.clamp(20.0, 90.0)),
      const FlSpot(16, 55),
      const FlSpot(20, 48),
      const FlSpot(24, 60),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.raisedCard(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header Row: Responsive LayoutBuilder
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 360;

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tren Kelembapan Tanah (24 Jam)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Evaluasi kecukupan air perakaran terhadap batas ambang',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildLegend(),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tren Kelembapan Tanah (24 Jam)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Evaluasi kecukupan air perakaran terhadap batas ambang',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildLegend(),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Structured Chart View
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 24,
                minY: 0,
                maxY: 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: AppColors.divider,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: 25,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 4,
                      getTitlesWidget: (value, meta) {
                        final valInt = value.toInt();
                        if (valInt % 4 == 0) {
                          final h = valInt.toString().padLeft(2, '0');
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '$h:00',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        if (spot.x == 14) {
                          return FlDotCirclePainter(
                            radius: 5,
                            color: Colors.white,
                            strokeWidth: 2.5,
                            strokeColor: AppColors.primary,
                          );
                        }
                        return FlDotCirclePainter(radius: 0);
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.25),
                          AppColors.primaryLight.withValues(alpha: 0.02),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
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

  Widget _buildLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          'Riwayat',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 10),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          'Saat Ini',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
