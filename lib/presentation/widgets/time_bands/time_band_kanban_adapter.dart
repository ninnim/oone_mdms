import '../../../core/models/time_band.dart';
import '../../themes/app_theme.dart';
import '../common/kanban_view.dart';
import 'time_band_smart_chips.dart';
import 'package:flutter/material.dart';

/// Adapter class to make TimeBand compatible with KanbanItem
class TimeBandKanbanItem extends KanbanItem {
  final TimeBand timeBand;
  final BuildContext context;

  TimeBandKanbanItem(this.timeBand, this.context);

  @override
  String get id => timeBand.id.toString();

  @override
  String get title => timeBand.name;

  @override
  String get status => timeBand.active ? 'active' : 'inactive';

  @override
  String? get subtitle => timeBand.timeRangeDisplay;

  @override
  String? get badge => timeBand.timeBandAttributes.isNotEmpty
      ? '${timeBand.timeBandAttributes.length} attributes'
      : null;

  @override
  IconData? get icon => Icons.schedule;

  @override
  Color? get itemColor => timeBand.active
      ? const Color(0xFF059669) // Green for active
      : const Color(0xFFDC2626); // Red for inactive

  @override
  List<Widget> get smartChips {
    final chips = <Widget>[];

    // Add Days of Week chips
    if (timeBand.daysOfWeek.isNotEmpty) {
      chips.add(TimeBandSmartChips.buildDayOfWeekChips(timeBand.daysOfWeek, context));
    }

    // Add Months of Year chips
    if (timeBand.monthsOfYear.isNotEmpty) {
      chips.add(
        TimeBandSmartChips.buildMonthOfYearChips(timeBand.monthsOfYear, context),
      );
    }

    return chips;
  }

  @override
  List<KanbanDetail> get details {
    final details = <KanbanDetail>[
      KanbanDetail(
        icon: Icons.access_time,
        label: 'Time Range',
        value: timeBand.timeRangeDisplay,
      ),
    ];

    if (timeBand.description.isNotEmpty) {
      details.add(
        KanbanDetail(
          icon: Icons.description,
          label: 'Description',
          value: timeBand.description,
        ),
      );
    }


    if (timeBand.monthsOfYear.isNotEmpty) {
      details.add(
        KanbanDetail(
          icon: Icons.date_range,
          label: 'Months',
          value: '${timeBand.monthsOfYear.length} months',
          valueColor: context.primaryColor,
        ),
      );
    }

    if (timeBand.seasonIds.isNotEmpty) {
      details.add(
        KanbanDetail(
          icon: Icons.eco,
          label: 'Seasons',
          value: '${timeBand.seasonIds.length} seasons',
          valueColor: context.secondaryColor,
        ),
      );
    }

    if (timeBand.specialDayIds.isNotEmpty) {
      details.add(
        KanbanDetail(
          icon: Icons.star,
          label: 'Special Days',
          value: '${timeBand.specialDayIds.length} days',
          valueColor: context.warningColor,
        ),
      );
    }

    return details;
  }

  @override
  bool get isActive => timeBand.active;
}

/// Kanban configuration for time bands
class TimeBandKanbanConfig {
  static List<KanbanColumn> get columns => [
    const KanbanColumn(
      key: 'active',
      title: 'Active',
      icon: Icons.check_circle,
      color: Color(0xFF059669), // Green
      emptyMessage: 'No active time bands',
    ),
    const KanbanColumn(
      key: 'inactive',
      title: 'Inactive',
      icon: Icons.cancel,
      color: Color(0xFFDC2626), // Red
      emptyMessage: 'No inactive time bands',
    ),
  ];

  static List<KanbanAction> getActions({
    Function(TimeBand)? onView,
    Function(TimeBand)? onEdit,
    Function(TimeBand)? onDelete,
    Function(TimeBand)? onDuplicate,
    required BuildContext context,
  }) {
    final actions = <KanbanAction>[];

    if (onView != null) {
      actions.add(
        KanbanAction(
          key: 'view',
          label: 'View Details',
          icon: Icons.visibility,
          color: context.primaryColor,
          onTap: (item) => onView((item as TimeBandKanbanItem).timeBand),
        ),
      );
    }

    if (onEdit != null) {
      actions.add(
        KanbanAction(
          key: 'edit',
          label: 'Edit',
          icon: Icons.edit,
          color: context.warningColor,
          onTap: (item) => onEdit((item as TimeBandKanbanItem).timeBand),
        ),
      );
    }

    if (onDuplicate != null) {
      actions.add(
        KanbanAction(
          key: 'duplicate',
          label: 'Duplicate',
          icon: Icons.copy,
          color: context.infoColor,
          onTap: (item) => onDuplicate((item as TimeBandKanbanItem).timeBand),
        ),
      );
    }

    if (onDelete != null) {
      actions.add(
        KanbanAction(
          key: 'delete',
          label: 'Delete',
          icon: Icons.delete,
          color: context.errorColor,
          onTap: (item) => onDelete((item as TimeBandKanbanItem).timeBand),
        ),
      );
    }

    return actions;
  }
}



