class Schedule {
  final String? billingDeviceId;
  final int? jobId;
  final int? jobTriggerId;
  final String? code;
  final String? name;
  final String? jobStatus;
  final String? targetType;
  final String? cronExpression;
  final BillingDevice? billingDevice;
  final int? id;
  final bool? active;
  final DateTime? createdDate;
  final String? createdBy;

  const Schedule({
    this.billingDeviceId,
    this.jobId,
    this.jobTriggerId,
    this.code,
    this.name,
    this.jobStatus,
    this.targetType,
    this.cronExpression,
    this.billingDevice,
    this.id,
    this.active,
    this.createdDate,
    this.createdBy,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      billingDeviceId: json['BillingDeviceId'],
      jobId: json['JobId'],
      jobTriggerId: json['JobTriggerId'],
      code: json['Code'],
      name: json['Name'],
      jobStatus: json['JobStatus'],
      targetType: json['TargetType'],
      cronExpression: json['CronExpression'],
      billingDevice: json['BillingDevice'] != null
          ? BillingDevice.fromJson(json['BillingDevice'])
          : null,
      id: json['Id'],
      active: json['Active'],
      createdDate: json['CreatedDate'] != null
          ? DateTime.parse(json['CreatedDate'])
          : null,
      createdBy: json['CreatedBy'],
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'Code': code,
      'Name': name,
      'CronExpression': cronExpression,
      'BillingDevice': billingDevice?.toJson(),
    };

    // For updates, include JobId at root level
    if (jobId != null) {
      data['JobId'] = jobId;
    }

    return data;
  }

  // Helper getters for easier access to nested properties
  String get displayTargetType => targetType ?? 'Unknown';
  String get displayInterval => billingDevice?.interval ?? 'Monthly';
  DateTime? get nextBillingDate => billingDevice?.nextBillingDate;
  DateTime? get lastExecutionTime => billingDevice?.lastExecutionTime;
  String get displayStatus => billingDevice?.status ?? 'Unknown';
  int get retryCount => billingDevice?.retryCount ?? 0;
  int? get siteId => billingDevice?.siteId;
  String? get deviceId => billingDevice?.deviceId;
  int? get deviceGroupId => billingDevice?.deviceGroupId;
  int? get timeOfUseId => billingDevice?.timeOfUseId;

  // Display helpers
  String get displayCode => code ?? 'N/A';
  String get displayName => name ?? 'N/A';
  bool get isActive => active ?? false;

  Schedule copyWith({
    String? billingDeviceId,
    int? jobId,
    int? jobTriggerId,
    String? code,
    String? name,
    String? jobStatus,
    String? targetType,
    String? cronExpression,
    BillingDevice? billingDevice,
    int? id,
    bool? active,
    DateTime? createdDate,
    String? createdBy,
  }) {
    return Schedule(
      billingDeviceId: billingDeviceId ?? this.billingDeviceId,
      jobId: jobId ?? this.jobId,
      jobTriggerId: jobTriggerId ?? this.jobTriggerId,
      code: code ?? this.code,
      name: name ?? this.name,
      jobStatus: jobStatus ?? this.jobStatus,
      targetType: targetType ?? this.targetType,
      cronExpression: cronExpression ?? this.cronExpression,
      billingDevice: billingDevice ?? this.billingDevice,
      id: id ?? this.id,
      active: active ?? this.active,
      createdDate: createdDate ?? this.createdDate,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  String toString() {
    return 'Schedule(id: $id, code: $code, name: $name, targetType: $targetType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Schedule && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class BillingDevice {
  final int? jobId;
  final int? jobTriggerId;
  final int? siteId;
  final String? deviceId;
  final int? deviceGroupId;
  final int? timeOfUseId;
  final String? status;
  final DateTime? nextBillingDate;
  final String? interval;
  final int? retryCount;
  final DateTime? lastExecutionTime;
  final String? userId;
  final bool? active;
  final String? id;
  final String? tenantId;
  final String? createdBy;
  final DateTime? createdDate;
  final DateTime? rowDate;

  const BillingDevice({
    this.jobId,
    this.jobTriggerId,
    this.siteId,
    this.deviceId,
    this.deviceGroupId,
    this.timeOfUseId,
    this.status,
    this.nextBillingDate,
    this.interval,
    this.retryCount,
    this.lastExecutionTime,
    this.userId,
    this.active,
    this.id,
    this.tenantId,
    this.createdBy,
    this.createdDate,
    this.rowDate,
  });

  factory BillingDevice.fromJson(Map<String, dynamic> json) {
    return BillingDevice(
      jobId: json['JobId'],
      jobTriggerId: json['JobTriggerId'],
      siteId: json['SiteId'],
      deviceId: json['DeviceId'],
      deviceGroupId: json['DeviceGroupId'],
      timeOfUseId: json['TimeOfUseId'],
      status: json['Status'],
      nextBillingDate: json['NextBillingDate'] != null
          ? DateTime.parse(json['NextBillingDate'])
          : null,
      interval: json['Interval'],
      retryCount: json['RetryCount'],
      lastExecutionTime: json['LastExecutionTime'] != null
          ? DateTime.parse(json['LastExecutionTime'])
          : null,
      userId: json['UserId'],
      active: json['Active'],
      id: json['Id'],
      tenantId: json['TenantId'],
      createdBy: json['CreatedBy'],
      createdDate: json['CreatedDate'] != null
          ? DateTime.parse(json['CreatedDate'])
          : null,
      rowDate: json['RowDate'] != null ? DateTime.parse(json['RowDate']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'SiteId': siteId,
      'TimeOfUseId': timeOfUseId,
      'Status': status,
      'RetryCount': retryCount,
    };

    // For updates, include Id and JobId
    if (id != null) {
      data['Id'] = id;
    }

    if (jobId != null) {
      data['JobId'] = jobId;
    }

    if (deviceId != null) {
      data['DeviceId'] = deviceId;
    }

    if (deviceGroupId != null) {
      data['DeviceGroupId'] = deviceGroupId;
    }

    if (nextBillingDate != null) {
      // Use full ISO format with timezone for API compatibility
      data['NextBillingDate'] = nextBillingDate!.toUtc().toIso8601String();
    }

    return data;
  }
}

// Enums for Schedule management
enum ScheduleTargetType {
  device('Device'),
  group('Group');

  const ScheduleTargetType(this.value);
  final String value;

  static ScheduleTargetType fromString(String value) {
    return ScheduleTargetType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ScheduleTargetType.device,
    );
  }
}

enum ScheduleInterval {
  monthly('Monthly'),
  weekly('Weekly'),
  daily('Daily');

  const ScheduleInterval(this.value);
  final String value;

  static ScheduleInterval fromString(String value) {
    return ScheduleInterval.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ScheduleInterval.monthly,
    );
  }
}

enum ScheduleStatus {
  enabled('Enabled'),
  disabled('Disabled'),
  paused('Paused');

  const ScheduleStatus(this.value);
  final String value;

  static ScheduleStatus fromString(String value) {
    return ScheduleStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ScheduleStatus.enabled,
    );
  }
}
