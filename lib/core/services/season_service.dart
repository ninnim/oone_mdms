import 'package:dio/dio.dart';
import '../models/season.dart';
import '../models/response_models.dart';
import 'api_service.dart';

/// Service for managing seasons
class SeasonService {
  final ApiService _apiService;

  SeasonService(this._apiService);

  /// Get all seasons with pagination and search
  Future<ApiResponse<List<Season>>> getSeasons({
    String search = '%%',
    int offset = 0,
    int limit = 25,
  }) async {
    try {
      print(
        '🔄 SeasonService: Fetching seasons (search: $search, offset: $offset, limit: $limit)',
      );

      final response = await _apiService.get(
        '/api/rest/v2/Season',
        queryParameters: {'search': search, 'offset': offset, 'limit': limit},
      );

      print('✅ SeasonService: Raw response received');
      print('📄 Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        final seasons =
            (data['Season'] as List?)
                ?.map((json) => Season.fromJson(json))
                .toList() ??
            [];

        // Extract pagination info
        final paging = data['Paging'];
        final total = paging?['Item']?['Total'] ?? 0;

        print(
          '✅ SeasonService: Parsed ${seasons.length} seasons, total: $total',
        );

        return ApiResponse<List<Season>>(
          success: true,
          data: seasons,
          message: 'Seasons fetched successfully',
          paging: Paging(item: PagingItem(total: total)),
        );
      } else {
        print('❌ SeasonService: HTTP error ${response.statusCode}');
        return ApiResponse<List<Season>>(
          success: false,
          data: [],
          message: 'Failed to fetch seasons: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ SeasonService: Exception in getSeasons: $e');
      return ApiResponse<List<Season>>(
        success: false,
        data: [],
        message: 'Error fetching seasons: $e',
      );
    }
  }

  /// Get season by ID
  Future<ApiResponse<Season>> getSeasonById(int id) async {
    try {
      print('🔄 SeasonService: Fetching season by ID: $id');

      final response = await _apiService.get('/api/rest/Season/$id');

      if (response.statusCode == 200) {
        final data = response.data;
        final seasonList = data['Season'] as List?;

        if (seasonList != null && seasonList.isNotEmpty) {
          final season = Season.fromJson(seasonList.first);
          print('✅ SeasonService: Fetched season: ${season.name}');

          return ApiResponse<Season>(
            success: true,
            data: season,
            message: 'Season fetched successfully',
          );
        } else {
          print('❌ SeasonService: Season not found in response');
          return ApiResponse<Season>(
            success: false,
            message: 'Season not found',
          );
        }
      } else {
        print('❌ SeasonService: HTTP error ${response.statusCode}');
        return ApiResponse<Season>(
          success: false,
          message: 'Failed to fetch season: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ SeasonService: Exception in getSeasonById: $e');
      return ApiResponse<Season>(
        success: false,
        message: 'Error fetching season: $e',
      );
    }
  }

  /// Create new season
  Future<ApiResponse<Season>> createSeason(Season season) async {
    try {
      print('🔄 SeasonService: Creating season: ${season.name}');

      final requestData = {
        'Season': {
          'Name': season.name,
          'Description': season.description,
          'MonthRange': season.monthRange,
        },
      };

      print('📤 SeasonService: Request data: $requestData');

      final response = await _apiService.post(
        '/api/rest/Season',
        data: requestData,
      );

      print('📥 SeasonService: Response status: ${response.statusCode}');
      print('📄 SeasonService: Response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final createdSeason = Season.fromJson(data['Season']);

        print(
          '✅ SeasonService: Season created successfully: ${createdSeason.name}',
        );

        return ApiResponse<Season>(
          success: true,
          data: createdSeason,
          message: 'Season created successfully',
        );
      } else {
        print('❌ SeasonService: HTTP error ${response.statusCode}');
        return ApiResponse<Season>(
          success: false,
          message: 'Failed to create season: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ SeasonService: Exception in createSeason: $e');
      if (e is DioException) {
        print('🔍 DioException details: ${e.response?.data}');
      }
      return ApiResponse<Season>(
        success: false,
        message: 'Error creating season: $e',
      );
    }
  }

  /// Update existing season
  Future<ApiResponse<Season>> updateSeason(Season season) async {
    try {
      print(
        '🔄 SeasonService: Updating season: ${season.name} (ID: ${season.id})',
      );

      final requestData = {
        'Season': {
          'Name': season.name,
          'Description': season.description,
          'MonthRange': season.monthRange,
        },
      };

      print('📤 SeasonService: Request data: $requestData');

      final response = await _apiService.post(
        '/api/rest/Season/${season.id}',
        data: requestData,
      );

      print('📥 SeasonService: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        final updatedSeason = Season.fromJson(data['Season']);

        print(
          '✅ SeasonService: Season updated successfully: ${updatedSeason.name}',
        );

        return ApiResponse<Season>(
          success: true,
          data: updatedSeason,
          message: 'Season updated successfully',
        );
      } else {
        print('❌ SeasonService: HTTP error ${response.statusCode}');
        return ApiResponse<Season>(
          success: false,
          message: 'Failed to update season: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ SeasonService: Exception in updateSeason: $e');
      if (e is DioException) {
        print('🔍 DioException details: ${e.response?.data}');
      }
      return ApiResponse<Season>(
        success: false,
        message: 'Error updating season: $e',
      );
    }
  }

  /// Delete season
  Future<ApiResponse<Season>> deleteSeason(int id) async {
    try {
      print('🔄 SeasonService: Deleting season ID: $id');

      final response = await _apiService.delete('/api/rest/Season/$id');

      print('📥 SeasonService: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        final deletedSeason = Season.fromJson(data['Season']);

        print(
          '✅ SeasonService: Season deleted successfully: ${deletedSeason.name}',
        );

        return ApiResponse<Season>(
          success: true,
          data: deletedSeason,
          message: 'Season deleted successfully',
        );
      } else {
        print('❌ SeasonService: HTTP error ${response.statusCode}');
        return ApiResponse<Season>(
          success: false,
          message: 'Failed to delete season: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ SeasonService: Exception in deleteSeason: $e');
      if (e is DioException) {
        print('🔍 DioException details: ${e.response?.data}');
      }
      return ApiResponse<Season>(
        success: false,
        message: 'Error deleting season: $e',
      );
    }
  }

  /// Helper method to get month name from month number
  static String getMonthName(int month) {
    const monthNames = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return month >= 1 && month <= 12 ? monthNames[month] : 'Invalid';
  }

  /// Helper method to get month names list from month range
  static String getMonthRangeDisplay(List<int> monthRange) {
    if (monthRange.isEmpty) return 'No months selected';

    final monthNames = monthRange.map((month) => getMonthName(month)).toList();

    if (monthNames.length <= 3) {
      return monthNames.join(', ');
    } else {
      return '${monthNames.take(3).join(', ')} +${monthNames.length - 3} more';
    }
  }
}
