import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class ResultsPagination extends StatefulWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int startItem;
  final int endItem;
  final Function(int) onPageChanged;
  final int itemsPerPage;
  final List<int> itemsPerPageOptions;
  final Function(int)? onItemsPerPageChanged;
  final bool showItemsPerPageSelector;
  final String itemLabel;

  const ResultsPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.startItem,
    required this.endItem,
    required this.onPageChanged,
    this.itemsPerPage = 10,
    this.itemsPerPageOptions = const [5, 10, 20, 50],
    this.onItemsPerPageChanged,
    this.showItemsPerPageSelector = true,
    this.itemLabel = 'Pages',
  });

  @override
  State<ResultsPagination> createState() => _ResultsPaginationState();
}

class _ResultsPaginationState extends State<ResultsPagination> {
  late TextEditingController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = TextEditingController(
      text: widget.currentPage.toString(),
    );
  }

  @override
  void didUpdateWidget(ResultsPagination oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPage != widget.currentPage) {
      _pageController.text = widget.currentPage.toString();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Results text
          //   _buildResultsText(theme),

          // Items per page selector
          if (widget.showItemsPerPageSelector &&
              widget.onItemsPerPageChanged != null) ...[
            const SizedBox(width: AppSizes.spacing24),
            _buildItemsPerPageSelector(theme),
          ],

          //  const Spacer(),
          const SizedBox(width: AppSizes.spacing8),
          // Page navigation with numbered buttons
          if (widget.totalPages > 1) _buildPageNavigation(theme),
        ],
      ),
    );
  }

  Widget _buildResultsText(ThemeData theme) {
    return Text(
      '${widget.startItem} to ${widget.endItem} of ${widget.totalItems} ${widget.itemLabel}',
      style: TextStyle(
        fontSize: AppSizes.fontSizeSmall,
        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildItemsPerPageSelector(ThemeData theme) {
    // Ensure the current itemsPerPage value is in the options list
    // If not, add it or use the closest value
    List<int> safeOptions = List.from(widget.itemsPerPageOptions);
    if (!safeOptions.contains(widget.itemsPerPage)) {
      safeOptions.add(widget.itemsPerPage);
      safeOptions.sort();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Text(
        //   'Items per page:',
        //   style: TextStyle(
        //     fontSize: AppSizes.fontSizeSmall,
        //     color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
        //     fontWeight: FontWeight.w400,
        //   ),
        // ),
        // const SizedBox(width: AppSizes.spacing8),
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
              value: widget.itemsPerPage,
              isDense: true,
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
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
              items: safeOptions.map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(value.toString()),
                );
              }).toList(),
              onChanged: (int? newValue) {
                if (newValue != null && widget.onItemsPerPageChanged != null) {
                  widget.onItemsPerPageChanged!(newValue);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageNavigation(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Previous button
        _buildNavigationButton(
          icon: Icons.chevron_left,
          onPressed: widget.currentPage > 1
              ? () => widget.onPageChanged(widget.currentPage - 1)
              : null,
          isEnabled: widget.currentPage > 1,
          theme: theme,
        ),

        const SizedBox(width: AppSizes.spacing8),

        // Page input field
        _buildPageInput(theme),

        const SizedBox(width: AppSizes.spacing8),

        // Page numbers with ellipsis
        ..._buildPageButtons(theme),

        const SizedBox(width: AppSizes.spacing8),

        // Next button
        _buildNavigationButton(
          icon: Icons.chevron_right,
          onPressed: widget.currentPage < widget.totalPages
              ? () => widget.onPageChanged(widget.currentPage + 1)
              : null,
          isEnabled: widget.currentPage < widget.totalPages,
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildPageInput(ThemeData theme) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        color: Colors.transparent,
      ),
      child: Center(
        child: TextField(
          controller: _pageController,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          style: TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            color: theme.textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w500,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            //  borderColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,

            // isDense: true,
          ),
          onSubmitted: (value) {
            final pageNum = int.tryParse(value);
            if (pageNum != null &&
                pageNum >= 1 &&
                pageNum <= widget.totalPages) {
              widget.onPageChanged(pageNum);
            } else {
              _pageController.text = widget.currentPage.toString();
            }
          },
        ),
      ),
    );
  }

  List<Widget> _buildPageButtons(ThemeData theme) {
    final pages = _generatePageNumbers();
    final buttons = <Widget>[];

    for (int i = 0; i < pages.length; i++) {
      final page = pages[i];

      if (page == -1) {
        // Ellipsis
        buttons.add(
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            child: Text(
              '...',
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.5,
                ),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        );
      } else {
        // Page button
        buttons.add(
          _buildPageButton(
            pageNumber: page,
            isActive: page == widget.currentPage,
            onTap: () => widget.onPageChanged(page),
            theme: theme,
          ),
        );
      }

      if (i < pages.length - 1) {
        buttons.add(const SizedBox(width: 4));
      }
    }

    return buttons;
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isEnabled,
    required ThemeData theme,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            border: Border.all(
              color: isEnabled
                  ? theme.dividerColor.withValues(alpha: 0.3)
                  : theme.dividerColor.withValues(alpha: 0.1),
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            color: theme.cardColor,
          ),
          child: Icon(
            icon,
            size: AppSizes.iconSmall,
            color: isEnabled
                ? theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8)
                : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }

  Widget _buildPageButton({
    required int pageNumber,
    required bool isActive,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : theme.cardColor,
          border: Border.all(
            color: isActive
                ? AppColors.primary
                : theme.dividerColor.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        ),
        alignment: Alignment.center,
        child: Text(
          pageNumber.toString(),
          style: TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            color: isActive ? Colors.white : theme.textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  List<int> _generatePageNumbers() {
    final pages = <int>[];

    if (widget.totalPages <= 7) {
      // Show all pages if 7 or fewer
      for (int i = 1; i <= widget.totalPages; i++) {
        pages.add(i);
      }
    } else {
      // Smart pagination with ellipsis
      if (widget.currentPage <= 4) {
        // Near the beginning
        for (int i = 1; i <= 5; i++) {
          pages.add(i);
        }
        pages.add(-1); // ellipsis
        pages.add(widget.totalPages);
      } else if (widget.currentPage >= widget.totalPages - 3) {
        // Near the end
        pages.add(1);
        pages.add(-1); // ellipsis
        for (int i = widget.totalPages - 4; i <= widget.totalPages; i++) {
          pages.add(i);
        }
      } else {
        // In the middle
        pages.add(1);
        pages.add(-1); // ellipsis
        for (int i = widget.currentPage - 1; i <= widget.currentPage + 1; i++) {
          pages.add(i);
        }
        pages.add(-1); // ellipsis
        pages.add(widget.totalPages);
      }
    }

    return pages;
  }
}
