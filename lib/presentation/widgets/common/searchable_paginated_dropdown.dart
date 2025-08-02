import 'package:flutter/material.dart';
import 'package:mdms_clone/core/constants/app_sizes.dart';

class SearchablePaginatedDropdown<T> extends StatefulWidget {
  final T? value;
  final String label;
  final String hintText;
  final List<DropdownMenuItem<T>> items;
  final bool isLoading;
  final bool hasMore;
  final String searchQuery;
  final ValueChanged<T?> onChanged;
  final VoidCallback onTap;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onLoadMore;

  const SearchablePaginatedDropdown({
    super.key,
    required this.value,
    required this.label,
    required this.hintText,
    required this.items,
    required this.isLoading,
    required this.hasMore,
    required this.searchQuery,
    required this.onChanged,
    required this.onTap,
    required this.onSearchChanged,
    required this.onLoadMore,
  });

  @override
  State<SearchablePaginatedDropdown<T>> createState() =>
      _SearchablePaginatedDropdownState<T>();
}

class _SearchablePaginatedDropdownState<T>
    extends State<SearchablePaginatedDropdown<T>> {
  final TextEditingController _searchController = TextEditingController();
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery;
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        widget.hasMore &&
        !widget.isLoading) {
      widget.onLoadMore();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showDropdown() {
    widget.onTap();

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 5.0),
          child: Material(
            elevation: 8.0,
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                border: Border.all(color: const Color(0xFFE1E5E9)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search field
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                            color: Color(0xFFE1E5E9),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                            color: Color(0xFFE1E5E9),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                            color: Color(0xFF2563eb),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: AppSizes.fontSizeSmall),
                      onChanged: (value) {
                        widget.onSearchChanged(value);
                      },
                    ),
                  ),
                  // Items list
                  Flexible(
                    child: widget.items.isEmpty && !widget.isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No items found',
                              style: TextStyle(
                                color: Color(0xFF64748b),
                                fontSize: AppSizes.fontSizeSmall,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            shrinkWrap: true,
                            itemCount:
                                widget.items.length +
                                (widget.isLoading ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == widget.items.length) {
                                // Loading indicator at the bottom
                                return const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              final item = widget.items[index];
                              final isSelected = item.value == widget.value;

                              return InkWell(
                                onTap: () {
                                  widget.onChanged(item.value);
                                  _removeOverlay();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(
                                            0xFF2563eb,
                                          ).withOpacity(0.1)
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(child: item.child),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check,
                                          color: Color(0xFF2563eb),
                                          size: 16,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getDisplayText() {
    if (widget.value == null) return widget.hintText;

    final selectedItem = widget.items.firstWhere(
      (item) => item.value == widget.value,
      orElse: () => DropdownMenuItem<T>(
        value: widget.value,
        child: Text(widget.hintText),
      ),
    );

    if (selectedItem.child is Text) {
      return (selectedItem.child as Text).data ?? widget.hintText;
    }

    return widget.hintText;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1e293b),
          ),
        ),
        const SizedBox(height: 8),
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: _showDropdown,
            child: Container(
              height: AppSizes.inputHeight,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE1E5E9)),
                borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                color: Colors.white,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _getDisplayText(),
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeSmall,
                          color: widget.value == null
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF1f2937),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFF64748b),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
