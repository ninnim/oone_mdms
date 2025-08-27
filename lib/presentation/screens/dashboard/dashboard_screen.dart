import 'package:flutter/material.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/status_chip.dart';
import '../../widgets/common/theme_switch.dart';
import '../../themes/app_theme.dart';
import '../../../core/constants/app_sizes.dart';
// import '../../../core/constants/app_colors.dart';
import '../../themes/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(context),
          const SizedBox(height: AppSizes.spacing24),
          _buildStatsGrid(context),
          const SizedBox(height: AppSizes.spacing24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildRecentDevicesCard(context),
                    const SizedBox(height: AppSizes.spacing24),
                    _buildDeviceStatusChart(context),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.spacing24),
              Expanded(
                child: Column(
                  children: [
                    _buildQuickActions(context),
                    const SizedBox(height: AppSizes.spacing24),
                    _buildSystemAlerts(context),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Device Management Dashboard',

                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor, //AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.spacing8),
              Text(
                'Welcome back! Here\'s an overview of your device network.',
                style: TextStyle(
                  fontSize: 16,
                  color: context
                      .textSecondaryColor, //AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
        const ThemeSwitch(isCompact: true, showLabel: false),
        // AppButton(
        //   text: 'Add Device',
        //   type: AppButtonType.primary,
        //   icon: const Icon(
        //     Icons.add,
        //     size: AppSizes.iconSmall,
        //     color: Theme.of(context).colorScheme.onInverseSurface,
        //   ),
        //   onPressed: () {
        //     // Navigate to devices screen or show add modal
        //   },
        // ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Total Devices',
            '1,247',
            Icons.electrical_services,
            context.primaryColor,
            '+12 this week',
          ),
        ),
        const SizedBox(width: AppSizes.spacing16),
        Expanded(
          child: _buildStatCard(
            context,
            'Active Devices',
            '1,189',
            Icons.power,
            context.successColor,
            '95.3% uptime',
          ),
        ),
        const SizedBox(width: AppSizes.spacing16),
        Expanded(
          child: _buildStatCard(
            context,
            'Offline Devices',
            '58',
            Icons.power_off,
            context.errorColor,
            '-3 since yesterday',
          ),
        ),
        const SizedBox(width: AppSizes.spacing16),
        Expanded(
          child: _buildStatCard(
            context,
            'Device Groups',
            '23',
            Icons.group_work,
            context.infoColor,
            '4 active groups',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
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
                color: context.successColor,
                size: AppSizes.iconSmall,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing16),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppSizes.spacing4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: context.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSizes.spacing8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: context.textTertiaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDevicesCard(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Recent Devices',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // Navigate to devices screen
                },
                child: Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing16),
          ...List.generate(
            5,
            (index) => _buildRecentDeviceItem(context, index),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDeviceItem(BuildContext context, int index) {
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            ),
            child: Icon(Icons.electrical_services, color: context.primaryColor),
          ),
          const SizedBox(width: AppSizes.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device['name']!,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSizes.spacing4),
                Text(
                  '${device['serial']!} • ${device['location']!}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
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

  Widget _buildDeviceStatusChart(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Device Status Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSizes.spacing24),
          Row(
            children: [
              Expanded(
                child: _buildStatusMetric(
                  context,
                  'Commissioned',
                  '852',
                  context.successColor,
                  68.3,
                ),
              ),
              Expanded(
                child: _buildStatusMetric(
                  context,
                  'Offline/None',
                  '337',
                  context.secondaryColor,
                  27.0,
                ),
              ),
              Expanded(
                child: _buildStatusMetric(
                  context,
                  'Renovation',
                  '58',
                  context.warningColor,
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
    BuildContext context,
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
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSizes.spacing4),
        Text(
          status,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSizes.spacing16),
          _buildQuickActionItem(
            context,
            'Add New Device',
            'Register a new device in the system',
            Icons.add_circle_outline,
            context.primaryColor,
          ),
          const SizedBox(height: AppSizes.spacing12),
          _buildQuickActionItem(
            context,
            'Device Groups',
            'Manage device groupings and categories',
            Icons.group_work,
            context.infoColor,
          ),
          const SizedBox(height: AppSizes.spacing12),
          _buildQuickActionItem(
            context,
            'System Reports',
            'Generate performance and usage reports',
            Icons.analytics,
            context.secondaryColor,
          ),
          const SizedBox(height: AppSizes.spacing12),
          _buildQuickActionItem(
            context,
            'Device Map',
            'View devices on interactive map',
            Icons.map,
            context.successColor,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSizes.spacing4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemAlerts(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Alerts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSizes.spacing16),
          _buildAlertItem(
            context,
            'Device Offline',
            '3 devices have been offline for >24h',
            Icons.warning,
            context.warningColor,
            '2 hours ago',
          ),
          const SizedBox(height: AppSizes.spacing12),
          _buildAlertItem(
            context,
            'High Usage',
            'Unusual power consumption detected',
            Icons.bolt,
            context.errorColor,
            '4 hours ago',
          ),
          const SizedBox(height: AppSizes.spacing12),
          _buildAlertItem(
            context,
            'Maintenance Due',
            '15 devices scheduled for maintenance',
            Icons.build,
            context.infoColor,
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
    BuildContext context,
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
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSizes.spacing4),
              Text(
                message,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: AppSizes.spacing4),
              Text(
                time,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
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
