class TimeOfUse {
  final int id;
  final String name;

  TimeOfUse({required this.id, required this.name});

  factory TimeOfUse.fromJson(Map<String, dynamic> json) {
    return TimeOfUse(id: json['Id'] ?? 0, name: json['Name'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'Id': id, 'Name': name};
  }
}

class DeviceBilling {
  final String deviceId;
  final int timeOfUseId;
  final DateTime startTime;
  final DateTime endTime;
  final TimeOfUse timeOfUse;

  DeviceBilling({
    required this.deviceId,
    required this.timeOfUseId,
    required this.startTime,
    required this.endTime,
    required this.timeOfUse,
  });

  factory DeviceBilling.fromJson(Map<String, dynamic> json) {
    return DeviceBilling(
      deviceId: json['DeviceId'] ?? '',
      timeOfUseId: json['TimeOfUseId'] ?? 0,
      startTime: DateTime.parse(
        json['StartTime'] ?? DateTime.now().toIso8601String(),
      ),
      endTime: DateTime.parse(
        json['EndTime'] ?? DateTime.now().toIso8601String(),
      ),
      timeOfUse: TimeOfUse.fromJson(json['TimeOfUse'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'DeviceId': deviceId,
      'TimeOfUseId': timeOfUseId,
      'StartTime': startTime.toIso8601String(),
      'EndTime': endTime.toIso8601String(),
      'TimeOfUse': timeOfUse.toJson(),
    };
  }
}

class MetricLabels {
  final String phase;
  final String units;
  final String flowDirection;
  final String apportionPolicy;

  MetricLabels({
    required this.phase,
    required this.units,
    required this.flowDirection,
    required this.apportionPolicy,
  });

  factory MetricLabels.fromJson(Map<String, dynamic> json) {
    return MetricLabels(
      phase: json['Phase'] ?? '',
      units: json['Units'] ?? '',
      flowDirection: json['FlowDirection'] ?? '',
      apportionPolicy: json['ApportionPolicy'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Phase': phase,
      'Units': units,
      'FlowDirection': flowDirection,
      'ApportionPolicy': apportionPolicy,
    };
  }
}

class DeviceBillingReading {
  final String deviceId;
  final String id;
  final DateTime billingDate;
  final DateTime endTime;
  final DateTime startTime;
  final MetricLabels metricLabels;
  final String registerDisplayCode;
  final double accumulativeValue;
  final TimeOfUse timeOfUse;

  DeviceBillingReading({
    required this.deviceId,
    required this.id,
    required this.billingDate,
    required this.endTime,
    required this.startTime,
    required this.metricLabels,
    required this.registerDisplayCode,
    required this.accumulativeValue,
    required this.timeOfUse,
  });

  factory DeviceBillingReading.fromJson(Map<String, dynamic> json) {
    return DeviceBillingReading(
      deviceId: json['DeviceId'] ?? '',
      id: json['Id'] ?? '',
      billingDate: DateTime.parse(
        json['BillingDate'] ?? DateTime.now().toIso8601String(),
      ),
      endTime: DateTime.parse(
        json['EndTime'] ?? DateTime.now().toIso8601String(),
      ),
      startTime: DateTime.parse(
        json['StartTime'] ?? DateTime.now().toIso8601String(),
      ),
      metricLabels: MetricLabels.fromJson(json['MetricLabels'] ?? {}),
      registerDisplayCode: json['RegisterDisplayCode'] ?? '',
      accumulativeValue: (json['AccumulativeValue'] ?? 0).toDouble(),
      timeOfUse: TimeOfUse.fromJson(json['TimeOfUse'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'DeviceId': deviceId,
      'Id': id,
      'BillingDate': billingDate.toIso8601String(),
      'EndTime': endTime.toIso8601String(),
      'StartTime': startTime.toIso8601String(),
      'MetricLabels': metricLabels.toJson(),
      'RegisterDisplayCode': registerDisplayCode,
      'AccumulativeValue': accumulativeValue,
      'TimeOfUse': timeOfUse.toJson().entries,
    };
  }
}
