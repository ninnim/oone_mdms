import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/chart_type.dart';
import '../common/app_card.dart';
import '../common/app_button.dart';
import '../common/app_toast.dart';

class GroupedMetricsCharts extends StatefulWidget {
  final List<Map<String, dynamic>> dynamicMetrics;
  final Function()? onRefresh;

  const GroupedMetricsCharts({
    super.key,
    required this.dynamicMetrics,
    this.onRefresh,
  });

  @override
  State<GroupedMetricsCharts> createState() => _GroupedMetricsChartsState();
}

class _GroupedMetricsChartsState extends State<GroupedMetricsCharts> {
  Set<String> _selectedChartFields = {};
  
  // Grouped chart types for each metric group
  final Map<String, ChartType> _groupChartTypes = {
    'Export': ChartType.line,
    'Import': ChartType.line,
    'Voltage': ChartType.line,
    'Current': ChartType.line,
    'Other': ChartType.line,
  };

  @override
  Widget build(BuildContext context) {
    if (widget.dynamicMetrics.isEmpty) {
      return AppCard(
        child: Container(
          height: 400,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: AppSizes.spacing16),
                Text(
                  'No metrics data available',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: AppSizes.spacing8),
                Text(
                  'Select a date range and load data to view charts',
                  style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _buildGroupedMetricsCharts();
  }

  Widget _buildGroupedMetricsCharts() {
    final groupedFields = _groupMetricsByType();
    
    if (groupedFields.isEmpty) {
      return AppCard(
        child: Container(
          height: 300,
          child: const Center(
            child: Text(
              'No grouped metrics available',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Header with global controls
        _buildGroupedChartsHeader(),
        const SizedBox(height: AppSizes.spacing16),
        
        // Grouped Chart Cards
        ...groupedFields.entries.map((entry) => 
          _buildGroupedChartCard(entry.key, entry.value)
        ).toList(),
      ],
    );
  }

  Map<String, List<String>> _groupMetricsByType() {
    if (widget.dynamicMetrics.isEmpty) return {};

    final Map<String, List<String>> groupedFields = {
      'Export': [],
      'Import': [], 
      'Voltage': [],
      'Current': [],
      'Other': [],
    };

    // Get all numeric fields from the first record
    final firstRecord = widget.dynamicMetrics.first;
    firstRecord.forEach((key, value) {
      if (key != 'Timestamp' && value is num) {
        final fieldName = key.toLowerCase();
        
        if (fieldName.contains('export') || 
            fieldName.contains('exp') ||
            fieldName.contains('delivery') ||
            fieldName.contains('wh') && fieldName.contains('exp')) {
          groupedFields['Export']!.add(key);
        } else if (fieldName.contains('import') || 
                   fieldName.contains('imp') ||
                   fieldName.contains('received') ||
                   fieldName.contains('wh') && fieldName.contains('imp')) {
          groupedFields['Import']!.add(key);
        } else if (fieldName.contains('voltage') || 
                   fieldName.contains('volt') ||
                   fieldName.contains('v_') ||
                   fieldName.contains('_v')) {
          groupedFields['Voltage']!.add(key);
        } else if (fieldName.contains('current') || 
                   fieldName.contains('amp') ||
                   fieldName.contains('i_') ||
                   fieldName.contains('_i')) {
          groupedFields['Current']!.add(key);
        } else if (fieldName.contains('varh')) {
          // Reactive energy can go to either import or export based on context
          if (fieldName.contains('export') || fieldName.contains('exp')) {
            groupedFields['Export']!.add(key);
          } else if (fieldName.contains('import') || fieldName.contains('imp')) {
            groupedFields['Import']!.add(key);
          } else {
            groupedFields['Other']!.add(key);
          }
        } else {
          groupedFields['Other']!.add(key);
        }
      }
    });

    // Remove empty groups
    groupedFields.removeWhere((key, value) => value.isEmpty);
    
    return groupedFields;
  }

  Widget _buildGroupedChartsHeader() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Metrics Dashboard',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Grouped metrics visualization with dynamic filtering (Wh, Varh, Voltage, Current)',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppButton(
                  text: 'Export All',
                  onPressed: _exportAllCharts,
                  type: AppButtonType.secondary,
                  size: AppButtonSize.small,
                ),
                const SizedBox(width: 8),
                if (widget.onRefresh != null)
                  AppButton(
                    text: 'Refresh',
                    onPressed: widget.onRefresh,
                    type: AppButtonType.primary,
                    size: AppButtonSize.small,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedChartCard(String groupType, List<String> fields) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacing16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header
            _buildGroupedChartHeader(groupType, fields),
            const SizedBox(height: AppSizes.spacing16),
            
            // Field Filters for this group
            _buildGroupFieldFilters(groupType, fields),
            const SizedBox(height: AppSizes.spacing16),
            
            // Chart Content
            Container(
              height: 400,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                border: Border.all(color: AppColors.border),
              ),
              child: _buildGroupChartContent(groupType, fields),
            ),
            
            const SizedBox(height: AppSizes.spacing16),
            
            // Summary Statistics for this group
            _buildGroupSummaryStats(groupType, fields),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedChartHeader(String groupType, List<String> fields) {
    final selectedFields = fields.where((field) => 
      _selectedChartFields.contains(field)).toList();
    
    return Row(
      children: [
        // Group Icon and Title
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getGroupColor(groupType).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getGroupIcon(groupType),
            color: _getGroupColor(groupType),
            size: 24,
          ),
        ),
        const SizedBox(width: AppSizes.spacing12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$groupType Metrics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${selectedFields.length} of ${fields.length} fields selected',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        
        // Group Controls
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Chart Type for this group
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              child: DropdownButton<ChartType>(
                value: _getGroupChartType(groupType),
                underline: const SizedBox.shrink(),
                isDense: true,
                items: ChartType.values.map((type) => DropdownMenuItem(
                  value: type,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getChartTypeIcon(type), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        _formatChartTypeName(type),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                )).toList(),
                onChanged: (ChartType? newType) {
                  if (newType != null) {
                    setState(() {
                      _setGroupChartType(groupType, newType);
                    });
                  }
                },
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Export this group
            IconButton(
              onPressed: () => _exportGroupChart(groupType, fields),
              icon: const Icon(Icons.download, size: 18),
              tooltip: 'Export $groupType Data',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceVariant,
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.all(8),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Toggle all fields in this group
            IconButton(
              onPressed: () => _toggleGroupFields(fields),
              icon: Icon(
                selectedFields.length == fields.length 
                  ? Icons.visibility_off 
                  : Icons.visibility,
                size: 18,
              ),
              tooltip: selectedFields.length == fields.length 
                ? 'Hide All $groupType' 
                : 'Show All $groupType',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceVariant,
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.all(8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGroupFieldFilters(String groupType, List<String> fields) {
    if (fields.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$groupType Fields (Wh, Varh filters)',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.spacing8),
        Wrap(
          spacing: AppSizes.spacing8,
          runSpacing: AppSizes.spacing8,
          children: fields.map((field) {
            final isSelected = _selectedChartFields.contains(field);
            final fieldColor = _getGroupColor(groupType);
            
            return FilterChip(
              label: Text(
                _formatFieldName(field),
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? fieldColor : AppColors.textPrimary,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedChartFields.add(field);
                  } else {
                    _selectedChartFields.remove(field);
                  }
                });
              },
              selectedColor: fieldColor.withOpacity(0.2),
              checkmarkColor: fieldColor,
              side: BorderSide(color: fieldColor.withOpacity(0.5)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGroupChartContent(String groupType, List<String> fields) {
    final selectedFields = fields.where((field) => 
      _selectedChartFields.contains(field)).toList();
    
    if (selectedFields.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getGroupIcon(groupType),
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSizes.spacing12),
            Text(
              'Select ${groupType.toLowerCase()} fields to display chart',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final chartType = _getGroupChartType(groupType);
    
    switch (chartType) {
      case ChartType.line:
        return _buildGroupLineChart(groupType, selectedFields);
      case ChartType.bar:
        return _buildGroupBarChart(groupType, selectedFields);
      case ChartType.area:
        return _buildGroupAreaChart(groupType, selectedFields);
      case ChartType.scatter:
        return _buildGroupScatterChart(groupType, selectedFields);
    }
  }

  Widget _buildGroupSummaryStats(String groupType, List<String> fields) {
    final selectedFields = fields.where((field) => 
      _selectedChartFields.contains(field)).toList();
    
    if (selectedFields.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing12),
      decoration: BoxDecoration(
        color: _getGroupColor(groupType).withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(
          color: _getGroupColor(groupType).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$groupType Summary (Table Format)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _getGroupColor(groupType),
            ),
          ),
          const SizedBox(height: AppSizes.spacing8),
          Wrap(
            spacing: AppSizes.spacing16,
            runSpacing: AppSizes.spacing8,
            children: selectedFields.map((field) {
              final values = _getFieldValues(field);
              final stats = _calculateFieldStats(values);
              
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacing12,
                  vertical: AppSizes.spacing8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatFieldName(field),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Avg: ${_formatNumber(stats['avg']!)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Max: ${_formatNumber(stats['max']!)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getGroupColor(String groupType) {
    switch (groupType) {
      case 'Export':
        return Colors.green;
      case 'Import':
        return Colors.blue;
      case 'Voltage':
        return Colors.orange;
      case 'Current':
        return Colors.purple;
      case 'Other':
        return Colors.grey;
    }
    return AppColors.primary;
  }

  IconData _getGroupIcon(String groupType) {
    switch (groupType) {
      case 'Export':
        return Icons.upload;
      case 'Import':
        return Icons.download;
      case 'Voltage':
        return Icons.electric_bolt;
      case 'Current':
        return Icons.electrical_services;
      case 'Other':
        return Icons.analytics;
    }
    return Icons.show_chart;
  }

  ChartType _getGroupChartType(String groupType) {
    return _groupChartTypes[groupType] ?? ChartType.line;
  }

  void _setGroupChartType(String groupType, ChartType chartType) {
    _groupChartTypes[groupType] = chartType;
  }

  IconData _getChartTypeIcon(ChartType type) {
    switch (type) {
      case ChartType.line:
        return Icons.show_chart;
      case ChartType.bar:
        return Icons.bar_chart;
      case ChartType.area:
        return Icons.area_chart;
      case ChartType.scatter:
        return Icons.scatter_plot;
    }
  }

  String _formatChartTypeName(ChartType type) {
    return type.toString().split('.').last.toUpperCase();
  }

  void _toggleGroupFields(List<String> fields) {
    setState(() {
      final selectedFieldsInGroup = fields.where((field) => 
        _selectedChartFields.contains(field)).toList();
      
      if (selectedFieldsInGroup.length == fields.length) {
        // All fields selected, deselect all
        for (final field in fields) {
          _selectedChartFields.remove(field);
        }
      } else {
        // Not all fields selected, select all
        for (final field in fields) {
          _selectedChartFields.add(field);
        }
      }
    });
  }

  void _exportAllCharts() {
    AppToast.showSuccess(
      context,
      title: 'Export Started',
      message: 'Exporting all chart data...',
    );
  }

  void _exportGroupChart(String groupType, List<String> fields) {
    AppToast.showSuccess(
      context,
      title: 'Export Started',
      message: 'Exporting $groupType chart data...',
    );
  }

  String _formatFieldName(String fieldName) {
    return fieldName
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .trim()
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty 
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : word)
        .join(' ');
  }

  List<double> _getFieldValues(String field) {
    return widget.dynamicMetrics
        .map((data) => (data[field] as num?)?.toDouble() ?? 0.0)
        .toList();
  }

  Map<String, double> _calculateFieldStats(List<double> values) {
    if (values.isEmpty) {
      return {'avg': 0.0, 'max': 0.0, 'min': 0.0};
    }

    final sum = values.fold<double>(0, (prev, val) => prev + val);
    final avg = sum / values.length;
    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);

    return {
      'avg': avg,
      'max': max,
      'min': min,
    };
  }

  String _formatNumber(double value) {
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(2)}K';
    } else if (value.abs() >= 1) {
      return value.toStringAsFixed(2);
    } else {
      return value.toStringAsFixed(4);
    }
  }

  // Chart building methods will be added in the next part...
  Widget _buildGroupLineChart(String groupType, List<String> fields) {
    final chartData = widget.dynamicMetrics;
    if (chartData.isEmpty) return const SizedBox.shrink();

    final fieldColors = _generateGroupFieldColors(groupType, fields.length);
    final maxY = _getMaxYValue(fields);
    final minY = _getMinYValue(fields);

    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.border,
              strokeWidth: 0.5,
            ),
            getDrawingVerticalLine: (value) => FlLine(
              color: AppColors.border,
              strokeWidth: 0.5,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) => _buildXAxisLabel(value, chartData),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) => _buildYAxisLabel(value),
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: AppColors.border),
          ),
          minX: 0,
          maxX: chartData.length.toDouble() - 1,
          minY: minY,
          maxY: maxY,
          lineBarsData: fields.asMap().entries.map((entry) {
            final index = entry.key;
            final fieldName = entry.value;
            final color = fieldColors[index % fieldColors.length];

            return LineChartBarData(
              spots: chartData.asMap().entries.map((dataEntry) {
                final xIndex = dataEntry.key;
                final dataPoint = dataEntry.value;
                final yValue = (dataPoint[fieldName] as num?)?.toDouble() ?? 0.0;
                return FlSpot(xIndex.toDouble(), yValue);
              }).toList(),
              isCurved: true,
              color: color,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
            );
          }).toList(),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => AppColors.surface,
              tooltipRoundedRadius: 8,
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final fieldName = fields[barSpot.barIndex];
                  final dataPoint = chartData[barSpot.x.toInt()];
                  final timestamp = dataPoint['Timestamp']?.toString() ?? '';
                  final value = barSpot.y;

                  return LineTooltipItem(
                    '${_formatFieldName(fieldName)}\n$timestamp\n${_formatNumber(value)}',
                    TextStyle(
                      color: fieldColors[barSpot.barIndex % fieldColors.length],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupBarChart(String groupType, List<String> fields) {
    // Simplified bar chart implementation
    return _buildGroupLineChart(groupType, fields);
  }

  Widget _buildGroupAreaChart(String groupType, List<String> fields) {
    // Simplified area chart implementation
    return _buildGroupLineChart(groupType, fields);
  }

  Widget _buildGroupScatterChart(String groupType, List<String> fields) {
    if (fields.length < 2) {
      return const Center(
        child: Text(
          'Scatter chart requires at least 2 fields',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return _buildGroupLineChart(groupType, fields);
  }

  List<Color> _generateGroupFieldColors(String groupType, int count) {
    final baseColor = _getGroupColor(groupType);
    final colors = <Color>[];
    
    for (int i = 0; i < count; i++) {
      final hue = (baseColor.computeLuminance() * 360 + i * 30) % 360;
      colors.add(HSVColor.fromAHSV(1.0, hue, 0.7, 0.8).toColor());
    }
    
    return colors;
  }

  double _getMaxYValue(List<String> fields) {
    double maxValue = 0;
    for (final data in widget.dynamicMetrics) {
      for (final field in fields) {
        final value = (data[field] as num?)?.toDouble() ?? 0.0;
        if (value > maxValue) maxValue = value;
      }
    }
    return maxValue * 1.1; // Add 10% padding
  }

  double _getMinYValue(List<String> fields) {
    double minValue = double.infinity;
    for (final data in widget.dynamicMetrics) {
      for (final field in fields) {
        final value = (data[field] as num?)?.toDouble() ?? 0.0;
        if (value < minValue) minValue = value;
      }
    }
    return minValue < 0 ? minValue * 1.1 : 0; // Add padding if negative
  }

  Widget _buildXAxisLabel(double value, List<Map<String, dynamic>> chartData) {
    final index = value.toInt();
    if (index < 0 || index >= chartData.length) {
      return const SizedBox.shrink();
    }

    final timestamp = chartData[index]['Timestamp']?.toString() ?? '';
    if (timestamp.isEmpty) return const SizedBox.shrink();

    // Show simplified date format
    try {
      final date = DateTime.parse(timestamp);
      return SideTitleWidget(
        axisSide: AxisSide.bottom,
        child: Text(
          '${date.day}/${date.month}',
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      );
    } catch (e) {
      return SideTitleWidget(
        axisSide: AxisSide.bottom,
        child: Text(
          index.toString(),
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      );
    }
  }

  Widget _buildYAxisLabel(double value) {
    return SideTitleWidget(
      axisSide: AxisSide.left,
      child: Text(
        _formatNumber(value),
        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
      ),
    );
  }
}
