import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/site.dart';
import '../common/status_chip.dart';
import '../common/blunest_data_table.dart';

class SiteTableColumns {
  static List<String> get availableColumns => [
    'No.',
    'Site Name',
    'Description',
    'Sub Sites',
    'Status',
    'Actions',
  ];

  static List<BluNestTableColumn<Site>> getBluNestColumns({
    Function(Site)? onView,
    Function(Site)? onEdit,
    Function(Site)? onDelete,
    int currentPage = 1,
    int itemsPerPage = 25,
    List<Site>? sites,
  }) {
    return [
      // No. (Row Number)
      BluNestTableColumn<Site>(
        key: 'no',
        title: 'No.',
        flex: 1,
        sortable: false,
        builder: (site) {
          final index = sites?.indexOf(site) ?? 0;
          final rowNumber = ((currentPage - 1) * itemsPerPage) + index + 1;
          return Container(
            alignment: Alignment.centerLeft,
            child: Text(
              '$rowNumber',
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          );
        },
      ),

      // Site Name
      BluNestTableColumn<Site>(
        key: 'name',
        title: 'Site Name',
        flex: 3,
        sortable: true,
        builder: (site) => Container(
          alignment: Alignment.centerLeft,
          child: Text(
            site.name.isNotEmpty ? site.name : 'N/A',
            style: const TextStyle(
              fontSize: AppSizes.fontSizeMedium,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),

      // Description
      BluNestTableColumn<Site>(
        key: 'description',
        title: 'Description',
        flex: 3,
        sortable: true,
        builder: (site) => Container(
          alignment: Alignment.centerLeft,
          child: Text(
            site.description.isNotEmpty ? site.description : 'N/A',
            style: const TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),

      // Sub Sites Count
      BluNestTableColumn<Site>(
        key: 'subSites',
        title: 'Sub Sites',
        flex: 2,
        sortable: true,
        builder: (site) => Container(
          alignment: Alignment.centerLeft,
          child: StatusChip(
            text: '${site.subSites?.length ?? 0}',
            type: StatusChipType.info,
            compact: true,
          ),
        ),
      ),

      // Status
      BluNestTableColumn<Site>(
        key: 'status',
        title: 'Status',
        flex: 2,
        sortable: true,
        builder: (site) => Container(
          alignment: Alignment.centerLeft,
          child: StatusChip(
            text: site.active ? 'Active' : 'Inactive',
            type: site.active ? StatusChipType.success : StatusChipType.error,
            compact: true,
          ),
        ),
      ),

      // Actions
      BluNestTableColumn<Site>(
        key: 'actions',
        title: 'Actions',
        flex: 1,
        sortable: false,
        isActions: true,
        builder: (site) => Container(
          alignment: Alignment.centerRight,
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
                  if (onView != null) onView(site);
                  break;
                case 'edit':
                  if (onEdit != null) onEdit(site);
                  break;
                case 'delete':
                  if (onDelete != null) onDelete(site);
                  break;
              }
            },
          ),
        ),
      ),
    ];
  }

  static List<BluNestTableColumn<Site>> buildBluNestColumns({
    required List<String> visibleColumns,
    required String? sortBy,
    required bool sortAscending,
    required Function(String, bool) onSort,
    Function(Site)? onView,
    Function(Site)? onEdit,
    Function(Site)? onDelete,
    int currentPage = 1,
    int itemsPerPage = 25,
    List<Site>? sites,
  }) {
    final allColumns = getBluNestColumns(
      onView: onView,
      onEdit: onEdit,
      onDelete: onDelete,
      currentPage: currentPage,
      itemsPerPage: itemsPerPage,
      sites: sites,
    );

    // Map friendly names to keys
    final columnKeyMap = {
      'Site Name': 'name',
      'Description': 'description',
      'Sub Sites': 'subSites',
      'Status': 'status',
      'Actions': 'actions',
    };

    return allColumns.where((column) {
      return visibleColumns.any(
        (visibleColumn) =>
            columnKeyMap[visibleColumn] == column.key || column.key == 'no',
      );
    }).toList();
  }
}
