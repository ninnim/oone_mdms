import 'package:flutter/material.dart';

class BluNestDataTable<T> extends StatefulWidget {
  final List<BluNestTableColumn<T>> columns;
  final List<T> data;
  final Function(T)? onRowTap;
  final Function(T)? onEdit;
  final Function(T)? onDelete;
  final Function(T)? onView;
  final Widget? emptyState;
  final bool isLoading;
  final String? sortBy;
  final bool sortAscending;
  final Function(String, bool)? onSort;
  final bool enableMultiSelect;
  final Set<T> selectedItems;
  final Function(Set<T>)? onSelectionChanged;
  final List<String> hiddenColumns;
  final Function(List<String>)? onColumnVisibilityChanged;

  const BluNestDataTable({
    super.key,
    required this.columns,
    required this.data,
    this.onRowTap,
    this.onEdit,
    this.onDelete,
    this.onView,
    this.emptyState,
    this.isLoading = false,
    this.sortBy,
    this.sortAscending = true,
    this.onSort,
    this.enableMultiSelect = false,
    this.selectedItems = const {},
    this.onSelectionChanged,
    this.hiddenColumns = const [],
    this.onColumnVisibilityChanged,
  });

  @override
  State<BluNestDataTable<T>> createState() => _BluNestDataTableState<T>();
}

class _BluNestDataTableState<T> extends State<BluNestDataTable<T>> {
  List<BluNestTableColumn<T>> get visibleColumns {
    return widget.columns
        .where((col) => !widget.hiddenColumns.contains(col.key))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingState();
    }

    if (widget.data.isEmpty) {
      return widget.emptyState ?? _buildEmptyState();
    }

    return Column(
      children: [
        if (widget.onColumnVisibilityChanged != null ||
            widget.enableMultiSelect)
          _buildTableControls(),
        Expanded(child: _buildTable()),
      ],
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FA),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: Color(0xFFE1E5E9), width: 1),
              ),
            ),
            child: Row(
              children: [
                if (widget.enableMultiSelect)
                  Container(
                    width: 40,
                    alignment: Alignment.centerLeft,
                    child: Transform.scale(
                      scale: 0.9,
                      child: Checkbox(
                        value:
                            widget.selectedItems.length == widget.data.length &&
                            widget.data.isNotEmpty,
                        onChanged: (value) {
                          if (value == true) {
                            widget.onSelectionChanged?.call(
                              widget.data.toSet(),
                            );
                          } else {
                            widget.onSelectionChanged?.call({});
                          }
                        },
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        activeColor: const Color(0xFF2563EB),
                        checkColor: Colors.white,
                        side: const BorderSide(
                          color: Color(0xFFD1D5DB),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ...visibleColumns.asMap().entries.map((entry) {
                  final column = entry.value;
                  return Expanded(
                    flex: column.flex ?? 1,
                    child: InkWell(
                      onTap: column.sortable
                          ? () {
                              final ascending = widget.sortBy == column.key
                                  ? !widget.sortAscending
                                  : true;
                              widget.onSort?.call(column.key, ascending);
                            }
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              column.title,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF374151),
                                letterSpacing: 0.25,
                              ),
                            ),
                            if (column.sortable) ...[
                              const SizedBox(width: 4),
                              Icon(
                                widget.sortBy == column.key
                                    ? (widget.sortAscending
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down)
                                    : Icons.unfold_more,
                                size: 16,
                                color: widget.sortBy == column.key
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF9CA3AF),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          // Table Body
          Expanded(
            child: ListView.builder(
              itemCount: widget.data.length,
              itemBuilder: (context, index) {
                final item = widget.data[index];
                final isSelected = widget.selectedItems.contains(item);
                final isEven = index % 2 == 0;

                return Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFF0F9FF)
                        : (isEven ? Colors.white : const Color(0xFFFAFBFC)),
                    border: const Border(
                      bottom: BorderSide(color: Color(0xFFF1F3F4), width: 1),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (widget.enableMultiSelect) {
                          final newSelection = Set<T>.from(
                            widget.selectedItems,
                          );
                          if (isSelected) {
                            newSelection.remove(item);
                          } else {
                            newSelection.add(item);
                          }
                          widget.onSelectionChanged?.call(newSelection);
                        } else {
                          widget.onRowTap?.call(item);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical:
                              12, // Reduced from 16 to 12 for smaller row height
                        ),
                        child: Row(
                          children: [
                            if (widget.enableMultiSelect)
                              Container(
                                width: 40,
                                alignment: Alignment.centerLeft,
                                child: Transform.scale(
                                  scale: 0.9,
                                  child: Checkbox(
                                    value: isSelected,
                                    onChanged: (value) {
                                      final newSelection = Set<T>.from(
                                        widget.selectedItems,
                                      );
                                      if (value == true) {
                                        newSelection.add(item);
                                      } else {
                                        newSelection.remove(item);
                                      }
                                      widget.onSelectionChanged?.call(
                                        newSelection,
                                      );
                                    },
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    activeColor: const Color(0xFF2563EB),
                                    checkColor: Colors.white,
                                    side: const BorderSide(
                                      color: Color(0xFFD1D5DB),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ...visibleColumns.map(
                              (column) => Expanded(
                                flex: column.flex ?? 1,
                                child: column.builder(item),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        border: Border(bottom: BorderSide(color: Color(0xFFE1E5E9))),
      ),
      child: Row(
        children: [
          if (widget.enableMultiSelect) ...[
            Text(
              '${widget.selectedItems.length} selected',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(width: 16),
            if (widget.selectedItems.isNotEmpty) ...[
              TextButton.icon(
                onPressed: () {
                  widget.onSelectionChanged?.call({});
                },
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Clear'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6B7280),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  widget.onSelectionChanged?.call(widget.data.toSet());
                },
                icon: const Icon(Icons.select_all, size: 16),
                label: const Text('Select All'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ],
          const Spacer(),
          if (widget.onColumnVisibilityChanged != null)
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.view_column,
                size: 20,
                color: Color(0xFF6B7280),
              ),
              tooltip: 'Show/Hide Columns',
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              itemBuilder: (context) => widget.columns
                  .map(
                    (col) => PopupMenuItem<String>(
                      value: col.key,
                      child: Row(
                        children: [
                          Transform.scale(
                            scale: 0.9,
                            child: Checkbox(
                              value: !widget.hiddenColumns.contains(col.key),
                              onChanged: (value) {
                                _toggleColumnVisibility(col.key);
                                Navigator.pop(context);
                              },
                              activeColor: const Color(0xFF2563EB),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(col.title, style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onSelected: _toggleColumnVisibility,
            ),
        ],
      ),
    );
  }

  void _toggleColumnVisibility(String columnKey) {
    List<String> newHiddenColumns = List.from(widget.hiddenColumns);
    if (newHiddenColumns.contains(columnKey)) {
      newHiddenColumns.remove(columnKey);
    } else {
      newHiddenColumns.add(columnKey);
    }
    widget.onColumnVisibilityChanged?.call(newHiddenColumns);
  }

  Widget _buildLoadingState() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Color(0xFF9CA3AF)),
            SizedBox(height: 16),
            Text(
              'No data available',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'There are no items to display at the moment.',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class BluNestTableColumn<T> {
  final String key;
  final String title;
  final Widget Function(T) builder;
  final bool sortable;
  final int? flex;

  BluNestTableColumn({
    required this.key,
    required this.title,
    required this.builder,
    this.sortable = false,
    this.flex,
  });
}
