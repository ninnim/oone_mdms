import 'package:flutter/material.dart';
import 'package:mdms_clone/presentation/widgets/common/app_button.dart';
import 'package:mdms_clone/presentation/widgets/common/app_input_field.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

enum DeviceViewMode { table, kanban, map }

class DeviceFiltersAndActions extends StatefulWidget {
  final Function(String) onSearchChanged;
  final Function(String?) onStatusFilterChanged;
  final Function(String?) onTypeFilterChanged;
  final Function(String?) onLinkStatusFilterChanged;
  final Function(DeviceViewMode) onViewModeChanged;
  final Function(List<String>) onColumnVisibilityChanged;
  final VoidCallback onAddDevice;
  final VoidCallback onRefresh;
  final VoidCallback? onExport;
  final VoidCallback? onImport;
  final DeviceViewMode currentViewMode;
  final List<String> availableColumns;
  final List<String> hiddenColumns;
  final String? selectedStatus;
  final String? selectedType;
  final String? selectedLinkStatus;

  const DeviceFiltersAndActions({
    super.key,
    required this.onSearchChanged,
    required this.onStatusFilterChanged,
    required this.onTypeFilterChanged,
    required this.onLinkStatusFilterChanged,
    required this.onViewModeChanged,
    required this.onColumnVisibilityChanged,
    required this.onAddDevice,
    required this.onRefresh,
    this.onExport,
    this.onImport,
    required this.currentViewMode,
    required this.availableColumns,
    required this.hiddenColumns,
    this.selectedStatus,
    this.selectedType,
    this.selectedLinkStatus,
  });

  @override
  State<DeviceFiltersAndActions> createState() =>
      _DeviceFiltersAndActionsState();
}

