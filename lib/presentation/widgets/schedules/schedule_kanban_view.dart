import 'package:flutter/material.dart';
import '../../../core/models/schedule.dart';
import '../common/kanban_view.dart';
import 'schedule_kanban_adapter.dart';

class ScheduleKanbanView extends StatelessWidget {
  final List<Schedule> schedules;
  final Function(Schedule) onScheduleSelected;
  final Function(Schedule)? onScheduleEdit;
  final Function(Schedule)? onScheduleDelete;
  final Function(Schedule)? onScheduleView;
  final bool isLoading;
  final bool enablePagination;
  final int itemsPerPage;

  const ScheduleKanbanView({
    super.key,
    required this.schedules,
    required this.onScheduleSelected,
    this.onScheduleEdit,
    this.onScheduleDelete,
    this.onScheduleView,
    this.isLoading = false,
    this.enablePagination = true,
    this.itemsPerPage = 25,
  });

  @override
  Widget build(BuildContext context) {
    // Convert schedules to KanbanItems
    final kanbanItems = schedules
        .map((schedule) => ScheduleKanbanItem(schedule))
        .toList();

    // Configure actions
    final actions = ScheduleKanbanConfig.getActions(
      context: context, 
      onView: onScheduleView,
      onEdit: onScheduleEdit,
      onDelete: onScheduleDelete,
    );

    return KanbanView<ScheduleKanbanItem>(
      items: kanbanItems,
      columns: ScheduleKanbanConfig.columns,
      actions: actions,
      onItemTap: (item) => onScheduleSelected(item.schedule),
      isLoading: isLoading,
      enablePagination: enablePagination,
      itemsPerPage: itemsPerPage,
    );
  }
}
