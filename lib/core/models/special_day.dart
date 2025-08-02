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
          (json['SpecialDayDetails'] as List?)
              ?.map((detail) => SpecialDayDetail.fromJson(detail))
              .toList() ??
          (json['SpecialDayDetail'] as List?)
              ?.map((detail) => SpecialDayDetail.fromJson(detail))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    final data = {'Name': name, 'Description': description, 'Active': active};

    // Add Id only for updates (when id > 0)
    if (id > 0) {
      data['Id'] = id;
    }

    // Add SpecialDayDetails with the required format
    if (specialDayDetails.isNotEmpty) {
      data['SpecialDayDetails'] = {
        'on_conflict': {
          'constraint': 'PK_SpecialDayDetail',
          'update_columns': [
            'Name',
            'Description',
            'StartDate',
            'EndDate',
            'Active',
          ],
        },
        'data': specialDayDetails.map((detail) => detail.toJson()).toList(),
      };
    }

    return data;
  }

  // Helper method to get the full payload format for API calls
  Map<String, dynamic> toPayload() {
    return {'SpecialDay': toJson()};
  }

  // Helper method to get count of details
  int get detailsCount => specialDayDetails.length;

  // Helper method to get active details count
  int get activeDetailsCount =>
      specialDayDetails.where((detail) => detail.active).length;

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
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String description;
  final bool active;

  SpecialDayDetail({
    required this.id,
    required this.specialDayId,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.description,
    required this.active,
  });

  factory SpecialDayDetail.fromJson(Map<String, dynamic> json) {
    return SpecialDayDetail(
      id: json['Id'] ?? 0,
      specialDayId: json['SpecialDayId'] ?? 0,
      name: json['Name'] ?? '',
      startDate: DateTime.tryParse(json['StartDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['EndDate'] ?? '') ?? DateTime.now(),
      description: json['Description'] ?? '',
      active: json['Active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final data = {
      'Name': name,
      'Description': description,
      'StartDate': startDate
          .toIso8601String()
          .split('T')
          .first, // Format as YYYY-MM-DD
      'EndDate': endDate
          .toIso8601String()
          .split('T')
          .first, // Format as YYYY-MM-DD
      'Active': active,
    };

    // Add Id only for updates (when id > 0)
    if (id > 0) {
      data['Id'] = id;
    }

    // Add SpecialDayId if provided
    if (specialDayId > 0) {
      data['SpecialDayId'] = specialDayId;
    }

    return data;
  }

  String get dateRangeDisplay {
    // Simple date formatting without importing intl package
    return '${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}';
  }

  // Helper method to get duration in days
  int get durationInDays {
    return endDate.difference(startDate).inDays + 1;
  }

  @override
  String toString() {
    return 'SpecialDayDetail(id: $id, name: $name, dateRange: $dateRangeDisplay)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpecialDayDetail && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
