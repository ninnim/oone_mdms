import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/time_of_use.dart';
import '../common/blunest_data_table.dart';
import '../common/status_chip.dart';

class TimeOfUseTableColumns {
  static List<BluNestTableColumn<TimeOfUse>> buildAllColumns({
    String? sortBy,
    bool sortAscending = true,
    Function(TimeOfUse)? onEdit,
    Function(TimeOfUse)? onDelete,
    Function(TimeOfUse)? onView,
  }) {
    return [
      // Name column
      BluNestTableColumn<TimeOfUse>(
        key: 'name',
        title: 'Name',
        sortable: true,
        flex: 2,
        builder: (timeOfUse) => _buildNameColumn(timeOfUse),
      ),

      // Code column
      BluNestTableColumn<TimeOfUse>(
        key: 'code',
        title: 'Code',
        sortable: true,
        flex: 1,
        builder: (timeOfUse) => _buildCodeColumn(timeOfUse),
      ),

      // Description column
      BluNestTableColumn<TimeOfUse>(
        key: 'description',
        title: 'Description',
        sortable: true,
        flex: 2,
        builder: (timeOfUse) => _buildDescriptionColumn(timeOfUse),
      ),

      // Time Bands column
      BluNestTableColumn<TimeOfUse>(
        key: 'timeBands',
        title: 'Time Bands',
        flex: 1,
        builder: (timeOfUse) => _buildTimeBandsColumn(timeOfUse),
      ),

      // Channels column
      BluNestTableColumn<TimeOfUse>(
        key: 'channels',
        title: 'Channels',
        flex: 1,
        builder: (timeOfUse) => _buildChannelsColumn(timeOfUse),
      ),

      // Status column
      BluNestTableColumn<TimeOfUse>(
        key: 'status',
        title: 'Status',
        sortable: true,
        flex: 1,
        builder: (timeOfUse) => _buildStatusColumn(timeOfUse),
      ),

      // Actions column
      BluNestTableColumn<TimeOfUse>(
        key: 'actions',
        title: 'Actions',
        flex: 1,
        builder: (timeOfUse) =>
            _buildActionsColumn(timeOfUse, onEdit, onDelete, onView),
      ),
    ];
  }

  static List<BluNestTableColumn<TimeOfUse>> buildBluNestColumns({
    required List<String> visibleColumns,
    String? sortBy,
    bool sortAscending = true,
    Function(TimeOfUse)? onEdit,
    Function(TimeOfUse)? onDelete,
    Function(TimeOfUse)? onView,
  }) {
    final allColumns = buildAllColumns(
      sortBy: sortBy,
      sortAscending: sortAscending,
      onEdit: onEdit,
      onDelete: onDelete,
      onView: onView,
    );

    return allColumns.where((col) => visibleColumns.contains(col.key)).toList();
  }

  static Widget _buildNameColumn(TimeOfUse timeOfUse) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            timeOfUse.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: AppSizes.fontSizeMedium,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (timeOfUse.id != null) ...[
            const SizedBox(height: 2),
            Text(
              'ID: ${timeOfUse.id}',
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _buildCodeColumn(TimeOfUse timeOfUse) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Text(
          timeOfUse.code,
          style: const TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  static Widget _buildDescriptionColumn(TimeOfUse timeOfUse) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Text(
        timeOfUse.description.isNotEmpty
            ? timeOfUse.description
            : 'No description',
        style: TextStyle(
          fontSize: AppSizes.fontSizeSmall,
          color: timeOfUse.description.isNotEmpty
              ? AppColors.textPrimary
              : AppColors.textSecondary,
          fontStyle: timeOfUse.description.isNotEmpty
              ? FontStyle.normal
              : FontStyle.italic,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  static Widget _buildTimeBandsColumn(TimeOfUse timeOfUse) {
    final uniqueTimeBands = timeOfUse.timeOfUseDetails
        .map((d) => d.timeBandId)
        .toSet()
        .length;

    return Container(
      padding: const EdgeInsets.all(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.info.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          border: Border.all(color: AppColors.info.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.schedule,
              size: AppSizes.iconSmall,
              color: AppColors.info,
            ),
            const SizedBox(width: 4),
            Text(
              '$uniqueTimeBands',
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                fontWeight: FontWeight.w600,
                color: AppColors.info,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildChannelsColumn(TimeOfUse timeOfUse) {
    final uniqueChannels = timeOfUse.timeOfUseDetails
        .map((d) => d.channelId)
        .toSet()
        .length;

    return Container(
      padding: const EdgeInsets.all(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.settings_input_component,
              size: AppSizes.iconSmall,
              color: AppColors.warning,
            ),
            const SizedBox(width: 4),
            Text(
              '$uniqueChannels',
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                fontWeight: FontWeight.w600,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildStatusColumn(TimeOfUse timeOfUse) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: StatusChip(
        text: timeOfUse.statusText,
        type: timeOfUse.active ? StatusChipType.success : StatusChipType.error,
      ),
    );
  }

  static Widget _buildActionsColumn(
    TimeOfUse timeOfUse,
    Function(TimeOfUse)? onEdit,
    Function(TimeOfUse)? onDelete,
    Function(TimeOfUse)? onView,
  ) {
    return Container(
      alignment: Alignment.centerLeft,
      height: AppSizes.spacing40,
      child: PopupMenuButton<String>(
        icon: const Icon(
          Icons.more_vert,
          color: AppColors.textSecondary,
          size: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
        itemBuilder: (context) => [
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
              onView?.call(timeOfUse);
              break;
            case 'edit':
              onEdit?.call(timeOfUse);
              break;
            case 'delete':
              onDelete?.call(timeOfUse);
              break;
          }
        },
      ),
    );
  }

  // Available columns list for column visibility
  static List<String> get availableColumns => [
    'name',
    'code',
    'description',
    'timeBands',
    'channels',
    'status',
    'actions',
  ];

  // Get all column keys (alias for availableColumns)
  static List<String> getAllColumnKeys() => availableColumns;

  // Default visible columns
  static List<String> get defaultVisibleColumns => [
    'name',
    'code',
    'description',
    'timeBands',
    'channels',
    'status',
    'actions',
  ];

  // Default hidden columns
  static List<String> get defaultHiddenColumns => [];
}
