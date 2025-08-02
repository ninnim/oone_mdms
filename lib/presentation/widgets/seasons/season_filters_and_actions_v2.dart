import 'package:flutter/material.dart';
import '../../../core/constants/app_enums.dart';
import '../common/universal_filters_and_actions.dart';
import '../common/advanced_filters.dart';

class SeasonFiltersAndActionsV2 extends StatefulWidget {
  final Function(String) onSearchChanged;
  final Function(String?) onStatusFilterChanged;
  final Function(SeasonViewMode) onViewModeChanged;
  final VoidCallback onAddSeason;
  final VoidCallback onRefresh;
  final VoidCallback? onExport;
  final VoidCallback? onImport;
  final SeasonViewMode currentViewMode;
  final String? selectedStatus;

  const SeasonFiltersAndActionsV2({
    super.key,
    required this.onSearchChanged,
    required this.onStatusFilterChanged,
    required this.onViewModeChanged,
    required this.onAddSeason,
    required this.onRefresh,
    this.onExport,
    this.onImport,
    required this.currentViewMode,
    this.selectedStatus,
  });

  @override
  State<SeasonFiltersAndActionsV2> createState() =>
      _SeasonFiltersAndActionsV2State();
}

class _SeasonFiltersAndActionsV2State extends State<SeasonFiltersAndActionsV2> {
  // Internal state to track current filter values
  Map<String, dynamic> _currentFilterValues = {};

  @override
  void initState() {
    super.initState();
    _currentFilterValues = _buildFilterValues();
  }

  @override
  void didUpdateWidget(SeasonFiltersAndActionsV2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update internal state when external props change
    if (oldWidget.selectedStatus != widget.selectedStatus) {
      _currentFilterValues = _buildFilterValues();
    }
  }

  @override
  Widget build(BuildContext context) {
    return UniversalFiltersAndActions<SeasonViewMode>(
      // Basic properties
      searchHint: 'Search seasons...',
      onSearchChanged: widget.onSearchChanged,
      onAddItem: widget.onAddSeason,
      onRefresh: widget.onRefresh,
      addButtonText: 'Add Season',
      addButtonIcon: Icons.add,

      // View modes
      availableViewModes: SeasonViewMode.values,
      currentViewMode: widget.currentViewMode,
      onViewModeChanged: widget.onViewModeChanged,
      viewModeConfigs: const {
        SeasonViewMode.table: CommonViewModes.table,
        SeasonViewMode.kanban: CommonViewModes.kanban,
      },

      // Advanced filters
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
        key: 'monthCount',
        label: 'Month Count',
        options: ['1-3 months', '4-6 months', '7-9 months', '10-12 months'],
        placeholder: 'Select month range',
        icon: Icons.calendar_month,
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
      'monthCount': null,
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
      print('Season filters cleared');
      return;
    }

    // Handle status filter change
    if (filters.containsKey('status')) {
      widget.onStatusFilterChanged(filters['status']);
    }

    // Handle month count filter
    if (filters.containsKey('monthCount')) {
      // You can add specific handling for month count filtering
      print('Month count filter: ${filters['monthCount']}');
    }

    // Handle date range filter
    if (filters.containsKey('dateRange')) {
      // You can add date range filtering logic here
      print('Date range filter: ${filters['dateRange']}');
    }

    print('Season advanced filters applied: $filters');
  }
}
