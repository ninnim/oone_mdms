import '../models/time_of_use.dart';
import '../models/time_band.dart';
import '../models/response_models.dart';
import 'api_service.dart';

class TimeOfUseService {
  final ApiService _apiService;

  TimeOfUseService(this._apiService);

  /// Get all Time of Use with pagination and search
  Future<ApiResponse<List<TimeOfUse>>> getTimeOfUse({
    String search = '',
    int limit = 25,
    int offset = 0,
    bool includeTimeOfUseDetails = true,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/rest/TimeOfUse',
        queryParameters: {
          'search': '%$search%',
          'includeTimeOfUseDetails': includeTimeOfUseDetails,
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final timeOfUseList = (data['TimeOfUse'] as List)
            .map((item) => TimeOfUse.fromJson(item))
            .toList();

        return ApiResponse<List<TimeOfUse>>(
          success: true,
          data: timeOfUseList,
          message: 'Time of Use loaded successfully',
          paging: data['Paging'] != null
              ? Paging.fromJson(data['Paging'])
              : null,
        );
      } else {
        return ApiResponse<List<TimeOfUse>>(
          success: false,
          message: 'Failed to load Time of Use: ${response.statusMessage}',
        );
      }
    } catch (e) {
      return ApiResponse<List<TimeOfUse>>(
        success: false,
        message: 'Error loading Time of Use: $e',
      );
    }
  }

