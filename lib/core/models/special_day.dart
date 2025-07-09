class SpecialDay {
  final int id;
  final String name;
  final String description;
  final bool active;
  final List<SpecialDayDetail> specialDayDetails;

  SpecialDay({
    required this.id,
    required this.name,
    required this.description,
    required this.active,
    this.specialDayDetails = const [],
  });

  factory SpecialDay.fromJson(Map<String, dynamic> json) {
    return SpecialDay(
      id: json['Id'] ?? 0,
      name: json['Name'] ?? '',
      description: json['Description'] ?? '',
      active: json['Active'] ?? false,
      specialDayDetails:
          (json['SpecialDayDetail'] as List?)
              ?.map((detail) => SpecialDayDetail.fromJson(detail))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Name': name,
      'Description': description,
      'Active': active,
      'SpecialDayDetail': specialDayDetails
          .map((detail) => detail.toJson())
          .toList(),
    };
  }

  @override
  String toString() {
    return 'SpecialDay(id: $id, name: $name, description: $description, active: $active)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpecialDay && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class SpecialDayDetail {
  final int id;
  final int specialDayId;
  final DateTime startDate;
  final DateTime endDate;
  final String description;
  final bool active;

  SpecialDayDetail({
    required this.id,
    required this.specialDayId,
    required this.startDate,
    required this.endDate,
    required this.description,
    required this.active,
  });

  factory SpecialDayDetail.fromJson(Map<String, dynamic> json) {
    return SpecialDayDetail(
      id: json['Id'] ?? 0,
      specialDayId: json['SpecialDayId'] ?? 0,
      startDate: DateTime.tryParse(json['StartDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['EndDate'] ?? '') ?? DateTime.now(),
      description: json['Description'] ?? '',
      active: json['Active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'SpecialDayId': specialDayId,
      'StartDate': startDate.toIso8601String(),
      'EndDate': endDate.toIso8601String(),
      'Description': description,
      'Active': active,
    };
  }

  String get dateRangeDisplay {
    // Simple date formatting without importing intl package
    return '${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}';
  }
}
