import 'package:mdms_clone/core/models/device_group.dart';

import 'address.dart';

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

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['Id'] ?? 0,
      code: json['Code'] ?? '',
      name: json['Name'] ?? '',
      units: json['Units'] ?? '',
      flowDirection: json['FlowDirection'] ?? '',
      phase: json['Phase'] ?? '',
      apportionPolicy: json['ApportionPolicy'] ?? '',
      active: json['Active'] ?? false,
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
}

class DeviceChannel {
  final String id;
  final String deviceId;
  final int channelId;
  final bool applyMetric;
  final double cumulative;
  final bool active;
  final Channel? channel;

  DeviceChannel({
    required this.id,
    required this.deviceId,
    required this.channelId,
    required this.applyMetric,
    required this.cumulative,
    required this.active,
    this.channel,
  });

  factory DeviceChannel.fromJson(Map<String, dynamic> json) {
    return DeviceChannel(
      id: json['Id'] ?? '',
      deviceId: json['DeviceId'] ?? '',
      channelId: json['ChannelId'] ?? 0,
      applyMetric: json['ApplyMetric'] ?? false,
      cumulative: (json['Cumulative'] ?? 0).toDouble(),
      active: json['Active'] ?? false,
      channel: json['Channel'] != null
          ? Channel.fromJson(json['Channel'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'DeviceId': deviceId,
      'ChannelId': channelId,
      'ApplyMetric': applyMetric,
      'Cumulative': cumulative,
      'Active': active,
      if (channel != null) 'Channel': channel!.toJson(),
    };
  }
}

class DeviceAttribute {
  final String id;
  final String deviceId;
  final String name;
  final String value;

  DeviceAttribute({
    required this.id,
    required this.deviceId,
    required this.name,
    required this.value,
  });

  factory DeviceAttribute.fromJson(Map<String, dynamic> json) {
    return DeviceAttribute(
      id: json['Id'] ?? '',
      deviceId: json['DeviceId'] ?? '',
      name: json['Name'] ?? '',
      value: json['Value'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'Id': id, 'DeviceId': deviceId, 'Name': name, 'Value': value};
  }
}

class Device {
  final String? id;
  final String serialNumber;
  final String name;
  final String deviceType;
  final String model;
  final String manufacturer;
  final String status;
  final String linkStatus;
  final bool active;
  final int deviceGroupId;
  final String addressId;
  final String addressText;
  final DeviceGroup? deviceGroup;
  final Address? address;
  final List<DeviceChannel> deviceChannels;
  final List<DeviceAttribute> deviceAttributes;

  Device({
    this.id,
    required this.serialNumber,
    required this.name,
    required this.deviceType,
    required this.model,
    required this.manufacturer,
    required this.status,
    required this.linkStatus,
    required this.active,
    required this.deviceGroupId,
    required this.addressId,
    required this.addressText,
    this.deviceGroup,
    this.address,
    required this.deviceChannels,
    required this.deviceAttributes,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['Id'] ?? '',
      serialNumber: json['SerialNumber'] ?? '',
      name: json['Name'] ?? '',
      deviceType: json['DeviceType'] ?? '',
      model: json['Model'] ?? '',
      manufacturer: json['Manufacturer'] ?? '',
      status: json['Status'] ?? '',
      linkStatus: json['LinkStatus'] ?? '',
      active: json['Active'] ?? false,
      deviceGroupId: json['DeviceGroupId'] ?? 0,
      addressId: json['AddressId'] ?? '',
      addressText: json['AddressText'] ?? '',
      deviceGroup: json['DeviceGroup'] != null
          ? DeviceGroup.fromJson(json['DeviceGroup'])
          : null,
      address: json['Address'] != null
          ? Address.fromJson(json['Address'])
          : null,
      deviceChannels:
          (json['DeviceChannels'] as List?)
              ?.map((e) => DeviceChannel.fromJson(e))
              .toList() ??
          [],
      deviceAttributes:
          (json['DeviceAttributes'] as List?)
              ?.map((e) => DeviceAttribute.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'SerialNumber': serialNumber,
      'Name': name,
      'DeviceType': deviceType,
      'Model': model,
      'Manufacturer': manufacturer,
      'Status': status,
      'LinkStatus': linkStatus,
      'Active': active,
      'DeviceGroupId': deviceGroupId,
      'AddressId': addressId,
      'AddressText': addressText,
      if (deviceGroup != null) 'DeviceGroup': deviceGroup!.toJson(),
      if (address != null) 'Address': address!.toJson(),
      'DeviceChannels': deviceChannels.map((e) => e.toJson()).toList(),
      'DeviceAttributes': deviceAttributes.map((e) => e.toJson()).toList(),
    };
  }

  Device copyWith({
    String? id,
    String? serialNumber,
    String? name,
    String? deviceType,
    String? model,
    String? manufacturer,
    String? status,
    String? linkStatus,
    bool? active,
    int? deviceGroupId,
    String? addressId,
    String? addressText,
    DeviceGroup? deviceGroup,
    Address? address,
    List<DeviceChannel>? deviceChannels,
    List<DeviceAttribute>? deviceAttributes,
  }) {
    return Device(
      id: id ?? this.id,
      serialNumber: serialNumber ?? this.serialNumber,
      name: name ?? this.name,
      deviceType: deviceType ?? this.deviceType,
      model: model ?? this.model,
      manufacturer: manufacturer ?? this.manufacturer,
      status: status ?? this.status,
      linkStatus: linkStatus ?? this.linkStatus,
      active: active ?? this.active,
      deviceGroupId: deviceGroupId ?? this.deviceGroupId,
      addressId: addressId ?? this.addressId,
      addressText: addressText ?? this.addressText,
      address: address ?? this.address,
      deviceGroup: deviceGroup ?? this.deviceGroup,
      deviceChannels: deviceChannels ?? this.deviceChannels,
      deviceAttributes: deviceAttributes ?? this.deviceAttributes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Device && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Device(id: $id, serialNumber: $serialNumber, name: $name, deviceType: $deviceType, model: $model, manufacturer: $manufacturer, status: $status, linkStatus: $linkStatus, active: $active)';
  }
}

// Device Status enum for easier handling
enum DeviceStatus {
  commissioned('Commissioned'),
  none('None'),
  renovation('Renovation'),
  construction('Construction');

  const DeviceStatus(this.value);
  final String value;

  static DeviceStatus fromString(String value) {
    return DeviceStatus.values.firstWhere(
      (e) => e.value.toLowerCase() == value.toLowerCase(),
      orElse: () => DeviceStatus.none,
    );
  }
}

// Link Status enum
enum LinkStatus {
  multidrive('MULTIDRIVE'),
  none('None'),
  connected('Connected'),
  disconnected('Disconnected');

  const LinkStatus(this.value);
  final String value;

  static LinkStatus fromString(String value) {
    return LinkStatus.values.firstWhere(
      (e) => e.value.toLowerCase() == value.toLowerCase(),
      orElse: () => LinkStatus.none,
    );
  }
}
