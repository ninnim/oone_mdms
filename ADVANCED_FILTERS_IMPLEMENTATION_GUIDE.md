# Advanced Filters Implementation - Complete Guide

## Overview

This document provides a comprehensive guide for the new **Advanced Filters System** implemented in the MDMS Clone project. The system provides a dynamic, reusable, and consistent filtering experience across all screens in the application.

## Key Components

### 1. `AdvancedFilters` Widget
**Location**: `lib/presentation/widgets/common/advanced_filters.dart`

A comprehensive filtering widget that supports multiple filter types:
- **Text filters**: Free text input with debouncing
- **Number filters**: Numeric input with validation
- **Dropdown filters**: Single selection from predefined options
- **Searchable dropdown filters**: Dropdown with search capability
- **Multi-select filters**: Multiple option selection with checkboxes
- **Date range filters**: Date range picker
- **Date picker filters**: Single date selection
- **Toggle filters**: Boolean on/off switches
- **Slider filters**: Range slider for numeric values

### 2. `UniversalFiltersAndActions` Widget
**Location**: `lib/presentation/widgets/common/universal_filters_and_actions.dart`

A universal toolbar that combines:
- Search functionality
- View mode switching (table, kanban, map, etc.)
- Quick filters (simple dropdowns)
- Advanced filters panel
- Action buttons (add, refresh, export, import)
- Column visibility management

## Features

### 🎯 Dynamic Configuration
- Filters are configured using `FilterConfig` objects
- Each filter type has factory constructors for easy setup
- Supports custom validation, callbacks, and styling

### 🔄 Auto-Apply & Debouncing
- Filters can auto-apply changes with configurable debouncing
- Manual apply mode with explicit "Apply Filters" button
- Real-time feedback with active filter indicators

### 💾 State Management
- Maintains filter state across widget rebuilds
- Supports default values and initialization
- Easy integration with existing state management

### 🎨 Consistent UI
- Uses existing reusable widgets (`AppInputField`, `AppSearchableDropdown`)
- Follows project design system (colors, spacing, typography)
- Responsive layout with configurable field widths

### 🔧 Extensible
- Easy to add new filter types
- Supports custom callbacks for each filter
- Configurable styling and behavior

## Usage Examples

### Basic Advanced Filters

```dart
AdvancedFilters(
  filterConfigs: [
    FilterConfig.text(
      key: 'name',
      label: 'Name',
      placeholder: 'Enter name',
      icon: Icons.person,
    ),
    FilterConfig.dropdown(
      key: 'status',
      label: 'Status',
      options: ['Active', 'Inactive', 'Pending'],
    ),
    FilterConfig.dateRange(
      key: 'dateRange',
      label: 'Date Range',
    ),
  ],
  initialValues: {},
  onFiltersChanged: (filters) {
    // Handle filter changes
    print('Filters: $filters');
  },
)
```

### Universal Filters with View Modes

```dart
UniversalFiltersAndActions<MyViewMode>(
  searchHint: 'Search items...',
  onSearchChanged: (query) => _handleSearch(query),
  addButtonText: 'Add Item',
  onAddItem: () => _showAddDialog(),
  onRefresh: () => _refreshData(),
  
  // View modes
  availableViewModes: MyViewMode.values,
  currentViewMode: _currentViewMode,
  onViewModeChanged: (mode) => setState(() => _currentViewMode = mode),
  viewModeConfigs: {
    MyViewMode.table: CommonViewModes.table,
    MyViewMode.kanban: CommonViewModes.kanban,
  },
  
  // Quick filters
  quickFilters: [
    QuickFilterConfig(
      key: 'status',
      label: 'Status',
      options: ['All', 'Active', 'Inactive'],
    ),
  ],
  onQuickFilterChanged: (key, value) => _handleQuickFilter(key, value),
  
  // Advanced filters
  filterConfigs: _buildFilterConfigs(),
  filterValues: _filterValues,
  onFiltersChanged: (filters) => _applyFilters(filters),
)
```

### Filter Configuration Examples

#### Text Filter with Icon
```dart
FilterConfig.text(
  key: 'serialNumber',
  label: 'Serial Number',
  placeholder: 'Enter serial number',
  icon: Icons.qr_code,
  required: true,
  onChanged: (value) => print('Serial: $value'),
)
```

#### Searchable Dropdown
```dart
FilterConfig.searchableDropdown(
  key: 'manufacturer',
  label: 'Manufacturer',
  options: ['Siemens', 'Schneider', 'ABB'],
  placeholder: 'Select manufacturer',
  icon: Icons.business,
  onSearchChanged: (query) => _searchManufacturers(query),
)
```

#### Multi-Select with Custom Width
```dart
FilterConfig.multiSelect(
  key: 'features',
  label: 'Features',
  options: ['Remote Control', 'Data Logging', 'GPS'],
  width: 250,
)
```

#### Slider Filter
```dart
FilterConfig.slider(
  key: 'batteryLevel',
  label: 'Battery Level (%)',
  min: 0,
  max: 100,
  divisions: 10,
  defaultValue: 50,
)
```

#### Toggle with Description
```dart
FilterConfig.toggle(
  key: 'isActive',
  label: 'Active Only',
  description: 'Show only active devices',
  defaultValue: false,
)
```

## Implementation in Existing Screens

### Devices Screen Migration

**Before** (using old `DeviceFiltersAndActions`):
```dart
DeviceFiltersAndActions(
  onSearchChanged: _handleSearch,
  onStatusFilterChanged: _handleStatusFilter,
  // ... many individual callbacks
)
```

