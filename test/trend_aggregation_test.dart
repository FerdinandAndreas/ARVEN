import 'package:flutter_test/flutter_test.dart';
import 'package:smartfarmingiot/models/device_data_model.dart';
import 'package:smartfarmingiot/providers/device_provider.dart';

void main() {
  group('Sensor trend aggregation', () {
    const int baseMs = 1795570000000;

    test('oneHour keeps live 5-second resolution within window and filters stale points', () {
      final live = [
        const SensorLogPoint(timestamp: baseMs - 4000000, soilMoisture: 10, temperature: 25, humidity: 60, rain: false),
        const SensorLogPoint(timestamp: baseMs - 30000, soilMoisture: 42, temperature: 27, humidity: 65, rain: false),
        const SensorLogPoint(timestamp: baseMs - 5000, soilMoisture: 45, temperature: 27.5, humidity: 64, rain: false),
      ];

      final result = buildTrendSeries(
        minuteLogs: const [],
        hourlyLogs: const [],
        liveBuffer: live,
        range: TrendRange.oneHour,
        nowMs: baseMs,
      );

      expect(result.length, 2);
      expect(result.first.soilMoisture, 42);
      expect(result.last.soilMoisture, 45);
    });

    test('thirtyDays combines hourly logs with latest minute points and aggregates smoothly', () {
      final hourly = List<SensorLogPoint>.generate(
        100,
        (i) => SensorLogPoint(
          timestamp: baseMs - (100 - i) * 3600000,
          soilMoisture: 40 + (i % 10).toDouble(),
          temperature: 28,
          humidity: 60,
          rain: false,
        ),
      );

      final result = buildTrendSeries(
        minuteLogs: const [
          SensorLogPoint(timestamp: baseMs - 60000, soilMoisture: 55, temperature: 29, humidity: 62, rain: false),
        ],
        hourlyLogs: hourly,
        liveBuffer: const [],
        range: TrendRange.thirtyDays,
        nowMs: baseMs,
      );

      expect(result.isNotEmpty, isTrue);
      expect(result.length, lessThan(hourly.length));
      expect(result.last.timestamp, greaterThan(result.first.timestamp));
    });

    test('returns empty list when no points exist in range', () {
      final result = buildTrendSeries(
        minuteLogs: const [],
        hourlyLogs: const [],
        liveBuffer: const [],
        range: TrendRange.sevenDays,
        nowMs: baseMs,
      );

      expect(result, isEmpty);
    });
  });
}
