import 'package:flutter/material.dart';
import '../../../core/models/device.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class DeviceSummaryCard extends StatelessWidget {
  final List<Device> devices;

  const DeviceSummaryCard({super.key, required this.devices});

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
          //       'Device Summary',
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
                  'Total Devices',
                  stats.totalDevices.toString(),
                  Icons.devices,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSizes.spacing12),
              Expanded(
                child: _buildStatCard(
                  'Commissioned',
                  stats.commissionedDevices.toString(),
                  Icons.check_circle_outline,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: AppSizes.spacing12),
              Expanded(
                child: _buildStatCard(
                  'Discommissioned / None',
                  stats.discommissionedDevices.toString(),
                  Icons.electric_meter,
                  AppColors.warning,
                ),
              ),
              const SizedBox(width: AppSizes.spacing12),
              Expanded(
                child: _buildStatCard(
                  'Connected',
                  stats.connectedDevices.toString(),
                  Icons.link,
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

  DeviceStats _calculateStats() {
    int totalDevices = devices.length;
    int commissionedDevices = devices
        .where((device) => device.status.toLowerCase() == 'commissioned')
        .length;
    int smartMeters = devices
        .where((device) => device.deviceType.toLowerCase() == 'smart meter')
        .length;
    int connectedDevices = devices
        .where(
          (device) =>
              device.linkStatus.toLowerCase() != 'none' &&
              device.linkStatus.isNotEmpty,
        )
        .length;
    int discommissionedDevices = devices
        .where(
          (device) =>
              device.status.toLowerCase() == 'discommissioned' ||
              device.status.toLowerCase() == 'none',
        )
        .length;

    return DeviceStats(
      totalDevices: totalDevices,
      commissionedDevices: commissionedDevices,
      smartMeters: smartMeters,
      connectedDevices: connectedDevices,
      discommissionedDevices: discommissionedDevices,
    );
  }
}

class DeviceStats {
  final int totalDevices;
  final int commissionedDevices;
  final int smartMeters;
  final int connectedDevices;
  final int discommissionedDevices;

  DeviceStats({
    required this.totalDevices,
    required this.commissionedDevices,
    required this.smartMeters,
    required this.connectedDevices,
    required this.discommissionedDevices,
  });
}
