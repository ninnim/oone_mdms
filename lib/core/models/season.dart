class Season {
  final int id;
  final String name;
  final String description;
  final List<int> monthRange;
  final bool active;

  Season({
    required this.id,
    required this.name,
    required this.description,
    required this.monthRange,
    required this.active,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      id: json['Id'] ?? 0,
      name: json['Name'] ?? '',
      description: json['Description'] ?? '',
      monthRange: List<int>.from(json['MonthRange'] ?? []),
      active: json['Active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Name': name,
      'Description': description,
      'MonthRange': monthRange,
      'Active': active,
    };
  }

  String get monthRangeDisplay {
    if (monthRange.isEmpty) return 'No months selected';

    final monthNames = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return monthRange.map((month) => monthNames[month]).join(', ');
  }

  @override
  String toString() {
    return 'Season(id: $id, name: $name, description: $description, active: $active, monthRange: $monthRange)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Season && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
