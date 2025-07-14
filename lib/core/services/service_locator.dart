import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'keycloak_service.dart';
import 'token_management_service.dart';

/// Service locator for managing API-related dependencies
class ServiceLocator extends ChangeNotifier {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  KeycloakService? _keycloakService;
  TokenManagementService? _tokenManagementService;
  ApiService? _apiService;

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

  /// Check if all services are initialized
  bool get isInitialized =>
      _keycloakService != null &&
      _tokenManagementService != null &&
      _apiService != null;

  /// Dispose all services
  @override
  void dispose() {
    _tokenManagementService?.dispose();
    _keycloakService = null;
    _tokenManagementService = null;
    _apiService = null;
    super.dispose();
  }
}
