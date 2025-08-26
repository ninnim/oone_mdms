import 'package:flutter/material.dart';
import '../../../core/models/time_of_use.dart';
import '../common/kanban_view.dart';
import 'time_of_use_kanban_adapter.dart';

class TimeOfUseKanbanView extends StatelessWidget {
  final List<TimeOfUse> timeOfUseList;
  final Function(TimeOfUse)? onItemTap;
  final Function(TimeOfUse)? onItemEdit;
  final Function(TimeOfUse)? onItemDelete;
  final Function()? onRefresh;
  final bool isLoading;
  final String? emptyMessage;
  final String? searchQuery;

  const TimeOfUseKanbanView({
    super.key,
    required this.timeOfUseList,
    this.onItemTap,
    this.onItemEdit,
    this.onItemDelete,
    this.onRefresh,
    this.isLoading = false,
    this.emptyMessage,
    this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    // Convert time of use to kanban items
    List<KanbanItem> items = timeOfUseList
        .map((timeOfUse) => TimeOfUseKanbanItem(timeOfUse, context))
        .toList();

    // Apply search filter if provided
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      items = items.where((item) {
        final query = searchQuery!.toLowerCase();
        return item.title.toLowerCase().contains(query) ||
            (item.subtitle?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return KanbanView(
      items: items,
      columns: TimeOfUseKanbanConfig.columns,
      onItemTap: (item) {
        if (onItemTap != null) {
          onItemTap!((item as TimeOfUseKanbanItem).timeOfUse);
        }
      },
      actions: TimeOfUseKanbanConfig.getActions(
        context: context,
        onView: onItemTap,
        onEdit: onItemEdit,
        onDelete: onItemDelete,
      ),
      isLoading: isLoading,
    );
  }
}
