import 'package:flutter/material.dart';
import '../../../core/models/schedule.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class ScheduleKanbanView extends StatelessWidget {
  final List<Schedule> schedules;
  final Function(Schedule) onScheduleSelected;
  final Function(Schedule)? onScheduleEdit;
  final Function(Schedule)? onScheduleDelete;
  final Function(Schedule)? onScheduleView;
  final bool isLoading;
  final bool enablePagination;
  final int itemsPerPage;

  const ScheduleKanbanView({
    super.key,
    required this.schedules,
    required this.onScheduleSelected,
    this.onScheduleEdit,
    this.onScheduleDelete,
    this.onScheduleView,
    this.isLoading = false,
    this.enablePagination = true,
    this.itemsPerPage = 25,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final groupedSchedules = _groupSchedulesByStatus();

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: groupedSchedules.entries.map((entry) {
            return _buildStatusColumn(entry.key, entry.value);
          }).toList(),
        ),
      ),
    );
  }

  Map<String, List<Schedule>> _groupSchedulesByStatus() {
    final Map<String, List<Schedule>> grouped = {'Enabled': [], 'Disabled': []};

    for (final schedule in schedules) {
      final status = schedule.displayStatus;
      if (status.toLowerCase() == 'enabled') {
        grouped['Enabled']!.add(schedule);
      } else {
        grouped['Disabled']!.add(schedule);
      }
    }

    return grouped;
  }

  Widget _buildStatusColumn(String status, List<Schedule> schedules) {
    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'enabled':
        statusColor = const Color(0xFF059669); // Green matching Enabled status
        statusIcon = Icons.play_circle_outline;
        break;
      case 'disabled':
        statusColor = const Color(0xFFDC2626); // Red matching Disabled status
        statusIcon = Icons.pause_circle_outline;
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.help_outline;
    }

    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: AppSizes.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column header
          Container(
            padding: const EdgeInsets.all(AppSizes.spacing16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radiusMedium),
                topRight: Radius.circular(AppSizes.radiusMedium),
              ),
              border: Border(
                bottom: BorderSide(color: statusColor.withOpacity(0.2)),
              ),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: AppSizes.spacing8),
                Text(
                  status,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                    fontSize: AppSizes.fontSizeMedium,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing8,
                    vertical: AppSizes.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  ),
                  child: Text(
                    '${schedules.length}',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeSmall,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Schedule cards
          Expanded(
            child: schedules.isEmpty
                ? _buildEmptyState(status)
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSizes.spacing8),
                    itemCount: schedules.length,
                    itemBuilder: (context, index) {
                      return _buildScheduleCard(schedules[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule_outlined,
            size: 48,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: AppSizes.spacing12),
          Text(
            'No ${status.toLowerCase()} schedules',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppSizes.fontSizeSmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(Schedule schedule) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacing8),
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => onScheduleSelected(schedule),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name, status, and actions
            Row(
              children: [
                Expanded(
                  child: Text(
                    schedule.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: AppSizes.fontSizeMedium,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSizes.spacing8),
                _buildScheduleStatusChip(
                  schedule.displayStatus,
                  schedule.isActive,
                ),
                const SizedBox(width: AppSizes.spacing4),
                _buildActionsDropdown(schedule),
              ],
            ),
            const SizedBox(height: AppSizes.spacing12),

            // Schedule details
            _buildDetailRow(Icons.code, 'Code', schedule.displayCode),
            const SizedBox(height: AppSizes.spacing8),
            _buildDetailRow(
              Icons.device_hub,
              'Target',
              schedule.displayTargetType,
            ),
            const SizedBox(height: AppSizes.spacing8),
            _buildDetailRow(
              Icons.schedule,
              'Interval',
              schedule.displayInterval,
            ),

            if (schedule.nextBillingDate != null) ...[
              const SizedBox(height: AppSizes.spacing8),
              _buildDetailRow(
                Icons.event,
                'Next Run',
                _formatDate(schedule.nextBillingDate!),
              ),
            ],

            // Footer with retry count
            if (schedule.retryCount > 0) ...[
              const SizedBox(height: AppSizes.spacing12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacing8,
                  vertical: AppSizes.spacing4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  border: Border.all(color: AppColors.info.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, size: 14, color: AppColors.info),
                    const SizedBox(width: AppSizes.spacing4),
                    Text(
                      'Retries: ${schedule.retryCount}',
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeExtraSmall,
                        color: AppColors.info,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleStatusChip(String status, bool isActive) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;

    if (status.toLowerCase() == 'disabled') {
      // Disabled - Red #DC2626
      backgroundColor = const Color(0xFFDC2626).withOpacity(0.1);
      borderColor = const Color(0xFFDC2626).withOpacity(0.3);
      textColor = const Color(0xFFDC2626);
    } else {
      // Enabled - Green
      backgroundColor = const Color(0xFF059669).withOpacity(0.1);
      borderColor = const Color(0xFF059669).withOpacity(0.3);
      textColor = const Color(0xFF059669);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing8,
        vertical: AppSizes.spacing4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: AppSizes.fontSizeSmall,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: AppSizes.iconSmall, color: AppColors.textSecondary),
        const SizedBox(width: AppSizes.spacing8),
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: AppSizes.spacing4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildActionsDropdown(Schedule schedule) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert,
        color: AppColors.textSecondary,
        size: 16,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      itemBuilder: (context) => [
        if (onScheduleView != null)
          const PopupMenuItem<String>(
            value: 'view',
            child: Row(
              children: [
                Icon(Icons.visibility, size: 16, color: AppColors.primary),
                SizedBox(width: AppSizes.spacing8),
                Text('View Details'),
              ],
            ),
          ),
        if (onScheduleEdit != null)
          const PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 16, color: AppColors.warning),
                SizedBox(width: AppSizes.spacing8),
                Text('Edit'),
              ],
            ),
          ),
        if (onScheduleDelete != null)
          const PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 16, color: AppColors.error),
                SizedBox(width: AppSizes.spacing8),
                Text('Delete', style: TextStyle(color: AppColors.error)),
              ],
            ),
          ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'view':
            onScheduleView?.call(schedule);
            break;
          case 'edit':
            onScheduleEdit?.call(schedule);
            break;
          case 'delete':
            onScheduleDelete?.call(schedule);
            break;
        }
      },
    );
  }
}
