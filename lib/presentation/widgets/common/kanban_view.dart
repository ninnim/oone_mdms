import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import 'results_pagination.dart';

/// A reusable Kanban board component with pagination support
class KanbanView<T extends Object> extends StatefulWidget {
  final List<KanbanColumn<T>> columns;
  final List<T> items;
  final Widget Function(T item) cardBuilder;
  final Function(T item, String fromColumn, String toColumn)? onItemMoved;
  final Function(T item)? onItemTapped;
  final bool enableDragDrop;
  final bool enablePagination;
  final int itemsPerPage;
  final bool isLoading;
  final Widget? emptyState;
  final String Function(T item) getItemColumn;

  const KanbanView({
    super.key,
    required this.columns,
    required this.items,
    required this.cardBuilder,
    required this.getItemColumn,
    this.onItemMoved,
    this.onItemTapped,
    this.enableDragDrop = true,
    this.enablePagination = false,
    this.itemsPerPage = 20,
    this.isLoading = false,
    this.emptyState,
  });

  @override
  State<KanbanView<T>> createState() => _KanbanViewState<T>();
}

class _KanbanViewState<T extends Object> extends State<KanbanView<T>> {
  int _currentPage = 1;
  final Map<String, ScrollController> _scrollControllers = {};

  @override
  void initState() {
    super.initState();
    for (final column in widget.columns) {
      _scrollControllers[column.id] = ScrollController();
    }
  }

  @override
  void dispose() {
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
        ),
      );
    }

    if (widget.items.isEmpty && widget.emptyState != null) {
      return widget.emptyState!;
    }

    // Get paginated items for global pagination
    final totalItems = widget.items.length;
    final totalPages = widget.enablePagination
        ? (totalItems / widget.itemsPerPage).ceil()
        : 1;
    final paginatedItems = widget.enablePagination
        ? _getGlobalPaginatedItems()
        : widget.items;

    return Column(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSizes.spacing16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.columns.map((column) {
                return Expanded(
                  child: _buildKanbanColumn(context, column, paginatedItems),
                );
              }).toList(),
            ),
          ),
        ),
        if (widget.enablePagination && totalPages > 1)
          Container(
            padding: const EdgeInsets.all(AppSizes.spacing16),
            child: ResultsPagination(
              currentPage: _currentPage,
              totalPages: totalPages,
              totalItems: totalItems,
              itemsPerPage: widget.itemsPerPage,
              startItem: ((_currentPage - 1) * widget.itemsPerPage) + 1,
              endItem: (_currentPage * widget.itemsPerPage) > totalItems
                  ? totalItems
                  : _currentPage * widget.itemsPerPage,
              onPageChanged: _onPageChanged,
              onItemsPerPageChanged: null, // Fixed items per page for Kanban
              showItemsPerPageSelector: false, // Don't show selector for Kanban
              itemLabel: 'devices',
            ),
          ),
      ],
    );
  }

  Widget _buildKanbanColumn(
    BuildContext context,
    KanbanColumn<T> column,
    List<T> paginatedItems,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final columnItems = _getColumnItems(column.id, paginatedItems);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.spacing8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildColumnHeader(context, column, columnItems.length),
          Expanded(
            child: DragTarget<T>(
              onWillAcceptWithDetails: (item) =>
                  widget.enableDragDrop && item != null,
              onAcceptWithDetails: (item) {
                if (widget.onItemMoved != null) {
                  final fromColumn = widget.getItemColumn(item as T);
                  if (fromColumn != column.id) {
                    widget.onItemMoved!(item as T, fromColumn, column.id);
                  }
                }
              },
              builder: (context, candidateData, rejectedData) {
                final isAcceptingDrag = candidateData.isNotEmpty;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isAcceptingDrag
                        ? column.color.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(AppSizes.radiusMedium),
                    ),
                  ),
                  child: _buildColumnContent(context, column, columnItems),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeader(
    BuildContext context,
    KanbanColumn<T> column,
    int itemCount,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: column.color.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusMedium),
        ),
        border: Border(
          bottom: BorderSide(color: column.color.withOpacity(0.3), width: 2),
        ),
      ),
      child: Row(
        children: [
          if (column.icon != null) ...[
            Icon(column.icon, color: column.color, size: AppSizes.iconMedium),
            const SizedBox(width: AppSizes.spacing8),
          ],
          Expanded(
            child: Text(
              column.title,
              style: TextStyle(
                fontSize: AppSizes.fontSizeMedium,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacing8,
              vertical: AppSizes.spacing4,
            ),
            decoration: BoxDecoration(
              color: column.color,
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
            child: Text(
              itemCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: AppSizes.fontSizeSmall,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnContent(
    BuildContext context,
    KanbanColumn<T> column,
    List<T> items,
  ) {
    if (items.isEmpty) {
      return _buildEmptyColumn(context, column);
    }

    return ListView.builder(
      controller: _scrollControllers[column.id],
      padding: const EdgeInsets.all(AppSizes.spacing12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        if (widget.enableDragDrop) {
          return Draggable<T>(
            data: item,
            feedback: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              child: SizedBox(width: 280, child: widget.cardBuilder(item)),
            ),
            childWhenDragging: Opacity(
              opacity: 0.5,
              child: _buildKanbanCard(context, item),
            ),
            child: _buildKanbanCard(context, item),
          );
        } else {
          return _buildKanbanCard(context, item);
        }
      },
    );
  }

  Widget _buildKanbanCard(BuildContext context, T item) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacing12),
      child: GestureDetector(
        onTap: () => widget.onItemTapped?.call(item),
        child: widget.cardBuilder(item),
      ),
    );
  }

  Widget _buildEmptyColumn(BuildContext context, KanbanColumn<T> column) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSizes.spacing12),
            Text(
              'No items in ${column.title}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: AppSizes.fontSizeMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<T> _getColumnItems(String columnId, List<T> allItems) {
    return allItems
        .where((item) => widget.getItemColumn(item) == columnId)
        .toList();
  }

  List<T> _getGlobalPaginatedItems() {
    final startIndex = (_currentPage - 1) * widget.itemsPerPage;
    final endIndex = startIndex + widget.itemsPerPage;

    return widget.items.sublist(
      startIndex,
      endIndex > widget.items.length ? widget.items.length : endIndex,
    );
  }

  void _onPageChanged(int newPage) {
    setState(() {
      _currentPage = newPage;
    });

    // Scroll all columns to top
    for (final controller in _scrollControllers.values) {
      controller.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}

/// Represents a column in the Kanban board
class KanbanColumn<T> {
  final String id;
  final String title;
  final Color color;
  final IconData? icon;
  final int? maxItems;

  const KanbanColumn({
    required this.id,
    required this.title,
    required this.color,
    this.icon,
    this.maxItems,
  });
}
