import 'package:mdms_clone/core/models/address.dart';
import 'api_service.dart';

class GoogleMapsService {
  final ApiService _apiService;

  GoogleMapsService(this._apiService);

  // Search for places by text input
  Future<List<PlaceSuggestion>> searchPlaces(String input) async {
    try {
      if (input.trim().isEmpty) {
        return [];
      }

      final response = await _apiService.get(
        '/esb/googleapi',
        queryParameters: {'input': input.trim()},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        // Parse Google Places API response
        if (data['predictions'] != null) {
          final predictions = data['predictions'] as List;
          return predictions
              .map((prediction) => PlaceSuggestion.fromJson(prediction))
              .toList();
        }

        return [];
      }

      return [];
    } catch (e) {
      print('Error searching places: $e');
      return [];
    }
  }

  // Get place details by place_id
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    try {
      final response = await _apiService.get(
        '/esb/googleapi/detail',
        queryParameters: {'place_id': placeId},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        if (data['result'] != null) {
          return PlaceDetails.fromJson(data['result']);
        }
      }

      return null;
    } catch (e) {
      print('Error getting place details: $e');
      return null;
    }
  }

  // Reverse geocode - get address from coordinates
  Future<String?> reverseGeocode(double latitude, double longitude) async {
    try {
      final response = await _apiService.get(
        '/esb/googleapi/geocode',
        queryParameters: {'address': '$latitude, $longitude'},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        if (data['results'] != null && (data['results'] as List).isNotEmpty) {
          final result = (data['results'] as List).first;
          return result['formatted_address'] as String?;
        }
      }

      return null;
    } catch (e) {
      print('Error reverse geocoding: $e');
      return null;
    }
  }
}

class PlaceSuggestion {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestion(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      mainText:
          json['structured_formatting']?['main_text'] ??
          json['description'] ??
          '',
      secondaryText: json['structured_formatting']?['secondary_text'] ?? '',
    );
  }
}

class PlaceDetails {
  final String placeId;
  final String formattedAddress;
  final double latitude;
  final double longitude;
  final String name;

  PlaceDetails({
    required this.placeId,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    required this.name,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'];
    final location = geometry?['location'];

    return PlaceDetails(
      placeId: json['place_id'] ?? '',
      formattedAddress: json['formatted_address'] ?? '',
      latitude: (location?['lat'] ?? 0.0).toDouble(),
      longitude: (location?['lng'] ?? 0.0).toDouble(),
      name: json['name'] ?? '',
    );
  }

  Address toAddress({String? id}) {
    return Address(
      id: id ?? '',
      street: formattedAddress,
      city: '',
      state: '',
      postalCode: '',
      country: '',
      latitude: latitude,
      longitude: longitude,
    );
  }
}
