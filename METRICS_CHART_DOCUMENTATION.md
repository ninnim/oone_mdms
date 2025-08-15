# Modern Metrics Chart System - Documentation

## Overview
The Modern Metrics Chart System is a comprehensive, dynamic charting solution for visualizing time-series data from API responses. It provides multiple chart types with consistent behavior, smart axis calculations, and professional tooltips.

## Features

### ✅ **Chart Types**
- **Line Chart**: Smooth curved lines with gradient areas
- **Bar Chart**: Grouped vertical bars with time intervals
- **Area Chart**: Filled area charts with gradients
- **Scatter Plot**: X/Y coordinate plotting for correlation analysis

### ✅ **Dynamic Data Handling**
- **API-Driven Fields**: Automatically detects all numeric fields from API response
- **Real-time Updates**: Responds to data changes and view switches
- **Smart Grouping**: Categorizes fields by type (Export, Import, Voltage, Current, Other)
- **Auto-Selection**: Automatically selects first available field on load

### ✅ **User Interface**
- **Loading States**: Shows loading spinner when switching from Table to Graphs view
- **Total Points Display**: Shows count of data points being visualized
- **Responsive Design**: Adapts to different screen sizes
- **Horizontal Scrolling**: Handles large datasets with smooth scrolling

### ✅ **Professional Styling**
- **Consistent Tooltips**: All chart types use same black tooltip with white text
- **Hover Always On Top**: Tooltips properly positioned and visible
- **Clean Typography**: Professional fonts and sizing
- **Color Coordination**: Automatic color assignment with field-specific colors

## Technical Implementation

### **Data Flow**

```
API Response → Field Detection → Chart Data Preparation → Visualization
```

1. **API Response Processing**
   ```dart
   // Scans all records to find ALL numeric fields
   for (final record in widget.data) {
     record.forEach((key, value) {
       if (key.toLowerCase() != 'timestamp' && value is num) {
         availableFields.add(key);
       }
     });
   }
   ```

2. **Chart Data Preparation**
   ```dart
   List<Map<String, dynamic>> _prepareChartData() {
     return widget.data.where((record) {
       return _selectedFields.any((field) {
         final value = record[field];
         return value != null && value is num && !value.isNaN;
       });
     }).toList();
   }
   ```

### **Axis Calculations**

#### **X-Axis (Time Axis)**
- **Format**: `Aug/15 05:00` (Month/Day Hour:Minute)
- **Interval**: Always `1.0` to show ALL timestamps from API
- **Spacing**: `2.0px` between timestamps for optimal readability
- **Scrolling**: Activates when more than 20 data points

```dart
double _calculateXAxisInterval(int dataLength) {
  return 1.0; // Always show ALL timestamps
}

String _formatEnhancedTimestamp(dynamic timestamp) {
  // Returns: Aug/15 05:00
}
```

#### **Y-Axis (Value Axis)**
- **Smart Intervals**: Prevents duplicate labels with calculated intervals
- **Nice Numbers**: Rounds to clean values (1, 2, 5, 10, etc.)
- **Minimum 5 Labels**: Ensures readable scale
- **Format**: K/M/B formatting for large numbers

```dart
double _calculateYAxisInterval(List<Map<String, dynamic>> data) {
  // Calculates optimal interval to prevent duplicates
  // Returns minimum interval ensuring 5 distinct labels
}
```

### **Chart Type Implementations**

#### **1. Line Chart**
```dart
Widget _buildLineChart(List<Map<String, dynamic>> data) {
  // Features:
  // - Smooth curved lines (curveSmoothness: 0.35)
  // - Gradient shadow effects
  // - Interactive tooltips
  // - Multiple field support
}
```

#### **2. Bar Chart**
```dart
Widget _buildBarChart(List<Map<String, dynamic>> data) {
  // Features:
  // - Time interval grouping
  // - Multiple bars per group
  // - Smart color coordination
  // - Range-based tooltips
}
```

#### **3. Area Chart**
```dart
Widget _buildAreaChart(List<Map<String, dynamic>> data) {
  // Features:
  // - Filled areas with gradients
  // - Curved lines with area fill
  // - Transparent overlays
  // - Same tooltip system as line chart
}
```

#### **4. Scatter Plot**
```dart
Widget _buildScatterChart(List<Map<String, dynamic>> data) {
  // Features:
  // - X/Y correlation visualization
  // - Requires minimum 2 fields
  // - Coordinate-based tooltips
  // - Grid lines for reference
}
```

### **Tooltip System**

All chart types use consistent tooltip formatting:

```dart
// Standard Tooltip Configuration
getTooltipColor: (spot) => Colors.black87,
tooltipRoundedRadius: 8,
tooltipPadding: const EdgeInsets.all(12),
tooltipMargin: 8,
fitInsideHorizontally: true,
fitInsideVertically: true,

// Content Format
'${fieldName}\n${formattedValue}\n${timestamp}'
```

