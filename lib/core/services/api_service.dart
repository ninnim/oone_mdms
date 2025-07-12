import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import 'keycloak_service.dart';

class ApiService {
  late final Dio _dio;
  final KeycloakService? _keycloakService;

  ApiService([this._keycloakService]) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        headers: {
          'Content-Type': ApiConstants.contentType,
          'Accept': ApiConstants.accept,
          'x-hasura-admin-secret': '4)-g\$xR&M0siAov3Fl4O',
          ApiConstants.tenant: ApiConstants.defaultTenant,
          ApiConstants.user: ApiConstants.defaultUser,
          ApiConstants.role: ApiConstants.defaultRole,
          'x-hasura-user-name': 'Admin',
          'x-hasura-user-id': '0a12968d-2a38-48ee-b60a-ce2498040825',
        },
      ),
    );

    // Add interceptor for Keycloak Bearer token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          debugPrint(
            'ApiService: Interceptor triggered for ${options.method} ${options.uri}',
          );
          debugPrint(
            'ApiService: Keycloak service available: ${_keycloakService != null}',
          );

          if (_keycloakService != null) {
            // Wait a moment to ensure Keycloak initialization is complete
            if (!_keycloakService.isAuthenticated) {
              debugPrint(
                'ApiService: Keycloak not authenticated, waiting briefly...',
              );
              await Future.delayed(Duration(milliseconds: 100));
            }

            debugPrint(
              'ApiService: Keycloak service authenticated: ${_keycloakService.isAuthenticated}',
            );
            final accessToken = _keycloakService.accessToken;
            debugPrint(
              'ApiService: Access token available: ${accessToken != null}',
            );

            if (accessToken != null && accessToken.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $accessToken';
              debugPrint(
                'ApiService: ✅ Adding Authorization header with token: ${accessToken.substring(0, 20)}...',
              );
            } else {
              debugPrint('ApiService: ❌ Access token is null or empty');
            }
          } else {
            debugPrint('ApiService: ❌ Keycloak service is null');
          }

          debugPrint('ApiService: Final headers: ${options.headers}');
          handler.next(options);
        },
      ),
    );

    // Add interceptors for debugging
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) => debugPrint(object.toString()),
      ),
    );
  }

  void setToken(String token) {
    _dio.options.headers[ApiConstants.tokenHeader] = token;
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
