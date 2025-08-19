import '../../../core/models/season.dart';
import '../../../core/constants/app_colors.dart';
import '../common/kanban_view.dart';
import 'season_smart_month_chips.dart';
import 'package:flutter/material.dart';

/// Adapter class to make Season compatible with KanbanItem
class SeasonKanbanItem extends KanbanItem {
  final Season season;

  SeasonKanbanItem(this.season);

  @override
  String get id => season.id.toString();

  @override
  String get title => season.name;

  @override
  String get status => season.active ? 'active' : 'inactive';

  @override
  String? get subtitle =>
      season.description.isNotEmpty ? season.description : null;

  @override
  String? get badge => season.monthRange.isNotEmpty
      ? '${season.monthRange.length} months'
      : null;

  @override
  IconData? get icon => Icons.calendar_month;

  @override
  Color? get itemColor => season.active
      ? const Color(0xFF059669) // Green for active
      : const Color(0xFFDC2626); // Red for inactive

  @override
  List<Widget> get smartChips => [
    if (season.monthRange.isNotEmpty)
      SeasonSmartMonthChips.buildSmartMonthChips(season.monthRange),
  ];

  @override
  List<KanbanDetail> get details => [
    if (season.description.isNotEmpty)
      KanbanDetail(
        icon: Icons.description,
        label: 'Description',
        value: season.description,
      ),
    // KanbanDetail(
    //   icon: Icons.calendar_month,
    //   label: 'Months',
    //   value: '${season.monthRange.length}',
    //   valueColor: AppColors.info,
    // ),
    // if (season.monthRange.isNotEmpty)
    //   KanbanDetail(
    //     icon: Icons.date_range,
    //     label: 'Range',
    //     value: season.monthRangeDisplay,
    //     valueColor: AppColors.primary,
    //   ),
  ];

  @override
  bool get isActive => season.active;
}

/// Kanban configuration for seasons
class SeasonKanbanConfig {
  static List<KanbanColumn> get columns => [
    const KanbanColumn(
      key: 'active',
      title: 'Active',
      icon: Icons.check_circle,
      color: Color(0xFF059669), // Green
      emptyMessage: 'No active seasons',
    ),
    const KanbanColumn(
      key: 'inactive',
      title: 'Inactive',
      icon: Icons.cancel,
      color: Color(0xFFDC2626), // Red
      emptyMessage: 'No inactive seasons',
    ),
  ];

  static List<KanbanAction> getActions({
    Function(Season)? onView,
    Function(Season)? onEdit,
    Function(Season)? onDelete,
  }) {
    final actions = <KanbanAction>[];

    if (onView != null) {
      actions.add(
        KanbanAction(
          key: 'view',
          label: 'View Details',
          icon: Icons.visibility,
          color: AppColors.primary,
          onTap: (item) => onView((item as SeasonKanbanItem).season),
        ),
      );
    }

    if (onEdit != null) {
      actions.add(
        KanbanAction(
          key: 'edit',
          label: 'Edit',
          icon: Icons.edit,
          color: AppColors.warning,
          onTap: (item) => onEdit((item as SeasonKanbanItem).season),
        ),
      );
    }

    if (onDelete != null) {
      actions.add(
        KanbanAction(
          key: 'delete',
          label: 'Delete',
          icon: Icons.delete,
          color: AppColors.error,
          onTap: (item) => onDelete((item as SeasonKanbanItem).season),
        ),
      );
    }

    return actions;
  }
}
