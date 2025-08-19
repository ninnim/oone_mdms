import '../../../core/models/time_of_use.dart';
import '../../../core/constants/app_colors.dart';
import '../common/kanban_view.dart';
import 'package:flutter/material.dart';

/// Adapter class to make TimeOfUse compatible with KanbanItem
class TimeOfUseKanbanItem extends KanbanItem {
  final TimeOfUse timeOfUse;

  TimeOfUseKanbanItem(this.timeOfUse);

  @override
  String get id => timeOfUse.id?.toString() ?? '';

  @override
  String get title => timeOfUse.name;

  @override
  String get status => timeOfUse.active ? 'active' : 'inactive';

  @override
  String? get subtitle => timeOfUse.code;

  @override
  String? get badge => timeOfUse.timeOfUseDetails.isNotEmpty
      ? '${timeOfUse.timeOfUseDetails.length} details'
      : null;

  @override
  IconData? get icon => Icons.access_time;

  @override
  Color? get itemColor => timeOfUse.active
      ? const Color(0xFF059669) // Green for active
      : const Color(0xFFDC2626); // Red for inactive

  @override
  List<KanbanDetail> get details => [
    KanbanDetail(icon: Icons.code, label: 'Code', value: timeOfUse.code),
    if (timeOfUse.description.isNotEmpty)
      KanbanDetail(
        icon: Icons.description,
        label: 'Description',
        value: timeOfUse.description,
      ),
    KanbanDetail(
      icon: Icons.list,
      label: 'Details',
      value: '${timeOfUse.timeOfUseDetails.length}',
      valueColor: AppColors.info,
    ),
    KanbanDetail(
      icon: Icons.schedule,
      label: 'Time Bands',
      value: '${timeOfUse.totalTimeBands}',
      valueColor: AppColors.primary,
    ),
    KanbanDetail(
      icon: Icons.stream,
      label: 'Channels',
      value: '${timeOfUse.totalChannels}',
      valueColor: AppColors.secondary,
    ),
  ];

  @override
  bool get isActive => timeOfUse.active;
}

/// Kanban configuration for time of use
class TimeOfUseKanbanConfig {
  static List<KanbanColumn> get columns => [
    const KanbanColumn(
      key: 'active',
      title: 'Active',
      icon: Icons.check_circle,
      color: Color(0xFF059669), // Green
      emptyMessage: 'No active time of use configurations',
    ),
    const KanbanColumn(
      key: 'inactive',
      title: 'Inactive',
      icon: Icons.cancel,
      color: Color(0xFFDC2626), // Red
      emptyMessage: 'No inactive time of use configurations',
    ),
  ];

  static List<KanbanAction> getActions({
    Function(TimeOfUse)? onView,
    Function(TimeOfUse)? onEdit,
    Function(TimeOfUse)? onDelete,
    Function(TimeOfUse)? onValidate,
  }) {
    final actions = <KanbanAction>[];

    if (onView != null) {
      actions.add(
        KanbanAction(
          key: 'view',
          label: 'View Details',
          icon: Icons.visibility,
          color: AppColors.primary,
          onTap: (item) => onView((item as TimeOfUseKanbanItem).timeOfUse),
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
          onTap: (item) => onEdit((item as TimeOfUseKanbanItem).timeOfUse),
        ),
      );
    }

    if (onValidate != null) {
      actions.add(
        KanbanAction(
          key: 'validate',
          label: 'Validate',
          icon: Icons.verified,
          color: AppColors.info,
          onTap: (item) => onValidate((item as TimeOfUseKanbanItem).timeOfUse),
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
          onTap: (item) => onDelete((item as TimeOfUseKanbanItem).timeOfUse),
        ),
      );
    }

    return actions;
  }
}
