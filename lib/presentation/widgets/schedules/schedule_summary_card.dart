import 'package:flutter/material.dart';
import '../../../core/models/schedule.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class ScheduleSummaryCard extends StatelessWidget {
  final List<Schedule> schedules;

  const ScheduleSummaryCard({super.key, required this.schedules});

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();

    return Container(
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
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  stats.totalSchedules.toString(),
                  Icons.schedule,
                  const Color(0xFF6366F1), // Indigo for total
                ),
              ),
              const SizedBox(width: AppSizes.spacing12),
              Expanded(
                child: _buildStatCard(
                  'Enabled',
                  stats.enabledSchedules.toString(),
                  Icons.check_circle_outline,
                  const Color(0xFF059669), // Green matching Enabled status
                ),
              ),
              const SizedBox(width: AppSizes.spacing12),
              Expanded(
                child: _buildStatCard(
                  'Disabled',
                  stats.disabledSchedules.toString(),
                  Icons.cancel_outlined,
                  const Color(0xFFDC2626), // Red matching Disabled status
                ),
              ),
              const SizedBox(width: AppSizes.spacing12),
              Expanded(
                child: _buildStatCard(
                  'By Group',
                  stats.scheduleByGroup.toString(),
                  Icons.group_work,
                  const Color(0xFFD97706), // Orange matching Group target type
                ),
              ),
              const SizedBox(width: AppSizes.spacing12),
              Expanded(
                child: _buildStatCard(
                  'By Device',
                  stats.scheduleByDevice.toString(),
                  Icons.device_hub,
                  const Color(0xFF2563EB), // Blue matching Device target type
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
            style: const TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  ScheduleStats _calculateStats() {
    int totalSchedules = schedules.length;
    int enabledSchedules = schedules
        .where((schedule) => schedule.displayStatus.toLowerCase() == 'enabled')
        .length;
    int disabledSchedules = schedules
        .where((schedule) => schedule.displayStatus.toLowerCase() == 'disabled')
        .length;
    int scheduleByGroup = schedules
        .where(
          (schedule) => schedule.displayTargetType.toLowerCase() == 'group',
        )
        .length;
    int scheduleByDevice = schedules
        .where(
          (schedule) => schedule.displayTargetType.toLowerCase() == 'device',
        )
        .length;

    return ScheduleStats(
      totalSchedules: totalSchedules,
      enabledSchedules: enabledSchedules,
      disabledSchedules: disabledSchedules,
      scheduleByGroup: scheduleByGroup,
      scheduleByDevice: scheduleByDevice,
    );
  }
}

class ScheduleStats {
  final int totalSchedules;
  final int enabledSchedules;
  final int disabledSchedules;
  final int scheduleByGroup;
  final int scheduleByDevice;

  ScheduleStats({
    required this.totalSchedules,
    required this.enabledSchedules,
    required this.disabledSchedules,
    required this.scheduleByGroup,
    required this.scheduleByDevice,
  });
}
