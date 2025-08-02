import 'package:flutter/material.dart';
import '../../../core/constants/app_enums.dart';
import '../../widgets/common/universal_filters_and_actions.dart';
import '../../widgets/common/advanced_filters.dart';

class TimeBandFiltersAndActionsV2 extends StatefulWidget {
  final Function(String) onSearchChanged;
  final Function(TimeBandViewMode?) onViewModeChanged;
  final VoidCallback onAddTimeBand;
  final VoidCallback onRefresh;
  final TimeBandViewMode currentViewMode;
  final VoidCallback? onExport;
  final VoidCallback? onImport;
  final String? selectedStatus;
  final Function(Map<String, dynamic>)? onFiltersChanged;

  const TimeBandFiltersAndActionsV2({
    super.key,
    required this.onSearchChanged,
    required this.onViewModeChanged,
    required this.onAddTimeBand,
    required this.onRefresh,
    required this.currentViewMode,
    this.onExport,
    this.onImport,
    this.selectedStatus,
    this.onFiltersChanged,
  });

  @override
  State<TimeBandFiltersAndActionsV2> createState() =>
      _TimeBandFiltersAndActionsV2State();
}

class _TimeBandFiltersAndActionsV2State
    extends State<TimeBandFiltersAndActionsV2> {
  Map<String, dynamic> _currentFilterValues = {};

  @override
  Widget build(BuildContext context) {
    return UniversalFiltersAndActions<TimeBandViewMode>(
      searchHint: 'Search time bands...',
      onSearchChanged: widget.onSearchChanged,
      onAddItem: widget.onAddTimeBand,
      onRefresh: widget.onRefresh,
      addButtonText: 'Add Time Band',
      addButtonIcon: Icons.access_time,

      // View modes
      availableViewModes: TimeBandViewMode.values,
      currentViewMode: widget.currentViewMode,
      onViewModeChanged: widget.onViewModeChanged,
      viewModeConfigs: const {
        TimeBandViewMode.table: CommonViewModes.table,
        TimeBandViewMode.kanban: CommonViewModes.kanban,
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
        key: 'timeRange',
        label: 'Time Range',
        options: [
          'Morning (06:00-12:00)',
          'Afternoon (12:00-18:00)',
          'Evening (18:00-24:00)',
          'Night (00:00-06:00)',
        ],
        placeholder: 'Select time range',
        icon: Icons.access_time,
      ),
      FilterConfig.dropdown(
        key: 'hasAttributes',
        label: 'Attributes',
        options: ['With Attributes', 'Without Attributes'],
        placeholder: 'Select attribute filter',
        icon: Icons.label,
      ),
      FilterConfig.dropdown(
        key: 'dayOfWeek',
        label: 'Day of Week',
        options: [
          'Weekdays (Mon-Fri)',
          'Weekends (Sat-Sun)',
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ],
        placeholder: 'Select day',
        icon: Icons.calendar_today,
      ),
      FilterConfig.dateRange(
        key: 'dateRange',
        label: 'Date Range',
        icon: Icons.date_range,
      ),
    ];
  }

  void _handleAdvancedFiltersChanged(Map<String, dynamic> filters) {
    setState(() {
      _currentFilterValues = filters;
    });
    widget.onFiltersChanged?.call(filters);
  }
}
