import 'package:flutter/material.dart';
import 'package:mdms_clone/presentation/widgets/common/status_chip.dart';
import '../../themes/app_theme.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/time_of_use.dart';
import '../common/blunest_data_table.dart';

class TimeOfUseTableColumns {
  static List<BluNestTableColumn<TimeOfUse>> buildAllColumns({
    String? sortBy,
    bool sortAscending = true,
    Function(TimeOfUse)? onEdit,
    Function(TimeOfUse)? onDelete,
    Function(TimeOfUse)? onView,
    required BuildContext context,
    int currentPage = 1,
    int itemsPerPage = 25,
    List<TimeOfUse>? data,
  }) {
    return [
      // No. (Row Number)
      BluNestTableColumn<TimeOfUse>(
        key: 'no',
        title: 'No.',
        flex: 1,
        sortable: false,
        builder: (timeOfUse) {
          final index = data?.indexOf(timeOfUse) ?? 0;
          final rowNumber = ((currentPage - 1) * itemsPerPage) + index + 1;
          return Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(vertical: 8),
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
      // Code column
      BluNestTableColumn<TimeOfUse>(
        key: 'code',
        title: 'Code',
        sortable: true,
        flex: 1,
        builder: (timeOfUse) => Container(
          alignment: Alignment.centerLeft,
          child: StatusChip(
            text: timeOfUse.code,
            type: StatusChipType.info,
            compact: true,
          ),
        ),
      ),
      // Name column
      BluNestTableColumn<TimeOfUse>(
        key: 'name',
        title: 'Name',
        sortable: true,
        flex: 2,
        builder: (timeOfUse) => _buildNameColumn(timeOfUse, context),
      ),

      // Time Bands column
      BluNestTableColumn<TimeOfUse>(
        key: 'timeBands',
        title: 'Time Bands',
        flex: 1,
        builder: (timeOfUse) => _buildTimeBandsColumn(timeOfUse, context),
      ),

      // Channels column
      BluNestTableColumn<TimeOfUse>(
        key: 'channels',
        title: 'Channels',
        flex: 1,
        builder: (timeOfUse) =>
            _buildChannelsColumn(timeOfUse, context),
      ),

      // Status column
      BluNestTableColumn<TimeOfUse>(
        key: 'status',
        title: 'Status',
        sortable: true,
        flex: 1,
        builder: (timeOfUse) => _buildStatusColumn(timeOfUse, context),
      ),
      // Description column
      BluNestTableColumn<TimeOfUse>(
        key: 'description',
        title: 'Description',
        sortable: true,
        flex: 2,
        builder: (timeOfUse) => _buildDescriptionColumn(timeOfUse, context),
      ),

      // Actions column
      BluNestTableColumn<TimeOfUse>(
        key: 'actions',
        title: 'Actions',
        flex: 1,
        isActions: true,
        builder: (timeOfUse) =>
            _buildActionsColumn(timeOfUse, onEdit, onDelete, onView,context),
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
    int currentPage = 1,
    int itemsPerPage = 25,
    List<TimeOfUse>? data,
    required BuildContext context,
  }) {
    final allColumns = buildAllColumns(
      sortBy: sortBy,
      context: context,
      sortAscending: sortAscending,
      onEdit: onEdit,
      onDelete: onDelete,
      onView: onView,
      currentPage: currentPage,
      itemsPerPage: itemsPerPage,
      data: data,
    );

    return allColumns.where((col) => visibleColumns.contains(col.key)).toList();
  }

  // New method that returns all columns without filtering (for BluNestDataTable column visibility)
  static List<BluNestTableColumn<TimeOfUse>> buildAllBluNestColumns({
    String? sortBy,
    bool sortAscending = true,
    Function(TimeOfUse)? onEdit,
    Function(TimeOfUse)? onDelete,
    Function(TimeOfUse)? onView,
    int currentPage = 1,
    int itemsPerPage = 25,
    List<TimeOfUse>? data,
    required BuildContext context,
  }) {
    return buildAllColumns(
      context: context,
      sortBy: sortBy,
      sortAscending: sortAscending,
      onEdit: onEdit,
      onDelete: onDelete,
      onView: onView,
      currentPage: currentPage,
      itemsPerPage: itemsPerPage,
      data: data,
    );
  }

  static Widget _buildNameColumn(TimeOfUse timeOfUse, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            timeOfUse.name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: AppSizes.fontSizeSmall,
              color: context.textPrimaryColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // if (timeOfUse.id != null) ...[
          //   const SizedBox(height: 2),
          //   Text(
          //     'ID: ${timeOfUse.id}',
          //     style: TextStyle(
          //       fontSize: AppSizes.fontSizeSmall,
          //       color: AppColors.textSecondary,
          //     ),
          //   ),
          // ],
        ],
      ),
    );
  }

