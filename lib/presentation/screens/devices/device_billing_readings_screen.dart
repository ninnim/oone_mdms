import 'package:flutter/material.dart';
import '../../../core/models/device.dart';
import '../../../core/services/device_service.dart';
import '../../../core/services/api_service.dart';
import '../../widgets/common/app_card.dart';

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

  @override
  Widget build(BuildContext context) {
    return Column(
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
          child: Row(
            children: [
              if (widget.onBack != null) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.onBack,
                  tooltip: 'Back to Device Details',
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Billing Readings',
                      style: const TextStyle(
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
              Row(
                children: [
                  IconButton(
                    onPressed: _loadBillingReadings,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh Data',
                  ),
                  IconButton(
                    onPressed: _exportReadings,
                    icon: const Icon(Icons.download),
                    tooltip: 'Export Readings',
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

                      // Billing Readings Table
                      const Text(
                        'Billing Readings',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1e293b),
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (_billingReadings != null) ...[
                        _buildBillingReadingsTable(),
                      ] else
                        const AppCard(
                          child: Center(
                            child: Text(
                              'No billing readings available',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF64748b),
                              ),
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

  Widget _buildBillingReadingsTable() {
    if (_billingReadings!['DeviceReadings'] == null ||
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

    final readings = _billingReadings!['DeviceReadings'] as List;

    return AppCard(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Billing Date')),
            DataColumn(label: Text('Accumulative Value')),
            DataColumn(label: Text('Start Time')),
            DataColumn(label: Text('End Time')),
            DataColumn(label: Text('Time of Use')),
            DataColumn(label: Text('Units')),
            DataColumn(label: Text('Phase')),
            DataColumn(label: Text('Flow Direction')),
          ],
          rows: readings.map<DataRow>((reading) {
            final metricLabels = reading['MetricLabels'] ?? {};
            final timeOfUse = reading['TimeOfUse'] ?? {};

            return DataRow(
              cells: [
                DataCell(
                  Text(
                    _formatTimestamp(reading['BillingDate']),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  Text(
                    reading['AccumulativeValue']?.toString() ?? '0',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                DataCell(
                  Text(
                    _formatTimestamp(reading['StartTime']),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  Text(
                    _formatTimestamp(reading['EndTime']),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  Text(
                    timeOfUse['Name'] ?? 'N/A',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(Text(metricLabels['Units'] ?? 'WH')),
                DataCell(Text(metricLabels['Phase'] ?? 'N/A')),
                DataCell(Text(metricLabels['FlowDirection'] ?? 'N/A')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
          const Text(
            ': ',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748b)),
          ),
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

  void _exportReadings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.download, color: Colors.white),
            SizedBox(width: 8),
            Text('Exporting billing readings...'),
          ],
        ),
        backgroundColor: Color(0xFF2563eb),
      ),
    );
  }
}
