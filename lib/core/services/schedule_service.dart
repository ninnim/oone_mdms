import '../models/response_models.dart';
import '../models/schedule.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

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
        '${ApiConstants.baseUrl}/core/api/rest/v1/Schedule',
        queryParameters: {'offset': offset, 'limit': limit},
      );

      final schedulesList = (response.data['Schedule'] as List)
          .map((json) => Schedule.fromJson(json))
          .toList();

      return ApiResponse.success(schedulesList);
    } catch (e) {
      return ApiResponse.error('Failed to fetch schedules: $e');
    }
  }

  // Get schedule by ID
  Future<ApiResponse<Schedule>> getScheduleById(String id) async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.baseUrl}/core/api/rest/v1/Schedule/$id',
      );

      final schedule = Schedule.fromJson(response.data['Schedule']);
      return ApiResponse.success(schedule);
    } catch (e) {
      return ApiResponse.error('Failed to fetch schedule: $e');
    }
  }

  // Get schedules by device group ID
  Future<ApiResponse<List<Schedule>>> getSchedulesByDeviceGroupId(
    int deviceGroupId,
  ) async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.baseUrl}/core/api/rest/v1/Schedule/DeviceGroup/$deviceGroupId',
      );

      final schedulesList = (response.data['Schedule'] as List)
          .map((json) => Schedule.fromJson(json))
          .toList();

      return ApiResponse.success(schedulesList);
    } catch (e) {
      return ApiResponse.error(
        'Failed to fetch schedules for device group: $e',
      );
    }
  }

  // Get schedules by device ID
  Future<ApiResponse<List<Schedule>>> getSchedulesByDeviceId(
    String deviceId,
  ) async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.baseUrl}/core/api/rest/v1/Schedule/Device/$deviceId',
      );

      final schedulesList = (response.data['Schedule'] as List)
          .map((json) => Schedule.fromJson(json))
          .toList();

      return ApiResponse.success(schedulesList);
    } catch (e) {
      return ApiResponse.error('Failed to fetch schedules for device: $e');
    }
  }
}
