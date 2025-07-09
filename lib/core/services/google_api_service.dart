import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class GoogleApiService {
  final Dio _dio;

  GoogleApiService() : _dio = Dio() {
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // Search location by text
  Future<List<PlaceSearchResult>> searchPlaces(String query) async {
    try {
      final response = await _dio.get(
        '/esb/googleapi',
        queryParameters: {'input': query},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['predictions'] != null) {
          return (data['predictions'] as List)
              .map((prediction) => PlaceSearchResult.fromJson(prediction))
              .toList();
        }
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
      final response = await _dio.get(
        '/esb/googleapi/detail',
        queryParameters: {'place_id': placeId},
      );

      if (response.statusCode == 200) {
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

  // Geocode lat/lng to address
  Future<GeocodeResult?> geocodeLocation(double lat, double lng) async {
    try {
      final response = await _dio.get(
        '/esb/googleapi/geocode',
        queryParameters: {'address': '$lat, $lng'},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['results'] != null && data['results'].isNotEmpty) {
          return GeocodeResult.fromJson(data['results'][0]);
        }
      }
      return null;
    } catch (e) {
      print('Error geocoding location: $e');
      return null;
    }
  }
}

class PlaceSearchResult {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlaceSearchResult({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlaceSearchResult.fromJson(Map<String, dynamic> json) {
    return PlaceSearchResult(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      mainText: json['structured_formatting']?['main_text'] ?? '',
      secondaryText: json['structured_formatting']?['secondary_text'] ?? '',
    );
  }
}

class PlaceDetails {
  final String placeId;
  final String name;
  final String formattedAddress;
  final double lat;
  final double lng;

  PlaceDetails({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    required this.lat,
    required this.lng,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'];
    final location = geometry?['location'];

    return PlaceDetails(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? '',
      formattedAddress: json['formatted_address'] ?? '',
      lat: (location?['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (location?['lng'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class GeocodeResult {
  final String formattedAddress;
  final double lat;
  final double lng;

  GeocodeResult({
    required this.formattedAddress,
    required this.lat,
    required this.lng,
  });

  factory GeocodeResult.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'];
    final location = geometry?['location'];

    return GeocodeResult(
      formattedAddress: json['formatted_address'] ?? '',
      lat: (location?['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (location?['lng'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
