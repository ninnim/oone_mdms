import 'package:flutter/material.dart';
import '../../../core/models/season.dart';
import '../common/kanban_view.dart';
import 'season_kanban_adapter.dart';

class SeasonsKanbanView extends StatelessWidget {
  final List<Season> seasons;
  final Function(Season)? onItemTap;
  final Function(Season)? onItemEdit;
  final Function(Season)? onItemDelete;
  final Function()? onRefresh;
  final bool isLoading;
  final String? emptyMessage;
  final String? searchQuery;

  const SeasonsKanbanView({
    super.key,
    required this.seasons,
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
    // Convert seasons to kanban items
    List<KanbanItem> items = seasons
        .map((season) => SeasonKanbanItem(season))
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
      columns: SeasonKanbanConfig.columns,
      onItemTap: (item) {
        if (onItemTap != null) {
          onItemTap!((item as SeasonKanbanItem).season);
        }
      },
      actions: SeasonKanbanConfig.getActions(
        onView: onItemTap,
        onEdit: onItemEdit,
        onDelete: onItemDelete,
      ),
      isLoading: isLoading,
    );
  }
}
