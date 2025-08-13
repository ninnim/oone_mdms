import 'package:flutter/material.dart';
import '../../../core/constants/app_enums.dart';
import '../common/universal_filters_and_actions.dart';
import '../common/advanced_filters.dart';

class ScheduleFiltersAndActionsV2 extends StatefulWidget {
  final Function(String) onSearchChanged;
  final Function(String?) onStatusFilterChanged;
  final Function(String?) onTargetTypeFilterChanged;
  final Function(ScheduleViewMode) onViewModeChanged;
  final VoidCallback onAddSchedule;
  final VoidCallback onRefresh;
  final VoidCallback? onExport;
  final VoidCallback? onImport;
  final ScheduleViewMode currentViewMode;
  final String? selectedStatus;
  final String? selectedTargetType;

  const ScheduleFiltersAndActionsV2({
    super.key,
    required this.onSearchChanged,
    required this.onStatusFilterChanged,
    required this.onTargetTypeFilterChanged,
    required this.onViewModeChanged,
    required this.onAddSchedule,
    required this.onRefresh,
    this.onExport,
    this.onImport,
    required this.currentViewMode,
    this.selectedStatus,
    this.selectedTargetType,
  });

  @override
  State<ScheduleFiltersAndActionsV2> createState() =>
      _ScheduleFiltersAndActionsV2State();
}

class _ScheduleFiltersAndActionsV2State
    extends State<ScheduleFiltersAndActionsV2> {
  // Internal state to track current filter values
  Map<String, dynamic> _currentFilterValues = {};

  @override
  void initState() {
    super.initState();
    _currentFilterValues = _buildFilterValues();
  }

  @override
  void didUpdateWidget(ScheduleFiltersAndActionsV2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update internal state when external props change
    if (oldWidget.selectedStatus != widget.selectedStatus ||
        oldWidget.selectedTargetType != widget.selectedTargetType) {
      _currentFilterValues = _buildFilterValues();
    }
  }

  @override
  Widget build(BuildContext context) {
    return UniversalFiltersAndActions<ScheduleViewMode>(
      // Basic properties
      searchHint: 'Search schedules...',
      onSearchChanged: widget.onSearchChanged,
      onAddItem: widget.onAddSchedule,
      onRefresh: widget.onRefresh,
      addButtonText: 'Add Schedule',
      addButtonIcon: Icons.add,

      // View modes
      availableViewModes: ScheduleViewMode.values,
      currentViewMode: widget.currentViewMode,
      onViewModeChanged: widget.onViewModeChanged,
      viewModeConfigs: const {
        ScheduleViewMode.table: CommonViewModes.table,
        ScheduleViewMode.kanban: CommonViewModes.kanban,
      },

      // Advanced filters only (removed quick filters)
      filterConfigs: _buildAdvancedFilterConfigs(),
      filterValues: _currentFilterValues,
      onFiltersChanged: _handleAdvancedFiltersChanged,

      // Actions
      onExport: widget.onExport,
      onImport: widget.onImport,
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
      FilterConfig.dropdown(
        key: 'targetType',
        label: 'Target Type',
        options: ['Device', 'DeviceGroup'],
        placeholder: 'Select target type',
        icon: Icons.device_hub,
      ),
      FilterConfig.dropdown(
        key: 'interval',
        label: 'Interval',
        options: ['Daily', 'Weekly', 'Monthly', 'Yearly'],
        placeholder: 'Select interval',
        icon: Icons.schedule,
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
      'targetType': widget.selectedTargetType,
      'interval': null,
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
      widget.onTargetTypeFilterChanged(null);
      print('Schedule filters cleared');
      return;
    }

    // Handle status filter change
    if (filters.containsKey('status')) {
      widget.onStatusFilterChanged(filters['status']);
    }

    // Handle target type filter change
    if (filters.containsKey('targetType')) {
      widget.onTargetTypeFilterChanged(filters['targetType']);
    }

    // Handle interval and date range filters
    // You can add more handling logic here for additional filtering
    print('Schedule advanced filters applied: $filters');
  }
}
