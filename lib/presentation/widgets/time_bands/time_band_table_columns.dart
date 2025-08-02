import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/time_band.dart';
import '../../../core/models/season.dart';
import '../../../core/models/special_day.dart';
import '../../widgets/common/blunest_data_table.dart';
import '../../widgets/common/status_chip.dart';
import 'time_band_smart_chips.dart';

class TimeBandTableColumns {
  static List<BluNestTableColumn<TimeBand>> buildBluNestColumns({
    required List<String> visibleColumns,
    String? sortBy,
    bool sortAscending = true,
    Function(TimeBand)? onEdit,
    Function(TimeBand)? onDelete,
    Function(TimeBand)? onView,
    List<Season> availableSeasons = const [],
    List<SpecialDay> availableSpecialDays = const [],
  }) {
    final allColumns = _buildAllColumnDefinitions(
      sortBy: sortBy,
      sortAscending: sortAscending,
      onEdit: onEdit,
      onDelete: onDelete,
      onView: onView,
      availableSeasons: availableSeasons,
      availableSpecialDays: availableSpecialDays,
    );

    return allColumns.where((col) => visibleColumns.contains(col.key)).toList();
  }

  static List<BluNestTableColumn<TimeBand>> buildAllColumns({
    String? sortBy,
    bool sortAscending = true,
    Function(TimeBand)? onEdit,
    Function(TimeBand)? onDelete,
    Function(TimeBand)? onView,
    List<Season> availableSeasons = const [],
    List<SpecialDay> availableSpecialDays = const [],
  }) {
    return _buildAllColumnDefinitions(
      sortBy: sortBy,
      sortAscending: sortAscending,
      onEdit: onEdit,
      onDelete: onDelete,
      onView: onView,
      availableSeasons: availableSeasons,
      availableSpecialDays: availableSpecialDays,
    );
  }

  static List<BluNestTableColumn<TimeBand>> _buildAllColumnDefinitions({
    String? sortBy,
    bool sortAscending = true,
    Function(TimeBand)? onEdit,
    Function(TimeBand)? onDelete,
    Function(TimeBand)? onView,
    List<Season> availableSeasons = const [],
    List<SpecialDay> availableSpecialDays = const [],
  }) {
    return [
      // Name column
      BluNestTableColumn<TimeBand>(
        key: 'name',
        title: 'Name',
        sortable: true,
        flex: 2,
        builder: (timeBand) => _buildNameColumn(timeBand),
      ),

      // Time Range column
      BluNestTableColumn<TimeBand>(
        key: 'timeRange',
        title: 'Time Range',
        sortable: true,
        flex: 2,
        builder: (timeBand) => _buildTimeRangeColumn(timeBand),
      ),

      // Days of Week column
      BluNestTableColumn<TimeBand>(
        key: 'daysOfWeek',
        title: 'Days of Week',
        sortable: false,
        flex: 2,
        builder: (timeBand) => _buildDaysOfWeekColumn(timeBand),
      ),

      // Months column
      BluNestTableColumn<TimeBand>(
        key: 'months',
        title: 'Months',
        sortable: false,
        flex: 2,
        builder: (timeBand) => _buildMonthsColumn(timeBand),
      ),

      // Seasons column
      BluNestTableColumn<TimeBand>(
        key: 'seasons',
        title: 'Seasons',
        sortable: false,
        flex: 2,
        builder: (timeBand) => _buildSeasonsColumn(timeBand, availableSeasons),
      ),

      // Special Days column
      BluNestTableColumn<TimeBand>(
        key: 'specialDays',
        title: 'Special Days',
        sortable: false,
        flex: 2,
        builder: (timeBand) =>
            _buildSpecialDaysColumn(timeBand, availableSpecialDays),
      ),

      // Status column
      BluNestTableColumn<TimeBand>(
        key: 'status',
        title: 'Status',
        sortable: true,
        flex: 1,
        builder: (timeBand) => _buildStatusColumn(timeBand),
      ),

      // Attributes count column
      BluNestTableColumn<TimeBand>(
        key: 'attributes',
        title: 'Attributes',
        sortable: false,
        flex: 1,
        builder: (timeBand) => _buildAttributesColumn(timeBand),
      ),

      // Description column (moved near actions)
      BluNestTableColumn<TimeBand>(
        key: 'description',
        title: 'Description',
        sortable: true,
        flex: 3,
        builder: (timeBand) => _buildDescriptionColumn(timeBand),
      ),

      // Actions column (always last)
      BluNestTableColumn<TimeBand>(
        key: 'actions',
        title: 'Actions',
        flex: 1,
        builder: (timeBand) =>
            _buildActionsColumn(timeBand, onEdit, onDelete, onView),
      ),
    ];
  }

