import 'dart:convert';
import 'package:dio/dio.dart';
import '../constants/app_messages.dart';

/// Service for translating error messages to user-friendly format
class ErrorTranslationService {
  // Private constructor to prevent instantiation
  ErrorTranslationService._();

  /// Translates any error to a user-friendly message
  static String translateError(dynamic error, {String? context}) {
    if (error == null) {
      return AppMessages.defaultError;
    }

    // Handle DioException (network errors)
    if (error is DioException) {
      return _translateDioError(error, context: context);
    }

    // Handle FormatException (JSON parsing errors)
    if (error is FormatException) {
      return _translateFormatError(error, context: context);
    }

    // Handle String errors
    if (error is String) {
      return _translateStringError(error, context: context);
    }

    // Handle Map errors (API response errors)
    if (error is Map<String, dynamic>) {
      return _translateMapError(error, context: context);
    }

    // Handle Exception objects
    if (error is Exception) {
      return _translateExceptionError(error, context: context);
    }

    // Fallback for unknown error types
    return _translateUnknownError(error, context: context);
  }

  /// Translates DioException to user-friendly message
  static String _translateDioError(DioException error, {String? context}) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppMessages.timeoutError;

      case DioExceptionType.connectionError:
        return AppMessages.networkError;

      case DioExceptionType.badResponse:
        return _translateHttpStatusCode(
          error.response?.statusCode,
          error.response?.data,
          context: context,
        );

      case DioExceptionType.cancel:
        return 'Request was cancelled. Please try again.';

      case DioExceptionType.badCertificate:
        return 'Security certificate error. Please contact support.';

