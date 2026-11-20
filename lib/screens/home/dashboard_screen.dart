import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_decorations.dart';
import '../../models/device_data_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';
import 'widgets/moisture_trend_chart.dart';
import 'widgets/plant_condition_card.dart';
import 'widgets/pump_status_card.dart';
import 'widgets/recent_activity_card.dart';
import 'widgets/schedule_card.dart';
import 'widgets/sensor_card.dart';
import 'widgets/settings_bottom_sheet.dart';

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
    const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final dayName = days[now.weekday % 7];
    final monthName = months[now.month - 1];
    return '$dayName, ${now.day} $monthName';
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds < 60) {
      return '$totalSeconds Detik';
    }
    final minutes = totalSeconds ~/ 60;
    final remainingSeconds = totalSeconds % 60;
    if (remainingSeconds == 0) {
      return '$minutes Menit';
    }
    return '$minutes Menit $remainingSeconds Detik';
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
                        _buildAnalyticsTab(device),
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

  // Top Bar (Responsive for narrow phones & tablets)
  Widget _buildTopBar(BuildContext context, String userName, DeviceStatus status, bool isCompact) {
    final isOnline = status.online;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Menu Hamburger Squircle
        Container(
          width: isCompact ? 40 : 44,
          height: isCompact ? 40 : 44,
          decoration: AppDecorations.squircleIcon(radius: 12),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(Icons.notes_rounded, color: AppColors.textPrimary, size: isCompact ? 20 : 22),
            onPressed: () => _showQuickMenu(context),
            tooltip: 'Menu Utama',
          ),
        ),
        SizedBox(width: isCompact ? 8 : 12),

        // Notification Bell with Badge "2"
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: isCompact ? 40 : 44,
              height: isCompact ? 40 : 44,
              decoration: AppDecorations.squircleIcon(radius: 12),
              child: Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: isCompact ? 20 : 22),
            ),
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: const Center(
                  child: Text(
                    '2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(width: 8),

        // Location & Facility Info (Flexible & Ellipsis-safe)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.location_on_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'GREENHOUSE ARVEN',
                      style: TextStyle(
                        fontSize: isCompact ? 11.5 : 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                _getCurrentFormattedDate(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        SizedBox(width: isCompact ? 8 : 12),

        // Profile Avatar with Status Ring
        GestureDetector(
          onTap: () => _confirmLogout(context),
          child: Container(
            width: isCompact ? 40 : 44,
            height: isCompact ? 40 : 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceWhite,
              border: Border.all(
                color: isOnline ? AppColors.success : AppColors.cardBorder,
                width: 2.2,
              ),
              boxShadow: AppDecorations.softRaisedShadow,
            ),
            child: Center(
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'O',
                style: TextStyle(
                  fontSize: isCompact ? 14 : 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
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
                    'Update: ${device.sensors.updatedAt != null ? "${device.sensors.updatedAt!.hour.toString().padLeft(2, '0')}:${device.sensors.updatedAt!.minute.toString().padLeft(2, '0')}" : "Realtime"}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Sensor Grid (Adaptive 2, 3, or 4 columns with zero overflow)
              _buildSensorGrid(device),
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
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      flex: 6,
                      child: MoistureTrendChart(currentMoisture: device.sensors.soilMoisture),
                    ),
                  ],
                )
              else
                PlantConditionCard(
                  soilMoisture: device.sensors.soilMoisture,
                  temperature: device.sensors.temperature,
                  isRaining: device.sensors.rain,
                ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // TAB 2: ACTUATOR & IRRIGATION CONTROL (Adaptive: Side-by-side on wide screens)
  Widget _buildActuatorTab(DeviceData device, DeviceProvider deviceProvider) {
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
                'Kendali Pompa Irigasi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Manajemen penyiraman manual, proteksi tekanan, dan status katup',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),

              if (isTablet)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: PumpStatusCard(device: device, provider: deviceProvider),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          ScheduleCard(
                            schedule: device.settings.schedule,
                            onManageTap: () => _openSettings(context, device.settings),
                          ),
                          const SizedBox(height: 18),
                          const RecentActivityCard(),
                        ],
                      ),
                    ),
                  ],
                )
              else ...[
                PumpStatusCard(device: device, provider: deviceProvider),
                const SizedBox(height: 16),
                ScheduleCard(
                  schedule: device.settings.schedule,
                  onManageTap: () => _openSettings(context, device.settings),
                ),
                const SizedBox(height: 16),
                const RecentActivityCard(),
              ],

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // TAB 3: ANALYTICS & TRENDS (Adaptive)
  Widget _buildAnalyticsTab(DeviceData device) {
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
                'Fluktuasi kelembapan tanah dan suhu udara 24 jam terakhir',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),

              if (isTablet)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: MoistureTrendChart(currentMoisture: device.sensors.soilMoisture),
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
                          ),
                          const SizedBox(height: 18),
                          const RecentActivityCard(),
                        ],
                      ),
                    ),
                  ],
                )
              else ...[
                MoistureTrendChart(currentMoisture: device.sensors.soilMoisture),
                const SizedBox(height: 16),
                PlantConditionCard(
                  soilMoisture: device.sensors.soilMoisture,
                  temperature: device.sensors.temperature,
                  isRaining: device.sensors.rain,
                ),
                const SizedBox(height: 16),
                const RecentActivityCard(),
              ],

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // TAB 4: SCHEDULES & DEVICE SETTINGS (Adaptive)
  Widget _buildSettingsTab(DeviceData device, DeviceProvider deviceProvider) {
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
                'Jadwal & Pengaturan Sistem',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Konfigurasi siklus otomatisasi, parameter batas, dan sinkronisasi ESP32',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),

              if (isTablet)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: ScheduleCard(
                        schedule: device.settings.schedule,
                        onManageTap: () => _openSettings(context, device.settings),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      flex: 5,
                      child: _buildParameterSummaryCard(device),
                    ),
                  ],
                )
              else ...[
                ScheduleCard(
                  schedule: device.settings.schedule,
                  onManageTap: () => _openSettings(context, device.settings),
                ),
                const SizedBox(height: 16),
                _buildParameterSummaryCard(device),
              ],

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildParameterSummaryCard(DeviceData device) {
    return Container(
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
                  'Ringkasan Parameter Aktif',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
                onPressed: () => _openSettings(context, device.settings),
                tooltip: 'Ubah Parameter',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildParamRow('Batas Min (Pompa ON)', '≤ ${device.settings.moistureThreshold}% (Kering)'),
          const SizedBox(height: 8),
          _buildParamRow('Target Max (Pompa OFF)', '≥ ${device.settings.moistureThresholdMax}% (Basah)'),
          const SizedBox(height: 8),
          _buildParamRow('Durasi Siram Terjadwal', _formatDuration(device.settings.schedule.durationSec)),
          const SizedBox(height: 8),
          _buildParamRow('Batas Pengaman Manual', '${device.settings.manualSafetyTimeoutMin} Menit (Auto Cut-Off)'),
          const SizedBox(height: 8),
          _buildParamRow('Proteksi Hujan (Rain Delay)', device.settings.rainDelayEnabled ? 'Aktif' : 'Nonaktif'),
          const SizedBox(height: 16),

          GestureDetector(
            onTap: () => _openSettings(context, device.settings),
            child: Container(
              height: 48,
              width: double.infinity,
              decoration: AppDecorations.primaryButtonDecoration(radius: 14),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.tune_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Buka Panel Konfigurasi Lengkap',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
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

  Widget _buildParamRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      ],
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
                    decoration: AppDecorations.raisedPill(isSelected: isSelected),
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

  // Sensor Grid: Fully Responsive with mainAxisExtent
  Widget _buildSensorGrid(DeviceData device) {
    final s = device.sensors;
    final threshold = device.settings.moistureThreshold;

    final bool isMoistureNormal = s.soilMoisture >= threshold;
    final String moistureBadge = isMoistureNormal ? 'Normal' : 'Kering';
    final Color moistureBadgeBg = isMoistureNormal ? AppColors.badgeSuccessBg : AppColors.badgeDangerBg;
    final Color moistureBadgeText = isMoistureNormal ? AppColors.badgeSuccessText : AppColors.badgeDangerText;

    final bool isTempIdeal = s.temperature >= 20.0 && s.temperature <= 29.0;
    final String tempBadge = isTempIdeal ? 'Ideal' : (s.temperature > 29.0 ? 'Tinggi' : 'Rendah');
    final Color tempBadgeBg = isTempIdeal ? AppColors.badgeSuccessBg : AppColors.badgeWarningBg;
    final Color tempBadgeText = isTempIdeal ? AppColors.badgeSuccessText : AppColors.badgeWarningText;

    final bool isHumidNormal = s.humidity >= 60.0 && s.humidity <= 85.0;
    final String humidBadge = isHumidNormal ? 'Normal' : (s.humidity > 85.0 ? 'Tinggi' : 'Rendah');
    final Color humidBadgeBg = isHumidNormal ? AppColors.badgeSuccessBg : AppColors.badgeInfoBg;
    final Color humidBadgeText = isHumidNormal ? AppColors.badgeSuccessText : AppColors.badgeInfoText;

    final String rainValue = s.rain ? 'Hujan' : 'Kering';
    final String rainBadge = s.rain ? 'Presipitasi' : 'Kering';
    final Color rainBadgeBg = s.rain ? AppColors.badgeInfoBg : AppColors.badgeSuccessBg;
    final Color rainBadgeText = s.rain ? AppColors.badgeInfoText : AppColors.badgeSuccessText;
    final String rainSubtitle = s.rain ? 'Presipitasi air terdeteksi' : 'Tidak ada hujan';

    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        int crossAxisCount = 2;
        double mainAxisExtent = 185;

        if (w >= 750) {
          crossAxisCount = 4;
          mainAxisExtent = 180;
        } else if (w >= 520) {
          crossAxisCount = 3;
          mainAxisExtent = 180;
        } else if (w < 350) {
          crossAxisCount = 2;
          mainAxisExtent = 195;
        }

        return GridView(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: w < 360 ? 10 : 14,
            mainAxisSpacing: w < 360 ? 10 : 14,
            mainAxisExtent: mainAxisExtent,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            SensorCard(
              icon: Icons.water_drop_outlined,
              title: 'Kelembapan Tanah',
              value: '${s.soilMoisture.toStringAsFixed(0)}%',
              badgeText: moistureBadge,
              badgeBgColor: moistureBadgeBg,
              badgeTextColor: moistureBadgeText,
              subtitle: 'Target: $threshold% - ${device.settings.moistureThresholdMax}%',
              progressPercent: s.soilMoisture / 100.0,
              progressColor: isMoistureNormal ? AppColors.primary : AppColors.danger,
            ),
            SensorCard(
              icon: Icons.thermostat_outlined,
              title: 'Suhu Udara',
              value: '${s.temperature.toStringAsFixed(1)}°C',
              badgeText: tempBadge,
              badgeBgColor: tempBadgeBg,
              badgeTextColor: tempBadgeText,
              subtitle: 'Rentang Ideal: 20-28°C',
              progressPercent: (s.temperature / 45.0).clamp(0.0, 1.0),
              progressColor: AppColors.primaryLight,
            ),
            SensorCard(
              icon: Icons.cloud_outlined,
              title: 'Kelembapan Udara',
              value: '${s.humidity.toStringAsFixed(0)}%',
              badgeText: humidBadge,
              badgeBgColor: humidBadgeBg,
              badgeTextColor: humidBadgeText,
              subtitle: 'Rentang Ideal: 60-85%',
              progressPercent: s.humidity / 100.0,
              progressColor: AppColors.accent,
            ),
            SensorCard(
              icon: s.rain ? Icons.grain_rounded : Icons.wb_sunny_outlined,
              title: 'Deteksi Hujan',
              value: rainValue,
              badgeText: rainBadge,
              badgeBgColor: rainBadgeBg,
              badgeTextColor: rainBadgeText,
              subtitle: rainSubtitle,
              customTrailing: Text(
                s.rain ? 'Deteksi Air Hujan' : 'Kondisi Kering',
                style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
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
              _buildNavItem(3, Icons.tune_rounded, 'Jadwal', isCompact),
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
