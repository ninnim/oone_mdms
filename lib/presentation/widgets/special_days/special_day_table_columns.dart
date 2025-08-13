import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/special_day.dart';
import '../common/status_chip.dart';
import '../common/blunest_data_table.dart';

class SpecialDayTableColumns {
  static List<String> get allColumns => [
    'no',
    'name',
    'description',
    'detailsCount',
    'status',
    'actions',
  ];

  static List<String> get availableColumns => [
    'No.',
    'Name',
    'Description',
    'Special Day Details',
    'Status',
    'Actions',
  ];

  static List<BluNestTableColumn<SpecialDay>> getBluNestColumns({
    Function(SpecialDay)? onView,
    Function(SpecialDay)? onEdit,
    Function(SpecialDay)? onDelete,
    int currentPage = 1,
    int itemsPerPage = 25,
    List<SpecialDay>? specialDays,
  }) {
    return [
      // No. (Row Number)
      BluNestTableColumn<SpecialDay>(
        key: 'no',
        title: 'No.',
        flex: 1,
        sortable: false,
        builder: (specialDay) {
          final index = specialDays?.indexOf(specialDay) ?? 0;
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

      // Name
      BluNestTableColumn<SpecialDay>(
        key: 'name',
        title: 'Name',
        flex: 3,
        sortable: true,
        builder: (specialDay) => Container(
          alignment: Alignment.centerLeft,
          child: Text(
            specialDay.name.isNotEmpty ? specialDay.name : 'N/A',
            style: const TextStyle(
              fontSize: AppSizes.fontSizeMedium,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),

      // Description
      BluNestTableColumn<SpecialDay>(
        key: 'description',
        title: 'Description',
        flex: 3,
        sortable: true,
        builder: (specialDay) => Container(
          alignment: Alignment.centerLeft,
          child: Text(
            specialDay.description.isNotEmpty ? specialDay.description : 'N/A',
            style: const TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),

      // Details Count
      BluNestTableColumn<SpecialDay>(
        key: 'detailsCount',
        title: 'Special Day Details',
        flex: 2,
        sortable: true,
        builder: (specialDay) => Container(
          alignment: Alignment.centerLeft,
          child: StatusChip(
            text: '${specialDay.detailsCount}',
            type: StatusChipType.info,
            compact: true,
          ),
        ),
      ),

      // Status
      BluNestTableColumn<SpecialDay>(
        key: 'status',
        title: 'Status',
        flex: 1,
        sortable: true,
        builder: (specialDay) => Container(
          alignment: Alignment.centerLeft,
          child: StatusChip(
            text: specialDay.active ? 'Active' : 'Inactive',
            type: specialDay.active
                ? StatusChipType.success
                : StatusChipType.secondary,
            compact: true,
          ),
        ),
      ),

      // Actions
      BluNestTableColumn<SpecialDay>(
        key: 'actions',
        title: 'Actions',
        flex: 1,
        sortable: false,
        isActions: true,
        builder: (specialDay) => Container(
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
                  if (onView != null) onView(specialDay);
                  break;
                case 'edit':
                  if (onEdit != null) onEdit(specialDay);
                  break;
                case 'delete':
                  if (onDelete != null) onDelete(specialDay);
                  break;
              }
            },
          ),
        ),
      ),
    ];
  }

  static List<BluNestTableColumn<SpecialDay>> buildBluNestColumns({
    required List<String> visibleColumns,
    required String? sortBy,
    required bool sortAscending,
    required Function(String, bool) onSort,
    Function(SpecialDay)? onView,
    Function(SpecialDay)? onEdit,
    Function(SpecialDay)? onDelete,
    int currentPage = 1,
    int itemsPerPage = 25,
    List<SpecialDay>? specialDays,
  }) {
    final allColumns = getBluNestColumns(
      onView: onView,
      onEdit: onEdit,
      onDelete: onDelete,
      currentPage: currentPage,
      itemsPerPage: itemsPerPage,
      specialDays: specialDays,
    );

    // Map friendly names to keys
    final columnKeyMap = {
      'Name': 'name',
      'Description': 'description',
      'Special Day Details': 'detailsCount',
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