      case DioExceptionType.unknown:
        return _translateUnknownDioError(error, context: context);
    }
  }

  /// Translates HTTP status codes to user-friendly messages
  static String _translateHttpStatusCode(
    int? statusCode,
    dynamic responseData, {
    String? context,
  }) {
    if (statusCode == null) {
      return AppMessages.networkError;
    }

    // First, try to extract error message from response data
    final apiErrorMessage = _extractApiErrorMessage(responseData);
    if (apiErrorMessage != null) {
      return apiErrorMessage;
    }

    // Fallback to status code mapping
    final statusCodeStr = statusCode.toString();
    return AppMessages.apiErrorMessages[statusCodeStr] ??
        AppMessages.serverError;
  }

  /// Extracts error message from API response data
  static String? _extractApiErrorMessage(dynamic responseData) {
    if (responseData == null) return null;

    try {
      Map<String, dynamic> data;

      if (responseData is String) {
        data = json.decode(responseData);
      } else if (responseData is Map<String, dynamic>) {
        data = responseData;
      } else {
        return null;
      }

      // Common API error message fields
      final errorFields = ['message', 'error', 'details', 'description', 'msg'];

      for (final field in errorFields) {
        if (data.containsKey(field) && data[field] is String) {
          final errorMessage = data[field] as String;
          return _translateApiErrorMessage(errorMessage);
        }
      }

      // Check for error code mapping
      if (data.containsKey('code') && data['code'] is String) {
        final errorCode = data['code'] as String;
        return AppMessages.apiErrorMessages[errorCode];
      }

      // Check for nested error objects
      if (data.containsKey('error') && data['error'] is Map) {
        final errorObj = data['error'] as Map<String, dynamic>;
        if (errorObj.containsKey('message')) {
          return _translateApiErrorMessage(errorObj['message'].toString());
        }
      }
    } catch (e) {
      // If JSON parsing fails, return null to use fallback
      return null;
    }

    return null;
  }

  /// Translates API error messages to user-friendly format
  static String _translateApiErrorMessage(String apiMessage) {
    final lowerMessage = apiMessage.toLowerCase();

    // Check for exact matches in API error messages
    for (final entry in AppMessages.apiErrorMessages.entries) {
      if (lowerMessage.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    // Check for pattern matches
    for (final entry in AppMessages.errorPatterns.entries) {
      if (lowerMessage.contains(entry.key)) {
        return entry.value;
      }
    }

    // Device-specific error patterns
    if (lowerMessage.contains('device')) {
      if (lowerMessage.contains('not found')) return AppMessages.deviceNotFound;
      if (lowerMessage.contains('already exists'))
        return AppMessages.deviceAlreadyExists;
      if (lowerMessage.contains('commission'))
        return AppMessages.deviceCommissionFailed;
      if (lowerMessage.contains('decommission'))
        return AppMessages.deviceDecommissionFailed;
      if (lowerMessage.contains('update'))
        return AppMessages.deviceUpdateFailed;
      if (lowerMessage.contains('delete'))
        return AppMessages.deviceDeleteFailed;
      if (lowerMessage.contains('link') || lowerMessage.contains('hes'))
        return AppMessages.deviceLinkHesFailed;
      if (lowerMessage.contains('ping')) return AppMessages.devicePingFailed;
    }

    // Authentication-specific error patterns
    if (lowerMessage.contains('auth') ||
        lowerMessage.contains('login') ||
        lowerMessage.contains('credential')) {
      return AppMessages.loginFailed;
    }

    if (lowerMessage.contains('token')) {
      if (lowerMessage.contains('expired')) return AppMessages.tokenExpired;
      if (lowerMessage.contains('invalid')) return AppMessages.tokenInvalid;
      return AppMessages.sessionExpired;
    }

    // Validation error patterns
    if (lowerMessage.contains('validation') ||
        lowerMessage.contains('invalid') ||
        lowerMessage.contains('required')) {
      return AppMessages.validationError;
    }

    // If no pattern matches, return the original message if it's reasonably short and user-friendly
    if (apiMessage.length <= 100 && !_containsTechnicalTerms(apiMessage)) {
      return apiMessage;
    }

    // Fallback to default error
    return AppMessages.defaultError;
  }

  /// Checks if message contains technical terms that shouldn't be shown to users
  static bool _containsTechnicalTerms(String message) {
    final technicalTerms = [
      'stack trace',
      'exception',
      'null pointer',
      'sql',
      'database',
      'internal error',
      'system error',
      'fatal error',
      'core dump',
      'segmentation fault',
      'memory',
      'thread',
      'process',
      'socket',
      'tcp',
      'http',
      'ssl',
      'tls',
      'certificate',
      'handshake',
      'json',
      'xml',
      'parse',
      'serialize',
      'deserialize',
    ];

    final lowerMessage = message.toLowerCase();
    return technicalTerms.any((term) => lowerMessage.contains(term));
  }

  /// Translates FormatException to user-friendly message
  static String _translateFormatError(
    FormatException error, {
    String? context,
  }) {
    if (context?.toLowerCase().contains('json') == true) {
      return 'Invalid data format received. Please try again.';
    }
    return AppMessages.validationError;
  }

  /// Translates String errors to user-friendly message
  static String _translateStringError(String error, {String? context}) {
    return _translateApiErrorMessage(error);
  }

  /// Translates Map errors to user-friendly message
  static String _translateMapError(
    Map<String, dynamic> error, {
    String? context,
  }) {
    return _extractApiErrorMessage(error) ?? AppMessages.defaultError;
  }

  /// Translates Exception objects to user-friendly message
  static String _translateExceptionError(Exception error, {String? context}) {
    final errorMessage = error.toString();

    // Remove "Exception: " prefix if present
    final cleanMessage = errorMessage.startsWith('Exception: ')
        ? errorMessage.substring(11)
        : errorMessage;

    return _translateApiErrorMessage(cleanMessage);
  }

  /// Translates unknown DioException to user-friendly message
  static String _translateUnknownDioError(
    DioException error, {
    String? context,
  }) {
    final message = error.message;
    if (message != null) {
      return _translateApiErrorMessage(message);
    }
    return AppMessages.networkError;
  }

  /// Translates completely unknown errors to user-friendly message
  static String _translateUnknownError(dynamic error, {String? context}) {
    final errorString = error.toString();

    // Check if it looks like a technical error message
    if (_containsTechnicalTerms(errorString)) {
      return AppMessages.defaultError;
    }

    // If it's a short, readable message, use it
    if (errorString.length <= 100) {
      return errorString;
    }

    return AppMessages.defaultError;
  }

  /// Gets contextual error message based on the operation being performed
  static String getContextualErrorMessage(
    dynamic error,
    String operationContext,
  ) {
    final baseMessage = translateError(error, context: operationContext);

    // Add context-specific prefixes for certain operations
    switch (operationContext.toLowerCase()) {
      case 'device_create':
        return baseMessage == AppMessages.defaultError
            ? 'Failed to create device. Please check your input and try again.'
            : baseMessage;

      case 'device_update':
        return baseMessage == AppMessages.defaultError
            ? 'Failed to update device. Please try again.'
            : baseMessage;

      case 'device_delete':
        return baseMessage == AppMessages.defaultError
            ? AppMessages.deviceDeleteFailed
            : baseMessage;

      case 'device_commission':
        return baseMessage == AppMessages.defaultError
            ? AppMessages.deviceCommissionFailed
            : baseMessage;

      case 'device_ping':
        return baseMessage == AppMessages.defaultError
            ? AppMessages.devicePingFailed
            : baseMessage;

      case 'login':
        return baseMessage == AppMessages.defaultError
            ? AppMessages.loginFailed
            : baseMessage;

      default:
        return baseMessage;
    }
  }
}
