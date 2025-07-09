import '../models/response_models.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

class ScheduleService {
  final ApiService _apiService;

  ScheduleService(this._apiService);

  // Get all schedules
  Future<ApiResponse<List<Map<String, dynamic>>>> getSchedules({
    String search = ApiConstants.defaultSearch,
    int offset = ApiConstants.defaultOffset,
    int limit = ApiConstants.defaultLimit,
  }) async {
    try {
      // TODO: Implement when schedule_spec.json is provided
      // For now, return mock data
      final mockSchedules = [
        {
          'id': 1,
          'name': 'Daily Schedule',
          'description': 'Daily data collection',
        },
        {
          'id': 2,
          'name': 'Weekly Schedule',
          'description': 'Weekly data collection',
        },
        {
          'id': 3,
          'name': 'Monthly Schedule',
          'description': 'Monthly data collection',
        },
      ];

      return ApiResponse.success(mockSchedules);

      // Actual implementation will be:
      // final response = await _apiService.get(
      //   ApiConstants.schedules,
      //   queryParameters: {'search': search, 'offset': offset, 'limit': limit},
      // );
      //
      // final schedules = (response.data['Schedules'] as List)
      //     .cast<Map<String, dynamic>>();
      //
      // return ApiResponse.success(schedules);
    } catch (e) {
      return ApiResponse.error('Failed to fetch schedules: $e');
    }
  }

  // Get schedule by ID
  Future<ApiResponse<Map<String, dynamic>>> getScheduleById(int id) async {
    try {
      // TODO: Implement when schedule_spec.json is provided
      final mockSchedule = {
        'id': id,
        'name': 'Schedule $id',
        'description': 'Schedule description',
      };

      return ApiResponse.success(mockSchedule);
    } catch (e) {
      return ApiResponse.error('Failed to fetch schedule: $e');
    }
  }
}
