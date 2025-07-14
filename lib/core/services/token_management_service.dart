import 'dart:async';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import 'keycloak_service.dart';

/// Service for managing API tokens and headers dynamically
class TokenManagementService extends ChangeNotifier {
  final KeycloakService _keycloakService;
  Timer? _refreshTimer;

  // Cached token information
  String? _cachedAccessToken;
  Map<String, dynamic>? _tokenPayload;
  String? _extractedTenant;
  List<String>? _allowedRoles;
  String? _selectedRole;
  DateTime? _tokenExpiry;

  TokenManagementService(this._keycloakService) {
    // Listen to Keycloak service changes
    _keycloakService.addListener(_onKeycloakServiceChanged);
    _initializeTokenManagement();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _keycloakService.removeListener(_onKeycloakServiceChanged);
    super.dispose();
  }

  /// Initialize token management and start auto-refresh
  Future<void> _initializeTokenManagement() async {
    await _extractTokenInformation();
    _scheduleTokenRefresh();
  }

  /// Handle Keycloak service changes
  void _onKeycloakServiceChanged() {
    _extractTokenInformation();
    notifyListeners();
  }

  /// Extract all necessary information from the JWT token
  Future<void> _extractTokenInformation() async {
    try {
      final accessToken = _keycloakService.accessToken;

      if (accessToken == null || accessToken.isEmpty) {
        _clearTokenCache();
        return;
      }

      // Check if token has changed
      if (_cachedAccessToken == accessToken) {
        return; // No change, skip extraction
      }

      _cachedAccessToken = accessToken;

      // Decode JWT token
      if (JwtDecoder.isExpired(accessToken)) {
        await _refreshTokenIfNeeded();
        return;
      }

      _tokenPayload = JwtDecoder.decode(accessToken);
      _tokenExpiry = JwtDecoder.getExpirationDate(accessToken);

      // Extract tenant from token
      _extractedTenant = _extractTenantFromToken();

      // Extract allowed roles from token
      _allowedRoles = _extractAllowedRolesFromToken();

      // Select the last (most privileged) role
      _selectedRole = _selectLastRole();

      // Schedule refresh before expiry
      _scheduleTokenRefresh();
    } catch (e) {
      _clearTokenCache();
    }
  }

  /// Extract tenant from JWT token
  String? _extractTenantFromToken() {
    if (_tokenPayload == null) return null;

    // First try to get from Hasura JWT claims section
    try {
      final hasuraClaimsKey = 'https://hasura.io/jwt/claims';
      if (_tokenPayload!.containsKey(hasuraClaimsKey)) {
        final hasuraClaims = _tokenPayload![hasuraClaimsKey];
        if (hasuraClaims is Map<String, dynamic> &&
            hasuraClaims.containsKey('x-hasura-tenant')) {
          final tenant = hasuraClaims['x-hasura-tenant'];
          if (tenant != null && tenant.toString().isNotEmpty) {
            return tenant.toString();
          }
        }
      }
    } catch (e) {
      // Silently continue to fallback
    }

    // Fallback: Try other possible tenant fields in JWT
    final tenantFields = [
      'x-hasura-tenant',
      'tenant',
      'hasura_tenant',
      'tenant_id',
      'organization_id',
      'org_id',
    ];

    for (final field in tenantFields) {
      final value = _tokenPayload![field];
      if (value != null && value.toString().isNotEmpty) {
        debugPrint(
          'TokenManagementService: Found tenant in field $field: $value',
        );
        return value.toString();
      }
    }

    debugPrint(
      'TokenManagementService: No tenant found in token, using default',
    );
    return ApiConstants.defaultTenant;
  }

