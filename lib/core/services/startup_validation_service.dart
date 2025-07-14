import 'package:flutter/foundation.dart';
import 'service_locator.dart';

/// Service to ensure initial setup and validation of required headers
class StartupValidationService {
  static Future<bool> validateInitialSetup() async {
    try {
      debugPrint('🚀 StartupValidationService: Starting validation...');

      final serviceLocator = ServiceLocator();

      // Ensure services are initialized
      if (!serviceLocator.isInitialized) {
        debugPrint('⚠️ Services not initialized, initializing now...');
        await serviceLocator.initialize();
      }

      final tokenService = serviceLocator.tokenManagementService;
      final keycloakService = serviceLocator.keycloakService;

      // Check if user is authenticated
      if (!keycloakService.isAuthenticated) {
        debugPrint('❌ User not authenticated');
        return false;
      }

      // Validate token is present and valid
      if (!tokenService.isTokenValid) {
        debugPrint('⚠️ Token invalid, attempting refresh...');
        final refreshed = await keycloakService.refreshToken();
        if (!refreshed) {
          debugPrint('❌ Token refresh failed');
          return false;
        }
      }

      // Get headers and validate required ones are present
      final headers = tokenService.getApiHeaders();
      final requiredHeaders = ['x-hasura-role', 'Authorization'];
      final missingHeaders = <String>[];

      for (final header in requiredHeaders) {
        if (!headers.containsKey(header) ||
            headers[header] == null ||
            headers[header]!.isEmpty) {
          missingHeaders.add(header);
        }
      }

      if (missingHeaders.isNotEmpty) {
        debugPrint('❌ Missing required headers: ${missingHeaders.join(', ')}');
        return false;
      }

      // Log successful validation
      debugPrint('✅ StartupValidationService: All validations passed');
      debugPrint('  - User authenticated: ${keycloakService.isAuthenticated}');
      debugPrint('  - Token valid: ${tokenService.isTokenValid}');
      debugPrint('  - Current tenant: ${tokenService.currentTenant}');
      debugPrint('  - Current role: ${tokenService.currentRole}');
      debugPrint('  - Allowed roles: ${tokenService.allowedRoles}');
      debugPrint('  - Headers ready: ${headers.keys.join(', ')}');

      return true;
    } catch (e) {
      debugPrint('❌ StartupValidationService failed: $e');
      return false;
    }
  }

  /// Monitor token status and auto-refresh
  static void startTokenMonitoring() {
    try {
      final serviceLocator = ServiceLocator();
      final tokenService = serviceLocator.tokenManagementService;

      // Listen to token changes
      tokenService.addListener(() {
        debugPrint('🔄 Token changed - updating headers');
        _logCurrentStatus();
      });

      debugPrint('👂 Token monitoring started');
      _logCurrentStatus();
    } catch (e) {
      debugPrint('❌ Failed to start token monitoring: $e');
    }
  }

  static void _logCurrentStatus() {
    try {
      final serviceLocator = ServiceLocator();
      final tokenService = serviceLocator.tokenManagementService;
      final keycloakService = serviceLocator.keycloakService;

      debugPrint('📊 Current Status:');
      debugPrint('  - Authenticated: ${keycloakService.isAuthenticated}');
      debugPrint('  - Token Valid: ${tokenService.isTokenValid}');
      debugPrint('  - Tenant: ${tokenService.currentTenant}');
      debugPrint('  - Role: ${tokenService.currentRole}');
      debugPrint('  - Token Expiry: ${tokenService.tokenExpiry}');
    } catch (e) {
      debugPrint('❌ Error logging status: $e');
    }
  }

  /// Test API call to verify headers are working
  static Future<bool> testApiHeaders() async {
    try {
      debugPrint('🧪 Testing API headers...');

      final serviceLocator = ServiceLocator();
      final apiService = serviceLocator.apiService;

      // Make a test API call
      final response = await apiService.get('/api/rest/Device?limit=1');

      if (response.statusCode == 200) {
        debugPrint('✅ API test successful - Headers are working!');
        return true;
      } else {
        debugPrint('⚠️ API test returned status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ API test failed: $e');
      return false;
    }
  }
}
