import '../models/time_band.dart';
import '../models/season.dart';
import '../models/special_day.dart';
import '../models/response_models.dart';
import 'api_service.dart';

class TouService {
  final ApiService _apiService;

  TouService(this._apiService);

  // Time Bands API Methods
  Future<ApiResponse<List<TimeBand>>> getTimeBands({
    String search = '',
    int limit = 25,
    int offset = 0,
    bool includeTimeBandAttributes = true,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/rest/TimeBand',
        queryParameters: {
          'search': '%$search%',
          'limit': limit,
          'offset': offset,
          'includeTimeBandAttributes': includeTimeBandAttributes,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final timeBands = (data['TimeBand'] as List)
            .map((item) => TimeBand.fromJson(item))
            .toList();

        return ApiResponse<List<TimeBand>>(
          success: true,
          data: timeBands,
          message: 'Time bands loaded successfully',
        );
      } else {
        return ApiResponse<List<TimeBand>>(
          success: false,
          message: 'Failed to load time bands: ${response.statusMessage}',
        );
      }
    } catch (e) {
      return ApiResponse<List<TimeBand>>(
        success: false,
        message: 'Error loading time bands: $e',
      );
    }
  }

  Future<ApiResponse<TimeBand>> getTimeBandById(int id) async {
    try {
      final response = await _apiService.get('/api/rest/TimeBand/$id');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final timeBand = TimeBand.fromJson(data['TimeBand'][0]);

        return ApiResponse<TimeBand>(
          success: true,
          data: timeBand,
          message: 'Time band loaded successfully',
        );
      } else {
        return ApiResponse<TimeBand>(
          success: false,
          message: 'Failed to load time band: ${response.statusMessage}',
        );
      }
    } catch (e) {
      return ApiResponse<TimeBand>(
        success: false,
        message: 'Error loading time band: $e',
      );
    }
  }

  Future<ApiResponse<TimeBand>> createTimeBand(TimeBand timeBand) async {
    try {
      final response = await _apiService.post(
        '/api/rest/TimeBand',
        data: timeBand.toJson(),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final createdTimeBand = TimeBand.fromJson(data['TimeBand'][0]);

        return ApiResponse<TimeBand>(
          success: true,
          data: createdTimeBand,
          message: 'Time band created successfully',
        );
      } else {
        return ApiResponse<TimeBand>(
          success: false,
          message: 'Failed to create time band: ${response.statusMessage}',
        );
      }
    } catch (e) {
      return ApiResponse<TimeBand>(
        success: false,
        message: 'Error creating time band: $e',
      );
    }
  }

  Future<ApiResponse<TimeBand>> updateTimeBand(TimeBand timeBand) async {
    try {
      final response = await _apiService.put(
        '/api/rest/TimeBand/${timeBand.id}',
        data: timeBand.toJson(),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final updatedTimeBand = TimeBand.fromJson(data['TimeBand'][0]);

        return ApiResponse<TimeBand>(
          success: true,
          data: updatedTimeBand,
          message: 'Time band updated successfully',
        );
      } else {
        return ApiResponse<TimeBand>(
          success: false,
          message: 'Failed to update time band: ${response.statusMessage}',
        );
      }
    } catch (e) {
      return ApiResponse<TimeBand>(
        success: false,
        message: 'Error updating time band: $e',
      );
    }
  }

  Future<ApiResponse<bool>> deleteTimeBand(int id) async {
    try {
      final response = await _apiService.delete('/api/rest/TimeBand/$id');

      if (response.statusCode == 200) {
        return ApiResponse<bool>(
          success: true,
          data: true,
          message: 'Time band deleted successfully',
        );
      } else {
        return ApiResponse<bool>(
          success: false,
          message: 'Failed to delete time band: ${response.statusMessage}',
        );
      }
    } catch (e) {
      return ApiResponse<bool>(
        success: false,
        message: 'Error deleting time band: $e',
      );
    }
  }

  // Seasons API Methods
  Future<ApiResponse<List<Season>>> getSeasons({
    String search = '',
    int limit = 25,
    int offset = 0,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/rest/v2/Season',
        queryParameters: {
          'search': '%$search%',
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final seasons = (data['Season'] as List)
            .map((item) => Season.fromJson(item))
            .toList();

        return ApiResponse<List<Season>>(
          success: true,
          data: seasons,
          message: 'Seasons loaded successfully',
        );
      } else {
        return ApiResponse<List<Season>>(
          success: false,
          message: 'Failed to load seasons: ${response.statusMessage}',
        );
      }
    } catch (e) {
      return ApiResponse<List<Season>>(
        success: false,
        message: 'Error loading seasons: $e',
      );
    }
  }

  Future<ApiResponse<Season>> getSeasonById(int id) async {
    try {
      final response = await _apiService.get('/api/rest/v2/Season/$id');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final season = Season.fromJson(data['Season'][0]);

        return ApiResponse<Season>(
          success: true,
          data: season,
          message: 'Season loaded successfully',
        );
      } else {
        return ApiResponse<Season>(
          success: false,
          message: 'Failed to load season: ${response.statusMessage}',
        );
      }
    } catch (e) {
      return ApiResponse<Season>(
        success: false,
        message: 'Error loading season: $e',
      );
    }
  }

  Future<ApiResponse<Season>> createSeason(Season season) async {
    try {
      final response = await _apiService.post(
        '/api/rest/v2/Season',
        data: season.toJson(),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final createdSeason = Season.fromJson(data['Season'][0]);

        return ApiResponse<Season>(
          success: true,
          data: createdSeason,
          message: 'Season created successfully',
        );
      } else {
        return ApiResponse<Season>(
          success: false,
          message: 'Failed to create season: ${response.statusMessage}',
        );
      }
    } catch (e) {
      return ApiResponse<Season>(
        success: false,
        message: 'Error creating season: $e',
      );
    }
  }

  Future<ApiResponse<Season>> updateSeason(Season season) async {
    try {
      final response = await _apiService.put(
        '/api/rest/v2/Season/${season.id}',
        data: season.toJson(),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final updatedSeason = Season.fromJson(data['Season'][0]);

        return ApiResponse<Season>(
          success: true,
          data: updatedSeason,
          message: 'Season updated successfully',
        );
      } else {
        return ApiResponse<Season>(
          success: false,
          message: 'Failed to update season: ${response.statusMessage}',
        );
      }
    } catch (e) {
      return ApiResponse<Season>(
        success: false,
        message: 'Error updating season: $e',
      );
    }
  }

  Future<ApiResponse<bool>> deleteSeason(int id) async {
    try {
      final response = await _apiService.delete('/api/rest/v2/Season/$id');

      if (response.statusCode == 200) {
        return ApiResponse<bool>(
          success: true,
          data: true,
          message: 'Season deleted successfully',
        );
      } else {
        return ApiResponse<bool>(
          success: false,
          message: 'Failed to delete season: ${response.statusMessage}',
        );
      }
    } catch (e) {
      return ApiResponse<bool>(
        success: false,
        message: 'Error deleting season: $e',
      );
    }
  }

  // Special Days API Methods
  Future<ApiResponse<List<SpecialDay>>> getSpecialDays({
    String search = '',
    int limit = 25,
    int offset = 0,
    bool includeSpecialDayDetail = true,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/rest/v2/SpecialDay',
        queryParameters: {
          'search': '%$search%',
          'limit': limit,
          'offset': offset,
          'includeSpecialDayDetail': includeSpecialDayDetail,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final specialDays = (data['SpecialDay'] as List)
            .map((item) => SpecialDay.fromJson(item))
            .toList();

        return ApiResponse<List<SpecialDay>>(
          success: true,
          data: specialDays,
          message: 'Special days loaded successfully',
        );
      } else {
        return ApiResponse<List<SpecialDay>>(
          success: false,
          message: 'Failed to load special days: ${response.statusMessage}',
        );
      }
    } catch (e) {
      return ApiResponse<List<SpecialDay>>(
        success: false,
        message: 'Error loading special days: $e',
      );
    }
  }

  Future<ApiResponse<SpecialDay>> getSpecialDayById(int id) async {
    try {
      final response = await _apiService.get('/api/rest/v2/SpecialDay/$id');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final specialDay = SpecialDay.fromJson(data['SpecialDay'][0]);

        return ApiResponse<SpecialDay>(
          success: true,
          data: specialDay,
          message: 'Special day loaded successfully',
        );
      } else {
        return ApiResponse<SpecialDay>(
          success: false,
          message: 'Failed to load special day: ${response.statusMessage}',
        );
      }
    } catch (e) {
      return ApiResponse<SpecialDay>(
        success: false,
        message: 'Error loading special day: $e',
      );
    }
  }

  Future<ApiResponse<SpecialDay>> createSpecialDay(
    SpecialDay specialDay,
  ) async {
    try {
      final response = await _apiService.post(
        '/api/rest/v2/SpecialDay',
        data: specialDay.toJson(),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final createdSpecialDay = SpecialDay.fromJson(data['SpecialDay'][0]);

        return ApiResponse<SpecialDay>(
          success: true,
          data: createdSpecialDay,
          message: 'Special day created successfully',
        );
      } else {
        return ApiResponse<SpecialDay>(
          success: false,
          message: 'Failed to create special day: ${response.statusMessage}',
        );
      }
    } catch (e) {
      return ApiResponse<SpecialDay>(
        success: false,
        message: 'Error creating special day: $e',
      );
    }
  }

  Future<ApiResponse<SpecialDay>> updateSpecialDay(
    SpecialDay specialDay,
  ) async {
    try {
      final response = await _apiService.put(
        '/api/rest/v2/SpecialDay/${specialDay.id}',
        data: specialDay.toJson(),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final updatedSpecialDay = SpecialDay.fromJson(data['SpecialDay'][0]);

        return ApiResponse<SpecialDay>(
          success: true,
          data: updatedSpecialDay,
          message: 'Special day updated successfully',
        );
      } else {
        return ApiResponse<SpecialDay>(
          success: false,
          message: 'Failed to update special day: ${response.statusMessage}',
        );
      }
    } catch (e) {
      return ApiResponse<SpecialDay>(
        success: false,
        message: 'Error updating special day: $e',
      );
    }
  }

  Future<ApiResponse<bool>> deleteSpecialDay(int id) async {
    try {
      final response = await _apiService.delete('/api/rest/v2/SpecialDay/$id');

      if (response.statusCode == 200) {
        return ApiResponse<bool>(
          success: true,
          data: true,
          message: 'Special day deleted successfully',
        );
      } else {
        return ApiResponse<bool>(
          success: false,
          message: 'Failed to delete special day: ${response.statusMessage}',
        );
      }
    } catch (e) {
      return ApiResponse<bool>(
        success: false,
        message: 'Error deleting special day: $e',
      );
    }
  }
}
