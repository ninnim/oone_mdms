import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mdms_clone/presentation/widgets/common/app_lottie_state_widget.dart';
// import '../../../core/constants/app_colors.dart';
import '../../themes/app_theme.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/chart_type.dart';
import '../common/app_card.dart';
import '../common/modern_chart_type_dropdown.dart';
import 'dart:math' as math;
import 'dart:async';

class ModernMetricsChart extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final VoidCallback? onExport;
  final Function(int pageSize)? onPageSizeChanged;

  const ModernMetricsChart({
    super.key,
    required this.data,
    this.isLoading = false,
    this.onRefresh,
    this.onExport,
    this.onPageSizeChanged,
  });

  @override
  State<ModernMetricsChart> createState() => _ModernMetricsChartState();
}

class _ModernMetricsChartState extends State<ModernMetricsChart>
    with TickerProviderStateMixin {
  ChartType _selectedChartType = ChartType.line;
  Set<String> _selectedFields = <String>{};
  Map<String, Color> _fieldColors = {};
  late AnimationController _animationController;
  late Animation<double> _animation;

  // PageSize control
  int _pageSize = 0; // Default 0 means get all
  final TextEditingController _pageSizeController = TextEditingController();
  Timer? _pageSizeTimer; // Timer for delayed API trigger

  // Scroll control for dragging
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _pageSizeController.text = _pageSize == 0 ? 'All' : _pageSize.toString();
    _initializeFields();
    _animationController.forward();
  }

  @override
  void didUpdateWidget(ModernMetricsChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data) {
      _initializeFields();
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageSizeController.dispose();
    _horizontalScrollController.dispose();
    _pageSizeTimer?.cancel();
    super.dispose();
  }

  void _triggerDelayedApiCall(int pageSize) {
    print(
      'ModernMetricsChart: Triggering delayed API call with pageSize: $pageSize',
    );
    _pageSizeTimer = Timer(const Duration(milliseconds: 800), () {
      print(
        'ModernMetricsChart: Timer fired, calling onPageSizeChanged with: $pageSize',
      );
      if (widget.onPageSizeChanged != null) {
        widget.onPageSizeChanged!(pageSize);
      } else {
        print(
          'ModernMetricsChart: WARNING - onPageSizeChanged callback is null!',
        );
      }
    });
  }

  void _initializeFields() {
    if (widget.data.isEmpty) return;

    final availableFields = <String>{};

    // Scan all records to get all possible fields (not just the first record)
    // This ensures we don't miss any fields that might be present in some records but not others
    for (final record in widget.data) {
      record.forEach((key, value) {
        if (key.toLowerCase() != 'timestamp' &&
            key.toLowerCase() != 'date' &&
            value != null &&
            value is num) {
          availableFields.add(key);
        }
      });
    }

    // If no available fields from scanning, fall back to first record approach
    if (availableFields.isEmpty && widget.data.isNotEmpty) {
      final firstRecord = widget.data.first;
      firstRecord.forEach((key, value) {
        if (key.toLowerCase() != 'timestamp' &&
            key.toLowerCase() != 'date' &&
            value != null &&
            value is num) {
          availableFields.add(key);
        }
      });
    }

    // Group fields by type for better organization
    _groupFieldsByType(availableFields);

    // Auto-select first field if none selected, or if current selection is no longer valid
    final validSelectedFields = _selectedFields
        .where(availableFields.contains)
        .toSet();

    if (validSelectedFields.isEmpty && availableFields.isNotEmpty) {
      // Select just the first field initially
      final orderedFields = _getOrderedFieldsByPriority(availableFields);
      _selectedFields = {orderedFields.first};
    } else {
      _selectedFields = validSelectedFields;
    }

    // Generate colors for all available fields
    _generateFieldColors(availableFields);

    print(
      'Initialized fields: ${availableFields.length} total, ${_selectedFields.length} selected',
    );
    print('Available fields: ${availableFields.toList()}');
    print('Selected fields: ${_selectedFields.toList()}');
  }

  Map<String, List<String>> _groupFieldsByType(Set<String> fields) {
    final groups = <String, List<String>>{
      'Export': [],
      'Import': [],
      'Voltage': [],
      'Current': [],
      'Power': [],
      'Energy': [],
      'Other': [],
    };

    for (final field in fields) {
      final lowerField = field.toLowerCase();
      if (lowerField.contains('export')) {
        groups['Export']!.add(field);
      } else if (lowerField.contains('import')) {
        groups['Import']!.add(field);
      } else if (lowerField.contains('voltage') ||
          lowerField.contains('volt')) {
        groups['Voltage']!.add(field);
      } else if (lowerField.contains('current') || lowerField.contains('amp')) {
        groups['Current']!.add(field);
      } else if (lowerField.contains('power') || lowerField.contains('watt')) {
        groups['Power']!.add(field);
      } else if (lowerField.contains('energy') || lowerField.contains('wh')) {
        groups['Energy']!.add(field);
      } else {
        groups['Other']!.add(field);
      }
    }

    // Remove empty groups
    groups.removeWhere((key, value) => value.isEmpty);
    return groups;
  }

  List<String> _getOrderedFieldsByPriority(Set<String> fields) {
    // Order fields by priority: Voltage, Current, Power, Energy, Export, Import, Other
    final orderedFields = <String>[];
    final groups = _groupFieldsByType(fields);

    // Add fields in priority order
    final priorityOrder = [
      'Voltage',
      'Current',
      'Power',
      'Energy',
      'Export',
      'Import',
      'Other',
    ];

    for (final groupName in priorityOrder) {
      if (groups.containsKey(groupName)) {
        orderedFields.addAll(groups[groupName]!);
      }
    }

    return orderedFields;
  }

  void _generateFieldColors(Set<String> fields) {
    // Define specific colors based on field names to match the image
    final specificColors = <String, Color>{
      'VoltagePhaseC': const Color(0xFF2196F3), // Blue
      'VoltagePhaseB': const Color(0xFF4CAF50), // Green
      'VoltagePhaseA': const Color(0xFFFF9800), // Orange
      'CurrentPhaseC': const Color(0xFF2196F3), // Blue
      'CurrentPhaseB': const Color(0xFF4CAF50), // Green
      'CurrentPhaseA': const Color(0xFFFF9800), // Orange
    };

    final defaultColors = [
      const Color(0xFF2196F3), // Blue
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFF9800), // Orange
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFFE91E63), // Pink
      const Color(0xFF607D8B), // Blue Grey
      const Color(0xFF795548), // Brown
    ];

    _fieldColors.clear();
    int colorIndex = 0;
    for (final field in fields) {
      if (specificColors.containsKey(field)) {
        _fieldColors[field] = specificColors[field]!;
      } else {
        _fieldColors[field] = defaultColors[colorIndex % defaultColors.length];
        colorIndex++;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state when switching to Graphs view
    if (widget.isLoading) {
      return AppCard(
        child: Container(
          height: 500,
          child: Center(
            child: AppLottieStateWidget.loading(lottieSize: 80),

            // CircularProgressIndicator(
            //   strokeWidth: 3,
            //   valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            // ),
          ),
        ),
      );
    }

    if (widget.data.isEmpty) {
      return _buildEmptyState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: AppSizes.spacing16),
                _buildFieldSelection(),
                const SizedBox(height: AppSizes.spacing16),
                _buildChart(),
                const SizedBox(height: AppSizes.spacing16),
                _buildSummaryCards(),
                const SizedBox(height: AppSizes.spacing24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return AppCard(
      child:
          //Row(
          // children: [
          //   Text(
          //     'Metrics Visualizationss',
          //     style: TextStyle(
          //       fontSize: AppSie,
          //       fontWeight: FontWeight.w700,
          //       color: AppColors.textPrimary,
          //     ),
          //   ),
          //   const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Chart Type Selector
              // Container(
              //   decoration: BoxDecoration(
              //     border: Border.all(color: AppColors.border),
              //     borderRadius: BorderRadius.circular(8),
              //   ),
              //   child: ModernChartTypeDropdown(
              //     selectedType: _selectedChartType,
              //     onChanged: (type) {
              //       setState(() {
              //         _selectedChartType = type;
              //       });
              //     },
              //   ),
              // ),
              const SizedBox(width: AppSizes.spacing12),
              // Export Button
              if (widget.onExport != null)
                IconButton(
                  onPressed: widget.onExport,
                  icon: const Icon(Icons.download),
                  tooltip: 'Export Chart',
                  style: IconButton.styleFrom(
                    backgroundColor: context.surfaceColor,
                    foregroundColor: context.textSecondaryColor,
                  ),
                ),
              const SizedBox(width: AppSizes.spacing8),
              // Refresh Button
              if (widget.onRefresh != null)
                ElevatedButton.icon(
                  onPressed: widget.isLoading ? null : widget.onRefresh,
                  icon: widget.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 16),
                  label: Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
            ],
            //   ),
            // ],
          ),
    );
  }

  Widget _buildEmptyState() {
    return AppCard(
      child: SizedBox(
        height: 400,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 64,
                color: context.textSecondaryColor,
              ),
              SizedBox(height: AppSizes.spacing16),
              Text(
                'No metrics data available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: context.textSecondaryColor,
                ),
              ),
              SizedBox(height: AppSizes.spacing8),
              Text(
                'Load data to view interactive charts and analytics',
                style: TextStyle(
                  fontSize: 14,
                  color: context.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldSelection() {
    final availableFields = _getAllFields();

    if (availableFields.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Chart Fields',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimaryColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _selectedFields.isEmpty
                      ? context.borderColor
                      : context.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedFields.isEmpty
                        ? context.borderColor
                        : context.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '${_selectedFields.length} selected',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: _selectedFields.isEmpty
                        ? context.textSecondaryColor
                        : context.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing8),
          Wrap(
            spacing: AppSizes.spacing6,
            runSpacing: AppSizes.spacing6,
            children: availableFields.map((field) {
              final isSelected = _selectedFields.contains(field);
              final color = _fieldColors[field] ?? context.primaryColor;

              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isSelected ? color : context.surfaceVariantColor,
                  border: Border.all(
                    color: isSelected ? color : context.borderColor,
                    width: 1,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedFields.remove(field);
                      } else {
                        _selectedFields.add(field);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatFieldName(field),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (_selectedFields.isEmpty) {
      return AppCard(
        child: Container(
          height: 350,
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.show_chart,
                  size: 48,
                  color: context.textSecondaryColor,
                ),
                SizedBox(height: AppSizes.spacing12),
                Text(
                  'Select metrics to display chart',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart header with legend
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Metrics Visualization',
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeMedium,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    Text(
                      'Total Points: ${_prepareChartData().length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              // PageSize input
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacing8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Points: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 32,
                      child: TextFormField(
                        controller: _pageSizeController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.spacing8,
                            vertical: AppSizes.spacing4,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(
                              color: context.borderColor,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(
                              color: context.borderColor,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(
                              color: context.primaryColor,
                              width: 2,
                            ),
                          ),
                          hintText: _pageSize == 0 ? 'All' : '${_pageSize}',
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: context.textSecondaryColor,
                          ),
                        ),
                        onChanged: (value) {
                          print(
                            'ModernMetricsChart: onChanged called with value: "$value"',
                          );
                          // Cancel previous timer
                          _pageSizeTimer?.cancel();

                          if (value.isNotEmpty) {
                            if (value.toLowerCase() == 'all') {
                              print(
                                'ModernMetricsChart: Setting pageSize to 0 (All)',
                              );
                              setState(() {
                                _pageSize = 0;
                              });
                              _triggerDelayedApiCall(0);
                            } else {
                              final int? newSize = int.tryParse(value);
                              print(
                                'ModernMetricsChart: Parsed value to: $newSize',
                              );
                              if (newSize != null && newSize > 0) {
                                print(
                                  'ModernMetricsChart: Valid pageSize, setting to: $newSize',
                                );
                                // Always allow any positive number - let the API handle the actual limits
                                setState(() {
                                  _pageSize = newSize;
                                });
                                _triggerDelayedApiCall(newSize);
                              } else {
                                print(
                                  'ModernMetricsChart: Invalid pageSize: $newSize',
                                );
                              }
                            }
                          } else {
                            print(
                              'ModernMetricsChart: Empty value, not triggering API',
                            );
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return null;
                          }
                          if (value.toLowerCase() == 'all') {
                            return null;
                          }
                          final int? size = int.tryParse(value);
                          if (size == null) {
                            return 'Invalid number';
                          }
                          if (size <= 0) {
                            return 'Must be > 0';
                          }
                          if (size > 10000) {
                            return 'Max: 10000';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              ModernChartTypeDropdown(
                selectedType: _selectedChartType,
                onChanged: (type) {
                  setState(() {
                    _selectedChartType = type;
                  });
                  _animationController.reset();
                  _animationController.forward();
                },
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing16),
          // Legend row
          if (_selectedFields.isNotEmpty)
            Wrap(
              spacing: AppSizes.spacing16,
              children: _selectedFields.map((field) {
                final color = _fieldColors[field] ?? context.primaryColor;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacing4),
                    Text(
                      _formatFieldName(field),
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          const SizedBox(height: AppSizes.spacing16),
          // Chart content with horizontal scrolling
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final chartData = _prepareChartData();
              final needsHorizontalScroll =
                  chartData.length >
                  20; // Reduced threshold for vertical timestamps

              return Container(
                height:
                    300, // Increased height to accommodate vertical timestamps
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  border: Border.all(color: context.borderColor),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  child: Stack(
                    children: [
                      // Main chart content with drag-to-scroll
                      needsHorizontalScroll
                          ? GestureDetector(
                              onPanUpdate: (details) {
                                // Enable drag-to-scroll horizontally
                                _horizontalScrollController.position.moveTo(
                                  _horizontalScrollController.offset -
                                      details.delta.dx,
                                );
                              },
                              child: SingleChildScrollView(
                                controller: _horizontalScrollController,
                                scrollDirection: Axis.horizontal,
                                physics: const ClampingScrollPhysics(),
                                child: SizedBox(
                                  width: math.max(
                                    MediaQuery.of(context).size.width - 40,
                                    chartData.length *
                                        15.0, // Optimized for vertical timestamps
                                  ),
                                  child: _buildChartContent(),
                                ),
                              ),
                            )
                          : _buildChartContent(),

                      // Loading overlay during filter transitions
                      if (_animation.status == AnimationStatus.forward)
                        AnimatedOpacity(
                          opacity: 1.0 - _animation.value,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            color: context.surfaceColor.withOpacity(0.8),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        context.primaryColor,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Updating chart...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: context.textSecondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChartContent() {
    final chartData = _prepareChartData();

    if (chartData.isEmpty) {
      return Center(
        child: Text(
          'No valid chart data available',
          style: TextStyle(fontSize: 14, color: context.textSecondaryColor),
        ),
      );
    }

    switch (_selectedChartType) {
      case ChartType.line:
        return _buildLineChart(chartData);
      case ChartType.bar:
        return _buildBarChart(chartData);
      case ChartType.area:
        return _buildAreaChart(chartData);
    }
  }

  Widget _buildLineChart(List<Map<String, dynamic>> data) {
    final spots = <String, List<FlSpot>>{};

    for (int i = 0; i < data.length; i++) {
      final record = data[i];
      for (final field in _selectedFields) {
        if (record[field] != null && record[field] is num) {
          spots.putIfAbsent(field, () => []);
          spots[field]!.add(FlSpot(i.toDouble(), record[field].toDouble()));
        }
      }
    }

    return SizedBox(
      height: 300,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: null,
              getDrawingHorizontalLine: (value) => FlLine(
                color: context.borderColor,
                strokeWidth: 1,
                dashArray: [3, 3],
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
                  reservedSize: 60, // Increased size for vertical text
                  interval: _calculateXAxisInterval(data.length),
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < data.length) {
                      final timestamp =
                          data[index]['Timestamp'] ?? data[index]['timestamp'];
                      return Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Transform.rotate(
                            angle: -1.5708, // -90 degrees in radians (π/2)
                            child: Text(
                              _formatEnhancedTimestamp(timestamp),
                              style: TextStyle(
                                fontSize: 10,
                                color: context.textSecondaryColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 55,
                  interval: _calculateYAxisInterval(data),
                  getTitlesWidget: (value, meta) {
                    return Text(
                      _formatNumber(value),
                      style: TextStyle(
                        fontSize: 10,
                        color: context.textSecondaryColor,
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            // Add these properties to ensure consistent chart area
            minX: 0,
            maxX: data.length > 1 ? (data.length - 1).toDouble() : 1,
            lineBarsData: spots.entries.map((entry) {
              final field = entry.key;
              final fieldSpots = entry.value;
              final color = _fieldColors[field] ?? context.primaryColor;

              return LineChartBarData(
                spots: fieldSpots,
                isCurved: true,
                curveSmoothness: 0.35,
                color: color,
                barWidth: 3,
                isStrokeCapRound: true,
                preventCurveOverShooting: true,
                dotData: FlDotData(
                  show: fieldSpots.length <= 15,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: color,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(show: false),
                shadow: Shadow(
                  color: color.withOpacity(0.2),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              );
            }).toList(),
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (touchedSpot) => Colors.black87,
                tooltipRoundedRadius: 8,
                tooltipPadding: const EdgeInsets.all(12),
                tooltipMargin: 8,
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots
                      .map((spot) {
                        final dataIndex = spot.x.toInt();
                        if (dataIndex >= 0 && dataIndex < data.length) {
                          final record = data[dataIndex];
                          final timestamp =
                              record['timestamp'] ?? record['Timestamp'];
                          final field = _selectedFields.elementAt(
                            spot.barIndex,
                          );
                          final color =
                              _fieldColors[field] ?? context.primaryColor;

                          return LineTooltipItem(
                            '${_formatFieldName(field)}\n',
                            TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            children: [
                              TextSpan(
                                text: '${_formatTableNumber(spot.y)}\n',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              TextSpan(
                                text: _formatFullTimestamp(timestamp),
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          );
                        }
                        return null;
                      })
                      .where((item) => item != null)
                      .cast<LineTooltipItem>()
                      .toList();
                },
              ),
              touchCallback:
                  (FlTouchEvent event, LineTouchResponse? touchResponse) {
                    // You can add haptic feedback or other interactions here
                  },
              handleBuiltInTouches: true,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> data) {
    // Group data by time intervals for better bar chart representation
    final groupedData = <int, Map<String, List<double>>>{};
    final intervalSize = math.max(
      1,
      (data.length / 200).ceil(),
    ); // Create ~20 groups

    for (int i = 0; i < data.length; i++) {
      final groupIndex = i ~/ intervalSize;
      final record = data[i];

      groupedData.putIfAbsent(groupIndex, () => {});

      for (final field in _selectedFields) {
        if (record[field] != null && record[field] is num) {
          groupedData[groupIndex]!.putIfAbsent(field, () => []);
          groupedData[groupIndex]![field]!.add(record[field].toDouble());
        }
      }
    }

    // Calculate averages for each group
    final barGroups = <BarChartGroupData>[];
    double maxY = 0;

    groupedData.forEach((groupIndex, fieldData) {
      final rods = <BarChartRodData>[];

      for (final field in _selectedFields) {
        final values = fieldData[field] ?? [];
        if (values.isNotEmpty) {
          final average = values.reduce((a, b) => a + b) / values.length;
          maxY = math.max(maxY, average);

          final color = _fieldColors[field] ?? context.primaryColor;

          rods.add(
            BarChartRodData(
              toY: average,
              color: color,
              width: 12,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          );
        }
      }

      if (rods.isNotEmpty) {
        barGroups.add(
          BarChartGroupData(x: groupIndex, barRods: rods, barsSpace: 4),
        );
      }
    });

    return SizedBox(
      height: 300,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY * 1.1,
            barGroups: barGroups,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => Colors.black87,
                tooltipRoundedRadius: 8,
                tooltipPadding: const EdgeInsets.all(12),
                tooltipMargin: 8,
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  if (rodIndex < _selectedFields.length) {
                    final field = _selectedFields.elementAt(rodIndex);
                    final startIndex = group.x * intervalSize;
                    final endIndex = math.min(
                      startIndex + intervalSize - 1,
                      data.length - 1,
                    );

                    String timeRange = '';
                    if (startIndex < data.length && endIndex < data.length) {
                      final startTime =
                          data[startIndex]['timestamp'] ??
                          data[startIndex]['Timestamp'];
                      final endTime =
                          data[endIndex]['timestamp'] ??
                          data[endIndex]['Timestamp'];
                      timeRange =
                          '\n${_formatEnhancedTimestamp(startTime)} - ${_formatEnhancedTimestamp(endTime)}';
                    }

                    return BarTooltipItem(
                      '${_formatFieldName(field)}\n${_formatTableNumber(rod.toY)}$timeRange',
                      TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    );
                  }
                  return null;
                },
              ),
              touchCallback:
                  (FlTouchEvent event, BarTouchResponse? touchResponse) {
                    // Ensure tooltip stays on top
                  },
              handleBuiltInTouches: true,
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
                  reservedSize: 60, // Increased size for vertical text
                  getTitlesWidget: (value, meta) {
                    final groupIndex = value.toInt();
                    final startIndex = groupIndex * intervalSize;
                    if (startIndex < data.length) {
                      final timestamp =
                          data[startIndex]['Timestamp'] ??
                          data[startIndex]['timestamp'];
                      return Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Transform.rotate(
                            angle: -1.5708, // -90 degrees in radians (π/2)
                            child: Text(
                              _formatEnhancedTimestamp(timestamp),
                              style: TextStyle(
                                fontSize: 10,
                                color: context.textSecondaryColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  interval: _calculateYAxisInterval(widget.data),
                  getTitlesWidget: (value, meta) {
                    return Text(
                      _formatNumber(value),
                      style: TextStyle(
                        fontSize: 10,
                        color: context.textSecondaryColor,
                      ),
                    );
                  },
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: null,
              getDrawingHorizontalLine: (value) => FlLine(
                color: context.borderColor.withOpacity(0.3),
                strokeWidth: 1,
                dashArray: [3, 3],
              ),
            ),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }

  Widget _buildAreaChart(List<Map<String, dynamic>> data) {
    final spots = <String, List<FlSpot>>{};

    for (int i = 0; i < data.length; i++) {
      final record = data[i];
      for (final field in _selectedFields) {
        if (record[field] != null && record[field] is num) {
          spots.putIfAbsent(field, () => []);
          spots[field]!.add(FlSpot(i.toDouble(), record[field].toDouble()));
        }
      }
    }

    return SizedBox(
      height: 320,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: null,
              getDrawingHorizontalLine: (value) => FlLine(
                color: context.borderColor.withOpacity(0.3),
                strokeWidth: 1,
                dashArray: [3, 3],
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
                  reservedSize: 60, // Increased size for vertical text
                  interval: _calculateXAxisInterval(data.length),
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < data.length) {
                      final timestamp =
                          data[index]['Timestamp'] ?? data[index]['timestamp'];
                      return Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Transform.rotate(
                            angle: -1.5708, // -90 degrees in radians (π/2)
                            child: Text(
                              _formatEnhancedTimestamp(timestamp),
                              style: TextStyle(
                                fontSize: 10,
                                color: context.textSecondaryColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 55, // Fixed from 10 to proper size
                  interval: _calculateYAxisInterval(widget.data),
                  getTitlesWidget: (value, meta) {
                    return Text(
                      _formatNumber(value),
                      style: TextStyle(
                        fontSize: 10,
                        color: context.textSecondaryColor,
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            // Add these properties to ensure consistent chart area
            minX: 0,
            maxX: data.length > 1 ? (data.length - 1).toDouble() : 1,
            lineBarsData: spots.entries.map((entry) {
              final field = entry.key;
              final fieldSpots = entry.value;
              final color = _fieldColors[field] ?? context.primaryColor;

              return LineChartBarData(
                spots: fieldSpots,
                isCurved: true,
                curveSmoothness: 0.35,
                color: color,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.4),
                      color.withOpacity(0.1),
                      color.withOpacity(0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                preventCurveOverShooting: true,
              );
            }).toList(),
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (touchedSpot) => Colors.black87,
                tooltipRoundedRadius: 8,
                tooltipPadding: const EdgeInsets.all(12),
                tooltipMargin: 8,
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots
                      .map((spot) {
                        final dataIndex = spot.x.toInt();
                        if (dataIndex >= 0 && dataIndex < data.length) {
                          final record = data[dataIndex];
                          final timestamp =
                              record['timestamp'] ?? record['Timestamp'];
                          final field = _selectedFields.elementAt(
                            spot.barIndex,
                          );
                          final color =
                              _fieldColors[field] ?? context.primaryColor;

                          return LineTooltipItem(
                            '${_formatFieldName(field)}\n',
                            TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            children: [
                              TextSpan(
                                text: '${_formatTableNumber(spot.y)}\n',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              TextSpan(
                                text: _formatFullTimestamp(timestamp),
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          );
                        }
                        return null;
                      })
                      .where((item) => item != null)
                      .cast<LineTooltipItem>()
                      .toList();
                },
              ),
              touchCallback:
                  (FlTouchEvent event, LineTouchResponse? touchResponse) {
                    // You can add haptic feedback or other interactions here
                  },
              handleBuiltInTouches: true,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    if (_selectedFields.isEmpty || widget.data.isEmpty) {
      return const SizedBox.shrink();
    }

    final stats = _calculateStats();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Metrics Summary',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.textPrimaryColor,
          ),
        ),
        const SizedBox(height: AppSizes.spacing16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: stats.entries.map((entry) {
              final field = entry.key;
              final fieldStats = entry.value;
              final color = _fieldColors[field] ?? context.primaryColor;

              return Container(
                margin: const EdgeInsets.only(right: AppSizes.spacing16),
                child: _buildSummaryCard(field, fieldStats, color),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String field,
    Map<String, double> stats,
    Color color,
  ) {
    // Get the icon for the field
    IconData fieldIcon = _getFieldIcon(field);

    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          AppSizes.shadowSmall,
          // BoxShadow(
          //   color:  Colors.black.withOpacity(0.04),
          //   blurRadius: 8,
          //   offset: const Offset(0, 2),
          // ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(fieldIcon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _formatFieldName(field),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Average (main value)
          Center(
            child: Column(
              children: [
                Text(
                  'Average',
                  style: TextStyle(
                    fontSize: 10,
                    color: context.textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatNumber(stats['avg'] ?? 0.0),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Min and Max row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Min',
                      style: TextStyle(
                        fontSize: 9,
                        color: context.textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _formatNumber(stats['min']),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Max',
                      style: TextStyle(
                        fontSize: 9,
                        color: context.textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _formatNumber(stats['max']),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Points count with yellow warning stripe (like in image)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.amber, width: 2)),
            ),
            child: Center(
              child: Text(
                '${(stats['count'] ?? 0.0).toInt()} points',
                style: TextStyle(
                  fontSize: 9,
                  color: context.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFieldIcon(String field) {
    final fieldLower = field.toLowerCase();
    if (fieldLower.contains('voltage')) {
      return Icons.electric_bolt;
    } else if (fieldLower.contains('current')) {
      return Icons.flash_on;
    } else if (fieldLower.contains('power')) {
      return Icons.power;
    } else if (fieldLower.contains('energy')) {
      return Icons.battery_charging_full;
    } else if (fieldLower.contains('frequency')) {
      return Icons.graphic_eq;
    } else if (fieldLower.contains('temperature')) {
      return Icons.thermostat;
    }
    return Icons.analytics;
  }

  // Helper methods
  Set<String> _getAllFields() {
    if (widget.data.isEmpty) return {};

    final fields = <String>{};

    // Scan all records to ensure we capture all possible fields
    // Some fields might be null in some records but present in others
    for (final record in widget.data) {
      record.forEach((key, value) {
        if (key.toLowerCase() != 'timestamp' &&
            key.toLowerCase() != 'date' &&
            value != null &&
            value is num &&
            !value.isNaN &&
            value.isFinite) {
          fields.add(key);
        }
      });
    }

    // If no fields found with the strict validation, fall back to more lenient check
    if (fields.isEmpty) {
      for (final record in widget.data) {
        record.forEach((key, value) {
          if (key.toLowerCase() != 'timestamp' &&
              key.toLowerCase() != 'date' &&
              value != null &&
              value is num) {
            fields.add(key);
          }
        });
      }
    }

    return fields;
  }

  String _formatFieldName(String fieldName) {
    return fieldName
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .trim()
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : '',
        )
        .join(' ');
  }

  String _formatNumber(double? value) {
    if (value == null) return '0';
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else if (value == value.toInt()) {
      return value.toInt().toString();
    } else {
      return value.toStringAsFixed(2);
    }
  }

  String _formatTableNumber(double? value) {
    if (value == null) return '0.00';

    // Format with thousands separators like: 22,344,443.30
    final formatter = value.toStringAsFixed(2);
    final parts = formatter.split('.');
    final wholePart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '00';

    // Add commas for thousands separators
    final regex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formattedWhole = wholePart.replaceAllMapped(
      regex,
      (Match m) => '${m[1]},',
    );

    return '$formattedWhole.$decimalPart';
  }

  String _formatFullTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';

    try {
      DateTime date;
      if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else {
        return timestamp.toString();
      }

      // Format as: 2025-08-13T01:00:00 +00:00
      final year = date.year;
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      return '$year-$month-${day}T$hour:$minute:00\n+00:00';
    } catch (e) {
      return timestamp.toString();
    }
  }

  String _formatEnhancedTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';

    try {
      DateTime date;
      if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else {
        return timestamp.toString();
      }

      // Format as "Aug/15 05:00" - month abbreviation, day, 24h time
      final monthNames = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final month = monthNames[date.month];
      final day = date.day.toString().padLeft(2, '0');
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$month/$day $hour:$minute';
    } catch (e) {
      return timestamp.toString();
    }
  }

  double _calculateXAxisInterval(int dataLength) {
    // Always show ALL timestamps from API - return 1.0 to display every data point
    return 1.0;
  }

  double _calculateYAxisInterval(List<Map<String, dynamic>> data) {
    if (data.isEmpty || _selectedFields.isEmpty) return 1.0;

    // Find min and max values across all selected fields
    double minValue = double.infinity;
    double maxValue = double.negativeInfinity;

    for (final record in data) {
      for (final field in _selectedFields) {
        final value = record[field];
        if (value != null && value is num && !value.isNaN && value.isFinite) {
          final doubleValue = value.toDouble();
          minValue = math.min(minValue, doubleValue);
          maxValue = math.max(maxValue, doubleValue);
        }
      }
    }

    if (minValue == double.infinity || maxValue == double.negativeInfinity) {
      return 1.0;
    }

    final range = maxValue - minValue;
    if (range == 0) return 1.0;

    // Calculate interval to prevent duplicates - ensure minimum 5 distinct labels
    final targetLabels = 5;
    final rawInterval = range / targetLabels;

    // Round to a nice number that ensures no duplicates
    final orderOfMagnitude = math.pow(
      10,
      (math.log(rawInterval) / math.ln10).floor(),
    );
    final normalizedInterval = rawInterval / orderOfMagnitude;

    double niceInterval;
    if (normalizedInterval <= 1) {
      niceInterval = 1;
    } else if (normalizedInterval <= 2) {
      niceInterval = 2;
    } else if (normalizedInterval <= 5) {
      niceInterval = 5;
    } else {
      niceInterval = 10;
    }

    final finalInterval = niceInterval * orderOfMagnitude;

    // Ensure minimum interval to prevent duplicates
    return math.max(finalInterval, range / 10);
  }

  List<Map<String, dynamic>> _prepareChartData() {
    // Filter data to only include records that have valid numeric data for selected fields
    final allData = widget.data.where((record) {
      // Check if at least one of the selected fields has valid numeric data in this record
      return _selectedFields.any((field) {
        final value = record[field];
        return value != null && value is num && !value.isNaN && value.isFinite;
      });
    }).toList();

    // Apply PageSize limit if specified (0 means get all)
    if (_pageSize > 0 && _pageSize < allData.length) {
      return allData.take(_pageSize).toList();
    }

    return allData;
  }

  // Helper method for separate DateTime axis container

  Map<String, Map<String, double>> _calculateStats() {
    final stats = <String, Map<String, double>>{};

    for (final field in _selectedFields) {
      final values = <double>[];
      for (final record in widget.data) {
        final value = record[field];
        if (value != null && value is num && !value.isNaN && value.isFinite) {
          values.add(value.toDouble());
        }
      }

      if (values.isNotEmpty) {
        values.sort();
        final min = values.first;
        final max = values.last;
        final avg = values.reduce((a, b) => a + b) / values.length;

        stats[field] = {
          'min': min,
          'max': max,
          'avg': avg,
          'count': values.length.toDouble(),
        };
      }
    }

    return stats;
  }
}
