import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class ResponsiveMapPagination extends StatefulWidget {
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

  const ResponsiveMapPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.startItem,
    required this.endItem,
    required this.onPageChanged,
    this.itemsPerPage = 8,
    this.itemsPerPageOptions = const [4, 8, 16, 32],
    this.onItemsPerPageChanged,
    this.showItemsPerPageSelector = true,
    this.itemLabel = 'devices',
    this.isLoading = false,
  });

  @override
  State<ResponsiveMapPagination> createState() =>
      _ResponsiveMapPaginationState();
}

class _ResponsiveMapPaginationState extends State<ResponsiveMapPagination> {
  late TextEditingController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = TextEditingController(
      text: widget.currentPage.toString(),
    );
  }

  @override
  void didUpdateWidget(ResponsiveMapPagination oldWidget) {
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
        final isLargeScreen = constraints.maxWidth >= 900;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? AppSizes.spacing8 : AppSizes.spacing16,
            vertical: isSmallScreen ? AppSizes.spacing8 : AppSizes.spacing12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: AppColors.border.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: isSmallScreen
              ? _buildCompactLayout()
              : isMediumScreen
              ? _buildMediumLayout()
              : _buildFullLayout(),
        );
      },
    );
  }

  Widget _buildCompactLayout() {
    // For small screens: Essential navigation + items per page selector
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Results info and items per page selector
        Row(
          children: [
            Expanded(child: _buildResultsInfo(isCompact: true)),
            if (widget.showItemsPerPageSelector &&
                widget.onItemsPerPageChanged != null)
              _buildItemsPerPageSelector(),
          ],
        ),

        const SizedBox(height: AppSizes.spacing8),

        // Navigation controls (always show, even for single page)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNavigationButton(
              icon: Icons.keyboard_double_arrow_left,
              onPressed: widget.currentPage > 1
                  ? () => widget.onPageChanged(1)
                  : null,
              isEnabled: widget.currentPage > 1,
              size: 28,
            ),

            const SizedBox(width: AppSizes.spacing4),

            _buildNavigationButton(
              icon: Icons.chevron_left,
              onPressed: widget.currentPage > 1
                  ? () => widget.onPageChanged(widget.currentPage - 1)
                  : null,
              isEnabled: widget.currentPage > 1,
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
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                '${widget.currentPage} / ${widget.totalPages}',
                style: const TextStyle(
                  fontSize: AppSizes.fontSizeSmall,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
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
              size: 28,
            ),

            const SizedBox(width: AppSizes.spacing4),

            _buildNavigationButton(
              icon: Icons.keyboard_double_arrow_right,
              onPressed: widget.currentPage < widget.totalPages
                  ? () => widget.onPageChanged(widget.totalPages)
                  : null,
              isEnabled: widget.currentPage < widget.totalPages,
              size: 28,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMediumLayout() {
    // For medium screens: Navigation + page numbers + items per page selector
    return Row(
      children: [
        // Results info
        Expanded(flex: 2, child: _buildResultsInfo()),

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
              ),

              const SizedBox(width: AppSizes.spacing8),

              // Limited page numbers for medium screens
              ..._buildLimitedPageButtons(),

              const SizedBox(width: AppSizes.spacing8),

              _buildNavigationButton(
                icon: Icons.chevron_right,
                onPressed: widget.currentPage < widget.totalPages
                    ? () => widget.onPageChanged(widget.currentPage + 1)
                    : null,
                isEnabled: widget.currentPage < widget.totalPages,
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
              children: [_buildItemsPerPageSelector()],
            ),
          ),
      ],
    );
  }

  Widget _buildFullLayout() {
    // For large screens: Full pagination with all features
    return Row(
      children: [
        // Results info
        _buildResultsInfo(),

        const Spacer(),

        // Items per page selector (always show if enabled)
        if (widget.showItemsPerPageSelector &&
            widget.onItemsPerPageChanged != null) ...[
          _buildItemsPerPageSelector(),
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
            ),

            const SizedBox(width: AppSizes.spacing4),

            _buildNavigationButton(
              icon: Icons.chevron_left,
              onPressed: widget.currentPage > 1
                  ? () => widget.onPageChanged(widget.currentPage - 1)
                  : null,
              isEnabled: widget.currentPage > 1,
            ),

            const SizedBox(width: AppSizes.spacing8),

            // Page input field
            _buildPageInput(),

            const SizedBox(width: AppSizes.spacing8),

            // Page numbers with smart ellipsis
            ..._buildSmartPageButtons(),

            const SizedBox(width: AppSizes.spacing8),

            _buildNavigationButton(
              icon: Icons.chevron_right,
              onPressed: widget.currentPage < widget.totalPages
                  ? () => widget.onPageChanged(widget.currentPage + 1)
                  : null,
              isEnabled: widget.currentPage < widget.totalPages,
            ),

            const SizedBox(width: AppSizes.spacing4),

            _buildNavigationButton(
              icon: Icons.keyboard_double_arrow_right,
              onPressed: widget.currentPage < widget.totalPages
                  ? () => widget.onPageChanged(widget.totalPages)
                  : null,
              isEnabled: widget.currentPage < widget.totalPages,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultsInfo({bool isCompact = false}) {
    return Row(
      mainAxisSize: isCompact ? MainAxisSize.min : MainAxisSize.max,
      children: [
        Icon(Icons.location_on, size: 16, color: AppColors.primary),
        const SizedBox(width: AppSizes.spacing4),

        Text(
          isCompact
              ? '${widget.totalItems} ${widget.itemLabel}'
              : '${widget.startItem}-${widget.endItem} of ${widget.totalItems} ${widget.itemLabel}',
          style: TextStyle(
            fontSize: isCompact
                ? AppSizes.fontSizeSmall
                : AppSizes.fontSizeSmall,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),

        if (widget.isLoading) ...[
          const SizedBox(width: AppSizes.spacing8),
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildItemsPerPageSelector() {
    List<int> safeOptions = List.from(widget.itemsPerPageOptions);
    if (!safeOptions.contains(widget.itemsPerPage)) {
      safeOptions.add(widget.itemsPerPage);
      safeOptions.sort();
    }

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: widget.itemsPerPage,
          isDense: true,
          style: const TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: AppSizes.iconSmall,
            color: AppColors.textSecondary,
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

  Widget _buildPageInput() {
    return Container(
      width: 40,
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        color: Colors.white,
      ),
      child: Center(
        child: TextField(
          controller: _pageController,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            color: AppColors.textPrimary,
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
                  ? AppColors.border.withValues(alpha: 0.3)
                  : AppColors.border.withValues(alpha: 0.1),
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            color: Colors.white,
          ),
          child: Icon(
            icon,
            size: size * 0.5,
            color: isEnabled ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildPageButton({
    required int pageNumber,
    required bool isActive,
    required VoidCallback onTap,
    double size = 32,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          border: Border.all(
            color: isActive
                ? AppColors.primary
                : AppColors.border.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        ),
        alignment: Alignment.center,
        child: Text(
          pageNumber.toString(),
          style: TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            color: isActive ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLimitedPageButtons() {
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
        ),
      );

      if (i < end) {
        buttons.add(const SizedBox(width: 4));
      }
    }

    return buttons;
  }

  List<Widget> _buildSmartPageButtons() {
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
                color: AppColors.textSecondary,
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
