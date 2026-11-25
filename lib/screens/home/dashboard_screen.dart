import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_decorations.dart';
import '../../models/device_data_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';
import 'widgets/moisture_trend_chart.dart';
import 'widgets/plant_condition_card.dart';
import 'widgets/recent_activity_card.dart';
import 'widgets/sensor_card.dart';
import 'widgets/settings_bottom_sheet.dart';
import 'widgets/control_tab_view.dart';
import 'widgets/irrigation_tab_view.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentTabIndex = 0;

  void _openSettings(BuildContext context, DeviceSettings settings) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SettingsBottomSheet(currentSettings: settings),
    );
  }

  String _getCurrentFormattedDate() {
    final now = DateTime.now();
    const days = ['minggu', 'senin', 'selasa', 'rabu', 'kamis', 'jumat', 'sabtu'];
    const months = ['jan', 'feb', 'mar', 'apr', 'mei', 'jun', 'jul', 'agu', 'sep', 'okt', 'nov', 'des'];
    final dayName = days[now.weekday % 7];
    final monthName = months[now.month - 1];
    return '$dayName, ${now.day} $monthName';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final deviceProvider = Provider.of<DeviceProvider>(context);

    final device = deviceProvider.deviceData;
    final userName = authProvider.currentUser?.displayName ?? 'Operator';
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isCompact = screenWidth < 360;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Column(
              children: [
                // Top App Bar with adaptive padding
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isCompact ? 14 : 20,
                    isCompact ? 12 : 16,
                    isCompact ? 14 : 20,
                    10,
                  ),
                  child: _buildTopBar(context, userName, device.status, isCompact),
                ),

                // Main Tab Content with Multi-Device Responsiveness
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async {
                      await Future.delayed(const Duration(milliseconds: 600));
                    },
                    child: IndexedStack(
                      index: _currentTabIndex,
                      children: [
                        _buildOverviewTab(device, deviceProvider),
                        _buildActuatorTab(device, deviceProvider),
                        _buildAnalyticsTab(device, deviceProvider),
                        _buildSettingsTab(device, deviceProvider),
                      ],
                    ),
                  ),
                ),

                // Raised Neomorphic Bottom Navigation Bar (Centered & bounded)
                _buildNeomorphicNavBar(isCompact),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Top Bar (Branding Logo + Title "ARVEN" + Subtitle Date & Right Profile Icon)
  Widget _buildTopBar(BuildContext context, String userName, DeviceStatus status, bool isCompact) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: Branding Logo + Title "ARVEN" + Subtitle "jumat, 20 nov"
        Row(
          children: [
            Container(
              width: isCompact ? 42 : 46,
              height: isCompact ? 42 : 46,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                  ...AppDecorations.raisedShadow,
                ],
              ),
              child: Image.asset(
                'assets/logo.webp',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ARVEN',
                  style: TextStyle(
                    fontSize: isCompact ? 15 : 16.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    color: AppColors.textPrimary,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _getCurrentFormattedDate(),
                  style: TextStyle(
                    fontSize: isCompact ? 11.5 : 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8F9FB9),
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Right: Profile Avatar Button
        GestureDetector(
          onTap: () => _showQuickMenu(context),
          child: Container(
            width: isCompact ? 38 : 42,
            height: isCompact ? 38 : 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF0F5FD),
              border: Border.all(
                color: const Color(0xFFD6E4FA),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.person_outline_rounded,
              color: AppColors.primary,
              size: isCompact ? 20 : 22,
            ),
          ),
        ),
      ],
    );
  }

  // TAB 1: OVERVIEW (Responsive: 1-col on mobile, 4-col sensor grid + side-by-side cards on tablet)
  Widget _buildOverviewTab(DeviceData device, DeviceProvider deviceProvider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isTablet = constraints.maxWidth >= 780;
        final double hPadding = constraints.maxWidth < 360 ? 14 : (isTablet ? 24 : 20);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Weather & Farming Card
              _buildHeroWeatherCard(device),
              const SizedBox(height: 18),

              // Operational Mode Horizontal Selector
              _buildModeTimelineSelector(device.activeMode, deviceProvider),
              const SizedBox(height: 16),

              // Quick Pump Control (Nyalakan & Hentikan Pompa Langsung di Beranda)
              _buildQuickPumpControl(device, deviceProvider),
              const SizedBox(height: 18),

              // Sensor Metrics Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Kondisi Lingkungan',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'Update: ${device.sensors.updatedAt != null ? "${device.sensors.updatedAt!.hour.toString().padLeft(2, '0')}:${device.sensors.updatedAt!.minute.toString().padLeft(2, '0')}" : "Menunggu data"}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              EnvironmentConditionsCard(device: device),
              const SizedBox(height: 18),

              // Tablet layout: Plant Condition & Trend Chart side-by-side
              if (isTablet)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: PlantConditionCard(
                        soilMoisture: device.sensors.soilMoisture,
                        temperature: device.sensors.temperature,
                        isRaining: device.sensors.rain,
                        humidity: device.sensors.humidity,
                        moistureThreshold: device.settings.moistureThreshold,
                        moistureThresholdMax: device.settings.moistureThresholdMax,
                        maxTemperatureLimit: device.settings.maxTemperatureLimit,
                        rainDelayEnabled: device.settings.rainDelayEnabled,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      flex: 6,
                      child: MoistureTrendChart(
                        device: device,
                        deviceProvider: deviceProvider,
                      ),
                    ),
                  ],
                )
              else
                PlantConditionCard(
                  soilMoisture: device.sensors.soilMoisture,
                  temperature: device.sensors.temperature,
                  isRaining: device.sensors.rain,
                  humidity: device.sensors.humidity,
                  moistureThreshold: device.settings.moistureThreshold,
                  moistureThresholdMax: device.settings.moistureThresholdMax,
                  maxTemperatureLimit: device.settings.maxTemperatureLimit,
                  rainDelayEnabled: device.settings.rainDelayEnabled,
                ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // TAB 2: MONITORING IRIGASI & KONSUMSI AIR (Debit 600 L/jam & Log Eksekusi)
  Widget _buildActuatorTab(DeviceData device, DeviceProvider deviceProvider) {
    return IrrigationTabView(
      device: device,
      deviceProvider: deviceProvider,
    );
  }

  // TAB 3: ANALYTICS & TRENDS (Adaptive)
  Widget _buildAnalyticsTab(DeviceData device, DeviceProvider deviceProvider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isTablet = constraints.maxWidth >= 780;
        final double hPadding = constraints.maxWidth < 360 ? 14 : (isTablet ? 24 : 20);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Analisis & Tren Sensor',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Fluktuasi kelembapan tanah, suhu, dan kelembapan udara secara realtime',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),

              if (isTablet)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: MoistureTrendChart(
                        device: device,
                        deviceProvider: deviceProvider,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          PlantConditionCard(
                            soilMoisture: device.sensors.soilMoisture,
                            temperature: device.sensors.temperature,
                            isRaining: device.sensors.rain,
                            humidity: device.sensors.humidity,
                            moistureThreshold: device.settings.moistureThreshold,
                            moistureThresholdMax: device.settings.moistureThresholdMax,
                            maxTemperatureLimit: device.settings.maxTemperatureLimit,
                            rainDelayEnabled: device.settings.rainDelayEnabled,
                          ),
                          const SizedBox(height: 18),
                          RecentActivityCard(
                            historyList: deviceProvider.historyList,
                            isSyncing: deviceProvider.isSyncing,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else ...[
                MoistureTrendChart(
                  device: device,
                  deviceProvider: deviceProvider,
                ),
                const SizedBox(height: 16),
                PlantConditionCard(
                  soilMoisture: device.sensors.soilMoisture,
                  temperature: device.sensors.temperature,
                  isRaining: device.sensors.rain,
                  humidity: device.sensors.humidity,
                  moistureThreshold: device.settings.moistureThreshold,
                  moistureThresholdMax: device.settings.moistureThresholdMax,
                  maxTemperatureLimit: device.settings.maxTemperatureLimit,
                  rainDelayEnabled: device.settings.rainDelayEnabled,
                ),
                const SizedBox(height: 16),
                RecentActivityCard(
                  historyList: deviceProvider.historyList,
                  isSyncing: deviceProvider.isSyncing,
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // TAB 4: KONTROL SISTEM & PARAMETER (Sesuai Referensi Pengguna)
  Widget _buildSettingsTab(DeviceData device, DeviceProvider deviceProvider) {
    return ControlTabView(
      device: device,
      deviceProvider: deviceProvider,
      onOpenFullSettings: () => _openSettings(context, device.settings),
    );
  }

  // Hero Weather & Farm Card (Responsive on small phones)
  Widget _buildHeroWeatherCard(DeviceData device) {
    final s = device.sensors;
    final isPumpActive = device.pumpState.active;

    String conditionText = 'Kondisi Optimal';
    if (s.rain) {
      conditionText = 'Hujan Terdeteksi';
    } else if (isPumpActive) {
      conditionText = 'Irigasi Berjalan';
    } else if (s.soilMoisture < device.settings.moistureThreshold) {
      conditionText = 'Tanah Perlu Air';
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 360;

        return Container(
          width: double.infinity,
          decoration: AppDecorations.heroCardDecoration(radius: isCompact ? 22 : 28),
          padding: EdgeInsets.all(isCompact ? 16 : 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: 3D Weather Icon + Large Temp & Condition
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Weather Icon Stack
                  Container(
                    width: isCompact ? 60 : 72,
                    height: isCompact ? 60 : 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        s.rain
                            ? Icons.water_drop_rounded
                            : (s.temperature > 30 ? Icons.wb_sunny_rounded : Icons.cloud_queue_rounded),
                        size: isCompact ? 32 : 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: isCompact ? 12 : 16),

                  // Big Temperature & Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${s.temperature.toStringAsFixed(0)}°C',
                            style: TextStyle(
                              fontSize: isCompact ? 30 : 36,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.0,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Terasa seperti ${(s.temperature + 1.2).toStringAsFixed(1)}°C',
                          style: TextStyle(
                            fontSize: isCompact ? 10.5 : 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Status Pill inside Hero
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 8 : 10,
                      vertical: isCompact ? 4 : 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      isPumpActive ? 'Menyiram' : conditionText,
                      style: TextStyle(
                        fontSize: isCompact ? 10 : 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isCompact ? 14 : 18),

              // Bottom Row inside Hero: 3 Frosted Metric Pills
              Row(
                children: [
                  Expanded(
                    child: _buildFrostedHeroMetricPill(
                      icon: Icons.water_drop_outlined,
                      label: 'Kelembapan',
                      value: '${s.soilMoisture.toStringAsFixed(0)}%',
                      isCompact: isCompact,
                    ),
                  ),
                  SizedBox(width: isCompact ? 6 : 8),
                  Expanded(
                    child: _buildFrostedHeroMetricPill(
                      icon: Icons.cloud_outlined,
                      label: 'Udara',
                      value: '${s.humidity.toStringAsFixed(0)}%',
                      isCompact: isCompact,
                    ),
                  ),
                  SizedBox(width: isCompact ? 6 : 8),
                  Expanded(
                    child: _buildFrostedHeroMetricPill(
                      icon: s.rain ? Icons.grain_rounded : Icons.wb_sunny_outlined,
                      label: 'Presipitasi',
                      value: s.rain ? 'Hujan' : 'Kering',
                      isCompact: isCompact,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFrostedHeroMetricPill({
    required IconData icon,
    required String label,
    required String value,
    required bool isCompact,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 4 : 8,
        vertical: isCompact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: isCompact ? 14 : 16, color: Colors.white),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isCompact ? 11.5 : 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isCompact ? 9.5 : 10,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Operational Mode Timeline Selector
  Widget _buildModeTimelineSelector(String activeMode, DeviceProvider deviceProvider) {
    final modes = [
      {'key': 'auto_moisture', 'title': 'Otomatis', 'icon': Icons.water_drop_rounded},
      {'key': 'scheduled', 'title': 'Terjadwal', 'icon': Icons.alarm_rounded},
      {'key': 'manual', 'title': 'Manual', 'icon': Icons.touch_app_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mode Operasi',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            InkWell(
              onTap: () => _openSettings(context, deviceProvider.deviceData.settings),
              borderRadius: BorderRadius.circular(6),
              child: const Row(
                children: [
                  Text(
                    'Pengaturan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.primary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Horizontal Pill Row
        Row(
          children: modes.map((m) {
            final key = m['key'] as String;
            final title = m['title'] as String;
            final icon = m['icon'] as IconData;
            final isSelected = activeMode == key;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => deviceProvider.setWateringMode(key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: isSelected
                        ? BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: AppDecorations.blueGlowShadow,
                          )
                        : AppDecorations.raisedPill(isSelected: false),
                    child: Column(
                      children: [
                        Icon(
                          icon,
                          size: 18,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Quick Pump Control with Clean IndoPrice-Style Card & Disabled State
  Widget _buildQuickPumpControl(DeviceData device, DeviceProvider deviceProvider) {
    final bool isPumpActive = device.pumpState.active;
    final bool isManual = device.activeMode == 'manual';
    final int safetyTimeoutSec = device.settings.manualSafetyTimeoutSec;
    final String cutoffStr = safetyTimeoutSec < 60
        ? '$safetyTimeoutSec dtk'
        : (safetyTimeoutSec % 60 == 0
            ? '${safetyTimeoutSec ~/ 60} mnt'
            : '${safetyTimeoutSec ~/ 60} mnt ${safetyTimeoutSec % 60} dtk');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: isPumpActive
          ? BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFBFDBFE), // Soft Ice-Blue dari IndoPrice
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                  offset: const Offset(0, 4),
                  blurRadius: 14,
                  spreadRadius: 0,
                ),
                ...AppDecorations.raisedShadow,
              ],
            )
          : AppDecorations.raisedCard(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Kontrol Pompa & Status Cut-off
          Row(
            children: [
              // Circle status icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPumpActive ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                  border: Border.all(
                    color: isPumpActive ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  isPumpActive ? Icons.water_drop_rounded : Icons.power_settings_new_rounded,
                  color: isPumpActive ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Status text & subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Kontrol Pompa',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.1,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isPumpActive ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                            boxShadow: isPumpActive
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF2563EB).withValues(alpha: 0.45),
                                      blurRadius: 5,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cut-off: $cutoffStr',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Pill Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: isPumpActive ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPumpActive ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  isPumpActive ? 'AKTIF' : 'SIAGA',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: isPumpActive ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Action Buttons: Nyalakan Pompa & Hentikan Pompa
          Row(
            children: [
              // Button 1: Nyalakan Pompa
              Expanded(
                flex: 6,
                child: GestureDetector(
                  onTap: (isManual && !isPumpActive)
                      ? () {
                          deviceProvider.toggleManualPump(true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Pompa dinyalakan (Auto cut-off: $cutoffStr).'),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 46,
                    decoration: (isManual && !isPumpActive)
                        ? AppDecorations.primaryButtonDecoration(radius: 14)
                        : BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                          ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          color: (isManual && !isPumpActive) ? Colors.white : const Color(0xFF94A3B8),
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Nyalakan Pompa',
                            style: TextStyle(
                              color: (isManual && !isPumpActive) ? Colors.white : const Color(0xFF94A3B8),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Button 2: Hentikan Pompa (Bisa ditekan kapan saja pompa aktif)
              Expanded(
                flex: 5,
                child: GestureDetector(
                  onTap: isPumpActive
                      ? () {
                          deviceProvider.forceTurnOffPump();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Pompa dimatikan dan disinkronkan ke Firebase.'),
                              backgroundColor: AppColors.danger,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 46,
                    decoration: isPumpActive
                        ? BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                                offset: const Offset(0, 4),
                                blurRadius: 12,
                                spreadRadius: 0,
                              ),
                            ],
                          )
                        : BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                          ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.stop_rounded,
                          color: isPumpActive ? Colors.white : const Color(0xFF94A3B8),
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Hentikan Pompa',
                            style: TextStyle(
                              color: isPumpActive ? Colors.white : const Color(0xFF94A3B8),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Neomorphic Raised Bottom Navigation Bar (Responsive & Centered)
  Widget _buildNeomorphicNavBar(bool isCompact) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          margin: EdgeInsets.fromLTRB(isCompact ? 12 : 16, 6, isCompact ? 12 : 16, 14),
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 6 : 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 1.5,
            ),
            boxShadow: AppDecorations.raisedShadow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.grid_view_rounded, 'Overview', isCompact),
              _buildNavItem(1, Icons.water_rounded, 'Irigasi', isCompact),
              _buildNavItem(2, Icons.analytics_outlined, 'Analitik', isCompact),
              _buildNavItem(3, Icons.tune_rounded, 'Kontrol', isCompact),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isCompact) {
    final isSelected = _currentTabIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTabIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? (isCompact ? 10 : 14) : (isCompact ? 8 : 10),
          vertical: 8,
        ),
        decoration: isSelected
            ? BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppDecorations.blueGlowShadow,
              )
            : BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isCompact ? 18 : 20,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            if (isSelected) ...[
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: isCompact ? 11 : 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showQuickMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Menu Sistem ARVEN',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: AppDecorations.squircleIcon(radius: 10),
                      child: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                    ),
                    title: const Text('Sinkronisasi Ulang Data', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Tarik telemetri terkini dari ESP32', style: TextStyle(fontSize: 12)),
                    onTap: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Telemetri sensor berhasil disinkronkan.'),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: AppDecorations.squircleIcon(radius: 10),
                      child: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                    ),
                    title: const Text('Informasi Firmware & Node', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Node ID: arven_device_01 (ESP32 v2.4)', style: TextStyle(fontSize: 12)),
                    onTap: () => Navigator.pop(ctx),
                  ),
                  ListTile(
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: AppDecorations.squircleIcon(radius: 10),
                      child: const Icon(Icons.logout_rounded, color: AppColors.danger),
                    ),
                    title: const Text('Keluar Akun', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.danger)),
                    subtitle: const Text('Akhiri sesi monitoring', style: TextStyle(fontSize: 12)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _confirmLogout(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Konfirmasi Keluar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text(
          'Apakah Anda ingin mengakhiri sesi monitoring saat ini?',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await authProvider.logout();
    }
  }
}
