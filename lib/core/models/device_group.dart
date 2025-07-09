import 'device.dart';

class DeviceGroup {
  final int id;
  final String name;
  final String description;
  final bool active;
  final List<Device> devices;

  DeviceGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.active,
    required this.devices,
  });

  factory DeviceGroup.fromJson(Map<String, dynamic> json) {
    return DeviceGroup(
      id: json['Id'] ?? 0,
      name: json['Name'] ?? '',
      description: json['Description'] ?? '',
      active: json['Active'] ?? false,
      devices:
          (json['Devices'] as List?)?.map((e) => Device.fromJson(e)).toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Name': name,
      'Description': description,
      'Active': active,
      'Devices': devices.map((e) => e.toJson()).toList(),
    };
  }

  DeviceGroup copyWith({
    int? id,
    String? name,
    String? description,
    bool? active,
    List<Device>? devices,
  }) {
    return DeviceGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      active: active ?? this.active,
      devices: devices ?? this.devices,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceGroup && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'DeviceGroup(id: $id, name: $name, description: $description, active: $active, devices: ${devices.length})';
  }
}
