import 'package:flutter/material.dart';
import '../widgets/devices/grouped_metrics_charts.dart';

class TestGroupedMetricsScreen extends StatelessWidget {
  const TestGroupedMetricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample mock data that mimics real API response structure
    final List<Map<String, dynamic>> mockMetrics = [
      {
        'Timestamp': '2024-01-01T10:00:00Z',
        'ExportWhPhaseA': 120.5,
        'ExportVarhPhaseA': 50.2,
        'ImportWhPhaseB': 230.1,
        'ImportVarhPhaseB': 75.3,
        'VoltagePhaseA': 240.2,
        'VoltagePhaseB': 238.9,
        'CurrentPhaseA': 15.2,
        'CurrentPhaseB': 18.4,
        'PowerFactor': 0.95,
      },
      {
        'Timestamp': '2024-01-01T11:00:00Z',
        'ExportWhPhaseA': 125.8,
        'ExportVarhPhaseA': 52.1,
        'ImportWhPhaseB': 245.6,
        'ImportVarhPhaseB': 78.9,
        'VoltagePhaseA': 241.1,
        'VoltagePhaseB': 239.5,
        'CurrentPhaseA': 16.1,
        'CurrentPhaseB': 19.2,
        'PowerFactor': 0.94,
      },
      {
        'Timestamp': '2024-01-01T12:00:00Z',
        'ExportWhPhaseA': 118.2,
        'ExportVarhPhaseA': 48.7,
        'ImportWhPhaseB': 220.3,
        'ImportVarhPhaseB': 72.1,
        'VoltagePhaseA': 239.8,
        'VoltagePhaseB': 238.2,
        'CurrentPhaseA': 14.8,
        'CurrentPhaseB': 17.6,
        'PowerFactor': 0.96,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grouped Metrics Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GroupedMetricsCharts(
          dynamicMetrics: mockMetrics,
          onRefresh: () {
            // Mock refresh action
            print('Refresh button clicked');
          },
        ),
      ),
    );
  }
}