  static Widget _buildDescriptionColumn(TimeOfUse timeOfUse, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Text(
        timeOfUse.description.isNotEmpty
            ? timeOfUse.description
            : 'No description',
        style: TextStyle(
          fontSize: AppSizes.fontSizeSmall,
          color: timeOfUse.description.isNotEmpty
              ? context.textPrimaryColor
              : context.textSecondaryColor,
          fontStyle: timeOfUse.description.isNotEmpty
              ? FontStyle.normal
              : FontStyle.italic,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  static Widget _buildTimeBandsColumn(TimeOfUse timeOfUse, BuildContext context) {
    final uniqueTimeBands = timeOfUse.timeOfUseDetails
        .map((d) => d.timeBandId)
        .toSet()
        .length;

    return Container(
      padding: const EdgeInsets.all(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: context.infoColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          border: Border.all(color: context.infoColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.schedule,
              size: AppSizes.iconSmall,
              color: context.infoColor,
            ),
            const SizedBox(width: 4),
            Text(
              '$uniqueTimeBands',
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                fontWeight: FontWeight.w600,
                color: context.infoColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildChannelsColumn(TimeOfUse timeOfUse, BuildContext context) {
    final uniqueChannels = timeOfUse.timeOfUseDetails
        .map((d) => d.channelId)
        .toSet()
        .length;

    return Container(
      padding: const EdgeInsets.all(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: context.warningColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          border: Border.all(color: context.warningColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.settings_input_component,
              size: AppSizes.iconSmall,
              color: context.warningColor,
            ),
            const SizedBox(width: 4),
            Text(
              '$uniqueChannels',
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                fontWeight: FontWeight.w600,
                color: context.warningColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildStatusColumn(TimeOfUse timeOfUse, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: timeOfUse.active
              ? context.successColor.withOpacity(0.1)
              : context.errorColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          border: Border.all(
            color: timeOfUse.active
                ? context.successColor.withOpacity(0.3)
                : context.errorColor.withOpacity(0.3),
          ),
        ),
        child: Text(
          timeOfUse.active ? 'Active' : 'Inactive',
          style: TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            fontWeight: FontWeight.w600,
            color: timeOfUse.active ? context.successColor : context.errorColor,
          ),
        ),
      ),
    );
  }

  static Widget _buildActionsColumn(
    TimeOfUse timeOfUse,
    Function(TimeOfUse)? onEdit,
    Function(TimeOfUse)? onDelete,
    Function(TimeOfUse)? onView,
     BuildContext context,
  ) {
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
    'no',
    'name',
    'code',
    'description',
    'timeBands',
    'channels',
    'status',
    'actions',
  ];

  // Get display names for column visibility UI
  static List<String> getDisplayNames() => [
    'No.',
    'Name',
    'Code',
    'Description',
    'Time Bands',
    'Channels',
    'Status',
    'Actions',
  ];

  // Get column keys to display names mapping
  static Map<String, String> getColumnMapping() => {
    'no': 'No.',
    'name': 'Name',
    'code': 'Code',
    'description': 'Description',
    'timeBands': 'Time Bands',
    'channels': 'Channels',
    'status': 'Status',
    'actions': 'Actions',
  };

  // Convert display names back to keys
  static List<String> convertDisplayNamesToKeys(List<String> displayNames) {
    final mapping = getColumnMapping();
    final reverseMapping = {
      for (var entry in mapping.entries) entry.value: entry.key,
    };
    return displayNames.map((name) => reverseMapping[name] ?? name).toList();
  }

  // Convert keys to display names
  static List<String> convertKeysToDisplayNames(List<String> keys) {
    final mapping = getColumnMapping();
    return keys.map((key) => mapping[key] ?? key).toList();
  }

  // Get all column keys (alias for availableColumns)
  static List<String> getAllColumnKeys() => availableColumns;

  // Default visible columns
  static List<String> get defaultVisibleColumns => [
    'no',
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





