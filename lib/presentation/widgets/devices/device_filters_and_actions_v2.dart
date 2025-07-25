import 'package:flutter/material.dart';
import '../common/universal_filters_and_actions.dart';
import '../common/advanced_filters.dart';

enum DeviceViewMode { table, kanban, map }

class DeviceFiltersAndActionsV2 extends StatefulWidget {
  final Function(String) onSearchChanged;
  final Function(String?) onStatusFilterChanged;
  final Function(String?) onLinkStatusFilterChanged;
  final Function(DeviceViewMode) onViewModeChanged;
  final VoidCallback onAddDevice;
  final VoidCallback onRefresh;
  final VoidCallback? onExport;
  final VoidCallback? onImport;
  final DeviceViewMode currentViewMode;
  final String? selectedStatus;
  final String? selectedLinkStatus;

  const DeviceFiltersAndActionsV2({
    super.key,
    required this.onSearchChanged,
    required this.onStatusFilterChanged,
    required this.onLinkStatusFilterChanged,
    required this.onViewModeChanged,
    required this.onAddDevice,
    required this.onRefresh,
    this.onExport,
    this.onImport,
    required this.currentViewMode,
    this.selectedStatus,
    this.selectedLinkStatus,
  });

  @override
  State<DeviceFiltersAndActionsV2> createState() =>
      _DeviceFiltersAndActionsV2State();
}

class _DeviceFiltersAndActionsV2State extends State<DeviceFiltersAndActionsV2> {
  // Internal state to track current filter values
  Map<String, dynamic> _currentFilterValues = {};

  @override
  void initState() {
    super.initState();
    _currentFilterValues = _buildFilterValues();
  }

  @override
  void didUpdateWidget(DeviceFiltersAndActionsV2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update internal state when external props change
    if (oldWidget.selectedStatus != widget.selectedStatus ||
        oldWidget.selectedLinkStatus != widget.selectedLinkStatus) {
      _currentFilterValues = _buildFilterValues();
    }
  }

  @override
  Widget build(BuildContext context) {
    return UniversalFiltersAndActions<DeviceViewMode>(
      // Basic properties
      searchHint: 'Search devices...',
      onSearchChanged: widget.onSearchChanged,
      onAddItem: widget.onAddDevice,
      onRefresh: widget.onRefresh,
      addButtonText: 'Add Device',
      addButtonIcon: Icons.add,

      // View modes
      availableViewModes: DeviceViewMode.values,
      currentViewMode: widget.currentViewMode,
      onViewModeChanged: widget.onViewModeChanged,
      viewModeConfigs: const {
        DeviceViewMode.table: CommonViewModes.table,
        DeviceViewMode.kanban: CommonViewModes.kanban,
        DeviceViewMode.map: CommonViewModes.map,
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
        options: ['Commissioned', 'Decommissioned', 'None'],
        placeholder: 'Select status',
        icon: Icons.check_circle,
      ),
      FilterConfig.dropdown(
        key: 'linkStatus',
        label: 'Link Status',
        options: ['None', 'MULTIDRIVE', 'E-POWER'],
        placeholder: 'Select link status',
        icon: Icons.link,
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
    return {
      'status': widget.selectedStatus,
      'linkStatus': widget.selectedLinkStatus,
      'dateRange': null,
    };
  }

  void _handleAdvancedFiltersChanged(Map<String, dynamic> filters) {
    setState(() {
      _currentFilterValues = Map.from(filters);
    });

    // Handle clear all filters (empty map)
    if (filters.isEmpty) {
      widget.onStatusFilterChanged(null);
      widget.onLinkStatusFilterChanged(null);
      print('Device filters cleared');
      return;
    }

    // Handle status filter change
    if (filters.containsKey('status')) {
      widget.onStatusFilterChanged(filters['status']);
    }

    // Handle link status filter change
    if (filters.containsKey('linkStatus')) {
      widget.onLinkStatusFilterChanged(filters['linkStatus']);
    }

    // Handle date range filter
    // You can add more handling logic here for date range filtering
    print('Device advanced filters applied: $filters');

    // Implement your filtering logic here
    // widget.onAdvancedFiltersChanged?.call(filters);
  }
}
