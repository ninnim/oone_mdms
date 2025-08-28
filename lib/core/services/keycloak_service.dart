import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:dio/dio.dart';
// Web-specific import
import 'dart:js' as js;

class KeycloakService extends ChangeNotifier {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    webOptions: WebOptions(
      dbName: 'mdms_keycloak_storage',
      publicKey: 'mdms_keycloak_public_key',
    ),
  );

  // Keycloak configuration
  static const String _baseUrl = 'https://oauth.oone.bz';
  static const String _realm = 'oone-ids';
  static const String _clientId = 'mdms';
  static const String _clientSecret = '0LTm4RzMaEGTjjOmrVVSWy1z3S6AOo5D';
  static const String _scope = 'openid profile email';

  // Keycloak endpoints
  static String get _authorizationEndpoint =>
      '$_baseUrl/realms/$_realm/protocol/openid-connect/auth';
  static String get _tokenEndpoint =>
      '$_baseUrl/realms/$_realm/protocol/openid-connect/token';
  static String get _userInfoEndpoint =>
      '$_baseUrl/realms/$_realm/protocol/openid-connect/userinfo';
  static String get _logoutEndpoint =>
      '$_baseUrl/realms/$_realm/protocol/openid-connect/logout';
  static String get _introspectEndpoint =>
      '$_baseUrl/realms/$_realm/protocol/openid-connect/token/introspect';

  // Storage keys
  static const String _accessTokenKey = 'keycloak_access_token';
  static const String _refreshTokenKey = 'keycloak_refresh_token';
  static const String _userInfoKey = 'keycloak_user_info';

  // Current user info
  Map<String, dynamic>? _currentUser;
  oauth2.Client? _oauthClient;
  String? _accessToken;

  // Callback for tenant service initialization
  Function()? _onTokenRefreshed;

  // Public getters
  String? get selectRoles => getCurrentRole();
  bool get isAuthenticated => _oauthClient != null && _accessToken != null;
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get accessToken {
    if (_accessToken != null) {}
    return _accessToken;
  }

  /// Set callback to be called when token is refreshed successfully
  void setTokenRefreshCallback(Function()? callback) {
    _onTokenRefreshed = callback;
  }

  /// Call CurrentUser API to get tenant information
  Future<void> callCurrentUserAPI() async {
    if (_accessToken == null) return;

    try {
      final dio = Dio();
      final response = await dio.get(
        'https://mtc-stg.oone.bz/v1/CurrentUser?ModuleCode=MDMS',
        options: Options(headers: {'Authorization': 'Bearer $_accessToken'}),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('KeycloakService: CurrentUser API call successful');
        }
        // Trigger tenant service refresh if callback is set
        _onTokenRefreshed?.call();
      }
    } catch (e) {
      if (kDebugMode) {
        print('KeycloakService: CurrentUser API call failed: $e');
      }
    }
  }

  Future<void> initialize() async {
    await _loadStoredTokens();

    if (isAuthenticated) {
      await _loadUserInfo();
    } else {}
    notifyListeners();
  }

  Future<void> login() async {
    if (kIsWeb) {
      await _webLogin();
    } else {
      throw UnsupportedError('OAuth login is only supported on web platform');
    }
  }

  Future<void> _webLogin() async {
    try {
      // Get current URL for redirect using JS context
      final currentUrl = js.context['location']['href']
          .split('?')[0]
          .split('#')[0];
      // Extract the base URL (protocol + host + port) from current URL
      final uri = Uri.parse(currentUrl);
      final baseUrl =
          '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
      final redirectUri = '$baseUrl/auth/callback';

      // Create OAuth2 authorization URL
      final authorizationUrl = Uri.parse(_authorizationEndpoint).replace(
        queryParameters: {
          'client_id': _clientId,
          'redirect_uri': redirectUri,
          'response_type': 'code',
          'scope': _scope,
        },
      );

      // Store the redirect URI for callback handling
      await _secureStorage.write(key: 'redirect_uri', value: redirectUri);

      // Use window.open to redirect to Keycloak login
      try {
        // Force a full page redirect to Keycloak
        js.context.callMethod('eval', [
          'window.location.href = "${authorizationUrl.toString()}";',
        ]);
      } catch (e) {
        if (kDebugMode) {
          print(
            'KeycloakService: Failed to redirect using eval, trying direct assignment: $e',
          );
        }
        // Fallback method
        js.context['location']['href'] = authorizationUrl.toString();
      }
    } catch (e) {
      if (kDebugMode) {
        print('KeycloakService: Error in _webLogin: $e');
      }
      rethrow;
    }
  }

  Future<bool> handleCallback(String code) async {
    try {
      if (kDebugMode) {
        print(
          'KeycloakService: Starting handleCallback with code: ${code.substring(0, 10)}...',
        );
      }
      final redirectUri = await _secureStorage.read(key: 'redirect_uri');
      if (redirectUri == null) {
        if (kDebugMode) {
          print('KeycloakService: Redirect URI not found');
        }
        throw Exception('Redirect URI not found');
      }
      if (kDebugMode) {
        print('KeycloakService: Using redirect URI: $redirectUri');
      }

      // Exchange authorization code for tokens
      if (kDebugMode) {
        print('KeycloakService: Exchanging code for tokens...');
      }
      final response = await Dio().post(
        _tokenEndpoint,
        data: {
          'grant_type': 'authorization_code',
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'code': code,
          'redirect_uri': redirectUri,
        },
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );

      if (response.statusCode == 200) {
        final tokenData = response.data;
        _accessToken = tokenData['access_token'];
        final refreshToken = tokenData['refresh_token'];

        // Store tokens
        await _storeTokens(_accessToken!, refreshToken);
        // Clean the URL to remove authentication parameters early
        cleanUrlAfterAuth();

        // Create OAuth client with credentials
        final credentials = oauth2.Credentials(
          _accessToken!,
          refreshToken: refreshToken,
          tokenEndpoint: Uri.parse(_tokenEndpoint),
        );

        _oauthClient = oauth2.Client(
          credentials,
          identifier: _clientId,
          secret: _clientSecret,
        );

        // Load user info
        await _loadUserInfo();

        // Call CurrentUser API to get tenant information
        await callCurrentUserAPI();

        // print('KeycloakService: Notifying listeners...');
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      if (refreshToken != null) {
        try {
          // print('KeycloakService: Revoking refresh token...');
          final dio = Dio();
          await dio.post(
            _logoutEndpoint,
            data: {
              'client_id': _clientId,
              'client_secret': _clientSecret,
              'refresh_token': refreshToken,
            },
            options: Options(
              headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            ),
          );
        } catch (e) {
          print('KeycloakService: Error revoking token: $e');
          // Continue with logout even if revocation fails
        }
      }

      // Clear stored data
      await _clearStoredData();

      // Reset state
      _accessToken = null;
      _oauthClient = null;
      _currentUser = null;

      notifyListeners();

      // Redirect to Keycloak logout page
      if (kIsWeb) {
        final currentUrl = js.context['location']['href']
            .split('?')[0]
            .split('#')[0];
        final uri = Uri.parse(currentUrl);
        final baseUrl =
            '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
        final postLogoutRedirectUri = baseUrl;

        final logoutUrl = Uri.parse(_logoutEndpoint).replace(
          queryParameters: {
            'client_id': _clientId,
            'post_logout_redirect_uri': postLogoutRedirectUri,
          },
        );

        print('KeycloakService: Redirecting to logout URL: $logoutUrl');
        js.context['location']['href'] = logoutUrl.toString();
      }
    } catch (e) {
      print('KeycloakService: Logout error: $e');
    }
  }

  Future<void> _loadStoredTokens() async {
    try {
      //  print('KeycloakService: Loading stored tokens...');
      _accessToken = await _secureStorage.read(key: _accessTokenKey);
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);

      // print(
      //   'KeycloakService: Access token loaded: ${_accessToken != null ? 'YES (${_accessToken!.substring(0, 20)}...)' : 'NO'}',
      // );
      // print(
      //   'KeycloakService: Refresh token loaded: ${refreshToken != null ? 'YES' : 'NO'}',
      // );

      if (_accessToken != null && refreshToken != null) {
        // print('KeycloakService: Creating OAuth client with stored tokens');
        // Recreate OAuth client with stored tokens
        final credentials = oauth2.Credentials(
          _accessToken!,
          refreshToken: refreshToken,
          tokenEndpoint: Uri.parse(_tokenEndpoint),
        );

        _oauthClient = oauth2.Client(
          credentials,
          identifier: _clientId,
          secret: _clientSecret,
        );

        // print('KeycloakService: Checking if access token is expired...');
        // Check if access token is expired and refresh if needed
        if (_isTokenExpired(_accessToken!)) {
          ///  print('KeycloakService: Token expired, refreshing...');
          await _refreshTokens();
        } else {
          print('KeycloakService: Token is still valid');
        }
      } else {
        print('KeycloakService: No stored tokens found');
      }
    } catch (e) {
      print('KeycloakService: Error loading stored tokens: $e');
    }
  }

  Future<void> _storeTokens(String accessToken, String? refreshToken) async {
    try {
      await _secureStorage.write(key: _accessTokenKey, value: accessToken);
      if (refreshToken != null) {
        await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
      }
    } catch (e) {
      print('KeycloakService: Error storing tokens: $e');
    }
  }

  Future<void> _loadUserInfo() async {
    if (_accessToken == null) return;

    try {
      // First try to get user info from stored data
      final storedUserInfo = await _secureStorage.read(key: _userInfoKey);
      if (storedUserInfo != null) {
        _currentUser = json.decode(storedUserInfo);
        print('KeycloakService: Loaded cached user info');
      }

      // Then fetch fresh user info from Keycloak
      await getUserInfo();
    } catch (e) {
      print('KeycloakService: Error loading user info: $e');
    }
  }

  /// Refresh the access token using the stored refresh token
  /// Returns true if refresh was successful, false otherwise
  Future<bool> refreshToken() async {
    try {
      await _refreshTokens();
      return _accessToken != null;
    } catch (e) {
      print('KeycloakService: Failed to refresh token: $e');
      return false;
    }
  }

  Future<void> _refreshTokens() async {
    final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
    if (refreshToken == null) {
      print('KeycloakService: No refresh token available');
      return;
    }

    try {
      print('KeycloakService: Refreshing tokens...');
      final dio = Dio();
      final response = await dio.post(
        _tokenEndpoint,
        data: {
          'grant_type': 'refresh_token',
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'refresh_token': refreshToken,
        },
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );

      if (response.statusCode == 200) {
        final tokenData = response.data;
        _accessToken = tokenData['access_token'];
        final newRefreshToken = tokenData['refresh_token'];

        print('KeycloakService: Tokens refreshed successfully');

        // Store new tokens
        await _storeTokens(_accessToken!, newRefreshToken);

        // Recreate OAuth client with new credentials
        final credentials = oauth2.Credentials(
          _accessToken!,
          refreshToken: newRefreshToken,
          tokenEndpoint: Uri.parse(_tokenEndpoint),
        );

        _oauthClient = oauth2.Client(
          credentials,
          identifier: _clientId,
          secret: _clientSecret,
        );

        // Call CurrentUser API to get updated tenant information
        await callCurrentUserAPI();

        notifyListeners();
      } else {
        print(
          'KeycloakService: Token refresh failed with status: ${response.statusCode}',
        );
        throw Exception('Token refresh failed');
      }
    } catch (e) {
      print('KeycloakService: Error refreshing tokens: $e');
      // If refresh fails, clear tokens and require re-login
      await _clearStoredData();
      _accessToken = null;
      _oauthClient = null;
      _currentUser = null;
      notifyListeners();
    }
  }

  bool _isTokenExpired(String token) {
    try {
      return JwtDecoder.isExpired(token);
    } catch (e) {
      return true; // If we can't decode, assume expired
    }
  }

  Future<void> _clearStoredData() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _userInfoKey);
    await _secureStorage.delete(key: 'redirect_uri');
  }

  Future<bool> introspectToken() async {
    if (_accessToken == null) return false;

    try {
      print('KeycloakService: Introspecting token...');
      final dio = Dio();
      final response = await dio.post(
        _introspectEndpoint,
        data: {
          'token': _accessToken,
          'client_id': _clientId,
          'client_secret': _clientSecret,
        },
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );

      if (response.statusCode == 200) {
        final introspectionData = response.data;
        final isActive = introspectionData['active'] ?? false;
        print(
          'KeycloakService: Token introspection result - active: $isActive',
        );
        return isActive;
      }

      print(
        'KeycloakService: Token introspection failed with status: ${response.statusCode}',
      );
      return false;
    } catch (e) {
      print('KeycloakService: Token introspection error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserInfo() async {
    if (_accessToken == null) return null;

    try {
      print('KeycloakService: Fetching user info...');
      final dio = Dio();
      final response = await dio.get(
        _userInfoEndpoint,
        options: Options(headers: {'Authorization': 'Bearer $_accessToken'}),
      );

      if (response.statusCode == 200) {
        print('KeycloakService: User info fetched successfully');
        _currentUser = response.data;
        await _secureStorage.write(
          key: _userInfoKey,
          value: json.encode(_currentUser),
        );
        return _currentUser;
      }

      print(
        'KeycloakService: Failed to fetch user info - status: ${response.statusCode}',
      );
      return null;
    } catch (e) {
      print('KeycloakService: Error fetching user info: $e');
      return null;
    }
  }

  /// Ensures the access token is valid and refreshes if necessary
  Future<bool> ensureValidToken() async {
    if (_accessToken == null) {
      print('KeycloakService: No access token available');
      return false;
    }

    // Check if token is expired
    if (_isTokenExpired(_accessToken!)) {
      print('KeycloakService: Access token expired, attempting refresh...');
      await _refreshTokens();
      return _accessToken != null;
    }

    // Token is still valid
    print('KeycloakService: Access token is still valid');
    return true;
  }

  /// Gets a valid access token, refreshing if necessary
  Future<String?> getValidAccessToken() async {
    final isValid = await ensureValidToken();
    return isValid ? _accessToken : null;
  }

  /// Checks if the user has a specific scope
  bool hasScope(String scope) {
    if (_accessToken == null) return false;

    try {
      final decodedToken = JwtDecoder.decode(_accessToken!);
      final scopes = decodedToken['scope']?.toString().split(' ') ?? [];
      return scopes.contains(scope);
    } catch (e) {
      print('KeycloakService: Error checking scope: $e');
      return false;
    }
  }

  /// Gets the user's roles from the token
  ///
  String getCurrentRole() {
    if (_accessToken == null) return 'getField';

    try {
      final decodedToken = JwtDecoder.decode(_accessToken!);
      final hasuraClaims = decodedToken['https://hasura.io/jwt/claims'];
      final hasuraRoles =
          hasuraClaims?['x-hasura-allowed-roles'] as List<dynamic>?;
      final selectRoles = hasuraClaims.isNotEmpty ? hasuraRoles?.last : null;
      debugPrint('getRole: $selectRoles');
      return selectRoles?.toString() ?? '';
    } catch (e) {
      print('KeycloakService: Error getting current role: $e');
      return '';
    }
  }

  List<String> getUserRoles() {
    if (_accessToken == null) return [];

    try {
      final decodedToken = JwtDecoder.decode(_accessToken!);
      final realmAccess = decodedToken['realm_access'] as Map<String, dynamic>?;
      final roles = realmAccess?['roles'] as List<dynamic>?;
      return roles?.map((role) => role.toString()).toList() ?? [];
    } catch (e) {
      print('KeycloakService: Error getting user roles: $e');
      return [];
    }
  }

  /// Gets token expiration time
  DateTime? getTokenExpiration() {
    if (_accessToken == null) return null;

    try {
      final decodedToken = JwtDecoder.decode(_accessToken!);
      final exp = decodedToken['exp'] as int?;
      return exp != null
          ? DateTime.fromMillisecondsSinceEpoch(exp * 1000)
          : null;
    } catch (e) {
      print('KeycloakService: Error getting token expiration: $e');
      return null;
    }
  }

  /// Cleans the browser URL by removing authentication parameters
  void cleanUrlAfterAuth() {
    if (kIsWeb) {
      try {
        print(
          'KeycloakService: Cleaning URL after successful authentication...',
        );

        // Get the current location without query parameters or hash
        final origin = js.context['location']['origin'];
        final cleanUrl = '$origin/dashboard';

        // Replace the current history state to clean the URL
        js.context['history'].callMethod('replaceState', [null, '', cleanUrl]);

        print('KeycloakService: URL cleaned successfully - new URL: $cleanUrl');
      } catch (e) {
        print('KeycloakService: Error cleaning URL: $e');

        // Fallback method using direct assignment
        try {
          final origin = js.context['location']['origin'];
          final cleanUrl = '$origin/dashboard';
          js.context['location']['href'] = cleanUrl;
          print(
            'KeycloakService: URL cleaned using fallback method: $cleanUrl',
          );
        } catch (fallbackError) {
          print(
            'KeycloakService: Fallback URL cleaning also failed: $fallbackError',
          );
        }
      }
    }
  }
}
