class TimeBand {
  final int id;
  final String name;
  final String startTime;
  final String endTime;
  final String description;
  final bool active;
  final List<TimeBandAttribute> timeBandAttributes;

  TimeBand({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.description,
    required this.active,
    this.timeBandAttributes = const [],
  });

  factory TimeBand.fromJson(Map<String, dynamic> json) {
    return TimeBand(
      id: json['Id'] ?? 0,
      name: json['Name'] ?? '',
      startTime: json['StartTime'] ?? '',
      endTime: json['EndTime'] ?? '',
      description: json['Description'] ?? '',
      active: json['Active'] ?? false,
      timeBandAttributes:
          (json['TimeBandAttributes'] as List?)
              ?.map((attr) => TimeBandAttribute.fromJson(attr))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Name': name,
      'StartTime': startTime,
      'EndTime': endTime,
      'Description': description,
      'Active': active,
      'TimeBandAttributes': timeBandAttributes
          .map((attr) => attr.toJson())
          .toList(),
    };
  }

  @override
  String toString() {
    return 'TimeBand(id: $id, name: $name, startTime: $startTime, endTime: $endTime, active: $active)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeBand && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class TimeBandAttribute {
  final int id;
  final int timeBandId;
  final String attributeType;
  final String attributeValue;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TimeBandAttribute({
    required this.id,
    required this.timeBandId,
    required this.attributeType,
    required this.attributeValue,
    this.createdAt,
    this.updatedAt,
  });

  factory TimeBandAttribute.fromJson(Map<String, dynamic> json) {
    return TimeBandAttribute(
      id: json['Id'] ?? 0,
      timeBandId: json['TimeBandId'] ?? 0,
      attributeType: json['AttributeType'] ?? '',
      attributeValue: json['AttributeValue'] ?? '',
      createdAt: json['CreatedAt'] != null
          ? DateTime.tryParse(json['CreatedAt'])
          : null,
      updatedAt: json['UpdatedAt'] != null
          ? DateTime.tryParse(json['UpdatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'TimeBandId': timeBandId,
      'AttributeType': attributeType,
      'AttributeValue': attributeValue,
      if (createdAt != null) 'CreatedAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'UpdatedAt': updatedAt!.toIso8601String(),
    };
  }
}