class _DeviceFiltersAndActionsState extends State<DeviceFiltersAndActions> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;
  bool _showColumnSettings = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main toolbar
        _buildMainToolbar(),

        // Expandable filters
        if (_showFilters) _buildFiltersPanel(),

        // Column visibility settings
        if (_showColumnSettings) _buildColumnSettings(),
      ],
    );
  }

  Widget _buildMainToolbar() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Search field
          Expanded(
            flex: 1,
            child: Container(
              alignment: Alignment.centerLeft,
              //  height: AppSizes.inputHeight,
              child: AppInputField(
                controller: _searchController,
                hintText: 'Search devices...',
                onChanged: widget.onSearchChanged,
                enabled: true,
                prefixIcon: const Icon(Icons.search, size: AppSizes.iconSmall),
              ),
              
            ),
          ),

          IconButton(
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
                if (_showFilters) _showColumnSettings = false;
              });
            },
            icon: Icon(
              _showFilters ? Icons.filter_list : Icons.filter_list_outlined,
              size: AppSizes.iconMedium,
              color: _showFilters ? AppColors.primary : AppColors.textSecondary,
            ),
            tooltip: 'Filters',
          ),
          Expanded(flex: 2, child: Container()),
          const SizedBox(width: AppSizes.spacing16),

          // View mode selector
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
            child: Row(
              children: [
                _buildViewModeButton(
                  icon: Icons.table_chart,
                  mode: DeviceViewMode.table,
                  tooltip: 'Table View',
                ),
                _buildViewModeButton(
                  icon: Icons.view_kanban,

                  mode: DeviceViewMode.kanban,
                  tooltip: 'Kanban View',
                ),
                _buildViewModeButton(
                  icon: Icons.map,
                  mode: DeviceViewMode.map,
                  tooltip: 'Map View',
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSizes.spacing16),

          // Action buttons
          Row(
            children: [
              // Filters toggle
              // IconButton(
              //   onPressed: () {
              //     setState(() {
              //       _showFilters = !_showFilters;
              //       if (_showFilters) _showColumnSettings = false;
              //     });
              //   },
              //   icon: Icon(
              //     _showFilters ? Icons.filter_list : Icons.filter_list_outlined,
              //     size: AppSizes.iconMedium,
              //     color: _showFilters
              //         ? AppColors.primary
              //         : AppColors.textSecondary,
              //   ),
              //   tooltip: 'Filters',
              // ),

              // Column settings (only for table view)
              // if (widget.currentViewMode == DeviceViewMode.table)
              //   IconButton(
              //     onPressed: () {
              //       setState(() {
              //         _showColumnSettings = !_showColumnSettings;
              //         if (_showColumnSettings) _showFilters = false;
              //       });
              //     },
              //     icon: Icon(
              //       _showColumnSettings
              //           ? Icons.view_column
              //           : Icons.view_column_outlined,
              //       color: _showColumnSettings
              //           ? AppColors.primary
              //           : AppColors.textSecondary,
              //     ),
              //     tooltip: 'Show/Hide Columns',
              //   ),

              // Refresh
              IconButton(
                onPressed: widget.onRefresh,
                icon: const Icon(Icons.refresh, size: AppSizes.iconMedium),
                color: AppColors.textSecondary,
                tooltip: 'Refresh',
              ),

              // Export
              if (widget.onExport != null)
                IconButton(
                  onPressed: widget.onExport,
                  icon: const Icon(
                    Icons.file_download,
                    size: AppSizes.iconMedium,
                  ),
                  color: AppColors.textSecondary,
                  tooltip: 'Export',
                ),

              // Import
              if (widget.onImport != null)
                IconButton(
                  onPressed: widget.onImport,
                  icon: const Icon(
                    Icons.file_upload,
                    size: AppSizes.iconMedium,
                  ),
                  color: AppColors.textSecondary,
                  tooltip: 'Import',
                ),

              const SizedBox(width: AppSizes.spacing8),

              // Add device button
              AppButton(
                onPressed: widget.onAddDevice,
                text: 'Add Device',
                icon: Icon(Icons.add, size: AppSizes.iconSmall),
                size: AppButtonSize.small,
                type: AppButtonType.primary,
              ),
              // ElevatedButton.icon(

              //   onPressed: widget.onAddDevice,
              //   icon: const Icon(Icons.add, size: AppSizes.iconSmall),
              //   label: const Text('Add Device'),
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: AppColors.primary,
              //     foregroundColor: AppColors.surface,
              //     padding: const EdgeInsets.symmetric(
              //       horizontal: AppSizes.spacing16,
              //      // vertical: AppSizes.spacing12,
              //     ),
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeButton({
    required IconData icon,
    required DeviceViewMode mode,
    required String tooltip,
  }) {
    final isSelected = widget.currentViewMode == mode;

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: IconButton(
        onPressed: () => widget.onViewModeChanged(mode),
        icon: Icon(
          icon,
          color: isSelected ? AppColors.surface : AppColors.textSecondary,
          size: AppSizes.iconMedium,
        ),
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Status filter
          Expanded(
            child: _buildFilterDropdown(
              label: 'Status',
              value: widget.selectedStatus,
              items: const ['All', 'Commissioned', 'Decommissioned', 'None'],
              onChanged: (value) =>
                  widget.onStatusFilterChanged(value == 'All' ? null : value),
            ),
          ),

          const SizedBox(width: AppSizes.spacing16),

          // Type filter
          Expanded(
            child: _buildFilterDropdown(
              label: 'Type',
              value: widget.selectedType,
              items: const ['All', 'Smart Meter', 'Sensor', 'Gateway'],
              onChanged: (value) =>
                  widget.onTypeFilterChanged(value == 'All' ? null : value),
            ),
          ),

          const SizedBox(width: AppSizes.spacing16),

          // Link Status filter
          Expanded(
            child: _buildFilterDropdown(
              label: 'Link Status',
              value: widget.selectedLinkStatus,
              items: const ['All', 'None', 'MULTIDRIVE', 'E-POWER'],
              onChanged: (value) => widget.onLinkStatusFilterChanged(
                value == 'All' ? null : value,
              ),
            ),
          ),

          const SizedBox(width: AppSizes.spacing16),

          // Clear filters
          TextButton.icon(
            onPressed: () {
              widget.onStatusFilterChanged(null);
              widget.onTypeFilterChanged(null);
              widget.onLinkStatusFilterChanged(null);
            },
            icon: const Icon(Icons.clear),
            label: const Text('Clear Filters'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSizes.spacing4),
        SizedBox(
          height: AppSizes.inputHeight,
          child: DropdownButtonFormField<String>(
            value: value ?? 'All',
            style: TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacing12,
                vertical: AppSizes.spacing8,
              ),
            ),
            items: items
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildColumnSettings() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Show/Hide Columns',
            style: TextStyle(
              fontSize: AppSizes.fontSizeMedium,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.spacing12),
          Wrap(
            spacing: AppSizes.spacing16,
            runSpacing: AppSizes.spacing8,
            children: widget.availableColumns.map((column) {
              final isVisible = !widget.hiddenColumns.contains(column);
              return FilterChip(
                label: Text(column),
                selected: isVisible,
                onSelected: (selected) {
                  final newHiddenColumns = List<String>.from(
                    widget.hiddenColumns,
                  );
                  if (selected) {
                    newHiddenColumns.remove(column);
                  } else {
                    newHiddenColumns.add(column);
                  }
                  widget.onColumnVisibilityChanged(newHiddenColumns);
                },
                selectedColor: AppColors.primary.withOpacity(0.2),
                checkmarkColor: AppColors.primary,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
