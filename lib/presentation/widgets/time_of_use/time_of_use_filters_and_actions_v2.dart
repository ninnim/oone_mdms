import 'package:flutter/material.dart';
import '../../../core/constants/app_enums.dart';
import '../common/universal_filters_and_actions.dart';
import '../common/advanced_filters.dart';

class TimeOfUseFiltersAndActionsV2 extends StatefulWidget {
  final Function(String) onSearchChanged;
  final Function(TimeOfUseViewMode?) onViewModeChanged;
  final VoidCallback onAddTimeOfUse;
  final VoidCallback onRefresh;
  final TimeOfUseViewMode currentViewMode;
  final VoidCallback? onExport;
  final VoidCallback? onImport;
  final String? selectedStatus;
  final Function(Map<String, dynamic>)? onFiltersChanged;
  final List<String>? availableColumns;
  final List<String>? hiddenColumns;
  final Function(List<String>)? onColumnVisibilityChanged;

  const TimeOfUseFiltersAndActionsV2({
    super.key,
    required this.onSearchChanged,
    required this.onViewModeChanged,
    required this.onAddTimeOfUse,
    required this.onRefresh,
    required this.currentViewMode,
    this.onExport,
    this.onImport,
    this.selectedStatus,
    this.onFiltersChanged,
    this.availableColumns,
    this.hiddenColumns,
    this.onColumnVisibilityChanged,
  });

  @override
  State<TimeOfUseFiltersAndActionsV2> createState() =>
      _TimeOfUseFiltersAndActionsV2State();
}

class _TimeOfUseFiltersAndActionsV2State
    extends State<TimeOfUseFiltersAndActionsV2> {
  Map<String, dynamic> _currentFilterValues = {};

  @override
  Widget build(BuildContext context) {
    return UniversalFiltersAndActions<TimeOfUseViewMode>(
      searchHint: 'Search time of use...',
      onSearchChanged: widget.onSearchChanged,
      onAddItem: widget.onAddTimeOfUse,
      onRefresh: widget.onRefresh,
      addButtonText: 'Add Time of Use',
      addButtonIcon: Icons.access_time,

      // View modes
      availableViewModes: TimeOfUseViewMode.values,
      currentViewMode: widget.currentViewMode,
      onViewModeChanged: widget.onViewModeChanged,
      viewModeConfigs: const {
        TimeOfUseViewMode.table: CommonViewModes.table,
        TimeOfUseViewMode.kanban: CommonViewModes.kanban,
      },

      // Advanced filters
      filterConfigs: _buildAdvancedFilterConfigs(),
      filterValues: _currentFilterValues,
      onFiltersChanged: _handleAdvancedFiltersChanged,

      // Actions
      onExport: widget.onExport,
      onImport: widget.onImport,

      // Column visibility
      availableColumns: widget.availableColumns,
      hiddenColumns: widget.hiddenColumns,
      onColumnVisibilityChanged: widget.onColumnVisibilityChanged,
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
    ];
  }

  void _handleAdvancedFiltersChanged(Map<String, dynamic> filterValues) {
    setState(() {
      _currentFilterValues = filterValues;
    });
    widget.onFiltersChanged?.call(filterValues);
  }
}