  /// Extract allowed roles from JWT token
  List<String>? _extractAllowedRolesFromToken() {
    if (_tokenPayload == null) return null;

    // First try to get from Hasura JWT claims section
    try {
      final hasuraClaimsKey = 'https://hasura.io/jwt/claims';
      if (_tokenPayload!.containsKey(hasuraClaimsKey)) {
        final hasuraClaims = _tokenPayload![hasuraClaimsKey];
        if (hasuraClaims is Map<String, dynamic> &&
            hasuraClaims.containsKey('x-hasura-allowed-roles')) {
          final roles = hasuraClaims['x-hasura-allowed-roles'];
          if (roles is List) {
            final roleList = roles.map((role) => role.toString()).toList();
            debugPrint(
              'TokenManagementService: Found roles in Hasura claims: $roleList',
            );
            return roleList;
          }
        }
      }
    } catch (e) {
      debugPrint(
        'TokenManagementService: Error extracting roles from Hasura claims: $e',
      );
    }

    // Fallback: Try other possible role fields in JWT
    final roleFields = [
      'x-hasura-allowed-roles',
      'hasura_allowed_roles',
      'allowed_roles',
      'roles',
      'realm_access.roles',
      'resource_access.mdms.roles',
    ];

    for (final field in roleFields) {
      dynamic value;

      if (field.contains('.')) {
        // Handle nested fields like 'realm_access.roles'
        final parts = field.split('.');
        value = _tokenPayload![parts[0]];
        for (int i = 1; i < parts.length && value != null; i++) {
          value = value[parts[i]];
        }
      } else {
        value = _tokenPayload![field];
      }

      if (value != null) {
        if (value is List) {
          final roleList = value.map((role) => role.toString()).toList();
          debugPrint(
            'TokenManagementService: Found roles in field $field: $roleList',
          );
          return roleList;
        } else if (value is String && value.isNotEmpty) {
          debugPrint(
            'TokenManagementService: Found single role in field $field: $value',
          );
          return [value];
        }
      }
    }

    debugPrint(
      'TokenManagementService: No roles found in token, using default',
    );
    return [ApiConstants.defaultRole];
  }

  /// Select the last (most privileged) role from allowed roles
  String? _selectLastRole() {
    if (_allowedRoles == null || _allowedRoles!.isEmpty) {
      return ApiConstants.defaultRole;
    }

    // Simply return the last role from the array as requested
    final lastRole = _allowedRoles!.last;
    debugPrint('TokenManagementService: Selected last role: $lastRole');
    return lastRole;
  }

  /// Schedule automatic token refresh
  void _scheduleTokenRefresh() {
    _refreshTimer?.cancel();

    if (_tokenExpiry == null) return;

    // Refresh 5 minutes before expiry
    final refreshTime = _tokenExpiry!.subtract(const Duration(minutes: 5));
    final now = DateTime.now();

    if (refreshTime.isAfter(now)) {
      final delay = refreshTime.difference(now);
      _refreshTimer = Timer(delay, () async {
        await _refreshTokenIfNeeded();
      });
    } else {
      // Token expires soon, refresh immediately
      _refreshTokenIfNeeded();
    }
  }

  /// Refresh token if needed
  Future<bool> _refreshTokenIfNeeded() async {
    try {
      // Check if token is expired or expires soon (within 1 minute)
      if (_tokenExpiry != null) {
        final now = DateTime.now();
        final expiresWithinMinute = _tokenExpiry!.isBefore(
          now.add(const Duration(minutes: 1)),
        );

        if (!expiresWithinMinute) {
          return true; // Token is still valid
        }
      }

      // Use Keycloak service to refresh token
      final success = await _keycloakService.refreshToken();

      if (success) {
        await _extractTokenInformation();
        notifyListeners();
        return true;
      } else {
        _clearTokenCache();
        return false;
      }
    } catch (e) {
      _clearTokenCache();
      return false;
    }
  }

  /// Clear token cache
  void _clearTokenCache() {
    _cachedAccessToken = null;
    _tokenPayload = null;
    _extractedTenant = null;
    _allowedRoles = null;
    _selectedRole = null;
    _tokenExpiry = null;
    _refreshTimer?.cancel();
  }

