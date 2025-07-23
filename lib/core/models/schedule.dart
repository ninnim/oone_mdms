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
    return {
      'BillingDeviceId': billingDeviceId,
      'JobId': jobId,
      'JobTriggerId': jobTriggerId,
      'Code': code,
      'Name': name,
      'JobStatus': jobStatus,
      'TargetType': targetType,
      'CronExpression': cronExpression,
      'BillingDevice': billingDevice?.toJson(),
      'Id': id,
      'Active': active,
      'CreatedDate': createdDate?.toIso8601String(),
      'CreatedBy': createdBy,
    };
  }

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
    return {
      'JobId': jobId,
      'JobTriggerId': jobTriggerId,
      'SiteId': siteId,
      'DeviceId': deviceId,
      'DeviceGroupId': deviceGroupId,
      'TimeOfUseId': timeOfUseId,
      'Status': status,
      'NextBillingDate': nextBillingDate?.toIso8601String(),
      'Interval': interval,
      'RetryCount': retryCount,
      'LastExecutionTime': lastExecutionTime?.toIso8601String(),
      'UserId': userId,
      'Active': active,
      'Id': id,
      'TenantId': tenantId,
      'CreatedBy': createdBy,
      'CreatedDate': createdDate?.toIso8601String(),
      'RowDate': rowDate?.toIso8601String(),
    };
  }
}
