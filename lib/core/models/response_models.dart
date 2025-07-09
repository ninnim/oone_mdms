class Paging {
  final PagingItem item;

  Paging({required this.item});

  factory Paging.fromJson(Map<String, dynamic> json) {
    return Paging(item: PagingItem.fromJson(json['Item'] ?? {}));
  }

  Map<String, dynamic> toJson() {
    return {'Item': item.toJson()};
  }
}

class PagingItem {
  final int total;

  PagingItem({required this.total});

  factory PagingItem.fromJson(Map<String, dynamic> json) {
    return PagingItem(total: json['Total'] ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {'Total': total};
  }
}

class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final Paging? paging;

  ApiResponse({required this.success, this.message, this.data, this.paging});

  factory ApiResponse.success(T data, {Paging? paging}) {
    return ApiResponse<T>(success: true, data: data, paging: paging);
  }

  factory ApiResponse.error(String message) {
    return ApiResponse<T>(success: false, message: message);
  }
}

class DeviceListResponse {
  final Paging paging;
  final List<dynamic> devices;

  DeviceListResponse({required this.paging, required this.devices});

  factory DeviceListResponse.fromJson(Map<String, dynamic> json) {
    return DeviceListResponse(
      paging: Paging.fromJson(json['Paging'] ?? {}),
      devices: json['Device'] ?? [],
    );
  }
}

class DeviceResponse {
  final dynamic device;

  DeviceResponse({required this.device});

  factory DeviceResponse.fromJson(Map<String, dynamic> json) {
    return DeviceResponse(device: json['Device']);
  }
}

class DeviceGroupListResponse {
  final Paging paging;
  final List<dynamic> deviceGroups;

  DeviceGroupListResponse({required this.paging, required this.deviceGroups});

  factory DeviceGroupListResponse.fromJson(Map<String, dynamic> json) {
    return DeviceGroupListResponse(
      paging: Paging.fromJson(json['Paging'] ?? {}),
      deviceGroups: json['DeviceGroup'] ?? [],
    );
  }
}
