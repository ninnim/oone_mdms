import 'package:flutter/material.dart';
import '../../widgets/common/app_card.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsCards(),
          const SizedBox(height: AppSizes.spacing24),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildRecentDevices(),
                ),
                const SizedBox(width: AppSizes.spacing24),
                Expanded(
                  child: _buildQuickActions(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Devices',
            '1,234',
            Icons.devices,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSizes.spacing16),
        Expanded(
          child: _buildStatCard(
            'Active Devices',
            '987',
            Icons.check_circle,
            AppColors.success,
          ),
        ),
        const SizedBox(width: AppSizes.spacing16),
        Expanded(
          child: _buildStatCard(
            'Offline Devices',
            '47',
            Icons.error,
            AppColors.error,
          ),
        ),
        const SizedBox(width: AppSizes.spacing16),
        Expanded(
          child: _buildStatCard(
            'Groups',
            '23',
            Icons.group_work,
            AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
            child: Icon(
              icon,
              color: color,
              size: AppSizes.iconLarge,
            ),
          ),
          const SizedBox(width: AppSizes.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeXXLarge,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeSmall,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDevices() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppCardHeader(
            title: 'Recent Devices',
            subtitle: 'Latest added devices',
          ),
          const SizedBox(height: AppSizes.spacing16),
          Expanded(
            child: ListView.separated(
              itemCount: 5,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    ),
                    child: const Icon(
                      Icons.memory,
                      color: AppColors.primary,
                      size: AppSizes.iconMedium,
                    ),
                  ),
                  title: Text(
                    'Device ${index + 1}',
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Serial: 000${219151707 + index}',
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeSmall,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.spacing8,
                      vertical: AppSizes.spacing4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    ),
                    child: const Text(
                      'Online',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: AppSizes.fontSizeSmall,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppCardHeader(
            title: 'Quick Actions',
            subtitle: 'Common tasks',
          ),
          const SizedBox(height: AppSizes.spacing16),
          Expanded(
            child: Column(
              children: [
                _buildQuickActionItem(
                  'Add New Device',
                  'Register a new device',
                  Icons.add_circle_outline,
                  AppColors.primary,
                ),
                const SizedBox(height: AppSizes.spacing12),
                _buildQuickActionItem(
                  'Create Group',
                  'Group devices together',
                  Icons.group_add,
                  AppColors.success,
                ),
                const SizedBox(height: AppSizes.spacing12),
                _buildQuickActionItem(
                  'Generate Report',
                  'Export device data',
                  Icons.assessment,
                  AppColors.warning,
                ),
                const SizedBox(height: AppSizes.spacing12),
                _buildQuickActionItem(
                  'System Settings',
                  'Configure system',
                  Icons.settings,
                  AppColors.secondary,
                ),
              ],
            ),
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
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: AppSizes.iconMedium,
          ),
          const SizedBox(width: AppSizes.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeMedium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeSmall,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppColors.textTertiary,
            size: AppSizes.iconSmall,
          ),
        ],
      ),
    );
  }
}