  static Widget _buildNameColumn(TimeBand timeBand) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          timeBand.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          'ID: ${timeBand.id}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  static Widget _buildTimeRangeColumn(TimeBand timeBand) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing8,
        vertical: AppSizes.spacing4,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Text(
        timeBand.timeRangeDisplay,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
      ),
    );
  }

  static Widget _buildDescriptionColumn(TimeBand timeBand) {
    return Text(
      timeBand.description.isNotEmpty ? timeBand.description : 'No description',
      style: TextStyle(
        fontSize: 13,
        color: timeBand.description.isNotEmpty ? null : Colors.grey[500],
        fontStyle: timeBand.description.isNotEmpty
            ? FontStyle.normal
            : FontStyle.italic,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  static Widget _buildDaysOfWeekColumn(TimeBand timeBand) {
    final daysOfWeek = timeBand.daysOfWeek;
    if (daysOfWeek.isEmpty) {
      return Text(
        'All days',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[500],
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return TimeBandSmartChips.buildDayOfWeekChips(daysOfWeek);
  }

  static Widget _buildMonthsColumn(TimeBand timeBand) {
    final monthsOfYear = timeBand.monthsOfYear;
    if (monthsOfYear.isEmpty) {
      return Text(
        'All months',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[500],
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return TimeBandSmartChips.buildMonthOfYearChips(monthsOfYear);
  }

  static Widget _buildSeasonsColumn(
    TimeBand timeBand,
    List<Season> availableSeasons,
  ) {
    return TimeBandSmartChips.buildSeasonChips(
      timeBand.seasonIds,
      availableSeasons,
    );
  }

  static Widget _buildSpecialDaysColumn(
    TimeBand timeBand,
    List<SpecialDay> availableSpecialDays,
  ) {
    return TimeBandSmartChips.buildSpecialDayChips(
      timeBand.specialDayIds,
      availableSpecialDays,
    );
  }

  static Widget _buildStatusColumn(TimeBand timeBand) {
    return StatusChip(
      text: timeBand.active ? 'Active' : 'Inactive',
      type: timeBand.active ? StatusChipType.success : StatusChipType.error,
    );
  }

  static Widget _buildAttributesColumn(TimeBand timeBand) {
    final attributeCount = timeBand.timeBandAttributes.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: attributeCount > 0
            ? AppColors.warning.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Text(
        attributeCount.toString(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: attributeCount > 0 ? AppColors.warning : Colors.grey[600],
        ),
      ),
    );
  }

  static Widget _buildActionsColumn(
    TimeBand timeBand,
    Function(TimeBand)? onEdit,
    Function(TimeBand)? onDelete,
    Function(TimeBand)? onView,
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
              onView?.call(timeBand);
              break;
            case 'edit':
              onEdit?.call(timeBand);
              break;
            case 'delete':
              onDelete?.call(timeBand);
              break;
          }
        },
      ),
    );
  }

  // Get all available column keys
  static List<String> get allColumnKeys => [
    'name',
    'timeRange',
    'daysOfWeek',
    'months',
    'seasons',
    'specialDays',
    'status',
    'attributes',
    'description',
    'actions',
  ];

  // Get default visible columns
  static List<String> get defaultVisibleColumns => [
    'name',
    'timeRange',
    'daysOfWeek',
    'months',
    'seasons',
    'specialDays',
    'status',
    'description',
    'actions',
  ];

  // Get column display names
  static Map<String, String> get columnDisplayNames => {
    'name': 'Name',
    'timeRange': 'Time Range',
    'description': 'Description',
    'daysOfWeek': 'Days of Week',
    'months': 'Months',
    'seasons': 'Seasons',
    'specialDays': 'Special Days',
    'status': 'Status',
    'attributes': 'Attributes',
    'actions': 'Actions',
  };
}
