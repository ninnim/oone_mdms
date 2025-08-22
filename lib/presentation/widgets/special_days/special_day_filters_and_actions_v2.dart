import 'package:flutter/material.dart';
import '../../../core/constants/app_enums.dart';
import '../common/universal_filters_and_actions.dart';
import '../common/advanced_filters.dart';

class SpecialDayFiltersAndActionsV2 extends StatefulWidget {
  final Function(String) onSearchChanged;
  final Function(String?) onStatusFilterChanged;
  final Function(SpecialDayViewMode) onViewModeChanged;
  final VoidCallback onAddSpecialDay;
  final VoidCallback onRefresh;
  final SpecialDayViewMode currentViewMode;
  final VoidCallback? onExport;
  final VoidCallback? onImport;
  final String? selectedStatus;

  const SpecialDayFiltersAndActionsV2({
    super.key,
    required this.onSearchChanged,
    required this.onStatusFilterChanged,
    required this.onViewModeChanged,
    required this.onAddSpecialDay,
    required this.onRefresh,
    required this.currentViewMode,
    this.onExport,
    this.onImport,
    this.selectedStatus,
  });

  @override
  State<SpecialDayFiltersAndActionsV2> createState() =>
      _SpecialDayFiltersAndActionsV2State();
}

class _SpecialDayFiltersAndActionsV2State
    extends State<SpecialDayFiltersAndActionsV2> {
  // Internal state to track current filter values
  Map<String, dynamic> _currentFilterValues = {};

  @override
  void initState() {
    super.initState();
    _currentFilterValues = _buildFilterValues();
  }

  @override
  void didUpdateWidget(SpecialDayFiltersAndActionsV2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update internal state when external props change
    if (oldWidget.selectedStatus != widget.selectedStatus) {
      _currentFilterValues = _buildFilterValues();
    }
  }

  @override
  Widget build(BuildContext context) {
    return UniversalFiltersAndActions<SpecialDayViewMode>(
      // Basic properties
      searchHint: 'Search special days...',
      onSearchChanged: widget.onSearchChanged,
      onAddItem: widget.onAddSpecialDay,
      onRefresh: widget.onRefresh,
      addButtonText: 'Add Special Day',
      addButtonIcon: Icons.add,

      // View modes
      availableViewModes: SpecialDayViewMode.values,
      currentViewMode: widget.currentViewMode,
      onViewModeChanged: widget.onViewModeChanged,
      viewModeConfigs: const {
        SpecialDayViewMode.table: CommonViewModes.table,
        SpecialDayViewMode.kanban: CommonViewModes.kanban,
      },

      // Advanced filters only (matching Sites module)
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
        key: 'detailsCount',
        label: 'Details Count',
        options: ['No Details', 'Has Details'],
        placeholder: 'Select details filter',
        icon: Icons.event_note,
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
      'detailsCount': null,
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
      print('Special Days filters cleared');
      return;
    }

    // Handle status filter change
    if (filters.containsKey('status')) {
      widget.onStatusFilterChanged(filters['status']);
    }

    // Handle details count filter
    // You can add more handling logic here for details count filtering

    // Handle date range filter
    // You can add more handling logic here for date range filtering

    print('Special Days advanced filters applied: $filters');

    // Implement additional filtering logic here as needed
    // widget.onAdvancedFiltersChanged?.call(filters);
  }
}
