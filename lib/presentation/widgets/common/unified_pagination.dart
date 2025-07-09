import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import 'app_button.dart';

class UnifiedPagination extends StatefulWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final Function(int) onPageChanged;
  final Function(int)? onItemsPerPageChanged;
  final List<int> itemsPerPageOptions;
  final bool showItemsPerPageSelector;
  final bool showPageInput;
  final String itemLabel;

  const UnifiedPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.onPageChanged,
    this.onItemsPerPageChanged,
    this.itemsPerPageOptions = const [10, 25, 50, 100],
    this.showItemsPerPageSelector = true,
    this.showPageInput = true,
    this.itemLabel = 'items',
  });

  @override
  State<UnifiedPagination> createState() => _UnifiedPaginationState();
}

class _UnifiedPaginationState extends State<UnifiedPagination> {
  late TextEditingController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = TextEditingController(
      text: widget.currentPage.toString(),
    );
  }

  @override
  void didUpdateWidget(UnifiedPagination oldWidget) {
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

  void _goToPage() {
    final page = int.tryParse(_pageController.text);
    if (page != null && page >= 1 && page <= widget.totalPages) {
      widget.onPageChanged(page);
    } else {
      // Reset to current page if invalid
      _pageController.text = widget.currentPage.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final startItem = widget.totalItems > 0
        ? (widget.currentPage - 1) * widget.itemsPerPage + 1
        : 0;
    final endItem = (widget.currentPage * widget.itemsPerPage).clamp(
      0,
      widget.totalItems,
    );

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          // Items per page selector
          if (widget.showItemsPerPageSelector &&
              widget.onItemsPerPageChanged != null) ...[
            Text(
              'Show:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(width: AppSizes.spacing8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacing8,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: widget.itemsPerPage,
                  isDense: true,
                  items: widget.itemsPerPageOptions.map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(
                        value.toString(),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    if (newValue != null &&
                        widget.onItemsPerPageChanged != null) {
                      widget.onItemsPerPageChanged!(newValue);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: AppSizes.spacing8),
            Text(
              'per page',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(width: AppSizes.spacing24),
          ],

          // Items count
          Expanded(
            child: Text(
              'Showing $startItem-$endItem of ${widget.totalItems} ${widget.itemLabel}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),

          // Navigation controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // First page button
              AppButton(
                text: 'First',
                onPressed: widget.currentPage > 1
                    ? () => widget.onPageChanged(1)
                    : null,
                size: AppButtonSize.small,
                type: AppButtonType.secondary,
              ),
              const SizedBox(width: AppSizes.spacing8),

              // Previous page button
              AppButton(
                text: 'Previous',
                onPressed: widget.currentPage > 1
                    ? () => widget.onPageChanged(widget.currentPage - 1)
                    : null,
                size: AppButtonSize.small,
                type: AppButtonType.secondary,
              ),
              const SizedBox(width: AppSizes.spacing12),

              // Page input
              if (widget.showPageInput) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Page', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(width: AppSizes.spacing8),
                    Container(
                      width: 60,
                      height: 32,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusSmall,
                        ),
                      ),
                      child: TextFormField(
                        controller: _pageController,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: Theme.of(context).textTheme.bodyMedium,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppSizes.spacing4,
                            vertical: AppSizes.spacing4,
                          ),
                          isDense: true,
                        ),
                        onFieldSubmitted: (_) => _goToPage(),
                        onEditingComplete: _goToPage,
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacing8),
                    Text(
                      'of ${widget.totalPages}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing12,
                    vertical: AppSizes.spacing8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  ),
                  child: Text(
                    'Page ${widget.currentPage} of ${widget.totalPages}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],

              const SizedBox(width: AppSizes.spacing12),

              // Next page button
              AppButton(
                text: 'Next',
                onPressed: widget.currentPage < widget.totalPages
                    ? () => widget.onPageChanged(widget.currentPage + 1)
                    : null,
                size: AppButtonSize.small,
                type: AppButtonType.secondary,
              ),
              const SizedBox(width: AppSizes.spacing8),

              // Last page button
              AppButton(
                text: 'Last',
                onPressed: widget.currentPage < widget.totalPages
                    ? () => widget.onPageChanged(widget.totalPages)
                    : null,
                size: AppButtonSize.small,
                type: AppButtonType.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
