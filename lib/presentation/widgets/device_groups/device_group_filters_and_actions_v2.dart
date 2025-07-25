import 'package:flutter/material.dart';
import '../../../core/constants/app_enums.dart';
import '../common/universal_filters_and_actions.dart';
import '../common/advanced_filters.dart';

class DeviceGroupFiltersAndActionsV2 extends StatefulWidget {
  final Function(String) onSearchChanged;
  final Function(String?) onStatusFilterChanged;
  final Function(DeviceGroupViewMode) onViewModeChanged;
  final VoidCallback onAddDeviceGroup;
  final VoidCallback onRefresh;
  final VoidCallback? onExport;
  final VoidCallback? onImport;
  final DeviceGroupViewMode currentViewMode;
  final String? selectedStatus;

  const DeviceGroupFiltersAndActionsV2({
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
  });

  @override
  State<DeviceGroupFiltersAndActionsV2> createState() =>
      _DeviceGroupFiltersAndActionsV2State();
}

class _DeviceGroupFiltersAndActionsV2State
    extends State<DeviceGroupFiltersAndActionsV2> {
  // Internal state to track current filter values
  Map<String, dynamic> _currentFilterValues = {};

  @override
  void initState() {
    super.initState();
    _currentFilterValues = _buildFilterValues();
  }

  @override
  void didUpdateWidget(DeviceGroupFiltersAndActionsV2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update internal state when external props change
    if (oldWidget.selectedStatus != widget.selectedStatus) {
      _currentFilterValues = _buildFilterValues();
    }
  }

  @override
  Widget build(BuildContext context) {
    return UniversalFiltersAndActions<DeviceGroupViewMode>(
      // Basic properties
      searchHint: 'Search device groups...',
      onSearchChanged: widget.onSearchChanged,
      onAddItem: widget.onAddDeviceGroup,
      onRefresh: widget.onRefresh,
      addButtonText: 'Add Device Group',
      addButtonIcon: Icons.add,

      // View modes
      availableViewModes: DeviceGroupViewMode.values,
      currentViewMode: widget.currentViewMode,
      onViewModeChanged: widget.onViewModeChanged,
      viewModeConfigs: const {
        DeviceGroupViewMode.table: CommonViewModes.table,
        DeviceGroupViewMode.kanban: CommonViewModes.kanban,
      },

      // Advanced filters only (removed quick filters)
      filterConfigs: _buildAdvancedFilterConfigs(),
      filterValues: _currentFilterValues,
      onFiltersChanged: _handleAdvancedFiltersChanged,

      // Actions
      onExport: widget.onExport,
      onImport: widget.onImport,

      // Removed column management
    );
  }

  List<FilterConfig> _buildAdvancedFilterConfigs() {
    return [
      FilterConfig.dropdown(
        key: 'status',
        label: 'Status',
        options: ['Active', 'Inactive'],
        placeholder: 'Select status',
        icon: Icons.check_circle,
      ),
      FilterConfig.dateRange(
        key: 'dateRange',
        label: 'Date Range',
        placeholder: 'Select date range',
        icon: Icons.date_range,
      ),
    ];
  }

  Map<String, dynamic> _buildFilterValues() {
    return {'status': widget.selectedStatus, 'dateRange': null};
  }

  void _handleAdvancedFiltersChanged(Map<String, dynamic> filters) {
    setState(() {
      _currentFilterValues = Map.from(filters);
    });

    // Handle clear all filters (empty map)
    if (filters.isEmpty) {
      widget.onStatusFilterChanged(null);
      print('Device Group filters cleared');
      return;
    }

    // Handle status filter change
    if (filters.containsKey('status')) {
      widget.onStatusFilterChanged(filters['status']);
    }

    // Handle date range filter
    // You can add more handling logic here for date range filtering
    print('Device Group advanced filters applied: $filters');

    // Implement your filtering logic here
    // widget.onAdvancedFiltersChanged?.call(filters);
  }
}
