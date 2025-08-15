import 'package:flutter/material.dart';
import '../../../presentation/widgets/devices/modern_metrics_chart.dart';

class TestModernMetricsScreen extends StatelessWidget {
  const TestModernMetricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample metrics data that mimics real API data
    final sampleData = [
      {
        'Timestamp': '2025-08-14T10:00:00Z',
        'ImportActiveEnergyWh': 150.5,
        'ImportReactiveEnergyVarh': 25.3,
        'ExportActiveEnergyWh': 80.2,
        'ExportReactiveEnergyVarh': 15.1,
        'VoltagePhaseA': 230.5,
        'VoltagePhaseB': 229.8,
        'VoltagePhaseC': 231.2,
        'CurrentPhaseA': 10.5,
        'CurrentPhaseB': 9.8,
        'CurrentPhaseC': 11.2,
        'PowerFactor': 0.95,
      },
      {
        'Timestamp': '2025-08-14T11:00:00Z',
        'ImportActiveEnergyWh': 155.8,
        'ImportReactiveEnergyVarh': 26.1,
        'ExportActiveEnergyWh': 82.5,
        'ExportReactiveEnergyVarh': 16.3,
        'VoltagePhaseA': 231.2,
        'VoltagePhaseB': 230.1,
        'VoltagePhaseC': 230.8,
        'CurrentPhaseA': 10.8,
        'CurrentPhaseB': 10.2,
        'CurrentPhaseC': 11.0,
        'PowerFactor': 0.96,
      },
      {
        'Timestamp': '2025-08-14T12:00:00Z',
        'ImportActiveEnergyWh': 160.2,
        'ImportReactiveEnergyVarh': 27.8,
        'ExportActiveEnergyWh': 85.1,
        'ExportReactiveEnergyVarh': 17.2,
        'VoltagePhaseA': 229.8,
        'VoltagePhaseB': 231.5,
        'VoltagePhaseC': 230.2,
        'CurrentPhaseA': 11.2,
        'CurrentPhaseB': 10.5,
        'CurrentPhaseC': 10.8,
        'PowerFactor': 0.94,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modern Metrics Chart Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ModernMetricsChart(
          data: sampleData,
          isLoading: false,
          onRefresh: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Refresh functionality works!')),
            );
          },
          onExport: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Export functionality works!')),
            );
          },
        ),
      ),
    );
  }
}
