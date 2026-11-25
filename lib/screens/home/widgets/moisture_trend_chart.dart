import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_decorations.dart';
import '../../../models/device_data_model.dart';
import '../../../providers/device_provider.dart';

enum _TrendMetric {
  soilMoisture('Tanah %'),
  temperature('Suhu °C'),
  humidity('Udara %');

  final String shortLabel;
  const _TrendMetric(this.shortLabel);
}

/// Grafik tren sensor realtime berbasis Firebase RTDB (`sensor_logs` + stream `/sensors`),
/// mendukung pemilihan rentang waktu (1 Jam s.d. 30 Hari) dan metrik lingkungan.
class MoistureTrendChart extends StatefulWidget {
  final DeviceData device;
  final DeviceProvider deviceProvider;

  const MoistureTrendChart({
    super.key,
    required this.device,
    required this.deviceProvider,
  });

  @override
  State<MoistureTrendChart> createState() => _MoistureTrendChartState();
}

class _MoistureTrendChartState extends State<MoistureTrendChart> {
  _TrendMetric _selectedMetric = _TrendMetric.soilMoisture;

  double _extractValue(SensorLogPoint point) {
    switch (_selectedMetric) {
      case _TrendMetric.soilMoisture:
        return point.soilMoisture.clamp(0.0, 100.0);
      case _TrendMetric.temperature:
        return point.temperature;
      case _TrendMetric.humidity:
        return point.humidity.clamp(0.0, 100.0);
    }
  }

  double _currentLiveValue() {
    final s = widget.device.sensors;
    switch (_selectedMetric) {
      case _TrendMetric.soilMoisture:
        return s.soilMoisture;
      case _TrendMetric.temperature:
        return s.temperature;
      case _TrendMetric.humidity:
        return s.humidity;
    }
  }

  String _formatMetricValue(double value) {
    switch (_selectedMetric) {
      case _TrendMetric.soilMoisture:
      case _TrendMetric.humidity:
        return '${value.toStringAsFixed(0)}%';
      case _TrendMetric.temperature:
        return '${value.toStringAsFixed(1)} °C';
    }
  }

  String _chartTitle(TrendRange range) {
    switch (_selectedMetric) {
      case _TrendMetric.soilMoisture:
        return 'Tren Kelembapan Tanah (${range.label})';
      case _TrendMetric.temperature:
        return 'Tren Suhu Udara (${range.label})';
      case _TrendMetric.humidity:
        return 'Tren Kelembapan Udara (${range.label})';
    }
  }

  String _chartSubtitle(TrendRange range) {
    final settings = widget.device.settings;
    switch (_selectedMetric) {
      case _TrendMetric.soilMoisture:
        return 'Evaluasi terhadap batas siram ${settings.moistureThreshold}% - ${settings.moistureThresholdMax}%';
      case _TrendMetric.temperature:
        return 'Evaluasi terhadap batas suhu aman ${settings.maxTemperatureLimit.toStringAsFixed(0)} °C';
      case _TrendMetric.humidity:
        return 'Fluktuasi kelembapan relatif udara dalam ${range.label.toLowerCase()}';
    }
  }

  double _axisIntervalMs(TrendRange range) {
    switch (range) {
      case TrendRange.oneHour:
        return const Duration(minutes: 15).inMilliseconds.toDouble();
      case TrendRange.twentyFourHours:
        return const Duration(hours: 6).inMilliseconds.toDouble();
      case TrendRange.threeDays:
        return const Duration(days: 1).inMilliseconds.toDouble();
      case TrendRange.sevenDays:
        return const Duration(days: 2).inMilliseconds.toDouble();
      case TrendRange.thirtyDays:
        return const Duration(days: 7).inMilliseconds.toDouble();
    }
  }

