import 'package:flutter/material.dart';
import 'package:mdms_clone/presentation/themes/app_theme.dart';
import 'package:mdms_clone/presentation/widgets/common/app_lottie_state_widget.dart';
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
  final bool isLoading;

  const ResultsPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.startItem,
    required this.endItem,
    required this.onPageChanged,
    this.itemsPerPage = 10,
    this.itemsPerPageOptions = const [5, 10, 20, 50, 100, 200],
    this.onItemsPerPageChanged,
    this.showItemsPerPageSelector = true,
    this.itemLabel = 'items',
    this.isLoading = false,
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
    // Always show pagination if there are items, even if only one page
    if (widget.totalItems <= 0) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final isMediumScreen =
            constraints.maxWidth >= 600 && constraints.maxWidth < 900;

        final theme = Theme.of(context);

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? AppSizes.spacing8 : AppSizes.spacing16,
            vertical: isSmallScreen ? AppSizes.spacing8 : AppSizes.spacing12,
          ),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(color: context.borderColor, width: 1),
            ),
            boxShadow: [AppSizes.shadowSmall],
          ),
          child: isSmallScreen
              ? _buildCompactLayout(theme)
              : isMediumScreen
              ? _buildMediumLayout(theme)
              : _buildFullLayout(theme),
        );
      },
    );
  }

  Widget _buildCompactLayout(ThemeData theme) {
    // For small screens: Essential navigation + items per page selector
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Results info and items per page selector
        Row(
          children: [
            Expanded(child: _buildResultsInfo(theme, isCompact: true)),
            if (widget.showItemsPerPageSelector &&
                widget.onItemsPerPageChanged != null)
              _buildItemsPerPageSelector(theme),
            const SizedBox(width: AppSizes.spacing8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildNavigationButton(
                  icon: Icons.keyboard_double_arrow_left,
                  onPressed: widget.currentPage > 1
                      ? () => widget.onPageChanged(1)
                      : null,
                  isEnabled: widget.currentPage > 1,
                  theme: theme,
                  size: 28,
                ),

                const SizedBox(width: AppSizes.spacing4),

                _buildNavigationButton(
                  icon: Icons.chevron_left,
                  onPressed: widget.currentPage > 1
                      ? () => widget.onPageChanged(widget.currentPage - 1)
                      : null,
                  isEnabled: widget.currentPage > 1,
                  theme: theme,
                  size: 28,
                ),

                const SizedBox(width: AppSizes.spacing8),

                // Page indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing8,
                    vertical: AppSizes.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    border: Border.all(
                      color: context.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '${widget.currentPage} / ${widget.totalPages}',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeSmall,
                      fontWeight: FontWeight.w600,
                      color: context.primaryColor,
                    ),
                  ),
                ),

                const SizedBox(width: AppSizes.spacing8),

                _buildNavigationButton(
                  icon: Icons.chevron_right,
                  onPressed: widget.currentPage < widget.totalPages
                      ? () => widget.onPageChanged(widget.currentPage + 1)
                      : null,
                  isEnabled: widget.currentPage < widget.totalPages,
                  theme: theme,
                  size: 28,
                ),

                const SizedBox(width: AppSizes.spacing4),

                _buildNavigationButton(
                  icon: Icons.keyboard_double_arrow_right,
                  onPressed: widget.currentPage < widget.totalPages
                      ? () => widget.onPageChanged(widget.totalPages)
                      : null,
                  isEnabled: widget.currentPage < widget.totalPages,
                  theme: theme,
                  size: 28,
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: AppSizes.spacing8),
      ],
    );
  }

  Widget _buildMediumLayout(ThemeData theme) {
    // For medium screens: Navigation + page numbers + items per page selector
    return Row(
      children: [
        // Results info
        Expanded(flex: 2, child: _buildResultsInfo(theme)),

        // Spacer
        const SizedBox(width: AppSizes.spacing16),

        // Navigation (always show, even for single page)
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildNavigationButton(
                icon: Icons.chevron_left,
                onPressed: widget.currentPage > 1
                    ? () => widget.onPageChanged(widget.currentPage - 1)
                    : null,
                isEnabled: widget.currentPage > 1,
                theme: theme,
              ),

              const SizedBox(width: AppSizes.spacing8),

              // Limited page numbers for medium screens
              ..._buildLimitedPageButtons(theme),

              const SizedBox(width: AppSizes.spacing8),

              _buildNavigationButton(
                icon: Icons.chevron_right,
                onPressed: widget.currentPage < widget.totalPages
                    ? () => widget.onPageChanged(widget.currentPage + 1)
                    : null,
                isEnabled: widget.currentPage < widget.totalPages,
                theme: theme,
              ),
            ],
          ),
        ),

        // Items per page selector (always show if enabled)
        if (widget.showItemsPerPageSelector &&
            widget.onItemsPerPageChanged != null)
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [_buildItemsPerPageSelector(theme)],
            ),
          ),
      ],
    );
  }

  Widget _buildFullLayout(ThemeData theme) {
    // For large screens: Full pagination with all features
    return Row(
      children: [
        // Results info
        _buildResultsInfo(theme),

        const Spacer(),

        // Items per page selector (always show if enabled)
        if (widget.showItemsPerPageSelector &&
            widget.onItemsPerPageChanged != null) ...[
          _buildItemsPerPageSelector(theme),
          const SizedBox(width: AppSizes.spacing24),
        ],

        // Full navigation with page numbers (always show)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNavigationButton(
              icon: Icons.keyboard_double_arrow_left,
              onPressed: widget.currentPage > 1
                  ? () => widget.onPageChanged(1)
                  : null,
              isEnabled: widget.currentPage > 1,
              theme: theme,
            ),

            const SizedBox(width: AppSizes.spacing4),

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

            // Page numbers with smart ellipsis
            ..._buildSmartPageButtons(theme),

            const SizedBox(width: AppSizes.spacing8),

            _buildNavigationButton(
              icon: Icons.chevron_right,
              onPressed: widget.currentPage < widget.totalPages
                  ? () => widget.onPageChanged(widget.currentPage + 1)
                  : null,
              isEnabled: widget.currentPage < widget.totalPages,
              theme: theme,
            ),

            const SizedBox(width: AppSizes.spacing4),

            _buildNavigationButton(
              icon: Icons.keyboard_double_arrow_right,
              onPressed: widget.currentPage < widget.totalPages
                  ? () => widget.onPageChanged(widget.totalPages)
                  : null,
              isEnabled: widget.currentPage < widget.totalPages,
              theme: theme,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultsInfo(ThemeData theme, {bool isCompact = false}) {
    return Row(
      mainAxisSize: isCompact ? MainAxisSize.min : MainAxisSize.max,
      children: [
        // items
        Text(
          isCompact
              ? ''
              // ? '${widget.totalItems} ${widget.itemLabel}'
              : '${widget.startItem} to ${widget.endItem} of ${widget.totalItems} ${widget.itemLabel}',
          style: TextStyle(
            fontSize: isCompact
                ? AppSizes.fontSizeSmall
                : AppSizes.fontSizeSmall,
            color: context.textSecondaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),

        if (widget.isLoading) ...[AppLottieStateWidget.loading(lottieSize: 80)],
      ],
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

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing8),
      decoration: BoxDecoration(
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        color: theme.cardColor,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: widget.itemsPerPage,
          isDense: true,
          style: TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            color: context.textPrimaryColor,
            fontWeight: FontWeight.w400,
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: AppSizes.iconSmall,
            color: context.textSecondaryColor,
          ),
          items: safeOptions.map((int value) {
            return DropdownMenuItem<int>(
              value: value,
              child: Text('$value per page'),
            );
          }).toList(),
          onChanged: (int? newValue) {
            if (newValue != null && widget.onItemsPerPageChanged != null) {
              widget.onItemsPerPageChanged!(newValue);
            }
          },
        ),
      ),
    );
  }

  Widget _buildPageInput(ThemeData theme) {
    return Container(
      width: 40,
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        color: theme.cardColor,
      ),
      child: Center(
        child: TextField(
          controller: _pageController,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          style: TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            color: context.textPrimaryColor,
            fontWeight: FontWeight.w600,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
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

  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isEnabled,
    required ThemeData theme,
    double size = 32,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border.all(
              color: isEnabled
                  ? context.borderColor
                  : context.borderColor.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            color: theme.cardColor,
          ),
          child: Icon(
            icon,
            size: size * 0.5,
            color: isEnabled
                ? context.textPrimaryColor
                : context.textSecondaryColor,
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
    double size = 32,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isActive ? context.primaryColor : theme.cardColor,
          border: Border.all(
            color: isActive ? context.primaryColor : context.borderColor,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        ),
        alignment: Alignment.center,
        child: Text(
          pageNumber.toString(),
          style: TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            color: isActive
                ? theme.colorScheme.onPrimary
                : context.textPrimaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLimitedPageButtons(ThemeData theme) {
    // For medium screens - show only 3-5 page numbers around current page
    final buttons = <Widget>[];
    final maxButtons = 5;

    int start = (widget.currentPage - 2).clamp(1, widget.totalPages);
    int end = (start + maxButtons - 1).clamp(1, widget.totalPages);

    // Adjust start if we're near the end
    if (end - start < maxButtons - 1) {
      start = (end - maxButtons + 1).clamp(1, widget.totalPages);
    }

    for (int i = start; i <= end; i++) {
      buttons.add(
        _buildPageButton(
          pageNumber: i,
          isActive: i == widget.currentPage,
          onTap: () => widget.onPageChanged(i),
          theme: theme,
        ),
      );

      if (i < end) {
        buttons.add(const SizedBox(width: 4));
      }
    }

    return buttons;
  }

  List<Widget> _buildSmartPageButtons(ThemeData theme) {
    // For large screens - full smart pagination
    final pages = _generateSmartPageNumbers();
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
              '⋯',
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

  List<int> _generateSmartPageNumbers() {
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
