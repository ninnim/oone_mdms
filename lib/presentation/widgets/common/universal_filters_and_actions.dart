import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';
import '../../../core/constants/app_sizes.dart';
import 'app_button.dart';
import 'app_input_field.dart';
import 'app_dropdown_field.dart';
import 'advanced_filters.dart';

/// Universal Filters and Actions Widget
///
/// A reusable widget that provides:
/// - Search functionality
/// - View mode switching (table, kanban, map)
/// - Advanced filters panel
/// - Action buttons (add, refresh, export, import, etc.)
/// - Column visibility management
///
/// This widget can be used across all screens that need filtering and actions.
class UniversalFiltersAndActions<T extends Enum> extends StatefulWidget {
  // Basic Properties
  final String searchHint;
  final Function(String) onSearchChanged;
  final VoidCallback? onAddItem;
  final VoidCallback onRefresh;
  final String addButtonText;
  final IconData addButtonIcon;

  // View Mode Properties
  final List<T> availableViewModes;
  final T currentViewMode;
  final Function(T) onViewModeChanged;
  final Map<T, ViewModeConfig> viewModeConfigs;

  // Advanced Filters
  final List<FilterConfig>? filterConfigs;
  final Map<String, dynamic> filterValues;
  final Function(Map<String, dynamic>)? onFiltersChanged;

  // Quick Filters (for backward compatibility)
  final List<QuickFilterConfig>? quickFilters;
  final Function(String, dynamic)? onQuickFilterChanged;

  // Action Buttons
  final List<ActionButtonConfig>? actionButtons;
  final VoidCallback? onExport;
  final VoidCallback? onImport;

  // Column Management
  final List<String>? availableColumns;
  final List<String>? hiddenColumns;
  final Function(List<String>)? onColumnVisibilityChanged;

  // Styling
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final bool showBorder;
  final String? title;

  const UniversalFiltersAndActions({
    super.key,
    // Required properties
    required this.searchHint,
    required this.onSearchChanged,
    required this.onRefresh,
    required this.addButtonText,
    required this.availableViewModes,
    required this.currentViewMode,
    required this.onViewModeChanged,
    required this.viewModeConfigs,

    // Optional properties
    this.onAddItem,
    this.addButtonIcon = Icons.add,
    this.filterConfigs,
    this.filterValues = const {},
    this.onFiltersChanged,
    this.quickFilters,
    this.onQuickFilterChanged,
    this.actionButtons,
    this.onExport,
    this.onImport,
    this.availableColumns,
    this.hiddenColumns,
    this.onColumnVisibilityChanged,
    this.backgroundColor,
    this.padding,
    this.showBorder = true,
    this.title,
  });

  @override
  State<UniversalFiltersAndActions<T>> createState() =>
      _UniversalFiltersAndActionsState<T>();
}

