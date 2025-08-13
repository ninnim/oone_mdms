import '../models/response_models.dart';
import '../models/schedule.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';
import 'error_translation_service.dart';

class ScheduleService {
  final ApiService _apiService;

  ScheduleService(this._apiService);

  // Get all schedules
  Future<ApiResponse<List<Schedule>>> getSchedules({
    String search = ApiConstants.defaultSearch,
    int offset = ApiConstants.defaultOffset,
    int limit = ApiConstants.defaultLimit,
  }) async {
    try {
      final response = await _apiService.get(
        '/core/api/rest/v1/Schedule',
        queryParameters: {'offset': offset, 'limit': limit},
      );

      final data = response.data;
      final schedules =
          (data['Schedule'] as List?)
              ?.map((json) => Schedule.fromJson(json))
              .toList() ??
          [];

      // Extract pagination info
      final paging = data['Paging'];
      final total = paging?['Item']?['total'] ?? 0;

      return ApiResponse<List<Schedule>>(
        success: true,
        data: schedules,
        message: 'Schedules loaded successfully',
        paging: Paging(item: PagingItem(total: total)),
      );
    } catch (e) {
      final userFriendlyMessage =
          ErrorTranslationService.getContextualErrorMessage(e, 'schedule_list');
      return ApiResponse.error(userFriendlyMessage);
    }
  }

  // Get schedule by ID
  Future<ApiResponse<Schedule>> getScheduleById(String id) async {
    try {
      final response = await _apiService.get('/core/api/rest/v1/Schedule/$id');

      final data = response.data;
      final scheduleData = data['Schedule'];

      if (scheduleData == null) {
        return ApiResponse.error('Schedule not found');
      }

      final schedule = Schedule.fromJson(scheduleData);

      return ApiResponse.success(schedule);
    } catch (e) {
      final userFriendlyMessage =
          ErrorTranslationService.getContextualErrorMessage(
            e,
            'schedule_detail',
          );
      return ApiResponse.error(userFriendlyMessage);
    }
  }

  // Get schedules by device group ID
  Future<ApiResponse<List<Schedule>>> getSchedulesByDeviceGroupId(
    int deviceGroupId,
  ) async {
    try {
      final response = await _apiService.get(
        '/core/api/rest/v1/Schedule/DeviceGroup/$deviceGroupId',
      );

      final data = response.data;
      final schedules =
          (data['Schedule'] as List?)
              ?.map((json) => Schedule.fromJson(json))
              .toList() ??
          [];

      return ApiResponse.success(schedules);
    } catch (e) {
      final userFriendlyMessage =
          ErrorTranslationService.getContextualErrorMessage(
            e,
            'schedule_device_group_list',
          );
      return ApiResponse.error(userFriendlyMessage);
    }
  }

  // Get schedules by device ID
  Future<ApiResponse<List<Schedule>>> getSchedulesByDeviceId(
    String deviceId,
  ) async {
    try {
      final response = await _apiService.get(
        '/core/api/rest/v1/Schedule/Device/$deviceId',
      );

      final data = response.data;
      final schedules =
          (data['Schedule'] as List?)
              ?.map((json) => Schedule.fromJson(json))
              .toList() ??
          [];

      return ApiResponse.success(schedules);
    } catch (e) {
      final userFriendlyMessage =
          ErrorTranslationService.getContextualErrorMessage(
            e,
            'schedule_device_list',
          );
      return ApiResponse.error(userFriendlyMessage);
    }
  }

  // Create schedule
  Future<ApiResponse<Schedule>> createSchedule(Schedule schedule) async {
    try {
      final response = await _apiService.post(
        '/core/api/rest/v1/Schedule',
        data: schedule.toJson(),
      );

      final data = response.data;
      final createdSchedule = Schedule.fromJson(data);

      return ApiResponse.success(createdSchedule);
    } catch (e) {
      final userFriendlyMessage =
          ErrorTranslationService.getContextualErrorMessage(
            e,
            'schedule_create',
          );
      return ApiResponse.error(userFriendlyMessage);
    }
  }

  // Update schedule
  Future<ApiResponse<Schedule>> updateSchedule(
    String id,
    Schedule schedule,
  ) async {
    try {
      final response = await _apiService.put(
        '/core/api/rest/v1/Schedule/$id',
        data: schedule.toJson(),
      );

      final data = response.data;
      final updatedSchedule = Schedule.fromJson(data);

      return ApiResponse.success(updatedSchedule);
    } catch (e) {
      final userFriendlyMessage =
          ErrorTranslationService.getContextualErrorMessage(
            e,
            'schedule_update',
          );
      return ApiResponse.error(userFriendlyMessage);
    }
  }

  // Delete schedule
  Future<ApiResponse<bool>> deleteSchedule(String id) async {
    print('🔗 API: Attempting to delete schedule with ID: $id');
    try {
      print('🔗 API: Making DELETE request to /core/api/rest/v1/Schedule/$id');
      final response = await _apiService.delete(
        '/core/api/rest/v1/Schedule/$id',
      );
      print(
        '🔗 API: Delete request completed, status code: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        print('🔗 API: Delete successful (status 200)');
        return ApiResponse.success(true);
      } else {
        print('🔗 API: Delete failed with status code: ${response.statusCode}');
        return ApiResponse.error(
          'Failed to delete schedule (status: ${response.statusCode})',
        );
      }
    } catch (e) {
      print('🔗 API: Delete request failed with error: $e');
      final userFriendlyMessage =
          ErrorTranslationService.getContextualErrorMessage(
            e,
            'schedule_delete',
          );
      print('🔗 API: Translated error message: $userFriendlyMessage');
      return ApiResponse.error(userFriendlyMessage);
    }
  }
}
