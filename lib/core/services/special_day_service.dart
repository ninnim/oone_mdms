import '../models/special_day.dart';
import '../models/response_models.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';
import 'error_translation_service.dart';

class SpecialDayService {
  final ApiService _apiService;

  SpecialDayService(this._apiService);

  // Get all special days with pagination and search
  Future<ApiResponse<List<SpecialDay>>> getSpecialDays({
    String search = ApiConstants.defaultSearch,
    int offset = ApiConstants.defaultOffset,
    int limit = ApiConstants.defaultLimit,
    bool includeSpecialDayDetail = true,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/rest/v2/SpecialDay',
        queryParameters: {
          'search': search,
          'offset': offset,
          'limit': limit,
          'includeSpecialDayDetail': includeSpecialDayDetail,
        },
      );

      final data = response.data;
      final specialDays =
          (data['SpecialDay'] as List?)
              ?.map((json) => SpecialDay.fromJson(json))
              .toList() ??
          [];

      // Extract pagination info
      final paging = data['Paging'];
      final total = paging?['Item']?['Total'] ?? 0;

      return ApiResponse<List<SpecialDay>>(
        success: true,
        data: specialDays,
        message: 'Special days loaded successfully',
        paging: Paging(item: PagingItem(total: total)),
      );
    } catch (e) {
      final userFriendlyMessage =
          ErrorTranslationService.getContextualErrorMessage(
            e,
            'special_day_list',
          );
      return ApiResponse.error(userFriendlyMessage);
    }
  }

  // Get special day by ID
  Future<ApiResponse<SpecialDay>> getSpecialDayById(
    int id, {
    bool includeSpecialDayDetail = true,
    String search = '%%',
  }) async {
    try {
      final response = await _apiService.get(
        '/api/rest/SpecialDay/$id',
        queryParameters: {
          'includeSpecialDayDetail': includeSpecialDayDetail,
          'search': search,
        },
      );

      final data = response.data;
      final specialDayData = (data['SpecialDay'] as List?)?.first;

      if (specialDayData == null) {
        return ApiResponse.error('Special day not found');
      }

      final specialDay = SpecialDay.fromJson(specialDayData);

      return ApiResponse.success(specialDay);
    } catch (e) {
      final userFriendlyMessage =
          ErrorTranslationService.getContextualErrorMessage(
            e,
            'special_day_detail',
          );
      return ApiResponse.error(userFriendlyMessage);
    }
  }

  // Create special day
  Future<ApiResponse<SpecialDay>> createSpecialDay(
    SpecialDay specialDay,
  ) async {
    try {
      final response = await _apiService.post(
        '/api/rest/SpecialDay',
        data: {'SpecialDay': specialDay.toCreateJson()},
      );

      final data = response.data;
      final createdSpecialDay = SpecialDay.fromJson(data['SpecialDay']);

      return ApiResponse.success(createdSpecialDay);
    } catch (e) {
      final userFriendlyMessage =
          ErrorTranslationService.getContextualErrorMessage(
            e,
            'special_day_create',
          );
      return ApiResponse.error(userFriendlyMessage);
    }
  }

  // Update special day - uses same endpoint as create but with different payload
  Future<ApiResponse<SpecialDay>> updateSpecialDay(
    SpecialDay specialDay,
  ) async {
    try {
      final response = await _apiService.post(
        '/api/rest/SpecialDay',
        data: {'SpecialDay': specialDay.toUpdateJson()},
      );

      final data = response.data;
      final updatedSpecialDay = SpecialDay.fromJson(data['SpecialDay']);

      return ApiResponse.success(updatedSpecialDay);
    } catch (e) {
      final userFriendlyMessage =
          ErrorTranslationService.getContextualErrorMessage(
            e,
            'special_day_update',
          );
      return ApiResponse.error(userFriendlyMessage);
    }
  }

  // Delete special day
  Future<ApiResponse<bool>> deleteSpecialDay(int id) async {
    print('🔗 API: Attempting to delete special day with ID: $id');
    try {
      print('🔗 API: Making DELETE request to /api/rest/SpecialDay/$id');
      final response = await _apiService.delete('/api/rest/SpecialDay/$id');
      print(
        '🔗 API: Delete request completed, status code: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        print('🔗 API: Delete successful (status 200)');
        return ApiResponse.success(true);
      } else {
        print('🔗 API: Delete failed with status code: ${response.statusCode}');
        return ApiResponse.error(
          'Failed to delete special day (status: ${response.statusCode})',
        );
      }
    } catch (e) {
      print('🔗 API: Delete request failed with error: $e');
      final userFriendlyMessage =
          ErrorTranslationService.getContextualErrorMessage(
            e,
            'special_day_delete',
          );
      print('🔗 API: Translated error message: $userFriendlyMessage');
      return ApiResponse.error(userFriendlyMessage);
    }
  }

  // Create special day detail
  Future<ApiResponse<SpecialDayDetail>> createSpecialDayDetail(
    SpecialDayDetail detail,
  ) async {
    try {
      final response = await _apiService.post(
        '/api/rest/SpecialDayDetail',
        data: {'SpecialDayDetail': detail.toJson()},
      );

      final data = response.data;
      final createdDetail = SpecialDayDetail.fromJson(data['SpecialDayDetail']);

      return ApiResponse.success(createdDetail);
    } catch (e) {
      final userFriendlyMessage =
          ErrorTranslationService.getContextualErrorMessage(
            e,
            'special_day_detail_create',
          );
      return ApiResponse.error(userFriendlyMessage);
    }
  }

  // Update special day detail
  Future<ApiResponse<SpecialDayDetail>> updateSpecialDayDetail(
    SpecialDayDetail detail,
  ) async {
    try {
      final response = await _apiService.post(
        '/api/rest/SpecialDayDetail/${detail.id}',
        data: {'SpecialDayDetail': detail.toJson()},
      );

      final data = response.data;
      final updatedDetail = SpecialDayDetail.fromJson(data['SpecialDay']);

      return ApiResponse.success(updatedDetail);
    } catch (e) {
      final userFriendlyMessage =
          ErrorTranslationService.getContextualErrorMessage(
            e,
            'special_day_detail_update',
          );
      return ApiResponse.error(userFriendlyMessage);
    }
  }

  // Delete special day detail
  Future<ApiResponse<bool>> deleteSpecialDayDetail(int id) async {
    print('🔗 API: Attempting to delete special day detail with ID: $id');
    try {
      print('🔗 API: Making DELETE request to /api/rest/SpecialDayDetail/$id');
      final response = await _apiService.delete(
        '/api/rest/SpecialDayDetail/$id',
      );
      print(
        '🔗 API: Delete detail request completed, status code: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        print('🔗 API: Delete detail successful (status 200)');
        return ApiResponse.success(true);
      } else {
        print(
          '🔗 API: Delete detail failed with status code: ${response.statusCode}',
        );
        return ApiResponse.error(
          'Failed to delete special day detail (status: ${response.statusCode})',
        );
      }
    } catch (e) {
      print('🔗 API: Delete detail request failed with error: $e');
      final userFriendlyMessage =
          ErrorTranslationService.getContextualErrorMessage(
            e,
            'special_day_detail_delete',
          );
      print('🔗 API: Translated error message: $userFriendlyMessage');
      return ApiResponse.error(userFriendlyMessage);
    }
  }
}
