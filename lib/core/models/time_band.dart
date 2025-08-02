import 'season.dart';
import 'special_day.dart';

// Time Band Models for MDMS

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
    final Map<String, dynamic> data = {
      'Name': name,
      'StartTime': startTime,
      'EndTime': endTime,
      'Description': description,
    };

    // Add Id only for updates (when id > 0)
    if (id > 0) {
      data['Id'] = id;
    }

    return data;
  }

  Map<String, dynamic> toCreateJson({
    required List<int> daysOfWeek,
    required List<int> monthsOfYear,
    required List<int> seasonIds,
    required List<int> specialDayIds,
  }) {
    final attributes = <Map<String, dynamic>>[];

    // Add DayOfWeek attribute if provided
    if (daysOfWeek.isNotEmpty) {
      attributes.add({'Key': 'DayOfWeek', 'Value': daysOfWeek});
    }

    // Add MonthOfYear attribute if provided
    if (monthsOfYear.isNotEmpty) {
      attributes.add({'Key': 'MonthOfYear', 'Value': monthsOfYear});
    }

    // Add Season attribute if provided
    if (seasonIds.isNotEmpty) {
      attributes.add({'Key': 'Season', 'Value': seasonIds});
    }

    // Add SpecialDay attribute if provided
    if (specialDayIds.isNotEmpty) {
      attributes.add({'Key': 'SpecialDay', 'Value': specialDayIds});
    }

    return {
      'TimeBand': {
        'Name': name,
        'StartTime': startTime,
        'EndTime': endTime,
        'Description': description,
        if (attributes.isNotEmpty)
          'TimeBandAttributes': {
            'on_conflict': {
              'constraint': 'PK_TimeBandAttribute',
              'update_columns': ['Key', 'Value', 'Active'],
            },
            'data': attributes,
          },
      },
    };
  }

  Map<String, dynamic> toUpdateJson({
    required List<int> daysOfWeek,
    required List<int> monthsOfYear,
    required List<int> seasonIds,
    required List<int> specialDayIds,
  }) {
    final attributes = <Map<String, dynamic>>[];

    // Build attributes list with existing IDs when available
    final existingDayAttr = timeBandAttributes
        .where((a) => a.attributeType == 'DayOfWeek')
        .firstOrNull;
    if (daysOfWeek.isNotEmpty || existingDayAttr != null) {
      final dayAttr = <String, dynamic>{
        'Key': 'DayOfWeek',
        'Value': daysOfWeek,
        'Active': true,
      };
      if (existingDayAttr != null) {
        dayAttr['Id'] = existingDayAttr.id;
      }
      attributes.add(dayAttr);
    }

    final existingMonthAttr = timeBandAttributes
        .where((a) => a.attributeType == 'MonthOfYear')
        .firstOrNull;
    if (monthsOfYear.isNotEmpty || existingMonthAttr != null) {
      final monthAttr = <String, dynamic>{
        'Key': 'MonthOfYear',
        'Value': monthsOfYear,
        'Active': true,
      };
      if (existingMonthAttr != null) {
        monthAttr['Id'] = existingMonthAttr.id;
      }
      attributes.add(monthAttr);
    }

    final existingSeasonAttr = timeBandAttributes
        .where((a) => a.attributeType == 'Season')
        .firstOrNull;
    if (seasonIds.isNotEmpty || existingSeasonAttr != null) {
      final seasonAttr = <String, dynamic>{
        'Key': 'Season',
        'Value': seasonIds,
        'Active': true,
      };
      if (existingSeasonAttr != null) {
        seasonAttr['Id'] = existingSeasonAttr.id;
      }
      attributes.add(seasonAttr);
    }

    final existingSpecialDayAttr = timeBandAttributes
        .where((a) => a.attributeType == 'SpecialDay')
        .firstOrNull;
    if (specialDayIds.isNotEmpty || existingSpecialDayAttr != null) {
      final specialDayAttr = <String, dynamic>{
        'Key': 'SpecialDay',
        'Value': specialDayIds,
        'Active': true,
      };
      if (existingSpecialDayAttr != null) {
        specialDayAttr['Id'] = existingSpecialDayAttr.id;
      }
      attributes.add(specialDayAttr);
    }

    return {
      'TimeBand': {
        'Id': id,
        'Name': name,
        'StartTime': startTime,
        'EndTime': endTime,
        'Description': description,
        'Active': active,
        if (attributes.isNotEmpty)
          'TimeBandAttributes': {
            'on_conflict': {
              'constraint': 'PK_TimeBandAttribute',
              'update_columns': ['Key', 'Value', 'Active'],
            },
            'data': attributes,
          },
      },
    };
  }

  // Helper getters for attributes
  List<int> get daysOfWeek {
    final attr = timeBandAttributes.firstWhere(
      (a) => a.attributeType == 'DayOfWeek',
      orElse: () => TimeBandAttribute(
        id: 0,
        timeBandId: 0,
        attributeType: 'DayOfWeek',
        attributeValue: '[]',
        active: true,
        seasons: [],
        specialDays: [],
      ),
    );
    return List<int>.from(attr.valueList);
  }

  List<int> get monthsOfYear {
    final attr = timeBandAttributes.firstWhere(
      (a) => a.attributeType == 'MonthOfYear',
      orElse: () => TimeBandAttribute(
        id: 0,
        timeBandId: 0,
        attributeType: 'MonthOfYear',
        attributeValue: '[]',
        active: true,
        seasons: [],
        specialDays: [],
      ),
    );
    return List<int>.from(attr.valueList);
  }

  List<int> get seasonIds {
    final attr = timeBandAttributes.firstWhere(
      (a) => a.attributeType == 'Season',
      orElse: () => TimeBandAttribute(
        id: 0,
        timeBandId: 0,
        attributeType: 'Season',
        attributeValue: '[]',
        active: true,
        seasons: [],
        specialDays: [],
      ),
    );
    return List<int>.from(attr.valueList);
  }

  List<int> get specialDayIds {
    final attr = timeBandAttributes.firstWhere(
      (a) => a.attributeType == 'SpecialDay',
      orElse: () => TimeBandAttribute(
        id: 0,
        timeBandId: 0,
        attributeType: 'SpecialDay',
        attributeValue: '[]',
        active: true,
        seasons: [],
        specialDays: [],
      ),
    );
    return List<int>.from(attr.valueList);
  }

  String get timeRangeDisplay => '$startTime - $endTime';

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
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<Season> seasons;
  final List<SpecialDay> specialDays;

  TimeBandAttribute({
    required this.id,
    required this.timeBandId,
    required this.attributeType,
    required this.attributeValue,
    this.active = true,
    this.createdAt,
    this.updatedAt,
    this.seasons = const [],
    this.specialDays = const [],
  });

  factory TimeBandAttribute.fromJson(Map<String, dynamic> json) {
    // Handle the Value field properly - it can be a List or a string
    String attributeValueStr;
    if (json['Value'] is List) {
      // Convert list to string representation for internal storage
      attributeValueStr = json['Value'].toString();
    } else {
      attributeValueStr = json['Value']?.toString() ?? '[]';
    }

    return TimeBandAttribute(
      id: json['Id'] ?? 0,
      timeBandId: json['TimeBandId'] ?? 0,
      attributeType: json['Key'] ?? '',
      attributeValue: attributeValueStr,
      active: json['Active'] ?? true,
      createdAt: json['CreatedAt'] != null
          ? DateTime.tryParse(json['CreatedAt'])
          : null,
      updatedAt: json['UpdatedAt'] != null
          ? DateTime.tryParse(json['UpdatedAt'])
          : null,
      seasons:
          (json['Seasons'] as List?)?.map((s) => Season.fromJson(s)).toList() ??
          [],
      specialDays:
          (json['SpecialDays'] as List?)
              ?.map((sd) => SpecialDay.fromJson(sd))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'TimeBandId': timeBandId,
      'Key': attributeType,
      'Value': valueList,
      'Active': active,
    };
  }

  List<dynamic> get valueList {
    try {
      // If attributeValue is already a string representation of a list from JSON
      if (attributeValue.startsWith('[') && attributeValue.endsWith(']')) {
        final content = attributeValue.substring(1, attributeValue.length - 1);
        if (content.trim().isEmpty) {
          return [];
        }
        return content.split(',').where((s) => s.trim().isNotEmpty).map((s) {
          final trimmed = s.trim();
          return int.tryParse(trimmed) ?? trimmed;
        }).toList();
      }

      // If it's a single value
      final intValue = int.tryParse(attributeValue);
      if (intValue != null) {
        return [intValue];
      }

      return [attributeValue];
    } catch (e) {
      print('Error parsing valueList from "$attributeValue": $e');
      return [];
    }
  }

  @override
  String toString() {
    return 'TimeBandAttribute(id: $id, type: $attributeType, value: $attributeValue, active: $active)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeBandAttribute && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
