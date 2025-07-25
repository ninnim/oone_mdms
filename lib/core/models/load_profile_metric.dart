class LoadProfileMetric {
  final String id;
  final String deviceId;
  final DateTime timestamp;
  final String phase; // L1, L2, L3
  final double value;
  final String unit; // V, A, W, kWh, etc.
  final String? flowDirection; // Import, Export
  final String? metricType; // Voltage, Current, Power, Energy
  final Map<String, dynamic>? attributes;

  const LoadProfileMetric({
    required this.id,
    required this.deviceId,
    required this.timestamp,
    required this.phase,
    required this.value,
    required this.unit,
    this.flowDirection,
    this.metricType,
    this.attributes,
  });

  factory LoadProfileMetric.fromJson(Map<String, dynamic> json) {
    return LoadProfileMetric(
      id: json['Id']?.toString() ?? '',
      deviceId: json['DeviceId']?.toString() ?? '',
      timestamp: json['Timestamp'] != null
          ? DateTime.tryParse(json['Timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      phase: json['Phase']?.toString() ?? 'L1',
      value: (json['Value'] ?? 0).toDouble(),
      unit: json['Unit']?.toString() ?? 'V',
      flowDirection: json['FlowDirection']?.toString(),
      metricType: json['MetricType']?.toString() ?? 'Voltage',
      attributes: json['Attributes'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'DeviceId': deviceId,
      'Timestamp': timestamp.toIso8601String(),
      'Phase': phase,
      'Value': value,
      'Unit': unit,
      'FlowDirection': flowDirection,
      'MetricType': metricType,
      'Attributes': attributes,
    };
  }

  LoadProfileMetric copyWith({
    String? id,
    String? deviceId,
    DateTime? timestamp,
    String? phase,
    double? value,
    String? unit,
    String? flowDirection,
    String? metricType,
    Map<String, dynamic>? attributes,
  }) {
    return LoadProfileMetric(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      timestamp: timestamp ?? this.timestamp,
      phase: phase ?? this.phase,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      flowDirection: flowDirection ?? this.flowDirection,
      metricType: metricType ?? this.metricType,
      attributes: attributes ?? this.attributes,
    );
  }
}

// Helper class for grouping metrics by phase
class PhaseMetrics {
  final String phase;
  final List<LoadProfileMetric> metrics;
  final double? averageValue;
  final double? maxValue;
  final double? minValue;
  final String unit;

  const PhaseMetrics({
    required this.phase,
    required this.metrics,
    this.averageValue,
    this.maxValue,
    this.minValue,
    required this.unit,
  });

  factory PhaseMetrics.fromMetrics(
    String phase,
    List<LoadProfileMetric> metrics,
  ) {
    if (metrics.isEmpty) {
      return PhaseMetrics(phase: phase, metrics: [], unit: 'V');
    }

    final values = metrics.map((m) => m.value).toList();
    final average = values.reduce((a, b) => a + b) / values.length;
    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);

    return PhaseMetrics(
      phase: phase,
      metrics: metrics,
      averageValue: average,
      maxValue: max,
      minValue: min,
      unit: metrics.first.unit,
    );
  }
}
