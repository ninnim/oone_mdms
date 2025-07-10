# Custom Date Range Picker Widget

## Overview
The `CustomDateRangePicker` is a reusable Flutter widget that provides a modern, dialog-based date range selection interface. It features a calendar view with month navigation, quick action buttons (Today, Last 7 days, Last 30 days), and Apply/Cancel buttons.

## Features
- 📅 **Calendar Interface**: Interactive calendar with month navigation
- 🎯 **Range Selection**: Click to select start and end dates
- ⚡ **Quick Actions**: Today button and preset ranges
- 🌗 **Dark/Light Mode**: Automatically adapts to app theme
- 🎨 **App Theme Integration**: Uses AppColors constants for consistency
- ✅ **Apply/Cancel**: Clear user feedback and action confirmation
- 🔄 **Reusable**: Can be used throughout the app

## Usage

### Basic Usage
```dart
CustomDateRangePicker(
  initialStartDate: DateTime.now().subtract(Duration(days: 7)),
  initialEndDate: DateTime.now(),
  onDateRangeSelected: (startDate, endDate) {
    print('Selected range: $startDate to $endDate');
    // Handle the selected date range
  },
)
```

### With Custom Styling
```dart
CustomDateRangePicker(
  initialStartDate: myStartDate,
  initialEndDate: myEndDate,
  onDateRangeSelected: (startDate, endDate) {
    setState(() {
      _startDate = startDate;
      _endDate = endDate;
    });
    _refreshData();
  },
  hintText: 'Select date range',
  enabled: true,
)
```

## Implementation in Device Metrics

The widget has been integrated into the Device 360 Details screen's Metrics section, replacing the old dropdown-based date picker:

### Location
- **File**: `lib/presentation/screens/devices/device_360_details_screen.dart`
- **Method**: `_buildDateFilter()`
- **Section**: Metrics tab

### Integration Code
```dart
Widget _buildDateFilter() {
  return Row(
    children: [
      CustomDateRangePicker(
        initialStartDate: _metricsStartDate,
        initialEndDate: _metricsEndDate,
        onDateRangeSelected: (startDate, endDate) {
          setState(() {
            _metricsStartDate = startDate;
            _metricsEndDate = endDate;
            _metricsCurrentPage = 1;
          });
          _refreshMetricsData();
        },
        hintText: 'Select date range',
        enabled: true,
      ),
      const SizedBox(width: 12),
      // Refresh button...
    ],
  );
}
```

## Widget Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `initialStartDate` | `DateTime?` | No | Initial start date to display |
| `initialEndDate` | `DateTime?` | No | Initial end date to display |
| `onDateRangeSelected` | `Function(DateTime, DateTime)` | Yes | Callback when date range is selected |
| `hintText` | `String?` | No | Placeholder text when no dates selected |
| `enabled` | `bool` | No | Whether the picker is interactive (default: true) |

## Dialog Features

### Calendar
- Monthly view with week day headers
- Click to select start and end dates
- Visual indication of selected range
- Event dots for special dates (customizable)
- Today highlighting

### Quick Actions
- **Today**: Sets both start and end to current date
- **Last 7 days**: Sets range to past week
- **Last 30 days**: Sets range to past month

### Navigation
- Previous/Next month arrows
- Month and year display

### Actions
- **Cancel**: Closes dialog without applying changes
- **Apply**: Confirms selection and triggers callback

## Theme Support

The widget automatically adapts to the current app theme:

### Light Mode
- White background (`AppColors.surface`)
- Dark text (`AppColors.textPrimary`)
- Light borders (`AppColors.border`)

### Dark Mode
- Dark background (`Color(0xFF2d3748)`)
- Light text (`Colors.white`)
- Dark borders (`Color(0xFF4a5568)`)

## Files Modified

### Integration Changes
1. **device_360_details_screen.dart**
   - Added import for `CustomDateRangePicker`
   - Replaced `_buildDateFilter()` method implementation
   - Removed old dropdown-based date picker code

### Widget Files
1. **custom_date_range_picker.dart**
   - Complete widget implementation
   - Theme integration with AppColors
   - Dialog-based date selection interface

## Testing

To test the widget:

1. Run the app: `flutter run -d windows`
2. Navigate to a device details page
3. Go to the Metrics tab
4. Click on the date range picker
5. Test the calendar interface:
   - Select start and end dates
   - Try the "Today" button
   - Test month navigation
   - Verify Apply/Cancel functionality

## Future Enhancements

Potential improvements for the widget:
- [ ] Preset range buttons (Last week, Last month, etc.)
- [ ] Custom date format options
- [ ] Min/Max date constraints
- [ ] Event/holiday highlighting
- [ ] Time selection capability
- [ ] Multi-month view option

## Usage Examples Throughout App

The widget can be reused in other sections:

### Device Billing
```dart
CustomDateRangePicker(
  initialStartDate: _billingStartDate,
  initialEndDate: _billingEndDate,
  onDateRangeSelected: (start, end) {
    // Update billing date range
  },
)
```

### Reports Section
```dart
CustomDateRangePicker(
  hintText: 'Report date range',
  onDateRangeSelected: (start, end) {
    // Generate report for date range
  },
)
```

### Any Other Date Range Selection
The widget is fully reusable and can be dropped into any screen that needs date range selection functionality.
