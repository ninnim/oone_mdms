import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusXLarge),
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
          // Table Header60
          Container(
            //    height: 60,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacing16,
              vertical: AppSizes.spacing8,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radiusXLarge),
                topRight: Radius.circular(AppSizes.radiusXLarge),
              ),
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
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
                        activeColor: AppColors.primary,
                        checkColor: AppColors.textInverse,
                        side: BorderSide(color: AppColors.border, width: 1.5),
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
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.spacing4,
                        ),
                        child: Row(
                          children: [
                            Text(
                              column.title,
                              style: const TextStyle(
                                fontSize: AppSizes.fontSizeSmall,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
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
                                size: AppSizes.iconSmall,
                                color: widget.sortBy == column.key
                                    ? AppColors.primary
                                    : AppColors.textTertiary,
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
                  //height: 60,
                  // padding: const EdgeInsets.symmetric(
                  //   // horizontal: AppSizes.spacing24,
                  //   vertical: AppSizes.spacing8,
                  // ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : (isEven
                              ? AppColors.surface
                              : AppColors.surfaceVariant),
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.borderLight,
                        width: 1,
                      ),
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
                          horizontal: AppSizes.spacing16,

                          vertical: AppSizes
                              .spacing4, // Reduced from 16 to 4 for smaller row height
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
                                    activeColor: AppColors.primary,
                                    checkColor: AppColors.textInverse,
                                    side: BorderSide(
                                      color: AppColors.border,
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
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (widget.enableMultiSelect) ...[
            Text(
              '${widget.selectedItems.length} selected',
              style: const TextStyle(
                fontSize: AppSizes.fontSizeMedium,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 16),
            if (widget.selectedItems.isNotEmpty) ...[
              TextButton.icon(
                onPressed: () {
                  widget.onSelectionChanged?.call({});
                },
                icon: const Icon(Icons.clear, size: AppSizes.iconMedium),
                label: const Text('Clear'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing12,
                    vertical: AppSizes.spacing8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  widget.onSelectionChanged?.call(widget.data.toSet());
                },
                icon: const Icon(Icons.select_all, size: AppSizes.iconMedium),
                label: const Text('Select All'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing12,
                    vertical: AppSizes.spacing8,
                  ),
                ),
              ),
            ],
          ],
          const Spacer(),
          if (widget.onColumnVisibilityChanged != null)
            PopupMenuButton<String>(
              icon: Icon(
                Icons.view_column,
                size: AppSizes.iconMedium,
                color: AppColors.textSecondary,
              ),
              tooltip: 'Show/Hide Columns',
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
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
                              activeColor: AppColors.primary,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: AppSizes.spacing8),
                          Text(
                            col.title,
                            style: const TextStyle(
                              fontSize: AppSizes.fontSizeMedium,
                            ),
                          ),
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
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            SizedBox(height: AppSizes.spacing16),
            Text(
              'Loading...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppSizes.fontSizeLarge,
              ),
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
            Icon(
              Icons.inbox_outlined,
              size: AppSizes.spacing64,
              color: AppColors.textTertiary,
            ),
            SizedBox(height: AppSizes.spacing16),
            Text(
              'No data available',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppSizes.fontSizeXLarge,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: AppSizes.spacing8),
            Text(
              'There are no items to display at the moment.',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: AppSizes.fontSizeMedium,
              ),
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
