import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../widgets/common/universal_filters_and_actions.dart';
import '../widgets/common/advanced_filters.dart';

// Example: How to use the new advanced filters in any screen
class ExampleScreenWithAdvancedFilters extends StatefulWidget {
  const ExampleScreenWithAdvancedFilters({super.key});

  @override
  State<ExampleScreenWithAdvancedFilters> createState() =>
      _ExampleScreenWithAdvancedFiltersState();
}

enum ExampleViewMode { table, kanban, grid }

class _ExampleScreenWithAdvancedFiltersState
    extends State<ExampleScreenWithAdvancedFilters> {
  // State variables
  ExampleViewMode _currentViewMode = ExampleViewMode.table;
  String _searchQuery = '';
  Map<String, dynamic> _filterValues = {};
  List<String> _hiddenColumns = [];

  // Quick filter state
  String? _selectedStatus;
  String? _selectedCategory;

  // Mock data
  final List<String> _availableColumns = [
    'Name',
    'Status',
    'Category',
    'Date Created',
    'Last Updated',
    'Actions',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Universal filters toolbar
          UniversalFiltersAndActions<ExampleViewMode>(
            // Basic search and actions
            searchHint: 'Search items...',
            onSearchChanged: _handleSearchChanged,
            onAddItem: _handleAddItem,
            onRefresh: _handleRefresh,
            addButtonText: 'Add Item',
            addButtonIcon: Icons.add,

            // View mode configuration
            availableViewModes: ExampleViewMode.values,
            currentViewMode: _currentViewMode,
            onViewModeChanged: _handleViewModeChanged,
            viewModeConfigs: const {
              ExampleViewMode.table: CommonViewModes.table,
              ExampleViewMode.kanban: CommonViewModes.kanban,
              ExampleViewMode.grid: CommonViewModes.grid,
            },

            // Quick filters for common filtering needs
            quickFilters: [
              QuickFilterConfig(
                key: 'status',
                label: 'Status',
                options: ['Active', 'Inactive', 'Pending'],
                value: _selectedStatus,
              ),
              QuickFilterConfig(
                key: 'category',
                label: 'Category',
                options: ['Type A', 'Type B', 'Type C'],
                value: _selectedCategory,
              ),
            ],
            onQuickFilterChanged: _handleQuickFilterChanged,

            // Advanced filters configuration
            filterConfigs: _buildAdvancedFilterConfigs(),
            filterValues: _filterValues,
            onFiltersChanged: _handleAdvancedFiltersChanged,

            // Additional actions
            actionButtons: [
              ActionButtonConfig(
                icon: Icons.analytics,
                tooltip: 'Analytics',
                onPressed: _showAnalytics,
              ),
              ActionButtonConfig(
                icon: Icons.settings,
                tooltip: 'Settings',
                onPressed: _showSettings,
              ),
            ],
            onExport: _handleExport,
            onImport: _handleImport,

            // Column management (for table view)
            availableColumns: _availableColumns,
            hiddenColumns: _hiddenColumns,
            onColumnVisibilityChanged: _handleColumnVisibilityChanged,

            // Optional styling
            title: 'Example Items',
            backgroundColor: AppColors.surface,
          ),

          // Content area - your existing content goes here
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  // Advanced filter configuration
  List<FilterConfig> _buildAdvancedFilterConfigs() {
    return [
      // Text filter example
      FilterConfig.text(
        key: 'name',
        label: 'Item Name',
        placeholder: 'Enter item name',
        icon: Icons.label,
        onChanged: (value) => print('Name filter changed: $value'),
      ),

      // Number filter example
      FilterConfig.number(
        key: 'price',
        label: 'Price',
        placeholder: 'Enter maximum price',
        icon: Icons.attach_money,
        width: 150,
      ),

      // Dropdown filter example
      FilterConfig.dropdown(
        key: 'priority',
        label: 'Priority',
        options: ['Low', 'Medium', 'High', 'Critical'],
        placeholder: 'Select priority',
        icon: Icons.priority_high,
      ),

      // Searchable dropdown example
      FilterConfig.searchableDropdown(
        key: 'assignee',
        label: 'Assignee',
        options: [
          'John Doe',
          'Jane Smith',
          'Bob Johnson',
          'Alice Brown',
          'Charlie Wilson',
          'Diana Prince',
          'Edward Norton',
        ],
        placeholder: 'Select assignee',
        icon: Icons.person,
        onSearchChanged: (query) {
          // You can implement dynamic loading here
          print('Searching assignees: $query');
        },
      ),

      // Multi-select filter example
      FilterConfig.multiSelect(
        key: 'tags',
        label: 'Tags',
        options: ['Important', 'Urgent', 'Bug', 'Feature', 'Documentation'],
        width: 220,
      ),

      // Date range filter example
      FilterConfig.dateRange(
        key: 'createdDateRange',
        label: 'Created Date Range',
        placeholder: 'Select date range',
        icon: Icons.date_range,
      ),

      // Single date filter example
      FilterConfig.datePicker(
        key: 'dueDate',
        label: 'Due Date',
        placeholder: 'Select due date',
        icon: Icons.event,
      ),

      // Slider filter example
      FilterConfig.slider(
        key: 'progress',
        label: 'Progress (%)',
        min: 0,
        max: 100,
        divisions: 10,
        defaultValue: 50,
        width: 200,
      ),

      // Toggle filter example
      FilterConfig.toggle(
        key: 'isCompleted',
        label: 'Completed Only',
        description: 'Show only completed items',
        defaultValue: false,
        width: 180,
      ),
    ];
  }

  // Event handlers
  void _handleSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _handleViewModeChanged(ExampleViewMode mode) {
    setState(() {
      _currentViewMode = mode;
    });
  }

  void _handleQuickFilterChanged(String key, dynamic value) {
    setState(() {
      switch (key) {
        case 'status':
          _selectedStatus = value;
          break;
        case 'category':
          _selectedCategory = value;
          break;
      }
    });
    _applyFilters();
  }

  void _handleAdvancedFiltersChanged(Map<String, dynamic> filters) {
    setState(() {
      _filterValues = Map.from(filters);
    });
    _applyFilters();
  }

  void _handleColumnVisibilityChanged(List<String> hiddenColumns) {
    setState(() {
      _hiddenColumns = hiddenColumns;
    });
  }

  void _handleAddItem() {
    // Show add item dialog or navigate to add page
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Item'),
        content: const Text('This would open the add item dialog.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleRefresh() {
    // Refresh your data
    print('Refreshing data...');
    // Example: _loadData();
  }

  void _handleExport() {
    // Export functionality
    print('Exporting data...');
  }

  void _handleImport() {
    // Import functionality
    print('Importing data...');
  }

  void _showAnalytics() {
    print('Showing analytics...');
  }

  void _showSettings() {
    print('Showing settings...');
  }

  // Apply all active filters
  void _applyFilters() {
    // Combine all filter sources
    final allFilters = <String, dynamic>{
      'search': _searchQuery.isNotEmpty ? _searchQuery : null,
      'status': _selectedStatus,
      'category': _selectedCategory,
      ..._filterValues,
    };

    // Remove null values
    allFilters.removeWhere((key, value) => value == null);

    print('Applying filters: $allFilters');

    // Apply to your data source
    // Example:
    // _dataService.getData(filters: allFilters);
    // or
    // _filterData(allFilters);
  }

  // Content builder based on current view mode
  Widget _buildContent() {
    switch (_currentViewMode) {
      case ExampleViewMode.table:
        return _buildTableView();
      case ExampleViewMode.kanban:
        return _buildKanbanView();
      case ExampleViewMode.grid:
        return _buildGridView();
    }
  }

  Widget _buildTableView() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: Column(
        children: [
          Text(
            'Table View - Search: "$_searchQuery"',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text('Active Filters: ${_getActiveFiltersDescription()}'),
          const SizedBox(height: 16),
          if (_hiddenColumns.isNotEmpty)
            Text('Hidden Columns: ${_hiddenColumns.join(", ")}'),
          const Expanded(
            child: Center(child: Text('Your table content goes here')),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanView() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: Column(
        children: [
          Text(
            'Kanban View - Search: "$_searchQuery"',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text('Active Filters: ${_getActiveFiltersDescription()}'),
          const Expanded(
            child: Center(child: Text('Your kanban content goes here')),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: Column(
        children: [
          Text(
            'Grid View - Search: "$_searchQuery"',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text('Active Filters: ${_getActiveFiltersDescription()}'),
          const Expanded(
            child: Center(child: Text('Your grid content goes here')),
          ),
        ],
      ),
    );
  }

  String _getActiveFiltersDescription() {
    final activeFilters = <String>[];

    if (_searchQuery.isNotEmpty) activeFilters.add('Search');
    if (_selectedStatus != null) activeFilters.add('Status');
    if (_selectedCategory != null) activeFilters.add('Category');

    // Count advanced filters
    final advancedCount = _filterValues.values.where((v) => v != null).length;
    if (advancedCount > 0) activeFilters.add('$advancedCount Advanced');

    return activeFilters.isEmpty ? 'None' : activeFilters.join(', ');
  }
}
