import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mdms_clone/presentation/widgets/common/app_input_field.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_colors.dart';

class AppSearchableDropdown<T> extends StatefulWidget {
  final String? label;
  final String hintText;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool hasMore;
  final String searchQuery;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onLoadMore;
  final String? Function(T?)? validator;
  final bool enabled;
  final double? height;
  final Duration debounceDelay;

  const AppSearchableDropdown({
    super.key,
    this.label,
    required this.hintText,
    this.value,
    required this.items,
    this.onChanged,
    this.onTap,
    this.isLoading = false,
    this.hasMore = false,
    this.searchQuery = '',
    this.onSearchChanged,
    this.onLoadMore,
    this.validator,
    this.enabled = true,
    this.height,
    this.debounceDelay = const Duration(milliseconds: 500),
  });

  @override
  State<AppSearchableDropdown<T>> createState() =>
      _AppSearchableDropdownState<T>();
}

class _AppSearchableDropdownState<T> extends State<AppSearchableDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  bool _isDropdownOpen = false;
  bool _shouldReopenAfterFetch = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Initialize search controller but don't sync with searchQuery
    // The search controller is only for the internal search field
    _searchController.text = '';

    // Remove focus listeners to prevent auto-closing
    // Dropdown will only close when:
    // 1. User clicks outside (handled by tap barrier)
    // 2. User selects an item
    // 3. User manually closes it
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    _closeDropdown();
    super.dispose();
  }

  @override
  void didUpdateWidget(AppSearchableDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Trigger rebuild if value changed
    if (oldWidget.value != widget.value) {
      setState(() {});
    }

    // Don't sync search controller with searchQuery to keep search independent
    // The search controller is only for the internal search field

    // Auto-reopen dropdown after data fetch if flag is set
    if (_shouldReopenAfterFetch &&
        !widget.isLoading &&
        widget.items.isNotEmpty &&
        !_isDropdownOpen) {
      _shouldReopenAfterFetch = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openDropdown();
      });
    }
  }

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    if (!_isDropdownOpen && mounted) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
      _isDropdownOpen = true;
      _focusNode.requestFocus();

      // Initialize search field with current search query when opening - use postFrameCallback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _searchController.text = widget.searchQuery;
          // Auto-focus search field if available
          if (widget.onSearchChanged != null) {
            _searchFocusNode.requestFocus();
          }
        }
      });

      setState(() {});
    }
  }

  void _closeDropdown() {
    if (_isDropdownOpen) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _isDropdownOpen = false;
      _focusNode.unfocus();

      // Clear search controller when closing to prevent interference
      _searchController.clear();

      setState(() {});
    }
  }

  void _onTap() {
    widget.onTap?.call();

    // If loading and no items, set flag to reopen after fetch
    if (widget.isLoading && widget.items.isEmpty) {
      _shouldReopenAfterFetch = true;
    }

    _toggleDropdown();
  }

  void _onSearchChanged(String value) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Start new timer
    _debounceTimer = Timer(widget.debounceDelay, () {
      widget.onSearchChanged?.call(value);
    });
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Size size = renderBox.size;
    final Offset offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Invisible barrier to detect clicks outside
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _closeDropdown();
              },
              child: Container(color: Colors.transparent),
            ),
          ),
          // Actual dropdown
          Positioned(
            left: offset.dx,
            top: offset.dy + size.height + 4,
            width: size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 4),
              child: GestureDetector(
                onTap: () {
                  // Prevent overlay from closing when tapping inside dropdown
                },
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  color: AppColors.surface,
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        AppSizes.radiusMedium,
                      ),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Search field (if search is enabled)
                        if (widget.onSearchChanged != null) ...[
                          AppInputField(
                            controller: _searchController,
                            //focusNode: _searchFocusNode,
                            onChanged: _onSearchChanged,
                            onTap: () {
                              // Prevent dropdown from closing when tapping search field
                            },
                            // decoration: InputDecoration(
                            //   hintText: 'Search...',
                            //   hintStyle: const TextStyle(
                            //     color: AppColors.textTertiary,
                            //     fontSize: AppSizes.fontSizeSmall,
                            //   ),
                            //   prefixIcon: const Icon(
                            //     Icons.search,
                            //     color: AppColors.textTertiary,
                            //     size: 20,
                            //   ),
                            //   border: OutlineInputBorder(
                            //     borderRadius: BorderRadius.circular(8),
                            //     borderSide: const BorderSide(
                            //       color: AppColors.border,
                            //     ),
                            //   ),
                            //   enabledBorder: OutlineInputBorder(
                            //     borderRadius: BorderRadius.circular(8),
                            //     borderSide: const BorderSide(
                            //       color: AppColors.border,
                            //     ),
                            //   ),
                            //   focusedBorder: OutlineInputBorder(
                            //     borderRadius: BorderRadius.circular(8),
                            //     borderSide: const BorderSide(
                            //       color: AppColors.primary,
                            //     ),
                            //   ),
                            //   contentPadding: const EdgeInsets.symmetric(
                            //     horizontal: 12,
                            //     vertical: 8,
                            //   ),
                            //   isDense: true,
                            // ),
                            // style: const TextStyle(
                            //   fontSize: AppSizes.fontSizeSmall,
                            // ),
                          ),
                          // Padding(
                          //   padding: const EdgeInsets.all(8.0),
                          //   child:

                          //   TextField(
                          //     controller: _searchController,
                          //     focusNode: _searchFocusNode,
                          //     onChanged: _onSearchChanged,
                          //     onTap: () {
                          //       // Prevent dropdown from closing when tapping search field
                          //     },
                          //     decoration: InputDecoration(
                          //       hintText: 'Search...',
                          //       hintStyle: const TextStyle(
                          //         color: AppColors.textTertiary,
                          //         fontSize: AppSizes.fontSizeSmall,
                          //       ),
                          //       prefixIcon: const Icon(
                          //         Icons.search,
                          //         color: AppColors.textTertiary,
                          //         size: 20,
                          //       ),
                          //       border: OutlineInputBorder(
                          //         borderRadius: BorderRadius.circular(8),
                          //         borderSide: const BorderSide(
                          //           color: AppColors.border,
                          //         ),
                          //       ),
                          //       enabledBorder: OutlineInputBorder(
                          //         borderRadius: BorderRadius.circular(8),
                          //         borderSide: const BorderSide(
                          //           color: AppColors.border,
                          //         ),
                          //       ),
                          //       focusedBorder: OutlineInputBorder(
                          //         borderRadius: BorderRadius.circular(8),
                          //         borderSide: const BorderSide(
                          //           color: AppColors.primary,
                          //         ),
                          //       ),
                          //       contentPadding: const EdgeInsets.symmetric(
                          //         horizontal: 12,
                          //         vertical: 8,
                          //       ),
                          //       isDense: true,
                          //     ),
                          //     style: const TextStyle(
                          //       fontSize: AppSizes.fontSizeSmall,
                          //     ),
                          //   ),
                          // ),
                          const Divider(height: 1, color: AppColors.border),
                        ],

                        // Loading indicator
                        if (widget.isLoading && widget.items.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 1),
                            ),
                          ),

                        // Items list
                        if (widget.items.isNotEmpty)
                          Flexible(
                            child: ListView.builder(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount:
                                  widget.items.length +
                                  (widget.hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                // Load more item
                                if (index == widget.items.length) {
                                  return _buildLoadMoreItem();
                                }

                                final item = widget.items[index];
                                final isSelected = item.value == widget.value;

                                return _buildDropdownItem(item, isSelected);
                              },
                            ),
                          ),

                        // Empty state
                        if (!widget.isLoading && widget.items.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No items found',
                              style: TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: AppSizes.fontSizeSmall,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownItem(DropdownMenuItem<T> item, bool isSelected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          widget.onChanged?.call(item.value);
          _closeDropdown();
          // Force a rebuild to update the display text
          setState(() {});
        },
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
              fontSize: AppSizes.fontSizeSmall,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
            child: item.child,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreItem() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onLoadMore,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: widget.isLoading
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Loading more...',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: AppSizes.fontSizeSmall,
                      ),
                    ),
                  ],
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.expand_more,
                      color: AppColors.textTertiary,
                      size: AppSizes.iconSmall,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Load more',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: AppSizes.fontSizeSmall,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null && widget.label!.isNotEmpty) ...[
            Text(
              widget.label!,
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
          ],

          FormField<T>(
            initialValue: widget.value,
            validator: widget.validator,
            builder: (FormFieldState<T> field) {
              // Update field value when widget value changes
              if (field.value != widget.value) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    field.didChange(widget.value);
                  }
                });
              }

              // Get display text based on current field value
              String getFieldDisplayText() {
                final currentValue = field.value ?? widget.value;
                if (currentValue == null) return '';

                final selectedItem = widget.items.firstWhere(
                  (item) => item.value == currentValue,
                  orElse: () => DropdownMenuItem<T>(
                    value: currentValue,
                    child: Text(currentValue.toString()),
                  ),
                );

                // Extract text from the widget
                if (selectedItem.child is Text) {
                  return (selectedItem.child as Text).data ?? '';
                }

                return currentValue.toString();
              }

              final displayText = getFieldDisplayText();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: widget.enabled ? _onTap : null,
                    child: Focus(
                      focusNode: _focusNode,
                      child: Container(
                        height: widget.height ?? AppSizes.inputHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusLarge,
                          ),
                          border: Border.all(
                            color: field.hasError
                                ? AppColors.error
                                : _isDropdownOpen
                                ? AppColors.primary
                                : AppColors.border,
                            width: _isDropdownOpen ? 2 : 1,
                          ),
                          color: widget.enabled
                              ? AppColors.surface
                              : AppColors.surface.withValues(alpha: 0.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  
                                  displayText.isEmpty
                                      ? widget.hintText
                                      : displayText,
                                  style: TextStyle(

                                    fontSize: AppSizes.fontSizeSmall,
                                    color: displayText.isEmpty
                                        ? AppColors.textTertiary
                                        : widget.enabled
                                        ? AppColors.textPrimary
                                        : AppColors.textTertiary,
                                  ),
                                ),
                              ),

                              if (widget.isLoading && widget.items.isEmpty)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary,
                                    ),
                                  ),
                                )
                              else
                                Icon(
                                  _isDropdownOpen
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: widget.enabled
                                      ? AppColors.textSecondary
                                      : AppColors.textTertiary,
                                  size: AppSizes.iconSmall,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (field.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        field.errorText!,
                        style: const TextStyle(
                          fontSize: AppSizes.fontSizeSmall,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
