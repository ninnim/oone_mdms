import 'package:flutter/material.dart';
import '../../../core/models/time_band.dart';
import '../common/kanban_view.dart';
import 'time_band_kanban_adapter.dart';

class TimeBandKanbanView extends StatelessWidget {
  final List<TimeBand> timeBands;
  final Function(TimeBand)? onItemTap;
  final Function(TimeBand)? onItemEdit;
  final Function(TimeBand)? onItemDelete;
  final Function()? onRefresh;
  final bool isLoading;
  final String? emptyMessage;
  final String? searchQuery;

  const TimeBandKanbanView({
    super.key,
    required this.timeBands,
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
    // Convert time bands to kanban items
    List<KanbanItem> items = timeBands
        .map((timeBand) => TimeBandKanbanItem(timeBand, context))
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
      columns: TimeBandKanbanConfig.columns,
      onItemTap: (item) {
        if (onItemTap != null) {
          onItemTap!((item as TimeBandKanbanItem).timeBand);
        }
      },
      actions: TimeBandKanbanConfig.getActions(
        context: context,
        onView: onItemTap,
        onEdit: onItemEdit,
        onDelete: onItemDelete,
      ),
      isLoading: isLoading,
    );
  }
}
