import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_enums.dart';
import '../common/app_button.dart';
import '../common/app_input_field.dart';

class SiteFiltersAndActions extends StatefulWidget {
  final String searchQuery;
  final Function(String) onSearchChanged;
  final SiteViewMode currentViewMode;
  final Function(SiteViewMode) onViewModeChanged;
  final VoidCallback onCreateSite;
  final Function(List<String>) onColumnsChanged;
  final List<String> availableColumns;
  final List<String> hiddenColumns;
  final VoidCallback? onRefresh;
  final int? totalItems;

  const SiteFiltersAndActions({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.currentViewMode,
    required this.onViewModeChanged,
    required this.onCreateSite,
    required this.onColumnsChanged,
    required this.availableColumns,
    required this.hiddenColumns,
    this.onRefresh,
    this.totalItems,
  });

  @override
  State<SiteFiltersAndActions> createState() => _SiteFiltersAndActionsState();
}

class _SiteFiltersAndActionsState extends State<SiteFiltersAndActions> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SiteFiltersAndActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      _searchController.text = widget.searchQuery;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: Column(
        children: [
          // Top row: Search, View Mode, Actions
          Row(
            children: [
              // Search field
              Expanded(
                flex: 2,
                child: AppInputField(
                  controller: _searchController,
                  hintText: 'Search sites...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: widget.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            widget.onSearchChanged('');
                          },
                        )
                      : null,
                  onChanged: widget.onSearchChanged,
                ),
              ),
              const SizedBox(width: AppSizes.spacing16),

              // View mode selector
              _buildViewModeSelector(),
              const SizedBox(width: AppSizes.spacing16),

              // Actions
              Row(
                children: [
                  // Refresh button
                  if (widget.onRefresh != null)
                    AppButton(
                      text: '',
                      icon: const Icon(Icons.refresh, size: 18),
                      type: AppButtonType.outline,
                      size: AppButtonSize.small,
                      onPressed: widget.onRefresh,
                    ),
                  const SizedBox(width: AppSizes.spacing8),

                  // Column visibility (only for table view)

                  // Create site button
                  AppButton(
                    text: 'Create Site',
                    icon: const Icon(Icons.add, size: 18),
                    type: AppButtonType.primary,
                    size: AppButtonSize.small,
                    onPressed: widget.onCreateSite,
                  ),
                ],
              ),
            ],
          ),

          // Results summary
          if (widget.totalItems != null) ...[
            const SizedBox(height: AppSizes.spacing12),
            Row(
              children: [
                Text(
                  'Found ${widget.totalItems} sites',
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeSmall,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (widget.searchQuery.isNotEmpty) ...[
                  const Text(
                    ' for "',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeSmall,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    widget.searchQuery,
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeSmall,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Text(
                    '"',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeSmall,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildViewModeSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeButton(
            icon: Icons.table_rows,
            isSelected: widget.currentViewMode == SiteViewMode.table,
            onPressed: () => widget.onViewModeChanged(SiteViewMode.table),
            tooltip: 'Table View',
          ),
          Container(width: 1, height: 32, color: AppColors.border),
          _buildModeButton(
            icon: Icons.view_kanban,
            isSelected: widget.currentViewMode == SiteViewMode.kanban,
            onPressed: () => widget.onViewModeChanged(SiteViewMode.kanban),
            tooltip: 'Kanban View',
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isSelected
            ? AppColors.primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          child: Container(
            padding: const EdgeInsets.all(AppSizes.spacing8),
            child: Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
