import '../../../core/models/schedule.dart';
// import '../../../core/constants/app_colors.dart';
import '../../themes/app_theme.dart';
import '../common/kanban_view.dart';
import 'package:flutter/material.dart';

/// Adapter class to make Schedule compatible with KanbanItem
class ScheduleKanbanItem extends KanbanItem {
  final Schedule schedule;

  ScheduleKanbanItem(this.schedule);

  @override
  String get id => schedule.id?.toString() ?? '';

  @override
  String get title => schedule.displayName;

  @override
  String get status => schedule.displayStatus;

  @override
  String? get subtitle => schedule.displayCode;

  @override
  String? get badge =>
      schedule.retryCount > 0 ? 'Retries: ${schedule.retryCount}' : null;

  @override
  IconData? get icon => null; // Will be handled by status

  @override
  Color? get itemColor => null;

  @override
  List<KanbanDetail> get details => [
    KanbanDetail(icon: Icons.code, label: 'Code', value: schedule.displayCode),
    KanbanDetail(
      icon: Icons.device_hub,
      label: 'Target',
      value: schedule.displayTargetType,
    ),
    KanbanDetail(
      icon: Icons.schedule,
      label: 'Interval',
      value: schedule.displayInterval,
    ),
    if (schedule.nextBillingDate != null)
      KanbanDetail(
        icon: Icons.event,
        label: 'Next Run',
        value: _formatDate(schedule.nextBillingDate!),
      ),
  ];

  @override
  bool get isActive => schedule.isActive;

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

/// Kanban configuration for schedules
class ScheduleKanbanConfig {
  static List<KanbanColumn> get columns => [
    const KanbanColumn(
      key: 'enabled',
      title: 'Enabled',
      icon: Icons.play_circle_outline,
      color: Color(0xFF059669), // Green
      emptyMessage: 'No enabled schedules',
    ),
    const KanbanColumn(
      key: 'disabled',
      title: 'Disabled',
      icon: Icons.pause_circle_outline,
      color: Color(0xFFDC2626), // Red
      emptyMessage: 'No disabled schedules',
    ),
  ];

  static List<KanbanAction> getActions({
    Function(Schedule)? onView,
    Function(Schedule)? onEdit,
    Function(Schedule)? onDelete,
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
          onTap: (item) => onView((item as ScheduleKanbanItem).schedule),
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
          onTap: (item) => onEdit((item as ScheduleKanbanItem).schedule),
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
          onTap: (item) => onDelete((item as ScheduleKanbanItem).schedule),
        ),
      );
    }

    return actions;
  }
}