  /// Get current API headers with dynamic token information
  Map<String, String> getApiHeaders() {
    final headers = <String, String>{
      'Content-Type': ApiConstants.contentType,
      'Accept': ApiConstants.accept,
      'x-hasura-admin-secret': ApiConstants.tokenHeader,
    };

    // Add Bearer token if available
    if (_cachedAccessToken != null) {
      headers['Authorization'] = 'Bearer $_cachedAccessToken';
    }

    // Add tenant header (use extracted tenant or default)
    headers[ApiConstants.tenant] =
        _extractedTenant ?? ApiConstants.defaultTenant;

    // Add allowed roles header
    if (_allowedRoles != null && _allowedRoles!.isNotEmpty) {
      headers['x-hasura-allowed-roles'] = _allowedRoles!.join(',');
    }

    // Add role header (use selected role or default)
    headers[ApiConstants.role] = _selectedRole ?? ApiConstants.defaultRole;

    // Add user header
    headers[ApiConstants.user] = ApiConstants.defaultUser;

    // Add additional headers for user identification
    final userInfo = _keycloakService.currentUser;
    if (userInfo != null) {
      headers['x-hasura-user-name'] =
          userInfo['name'] ?? userInfo['preferred_username'] ?? 'Admin';
      headers['x-hasura-user-id'] =
          userInfo['sub'] ?? _extractedTenant ?? ApiConstants.defaultTenant;
    } else {
      headers['x-hasura-user-name'] = 'Admin';
      headers['x-hasura-user-id'] =
          _extractedTenant ?? ApiConstants.defaultTenant;
    }

    return headers;
  }

  /// Check if token is valid and not expired
  bool get isTokenValid {
    if (_cachedAccessToken == null || _tokenExpiry == null) {
      return false;
    }

    final now = DateTime.now();
    return _tokenExpiry!.isAfter(now.add(const Duration(minutes: 1)));
  }

  /// Force refresh token
  Future<bool> forceRefreshToken() async {
    debugPrint('TokenManagementService: Force refreshing token...');
    return await _refreshTokenIfNeeded();
  }

  /// Get current tenant
  String get currentTenant => _extractedTenant ?? ApiConstants.defaultTenant;

  /// Get current role
  String get currentRole => _selectedRole ?? ApiConstants.defaultRole;

  /// Get all allowed roles
  List<String> get allowedRoles => _allowedRoles ?? [ApiConstants.defaultRole];

  /// Get token expiry time
  DateTime? get tokenExpiry => _tokenExpiry;

  /// Get time until token expires
  Duration? get timeUntilExpiry {
    if (_tokenExpiry == null) return null;
    final now = DateTime.now();
    final diff = _tokenExpiry!.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Set specific role (if allowed)
  bool setRole(String role) {
    if (_allowedRoles != null && _allowedRoles!.contains(role)) {
      _selectedRole = role;
      notifyListeners();
      debugPrint('TokenManagementService: Role changed to: $role');
      return true;
    }

    debugPrint(
      'TokenManagementService: Role $role not allowed. Allowed roles: $_allowedRoles',
    );
    return false;
  }

  /// Get token information summary
  Map<String, dynamic> getTokenInfo() {
    return {
      'isValid': isTokenValid,
      'tenant': currentTenant,
      'role': currentRole,
      'allowedRoles': allowedRoles,
      'expiresAt': _tokenExpiry?.toIso8601String(),
      'timeUntilExpiry': timeUntilExpiry?.inMinutes,
      'hasToken': _cachedAccessToken != null,
    };
  }

  /// Initialize the token management service
  Future<void> initialize() async {
    debugPrint('TokenManagementService: Initializing...');

    try {
      // Extract token data initially
      _onKeycloakServiceChanged();

      // Start auto-refresh if needed
      _scheduleTokenRefresh();

      debugPrint('TokenManagementService: ✅ Initialized successfully');
    } catch (e) {
      debugPrint('TokenManagementService: ❌ Initialization failed: $e');
      // Don't throw - allow graceful degradation
    }
  }
}
