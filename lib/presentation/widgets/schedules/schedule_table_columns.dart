import 'package:flutter/material.dart';
// import '../../../core/constants/app_colors.dart';
import '../../themes/app_theme.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/schedule.dart';
import '../common/blunest_data_table.dart';
import '../common/status_chip.dart';

class ScheduleTableColumns {
  static List<String> get availableColumns => [
    'No.',
    'Code',
    'Name',
    'Target Type',
    'Interval',
    'Next Billing Date',
    'Last Execute',
    'Status',
    'Actions',
  ];

  static List<BluNestTableColumn<Schedule>> getBluNestColumns({
    Function(Schedule)? onView,
    Function(Schedule)? onEdit,
    Function(Schedule)? onDelete,
    int currentPage = 1,
    int itemsPerPage = 25,
    List<Schedule>? schedules,
    required BuildContext context, 
  }) {
    return [
      // No. (Row Number)
      BluNestTableColumn<Schedule>(
        key: 'no',
        title: 'No.',
        flex: 1,
        sortable: false,
        builder: (schedule) {
          final index = schedules?.indexOf(schedule) ?? 0;
          final rowNumber = ((currentPage - 1) * itemsPerPage) + index + 1;
          return Container(
            alignment: Alignment.centerLeft,
            child: Text(
              '$rowNumber',
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                fontWeight: FontWeight.w500,
                color: context.textSecondaryColor,
              ),
            ),
          );
        },
      ),

      // Code
      BluNestTableColumn<Schedule>(
        key: 'code',
        title: 'Code',
        flex: 2,
        sortable: true,
        builder: (schedule) => Container(
          alignment: Alignment.centerLeft,
          child: Text(
            schedule.displayCode,
            style: TextStyle(
              fontSize: AppSizes.fontSizeMedium,
              fontWeight: FontWeight.w600,
              color: context.textPrimaryColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),

      // Name
      BluNestTableColumn<Schedule>(
        key: 'name',
        title: 'Name',
        flex: 3,
        sortable: true,
        builder: (schedule) => Container(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                schedule.displayName,
                style: TextStyle(
                  fontSize: AppSizes.fontSizeMedium,
                  fontWeight: FontWeight.w500,
                  color: context.textPrimaryColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              // if (schedule.cronExpression?.isNotEmpty == true) ...[
              //   const SizedBox(height: 2),
              //   Text(
              //     'Cron: ${schedule.cronExpression}',
              //     style: TextStyle(
              //       fontSize: AppSizes.fontSizeSmall,
              //       color: AppColors.textSecondary,
              //     ),
              //     overflow: TextOverflow.ellipsis,
              //   ),
              // ],
            ],
          ),
        ),
      ),

      // Target Type
      BluNestTableColumn<Schedule>(
        key: 'targetType',
        title: 'Target Type',
        flex: 2,
        sortable: true,
        builder: (schedule) => Container(
          alignment: Alignment.centerLeft,
          child: StatusChip(
            compact: true,
            text: schedule.displayTargetType,
            type: schedule.displayTargetType == 'Device'
                ? StatusChipType.info
                : StatusChipType.warning,
          ),
        ),
      ),

      // Interval
      BluNestTableColumn<Schedule>(
        key: 'interval',
        title: 'Interval',
        flex: 2,
        sortable: true,
        builder: (schedule) => Container(
          alignment: Alignment.centerLeft,
          child: Text(
            schedule.displayInterval,
            style: TextStyle(
              fontSize: AppSizes.fontSizeMedium,
              fontWeight: FontWeight.w500,
              color: context.textPrimaryColor,
            ),
          ),
        ),
      ),

      // Next Billing Date
      BluNestTableColumn<Schedule>(
        key: 'nextBillingDate',
        title: 'Next Billing Date',
        flex: 2,
        sortable: true,
        builder: (schedule) => Container(
          alignment: Alignment.centerLeft,
          child: Text(
            schedule.nextBillingDate != null
                ? _formatDate(schedule.nextBillingDate!)
                : 'Not set',
            style: TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              color: schedule.nextBillingDate != null
                  ? context.textPrimaryColor
                  : context.textSecondaryColor,
            ),
          ),
        ),
      ),

      // Last Execute
      BluNestTableColumn<Schedule>(
        key: 'lastExecute',
        title: 'Last Execute',
        flex: 2,
        sortable: true,
        builder: (schedule) => Container(
          alignment: Alignment.centerLeft,
          child: Text(
            schedule.lastExecutionTime != null
                ? _formatDateTime(schedule.lastExecutionTime!)
                : 'N/A',
            style: TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              color: schedule.lastExecutionTime != null
                  ? context.textPrimaryColor
                  : context.textSecondaryColor,
            ),
          ),
        ),
      ),

      // Status
      BluNestTableColumn<Schedule>(
        key: 'status',
        title: 'Status',
        flex: 1,
        sortable: true,
        builder: (schedule) => Container(
          alignment: Alignment.centerLeft,
          child: StatusChip(
            compact: true,
            text: schedule.displayStatus,
            type: _getStatusChipType(schedule.displayStatus),
          ),
        ),
      ),

      // Actions
      BluNestTableColumn<Schedule>(
        key: 'actions',
        title: 'Actions',
        flex: 1,
        isActions: true,
        sortable: false,
        builder: (schedule) => _buildActionsColumn(
          schedule,
          onEdit: onEdit,
          onDelete: onDelete,
          onView: onView,
          context: context,
        ),
      ),
    ];
  }

  static Widget _buildActionsColumn(
    Schedule schedule, {
    Function(Schedule)? onEdit,
    Function(Schedule)? onDelete,
    Function(Schedule)? onView,
    required BuildContext context,
  }) {
    return Container(
      alignment: Alignment.centerRight,
      height: AppSizes.spacing40,
      child: PopupMenuButton<String>(
        icon:  Icon(
          Icons.more_vert,
          color: context.textSecondaryColor,
          size: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
        itemBuilder: (context) => [
           PopupMenuItem<String>(
            value: 'view',
            child: Row(
              children: [
                Icon(Icons.visibility, size: 16, color: context.primaryColor),
                SizedBox(width: AppSizes.spacing8),
                Text('View Details'),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 16, color: context.warningColor),
                SizedBox(width: AppSizes.spacing8),
                Text('Edit'),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 16, color: context.errorColor),
                SizedBox(width: AppSizes.spacing8),
                Text('Delete', style: TextStyle(color: context.errorColor)),
              ],
            ),
          ),
        ],
        onSelected: (value) {
          switch (value) {
            case 'view':
              onView?.call(schedule);
              break;
            case 'edit':
              onEdit?.call(schedule);
              break;
            case 'delete':
              onDelete?.call(schedule);
              break;
          }
        },
      ),
    );
  }

  static StatusChipType _getStatusChipType(String status) {
    switch (status.toLowerCase()) {
      case 'enabled':
      case 'active':
        return StatusChipType.success;
      case 'disabled':
      case 'inactive':
        return StatusChipType.error;
      case 'paused':
        return StatusChipType.warning;
      default:
        return StatusChipType.secondary;
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}





