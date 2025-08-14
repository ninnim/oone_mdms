import 'package:flutter/material.dart';
import 'package:mdms_clone/presentation/widgets/common/app_lottie_state_widget.dart';
import 'package:mdms_clone/presentation/widgets/common/status_chip.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class BluNestDataTable<T> extends StatefulWidget {
  final List<BluNestTableColumn<T>> columns;
  final List<T> data;
  final Function(T)? onRowTap;
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

  // New parameters for enhanced selection
  final int? totalItemsCount;
  final Future<List<T>> Function()? onSelectAllItems;
  final Function(T)? onEdit;

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
    this.totalItemsCount,
    this.onSelectAllItems,
  });

  @override
  State<BluNestDataTable<T>> createState() => _BluNestDataTableState<T>();
}

class _BluNestDataTableState<T> extends State<BluNestDataTable<T>> {
  bool _isSelectingAllItems = false;

  /// Helper method to determine if all items are selected
  bool _isAllItemsSelected() {
    if (widget.selectedItems.isEmpty || widget.data.isEmpty) {
      return false;
    }

    // If we have total items count, check against that
    if (widget.totalItemsCount != null) {
      return widget.selectedItems.length == widget.totalItemsCount;
    }

    // Otherwise, check against current page data
    return widget.selectedItems.length == widget.data.length;
  }

  List<BluNestTableColumn<T>> get visibleColumns {
    final columns = widget.columns
        .where((col) => !widget.hiddenColumns.contains(col.key))
        .toList();

    // Sort columns: non-actions first, then actions columns at the end
    final nonActionsColumns = columns.where((col) => !col.isActions).toList();
    final actionsColumns = columns.where((col) => col.isActions).toList();

    return [...nonActionsColumns, ...actionsColumns];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingState();
    }

    if (widget.data.isEmpty) {
      return _buildEmptyStateWithHeaders();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
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
        mainAxisSize: MainAxisSize.min,
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
                        value: _isAllItemsSelected(),
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
                        alignment: column.isActions
                            ? Alignment.centerRight
                            : (column.alignment ?? Alignment.centerLeft),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.spacing4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: column.isActions
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Text(
                                column.title,
                                style: const TextStyle(
                                  fontSize: AppSizes.fontSizeSmall,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  letterSpacing: 0.25,
                                ),
                                overflow: TextOverflow.ellipsis,
                                textAlign: column.isActions
                                    ? TextAlign.right
                                    : TextAlign.left,
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
                        // Always call onRowTap when available - this opens sidebar
                        widget.onRowTap?.call(item);
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
                                child: Container(
                                  alignment: column.isActions
                                      ? Alignment.centerRight
                                      : (column.alignment ??
                                            Alignment.centerLeft),
                                  child: column.builder(item),
                                ),
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
            StatusChip(
              text: '${widget.selectedItems.length} selected',
              type: StatusChipType.info,
              compact: true,
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
              // Enhanced Select All with dropdown
              _buildSelectAllButton(),
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
              itemBuilder: (context) => [
                // Show All Columns option
                if (widget.hiddenColumns.isNotEmpty)
                  PopupMenuItem<String>(
                    value: '__show_all__',
                    child: Row(
                      children: [
                        Icon(
                          Icons.visibility,
                          size: AppSizes.iconSmall,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSizes.spacing8),
                        Text(
                          'Show All Columns',
                          style: TextStyle(
                            fontSize: AppSizes.fontSizeMedium,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Divider if there are hidden columns
                if (widget.hiddenColumns.isNotEmpty) const PopupMenuDivider(),
                // Individual column toggles
                ...widget.columns.map(
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
                ),
              ],
              onSelected: (value) {
                if (value == '__show_all__') {
                  // Show all columns
                  widget.onColumnVisibilityChanged?.call([]);
                } else {
                  _toggleColumnVisibility(value);
                }
              },
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

  Widget _buildSelectAllButton() {
    // If we don't have total count or select all callback, show simple select all
    if (widget.totalItemsCount == null || widget.onSelectAllItems == null) {
      return TextButton.icon(
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
      );
    }

    // Enhanced version with dropdown
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'current_page') {
          widget.onSelectionChanged?.call(widget.data.toSet());
        } else if (value == 'all_items') {
          setState(() {
            _isSelectingAllItems = true;
          });

          try {
            final allItems = await widget.onSelectAllItems!();
            widget.onSelectionChanged?.call(allItems.toSet());
          } catch (e) {
            // Handle error - maybe show a snackbar
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to select all items: $e'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          } finally {
            if (mounted) {
              setState(() {
                _isSelectingAllItems = false;
              });
            }
          }
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'current_page',
          child: Row(
            children: [
              const Icon(Icons.select_all, size: AppSizes.iconSmall),
              const SizedBox(width: AppSizes.spacing8),
              Text('Select All (${widget.data.length} items)'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'all_items',
          child: Row(
            children: [
              const Icon(Icons.done_all, size: AppSizes.iconSmall),
              const SizedBox(width: AppSizes.spacing8),
              Text('Select All (${widget.totalItemsCount} items)'),
            ],
          ),
        ),
      ],
      child: TextButton.icon(
        onPressed: null, // Disabled, dropdown handles the action
        icon: _isSelectingAllItems
            ? const SizedBox(
                width: AppSizes.iconMedium,
                height: AppSizes.iconMedium,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.select_all, size: AppSizes.iconMedium),
        label: Text(_isSelectingAllItems ? 'Selecting...' : 'Select All'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacing12,
            vertical: AppSizes.spacing8,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateWithHeaders() {
    return Column(
      children: [
        // Show table controls if needed
        if (widget.onColumnVisibilityChanged != null ||
            widget.enableMultiSelect)
          _buildTableControls(),

        // Container with table header and empty state
        Expanded(
          child: Container(
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
              mainAxisSize: MainAxisSize.min,
              children: [
                // Table Header - Same as in _buildTable()
                Container(
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
                              value: false, // No data, so nothing selected
                              onChanged: null, // Disabled when no data
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
                      ...visibleColumns.asMap().entries.map((entry) {
                        final column = entry.value;
                        return Expanded(
                          flex: column.flex ?? 1,
                          child: InkWell(
                            onTap: column.sortable
                                ? () {
                                    final ascending =
                                        widget.sortBy == column.key
                                        ? !widget.sortAscending
                                        : true;
                                    widget.onSort?.call(column.key, ascending);
                                  }
                                : null,
                            child: Container(
                              alignment: column.isActions
                                  ? Alignment.centerRight
                                  : (column.alignment ?? Alignment.centerLeft),
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSizes.spacing4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: column.isActions
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                children: [
                                  Flexible(
                                    child: Text(
                                      column.title,
                                      style: const TextStyle(
                                        fontSize: AppSizes.fontSizeSmall,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                        letterSpacing: 0.25,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: column.isActions
                                          ? TextAlign.right
                                          : TextAlign.left,
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

                // Empty state content
                Expanded(
                  child:
                      widget.emptyState ??
                      AppLottieStateWidget.noData(lottieSize: 120),
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppLottieStateWidget.loading(
              title: 'Loading',
              message: '',
              lottieSize: 80,
              titleColor: AppColors.primary,
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
  final Alignment? alignment;
  final bool isActions;

  BluNestTableColumn({
    required this.key,
    required this.title,
    required this.builder,
    this.sortable = false,
    this.flex,
    this.alignment,
    this.isActions = false,
  });
}
