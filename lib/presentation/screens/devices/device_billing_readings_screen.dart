import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/models/device.dart';
import '../../../core/services/device_service.dart';
import '../../../core/services/service_locator.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/results_pagination.dart';
import '../../widgets/common/blunest_data_table.dart';
import '../../widgets/common/app_lottie_state_widget.dart';

class DeviceBillingReadingsScreen extends StatefulWidget {
  final Device device;
  final Map<String, dynamic> billingRecord;
  final VoidCallback? onBack;

  const DeviceBillingReadingsScreen({
    super.key,
    required this.device,
    required this.billingRecord,
    this.onBack,
  });

  @override
  State<DeviceBillingReadingsScreen> createState() =>
      _DeviceBillingReadingsScreenState();
}

class _DeviceBillingReadingsScreenState
    extends State<DeviceBillingReadingsScreen> {
  late DeviceService _deviceService;
  Map<String, dynamic>? _billingReadings;
  bool _isLoading = true;
  String? _error;

  // View state
  bool _isTableView = true; // true for table, false for graph
  int _currentPage = 1;
  int _itemsPerPage = 10;
  String? _sortBy;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();

    // Use ServiceLocator to get properly configured API service
    final serviceLocator = ServiceLocator();
    final apiService = serviceLocator.apiService;
    _deviceService = DeviceService(apiService);
    _loadBillingReadings();
  }

  Future<void> _loadBillingReadings() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final startTime =
          widget.billingRecord['StartTime'] ?? '2024-01-01T00:00:00.000+07';
      final endTime =
          widget.billingRecord['EndTime'] ?? '2024-12-31T23:59:59.999+07';

      final response = await _deviceService.getDeviceBillingReadings(
        widget.device.id ?? '',
        startTime: startTime,
        endTime: endTime,
      );

      if (response.success) {
        _billingReadings = response.data;
      } else {
        _error = response.message;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load billing readings: $e';
        _isLoading = false;
      });
    }
  }

  void _handleSort(String key, bool ascending) {
    setState(() {
      _sortBy = key;
      _sortAscending = ascending;
    });
  }

  void _exportReadings() {
    // TODO: Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE1E5E9), width: 1),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // if (widget.onBack != null) ...[
                    //   IconButton(
                    //     icon: const Icon(Icons.arrow_back),
                    //     onPressed: widget.onBack,
                    //     tooltip: 'Back to Device Details',
                    //   ),
                    //   const SizedBox(width: 16),
                    // ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Device Billing Readings',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1e293b),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Device: ${widget.device.serialNumber}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF64748b),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // View Toggle - Button style like metrics
                    _buildViewToggle(),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563eb),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: IconButton(
                        onPressed: _loadBillingReadings,
                        icon: const Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 18,
                        ),
                        tooltip: 'Refresh Data',
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF64748b),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: IconButton(
                        onPressed: _exportReadings,
                        icon: const Icon(
                          Icons.download,
                          color: Colors.white,
                          size: 18,
                        ),
                        tooltip: 'Export Readings',
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content section
          Expanded(
            child: _isLoading
                ? AppLottieStateWidget.loading(
                    title: 'Loading Billing Readings',
                    message: 'Please wait while we load the billing readings.',
                    lottieSize: 80,
                  )
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Color(0xFFef4444),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFFef4444),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadBillingReadings,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Billing Period Info - Sticky Header
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFFE1E5E9),
                              width: 1,
                            ),
                          ),
                        ),
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Billing Period Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1e293b),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildInfoRow(
                                'Device ID',
                                widget.billingRecord['DeviceId'] ?? 'N/A',
                              ),
                              _buildInfoRow(
                                'Start Time',
                                widget.billingRecord['StartTime'] ?? 'N/A',
                              ),
                              _buildInfoRow(
                                'End Time',
                                widget.billingRecord['EndTime'] ?? 'N/A',
                              ),
                              if (widget.billingRecord['TimeOfUse'] != null)
                                _buildInfoRow(
                                  'Time of Use',
                                  widget.billingRecord['TimeOfUse']['Name'] ??
                                      'N/A',
                                ),
                            ],
                          ),
                        ),
                      ),
                      // Scrollable content area
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: _isTableView
                              ? _buildTableView()
                              : SingleChildScrollView(child: _buildGraphView()),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      height: 40, // AppSizes.buttonHeightSmall equivalent
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          8,
        ), // AppSizes.radiusMedium equivalent
        color: const Color(0xFFF1F5F9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewToggleButton(
            icon: Icons.table_chart,
            label: 'Table',
            isActive: _isTableView,
            onTap: () {
              print('Switching to TABLE view');
              setState(() => _isTableView = true);
            },
          ),
          _buildViewToggleButton(
            icon: Icons.bar_chart,
            label: 'Graph',
            isActive: !_isTableView,
            onTap: () {
              print('Switching to GRAPH view');
              setState(() => _isTableView = false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        print(
          'Toggle button tapped: $label, isActive: $isActive, switching to: ${!isActive}',
        );
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(8), // AppSizes.spacing8 equivalent
        constraints: const BoxConstraints(
          minWidth: 32, // AppSizes.spacing32 equivalent
          minHeight: 32, // AppSizes.spacing32 equivalent
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            8,
          ), // AppSizes.radiusMedium equivalent
          color: isActive ? const Color(0xFF2563eb) : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16, // AppSizes.iconSmall equivalent
              color: isActive ? Colors.white : const Color(0xFF64748b),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14, // AppSizes.fontSizeSmall equivalent
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : const Color(0xFF64748b),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableView() {
    if (_billingReadings == null ||
        _billingReadings!['DeviceReadings'] == null ||
        (_billingReadings!['DeviceReadings'] as List).isEmpty) {
      return const AppCard(
        child: Center(
          child: Text(
            'No billing readings data available for this period',
            style: TextStyle(fontSize: 16, color: Color(0xFF64748b)),
          ),
        ),
      );
    }

    List<dynamic> readings = _billingReadings!['DeviceReadings'] as List;

    // Convert to Map<String, dynamic> for compatibility
    final convertedReadings = readings
        .map((reading) => reading as Map<String, dynamic>)
        .toList();

    // Apply sorting
    if (_sortBy != null) {
      convertedReadings.sort((a, b) {
        dynamic aValue = a[_sortBy!];
        dynamic bValue = b[_sortBy!];

        // Handle DateTime sorting
        if (_sortBy == 'BillingDate' ||
            _sortBy == 'StartTime' ||
            _sortBy == 'EndTime') {
          aValue =
              DateTime.tryParse(aValue?.toString() ?? '') ?? DateTime.now();
          bValue =
              DateTime.tryParse(bValue?.toString() ?? '') ?? DateTime.now();
        }

        final comparison = aValue.toString().compareTo(bValue.toString());
        return _sortAscending ? comparison : -comparison;
      });
    }

    // Calculate pagination
    final totalItems = convertedReadings.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
    final paginatedReadings = convertedReadings.sublist(startIndex, endIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Billing Readings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1e293b),
          ),
        ),
        const SizedBox(height: 16),

        // Table using BluNestDataTable with sticky headers
        Expanded(
          child: BluNestDataTable<Map<String, dynamic>>(
            data: paginatedReadings,
            columns: _getBillingReadingsColumns(),
            sortBy: _sortBy,
            sortAscending: _sortAscending,
            onSort: _handleSort,
          ),
        ),

        const SizedBox(height: 16),

        // Pagination controls
        _buildPagination(totalPages, totalItems),
      ],
    );
  }

  Widget _buildGraphView() {
    if (_billingReadings == null ||
        _billingReadings!['DeviceReadings'] == null ||
        (_billingReadings!['DeviceReadings'] as List).isEmpty) {
      return const AppCard(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart, size: 64, color: Color(0xFF64748b)),
              SizedBox(height: 16),
              Text(
                'No billing readings data available for graphing',
                style: TextStyle(fontSize: 16, color: Color(0xFF64748b)),
              ),
              SizedBox(height: 8),
              Text(
                'Try refreshing the data or check billing records',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748b)),
              ),
            ],
          ),
        ),
      );
    }

    List<dynamic> readings = _billingReadings!['DeviceReadings'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Billing Analytics Dashboard',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1e293b),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Interactive analysis of accumulative values and consumption patterns',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),

        // Analytics Summary Cards
        _buildAnalyticsSummaryCards(readings),
        const SizedBox(height: 24),

        // Main Chart with Multiple Views
        _buildModernAnalyticsChart(readings),
        const SizedBox(height: 24),

        // Consumption Analysis Grid
        _buildConsumptionAnalysisGrid(readings),
      ],
    );
  }

  Widget _buildAnalyticsSummaryCards(List<dynamic> readings) {
    final values = readings
        .map(
          (r) =>
              double.tryParse(r['AccumulativeValue']?.toString() ?? '0') ?? 0,
        )
        .toList();

    if (values.isEmpty) return const SizedBox.shrink();

    final totalConsumption = values.isNotEmpty ? values.last : 0;
    final avgDailyConsumption = values.length > 1
        ? totalConsumption / values.length
        : 0;
    final peakConsumption = values.isNotEmpty
        ? values.reduce((a, b) => a > b ? a : b)
        : 0;
    final growthRate = values.length >= 2
        ? ((values.last - values.first) / values.first * 100)
        : 0;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Consumption',
            '${totalConsumption.toStringAsFixed(2)} kWh',
            Icons.bolt,
            const Color(0xFF2563eb),
            '${((totalConsumption / 1000) * 0.12).toStringAsFixed(2)} USD',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Avg Daily',
            '${avgDailyConsumption.toStringAsFixed(2)} kWh',
            Icons.trending_up,
            const Color(0xFF10b981),
            '${readings.length} days',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Peak Reading',
            '${peakConsumption.toStringAsFixed(2)} kWh',
            Icons.flash_on,
            const Color(0xFFf59e0b),
            'Highest value',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Growth Rate',
            '${growthRate.toStringAsFixed(1)}%',
            growthRate >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
            growthRate >= 0 ? const Color(0xFF10b981) : const Color(0xFFef4444),
            'Period trend',
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748b),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Color(0xFF94a3b8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAnalyticsChart(List<dynamic> readings) {
    return AppCard(
      child: Container(
        height: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Accumulative Consumption Trend',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1e293b),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Daily consumption accumulation over time',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748b)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563eb).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF2563eb).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563eb),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'kWh',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2563eb),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: null,
                    verticalInterval: null,
                    getDrawingHorizontalLine: (value) {
                      return const FlLine(
                        color: Color(0xFFf1f5f9),
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return const FlLine(
                        color: Color(0xFFf1f5f9),
                        strokeWidth: 1,
                      );
                    },
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
                        reservedSize: 40,
                        interval: readings.length > 10
                            ? (readings.length / 5).ceilToDouble()
                            : 1,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < readings.length) {
                            final reading = readings[value.toInt()];
                            final date = DateTime.tryParse(
                              reading['BillingDate'] ?? '',
                            );
                            if (date != null) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  DateFormat('MMM d').format(date),
                                  style: const TextStyle(
                                    color: Color(0xFF64748b),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: null,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            '${(value / 1000).toStringAsFixed(1)}k',
                            style: const TextStyle(
                              color: Color(0xFF64748b),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                        reservedSize: 50,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: const Color(0xFFe2e8f0),
                      width: 1,
                    ),
                  ),
                  minX: 0,
                  maxX: (readings.length - 1).toDouble(),
                  minY: 0,
                  maxY:
                      readings
                          .map(
                            (r) =>
                                double.tryParse(
                                  r['AccumulativeValue']?.toString() ?? '0',
                                ) ??
                                0,
                          )
                          .reduce((a, b) => a > b ? a : b) *
                      1.1,
                  lineBarsData: [
                    LineChartBarData(
                      spots: readings.asMap().entries.map((entry) {
                        final index = entry.key;
                        final reading = entry.value;
                        final value =
                            double.tryParse(
                              reading['AccumulativeValue']?.toString() ?? '0',
                            ) ??
                            0;
                        return FlSpot(index.toDouble(), value);
                      }).toList(),
                      isCurved: true,
                      curveSmoothness: 0.3,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563eb), Color(0xFF3b82f6)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: const Color(0xFF2563eb),
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF2563eb).withOpacity(0.3),
                            const Color(0xFF2563eb).withOpacity(0.1),
                            const Color(0xFF2563eb).withOpacity(0.05),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                        return touchedBarSpots
                            .map((barSpot) {
                              final index = barSpot.x.toInt();
                              if (index >= 0 && index < readings.length) {
                                final reading = readings[index];
                                final date = DateTime.tryParse(
                                  reading['BillingDate'] ?? '',
                                );
                                final dateStr = date != null
                                    ? DateFormat('MMM d, y').format(date)
                                    : 'Unknown date';
                                return LineTooltipItem(
                                  '$dateStr\n${barSpot.y.toStringAsFixed(2)} kWh',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              }
                              return null;
                            })
                            .where((item) => item != null)
                            .cast<LineTooltipItem>()
                            .toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsumptionAnalysisGrid(List<dynamic> readings) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _buildDailyConsumptionChart(readings)),
        const SizedBox(width: 16),
        Expanded(flex: 1, child: _buildConsumptionInsights(readings)),
      ],
    );
  }

  Widget _buildDailyConsumptionChart(List<dynamic> readings) {
    // Calculate daily consumption differences
    final dailyConsumption = <double>[];
    for (int i = 1; i < readings.length; i++) {
      final current =
          double.tryParse(
            readings[i]['AccumulativeValue']?.toString() ?? '0',
          ) ??
          0;
      final previous =
          double.tryParse(
            readings[i - 1]['AccumulativeValue']?.toString() ?? '0',
          ) ??
          0;
      dailyConsumption.add(current - previous);
    }

    return AppCard(
      child: Container(
        height: 300,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Consumption Pattern',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1e293b),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Daily usage variations and patterns',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: dailyConsumption.isNotEmpty
                      ? dailyConsumption.reduce((a, b) => a > b ? a : b) * 1.2
                      : 100,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final value = rod.toY;
                        return BarTooltipItem(
                          '${value.toStringAsFixed(2)} kWh',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
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
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < dailyConsumption.length) {
                            return Text(
                              'D${index + 1}',
                              style: const TextStyle(
                                color: Color(0xFF64748b),
                                fontSize: 10,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            value.toStringAsFixed(0),
                            style: const TextStyle(
                              color: Color(0xFF64748b),
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: dailyConsumption.asMap().entries.map((entry) {
                    final index = entry.key;
                    final value = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: value,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF10b981).withOpacity(0.8),
                              const Color(0xFF10b981),
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: 16,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: null,
                    getDrawingHorizontalLine: (value) {
                      return const FlLine(
                        color: Color(0xFFf1f5f9),
                        strokeWidth: 1,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsumptionInsights(List<dynamic> readings) {
    final values = readings
        .map(
          (r) =>
              double.tryParse(r['AccumulativeValue']?.toString() ?? '0') ?? 0,
        )
        .toList();

    if (values.isEmpty) {
      return const AppCard(child: Center(child: Text('No insights available')));
    }

    // Calculate insights
    final totalConsumption = values.last;
    final avgDailyConsumption = values.length > 1
        ? totalConsumption / values.length
        : 0;
    final peakDay = _findPeakConsumptionDay(readings);
    final efficiency = _calculateEfficiencyScore(readings);

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Consumption Insights',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1e293b),
              ),
            ),
            const SizedBox(height: 16),

            _buildInsightItem(
              'Peak Consumption Day',
              peakDay['date'] ?? 'N/A',
              '${peakDay['value']} kWh',
              Icons.trending_up,
              const Color(0xFFf59e0b),
            ),
            const SizedBox(height: 16),

            _buildInsightItem(
              'Efficiency Score',
              '${efficiency.toStringAsFixed(0)}/100',
              efficiency >= 75
                  ? 'Excellent'
                  : efficiency >= 50
                  ? 'Good'
                  : 'Needs Improvement',
              Icons.eco,
              efficiency >= 75
                  ? const Color(0xFF10b981)
                  : efficiency >= 50
                  ? const Color(0xFFf59e0b)
                  : const Color(0xFFef4444),
            ),
            const SizedBox(height: 16),

            _buildInsightItem(
              'Consumption Pattern',
              _getConsumptionPattern(readings),
              'Based on trend analysis',
              Icons.analytics,
              const Color(0xFF2563eb),
            ),
            const SizedBox(height: 16),

            _buildInsightItem(
              'Forecast Next Week',
              '${(avgDailyConsumption * 7).toStringAsFixed(1)} kWh',
              'Estimated usage',
              Icons.schedule,
              const Color(0xFF8b5cf6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748b),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94a3b8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _findPeakConsumptionDay(List<dynamic> readings) {
    if (readings.length < 2) return {'date': 'N/A', 'value': '0'};

    double maxDailyConsumption = 0;
    String peakDate = '';

    for (int i = 1; i < readings.length; i++) {
      final current =
          double.tryParse(
            readings[i]['AccumulativeValue']?.toString() ?? '0',
          ) ??
          0;
      final previous =
          double.tryParse(
            readings[i - 1]['AccumulativeValue']?.toString() ?? '0',
          ) ??
          0;
      final dailyConsumption = current - previous;

      if (dailyConsumption > maxDailyConsumption) {
        maxDailyConsumption = dailyConsumption;
        final date = DateTime.tryParse(readings[i]['BillingDate'] ?? '');
        peakDate = date != null ? DateFormat('MMM d').format(date) : 'Unknown';
      }
    }

    return {'date': peakDate, 'value': maxDailyConsumption.toStringAsFixed(1)};
  }

  num _calculateEfficiencyScore(List<dynamic> readings) {
    if (readings.length < 3) return 50;

    final values = readings
        .map(
          (r) =>
              double.tryParse(r['AccumulativeValue']?.toString() ?? '0') ?? 0,
        )
        .toList();

    // Calculate variance in daily consumption
    final dailyConsumption = <double>[];
    for (int i = 1; i < values.length; i++) {
      dailyConsumption.add(values[i] - values[i - 1]);
    }

    if (dailyConsumption.isEmpty) return 50;

    final mean =
        dailyConsumption.reduce((a, b) => a + b) / dailyConsumption.length;
    final variance =
        dailyConsumption
            .map((x) => (x - mean) * (x - mean))
            .reduce((a, b) => a + b) /
        dailyConsumption.length;

    // Lower variance = higher efficiency score
    final normalizedVariance = (variance / mean).abs();
    final score = (100 - (normalizedVariance * 100)).clamp(0, 100);

    return score;
  }

  String _getConsumptionPattern(List<dynamic> readings) {
    if (readings.length < 3) return 'Insufficient data';

    final values = readings
        .map(
          (r) =>
              double.tryParse(r['AccumulativeValue']?.toString() ?? '0') ?? 0,
        )
        .toList();

    final firstHalf = values.sublist(0, values.length ~/ 2);
    final secondHalf = values.sublist(values.length ~/ 2);

    final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;

    if (secondAvg > firstAvg * 1.1) {
      return 'Increasing';
    } else if (secondAvg < firstAvg * 0.9) {
      return 'Decreasing';
    } else {
      return 'Stable';
    }
  }

  List<BluNestTableColumn<Map<String, dynamic>>> _getBillingReadingsColumns() {
    return [
      // No. (Row Number)
      BluNestTableColumn<Map<String, dynamic>>(
        key: 'no',
        title: 'No.',
        flex: 1,
        sortable: false,
        builder: (reading) {
          return Container(
            child: Text(
              '${(_currentPage - 1) * _itemsPerPage + 1}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
          );
        },
      ),

      // Billing Date
      BluNestTableColumn<Map<String, dynamic>>(
        key: 'BillingDate',
        title: 'Billing Date',
        flex: 2,
        sortable: true,
        builder: (reading) => Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            _formatTimestamp(reading['BillingDate']),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1e293b),
            ),
          ),
        ),
      ),

      // Accumulative Value
      BluNestTableColumn<Map<String, dynamic>>(
        key: 'AccumulativeValue',
        title: 'Accumulative Value',
        flex: 2,
        sortable: true,
        builder: (reading) => Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            reading['AccumulativeValue']?.toString() ?? 'N/A',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1e293b),
            ),
          ),
        ),
      ),

      // Start Time
      BluNestTableColumn<Map<String, dynamic>>(
        key: 'StartTime',
        title: 'Start Time',
        flex: 2,
        sortable: true,
        builder: (reading) => Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            _formatTimestamp(reading['StartTime']),
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748b)),
          ),
        ),
      ),

      // End Time
      BluNestTableColumn<Map<String, dynamic>>(
        key: 'EndTime',
        title: 'End Time',
        flex: 2,
        sortable: true,
        builder: (reading) => Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            _formatTimestamp(reading['EndTime']),
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748b)),
          ),
        ),
      ),

      // Time of Use
      BluNestTableColumn<Map<String, dynamic>>(
        key: 'TimeOfUse',
        title: 'Time of Use',
        flex: 2,
        sortable: false,
        builder: (reading) => Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            reading['TimeOfUse']?['Name'] ?? 'N/A',
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748b)),
          ),
        ),
      ),

      // Units
      BluNestTableColumn<Map<String, dynamic>>(
        key: 'Units',
        title: 'Units',
        flex: 1,
        sortable: false,
        builder: (reading) => Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            reading['MetricLabels']?['Units'] ?? 'N/A',
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748b)),
          ),
        ),
      ),

      // Phase
      BluNestTableColumn<Map<String, dynamic>>(
        key: 'Phase',
        title: 'Phase',
        flex: 1,
        sortable: false,
        builder: (reading) => Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            reading['MetricLabels']?['Phase'] ?? 'N/A',
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748b)),
          ),
        ),
      ),

      // Flow Direction
      BluNestTableColumn<Map<String, dynamic>>(
        key: 'FlowDirection',
        title: 'Flow Direction',
        flex: 2,
        sortable: false,
        builder: (reading) => Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            reading['MetricLabels']?['FlowDirection'] ?? 'N/A',
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748b)),
          ),
        ),
      ),
    ];
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    try {
      final date = DateTime.parse(timestamp.toString());
      return DateFormat('MMM d, y HH:mm').format(date);
    } catch (e) {
      return timestamp.toString();
    }
  }

  Widget _buildPagination(int totalPages, int totalItems) {
    final startItem = (_currentPage - 1) * _itemsPerPage + 1;
    final endItem = (_currentPage * _itemsPerPage) > totalItems
        ? totalItems
        : _currentPage * _itemsPerPage;

    return ResultsPagination(
      currentPage: _currentPage,
      totalPages: totalPages,
      totalItems: totalItems,
      itemsPerPage: _itemsPerPage,
      startItem: startItem,
      endItem: endItem,
      onPageChanged: (page) {
        setState(() {
          _currentPage = page;
        });
      },
      onItemsPerPageChanged: (newItemsPerPage) {
        setState(() {
          _itemsPerPage = newItemsPerPage;
          _currentPage = 1; // Reset to first page
        });
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748b),
              ),
            ),
          ),
          const Text(': ', style: TextStyle(color: Color(0xFF64748b))),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1e293b)),
            ),
          ),
        ],
      ),
    );
  }
}
