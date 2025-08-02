import '../models/response_models.dart';
import '../models/time_band.dart';
import 'api_service.dart';

class TimeBandService {
  final ApiService _apiService;

  TimeBandService(this._apiService);

  // Get all time bands with pagination and search
  Future<ApiResponse<List<TimeBand>>> getTimeBands({
    String search = '%%',
    int offset = 0,
    int limit = 25,
  }) async {
    try {
      print(
        '🔄 TimeBandService: Fetching time bands (search: $search, offset: $offset, limit: $limit)',
      );

      final response = await _apiService.get(
        '/api/rest/TimeBand',
        queryParameters: {'search': search, 'offset': offset, 'limit': limit},
      );

      print('✅ TimeBandService: Raw response received');
      print('📄 Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        final timeBands =
            (data['TimeBand'] as List?)
                ?.map((json) => TimeBand.fromJson(json))
                .toList() ??
            [];

        // Extract pagination info
        final paging = data['Paging'];
        final total = paging?['Item']?['Total'] ?? 0;

        print(
          '✅ TimeBandService: Parsed ${timeBands.length} time bands, total: $total',
        );

        return ApiResponse<List<TimeBand>>(
          success: true,
          data: timeBands,
          message: 'Time bands fetched successfully',
          paging: Paging(item: PagingItem(total: total)),
        );
      } else {
        print('❌ TimeBandService: HTTP error ${response.statusCode}');
        return ApiResponse<List<TimeBand>>(
          success: false,
          data: [],
          message: 'Failed to fetch time bands: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ TimeBandService: Exception in getTimeBands: $e');
      return ApiResponse<List<TimeBand>>(
        success: false,
        data: [],
        message: 'Error fetching time bands: $e',
      );
    }
  }

  // Get time band by ID
  Future<ApiResponse<TimeBand>> getTimeBandById(int id) async {
    try {
      print('🔄 TimeBandService: Fetching time band by ID: $id');

      final response = await _apiService.get('/api/rest/TimeBand/$id');

      if (response.statusCode == 200) {
        final data = response.data;
        final timeBandList = data['TimeBand'] as List?;

        if (timeBandList != null && timeBandList.isNotEmpty) {
          final timeBand = TimeBand.fromJson(timeBandList.first);
          print('✅ TimeBandService: Time band fetched successfully');
          return ApiResponse<TimeBand>(
            success: true,
            data: timeBand,
            message: 'Time band fetched successfully',
          );
        } else {
          print('❌ TimeBandService: Time band not found');
          return ApiResponse<TimeBand>(
            success: false,
            message: 'Time band not found',
          );
        }
      } else {
        print('❌ TimeBandService: HTTP error ${response.statusCode}');
        return ApiResponse<TimeBand>(
          success: false,
          message: 'Failed to fetch time band: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ TimeBandService: Exception in getTimeBandById: $e');
      return ApiResponse<TimeBand>(
        success: false,
        message: 'Error fetching time band: $e',
      );
    }
  }

  // Create new time band
  Future<ApiResponse<TimeBand>> createTimeBand({
    required String name,
    required String startTime,
    required String endTime,
    required String description,
    List<int> daysOfWeek = const [],
    List<int> monthsOfYear = const [],
    List<int> seasonIds = const [],
    List<int> specialDayIds = const [],
  }) async {
    try {
      print('🔄 TimeBandService: Creating new time band: $name');

      final timeBand = TimeBand(
        id: 0, // Will be assigned by server
        name: name,
        startTime: startTime,
        endTime: endTime,
        description: description,
        active: true,
      );

      final payload = timeBand.toCreateJson(
        daysOfWeek: daysOfWeek,
        monthsOfYear: monthsOfYear,
        seasonIds: seasonIds,
        specialDayIds: specialDayIds,
      );

      print('📄 TimeBandService: Create payload: $payload');

      final response = await _apiService.post(
        '/api/rest/TimeBand',
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        print('📄 TimeBandService: Create response data: $data');

        // Handle both list and object response formats
        final timeBandData = data['TimeBand'];

        if (timeBandData != null) {
          final TimeBand createdTimeBand;
          if (timeBandData is List && timeBandData.isNotEmpty) {
            createdTimeBand = TimeBand.fromJson(timeBandData.first);
          } else if (timeBandData is Map<String, dynamic>) {
            createdTimeBand = TimeBand.fromJson(timeBandData);
          } else {
            print(
              '❌ TimeBandService: Invalid response structure: $timeBandData',
            );
            return ApiResponse<TimeBand>(
              success: false,
              message:
                  'Failed to create time band - invalid response structure',
            );
          }

          print('✅ TimeBandService: Time band created successfully');
          return ApiResponse<TimeBand>(
            success: true,
            data: createdTimeBand,
            message: 'Time band created successfully',
          );
        } else {
          print('❌ TimeBandService: No TimeBand in response');
          return ApiResponse<TimeBand>(
            success: false,
            message: 'Failed to create time band - no data in response',
          );
        }
      } else {
        print('❌ TimeBandService: HTTP error ${response.statusCode}');
        return ApiResponse<TimeBand>(
          success: false,
          message: 'Failed to create time band: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ TimeBandService: Exception in createTimeBand: $e');
      return ApiResponse<TimeBand>(
        success: false,
        message: 'Error creating time band: $e',
      );
    }
  }

  // Update existing time band
  Future<ApiResponse<TimeBand>> updateTimeBand({
    required TimeBand timeBand,
    List<int> daysOfWeek = const [],
    List<int> monthsOfYear = const [],
    List<int> seasonIds = const [],
    List<int> specialDayIds = const [],
  }) async {
    try {
      print('🔄 TimeBandService: Updating time band: ${timeBand.name}');

      // Use the same endpoint and format as create, but include the ID
      final payload = timeBand.toUpdateJson(
        daysOfWeek: daysOfWeek,
        monthsOfYear: monthsOfYear,
        seasonIds: seasonIds,
        specialDayIds: specialDayIds,
      );

      print('📄 TimeBandService: Update payload: $payload');

      // Try using the same endpoint as create but with the ID in the payload
      final response = await _apiService.post(
        '/api/rest/TimeBand',
        data: payload,
      );

      print('📥 TimeBandService: Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        print('📄 TimeBandService: Update response data: $data');

        // Handle both list and object response formats
        final timeBandData = data['TimeBand'];

        if (timeBandData != null) {
          final TimeBand updatedTimeBand;
          if (timeBandData is List && timeBandData.isNotEmpty) {
            // Find the updated time band by ID
            final updatedData = timeBandData.firstWhere(
              (item) => item['Id'] == timeBand.id,
              orElse: () => timeBandData.first,
            );
            updatedTimeBand = TimeBand.fromJson(updatedData);
          } else if (timeBandData is Map<String, dynamic>) {
            updatedTimeBand = TimeBand.fromJson(timeBandData);
          } else {
            print(
              '❌ TimeBandService: Invalid response structure: $timeBandData',
            );
            return ApiResponse<TimeBand>(
              success: false,
              message:
                  'Failed to update time band - invalid response structure',
            );
          }

          print('✅ TimeBandService: Time band updated successfully');
          return ApiResponse<TimeBand>(
            success: true,
            data: updatedTimeBand,
            message: 'Time band updated successfully',
          );
        } else {
          print('❌ TimeBandService: No TimeBand in response');
          return ApiResponse<TimeBand>(
            success: false,
            message: 'Failed to update time band - no data in response',
          );
        }
      } else {
        print('❌ TimeBandService: HTTP error ${response.statusCode}');
        return ApiResponse<TimeBand>(
          success: false,
          message: 'Failed to update time band: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ TimeBandService: Exception in updateTimeBand: $e');
      return ApiResponse<TimeBand>(
        success: false,
        message: 'Error updating time band: $e',
      );
    }
  }

  // Delete time band
  Future<ApiResponse<bool>> deleteTimeBand(int id) async {
    try {
      print('🔄 TimeBandService: Deleting time band ID: $id');

      final response = await _apiService.delete('/api/rest/TimeBand/$id');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ TimeBandService: Time band deleted successfully');
        return ApiResponse<bool>(
          success: true,
          data: true,
          message: 'Time band deleted successfully',
        );
      } else {
        print('❌ TimeBandService: HTTP error ${response.statusCode}');
        return ApiResponse<bool>(
          success: false,
          data: false,
          message: 'Failed to delete time band: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ TimeBandService: Exception in deleteTimeBand: $e');
      return ApiResponse<bool>(
        success: false,
        data: false,
        message: 'Error deleting time band: $e',
      );
    }
  }

  // Delete multiple time bands
  Future<ApiResponse<bool>> deleteTimeBands(List<int> ids) async {
    try {
      print('🔄 TimeBandService: Deleting ${ids.length} time bands');

      int successCount = 0;
      int failureCount = 0;

      for (final id in ids) {
        final result = await deleteTimeBand(id);
        if (result.success) {
          successCount++;
        } else {
          failureCount++;
        }
      }

      if (failureCount == 0) {
        print('✅ TimeBandService: All time bands deleted successfully');
        return ApiResponse<bool>(
          success: true,
          data: true,
          message: 'All time bands deleted successfully',
        );
      } else if (successCount > 0) {
        print('⚠️ TimeBandService: Partial deletion success');
        return ApiResponse<bool>(
          success: true,
          data: true,
          message: '$successCount time bands deleted, $failureCount failed',
        );
      } else {
        print('❌ TimeBandService: All deletions failed');
        return ApiResponse<bool>(
          success: false,
          data: false,
          message: 'Failed to delete time bands',
        );
      }
    } catch (e) {
      print('❌ TimeBandService: Exception in deleteTimeBands: $e');
      return ApiResponse<bool>(
        success: false,
        data: false,
        message: 'Error deleting time bands: $e',
      );
    }
  }

  // Validate time format (HH:mm)
  bool validateTimeFormat(String time) {
    // Accept both HH:mm and HH:mm:ss formats
    final timeRegex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$');
    return timeRegex.hasMatch(time);
  }

  // Validate time range (allows overnight time bands)
  bool validateTimeRange(String startTime, String endTime) {
    try {
      // Ensure both times have seconds (add :00 if missing)
      final normalizedStartTime =
          startTime.contains(':') && startTime.split(':').length == 2
          ? '$startTime:00'
          : startTime;
      final normalizedEndTime =
          endTime.contains(':') && endTime.split(':').length == 2
          ? '$endTime:00'
          : endTime;

      // Parse both times to ensure they are valid time formats
      DateTime.parse('2000-01-01 $normalizedStartTime');
      DateTime.parse('2000-01-01 $normalizedEndTime');

      // Allow overnight time bands (start > end is valid)
      // This covers cases like 22:00:00 to 06:00:00 (10 PM to 6 AM next day)
      return true; // All time ranges are valid if parsing succeeds
    } catch (e) {
      return false; // Only false if parsing fails
    }
  }

  // Get time bands for dropdown selection
  Future<ApiResponse<List<TimeBand>>> getTimeBandsForDropdown() async {
    return getTimeBands(limit: 100); // Get more items for dropdown
  }
}
