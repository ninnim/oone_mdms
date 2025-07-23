import 'package:flutter/material.dart';
import '../../../core/models/device_group.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class DeviceGroupSummaryCard extends StatelessWidget {
  final List<DeviceGroup> deviceGroups;

  const DeviceGroupSummaryCard({super.key, required this.deviceGroups});

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();

    return Container(
      // margin: const EdgeInsets.only(bottom: AppSizes.spacing16),
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row(
          //   children: [
          //     Icon(
          //       Icons.dashboard_outlined,
          //       color: AppColors.primary,
          //       size: 24,
          //     ),
          //     const SizedBox(width: AppSizes.spacing12),
          //     Text(
          //       'Device Group Summary',
          //       style: TextStyle(
          //         fontSize: AppSizes.fontSizeLarge,
          //         fontWeight: FontWeight.bold,
          //         color: AppColors.textPrimary,
          //       ),
          //     ),
          //   ],
          // ),
          // const SizedBox(height: AppSizes.spacing16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Groups',
                  stats.totalGroups.toString(),
                  Icons.groups,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSizes.spacing12),
              Expanded(
                child: _buildStatCard(
                  'Active Groups',
                  stats.activeGroups.toString(),
                  Icons.check_circle_outline,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: AppSizes.spacing12),
              Expanded(
                child: _buildStatCard(
                  'Empty Groups',
                  stats.emptyGroups.toString(),
                  Icons.remove_circle_outline,
                  AppColors.warning,
                ),
              ),
              const SizedBox(width: AppSizes.spacing12),
              Expanded(
                child: _buildStatCard(
                  'Total Devices',
                  stats.totalDevices.toString(),
                  Icons.devices,
                  AppColors.info,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing8),
          Text(
            title,
            style: TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  DeviceGroupStats _calculateStats() {
    int totalGroups = deviceGroups.length;
    int activeGroups = deviceGroups
        .where((group) => group.devices != null && group.devices!.isNotEmpty)
        .length;
    int emptyGroups = deviceGroups
        .where((group) => group.devices == null || group.devices!.isEmpty)
        .length;
    int totalDevices = deviceGroups.fold<int>(
      0,
      (sum, group) => sum + (group.devices?.length ?? 0),
    );

    return DeviceGroupStats(
      totalGroups: totalGroups,
      activeGroups: activeGroups,
      emptyGroups: emptyGroups,
      totalDevices: totalDevices,
    );
  }
}

class DeviceGroupStats {
  final int totalGroups;
  final int activeGroups;
  final int emptyGroups;
  final int totalDevices;

  DeviceGroupStats({
    required this.totalGroups,
    required this.activeGroups,
    required this.emptyGroups,
    required this.totalDevices,
  });
}