  String _formatAxisTimestamp(int ms, TrendRange range) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    switch (range) {
      case TrendRange.oneHour:
      case TrendRange.twentyFourHours:
        return DateFormat('HH:mm').format(dt);
      case TrendRange.threeDays:
      case TrendRange.sevenDays:
      case TrendRange.thirtyDays:
        return DateFormat('dd/MM').format(dt);
    }
  }

  String _formatTooltipTimestamp(int ms, TrendRange range) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    if (range == TrendRange.oneHour) {
      return '${DateFormat('HH:mm:ss').format(dt)} WIB';
    }
    return '${DateFormat('dd/MM HH:mm').format(dt)} WIB';
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.deviceProvider;
    final TrendRange range = provider.selectedTrendRange;
    final List<SensorLogPoint> points = provider.getTrendPoints(range);
    final bool isLoading = provider.isLoadingTrend && points.isEmpty;
    final String? errorMsg = provider.trendError;

    double? minVal;
    double? maxVal;
    double? avgVal;
    if (points.isNotEmpty) {
      double sum = 0;
      double lo = _extractValue(points.first);
      double hi = lo;
      for (final p in points) {
        final v = _extractValue(p);
        sum += v;
        if (v < lo) lo = v;
        if (v > hi) hi = v;
      }
      minVal = lo;
      maxVal = hi;
      avgVal = sum / points.length;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 360;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isCompact ? 16 : 20),
          decoration: AppDecorations.raisedCard(radius: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Judul & status live sensor
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _chartTitle(range),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _chartSubtitle(range),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.device.status.online ? AppColors.badgeSuccessBg : AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.device.status.online
                            ? AppColors.badgeSuccessText.withValues(alpha: 0.25)
                            : AppColors.cardBorder,
                      ),
                    ),
                    child: Text(
                      widget.device.status.online ? 'Realtime' : 'Offline',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: widget.device.status.online ? AppColors.badgeSuccessText : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Pemilih Metrik (Tanah % | Suhu °C | Udara %)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder, width: 0.9),
                ),
                child: Row(
                  children: _TrendMetric.values.map((metric) {
                    final bool isSelected = _selectedMetric == metric;
                    return Expanded(
                      child: Semantics(
                        button: true,
                        selected: isSelected,
                        label: 'Tampilkan grafik ${metric.shortLabel}',
                        child: Material(
                          color: isSelected ? AppColors.badgeInfoBg : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                          child: InkWell(
                            onTap: () => setState(() => _selectedMetric = metric),
                            borderRadius: BorderRadius.circular(9),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 38),
                              alignment: Alignment.center,
                              decoration: isSelected
                                  ? BoxDecoration(
                                      borderRadius: BorderRadius.circular(9),
                                      border: Border.all(
                                        color: AppColors.primary.withValues(alpha: 0.3),
                                        width: 0.9,
                                      ),
                                    )
                                  : null,
                              child: Text(
                                metric.shortLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),

              // Pemilih Rentang Waktu (1 Jam, 24 Jam, 3 Hari, 7 Hari, 30 Hari)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: TrendRange.values.map((r) {
                    final bool isSelected = range == r;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Semantics(
                        button: true,
                        selected: isSelected,
                        label: 'Rentang waktu ${r.label}',
                        child: Material(
                          color: isSelected ? AppColors.primary : AppColors.surfaceWhite,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            onTap: () => provider.setTrendRange(r),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 38, minWidth: 54),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.cardBorder,
                                  width: 1.0,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                r.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              // Ringkasan Statistik Aktual dari Data Rentang Terpilih
              Row(
                children: [
                  Expanded(
                    child: _buildStatPill(
                      'Saat Ini',
                      widget.device.sensors.updatedAt != null ? _formatMetricValue(_currentLiveValue()) : '--',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatPill('Min', minVal != null ? _formatMetricValue(minVal) : '--'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatPill('Maks', maxVal != null ? _formatMetricValue(maxVal) : '--'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatPill('Rata-rata', avgVal != null ? _formatMetricValue(avgVal) : '--'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (errorMsg != null)
                _buildErrorState(errorMsg)
              else if (isLoading)
                _buildLoadingState()
              else if (points.isEmpty)
                _buildEmptyState(range)
              else ...[
                _buildLineChart(points, range),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${points.length} titik data tercatat',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      points.length == 1
                          ? 'Menunggu sampel berikutnya...'
                          : 'Sentuh grafik untuk detail waktu',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<SensorLogPoint> points, TrendRange range) {
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final int cutoffMs = nowMs - range.duration.inMilliseconds;
    final double minX = cutoffMs.toDouble();
    final double maxX = nowMs.toDouble();

    final List<FlSpot> spots = points
        .map((p) => FlSpot(p.timestamp.toDouble().clamp(minX, maxX), _extractValue(p)))
        .toList();

    double minY = 0;
    double maxY = 100;
    double yInterval = 25;

    if (_selectedMetric == _TrendMetric.temperature) {
      double dataMin = spots.first.y;
      double dataMax = spots.first.y;
      for (final spot in spots) {
        if (spot.y < dataMin) dataMin = spot.y;
        if (spot.y > dataMax) dataMax = spot.y;
      }
      final double refMax = widget.device.settings.maxTemperatureLimit;
      minY = ((dataMin - 5).clamp(0.0, 30.0) / 5).floor() * 5.0;
      maxY = (((dataMax > refMax ? dataMax : refMax) + 5).clamp(25.0, 60.0) / 5).ceil() * 5.0;
      yInterval = 10;
    }

    final List<HorizontalLine> thresholdLines = [];
    if (_selectedMetric == _TrendMetric.soilMoisture) {
      final double minThresh = widget.device.settings.moistureThreshold.toDouble();
      final double maxThresh = widget.device.settings.moistureThresholdMax.toDouble();
      thresholdLines.addAll([
        HorizontalLine(
          y: minThresh,
          color: AppColors.badgeDangerText.withValues(alpha: 0.7),
          strokeWidth: 1.2,
          dashArray: const [5, 4],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            padding: const EdgeInsets.only(right: 4, bottom: 2),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.badgeDangerText,
            ),
            labelResolver: (_) => 'Min ${minThresh.toInt()}%',
          ),
        ),
        HorizontalLine(
          y: maxThresh,
          color: AppColors.badgeSuccessText.withValues(alpha: 0.7),
          strokeWidth: 1.2,
          dashArray: const [5, 4],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            padding: const EdgeInsets.only(right: 4, bottom: 2),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.badgeSuccessText,
            ),
            labelResolver: (_) => 'Maks ${maxThresh.toInt()}%',
          ),
        ),
      ]);
    } else if (_selectedMetric == _TrendMetric.temperature) {
      final double maxTemp = widget.device.settings.maxTemperatureLimit;
      thresholdLines.add(
        HorizontalLine(
          y: maxTemp,
          color: AppColors.badgeWarningText.withValues(alpha: 0.75),
          strokeWidth: 1.2,
          dashArray: const [5, 4],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            padding: const EdgeInsets.only(right: 4, bottom: 2),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.badgeWarningText,
            ),
            labelResolver: (_) => 'Batas ${maxTemp.toStringAsFixed(0)}°C',
          ),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minX: minX,
          maxX: maxX,
          minY: minY,
          maxY: maxY,
          clipData: const FlClipData.all(),
          extraLinesData: ExtraLinesData(horizontalLines: thresholdLines),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yInterval,
            getDrawingHorizontalLine: (value) => const FlLine(
              color: AppColors.divider,
              strokeWidth: 1,
            ),
          ),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.textPrimary,
              tooltipRoundedRadius: 10,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final String timeLabel = _formatTooltipTimestamp(spot.x.toInt(), range);
                  final String valLabel = _formatMetricValue(spot.y);
                  return LineTooltipItem(
                    '$valLabel\n$timeLabel',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                interval: yInterval,
                getTitlesWidget: (value, meta) {
                  final String unit = _selectedMetric == _TrendMetric.temperature ? '°' : '%';
                  return Text(
                    '${value.toInt()}$unit',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: _axisIntervalMs(range),
                minIncluded: false,
                maxIncluded: false,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _formatAxisTimestamp(value.toInt(), range),
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: spots.length > 2,
              curveSmoothness: 0.25,
              preventCurveOverShooting: true,
              color: AppColors.primary,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  final bool isLatest = index == spots.length - 1;
                  if (isLatest || spots.length <= 12) {
                    return FlDotCirclePainter(
                      radius: isLatest ? 4.5 : 2.5,
                      color: isLatest ? Colors.white : AppColors.primary,
                      strokeWidth: isLatest ? 2.5 : 0,
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
                    AppColors.primary.withValues(alpha: 0.22),
                    AppColors.primary.withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const SizedBox(
      height: 180,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
            ),
            SizedBox(height: 12),
            Text(
              'Memuat riwayat pembacaan sensor...',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.badgeDangerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.badgeDangerText.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.badgeDangerText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$message. Periksa koneksi internet lalu coba tarik layar untuk memuat ulang.',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.badgeDangerText,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(TrendRange range) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 0.9),
      ),
      child: Column(
        children: [
          const Icon(Icons.show_chart_rounded, size: 28, color: AppColors.textSecondary),
          const SizedBox(height: 10),
          Text(
            'Belum Ada Riwayat pada Rentang ${range.label}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Grafik mulai terisi otomatis secara realtime saat sensor ESP32 mengirimkan pembaruan data ke Firebase.',
            textAlign: TextAlign.center,
            style: TextStyle(
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
