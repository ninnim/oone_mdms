import 'package:flutter/material.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/status_chip.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(),
          const SizedBox(height: AppSizes.spacing24),
          _buildStatsGrid(),
          const SizedBox(height: AppSizes.spacing24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildRecentDevicesCard(),
                    const SizedBox(height: AppSizes.spacing24),
                    _buildDeviceStatusChart(),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.spacing24),
              Expanded(
                child: Column(
                  children: [
                    _buildQuickActions(),
                    const SizedBox(height: AppSizes.spacing24),
                    _buildSystemAlerts(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Device Management Dashboard',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.spacing8),
              Text(
                'Welcome back! Here\'s an overview of your device network.',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        AppButton(
          text: 'Add Device',
          type: AppButtonType.primary,
          icon: const Icon(
            Icons.add,
            size: AppSizes.iconSmall,
            color: AppColors.textInverse,
          ),
          onPressed: () {
            // Navigate to devices screen or show add modal
          },
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Devices',
            '1,247',
            Icons.electrical_services,
            AppColors.primary,
            '+12 this week',
          ),
        ),
        const SizedBox(width: AppSizes.spacing16),
        Expanded(
          child: _buildStatCard(
            'Active Devices',
            '1,189',
            Icons.power,
            AppColors.success,
            '95.3% uptime',
          ),
        ),
        const SizedBox(width: AppSizes.spacing16),
        Expanded(
          child: _buildStatCard(
            'Offline Devices',
            '58',
            Icons.power_off,
            AppColors.error,
            '-3 since yesterday',
          ),
        ),
        const SizedBox(width: AppSizes.spacing16),
        Expanded(
          child: _buildStatCard(
            'Device Groups',
            '23',
            Icons.group_work,
            AppColors.info,
            '4 active groups',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.spacing8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                ),
                child: Icon(icon, color: color, size: AppSizes.iconLarge),
              ),
              const Spacer(),
              Icon(
                Icons.trending_up,
                color: AppColors.success,
                size: AppSizes.iconSmall,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.spacing4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSizes.spacing8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDevicesCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Recent Devices',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // Navigate to devices screen
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing16),
          ...List.generate(5, (index) => _buildRecentDeviceItem(index)),
        ],
      ),
    );
  }

  Widget _buildRecentDeviceItem(int index) {
    final devices = [
      {
        'serial': 'SN000219151707',
        'name': 'Smart Meter Building A',
        'status': 'Commissioned',
        'location': '123 Main St',
      },
      {
        'serial': 'SN000252240670',
        'name': 'Industrial Meter Unit 1',
        'status': 'Commissioned',
        'location': '456 Industrial Ave',
      },
      {
        'serial': 'SN123456789',
        'name': 'Residential Meter X200',
        'status': 'None',
        'location': 'Khan Sen Sok',
      },
      {
        'serial': 'SDN001',
        'name': 'Test Device Campus',
        'status': 'Renovation',
        'location': 'Unnamed Road',
      },
      {
        'serial': 'SN987654321',
        'name': 'Energy Monitor Pro',
        'status': 'Commissioned',
        'location': 'Downtown Plaza',
      },
    ];

    final device = devices[index];
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacing8),
      padding: const EdgeInsets.all(AppSizes.spacing12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            ),
            child: const Icon(
              Icons.electrical_services,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSizes.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device['name']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.spacing4),
                Text(
                  '${device['serial']!} • ${device['location']!}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          StatusChip(
            text: device['status']!,
            type: _getStatusChipType(device['status']!),
            compact: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceStatusChart() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Device Status Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.spacing24),
          Row(
            children: [
              Expanded(
                child: _buildStatusMetric(
                  'Commissioned',
                  '852',
                  AppColors.success,
                  68.3,
                ),
              ),
              Expanded(
                child: _buildStatusMetric(
                  'Offline/None',
                  '337',
                  AppColors.secondary,
                  27.0,
                ),
              ),
              Expanded(
                child: _buildStatusMetric(
                  'Renovation',
                  '58',
                  AppColors.warning,
                  4.7,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMetric(
    String status,
    String count,
    Color color,
    double percentage,
  ) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${percentage.toInt()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.spacing8),
        Text(
          count,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.spacing4),
        Text(
          status,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.spacing16),
          _buildQuickActionItem(
            'Add New Device',
            'Register a new device in the system',
            Icons.add_circle_outline,
            AppColors.primary,
          ),
          const SizedBox(height: AppSizes.spacing12),
          _buildQuickActionItem(
            'Device Groups',
            'Manage device groupings and categories',
            Icons.group_work,
            AppColors.info,
          ),
          const SizedBox(height: AppSizes.spacing12),
          _buildQuickActionItem(
            'System Reports',
            'Generate performance and usage reports',
            Icons.analytics,
            AppColors.secondary,
          ),
          const SizedBox(height: AppSizes.spacing12),
          _buildQuickActionItem(
            'Device Map',
            'View devices on interactive map',
            Icons.map,
            AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.spacing8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            ),
            child: Icon(icon, color: color, size: AppSizes.iconMedium),
          ),
          const SizedBox(width: AppSizes.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.spacing4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildSystemAlerts() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Alerts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.spacing16),
          _buildAlertItem(
            'Device Offline',
            '3 devices have been offline for >24h',
            Icons.warning,
            AppColors.warning,
            '2 hours ago',
          ),
          const SizedBox(height: AppSizes.spacing12),
          _buildAlertItem(
            'High Usage',
            'Unusual power consumption detected',
            Icons.bolt,
            AppColors.error,
            '4 hours ago',
          ),
          const SizedBox(height: AppSizes.spacing12),
          _buildAlertItem(
            'Maintenance Due',
            '15 devices scheduled for maintenance',
            Icons.build,
            AppColors.info,
            '1 day ago',
          ),
          const SizedBox(height: AppSizes.spacing16),
          AppButton(
            text: 'View All Alerts',
            type: AppButtonType.secondary,
            onPressed: () {},
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(
    String title,
    String message,
    IconData icon,
    Color color,
    String time,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSizes.spacing4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          ),
          child: Icon(icon, color: color, size: AppSizes.iconSmall),
        ),
        const SizedBox(width: AppSizes.spacing12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.spacing4),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.spacing4),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  StatusChipType _getStatusChipType(String status) {
    switch (status.toLowerCase()) {
      case 'commissioned':
        return StatusChipType.commissioned;
      case 'renovation':
        return StatusChipType.renovation;
      case 'construction':
        return StatusChipType.construction;
      default:
        return StatusChipType.none;
    }
  }
}