class _UniversalFiltersAndActionsState<T extends Enum>
    extends State<UniversalFiltersAndActions<T>> {
  final TextEditingController _searchController = TextEditingController();
  bool _showAdvancedFilters = false;
  bool _showQuickFilters = false;
  bool _showColumnSettings = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? context.surfaceColor,
        border: widget.showBorder
            ? Border(bottom: BorderSide(color: context.borderColor))
            : null,
      ),
      child: Column(
        children: [
          // Main toolbar
          _buildMainToolbar(),

          // Quick filters (simple dropdowns)
          if (_showQuickFilters && widget.quickFilters != null)
            _buildQuickFiltersPanel(),

          // Advanced filters
          if (_showAdvancedFilters && widget.filterConfigs != null)
            _buildAdvancedFiltersPanel(),

          // Column visibility settings
          if (_showColumnSettings && widget.availableColumns != null)
            _buildColumnSettings(),
        ],
      ),
    );
  }

  Widget _buildMainToolbar() {
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(AppSizes.spacing16),
      child: Row(
        children: [
          // Title (if provided)
          if (widget.title != null) ...[
            Text(
              widget.title!,
              style: TextStyle(
                fontSize: AppSizes.fontSizeLarge,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,

                //AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: AppSizes.spacing16),
          ],

          // Search field
          Expanded(
            flex: 1,
            child: AppInputField.search(
              controller: _searchController,
              hintText: widget.searchHint,
              onChanged: widget.onSearchChanged,
              enabled: true,
              prefixIcon: const Icon(Icons.search, size: AppSizes.iconSmall),
            ),
          ),

          const SizedBox(width: AppSizes.spacing16),

          // Filter toggles
          _buildFilterToggles(),

          const Spacer(),

          // View mode selector
          _buildViewModeSelector(),

          const SizedBox(width: AppSizes.spacing16),

          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildFilterToggles() {
    return Row(
      children: [
        // Quick filters toggle
        if (widget.quickFilters != null && widget.quickFilters!.isNotEmpty)
          IconButton(
            onPressed: () {
              setState(() {
                _showQuickFilters = !_showQuickFilters;
                if (_showQuickFilters) {
                  _showAdvancedFilters = false;
                  _showColumnSettings = false;
                }
              });
            },
            icon: Icon(
              _showQuickFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
              size: AppSizes.iconMedium,
              color: _showQuickFilters
                  ? context.primaryColor
                  : context.textSecondaryColor,
            ),
            tooltip: 'Quick Filters',
          ),

        // Advanced filters toggle
        if (widget.filterConfigs != null && widget.filterConfigs!.isNotEmpty)
          IconButton(
            onPressed: () {
              setState(() {
                _showAdvancedFilters = !_showAdvancedFilters;
                if (_showAdvancedFilters) {
                  _showQuickFilters = false;
                  _showColumnSettings = false;
                }
              });
            },
            icon: Icon(
              _showAdvancedFilters ? Icons.tune : Icons.tune_outlined,
              size: AppSizes.iconMedium,
              color: _showAdvancedFilters
                  ? context.primaryColor
                  : context.textSecondaryColor,
            ),
            tooltip: 'Advanced Filters',
          ),

        // Column settings toggle (only for table view)
        if (widget.availableColumns != null &&
            _isTableView() &&
            widget.onColumnVisibilityChanged != null)
          IconButton(
            onPressed: () {
              setState(() {
                _showColumnSettings = !_showColumnSettings;
                if (_showColumnSettings) {
                  _showQuickFilters = false;
                  _showAdvancedFilters = false;
                }
              });
            },
            icon: Icon(
              _showColumnSettings
                  ? Icons.view_column
                  : Icons.view_column_outlined,
              size: AppSizes.iconMedium,
              color: _showColumnSettings
                  ? context.primaryColor
                  : context.textSecondaryColor,
            ),
            tooltip: 'Column Settings',
          ),
      ],
    );
  }

  Widget _buildViewModeSelector() {
    return Container(
      height: AppSizes.buttonHeightSmall,
      decoration: BoxDecoration(
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Row(
        children: widget.availableViewModes.map((mode) {
          final config = widget.viewModeConfigs[mode]!;
          final isSelected = widget.currentViewMode == mode;

          return Container(
            height: AppSizes.buttonHeightSmall,
            width: AppSizes.buttonHeightSmall,
            decoration: BoxDecoration(
              color: isSelected ? context.primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
            child: IconButton(
              onPressed: () => widget.onViewModeChanged(mode),
              icon: Icon(
                config.icon,
                color: isSelected
                    ? context.surfaceColor
                    : context.textSecondaryColor,
                size: AppSizes.iconMedium,
              ),
              tooltip: config.tooltip,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Custom action buttons
        if (widget.actionButtons != null)
          ...widget.actionButtons!.map(
            (button) => Padding(
              padding: const EdgeInsets.only(right: AppSizes.spacing8),
              child: IconButton(
                onPressed: button.onPressed,
                icon: Icon(button.icon, size: AppSizes.iconMedium),
                color: context.textSecondaryColor,
                tooltip: button.tooltip,
              ),
            ),
          ),

        // More actions dropdown
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'refresh':
                widget.onRefresh();
                break;
              case 'export':
                widget.onExport?.call();
                break;
              case 'import':
                widget.onImport?.call();
                break;
            }
          },
          icon: Icon(
            Icons.more_vert,
            size: AppSizes.iconMedium,
            color: context.textSecondaryColor,
          ),
          tooltip: 'More actions',
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh, size: AppSizes.iconSmall),
                  SizedBox(width: AppSizes.spacing8),
                  Text('Refresh'),
                ],
              ),
            ),
            if (widget.onExport != null)
              const PopupMenuItem<String>(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_download, size: AppSizes.iconSmall),
                    SizedBox(width: AppSizes.spacing8),
                    Text('Export'),
                  ],
                ),
              ),
            if (widget.onImport != null)
              const PopupMenuItem<String>(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.file_upload, size: AppSizes.iconSmall),
                    SizedBox(width: AppSizes.spacing8),
                    Text('Import'),
                  ],
                ),
              ),
          ],
        ),

        const SizedBox(width: AppSizes.spacing8),

        // Add button
        if (widget.onAddItem != null)
          AppButton(
            onPressed: widget.onAddItem!,
            text: widget.addButtonText,
            icon: Icon(widget.addButtonIcon, size: AppSizes.iconSmall),
            size: AppButtonSize.small,
            type: AppButtonType.primary,
          ),
      ],
    );
  }

  Widget _buildQuickFiltersPanel() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: context.surfaceVariantColor,
        border: Border(bottom: BorderSide(color: context.borderColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ...widget.quickFilters!.map(
            (filter) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: AppSizes.spacing16),
                child: _buildQuickFilter(filter),
              ),
            ),
          ),

          // Clear filters button
          TextButton.icon(
            onPressed: () {
              _searchController.clear();
              widget.onSearchChanged('');
              // Clear all quick filters
              for (final filter in widget.quickFilters!) {
                widget.onQuickFilterChanged?.call(filter.key, null);
              }
            },
            icon: const Icon(Icons.clear, size: AppSizes.iconSmall),
            label: Text('Clear Filters'),
            style: TextButton.styleFrom(
              foregroundColor: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilter(QuickFilterConfig filter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          filter.label,
          style: TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            fontWeight: FontWeight.w500,
            color: context.textSecondaryColor,
          ),
        ),
        const SizedBox(height: AppSizes.spacing4),
        SizedBox(
          height: AppSizes.inputHeight,
          child: AppSearchableDropdown<String>(
            value: filter.value,
            hintText: 'All ${filter.label}',
            items: [
              DropdownMenuItem(value: null, child: Text('All ${filter.label}')),
              ...filter.options.map(
                (option) =>
                    DropdownMenuItem(value: option, child: Text(option)),
              ),
            ],
            onChanged: (value) =>
                widget.onQuickFilterChanged?.call(filter.key, value),
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedFiltersPanel() {
    return AdvancedFilters(
      filterConfigs: widget.filterConfigs!,
      initialValues: widget.filterValues,
      onFiltersChanged: widget.onFiltersChanged!,
      onClear: () {
        // Call the clear callback to reset filter values in parent
        widget.onFiltersChanged?.call({});
      },
      startExpanded: true,
      showApplyButton: true,
      autoApply: false, // Disable auto-apply, require Apply button click
    );
  }

  Widget _buildColumnSettings() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: context.surfaceVariantColor,
        border: Border(bottom: BorderSide(color: context.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Show/Hide Columns',
            style: TextStyle(
              fontSize: AppSizes.fontSizeMedium,
              fontWeight: FontWeight.w600,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppSizes.spacing12),
          Wrap(
            spacing: AppSizes.spacing16,
            runSpacing: AppSizes.spacing8,
            children: widget.availableColumns!.map((column) {
              final isVisible = !widget.hiddenColumns!.contains(column);
              return FilterChip(
                label: Text(column),
                selected: isVisible,
                onSelected: (selected) {
                  final newHiddenColumns = List<String>.from(
                    widget.hiddenColumns!,
                  );
                  if (selected) {
                    newHiddenColumns.remove(column);
                  } else {
                    newHiddenColumns.add(column);
                  }
                  widget.onColumnVisibilityChanged!(newHiddenColumns);
                },
                selectedColor: context.primaryColor.withOpacity(0.2),
                checkmarkColor: context.primaryColor,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  bool _isTableView() {
    final config = widget.viewModeConfigs[widget.currentViewMode];
    return config?.isTableView == true;
  }
}

// Configuration classes
class ViewModeConfig {
  final IconData icon;
  final String tooltip;
  final bool isTableView;

  const ViewModeConfig({
    required this.icon,
    required this.tooltip,
    this.isTableView = false,
  });
}

class QuickFilterConfig {
  final String key;
  final String label;
  final List<String> options;
  final String? value;

  const QuickFilterConfig({
    required this.key,
    required this.label,
    required this.options,
    this.value,
  });
}

class ActionButtonConfig {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const ActionButtonConfig({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });
}

// Predefined view mode configurations for common use cases
class CommonViewModes {
  static const table = ViewModeConfig(
    icon: Icons.table_chart,
    tooltip: 'Table View',
    isTableView: true,
  );

  static const kanban = ViewModeConfig(
    icon: Icons.view_kanban,
    tooltip: 'Kanban View',
  );

  static const map = ViewModeConfig(icon: Icons.map, tooltip: 'Map View');

  static const grid = ViewModeConfig(
    icon: Icons.grid_view,
    tooltip: 'Grid View',
  );

  static const list = ViewModeConfig(icon: Icons.list, tooltip: 'List View');
}
