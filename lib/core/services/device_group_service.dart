import '../models/device.dart';
import '../models/device_group.dart';
import '../models/response_models.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';
import 'error_translation_service.dart';

class DeviceGroupService {
  final ApiService _apiService;

  DeviceGroupService(this._apiService);

  // Get all device groups
  Future<ApiResponse<List<DeviceGroup>>> getDeviceGroups({
    String search = '%%',
    int offset = 0,
    int limit = 25,
    bool includeDevices = true,
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

      // Based on API spec: {"Paging": {"Item": {"Total": 1}}, "DeviceGroup": [...]}
      final data = response.data;
      final deviceGroupsJson = data['DeviceGroup'] as List<dynamic>;
      final deviceGroups = deviceGroupsJson
          .map((json) => DeviceGroup.fromJson(json))
          .toList();

      // Extract paging info if available
      final pagingData = data['Paging'] as Map<String, dynamic>?;
      final totalItems = pagingData?['Item']?['Total'] as int? ?? deviceGroups.length;

      return ApiResponse.success(
        deviceGroups, 
        paging: Paging(
          item: PagingItem(total: totalItems),
        ),
      );
    } catch (e) {
      final userFriendlyMessage =
          ErrorTranslationService.getContextualErrorMessage(
            e,
            'device_group_list',
          );
      return ApiResponse.error(userFriendlyMessage);
    }
  }

  // Get device group by ID
  Future<ApiResponse<DeviceGroup>> getDeviceGroupById(
    int id, {
    bool includeDevices = true,
  }) async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.deviceGroups}/$id',
        queryParameters: {'includeDevices': includeDevices},
      );

      // Based on API spec: {"DeviceGroup": {...}}
      final deviceGroupJson = response.data['DeviceGroup'] as Map<String, dynamic>;
      final deviceGroup = DeviceGroup.fromJson(deviceGroupJson);

      return ApiResponse.success(deviceGroup);
    } catch (e) {
      final userFriendlyMessage =
          ErrorTranslationService.getContextualErrorMessage(
            e,
            'device_group_detail',
          );
      return ApiResponse.error(userFriendlyMessage);
    }
  }

  // Create device group
  Future<ApiResponse<DeviceGroup>> createDeviceGroup(DeviceGroup deviceGroup) async {
    try {
      // Based on API spec request structure
      final requestData = {
        'DeviceGroup': {
          'Name': deviceGroup.name,
          'Description': deviceGroup.description,
          'Devices': {
            'on_conflict': {
              'constraint': 'PK_Device',
              'update_columns': ['DeviceGroupId'],
            },
            'data': deviceGroup.devices?.map((device) => {'Id': device.id}).toList() ?? [],
          },
        },
        'RemovedDevices': [],
      };

      final response = await _apiService.post(
        ApiConstants.deviceGroups,
        data: requestData,
      );

      // Based on API spec response: {"DeviceGroup": {...}, "RemovedDevices": {...}}
      final deviceGroupJson = response.data['DeviceGroup'] as Map<String, dynamic>;
      final createdDeviceGroup = DeviceGroup.fromJson(deviceGroupJson);

      return ApiResponse.success(createdDeviceGroup);
    } catch (e) {
      final userFriendlyMessage =
          ErrorTranslationService.getContextualErrorMessage(e, 'device_group_create');
      return ApiResponse.error(userFriendlyMessage);
    }
  }

  // Update device group
  Future<ApiResponse<DeviceGroup>> updateDeviceGroup(DeviceGroup deviceGroup, {List<Device>? removedDevices}) async {
    try {
      // Based on API spec request structure for update
      final requestData = {
        'DeviceGroup': {
          'Id': deviceGroup.id,
          'Name': deviceGroup.name,
          'Description': deviceGroup.description,
          'Devices': {
            'on_conflict': {
              'constraint': 'PK_Device',
              'update_columns': ['DeviceGroupId'],
            },
            'data': deviceGroup.devices?.map((device) => {'Id': device.id}).toList() ?? [],
          },
        },
        'RemovedDevices': removedDevices?.map((device) => device.id).toList() ?? [],
      };

      final response = await _apiService.post(
        ApiConstants.deviceGroups,
        data: requestData,
      );

      // Based on API spec response: {"DeviceGroup": {...}, "RemovedDevices": {...}}
      final deviceGroupJson = response.data['DeviceGroup'] as Map<String, dynamic>;
      final updatedDeviceGroup = DeviceGroup.fromJson(deviceGroupJson);

      return ApiResponse.success(updatedDeviceGroup);
    } catch (e) {
      final userFriendlyMessage =
          ErrorTranslationService.getContextualErrorMessage(e, 'device_group_update');
      return ApiResponse.error(userFriendlyMessage);
    }
  }

  // Delete device group
  Future<ApiResponse<bool>> deleteDeviceGroup(int id) async {
    try {
      await _apiService.delete('${ApiConstants.deviceGroups}/$id');
      return ApiResponse.success(true);
    } catch (e) {
      final userFriendlyMessage =
          ErrorTranslationService.getContextualErrorMessage(e, 'device_group_delete');
      return ApiResponse.error(userFriendlyMessage);
    }
  }
}
