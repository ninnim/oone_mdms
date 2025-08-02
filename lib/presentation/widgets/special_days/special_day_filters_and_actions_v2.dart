import 'package:flutter/material.dart';
import '../../../core/constants/app_enums.dart';
import '../common/universal_filters_and_actions.dart';
import '../common/advanced_filters.dart';

class SpecialDayFiltersAndActionsV2 extends StatefulWidget {
  final Function(String) onSearchChanged;
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
  Map<String, dynamic> _currentFilterValues = {};

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
    ];
  }

  void _handleAdvancedFiltersChanged(Map<String, dynamic> filters) {
    setState(() {
      _currentFilterValues = filters;
    });
    // TODO: Apply filters to data
  }

  @override
  Widget build(BuildContext context) {
    return UniversalFiltersAndActions<SpecialDayViewMode>(
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

      // Advanced filters
      filterConfigs: _buildAdvancedFilterConfigs(),
      filterValues: _currentFilterValues,
      onFiltersChanged: _handleAdvancedFiltersChanged,

      // Actions
      onExport: widget.onExport,
      onImport: widget.onImport,
    );
  }
}