  /// Get Time of Use by ID
  Future<ApiResponse<TimeOfUse>> getTimeOfUseById(
    int id, {
    bool includeTimeOfUseDetails = true,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/rest/TimeOfUse/$id',
        queryParameters: {'includeTimeOfUseDetails': includeTimeOfUseDetails},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final timeOfUse = TimeOfUse.fromJson(data['TimeOfUse']);

        return ApiResponse<TimeOfUse>(
          success: true,
          data: timeOfUse,
          message: 'Time of Use loaded successfully',
        );
      } else {
        return ApiResponse<TimeOfUse>(
          success: false,
          message: 'Failed to load Time of Use: ${response.statusMessage}',
        );
      }
    } catch (e) {
      return ApiResponse<TimeOfUse>(
        success: false,
        message: 'Error loading Time of Use: $e',
      );
    }
  }

  /// Create new Time of Use
  Future<ApiResponse<TimeOfUse>> createTimeOfUse({
    required String code,
    required String name,
    required String description,
    required List<TimeOfUseDetail> timeOfUseDetails,
  }) async {
    try {
      final timeOfUse = TimeOfUse(
        code: code,
        name: name,
        description: description,
        active: true,
        timeOfUseDetails: timeOfUseDetails,
      );

      final response = await _apiService.post(
        '/api/rest/TimeOfUse',
        data: timeOfUse.toCreateJson(),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final createdTimeOfUse = TimeOfUse.fromJson(data['TimeOfUse']);

        return ApiResponse<TimeOfUse>(
          success: true,
          data: createdTimeOfUse,
          message: 'Time of Use created successfully',
        );
      } else {
        return ApiResponse<TimeOfUse>(
          success: false,
          message: 'Failed to create Time of Use: ${response.statusMessage}',
        );
      }
    } catch (e) {
      return ApiResponse<TimeOfUse>(
        success: false,
        message: 'Error creating Time of Use: $e',
      );
    }
  }

  /// Update existing Time of Use
  Future<ApiResponse<TimeOfUse>> updateTimeOfUse({
    required TimeOfUse timeOfUse,
    required List<TimeOfUseDetail> timeOfUseDetails,
  }) async {
    try {
      if (timeOfUse.id == null) {
        return ApiResponse<TimeOfUse>(
          success: false,
          message: 'Time of Use ID is required for update',
        );
      }

      // Step 1: Update the TimeOfUse basic information
      final response = await _apiService.post(
        '/api/rest/TimeOfUse/${timeOfUse.id}',
        data: timeOfUse.toUpdateJson(),
      );

      if (response.statusCode != 200) {
        return ApiResponse<TimeOfUse>(
          success: false,
          message: 'Failed to update Time of Use: ${response.statusMessage}',
        );
      }

      // Step 2: Update TimeOfUseDetails separately
      final detailsResponse = await _updateTimeOfUseDetails(
        timeOfUse.id!,
        timeOfUseDetails,
      );

      if (!detailsResponse.success) {
        return ApiResponse<TimeOfUse>(
          success: false,
          message:
              'Time of Use updated but failed to update details: ${detailsResponse.message}',
        );
      }

      // Step 3: Fetch the updated TimeOfUse with details to return
      final updatedResponse = await getTimeOfUseById(timeOfUse.id!);

      if (updatedResponse.success) {
        return ApiResponse<TimeOfUse>(
          success: true,
          data: updatedResponse.data!,
          message: 'Time of Use updated successfully',
        );
      } else {
        return ApiResponse<TimeOfUse>(
          success: true,
          data: timeOfUse.copyWith(timeOfUseDetails: timeOfUseDetails),
          message: 'Time of Use updated successfully',
        );
      }
    } catch (e) {
      return ApiResponse<TimeOfUse>(
        success: false,
        message: 'Error updating Time of Use: $e',
      );
    }
  }

  /// Internal method to update TimeOfUseDetails
  Future<ApiResponse<bool>> _updateTimeOfUseDetails(
    int timeOfUseId,
    List<TimeOfUseDetail> details,
  ) async {
    try {
      // Get current details to identify which ones to delete
      final currentResponse = await getTimeOfUseById(timeOfUseId);
      if (!currentResponse.success) {
        return ApiResponse<bool>(
          success: false,
          message: 'Failed to get current details for comparison',
        );
      }

      final currentDetails = currentResponse.data!.timeOfUseDetails;
      final currentDetailIds = currentDetails
          .map((d) => d.id)
          .where((id) => id != null)
          .toSet();
      final newDetailIds = details
          .map((d) => d.id)
          .where((id) => id != null)
          .toSet();

      // Delete details that are no longer present
      final detailsToDelete = currentDetailIds.difference(newDetailIds);
      for (final detailId in detailsToDelete) {
        await _apiService.delete('/api/rest/TimeOfUseDetail/$detailId');
      }

      // Create or update remaining details
      for (final detail in details) {
        final detailData = {
          'TimeOfUseDetail': {
            if (detail.id != null) 'Id': detail.id,
            'TimeOfUseId': timeOfUseId,
            'TimeBandId': detail.timeBandId,
            'ChannelId': detail.channelId,
            'RegisterDisplayCode': detail.registerDisplayCode,
            'PriorityOrder': detail.priorityOrder,
            'Active': detail.active,
          },
        };

        if (detail.id != null) {
          // Update existing detail
          await _apiService.post(
            '/api/rest/TimeOfUseDetail/${detail.id}',
            data: detailData,
          );
        } else {
          // Create new detail
          await _apiService.post('/api/rest/TimeOfUseDetail', data: detailData);
        }
      }

      return ApiResponse<bool>(
        success: true,
        data: true,
        message: 'Time of Use details updated successfully',
      );
    } catch (e) {
      return ApiResponse<bool>(
        success: false,
        message: 'Error updating Time of Use details: $e',
      );
    }
  }

  /// Delete Time of Use
  Future<ApiResponse<bool>> deleteTimeOfUse(int id) async {
    try {
      final response = await _apiService.delete('/api/rest/TimeOfUse/$id');

      if (response.statusCode == 200) {
        return ApiResponse<bool>(
          success: true,
          data: true,
          message: 'Time of Use deleted successfully',
        );
      } else {
        return ApiResponse<bool>(
          success: false,
          message: 'Failed to delete Time of Use: ${response.statusMessage}',
        );
      }
    } catch (e) {
      return ApiResponse<bool>(
        success: false,
        message: 'Error deleting Time of Use: $e',
      );
    }
  }

  /// Get available Time Bands for selection
  Future<ApiResponse<List<TimeBand>>> getAvailableTimeBands({
    String search = '',
    int limit = 100,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/rest/TimeBand',
        queryParameters: {
          'search': '%$search%',
          'limit': limit,
          'offset': 0,
          'includeTimeBandAttributes': true,
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

  /// Get available Channels for selection
  Future<ApiResponse<List<Channel>>> getAvailableChannels({
    String search = '',
    int limit = 100,
  }) async {
    try {
      // Note: This endpoint might need to be adjusted based on your API
      final response = await _apiService.get(
        '/api/rest/Channel',
        queryParameters: {'search': '%$search%', 'limit': limit, 'offset': 0},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final channels = (data['Channel'] as List)
            .map((item) => Channel.fromJson(item))
            .toList();

        return ApiResponse<List<Channel>>(
          success: true,
          data: channels,
          message: 'Channels loaded successfully',
        );
      } else {
        return ApiResponse<List<Channel>>(
          success: false,
          message: 'Failed to load channels: ${response.statusMessage}',
        );
      }
    } catch (e) {
      return ApiResponse<List<Channel>>(
        success: false,
        message: 'Error loading channels: $e',
      );
    }
  }

  /// Validate Time of Use details
  bool validateTimeOfUseDetails(List<TimeOfUseDetail> details) {
    if (details.isEmpty) {
      return false;
    }

    // Check for unique priority orders
    final priorityOrders = details.map((d) => d.priorityOrder).toSet();
    if (priorityOrders.length != details.length) {
      return false;
    }

    // Check for valid register display codes
    for (final detail in details) {
      if (detail.registerDisplayCode.isEmpty) {
        return false;
      }
    }

    return true;
  }

  /// Get Time of Use statistics for summary
  Map<String, int> getTimeOfUseStats(List<TimeOfUse> timeOfUseList) {
    int activeCount = 0;
    int inactiveCount = 0;
    int totalTimeBands = 0;
    int totalChannels = 0;

    final allTimeBandIds = <int>{};
    final allChannelIds = <int>{};

    for (final tou in timeOfUseList) {
      if (tou.active) {
        activeCount++;
      } else {
        inactiveCount++;
      }

      for (final detail in tou.timeOfUseDetails) {
        allTimeBandIds.add(detail.timeBandId);
        allChannelIds.add(detail.channelId);
      }
    }

    totalTimeBands = allTimeBandIds.length;
    totalChannels = allChannelIds.length;

    return {
      'total': timeOfUseList.length,
      'active': activeCount,
      'inactive': inactiveCount,
      'draft': 0, // Not supported in current model
      'totalTimeBands': totalTimeBands,
      'totalChannels': totalChannels,
    };
  }
}
