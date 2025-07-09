import '../models/device.dart';
import '../models/device_group.dart';
import '../models/response_models.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

class DeviceService {
  final ApiService _apiService;

  DeviceService(this._apiService);

  // Get all devices
  Future<ApiResponse<List<Device>>> getDevices({
    String search = ApiConstants.defaultSearch,
    int offset = ApiConstants.defaultOffset,
    int limit = ApiConstants.defaultLimit,
  }) async {
    try {
      final response = await _apiService.get(
        ApiConstants.devices,
        queryParameters: {'search': search, 'offset': offset, 'limit': limit},
      );

      final listResponse = DeviceListResponse.fromJson(response.data);
      final devices = listResponse.devices
          .map((json) => Device.fromJson(json))
          .toList();

      return ApiResponse.success(devices, paging: listResponse.paging);
    } catch (e) {
      return ApiResponse.error('Failed to fetch devices: $e');
    }
  }

  // Get device by ID
  Future<ApiResponse<Device>> getDeviceById(String id) async {
    try {
      final response = await _apiService.get('${ApiConstants.devices}/$id');

      final deviceResponse = DeviceResponse.fromJson(response.data);
      final device = Device.fromJson(deviceResponse.device);

      return ApiResponse.success(device);
    } catch (e) {
      return ApiResponse.error('Failed to fetch device: $e');
    }
  }

  // Create device
  Future<ApiResponse<Device>> createDevice(Device device) async {
    try {
      final requestData = {
        'Device': {
          'SerialNumber': device.serialNumber,
          'Model': device.model,
          'DeviceType': device.deviceType,
          'Manufacturer': device.manufacturer,
          'AddressText': device.addressText,
          if (device.address != null)
            'Address': {'data': device.address!.toJson()},
          'DeviceChannels': {
            'on_conflict': {
              'constraint': 'PK_DeviceChannel',
              'update_columns': ['ApplyMetric', 'Cumulative'],
            },
            'data': device.deviceChannels.map((e) => e.toJson()).toList(),
          },
        },
      };

      final response = await _apiService.post(
        ApiConstants.devices,
        data: requestData,
      );

      final deviceResponse = DeviceResponse.fromJson(response.data);
      final createdDevice = Device.fromJson(deviceResponse.device);

      return ApiResponse.success(createdDevice);
    } catch (e) {
      return ApiResponse.error('Failed to create device: $e');
    }
  }

  // Update device
  Future<ApiResponse<Device>> updateDevice(Device device) async {
    try {
      final requestData = {
        'Device': {
          'Id': device.id,
          'SerialNumber': device.serialNumber,
          'Model': device.model,
          'DeviceType': device.deviceType,
          'Manufacturer': device.manufacturer,
          'Status': device.status,
          'LinkStatus': device.linkStatus,
          'DeviceGroupId': device.deviceGroupId,
          'AddressText': device.addressText,
          if (device.address != null)
            'Address': {
              'on_conflict': {
                'constraint': 'PK_Address',
                'update_columns': [
                  'Latitute',
                  'Longtitute',
                  'LongText',
                  'ShortText',
                ],
              },
              'data': {...device.address!.toJson(), 'Id': device.addressId},
            },
          'DeviceChannels': {
            'on_conflict': {
              'constraint': 'PK_DeviceChannel',
              'update_columns': ['ApplyMetric', 'Cumulative'],
            },
            'data': device.deviceChannels.map((e) => e.toJson()).toList(),
          },
        },
      };

      final response = await _apiService.post(
        ApiConstants.devices,
        data: requestData,
      );

      final deviceResponse = DeviceResponse.fromJson(response.data);
      final updatedDevice = Device.fromJson(deviceResponse.device);

      return ApiResponse.success(updatedDevice);
    } catch (e) {
      return ApiResponse.error('Failed to update device: $e');
    }
  }

  // Delete device
  Future<ApiResponse<bool>> deleteDevice(String id) async {
    try {
      await _apiService.delete('${ApiConstants.devices}/$id');
      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.error('Failed to delete device: $e');
    }
  }

  // Filter devices
  Future<ApiResponse<List<Device>>> filterDevices({
    Map<String, dynamic>? filter,
    String search = ApiConstants.defaultSearch,
    int offset = ApiConstants.defaultOffset,
    int limit = ApiConstants.defaultLimit,
  }) async {
    try {
      final requestData = {if (filter != null) 'filter': filter};

      final response = await _apiService.post(
        ApiConstants.deviceFilter,
        data: requestData,
        queryParameters: {'search': search, 'offset': offset, 'limit': limit},
      );

      final listResponse = DeviceListResponse.fromJson(response.data);
      final devices = listResponse.devices
          .map((json) => Device.fromJson(json))
          .toList();

      return ApiResponse.success(devices, paging: listResponse.paging);
    } catch (e) {
      return ApiResponse.error('Failed to filter devices: $e');
    }
  }

  // Link device to HES
  Future<ApiResponse<bool>> linkDeviceToHes(String deviceId) async {
    try {
      final requestData = {'DeviceId': deviceId};

      await _apiService.post(ApiConstants.linkHes, data: requestData);

      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.error('Failed to link device to HES: $e');
    }
  }

