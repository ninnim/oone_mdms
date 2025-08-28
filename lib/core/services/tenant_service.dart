import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/tenant.dart';
import '../models/current_user_response.dart';
import 'keycloak_service.dart';

class TenantService extends ChangeNotifier {
  static const String baseUrl = 'https://mtc-stg.oone.bz/v1';

  CurrentUserResponse? _currentUserResponse;
  List<Tenant> _allTenants = [];
  bool _isLoading = false;
  String? _error;
  int _tenantSwitchTimestamp = 0;

  // Getters
  CurrentUserResponse? get currentUserResponse => _currentUserResponse;
  List<Tenant> get allTenants =>
      _allTenants.where((tenant) => tenant.status == 'active').toList();
  Tenant? get currentTenant => _currentUserResponse?.currentTenant;
  String? get currentTenantName => currentTenant?.tenant;
  String? get userEmail =>
      currentTenant?.userId; // This should be email from user info
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get tenantSwitchTimestamp => _tenantSwitchTimestamp;

  final KeycloakService _keycloakService;

  TenantService(this._keycloakService);

  /// Get current user and tenant information
  Future<bool> getCurrentUser() async {
    try {
      _setLoading(true);
      _error = null;

      final token = _keycloakService.accessToken;
      if (token == null || token.isEmpty) {
        throw Exception('No valid access token available');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/CurrentUser?ModuleCode=MDMS'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _currentUserResponse = CurrentUserResponse.fromJson(data);
        notifyListeners();
        return true;
      } else {
        throw Exception('Failed to get current user: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error getting current user: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get all available tenants
  Future<bool> getAllTenants() async {
    try {
      _setLoading(true);
      _error = null;

      final token = _keycloakService.accessToken;
      if (token == null || token.isEmpty) {
        throw Exception('No valid access token available');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/Tenant?ModuleCodes=mdms'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _allTenants = data.map((json) => Tenant.fromJson(json)).toList();
        notifyListeners();
        return true;
      } else {
        throw Exception('Failed to get tenants: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error getting tenants: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Switch to a different tenant
  Future<bool> switchTenant(String toTenantId) async {
    try {
      _setLoading(true);
      _error = null;

      final token = _keycloakService.accessToken;
      if (token == null || token.isEmpty) {
        throw Exception('No valid access token available');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/Tenant/SwitchTenant'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'toTenantId': toTenantId}),
      );

      if (response.statusCode == 200) {
        // After successful switch, refresh token and get current user info
        await _keycloakService.refreshToken();
        final success = await getCurrentUser();

        // Force additional notification to ensure UI updates
        if (success) {
          _tenantSwitchTimestamp = DateTime.now().millisecondsSinceEpoch;
          await Future.delayed(const Duration(milliseconds: 50));
          notifyListeners();
        }

        return success;
      } else {
        throw Exception('Failed to switch tenant: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error switching tenant: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Initialize tenant service - get current user and all tenants
  Future<bool> initialize() async {
    try {
      final currentUserSuccess = await getCurrentUser();
      final tenantsSuccess = await getAllTenants();
      return currentUserSuccess && tenantsSuccess;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
