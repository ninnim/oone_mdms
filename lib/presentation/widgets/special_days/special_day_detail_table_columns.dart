import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/special_day.dart';
import '../common/blunest_data_table.dart';

class SpecialDayDetailTableColumns {
  static List<BluNestTableColumn<SpecialDayDetail>> getBluNestColumns({
    required BuildContext context,
    required Function(SpecialDayDetail) onEdit,
    required Function(SpecialDayDetail) onDelete,
    required List<SpecialDayDetail> specialDayDetails,
    String? sortColumn,
    bool sortAscending = true,
  }) {
    return [
      BluNestTableColumn<SpecialDayDetail>(
        key: 'no',
        title: 'No.',
        flex: 1,
        sortable: false,
        builder: (detail) {
          final index = specialDayDetails.indexOf(detail) + 1;
          return Container(
            alignment: Alignment.centerLeft,
            height: AppSizes.rowHeight,
            child: Text(
              index.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          );
        },
      ),
      BluNestTableColumn<SpecialDayDetail>(
        key: 'name',
        title: 'Name',
        flex: 2,
        sortable: true,
        builder: (detail) => Container(
          alignment: Alignment.centerLeft,
          child: Text(
            detail.name,
            style: TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      BluNestTableColumn<SpecialDayDetail>(
        key: 'description',
        title: 'Description',
        flex: 2,
        sortable: true,
        builder: (detail) => Container(
          alignment: Alignment.centerLeft,
          child: Text(
            detail.description.isEmpty ? '-' : detail.description,
            style: TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      BluNestTableColumn<SpecialDayDetail>(
        key: 'startDate',
        title: 'Start Date',
        flex: 3,
        sortable: true,
        builder: (detail) => Container(
          alignment: Alignment.centerLeft,
          child: _buildStartDateColumn(detail),
        ),
      ),
      BluNestTableColumn<SpecialDayDetail>(
        key: 'endDate',
        title: 'End Date',
        flex: 3,
        sortable: true,
        builder: (detail) => Container(
          alignment: Alignment.centerLeft,
          child: _buildEndDateColumn(detail),
        ),
      ),
      // BluNestTableColumn<SpecialDayDetail>(
      //   key: 'status',
      //   title: 'Status',
      //   flex: 1,
      //   sortable: true,
      //   builder: (detail) => Container(
      //     alignment: Alignment.centerLeft,
      //     child: StatusChip(
      //       text: detail.active ? 'Active' : 'Inactive',
      //       type: detail.active
      //           ? StatusChipType.success
      //           : StatusChipType.secondary,
      //       compact: true,
      //     ),
      //   ),
      // ),
      BluNestTableColumn<SpecialDayDetail>(
        key: 'actions',
        title: 'Actions',
        flex: 1,
        sortable: false,
        builder: (detail) => Container(
          alignment: Alignment.center,
          child: PopupMenuButton<String>(
            tooltip: 'More actions',
            onSelected: (value) {
              print(
                '🔄 Special day detail action selected: $value for detail: ${detail.name} (ID: ${detail.id})',
              );
              switch (value) {
                case 'edit':
                  print(
                    '🔄 Calling onEdit for special day detail: ${detail.name}',
                  );
                  onEdit(detail);
                  break;
                case 'delete':
                  print(
                    '🔄 Calling onDelete for special day detail: ${detail.name}',
                  );
                  onDelete(detail);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
            child: Icon(
              Icons.more_vert,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    ];
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static Widget _buildStartDateColumn(SpecialDayDetail detail) {
    final now = DateTime.now();
    final startDate = detail.startDate;
    final endDate = detail.endDate;
    final isActive =
        startDate.isBefore(now.add(const Duration(days: 1))) &&
        endDate.isAfter(now.subtract(const Duration(days: 1)));
    final isUpcoming = startDate.isAfter(now);
    final isPast = endDate.isBefore(now);

    Color textColor;
    Color? backgroundColor;
    IconData? icon;

    if (isPast) {
      textColor = AppColors.textSecondary;
      backgroundColor = AppColors.textSecondary.withOpacity(0.1);
      icon = Icons.history;
    } else if (isActive) {
      textColor = AppColors.success;
      backgroundColor = AppColors.success.withOpacity(0.1);
      icon = Icons.play_circle_filled;
    } else if (isUpcoming) {
      textColor = AppColors.primary;
      backgroundColor = AppColors.primary.withOpacity(0.1);
      icon = Icons.schedule;
    } else {
      textColor = AppColors.textPrimary;
      backgroundColor = Colors.transparent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing8,
        vertical: AppSizes.spacing4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            _formatDate(startDate),
            style: TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildEndDateColumn(SpecialDayDetail detail) {
    final now = DateTime.now();
    final startDate = detail.startDate;
    final endDate = detail.endDate;
    final isExpired = endDate.isBefore(now);
    final isExpiringSoon = !isExpired && endDate.difference(now).inDays <= 7;
    final isActive =
        startDate.isBefore(now.add(const Duration(days: 1))) &&
        endDate.isAfter(now.subtract(const Duration(days: 1)));
    final isUpcoming = startDate.isAfter(now);

    Color textColor;
    Color? backgroundColor;
    IconData? icon;
    String? tooltip;

    if (isExpired) {
      textColor = AppColors.error;
      backgroundColor = AppColors.error.withOpacity(0.1);
      icon = Icons.cancel;
      tooltip = 'Expired';
    } else if (isExpiringSoon) {
      textColor = AppColors.warning;
      backgroundColor = AppColors.warning.withOpacity(0.1);
      icon = Icons.warning_amber;
      tooltip = 'Expiring soon';
    } else if (isActive) {
      textColor = AppColors.success;
      backgroundColor = AppColors.success.withOpacity(0.1);
      icon = Icons.check_circle;
      tooltip = 'Currently active';
    } else if (isUpcoming) {
      textColor = AppColors.primary;
      backgroundColor = AppColors.primary.withOpacity(0.1);
      icon = Icons.access_time;
      tooltip = 'Upcoming';
    } else {
      textColor = AppColors.textPrimary;
      backgroundColor = Colors.transparent;
    }

    Widget content = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing8,
        vertical: AppSizes.spacing4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            _formatDate(endDate),
            style: TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: content);
    }

    return content;
  }
}