  // Get device groups
  Future<ApiResponse<List<DeviceGroup>>> getDeviceGroups({
    String search = ApiConstants.defaultSearch,
    int offset = ApiConstants.defaultOffset,
    int limit = ApiConstants.defaultLimit,
    bool includeDevices = false,
  }) async {
    try {
      final response = await _apiService.get(
        ApiConstants.deviceGroups,
        queryParameters: {
          'search': search,
          'offset': offset,
          'limit': limit,
          'includeDevices': includeDevices,
        },
      );

      final listResponse = DeviceGroupListResponse.fromJson(response.data);
      final deviceGroups = listResponse.deviceGroups
          .map((json) => DeviceGroup.fromJson(json))
          .toList();

      return ApiResponse.success(deviceGroups, paging: listResponse.paging);
    } catch (e) {
      return ApiResponse.error('Failed to fetch device groups: $e');
    }
  }

  // Get device group by ID
  Future<ApiResponse<DeviceGroup>> getDeviceGroupById(
    int id, {
    bool includeDevices = false,
  }) async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.deviceGroups}/$id',
        queryParameters: {'includeDevices': includeDevices},
      );

      final deviceGroup = DeviceGroup.fromJson(response.data['DeviceGroup']);
      return ApiResponse.success(deviceGroup);
    } catch (e) {
      return ApiResponse.error('Failed to fetch device group: $e');
    }
  }

  // Link device to HES
  Future<ApiResponse<String>> linkToHes(String deviceId) async {
    try {
      final response = await _apiService.post(
        ApiConstants.linkHes,
        data: {'DeviceId': deviceId},
      );

      final message = response.data['Message'] ?? 'Device linked successfully';
      return ApiResponse.success(message);
    } catch (e) {
      return ApiResponse.error('Failed to link device to HES: $e');
    }
  }

  // Get device metrics
  Future<ApiResponse<Map<String, dynamic>>> getDeviceMetrics(
    String deviceId, {
    String? startDate,
    String? endDate,
    int limit = 25,
    int offset = 0,
  }) async {
    try {
      final requestData = {
        'limit': limit,
        'offset': offset,
        'where': {
          '_and': [
            if (startDate != null)
              {
                'Timestamp': {'_gte': startDate},
              },
            if (endDate != null)
              {
                'Timestamp': {'_lte': endDate},
              },
          ],
        },
      };

      final endpoint = ApiConstants.deviceMetrics.replaceAll('{id}', deviceId);
      final response = await _apiService.post(endpoint, data: requestData);

      return ApiResponse.success(response.data);
    } catch (e) {
      return ApiResponse.error('Failed to fetch device metrics: $e');
    }
  }

  // Get device billing
  Future<ApiResponse<Map<String, dynamic>>> getDeviceBilling(
    String deviceId, {
    int limit = 25,
    int offset = 0,
  }) async {
    try {
      final endpoint = ApiConstants.deviceBilling.replaceAll('{id}', deviceId);
      final response = await _apiService.get(
        endpoint,
        queryParameters: {'limit': limit, 'offset': offset},
      );

      return ApiResponse.success(response.data);
    } catch (e) {
      return ApiResponse.error('Failed to fetch device billing: $e');
    }
  }

  // Get device billing readings
  Future<ApiResponse<Map<String, dynamic>>> getDeviceBillingReadings(
    String deviceId, {
    required String startTime,
    required String endTime,
  }) async {
    try {
      final endpoint = ApiConstants.deviceBillingReadings.replaceAll(
        '{id}',
        deviceId,
      );
      final response = await _apiService.get(
        endpoint,
        queryParameters: {'startTime': startTime, 'endTime': endTime},
      );

      return ApiResponse.success(response.data);
    } catch (e) {
      return ApiResponse.error('Failed to fetch device billing readings: $e');
    }
  }

  // Ping device
  Future<ApiResponse<Map<String, dynamic>>> pingDevice(String deviceId) async {
    try {
      final endpoint = ApiConstants.pingDevice.replaceAll('{id}', deviceId);
      final response = await _apiService.post(endpoint);

      return ApiResponse.success(response.data);
    } catch (e) {
      return ApiResponse.error('Failed to ping device: $e');
    }
  }

  // Commission device
  Future<ApiResponse<Map<String, dynamic>>> commissionDevice(
    String deviceId,
  ) async {
    try {
      final endpoint = ApiConstants.commissionDevice.replaceAll(
        '{id}',
        deviceId,
      );
      final response = await _apiService.post(endpoint);

      return ApiResponse.success(response.data);
    } catch (e) {
      return ApiResponse.error('Failed to commission device: $e');
    }
  }

  // Link device to HES (improved implementation)
  Future<ApiResponse<Map<String, dynamic>>> linkDeviceToHES(
    String deviceId,
  ) async {
    try {
      final response = await _apiService.post(
        ApiConstants.linkHes,
        data: {'deviceId': deviceId},
      );

      return ApiResponse.success(response.data);
    } catch (e) {
      return ApiResponse.error('Failed to link device to HES: $e');
    }
  }

  // Get devices with location data for map clustering
  Future<ApiResponse<List<Device>>> getDevicesForMap({
    String search = ApiConstants.defaultSearch,
    int offset = ApiConstants.defaultOffset,
    int limit = ApiConstants.defaultLimit,
  }) async {
    try {
      final filter = {
        "AddressText": {"_neq": ""},
      };

      final requestData = {'filter': filter};

      final response = await _apiService.post(
        ApiConstants.deviceFilter,
        data: requestData,
        queryParameters: {'search': search, 'offset': offset, 'limit': limit},
      );

      final listResponse = DeviceListResponse.fromJson(response.data);
      final devices = listResponse.devices
          .map((json) => Device.fromJson(json))
          .toList();

      return ApiResponse.success(devices, paging: listResponse.paging);
    } catch (e) {
      return ApiResponse.error('Failed to fetch devices for map: $e');
    }
  }
}
