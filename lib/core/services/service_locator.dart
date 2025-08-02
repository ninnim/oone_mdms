import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'keycloak_service.dart';
import 'token_management_service.dart';
import 'time_band_service.dart';
import 'season_service.dart';
import 'special_day_service.dart';

/// Service locator for managing API-related dependencies
class ServiceLocator extends ChangeNotifier {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  KeycloakService? _keycloakService;
  TokenManagementService? _tokenManagementService;
  ApiService? _apiService;
  TimeBandService? _timeBandService;
  SeasonService? _seasonService;
  SpecialDayService? _specialDayService;

  /// Initialize all services
  Future<void> initialize() async {
    try {
      // Initialize Keycloak service
      _keycloakService = KeycloakService();
      await _keycloakService!.initialize();

      // Initialize Token management service
      _tokenManagementService = TokenManagementService(_keycloakService!);
      await _tokenManagementService!.initialize();

      // Initialize API service with both dependencies
      _apiService = ApiService(_keycloakService, _tokenManagementService);

      // Initialize domain services
      _timeBandService = TimeBandService(_apiService!);
      _seasonService = SeasonService(_apiService!);
      _specialDayService = SpecialDayService(_apiService!);

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Get Keycloak service instance
  KeycloakService get keycloakService {
    if (_keycloakService == null) {
      throw Exception(
        'ServiceLocator: KeycloakService not initialized. Call initialize() first.',
      );
    }
    return _keycloakService!;
  }

  /// Get Token management service instance
  TokenManagementService get tokenManagementService {
    if (_tokenManagementService == null) {
      throw Exception(
        'ServiceLocator: TokenManagementService not initialized. Call initialize() first.',
      );
    }
    return _tokenManagementService!;
  }

  /// Get API service instance
  ApiService get apiService {
    if (_apiService == null) {
      throw Exception(
        'ServiceLocator: ApiService not initialized. Call initialize() first.',
      );
    }
    return _apiService!;
  }

  /// Get TimeBand service instance
  TimeBandService get timeBandService {
    if (_timeBandService == null) {
      throw Exception(
        'ServiceLocator: TimeBandService not initialized. Call initialize() first.',
      );
    }
    return _timeBandService!;
  }

  /// Get Season service instance
  SeasonService get seasonService {
    if (_seasonService == null) {
      throw Exception(
        'ServiceLocator: SeasonService not initialized. Call initialize() first.',
      );
    }
    return _seasonService!;
  }

  /// Get SpecialDay service instance
  SpecialDayService get specialDayService {
    if (_specialDayService == null) {
      throw Exception(
        'ServiceLocator: SpecialDayService not initialized. Call initialize() first.',
      );
    }
    return _specialDayService!;
  }

  /// Check if all services are initialized
  bool get isInitialized =>
      _keycloakService != null &&
      _tokenManagementService != null &&
      _apiService != null &&
      _timeBandService != null &&
      _seasonService != null &&
      _specialDayService != null;

  /// Dispose all services
  @override
  void dispose() {
    _tokenManagementService?.dispose();
    _keycloakService = null;
    _tokenManagementService = null;
    _apiService = null;
    _timeBandService = null;
    _seasonService = null;
    _specialDayService = null;
    super.dispose();
  }
}
