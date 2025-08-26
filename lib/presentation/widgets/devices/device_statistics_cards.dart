import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../presentation/themes/app_theme.dart';
import '../../../core/models/device.dart';

// Updated statistics cards with smaller design
class DeviceStatisticsCards extends StatelessWidget {
  final List<Device> devices;
  final bool isLoading;

  const DeviceStatisticsCards({
    super.key,
    required this.devices,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStatistics();

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Total Devices',
            value: stats['total'].toString(),
            icon: Icons.devices,
            color: context.primaryColor,
          ),
        ),
        const SizedBox(width: AppSizes.spacing6), // Reduced from spacing12
        Expanded(
          child: _buildStatCard(
            title: 'Commissioned',
            value: stats['commissioned'].toString(),
            icon: Icons.check_circle,
            color: context.successColor,
          ),
        ),
        const SizedBox(width: AppSizes.spacing6), // Reduced from spacing12
        Expanded(
          child: _buildStatCard(
            title: 'Decommissioned',
            value: stats['decommissioned'].toString(),
            icon: Icons.cancel,
            color: context.errorColor,
          ),
        ),
        const SizedBox(width: AppSizes.spacing6), // Reduced from spacing12
        Expanded(
          child: _buildStatCard(
            title: 'MULTIDRIVE',
            value: stats['multidrive'].toString(),
            icon: Icons.electrical_services,
            color: context.warningColor,
          ),
        ),
        const SizedBox(width: AppSizes.spacing6), // Reduced from spacing12
        Expanded(
          child: _buildStatCard(
            title: 'E-POWER',
            value: stats['epower'].toString(),
            icon: Icons.power,
            color: context.infoColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Builder(
      builder: (context) => Container(
        height: 60, // Reduced from 80
        padding: const EdgeInsets.all(
          AppSizes.spacing8,
        ), // Reduced from spacing12
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          border: Border.all(color: context.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          // Changed from Column to Row for horizontal layout
          children: [
            Container(
              padding: const EdgeInsets.all(
                AppSizes.spacing2,
              ), // Reduced from spacing4
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              ),
              child: Icon(
                icon,
                color: color,
                size: 14, // Reduced from AppSizes.iconSmall (16)
              ),
            ),
            const SizedBox(width: AppSizes.spacing6), // Reduced from spacing8
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16, // Reduced from 18
                      fontWeight: FontWeight.bold,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 10, // Reduced from AppSizes.fontSizeSmall (12)
                      color: context.textPrimaryColor.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              SizedBox(
                width: 12, // Reduced from 14
                height: 12, // Reduced from 14
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    context.textPrimaryColor.withOpacity(0.7),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Map<String, int> _calculateStatistics() {
    if (isLoading) {
      return {
        'total': 0,
        'commissioned': 0,
        'decommissioned': 0,
        'multidrive': 0,
        'epower': 0,
      };
    }

    final total = devices.length;
    final commissioned = devices
        .where((d) => d.status == 'Commissioned')
        .length;
    final decommissioned = devices
        .where((d) => d.status == 'Decommissioned')
        .length;
    final multidrive = devices
        .where((d) => d.linkStatus == 'MULTIDRIVE')
        .length;
    final epower = devices.where((d) => d.linkStatus == 'E-POWER').length;

    return {
      'total': total,
      'commissioned': commissioned,
      'decommissioned': decommissioned,
      'multidrive': multidrive,
      'epower': epower,
    };
  }
}
