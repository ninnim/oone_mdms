import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class ResultsPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final int startItem;
  final int endItem;
  final Function(int) onPageChanged;
  final Function(int)? onItemsPerPageChanged;
  final List<int> itemsPerPageOptions;
  final bool showItemsPerPageSelector;
  final String itemLabel;

  const ResultsPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.startItem,
    required this.endItem,
    required this.onPageChanged,
    this.onItemsPerPageChanged,
    this.itemsPerPageOptions = const [10, 20, 25, 50, 100],
    this.showItemsPerPageSelector = true,
    this.itemLabel = 'items',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing16,
        vertical: AppSizes.spacing12,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Results text
          _buildResultsText(theme),

          // Items per page selector
          if (showItemsPerPageSelector && onItemsPerPageChanged != null) ...[
            const SizedBox(width: AppSizes.spacing24),
            _buildItemsPerPageSelector(theme),
          ],

          const Spacer(),

          // Page navigation
          _buildPageNavigation(theme),
        ],
      ),
    );
  }

  Widget _buildResultsText(ThemeData theme) {
    return Text(
      'Results: $startItem - $endItem of $totalItems',
      style: TextStyle(
        fontSize: AppSizes.fontSizeMedium,
        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildItemsPerPageSelector(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing8),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            color: theme.cardColor,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: itemsPerPage,
              isDense: true,
              style: TextStyle(
                fontSize: AppSizes.fontSizeMedium,
                color: theme.textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w400,
              ),
              icon: Icon(
                Icons.keyboard_arrow_down,
                size: AppSizes.iconSmall,
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.6,
                ),
              ),
              items: itemsPerPageOptions.map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(value.toString()),
                );
              }).toList(),
              onChanged: (int? newValue) {
                if (newValue != null && onItemsPerPageChanged != null) {
                  onItemsPerPageChanged!(newValue);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageNavigation(ThemeData theme) {
    List<Widget> pageButtons = [];

    // Previous button
    pageButtons.add(
      _buildNavigationButton(
        icon: Icons.chevron_left,
        onPressed: currentPage > 1
            ? () => onPageChanged(currentPage - 1)
            : null,
        theme: theme,
      ),
    );

    // Page number buttons
    List<int> pageNumbers = _generatePageNumbers();

    for (int pageNum in pageNumbers) {
      if (pageNum == -1) {
        // Ellipsis
        pageButtons.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing4),
            child: Text(
              '...',
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.6,
                ),
              ),
            ),
          ),
        );
      } else {
        pageButtons.add(
          _buildPageButton(
            pageNumber: pageNum,
            isActive: pageNum == currentPage,
            theme: theme,
          ),
        );
      }
    }

    // Next button
    pageButtons.add(
      _buildNavigationButton(
        icon: Icons.chevron_right,
        onPressed: currentPage < totalPages
            ? () => onPageChanged(currentPage + 1)
            : null,
        theme: theme,
      ),
    );

    return Row(mainAxisSize: MainAxisSize.min, children: pageButtons);
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required ThemeData theme,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              border: Border.all(
                color: onPressed != null
                    ? theme.dividerColor.withValues(alpha: 0.3)
                    : theme.dividerColor.withValues(alpha: 0.1),
              ),
              borderRadius: BorderRadius.circular(4),
              color: theme.cardColor,
            ),
            child: Icon(
              icon,
              size: 16,
              color: onPressed != null
                  ? theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8)
                  : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageButton({
    required int pageNumber,
    required bool isActive,
    required ThemeData theme,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onPageChanged(pageNumber),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              border: Border.all(
                color: isActive
                    ? AppColors.primary.withValues(alpha: 0.6)
                    : theme.dividerColor.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(4),
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : theme.cardColor,
            ),
            child: Center(
              child: Text(
                pageNumber.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive
                      ? AppColors.primary
                      : theme.textTheme.bodyMedium?.color?.withValues(
                          alpha: 0.8,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<int> _generatePageNumbers() {
    List<int> pages = [];

    if (totalPages <= 7) {
      // Show all pages if 7 or fewer
      for (int i = 1; i <= totalPages; i++) {
        pages.add(i);
      }
    } else {
      // Always show first page
      pages.add(1);

      if (currentPage <= 4) {
        // Show pages 2, 3, 4, 5, ..., last
        for (int i = 2; i <= 5; i++) {
          pages.add(i);
        }
        pages.add(-1); // Ellipsis
        pages.add(totalPages);
      } else if (currentPage >= totalPages - 3) {
        // Show 1, ..., last-4, last-3, last-2, last-1, last
        pages.add(-1); // Ellipsis
        for (int i = totalPages - 4; i <= totalPages; i++) {
          pages.add(i);
        }
      } else {
        // Show 1, ..., current-1, current, current+1, ..., last
        pages.add(-1); // Ellipsis
        for (int i = currentPage - 1; i <= currentPage + 1; i++) {
          pages.add(i);
        }
        pages.add(-1); // Ellipsis
        pages.add(totalPages);
      }
    }

    return pages;
  }
}
