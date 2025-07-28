import '../models/site.dart';
import '../models/response_models.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';
import 'error_translation_service.dart';

class SiteService {
  final ApiService _apiService;

  SiteService(this._apiService);

  // Get all sites with pagination and search
  Future<ApiResponse<List<Site>>> getSites({
    String search = ApiConstants.defaultSearch,
    int offset = ApiConstants.defaultOffset,
    int limit = ApiConstants.defaultLimit,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/rest/v2/Site',
        queryParameters: {'search': search, 'offset': offset, 'limit': limit},
      );

      final listResponse = SiteListResponse.fromJson(response.data);
      final sites = listResponse.sites
          .map((json) => Site.fromJson(json))
          .toList();

      final paging = listResponse.paging != null
          ? Paging.fromJson(listResponse.paging!)
          : null;

      return ApiResponse.success(sites, paging: paging);
    } catch (e) {
      final userFriendlyMessage =
          ErrorTranslationService.getContextualErrorMessage(e, 'site_list');
      return ApiResponse.error(userFriendlyMessage);
    }
  }

  // Get site by ID
  Future<ApiResponse<Site>> getSiteById(
    int id, {
    bool includeSubSite = true,
    String search = '%%',
  }) async {
    try {
      final response = await _apiService.get(
        '/api/rest/Site/$id',
        queryParameters: {'includeSubSite': includeSubSite, 'search': search},
      );

      final siteResponse = SiteResponse.fromJson(response.data);
      if (siteResponse.sites.isNotEmpty) {
        final site = Site.fromJson(siteResponse.sites.first);
        return ApiResponse.success(site);
      } else {
        return ApiResponse.error('Site not found');
      }
    } catch (e) {
      final userFriendlyMessage =
          ErrorTranslationService.getContextualErrorMessage(e, 'site_detail');
      return ApiResponse.error(userFriendlyMessage);
    }
  }

  // Create site
  Future<ApiResponse<Site>> createSite(Site site) async {
    try {
      final requestData = {
        'Site': {
          'Name': site.name,
          'Description': site.description,
          'ParentId': site.parentId,
        },
      };

      final response = await _apiService.post(
        '/api/rest/Site',
        data: requestData,
      );

      final siteResponse = SiteResponse.fromJson(response.data);
      if (siteResponse.sites.isNotEmpty) {
        final createdSite = Site.fromJson(siteResponse.sites.first);
        return ApiResponse.success(createdSite);
      } else {
        return ApiResponse.error('Failed to create site');
      }
    } catch (e) {
      final userFriendlyMessage =
          ErrorTranslationService.getContextualErrorMessage(e, 'site_create');
      return ApiResponse.error(userFriendlyMessage);
    }
  }

  // Update site
  Future<ApiResponse<Site>> updateSite(Site site) async {
    try {
      final requestData = {
        'Site': {
          'ParentId': site.parentId,
          'Name': site.name,
          'Description': site.description,
        },
      };

      final response = await _apiService.post(
        '/api/rest/Site/${site.id}',
        data: requestData,
      );

      final siteResponse = SiteResponse.fromJson(response.data);
      if (siteResponse.sites.isNotEmpty) {
        final updatedSite = Site.fromJson(siteResponse.sites.first);
        return ApiResponse.success(updatedSite);
      } else {
        return ApiResponse.error('Failed to update site');
      }
    } catch (e) {
      final userFriendlyMessage =
          ErrorTranslationService.getContextualErrorMessage(e, 'site_update');
      return ApiResponse.error(userFriendlyMessage);
    }
  }

  // Delete site
  Future<ApiResponse<bool>> deleteSite(int id) async {
    try {
      final response = await _apiService.delete('/api/rest/Site/$id');

      if (response.statusCode == 200) {
        return ApiResponse.success(true);
      } else {
        return ApiResponse.error('Failed to delete site');
      }
    } catch (e) {
      final userFriendlyMessage =
          ErrorTranslationService.getContextualErrorMessage(e, 'site_delete');
      return ApiResponse.error(userFriendlyMessage);
    }
  }

  // Get main sites only (parentId = 0)
  Future<ApiResponse<List<Site>>> getMainSites({
    String search = ApiConstants.defaultSearch,
    int offset = ApiConstants.defaultOffset,
    int limit = ApiConstants.defaultLimit,
  }) async {
    try {
      final response = await getSites(
        search: search,
        offset: offset,
        limit: limit,
      );

      if (response.success && response.data != null) {
        final mainSites = response.data!
            .where((site) => site.isMainSite)
            .toList();
        return ApiResponse.success(mainSites, paging: response.paging);
      } else {
        return response;
      }
    } catch (e) {
      return ApiResponse.error('Failed to fetch main sites: $e');
    }
  }

  // Get sub sites for a specific parent
  Future<ApiResponse<List<Site>>> getSubSites(
    int parentId, {
    String search = ApiConstants.defaultSearch,
    int offset = ApiConstants.defaultOffset,
    int limit = ApiConstants.defaultLimit,
  }) async {
    try {
      final response = await getSiteById(parentId);

      if (response.success && response.data != null) {
        final subSites = response.data!.subSites ?? [];
        return ApiResponse.success(subSites);
      } else {
        return ApiResponse.error('Failed to fetch sub sites');
      }
    } catch (e) {
      return ApiResponse.error('Failed to fetch sub sites: $e');
    }
  }
}
