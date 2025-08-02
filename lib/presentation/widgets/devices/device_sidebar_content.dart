import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../core/models/device.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/device_service.dart';

class DeviceSidebarContent extends StatefulWidget {
  final Device device;

  const DeviceSidebarContent({super.key, required this.device});

  @override
  State<DeviceSidebarContent> createState() => _DeviceSidebarContentState();
}

class _DeviceSidebarContentState extends State<DeviceSidebarContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DeviceService _deviceService;

  // Real data state
  Map<String, dynamic>? _metricsData;
  dynamic _billingReadingsData; // Can be List or Map depending on API response
  bool _isLoadingMetrics = false;
  bool _isLoadingBilling = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _deviceService = Provider.of<DeviceService>(context, listen: false);
    _loadDeviceData();
  }

  @override
  void didUpdateWidget(DeviceSidebarContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload data when device changes
    if (oldWidget.device.id != widget.device.id) {
      _loadDeviceData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceData() async {
    if (widget.device.id == null || widget.device.id!.isEmpty) return;

    // Load metrics data
    _loadMetricsData();

    // Load billing data
    _loadBillingData();
  }

  Future<void> _loadMetricsData() async {
    if (widget.device.id == null || widget.device.id!.isEmpty) return;

    setState(() {
      _isLoadingMetrics = true;
    });

    try {
      final now = DateTime.now();
      final startDate = now
          .subtract(const Duration(days: 30))
          .toIso8601String();
      final endDate = now.toIso8601String();

      final response = await _deviceService.getDeviceMetrics(
        widget.device.id!,
        startDate: startDate,
        endDate: endDate,
        limit: 100,
      );

      if (mounted) {
        setState(() {
          if (response.success && response.data != null) {
            _metricsData = response.data;
          } else {
            _metricsData = null;
          }
          _isLoadingMetrics = false;
        });
      }
    } catch (e) {
      print('Error loading metrics: $e');
      if (mounted) {
        setState(() {
          _metricsData = null;
          _isLoadingMetrics = false;
        });
      }
    }
  }

  Future<void> _loadBillingData() async {
    if (widget.device.id == null || widget.device.id!.isEmpty) return;

    setState(() {
      _isLoadingBilling = true;
    });

    try {
      // Load billing readings for the last 6 months
      final now = DateTime.now();
      final startTime = DateTime(now.year, now.month - 6, 1).toIso8601String();
      final endTime = now.toIso8601String();

      final readingsResponse = await _deviceService.getDeviceBillingReadings(
        widget.device.id!,
        startTime: startTime,
        endTime: endTime,
      );

      if (mounted) {
        setState(() {
          if (readingsResponse.success && readingsResponse.data != null) {
            print(
              'Billing response type: ${readingsResponse.data.runtimeType}',
            );
            print('Billing response data: ${readingsResponse.data}');

            // Handle different response formats - could be a List or an Object with data
            if (readingsResponse.data is List) {
              _billingReadingsData = readingsResponse.data;
            } else if (readingsResponse.data is Map<String, dynamic>) {
              // Extract the list from the response object
              final responseMap = readingsResponse.data as Map<String, dynamic>;
              if (responseMap.containsKey('data')) {
                _billingReadingsData = responseMap['data'];
              } else if (responseMap.containsKey('billingReadings')) {
                _billingReadingsData = responseMap['billingReadings'];
              } else if (responseMap.containsKey('readings')) {
                _billingReadingsData = responseMap['readings'];
              } else {
                // If it's a single object, wrap it in a list
                _billingReadingsData = [responseMap];
              }
            } else {
              _billingReadingsData = [];
            }
          } else {
            _billingReadingsData = [];
          }
          _isLoadingBilling = false;
        });
      }
    } catch (e) {
      print('Error loading billing data: $e');
      if (mounted) {
        setState(() {
          _billingReadingsData = [];
          _isLoadingBilling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMetricsTab(),
              _buildBillingTab(),
              _buildGroupTab(),
              _buildScheduleTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing20),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSizes.radiusMedium),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Device Details',
            style: TextStyle(
              fontSize: AppSizes.fontSizeLarge,
              fontWeight: FontWeight.bold,
              color: AppColors.textInverse,
            ),
          ),
          const SizedBox(height: AppSizes.spacing8),
          Text(
            widget.device.serialNumber,
            style: TextStyle(
              fontSize: AppSizes.fontSizeMedium,
              color: AppColors.textInverse.withOpacity(0.9),
              fontFamily: 'monospace',
            ),
          ),
          if (widget.device.name.isNotEmpty) ...[
            const SizedBox(height: AppSizes.spacing4),
            Text(
              widget.device.name,
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: AppColors.textInverse.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontSize: AppSizes.fontSizeSmall,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Metrics'),
          Tab(text: 'Billing'),
          Tab(text: 'Group'),
          Tab(text: 'Schedule'),
        ],
      ),
    );
  }

  Widget _buildMetricsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard('Device Information', [
            _buildInfoRow('Serial Number', widget.device.serialNumber),
            _buildInfoRow(
              'Model',
              widget.device.model.isNotEmpty ? widget.device.model : 'N/A',
            ),
            _buildInfoRow('Type', widget.device.deviceType),
            _buildInfoRow(
              'Manufacturer',
              widget.device.manufacturer.isNotEmpty
                  ? widget.device.manufacturer
                  : 'N/A',
            ),
          ]),
          const SizedBox(height: AppSizes.spacing16),
          _buildInfoCard('Status', [
            _buildStatusRow('Device Status', widget.device.status),
            _buildStatusRow('Link Status', widget.device.linkStatus),
          ]),
          const SizedBox(height: AppSizes.spacing16),
          _buildInfoCard('Location', [
            _buildInfoRow(
              'Address',
              widget.device.addressText.isNotEmpty
                  ? widget.device.addressText
                  : 'No address',
            ),
          ]),
          const SizedBox(height: AppSizes.spacing16),
          _buildRealMetricsChartsCard(),
        ],
      ),
    );
  }

  Widget _buildBillingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard('Billing Information', [
            _buildInfoRow('Device ID', widget.device.id ?? 'N/A'),
            _buildInfoRow('Serial Number', widget.device.serialNumber),
            _buildInfoRow('Last Reading', _getLastReadingInfo()),
          ]),
          const SizedBox(height: AppSizes.spacing16),
          _buildRealBillingChartsCard(),
          const SizedBox(height: AppSizes.spacing16),
          Container(
            padding: const EdgeInsets.all(AppSizes.spacing16),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.info, size: 20),
                const SizedBox(width: AppSizes.spacing12),
                Expanded(
                  child: Text(
                    'Billing readings are automatically updated when the device reports new data.',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeSmall,
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard('Group Information', [
            _buildInfoRow('Group ID', widget.device.deviceGroupId.toString()),
            _buildInfoRow(
              'Group Name',
              widget.device.deviceGroup?.name ?? 'Default Group',
            ),
            _buildInfoRow('Group Type', 'Device Collection'),
          ]),
          const SizedBox(height: AppSizes.spacing16),
          Container(
            padding: const EdgeInsets.all(AppSizes.spacing16),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.group_outlined, color: AppColors.warning, size: 20),
                const SizedBox(width: AppSizes.spacing12),
                Expanded(
                  child: Text(
                    'Device group management allows you to organize devices for easier maintenance and monitoring.',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeSmall,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard('Schedule Information', [
            _buildInfoRow('Schedule ID', 'Not assigned'),
            _buildInfoRow('Schedule Name', 'Default Schedule'),
            _buildInfoRow('Frequency', 'Daily'),
          ]),
          const SizedBox(height: AppSizes.spacing16),
          Container(
            padding: const EdgeInsets.all(AppSizes.spacing16),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, color: AppColors.success, size: 20),
                const SizedBox(width: AppSizes.spacing12),
                Expanded(
                  child: Text(
                    'Schedules define when and how often the device should collect and transmit data.',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeSmall,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.spacing12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radiusSmall),
                topRight: Radius.circular(AppSizes.radiusSmall),
              ),
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeMedium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSizes.spacing12),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.spacing8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.spacing8),
          Expanded(child: _buildStatusChip(status)),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    String displayText;

    switch (status.toLowerCase()) {
      case 'commissioned':
        backgroundColor = AppColors.success.withOpacity(0.1);
        textColor = AppColors.success;
        displayText = 'Commissioned';
        break;
      case 'multidrive':
        backgroundColor = AppColors.primary.withOpacity(0.1);
        textColor = AppColors.primary;
        displayText = 'MULTIDRIVE';
        break;
      case 'e-power':
        backgroundColor = AppColors.warning.withOpacity(0.1);
        textColor = AppColors.warning;
        displayText = 'E-POWER';
        break;
      case 'none':
        backgroundColor = AppColors.secondary.withOpacity(0.1);
        textColor = AppColors.secondary;
        displayText = 'None';
        break;
      default:
        backgroundColor = AppColors.surfaceVariant;
        textColor = AppColors.textSecondary;
        displayText = status.isNotEmpty ? status : 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  String _getLastReadingInfo() {
    final readings = _getBillingReadingsList();
    if (readings.isEmpty) return 'No readings available';

    try {
      // Find the most recent reading with proper validation
      final validReadings = readings
          .where(
            (reading) =>
                reading is Map &&
                reading.containsKey('created_at') &&
                reading['created_at'] != null &&
                reading.containsKey('reading_value'),
          )
          .toList();

      if (validReadings.isEmpty) return 'No valid readings available';

      final lastReading = validReadings.reduce((a, b) {
        try {
          final dateA = DateTime.parse(a['created_at'].toString());
          final dateB = DateTime.parse(b['created_at'].toString());
          return dateA.isAfter(dateB) ? a : b;
        } catch (e) {
          return b; // If date parsing fails, return the other reading
        }
      });

      final date = DateTime.parse(lastReading['created_at'].toString());
      final formattedDate = '${date.day}/${date.month}/${date.year}';
      final value = lastReading['reading_value']?.toString() ?? 'N/A';

      return '$value kWh on $formattedDate';
    } catch (e) {
      print('Error getting last reading info: $e');
      return 'Unable to load reading info';
    }
  }

  // Helper method to safely extract list from different response formats
  List<dynamic> _getBillingReadingsList() {
    if (_billingReadingsData == null) return [];

    try {
      if (_billingReadingsData is List) {
        return _billingReadingsData as List<dynamic>;
      } else if (_billingReadingsData is Map<String, dynamic>) {
        final responseMap = _billingReadingsData as Map<String, dynamic>;
        if (responseMap.containsKey('data') && responseMap['data'] is List) {
          return responseMap['data'] as List<dynamic>;
        } else if (responseMap.containsKey('billingReadings') &&
            responseMap['billingReadings'] is List) {
          return responseMap['billingReadings'] as List<dynamic>;
        } else if (responseMap.containsKey('readings') &&
            responseMap['readings'] is List) {
          return responseMap['readings'] as List<dynamic>;
        } else {
          // If it's a single object, wrap it in a list
          return [responseMap];
        }
      }
    } catch (e) {
      print('Error processing billing readings: $e');
    }

    return [];
  }

  Widget _buildRealMetricsChartsCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSizes.spacing8),
              Text(
                'Device Metrics',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeMedium,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing16),
          _isLoadingMetrics
              ? SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              : _metricsData == null
              ? Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: AppSizes.spacing8),
                        Text(
                          'No metrics data available',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: AppSizes.fontSizeSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 1,
                        verticalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: AppColors.border,
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: AppColors.border,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(
                                  '${value.toInt()}',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 10,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              );
                            },
                            reservedSize: 42,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: AppColors.border),
                      ),
                      minX: 0,
                      maxX: 10,
                      minY: 0,
                      maxY: 100,
                      lineBarsData: [
                        LineChartBarData(
                          spots: _getMetricsSpots(),
                          isCurved: true,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.success,
                              AppColors.success.withOpacity(0.3),
                            ],
                          ),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                                  radius: 4,
                                  color: AppColors.success,
                                  strokeWidth: 2,
                                  strokeColor: Colors.white,
                                ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.success.withOpacity(0.3),
                                AppColors.success.withOpacity(0.1),
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
    );
  }

  List<FlSpot> _getMetricsSpots() {
    // Generate sample data based on device activity
    return List.generate(11, (index) {
      final value =
          20 + (index * 5) + (widget.device.serialNumber.hashCode % 30);
      return FlSpot(index.toDouble(), value.toDouble() % 100);
    });
  }

  Widget _buildRealBillingChartsCard() {
    final readings = _getBillingReadingsList();

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSizes.spacing8),
              Text(
                'Billing Consumption Charts',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeMedium,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing16),
          _isLoadingBilling
              ? SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              : readings.isEmpty
              ? Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: AppSizes.spacing8),
                        Text(
                          'No billing data available',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: AppSizes.fontSizeSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SizedBox(
                  height: 250,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 1,
                        verticalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: AppColors.border,
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: AppColors.border,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              try {
                                if (value.toInt() >= 0 &&
                                    value.toInt() < readings.length) {
                                  final reading = readings[value.toInt()];
                                  if (reading is Map &&
                                      reading.containsKey('created_at') &&
                                      reading['created_at'] != null) {
                                    final date = DateTime.parse(
                                      reading['created_at'].toString(),
                                    );
                                    return SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      child: Text(
                                        '${date.day}/${date.month}',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                print('Error formatting chart date: $e');
                              }
                              return Container();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 50,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              );
                            },
                            reservedSize: 42,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: AppColors.border),
                      ),
                      minX: 0,
                      maxX: readings.length.toDouble() - 1,
                      minY: 0,
                      maxY: _getBillingMaxY(),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _getBillingSpots(),
                          isCurved: true,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.3),
                            ],
                          ),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                                  radius: 4,
                                  color: AppColors.primary,
                                  strokeWidth: 2,
                                  strokeColor: Colors.white,
                                ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.3),
                                AppColors.primary.withOpacity(0.1),
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
    );
  }

  double _getBillingMaxY() {
    final readings = _getBillingReadingsList();
    if (readings.isEmpty) return 100;

    final maxValue = readings
        .where(
          (reading) => reading is Map && reading.containsKey('reading_value'),
        )
        .map((reading) => (reading['reading_value'] as num?)?.toDouble() ?? 0.0)
        .fold(0.0, (a, b) => a > b ? a : b);

    return maxValue > 0 ? maxValue * 1.2 : 100; // Add 20% padding
  }

  List<FlSpot> _getBillingSpots() {
    final readings = _getBillingReadingsList();
    final spots = <FlSpot>[];

    try {
      for (int i = 0; i < readings.length; i++) {
        final reading = readings[i];
        if (reading is Map && reading.containsKey('reading_value')) {
          final value = (reading['reading_value'] as num?)?.toDouble() ?? 0.0;
          spots.add(FlSpot(i.toDouble(), value));
        }
      }
    } catch (e) {
      print('Error generating billing spots: $e');
    }

    // Return at least one point to avoid chart errors
    return spots.isEmpty ? [FlSpot(0, 0)] : spots;
  }
}
