# Reusable Kanban Widget System

This document describes the new reusable Kanban widget system implemented for the MDMS project. The system provides a generic, configurable Kanban board that can be used across all modules.

## Overview

The Kanban system consists of:
- **Generic KanbanView widget**: Core reusable component
- **KanbanItem abstract class**: Interface for data models
- **Module-specific adapters**: Convert existing models to work with KanbanView
- **Configuration classes**: Define columns and actions per module

## Architecture

### Core Components

#### 1. KanbanView<T extends KanbanItem>
```dart
KanbanView<ScheduleKanbanItem>(
  items: kanbanItems,
  columns: ScheduleKanbanConfig.columns,
  actions: actions,
  onItemTap: (item) => onItemSelected(item.schedule),
  isLoading: false,
  enablePagination: true,
  itemsPerPage: 25,
)
```

#### 2. KanbanItem Abstract Class
Defines the interface that all data models must implement:
```dart
abstract class KanbanItem {
  String get id;           // Unique identifier
  String get title;        // Display title/name
  String get status;       // Status/column for grouping
  String? get subtitle;    // Optional subtitle/description
  String? get badge;       // Optional badge text
  IconData? get icon;      // Optional icon
  Color? get itemColor;    // Optional color scheme
  List<KanbanDetail> get details; // Additional details
  bool get isActive;       // Whether item is active/enabled
}
```

#### 3. KanbanColumn Configuration
```dart
const KanbanColumn(
  key: 'active',
  title: 'Active',
  icon: Icons.check_circle,
  color: Color(0xFF059669), // Green
  emptyMessage: 'No active items',
)
```

#### 4. KanbanAction Configuration
```dart
KanbanAction(
  key: 'edit',
  label: 'Edit',
  icon: Icons.edit,
  color: AppColors.warning,
  onTap: (item) => onEdit(item),
)
```

## Module Implementations

### 1. Schedules Module

**Files:**
- `lib/presentation/widgets/schedules/schedule_kanban_adapter.dart`
- `lib/presentation/widgets/schedules/schedule_kanban_view.dart` (updated)

**Usage:**
```dart
ScheduleKanbanView(
  schedules: schedules,
  onScheduleSelected: (schedule) => navigateToDetails(schedule),
  onScheduleEdit: (schedule) => showEditDialog(schedule),
  onScheduleDelete: (schedule) => confirmDelete(schedule),
  onScheduleView: (schedule) => showViewDialog(schedule),
)
```

**Columns:**
- **Enabled**: Green, shows enabled schedules
- **Disabled**: Red, shows disabled schedules

### 2. Devices Module

**Files:**
- `lib/presentation/widgets/devices/device_kanban_adapter.dart`
- `lib/presentation/widgets/devices/device_kanban_view.dart`

**Usage:**
```dart
DeviceKanbanView(
  devices: devices,
  onDeviceSelected: (device) => navigateToDetails(device),
  onDeviceEdit: (device) => showEditDialog(device),
  onManageChannels: (device) => showChannelsDialog(device),
)
```

**Columns:**
- **Connected**: Green, shows connected devices
- **Disconnected**: Red, shows disconnected devices
- **Multidrive**: Blue, shows multidrive devices
- **Unknown**: Gray, shows devices with unknown status

### 3. Device Groups Module

**Files:**
- `lib/presentation/widgets/device_groups/device_group_kanban_adapter.dart`
- `lib/presentation/widgets/device_groups/device_group_kanban_view.dart`

**Usage:**
```dart
DeviceGroupKanbanView(
  deviceGroups: deviceGroups,
  onDeviceGroupSelected: (group) => navigateToDetails(group),
  onManageDevices: (group) => showManageDevicesDialog(group),
)
```

**Columns:**
- **Active**: Green, shows active device groups
- **Inactive**: Red, shows inactive device groups

### 4. Sites Module

**Files:**
- `lib/presentation/widgets/sites/site_kanban_adapter.dart`

**Usage:**
```dart
KanbanView<SiteKanbanItem>(
  items: sites.map((site) => SiteKanbanItem(site)).toList(),
  columns: SiteKanbanConfig.columns,
  actions: SiteKanbanConfig.getActions(
    onView: onViewSite,
    onEdit: onEditSite,
  ),
  onItemTap: (item) => onSiteSelected(item.site),
)
```

### 5. Time of Use Module

**Files:**
- `lib/presentation/widgets/time_of_use/time_of_use_kanban_adapter.dart`

### 6. Time Bands Module

