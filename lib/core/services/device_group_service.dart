import '../models/device_group.dart';
import '../models/device.dart';
import '../models/response_models.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';
import 'error_translation_service.dart';

class DeviceGroupService {
  final ApiService _apiService;

  DeviceGroupService(this._apiService);

  // Get all device groups with pagination and search
  Future<ApiResponse<List<DeviceGroup>>> getDeviceGroups({
    String search = ApiConstants.defaultSearch,
    int offset = ApiConstants.defaultOffset,
    int limit = ApiConstants.defaultLimit,
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

      final listResponse = DeviceGroupListResponse.fromJson(response.data);
      final deviceGroups = listResponse.deviceGroups
          .map((json) => DeviceGroup.fromJson(json))
          .toList();

      return ApiResponse.success(deviceGroups, paging: listResponse.paging);
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

      final deviceGroupResponse = DeviceGroupResponse.fromJson(response.data);
      final deviceGroup = DeviceGroup.fromJson(deviceGroupResponse.deviceGroup);

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

  // Create device group with devices and removed devices
  Future<ApiResponse<DeviceGroup>> createDeviceGroup(
    DeviceGroup deviceGroup, {
    List<String> deviceIds = const [],
    List<String> removedDeviceIds = const [],
  }) async {
    try {
      final requestData = {
        'DeviceGroup': {
          'Name': deviceGroup.name,
          'Description': deviceGroup.description,
          'Devices': {
            'on_conflict': {
              'constraint': 'PK_Device',
              'update_columns': ['DeviceGroupId'],
            },
            'data': deviceIds.map((id) => {'Id': id}).toList(),
          },
        },
        'RemovedDevices': removedDeviceIds,
      };

      final response = await _apiService.post(
        ApiConstants.deviceGroups,
        data: requestData,
      );

      final deviceGroupResponse = DeviceGroupCreateResponse.fromJson(
        response.data,
      );
      final createdGroup = DeviceGroup.fromJson(
        deviceGroupResponse.deviceGroup,
      );

      return ApiResponse.success(createdGroup);
    } catch (e) {
      final userFriendlyMessage =
          ErrorTranslationService.getContextualErrorMessage(
            e,
            'device_group_create',
          );
      return ApiResponse.error(userFriendlyMessage);
    }
  }

  // Update device group with devices and removed devices
  Future<ApiResponse<DeviceGroup>> updateDeviceGroup(
    DeviceGroup deviceGroup, {
    List<String> deviceIds = const [],
    List<String> removedDeviceIds = const [],
  }) async {
    try {
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
            'data': deviceIds.map((id) => {'Id': id}).toList(),
          },
        },
        'RemovedDevices': removedDeviceIds,
      };

      final response = await _apiService.post(
        ApiConstants.deviceGroups,
        data: requestData,
      );

      final deviceGroupResponse = DeviceGroupCreateResponse.fromJson(
        response.data,
      );
      final updatedGroup = DeviceGroup.fromJson(
        deviceGroupResponse.deviceGroup,
      );

      return ApiResponse.success(updatedGroup);
    } catch (e) {
      final userFriendlyMessage =
          ErrorTranslationService.getContextualErrorMessage(
            e,
            'device_group_update',
          );
      return ApiResponse.error(userFriendlyMessage);
    }
  }

  // Delete device group
  Future<ApiResponse<DeviceGroup>> deleteDeviceGroup(int id) async {
    try {
      final response = await _apiService.delete(
        '${ApiConstants.deviceGroups}/$id',
      );

      final deviceGroupResponse = DeviceGroupCreateResponse.fromJson(
        response.data,
      );
      final deletedGroup = DeviceGroup.fromJson(
        deviceGroupResponse.deviceGroup,
      );

      return ApiResponse.success(deletedGroup);
    } catch (e) {
      final userFriendlyMessage =
          ErrorTranslationService.getContextualErrorMessage(
            e,
            'device_group_delete',
          );
      return ApiResponse.error(userFriendlyMessage);
    }
  }

  // Add devices to group
  Future<ApiResponse<DeviceGroup>> addDevicesToGroup(
    int groupId,
    List<String> deviceIds,
  ) async {
    try {
      // First get the current group to maintain existing data
      final groupResponse = await getDeviceGroupById(groupId);
      if (!groupResponse.success || groupResponse.data == null) {
        return ApiResponse.error('Failed to get device group');
      }

      final currentGroup = groupResponse.data!;
      final existingDeviceIds =
          currentGroup.devices?.map((d) => d.id).toList() ?? [];

      // Combine existing and new device IDs
      final allDeviceIds = [...existingDeviceIds, ...deviceIds];

      final requestData = {
        'DeviceGroup': {
          'Id': groupId,
          'Name': currentGroup.name,
          'Description': currentGroup.description,
          'Devices': {
            'on_conflict': {
              'constraint': 'PK_Device',
              'update_columns': ['DeviceGroupId'],
            },
            'data': allDeviceIds.map((id) => {'Id': id}).toList(),
          },
        },
        'RemovedDevices': [],
      };

      final response = await _apiService.post(
        ApiConstants.deviceGroups,
        data: requestData,
      );

      final deviceGroupResponse = DeviceGroupCreateResponse.fromJson(
        response.data,
      );
      final updatedGroup = DeviceGroup.fromJson(
        deviceGroupResponse.deviceGroup,
      );

      return ApiResponse.success(updatedGroup);
    } catch (e) {
      final userFriendlyMessage =
          ErrorTranslationService.getContextualErrorMessage(
            e,
            'device_group_add_devices',
          );
      return ApiResponse.error(userFriendlyMessage);
    }
  }

  // Remove devices from group
  Future<ApiResponse<DeviceGroup>> removeDevicesFromGroup(
    int groupId,
    List<String> deviceIds,
  ) async {
    try {
      // First get the current group
      final groupResponse = await getDeviceGroupById(groupId);
      if (!groupResponse.success || groupResponse.data == null) {
        return ApiResponse.error('Failed to get device group');
      }

      final currentGroup = groupResponse.data!;

      final requestData = {
        'DeviceGroup': {
          'Id': groupId,
          'Name': currentGroup.name,
          'Description': currentGroup.description,
          'Devices': {
            'on_conflict': {
              'constraint': 'PK_Device',
              'update_columns': ['DeviceGroupId'],
            },
            'data': [], // Keep existing devices except those to be removed
          },
        },
        'RemovedDevices': deviceIds,
      };

      final response = await _apiService.post(
        ApiConstants.deviceGroups,
        data: requestData,
      );

      final deviceGroupResponse = DeviceGroupCreateResponse.fromJson(
        response.data,
      );
      final updatedGroup = DeviceGroup.fromJson(
        deviceGroupResponse.deviceGroup,
      );

      return ApiResponse.success(updatedGroup);
    } catch (e) {
      final userFriendlyMessage =
          ErrorTranslationService.getContextualErrorMessage(
            e,
            'device_group_remove_devices',
          );
      return ApiResponse.error(userFriendlyMessage);
    }
  }

  // Get available devices (not assigned to any group)
  Future<ApiResponse<List<Device>>> getAvailableDevices({
    String search = ApiConstants.defaultSearch,
    int offset = ApiConstants.defaultOffset,
    int limit = ApiConstants.defaultLimit,
  }) async {
    try {
      // Use the Device Filter API to get devices with no group
      final response = await _apiService.post(
        ApiConstants.deviceFilter,
        queryParameters: {
          'search': '%$search%',
          'offset': offset,
          'limit': limit,
        },
        data: {
          'filter': {
            'DeviceGroupId': {'_eq': 0},
          },
        },
      );

      final listResponse = DeviceListResponse.fromJson(response.data);
      final availableDevices = listResponse.devices
          .map((json) => Device.fromJson(json))
          .toList();

      return ApiResponse.success(availableDevices, paging: listResponse.paging);
    } catch (e) {
      final userFriendlyMessage =
          ErrorTranslationService.getContextualErrorMessage(
            e,
            'available_devices',
          );
      return ApiResponse.error(userFriendlyMessage);
    }
  }

  // Get devices assigned to a specific group
  Future<ApiResponse<List<Device>>> getDevicesInGroup({
    required int groupId,
    String search = ApiConstants.defaultSearch,
    int offset = ApiConstants.defaultOffset,
    int limit = ApiConstants.defaultLimit,
  }) async {
    try {
      // Use the Device Filter API to get devices in a specific group
      final response = await _apiService.post(
        ApiConstants.deviceFilter,
        queryParameters: {
          'search': '%$search%',
          'offset': offset,
          'limit': limit,
        },
        data: {
          'filter': {
            'DeviceGroupId': {'_eq': groupId},
          },
        },
      );

      final listResponse = DeviceListResponse.fromJson(response.data);
      final groupDevices = listResponse.devices
          .map((json) => Device.fromJson(json))
          .toList();

      return ApiResponse.success(groupDevices, paging: listResponse.paging);
    } catch (e) {
      final userFriendlyMessage =
          ErrorTranslationService.getContextualErrorMessage(e, 'group_devices');
      return ApiResponse.error(userFriendlyMessage);
    }
  }
}
