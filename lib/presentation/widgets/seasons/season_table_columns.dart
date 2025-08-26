import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/season.dart';
import '../common/blunest_data_table.dart';
import '../common/status_chip.dart';
import 'season_smart_month_chips.dart';

class SeasonTableColumns {
  static List<BluNestTableColumn<Season>> buildAllColumns({
    String? sortBy,
    bool sortAscending = true,
    Function(Season)? onEdit,
    Function(Season)? onDelete,
    Function(Season)? onView,
    int currentPage = 1,
    int itemsPerPage = 25,
    List<Season>? data,
    required BuildContext context,
  }) {
    return [
      // No. (Row Number)
      BluNestTableColumn<Season>(
        key: 'no',
        title: 'No.',
        flex: 1,
        sortable: false,
        builder: (season) {
          final index = data?.indexOf(season) ?? 0;
          final rowNumber = ((currentPage - 1) * itemsPerPage) + index + 1;
          return Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing8),
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

      // Name column
      BluNestTableColumn<Season>(
        key: 'name',
        title: 'Name',
        sortable: true,
        flex: 2,
        builder: (season) => _buildNameColumn(season, context),
      ),

      // Description column
      BluNestTableColumn<Season>(
        key: 'description',
        title: 'Description',
        sortable: true,
        flex: 3,
        builder: (season) => _buildDescriptionColumn(season, context),
      ),

      // Month Range column
      BluNestTableColumn<Season>(
        key: 'monthRange',
        title: 'Month Range',
        sortable: false,
        flex: 3,
        builder: (season) => _buildMonthRangeColumn(season, context),
      ),

      // Status column
      BluNestTableColumn<Season>(
        key: 'active',
        title: 'Status',
        sortable: true,
        flex: 1,
        builder: (season) => _buildStatusColumn(season, context),
      ),

      // Actions column
      BluNestTableColumn<Season>(
        key: 'actions',
        title: 'Actions',
        isActions: true,
        sortable: false,
        flex: 1,
        alignment: Alignment.centerRight,
        builder: (season) => _buildActionsColumn(
          context: context,
          season,
          onEdit: onEdit,
          onDelete: onDelete,
          onView: onView,
        ),
      ),
    ];
  }

  static Widget _buildNameColumn(Season season, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            season.name,
            style: TextStyle(
              fontSize: AppSizes.fontSizeMedium,
              fontWeight: FontWeight.w600,
              color: context.textPrimaryColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  static Widget _buildDescriptionColumn(Season season, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing8),
      child: Text(
        season.description,
        style: TextStyle(
          fontSize: AppSizes.fontSizeSmall,
          color: context.textSecondaryColor,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
    );
  }

  static Widget _buildMonthRangeColumn(Season season, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing8),
      child: SeasonSmartMonthChips.buildSmartMonthChips(
        season.monthRange,
        context,
      ),
    );
  }

  static Widget _buildStatusColumn(Season season, BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      child: StatusChip(
        text: season.active ? 'Active' : 'Inactive',
        compact: true,
        type: season.active ? StatusChipType.success : StatusChipType.secondary,
      ),
    );
  }

  static Widget _buildActionsColumn(
    Season season, {
    Function(Season)? onEdit,
    Function(Season)? onDelete,
    Function(Season)? onView,
    required BuildContext context,
  }) {
    return Container(
      alignment: Alignment.centerRight,
      height: AppSizes.spacing40,
      child: PopupMenuButton<String>(
        icon: Icon(
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
              onView?.call(season);
              break;
            case 'edit':
              onEdit?.call(season);
              break;
            case 'delete':
              onDelete?.call(season);
              break;
          }
        },
      ),
    );
  }

  // Helper methods for getting specific column configurations
  static List<BluNestTableColumn<Season>> getDefaultColumns({
    Function(Season)? onEdit,
    Function(Season)? onDelete,
    Function(Season)? onView,
    int currentPage = 1,
    int itemsPerPage = 25,
    List<Season>? data,
    required BuildContext context,
  }) {
    return buildAllColumns(
      context: context,
      onEdit: onEdit,
      onDelete: onDelete,
      onView: onView,
      currentPage: currentPage,
      itemsPerPage: itemsPerPage,
      data: data,
    );
  }

  static List<BluNestTableColumn<Season>> getCompactColumns({
    Function(Season)? onEdit,
    Function(Season)? onDelete,
    Function(Season)? onView,
    int currentPage = 1,
    int itemsPerPage = 25,
    List<Season>? data,
    required BuildContext context,
  }) {
    return [
      // No. (Row Number)
      BluNestTableColumn<Season>(
        key: 'no',
        title: 'No.',
        flex: 1,
        sortable: false,
        builder: (season) {
          final index = data?.indexOf(season) ?? 0;
          final rowNumber = ((currentPage - 1) * itemsPerPage) + index + 1;
          return Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing8),
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

      // Name column
      BluNestTableColumn<Season>(
        key: 'name',
        title: 'Name',
        sortable: true,
        flex: 2,
        builder: (season) => _buildNameColumn(season, context),
      ),

      // Month Range column
      BluNestTableColumn<Season>(
        key: 'monthRange',
        title: 'Month Range',
        sortable: false,
        flex: 3,
        builder: (season) => _buildMonthRangeColumn(season, context),
      ),

      // Status column
      BluNestTableColumn<Season>(
        key: 'active',
        title: 'Status',
        sortable: true,
        flex: 1,
        builder: (season) => _buildStatusColumn(season, context),
      ),

      // Actions column
      BluNestTableColumn<Season>(
        key: 'actions',
        title: 'Actions',
        isActions: true,
        sortable: false,
        flex: 1,
        alignment: Alignment.centerRight,
        builder: (season) => _buildActionsColumn(
          context: context,
          season,
          onEdit: onEdit,
          onDelete: onDelete,
          onView: onView,
        ),
      ),
    ];
  }
}
