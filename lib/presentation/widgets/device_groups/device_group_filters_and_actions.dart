import 'package:flutter/material.dart';
import 'package:mdms_clone/presentation/widgets/common/app_button.dart';
import 'package:mdms_clone/presentation/widgets/common/app_input_field.dart';
import 'package:mdms_clone/presentation/widgets/common/app_dropdown_field.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_enums.dart';

class DeviceGroupFiltersAndActions extends StatefulWidget {
  final Function(String) onSearchChanged;
  final Function(String?) onStatusFilterChanged;
  final Function(DeviceGroupViewMode) onViewModeChanged;
  final VoidCallback onAddDeviceGroup;
  final VoidCallback onRefresh;
  final VoidCallback? onExport;
  final VoidCallback? onImport;
  final DeviceGroupViewMode currentViewMode;
  final String? selectedStatus;
  final List<String> availableColumns;
  final List<String> hiddenColumns;
  final Function(List<String>) onColumnVisibilityChanged;

  const DeviceGroupFiltersAndActions({
    super.key,
    required this.onSearchChanged,
    required this.onStatusFilterChanged,
    required this.onViewModeChanged,
    required this.onAddDeviceGroup,
    required this.onRefresh,
    this.onExport,
    this.onImport,
    required this.currentViewMode,
    this.selectedStatus,
    required this.availableColumns,
    required this.hiddenColumns,
    required this.onColumnVisibilityChanged,
  });

  @override
  State<DeviceGroupFiltersAndActions> createState() =>
      _DeviceGroupFiltersAndActionsState();
}

class _DeviceGroupFiltersAndActionsState
    extends State<DeviceGroupFiltersAndActions> {
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
        // Top bar with search, view modes, and actions
        Container(
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
                  child: AppInputField(
                    controller: _searchController,
                    onChanged: widget.onSearchChanged,
                    hintText: 'Search device groups...',
                    prefixIcon: const Icon(
                      Icons.search,
                      size: AppSizes.iconMedium,
                    ),
                    enabled: true,
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
                  color: _showFilters
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                tooltip: 'Filters',
              ),
              const SizedBox(width: AppSizes.spacing16),
              const Spacer(),
              // View mode selector
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
                child: Row(
                  children: [
                    _buildViewModeButton(
                      icon: Icons.table_chart,
                      mode: DeviceGroupViewMode.table,
                      tooltip: 'Table View',
                    ),
                    _buildViewModeButton(
                      icon: Icons.view_kanban,
                      mode: DeviceGroupViewMode.kanban,
                      tooltip: 'Kanban View',
                    ),
                  ],
                ),
              ),

              ///   const SizedBox(width: AppSizes.spacing16),

              // Action buttons
              Row(
                children: [
                  // Filters toggle

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
                    icon: const Icon(
                      Icons.more_vert,
                      size: AppSizes.iconMedium,
                      color: AppColors.textSecondary,
                    ),
                    tooltip: 'More actions',
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
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
                                  Icon(
                                    Icons.file_download,
                                    size: AppSizes.iconSmall,
                                  ),
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
                                  Icon(
                                    Icons.file_upload,
                                    size: AppSizes.iconSmall,
                                  ),
                                  SizedBox(width: AppSizes.spacing8),
                                  Text('Import'),
                                ],
                              ),
                            ),
                        ],
                  ),

                  const SizedBox(width: AppSizes.spacing8),

                  // Add device group button
                  AppButton(
                    onPressed: widget.onAddDeviceGroup,
                    text: 'Add Device Group',
                    icon: const Icon(Icons.add, size: AppSizes.iconSmall),
                    size: AppButtonSize.small,
                    type: AppButtonType.primary,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Filters panel (collapsible)
        if (_showFilters) _buildFiltersPanel(),

        // Column visibility settings
        if (_showColumnSettings) _buildColumnSettings(),
      ],
    );
  }

  Widget _buildViewModeButton({
    required IconData icon,
    required DeviceGroupViewMode mode,
    required String tooltip,
  }) {
    final isSelected = widget.currentViewMode == mode;

    return Container(
      width: AppSizes.buttonHeightSmall,
      height: AppSizes.buttonHeightSmall,
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
        children: [
          // Status filter
          SizedBox(
            width: 200,
            height: AppSizes.inputHeight,
            child: AppSearchableDropdown<String>(
              label: 'Status',
              hintText: 'All Statuses',
              value: widget.selectedStatus,
              items: const [
                DropdownMenuItem(value: null, child: Text('All Statuses')),
                DropdownMenuItem(value: 'Active', child: Text('Active')),
                DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
              ],
              onChanged: widget.onStatusFilterChanged,
            ),
          ),

          const SizedBox(width: AppSizes.spacing16),

          // Clear filters button
          TextButton.icon(
            onPressed: () {
              _searchController.clear();
              widget.onSearchChanged('');
              widget.onStatusFilterChanged(null);
            },
            icon: const Icon(Icons.clear, size: AppSizes.iconSmall),
            label: Text('Clear Filters'),
          ),
        ],
      ),
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
          Text(
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