**Files:**
- `lib/presentation/widgets/time_bands/time_band_kanban_adapter.dart`

### 7. Special Days Module

**Files:**
- `lib/presentation/widgets/special_days/special_day_kanban_adapter.dart`

## How to Add Kanban to a New Module

### Step 1: Create Adapter
```dart
// lib/presentation/widgets/your_module/your_model_kanban_adapter.dart
class YourModelKanbanItem extends KanbanItem {
  final YourModel yourModel;
  
  YourModelKanbanItem(this.yourModel);
  
  @override
  String get id => yourModel.id?.toString() ?? '';
  
  @override
  String get title => yourModel.name;
  
  @override
  String get status => yourModel.active ? 'active' : 'inactive';
  
  // Implement other required getters...
}

class YourModelKanbanConfig {
  static List<KanbanColumn> get columns => [
    // Define your columns...
  ];
  
  static List<KanbanAction> getActions({...}) {
    // Define your actions...
  }
}
```

### Step 2: Create Widget (Optional)
```dart
// lib/presentation/widgets/your_module/your_model_kanban_view.dart
class YourModelKanbanView extends StatelessWidget {
  final List<YourModel> items;
  final Function(YourModel) onItemSelected;
  // Other callbacks...
  
  @override
  Widget build(BuildContext context) {
    final kanbanItems = items.map((item) => YourModelKanbanItem(item)).toList();
    final actions = YourModelKanbanConfig.getActions(/* ... */);
    
    return KanbanView<YourModelKanbanItem>(
      items: kanbanItems,
      columns: YourModelKanbanConfig.columns,
      actions: actions,
      onItemTap: (item) => onItemSelected(item.yourModel),
    );
  }
}
```

### Step 3: Use in Screen
```dart
// In your screen widget
YourModelKanbanView(
  items: yourItems,
  onItemSelected: (item) => handleSelection(item),
  // Other callbacks...
)
```

## Customization Options

### Column Width
```dart
KanbanView(
  columnWidth: 350.0, // Default: 300.0
  // ...
)
```

### Maximum Height
```dart
KanbanView(
  maxHeight: 600.0, // Default: unlimited
  // ...
)
```

### Custom Item Builder
```dart
KanbanView(
  customItemBuilder: (item) => CustomCard(item: item),
  // ...
)
```

### Custom Empty State
```dart
KanbanView(
  customEmptyBuilder: (columnKey) => CustomEmptyWidget(columnKey),
  // ...
)
```

### Pagination
```dart
KanbanView(
  enablePagination: true,
  itemsPerPage: 50, // Default: 25
  // ...
)
```

## Benefits

1. **Consistency**: Uniform look and behavior across all modules
2. **Maintainability**: Single source of truth for Kanban functionality
3. **Flexibility**: Highly configurable for different use cases
4. **Performance**: Optimized rendering and pagination
5. **Accessibility**: Built-in accessibility features
6. **Responsiveness**: Adaptive to different screen sizes

## Best Practices

1. **Status Mapping**: Ensure your status values match column keys (case-insensitive)
2. **Color Consistency**: Use the app's color scheme for consistency
3. **Icon Selection**: Choose meaningful icons that represent the data type
4. **Action Ordering**: Place most common actions first
5. **Badge Information**: Use badges for quick, relevant information
6. **Detail Prioritization**: Show most important details first

## Migration Guide

To migrate existing custom Kanban implementations:

1. **Identify Data Structure**: Understand your current data model
2. **Create Adapter**: Implement the KanbanItem interface
3. **Define Configuration**: Set up columns and actions
4. **Replace Widget**: Switch to using KanbanView
5. **Test Functionality**: Verify all interactions work correctly
6. **Remove Old Code**: Clean up the old implementation

## Performance Considerations

- **Pagination**: Enable for large datasets (>100 items)
- **Lazy Loading**: Consider implementing for very large datasets
- **Virtualization**: Built-in ListView virtualization handles scrolling efficiently
- **Image Caching**: Icons are efficiently cached by Flutter

## Accessibility

The Kanban widget includes:
- **Screen Reader Support**: Semantic labels and descriptions
- **Keyboard Navigation**: Tab and enter key support
- **High Contrast**: Respects system accessibility settings
- **Touch Targets**: Minimum 44px touch targets

## Future Enhancements

Planned improvements:
- **Drag & Drop**: Move items between columns
- **Filtering**: Built-in search and filter capabilities
- **Sorting**: Multiple sort options per column
- **Export**: Export Kanban data to CSV/PDF
- **Themes**: Additional color themes and layouts
