import 'time_band.dart';

/// Channel model for Time of Use details
class Channel {
  final int id;
  final String code;
  final String name;
  final String units;
  final String flowDirection;
  final String phase;
  final String apportionPolicy;
  final bool active;

  Channel({
    required this.id,
    required this.code,
    required this.name,
    required this.units,
    required this.flowDirection,
    required this.phase,
    required this.apportionPolicy,
    required this.active,
  });

  /// Simple constructor for UI use
  Channel.simple({required this.id, required this.name, String? type})
    : code = '',
      units = '',
      flowDirection = '',
      phase = '',
      apportionPolicy = '',
      active = true;

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['Id'] ?? 0,
      code: json['Code'] ?? '',
      name: json['Name'] ?? '',
      units: json['Units'] ?? '',
      flowDirection: json['FlowDirection'] ?? '',
      phase: json['Phase'] ?? '',
      apportionPolicy: json['ApportionPolicy'] ?? '',
      active: json['Active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Code': code,
      'Name': name,
      'Units': units,
      'FlowDirection': flowDirection,
      'Phase': phase,
      'ApportionPolicy': apportionPolicy,
      'Active': active,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Channel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Channel(id: $id, code: $code, name: $name, units: $units, flowDirection: $flowDirection, phase: $phase, apportionPolicy: $apportionPolicy, active: $active)';
  }
}

/// Time of Use Detail model
class TimeOfUseDetail {
  final int? id;
  final int timeBandId;
  final int channelId;
  final String registerDisplayCode;
  final int priorityOrder;
  final bool active;
  final Channel? channel;
  final TimeBand? timeBand;

  TimeOfUseDetail({
    this.id,
    required this.timeBandId,
    required this.channelId,
    required this.registerDisplayCode,
    required this.priorityOrder,
    required this.active,
    this.channel,
    this.timeBand,
  });

  factory TimeOfUseDetail.fromJson(Map<String, dynamic> json) {
    return TimeOfUseDetail(
      id: json['Id'],
      timeBandId: json['TimeBandId'] ?? 0,
      channelId: json['ChannelId'] ?? 0,
      registerDisplayCode: json['RegisterDisplayCode'] ?? '',
      priorityOrder: json['PriorityOrder'] ?? 0,
      active: json['Active'] ?? true,
      channel: json['Channel'] != null
          ? Channel.fromJson(json['Channel'])
          : null,
      timeBand: json['TimeBand'] != null
          ? TimeBand.fromJson(json['TimeBand'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'Id': id,
      'TimeBandId': timeBandId,
      'ChannelId': channelId,
      'RegisterDisplayCode': registerDisplayCode,
      'PriorityOrder': priorityOrder,
      'Active': active,
      if (channel != null) 'Channel': channel!.toJson(),
      if (timeBand != null) 'TimeBand': timeBand!.toJson(),
    };
  }

  /// Create a copy with updated fields
  TimeOfUseDetail copyWith({
    int? id,
    int? timeBandId,
    int? channelId,
    String? registerDisplayCode,
    int? priorityOrder,
    bool? active,
    Channel? channel,
    TimeBand? timeBand,
  }) {
    return TimeOfUseDetail(
      id: id ?? this.id,
      timeBandId: timeBandId ?? this.timeBandId,
      channelId: channelId ?? this.channelId,
      registerDisplayCode: registerDisplayCode ?? this.registerDisplayCode,
      priorityOrder: priorityOrder ?? this.priorityOrder,
      active: active ?? this.active,
      channel: channel ?? this.channel,
      timeBand: timeBand ?? this.timeBand,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeOfUseDetail && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TimeOfUseDetail(id: $id, timeBandId: $timeBandId, channelId: $channelId, registerDisplayCode: $registerDisplayCode, priorityOrder: $priorityOrder, active: $active)';
  }
}

/// Main Time of Use model
class TimeOfUse {
  final int? id;
  final String code;
  final String name;
  final String description;
  final bool active;
  final List<TimeOfUseDetail> timeOfUseDetails;

  TimeOfUse({
    this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.active,
    required this.timeOfUseDetails,
  });

  factory TimeOfUse.fromJson(Map<String, dynamic> json) {
    final details =
        (json['TimeOfUseDetails'] as List<dynamic>?)
            ?.map((detail) => TimeOfUseDetail.fromJson(detail))
            .toList() ??
        [];

    // Sort details by PriorityOrder (lowest number first, as it calculates first)
    details.sort((a, b) => a.priorityOrder.compareTo(b.priorityOrder));

    return TimeOfUse(
      id: json['Id'],
      code: json['Code'] ?? '',
      name: json['Name'] ?? '',
      description: json['Description'] ?? '',
      active: json['Active'] ?? true,
      timeOfUseDetails: details,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'Id': id,
      'Code': code,
      'Name': name,
      'Description': description,
      'Active': active,
      'TimeOfUseDetails': timeOfUseDetails
          .map((detail) => detail.toJson())
          .toList(),
    };
  }

  /// Create JSON for API creation
  Map<String, dynamic> toCreateJson() {
    return {
      'TimeOfUse': {
        'Code': code,
        'Name': name,
        'Description': description,
        'TimeOfUseDetails': {
          'on_conflict': {
            'constraint': 'PK_TimeOfUseDetail',
            'update_columns': [
              'TimeBandId',
              'ChannelId',
              'RegisterDisplayCode',
              'PriorityOrder',
              'Active',
            ],
          },
          'data': timeOfUseDetails
              .map(
                (detail) => {
                  'TimeBandId': detail.timeBandId,
                  'ChannelId': detail.channelId,
                  'RegisterDisplayCode': detail.registerDisplayCode,
                  'PriorityOrder': detail.priorityOrder,
                  'Active': detail.active,
                },
              )
              .toList(),
        },
      },
    };
  }

  /// Create JSON for API update
  Map<String, dynamic> toUpdateJson() {
    return {
      'TimeOfUse': {
        'Id': id.toString(),
        'Code': code,
        'Name': name,
        'Description': description,
        'Active': active,
      },
    };
  }

  /// Create a copy with updated fields
  TimeOfUse copyWith({
    int? id,
    String? code,
    String? name,
    String? description,
    bool? active,
    List<TimeOfUseDetail>? timeOfUseDetails,
  }) {
    final details = timeOfUseDetails ?? this.timeOfUseDetails;
    // Sort details by PriorityOrder whenever creating a copy
    final sortedDetails = List<TimeOfUseDetail>.from(details)
      ..sort((a, b) => a.priorityOrder.compareTo(b.priorityOrder));

    return TimeOfUse(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      active: active ?? this.active,
      timeOfUseDetails: sortedDetails,
    );
  }

  /// Get total number of time bands used
  int get totalTimeBands =>
      timeOfUseDetails.map((d) => d.timeBandId).toSet().length;

  /// Get total number of channels used
  int get totalChannels =>
      timeOfUseDetails.map((d) => d.channelId).toSet().length;

  /// Get status text based on active flag
  String get statusText => active ? 'Active' : 'Inactive';

  /// Get status color
  String get statusColor => active ? 'success' : 'error';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeOfUse && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TimeOfUse(id: $id, code: $code, name: $name, description: $description, active: $active)';
  }
}
