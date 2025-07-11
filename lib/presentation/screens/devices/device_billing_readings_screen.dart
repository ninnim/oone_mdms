import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/models/device.dart';
import '../../../core/services/device_service.dart';
import '../../../core/services/api_service.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/results_pagination.dart';
import '../../widgets/common/blunest_data_table.dart';

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
    _deviceService = DeviceService(ApiService());
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
        widget.device.id,
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
                ? const Center(child: CircularProgressIndicator())
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
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Billing Period Info
                        AppCard(
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
                        const SizedBox(height: 24),

                        // Content based on view toggle
                        if (_isTableView)
                          _buildTableView()
                        else
                          _buildGraphView(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewToggleButton(
            icon: Icons.table_chart,
            label: 'Table',
            isActive: _isTableView,
            onTap: () {
              setState(() {
                _isTableView = true;
              });
            },
          ),
          _buildViewToggleButton(
            icon: Icons.bar_chart,
            label: 'Graph',
            isActive: !_isTableView,
            onTap: () {
              setState(() {
                _isTableView = false;
              });
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? const Color(0xFF2563eb)
                  : const Color(0xFF64748b),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isActive
                    ? const Color(0xFF2563eb)
                    : const Color(0xFF64748b),
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

        // Table using BluNestDataTable
        SizedBox(
          height: 500,
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
          'Billing Readings Chart',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1e293b),
          ),
        ),
        const SizedBox(height: 16),

        AppCard(
          child: Container(
            height: 400,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Accumulative Value Over Time',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1e293b),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        getDrawingHorizontalLine: (value) {
                          return const FlLine(
                            color: Color(0xFFE2E8F0),
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return const FlLine(
                            color: Color(0xFFE2E8F0),
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
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              if (value.toInt() >= 0 &&
                                  value.toInt() < readings.length) {
                                final reading = readings[value.toInt()];
                                final date = DateTime.tryParse(
                                  reading['BillingDate'] ?? '',
                                );
                                if (date != null) {
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    child: Text(
                                      DateFormat('MM/dd').format(date),
                                      style: const TextStyle(
                                        color: Color(0xFF64748b),
                                        fontSize: 12,
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
                                value.toInt().toString(),
                                style: const TextStyle(
                                  color: Color(0xFF64748b),
                                  fontSize: 12,
                                ),
                              );
                            },
                            reservedSize: 42,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                                  reading['AccumulativeValue']?.toString() ??
                                      '0',
                                ) ??
                                0;
                            return FlSpot(index.toDouble(), value);
                          }).toList(),
                          isCurved: true,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563eb), Color(0xFF3b82f6)],
                          ),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF2563eb).withOpacity(0.3),
                                const Color(0xFF2563eb).withOpacity(0.1),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
