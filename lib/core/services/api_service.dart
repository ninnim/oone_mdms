import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import 'keycloak_service.dart';
import 'token_management_service.dart';

class ApiService {
  late final Dio _dio;
  final KeycloakService? _keycloakService;
  final TokenManagementService? _tokenManagementService;

  ApiService([this._keycloakService, this._tokenManagementService]) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        headers: {
          'Content-Type': ApiConstants.contentType,
          'Accept': ApiConstants.accept,
          ApiConstants.role:
              _keycloakService?.getCurrentRole ??
              _tokenManagementService?.currentRole,
          //'x-hasura-admin-secret': '4)-g\$xR&M0siAov3Fl4O',
          // Note: All other headers will be set dynamically in the interceptor
        },
      ),
    );

    // Add interceptor for dynamic headers and auto token refresh
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Step 1: Check token expiry and refresh if needed
          await _ensureValidToken();

          // Step 2: Always try to get dynamic headers from TokenManagementService
          bool dynamicHeadersAdded = false;
          if (_tokenManagementService != null) {
            try {
              final dynamicHeaders = _tokenManagementService.getApiHeaders();

              // Ensure required headers are present
              if (dynamicHeaders.containsKey('x-hasura-role') &&
                  dynamicHeaders.containsKey('Authorization')) {
                // Replace all headers with dynamic ones
                options.headers.addAll(dynamicHeaders);
                dynamicHeadersAdded = true;
              }
            } catch (e) {
              // Silently continue to fallback
            }
          }

          // Step 3: Fallback - ensure minimum required headers are present
          if (!dynamicHeadersAdded) {
            await _addFallbackHeaders(options);
          }

          // Step 4: Validate that required headers are present
          _validateRequiredHeaders(options);

          handler.next(options);
        },
      ),
    );

    // Add interceptors for debugging in development only
    if (!kReleaseMode) {
      // Temporarily disabled LogInterceptor due to header parsing issues
      // _dio.interceptors.add(
      //   LogInterceptor(
      //     requestBody: false,
      //     responseBody: false,
      //     logPrint: (object) => debugPrint(object.toString()),
      //   ),
      // );
    }
  }

  /// Ensure token is valid and refresh if needed
  Future<void> _ensureValidToken() async {
    try {
      // Check if token management service is available
      if (_tokenManagementService != null) {
        if (!_tokenManagementService.isTokenValid) {
          // Try to refresh token
          if (_keycloakService != null) {
            await _keycloakService.refreshToken();
          }
        }
      }
    } catch (e) {
      // Silently handle token refresh errors
    }
  }

  /// Add fallback headers when dynamic headers are not available
  Future<void> _addFallbackHeaders(RequestOptions options) async {
    if (_keycloakService != null) {
      // Ensure Keycloak is authenticated
      if (!_keycloakService.isAuthenticated) {
        await Future.delayed(Duration(milliseconds: 100));
      }

      final accessToken = _keycloakService.accessToken;
      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }

      // Add fallback role if available
      if (_keycloakService.getCurrentRole().isNotEmpty) {
        options.headers['x-hasura-role'] = _keycloakService.getCurrentRole();
      }
    }
  }

  /// Validate that required headers are present
  void _validateRequiredHeaders(RequestOptions options) {
    final requiredHeaders = ['x-hasura-role', 'Authorization'];
    final missingHeaders = <String>[];

    for (final header in requiredHeaders) {
      if (!options.headers.containsKey(header) ||
          options.headers[header] == null ||
          options.headers[header].toString().isEmpty) {
        missingHeaders.add(header);
      }
    }

    if (missingHeaders.isNotEmpty) {
      // Add default headers as last resort
      if (missingHeaders.contains('x-hasura-role')) {
        options.headers['x-hasura-role'] = ApiConstants.defaultRole;
      }
      if (missingHeaders.contains('Authorization') &&
          _keycloakService?.accessToken != null) {
        options.headers['Authorization'] =
            'Bearer ${_keycloakService!.accessToken}';
      }
    }
  }

  // GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE request
  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Error handling
  Exception _handleError(DioException error) {
    String message;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        message = 'Connection timeout';
        break;
      case DioExceptionType.sendTimeout:
        message = 'Send timeout';
        break;
      case DioExceptionType.receiveTimeout:
        message = 'Receive timeout';
        break;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        message =
            'Server error ($statusCode): ${data?.toString() ?? 'Unknown error'}';
        break;
      case DioExceptionType.cancel:
        message = 'Request cancelled';
        break;
      case DioExceptionType.connectionError:
        message = 'Connection error';
        break;
      default:
        message = 'Unknown error: ${error.message}';
    }

    return Exception(message);
  }
}