**After** (using new `UniversalFiltersAndActions`):
```dart
UniversalFiltersAndActions<DeviceViewMode>(
  searchHint: 'Search devices...',
  onSearchChanged: _handleSearch,
  addButtonText: 'Add Device',
  
  // All filtering logic consolidated
  quickFilters: _buildQuickFilters(),
  filterConfigs: _buildAdvancedFilters(),
  onFiltersChanged: _applyAllFilters,
)
```

### Benefits of Migration

1. **Reduced Code Duplication**: Single widget handles all filter types
2. **Consistent UX**: Same filtering experience across all screens
3. **Enhanced Functionality**: More filter types and better user experience
4. **Easier Maintenance**: Centralized filter logic
5. **Better Performance**: Optimized debouncing and state management

## Advanced Configuration

### Custom Filter Types

You can extend the system by adding new filter types:

```dart
// 1. Add to FilterType enum
enum FilterType { 
  // existing types...
  customRange,
}

// 2. Add factory constructor
factory FilterConfig.customRange({
  required String key,
  required String label,
  // custom parameters
}) {
  return FilterConfig(
    key: key,
    label: label,
    type: FilterType.customRange,
    // ...
  );
}

// 3. Add builder method in AdvancedFilters
Widget _buildCustomRangeFilter(FilterConfig config) {
  // Custom implementation
}
```

### Integration with API Filters

```dart
void _applyFilters(Map<String, dynamic> filters) {
  // Convert UI filters to API format
  final apiFilters = _convertToApiFormat(filters);
  
  // Apply to your service/repository
  _deviceService.getDevices(
    filters: apiFilters,
    page: _currentPage,
    limit: _itemsPerPage,
  );
}

Map<String, dynamic> _convertToApiFormat(Map<String, dynamic> uiFilters) {
  final apiFilters = <String, dynamic>{};
  
  // Convert date ranges
  if (uiFilters['dateRange'] != null) {
    final range = uiFilters['dateRange'] as DateTimeRange;
    apiFilters['startDate'] = range.start.toIso8601String();
    apiFilters['endDate'] = range.end.toIso8601String();
  }
  
  // Convert multi-select to array
  if (uiFilters['features'] != null) {
    apiFilters['features'] = (uiFilters['features'] as List<String>).join(',');
  }
  
  return apiFilters;
}
```

## Performance Considerations

### Debouncing
- Text inputs are debounced by 500ms by default
- Configurable per filter: `debounceDelay: Duration(milliseconds: 300)`
- Auto-apply mode uses debouncing to prevent excessive API calls

### Memory Management
- Text controllers are properly disposed
- Timers are cancelled on widget disposal
- Overlay entries are cleaned up

### Optimization Tips
1. Use `autoApply: true` for real-time filtering
2. Set appropriate debounce delays based on data size
3. Consider pagination with filters for large datasets
4. Cache filter configurations to avoid rebuilding

## Migration Guide

### Step 1: Update Dependencies
Add the new filter widgets to your screen imports:
```dart
import '../common/universal_filters_and_actions.dart';
import '../common/advanced_filters.dart';
```

### Step 2: Replace Existing Filter Widgets
```dart
// Replace this:
DeviceFiltersAndActions(...)

// With this:
UniversalFiltersAndActions<DeviceViewMode>(...)
```

### Step 3: Configure Filters
```dart
List<FilterConfig> _buildFilterConfigs() {
  return [
    // Define your filters
  ];
}
```

### Step 4: Handle Filter Changes
```dart
void _handleFiltersChanged(Map<String, dynamic> filters) {
  // Apply filters to your data source
}
```

### Step 5: Test and Validate
- Verify all filter types work correctly
- Test with your actual data
- Ensure performance is acceptable

## Best Practices

### 1. Filter Configuration
- Use factory constructors for type safety
- Set appropriate default values
- Add icons for better UX
- Use descriptive labels and placeholders

### 2. State Management
- Keep filter state in parent widget
- Use `initState` to set initial values
- Handle filter persistence if needed

### 3. Performance
- Use debouncing for text inputs
- Implement pagination with filters
- Consider caching expensive filter operations

### 4. UX Guidelines
- Group related filters logically
- Use appropriate field widths
- Provide clear filter feedback
- Include reset/clear functionality

## Troubleshooting

### Common Issues

**1. Filters not applying**
- Check that `onFiltersChanged` callback is implemented
- Verify filter keys match your data model
- Ensure debouncing isn't preventing immediate updates

**2. State not persisting**
- Make sure filter values are stored in parent widget state
- Check that `initialValues` prop is correctly set
- Verify widget rebuild behavior

**3. Performance issues**
- Reduce debounce delay for text inputs
- Check for memory leaks in callbacks
- Consider lazy loading for large filter option lists

**4. UI layout problems**
- Adjust filter field widths using `width` property
- Check responsive behavior on different screen sizes
- Verify color scheme compatibility

## Future Enhancements

### Planned Features
1. **Saved Filter Presets**: Save and load filter combinations
2. **Filter Templates**: Predefined filter sets for common use cases
3. **Export Filters**: Export current filter configuration
4. **Filter Analytics**: Track most used filters
5. **Conditional Filters**: Filters that depend on other filter values

### Contributing
When adding new filter types or features:
1. Follow existing code patterns
2. Update documentation
3. Add usage examples
4. Test with multiple screen sizes
5. Ensure accessibility compliance

## Conclusion

The new Advanced Filters system provides a powerful, flexible, and consistent filtering experience across the entire MDMS Clone application. By using reusable components and following established patterns, it reduces code duplication while enhancing user experience.

For questions or issues, refer to the code examples above or check the implementation in the existing screens.
