import 'package:flutter/material.dart';
import 'package:mdms_clone/presentation/widgets/common/app_lottie_state_widget.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// Generic data model for Kanban items
abstract class KanbanItem {
  /// Unique identifier for the item
  String get id;

  /// Display title/name for the item
  String get title;

  /// Status/column for grouping
  String get status;

  /// Optional subtitle/description
  String? get subtitle => null;

  /// Optional badge text (e.g., count, priority)
  String? get badge => null;

  /// Optional status badge (e.g., link status, connection state)
  Widget? get statusBadge => null;

  /// Optional icon for the item
  IconData? get icon => null;

  /// Color scheme for the item (optional)
  Color? get itemColor => null;

  /// Additional details to display
  List<KanbanDetail> get details => [];

  /// Smart chips to display (e.g., month range, days of week)
  List<Widget> get smartChips => [];

  /// Whether the item is active/enabled
  bool get isActive => true;
}

/// Detail row structure for Kanban items
class KanbanDetail {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const KanbanDetail({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
}

/// Configuration for Kanban columns
class KanbanColumn {
  final String key;
  final String title;
  final IconData icon;
  final Color color;
  final String emptyMessage;

  const KanbanColumn({
    required this.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.emptyMessage,
  });
}

/// Action configuration for items
class KanbanAction {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  final Function(KanbanItem) onTap;

  const KanbanAction({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

/// Generic and reusable Kanban view widget
class KanbanView<T extends KanbanItem> extends StatelessWidget {
  final List<T> items;
  final List<KanbanColumn> columns;
  final List<KanbanAction> actions;
  final Function(T) onItemTap;
  final bool isLoading;
  final bool enablePagination;
  final int itemsPerPage;
  final double? columnWidth;
  final double? maxHeight;
  final EdgeInsets? padding;
  final Widget Function(T)? customItemBuilder;
  final Widget Function(String)? customEmptyBuilder;

  const KanbanView({
    super.key,
    required this.items,
    required this.columns,
    required this.onItemTap,
    this.actions = const [],
    this.isLoading = false,
    this.enablePagination = true,
    this.itemsPerPage = 25,
    this.columnWidth,
    this.maxHeight,
    this.padding,
    this.customItemBuilder,
    this.customEmptyBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: AppLottieStateWidget.loading(lottieSize: 80));
    }

    final groupedItems = _groupItemsByStatus();

    // Filter out empty columns
    final nonEmptyColumns = columns.where((column) {
      final columnItems = groupedItems[column.key] ?? [];
      return columnItems.isNotEmpty;
    }).toList();

    if (nonEmptyColumns.isEmpty) {
      return Center(
        child: Text(
          'No items to display',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: AppSizes.fontSizeMedium,
          ),
        ),
      );
    }

    // Calculate responsive column width
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth =
        screenWidth - (padding?.horizontal ?? AppSizes.spacing16 * 2);
    final dynamicColumnWidth = _calculateColumnWidth(
      availableWidth,
      nonEmptyColumns.length,
    );

    return Container(
      padding: padding ?? const EdgeInsets.all(AppSizes.spacing16),
      height: maxHeight,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: nonEmptyColumns.length == 1
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: nonEmptyColumns.map((column) {
              final columnItems = groupedItems[column.key] ?? [];
              return _buildStatusColumn(
                column,
                columnItems,
                dynamicColumnWidth,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// Calculate responsive column width based on available space and number of columns
  double _calculateColumnWidth(double availableWidth, int columnCount) {
    if (columnWidth != null) {
      return columnWidth!;
    }

    const minColumnWidth = 280.0;
    const maxColumnWidth = 450.0;
    const columnSpacing = AppSizes.spacing16;

    // Calculate total spacing between columns
    final totalSpacing = (columnCount - 1) * columnSpacing;
    final availableWidthForColumns = availableWidth - totalSpacing;

    // Calculate width per column
    double calculatedWidth = availableWidthForColumns / columnCount;

    // Smart responsive behavior based on screen size and column count:
    if (availableWidth < 768) {
      // Mobile: Prioritize readability, allow horizontal scroll if needed
      if (columnCount == 1) {
        calculatedWidth = (availableWidthForColumns * 0.95).clamp(
          minColumnWidth,
          maxColumnWidth,
        );
      } else {
        // For multiple columns on mobile, use minimum width to ensure readability
        calculatedWidth = minColumnWidth;
      }
    } else if (availableWidth < 1024) {
      // Tablet: Balance between fitting columns and readability
      if (columnCount <= 2) {
        calculatedWidth = (availableWidthForColumns / columnCount).clamp(
          minColumnWidth,
          maxColumnWidth,
        );
      } else {
        calculatedWidth = calculatedWidth.clamp(
          minColumnWidth,
          maxColumnWidth * 0.8,
        );
      }
    } else {
      // Desktop: Try to fit all columns while maintaining readability
      if (columnCount == 1) {
        // Single column gets centered with comfortable width
        calculatedWidth = (availableWidthForColumns * 0.6).clamp(
          minColumnWidth,
          maxColumnWidth,
        );
      } else if (columnCount <= 3) {
        calculatedWidth = (availableWidthForColumns / columnCount).clamp(
          minColumnWidth,
          maxColumnWidth,
        );
      } else {
        // For many columns, allow horizontal scroll with reasonable width
        calculatedWidth = calculatedWidth.clamp(
          minColumnWidth,
          maxColumnWidth * 0.9,
        );
      }
    }

    // Ensure minimum width is respected
    if (calculatedWidth < minColumnWidth) {
      calculatedWidth = minColumnWidth;
    }

    return calculatedWidth;
  }

  Map<String, List<T>> _groupItemsByStatus() {
    final Map<String, List<T>> grouped = {};

    // Initialize with empty lists for all columns
    for (final column in columns) {
      grouped[column.key] = [];
    }

    // Group items by status
    for (final item in items) {
      final status = item.status.toLowerCase().trim();
      String columnKey;

      // Handle empty status
      if (status.isEmpty) {
        columnKey = 'none';
      } else {
        // Find matching column or default to the first one
        final matchingColumn = columns.firstWhere(
          (col) => col.key.toLowerCase() == status,
          orElse: () => columns.firstWhere(
            (col) => col.key == 'none',
            orElse: () => columns.first,
          ),
        );
        columnKey = matchingColumn.key;
      }

      grouped[columnKey]!.add(item);
    }

    return grouped;
  }

  Widget _buildStatusColumn(
    KanbanColumn column,
    List<T> items,
    double effectiveColumnWidth,
  ) {
    return Container(
      width: effectiveColumnWidth,
      margin: const EdgeInsets.only(right: AppSizes.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.border),
        boxShadow: [AppSizes.shadowSmall],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column header
          Container(
            padding: const EdgeInsets.all(AppSizes.spacing16),
            decoration: BoxDecoration(
              color: column.color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radiusMedium),
                topRight: Radius.circular(AppSizes.radiusMedium),
              ),
              border: Border(
                bottom: BorderSide(color: column.color.withValues(alpha: 0.2)),
              ),
            ),
            child: Row(
              children: [
                Icon(column.icon, color: column.color, size: 20),
                const SizedBox(width: AppSizes.spacing8),
                Expanded(
                  child: Text(
                    column.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: column.color,
                      fontSize: AppSizes.fontSizeMedium,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSizes.spacing8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing8,
                    vertical: AppSizes.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: column.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  ),
                  child: Text(
                    '${items.length}',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeSmall,
                      fontWeight: FontWeight.w600,
                      color: column.color,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Items list
          Expanded(
            child: items.isEmpty
                ? _buildEmptyState(column)
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSizes.spacing8),
                    itemCount: enablePagination
                        ? (items.length > itemsPerPage
                              ? itemsPerPage
                              : items.length)
                        : items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return customItemBuilder?.call(item) ??
                          _buildItemCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(KanbanColumn column) {
    if (customEmptyBuilder != null) {
      return customEmptyBuilder!(column.key);
    }

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            column.icon,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSizes.spacing12),
          Text(
            column.emptyMessage,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppSizes.fontSizeSmall,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(T item) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacing8),
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.border),
        boxShadow: [AppSizes.shadowSmall],
      ),
      child: InkWell(
        onTap: () => onItemTap(item),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title, status, and actions
            Row(
              children: [
                if (item.icon != null) ...[
                  Icon(
                    item.icon!,
                    color: item.itemColor ?? AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: AppSizes.spacing8),
                ],
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: AppSizes.fontSizeMedium,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSizes.spacing8),
                if (item.badge != null) _buildBadge(item.badge!),
                if (item.statusBadge != null) ...[
                  const SizedBox(width: AppSizes.spacing4),
                  item.statusBadge!,
                ],
                if (actions.isNotEmpty) ...[
                  const SizedBox(width: AppSizes.spacing4),
                  _buildActionsDropdown(item),
                ],
              ],
            ),

            // Subtitle
            if (item.subtitle != null) ...[
              const SizedBox(height: AppSizes.spacing8),
              Text(
                item.subtitle!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppSizes.fontSizeSmall,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Smart chips
            if (item.smartChips.isNotEmpty) ...[
              const SizedBox(height: AppSizes.spacing8),
              ...item.smartChips.map(
                (chip) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.spacing4),
                  child: chip,
                ),
              ),
            ],

            // Details
            if (item.details.isNotEmpty) ...[
              const SizedBox(height: AppSizes.spacing12),
              ...item.details.map(
                (detail) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.spacing6),
                  child: _buildDetailRow(detail),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing8,
        vertical: AppSizes.spacing4,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppSizes.fontSizeExtraSmall,
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDetailRow(KanbanDetail detail) {
    return Row(
      children: [
        Icon(
          detail.icon,
          size: AppSizes.iconSmall,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppSizes.spacing8),
        Text(
          '${detail.label}:',
          style: const TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: AppSizes.spacing4),
        Expanded(
          child: Text(
            detail.value,
            style: TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              color: detail.valueColor ?? AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionsDropdown(T item) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert,
        color: AppColors.textSecondary,
        size: 16,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      itemBuilder: (context) => actions.map((action) {
        return PopupMenuItem<String>(
          value: action.key,
          child: Row(
            children: [
              Icon(action.icon, size: 16, color: action.color),
              const SizedBox(width: AppSizes.spacing8),
              Text(
                action.label,
                style: action.color == AppColors.error
                    ? TextStyle(color: action.color)
                    : null,
              ),
            ],
          ),
        );
      }).toList(),
      onSelected: (value) {
        final action = actions.firstWhere((a) => a.key == value);
        action.onTap(item);
      },
    );
  }
}
