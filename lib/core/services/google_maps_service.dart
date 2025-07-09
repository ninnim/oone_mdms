import '../models/address.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

class GoogleMapsService {
  final ApiService _apiService;

  GoogleMapsService(this._apiService);

  // Search for locations using text input
  Future<List<Address>> searchLocations(String query) async {
    try {
      final response = await _apiService.get(
        ApiConstants.googleApi,
        queryParameters: {'input': query},
      );

      final predictions = response.data['predictions'] as List<dynamic>? ?? [];
      return predictions.map((prediction) {
        return Address(
          id: '',
          latitude: 0,
          longitude: 0,
          shortText: prediction['structured_formatting']?['main_text'] ?? '',
          longText: prediction['description'] ?? '',
          street: '',
          city: '',
          state: '',
          postalCode: '',
          country: '',
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to search locations: $e');
    }
  }

  // Get place details by place ID
  Future<Address> getPlaceDetails(String placeId) async {
    try {
      final response = await _apiService.get(
        ApiConstants.googleApiDetail,
        queryParameters: {'place_id': placeId},
      );

      final result = response.data['result'];
      final geometry = result['geometry']?['location'];
      final addressComponents =
          result['address_components'] as List<dynamic>? ?? [];

      // Parse address components
      String street = '';
      String city = '';
      String state = '';
      String postalCode = '';
      String country = '';

      for (var component in addressComponents) {
        final types = List<String>.from(component['types'] ?? []);
        final longName = component['long_name'] ?? '';

        if (types.contains('street_number') || types.contains('route')) {
          street += (street.isEmpty ? '' : ' ') + longName;
        } else if (types.contains('locality') ||
            types.contains('sublocality')) {
          city = longName;
        } else if (types.contains('administrative_area_level_1')) {
          state = longName;
        } else if (types.contains('postal_code')) {
          postalCode = longName;
        } else if (types.contains('country')) {
          country = longName;
        }
      }

      return Address(
        id: '',
        latitude: geometry?['lat']?.toDouble() ?? 0,
        longitude: geometry?['lng']?.toDouble() ?? 0,
        shortText: result['name'] ?? '',
        longText: result['formatted_address'] ?? '',
        street: street,
        city: city,
        state: state,
        postalCode: postalCode,
        country: country,
      );
    } catch (e) {
      throw Exception('Failed to get place details: $e');
    }
  }

  // Reverse geocode coordinates to address
  Future<Address> reverseGeocode(double latitude, double longitude) async {
    try {
      final response = await _apiService.get(
        ApiConstants.googleApiGeocode,
        queryParameters: {'address': '$latitude, $longitude'},
      );

      final results = response.data['results'] as List<dynamic>? ?? [];
      if (results.isEmpty) {
        throw Exception('No address found for coordinates');
      }

      final result = results.first;
      final addressComponents =
          result['address_components'] as List<dynamic>? ?? [];

      // Parse address components
      String street = '';
      String city = '';
      String state = '';
      String postalCode = '';
      String country = '';

      for (var component in addressComponents) {
        final types = List<String>.from(component['types'] ?? []);
        final longName = component['long_name'] ?? '';

        if (types.contains('street_number') || types.contains('route')) {
          street += (street.isEmpty ? '' : ' ') + longName;
        } else if (types.contains('locality') ||
            types.contains('sublocality')) {
          city = longName;
        } else if (types.contains('administrative_area_level_1')) {
          state = longName;
        } else if (types.contains('postal_code')) {
          postalCode = longName;
        } else if (types.contains('country')) {
          country = longName;
        }
      }

      return Address(
        id: '',
        latitude: latitude,
        longitude: longitude,
        shortText: result['address_components']?.first?['long_name'] ?? '',
        longText: result['formatted_address'] ?? '',
        street: street,
        city: city,
        state: state,
        postalCode: postalCode,
        country: country,
      );
    } catch (e) {
      throw Exception('Failed to reverse geocode: $e');
    }
  }
}