### **Loading States**

```dart
if (widget.isLoading) {
  return AppCard(
    child: Container(
      height: 500,
      child: const Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            Text('Loading Metrics...'),
          ],
        ),
      ),
    ),
  );
}
```

## Usage Examples

### **1. Basic Implementation**
```dart
ModernMetricsChart(
  data: apiResponseData,
  isLoading: false,
  onRefresh: () => refreshData(),
  onExport: () => exportData(),
)
```

### **2. With Loading State**
```dart
ModernMetricsChart(
  data: metricsData,
  isLoading: isLoadingGraphsView,
  onRefresh: _refreshMetrics,
  onExport: _exportMetrics,
)
```

### **3. API Response Format**
```json
[
  {
    "timestamp": "2025-08-15T05:00:00Z",
    "Voltage Phase A": 12.85,
    "Current Phase A": 145.2,
    "Export Active Power": 1850.5,
    "Import Active Power": 0.0
  },
  {
    "timestamp": "2025-08-15T06:00:00Z",
    "Voltage Phase A": 12.90,
    "Current Phase A": 148.1,
    "Export Active Power": 1920.3,
    "Import Active Power": 0.0
  }
]
```

## Performance Optimizations

### **Memory Management**
- Efficient data filtering
- Lazy chart building
- Animation controllers properly disposed
- Smart re-rendering on data changes

### **Rendering Optimizations**
- Horizontal scrolling for large datasets
- Adaptive spacing calculations
- Minimal widget rebuilds
- Cached color assignments

### **Data Processing**
- Single-pass field detection
- Optimized value filtering
- Efficient grouping algorithms
- Smart interval calculations

## Troubleshooting

### **Common Issues**

1. **Overlapping X-axis Labels**
   - **Solution**: Automatic horizontal scrolling activates
   - **Spacing**: 2.0px between timestamps ensures readability

2. **Duplicate Y-axis Values**
   - **Solution**: Smart interval calculation prevents duplicates
   - **Minimum**: Always shows at least 5 distinct labels

3. **Missing Chart Fields**
   - **Solution**: Dynamic field detection scans ALL records
   - **Fallback**: Auto-selects first available field

4. **Tooltip Not Visible**
   - **Solution**: `fitInsideHorizontally` and `fitInsideVertically` ensure visibility
   - **Positioning**: Automatic adjustment for screen boundaries

### **Performance Issues**

1. **Large Datasets**
   - **Solution**: Horizontal scrolling with optimized spacing
   - **Threshold**: Activates at >20 data points

2. **Memory Usage**
   - **Solution**: Efficient data filtering and caching
   - **Cleanup**: Proper animation controller disposal

## API Integration

### **Required Props**
```dart
final List<Map<String, dynamic>> data; // API response data
final bool isLoading;                   // Loading state
final VoidCallback? onRefresh;          // Refresh function
final VoidCallback? onExport;           // Export function
```

### **Expected Data Format**
- Each record must have a `timestamp` or `Timestamp` field
- Numeric fields are automatically detected and available for selection
- Non-numeric and timestamp fields are filtered out
- Empty or invalid values are handled gracefully

### **Dynamic Field Detection**
The system automatically:
1. Scans ALL records in the dataset
2. Identifies numeric fields (excluding timestamps)
3. Groups fields by category (Export, Import, Voltage, Current, Other)
4. Auto-selects the first field for initial display
5. Updates available fields when data changes

## Customization

### **Colors**
Field-specific colors are automatically assigned:
```dart
final specificColors = {
  'Voltage Phase A': Colors.orange,
  'Voltage Phase B': Colors.blue,
  'Current Phase A': Colors.green,
  // ... more field-specific colors
};
```

### **Chart Types**
Switch between chart types using the dropdown:
- Line Chart (default)
- Bar Chart
- Area Chart
- Scatter Plot

### **Field Selection**
Users can select/deselect fields using the field chips interface.

## Future Enhancements

### **Planned Features**
- [ ] Real-time data streaming
- [ ] Custom date range filtering
- [ ] Advanced export options (PDF, CSV, PNG)
- [ ] Custom color themes
- [ ] Chart annotations
- [ ] Zoom and pan capabilities

### **Performance Improvements**
- [ ] Virtual scrolling for massive datasets
- [ ] WebGL rendering for complex visualizations
- [ ] Background data processing
- [ ] Intelligent caching strategies

---

**Version**: 1.0.0  
**Last Updated**: August 15, 2025  
**Compatibility**: Flutter 3.0+, fl_chart 0.60+

For technical support or feature requests, please refer to the development team.
