import 'package:flutter/material.dart';
import '../../../core/services/error_translation_service.dart';
import '../../../core/constants/app_messages.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/error_message_widget.dart';

/// Example usage of the error translation system
class ErrorTranslationExamples extends StatefulWidget {
  const ErrorTranslationExamples({super.key});

  @override
  State<ErrorTranslationExamples> createState() =>
      _ErrorTranslationExamplesState();
}

class _ErrorTranslationExamplesState extends State<ErrorTranslationExamples> {
  String _lastError = 'No errors yet';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error Translation Examples')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Error Translation System Examples',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Example 1: Direct error translation
            const Text(
              '1. Direct Error Translation:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _simulateError('API returned 404'),
              child: const Text('Simulate API 404 Error'),
            ),

            const SizedBox(height: 16),

            // Example 2: Context-aware translation
            const Text(
              '2. Context-aware Translation:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () =>
                  _simulateContextualError('Network timeout', 'device_create'),
              child: const Text('Simulate Device Creation Error'),
            ),

            const SizedBox(height: 16),

            // Example 3: Toast error display
            const Text(
              '3. Error Toast Display:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _showErrorToast('Token expired'),
              child: const Text('Show Error Toast'),
            ),

            const SizedBox(height: 16),

            // Example 4: Error widget display
            const Text(
              '4. Error Widget Display:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _showErrorWidget('DEVICE_NOT_FOUND'),
              child: const Text('Show Error Widget'),
            ),

            const SizedBox(height: 24),

            // Display last error
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Last Error Translation:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(_lastError),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Error widget example
            if (_showExampleError)
              ErrorMessageWidget(
                error: _exampleError,
                context: 'device_operation',
                onRetry: () {
                  setState(() {
                    _showExampleError = false;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  bool _showExampleError = false;
  dynamic _exampleError;

  void _simulateError(String errorMessage) {
    final translated = ErrorTranslationService.translateError(errorMessage);
    setState(() {
      _lastError = 'Original: "$errorMessage"\nTranslated: "$translated"';
    });
  }

  void _simulateContextualError(String errorMessage, String context) {
    final translated = ErrorTranslationService.getContextualErrorMessage(
      errorMessage,
      context,
    );
    setState(() {
      _lastError =
          'Original: "$errorMessage"\nContext: "$context"\nTranslated: "$translated"';
    });
  }

  void _showErrorToast(String errorMessage) {
    AppToast.showError(
      context,
      error: errorMessage,
      title: 'Authentication Error',
      errorContext: 'login',
    );

    final translated = ErrorTranslationService.translateError(
      errorMessage,
      context: 'login',
    );
    setState(() {
      _lastError = 'Toast shown with: "$translated"';
    });
  }

  void _showErrorWidget(String errorMessage) {
    setState(() {
      _exampleError = errorMessage;
      _showExampleError = true;
      _lastError = 'Error widget shown for: "$errorMessage"';
    });
  }
}

/// Example of using error translation in a service call
class DeviceOperationExample {
  /// Example method showing how to handle API errors with translation
  static Future<String> exampleApiCall(String deviceId) async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Simulate different types of errors
      if (deviceId == 'not_found') {
        throw Exception('Device with ID $deviceId not found');
      } else if (deviceId == 'network') {
        throw Exception('Connection timeout');
      } else if (deviceId == 'auth') {
        throw Exception('Unauthorized access');
      }

      return 'Operation successful';
    } catch (e) {
      // Use error translation service to get user-friendly message
      final userFriendlyMessage =
          ErrorTranslationService.getContextualErrorMessage(
            e,
            'device_operation',
          );

      // Return the translated error message
      throw userFriendlyMessage;
    }
  }

  /// Example of showing error in UI
  static void showErrorInUI(BuildContext context, dynamic error) {
    // Method 1: Using toast
    AppToast.showError(context, error: error, errorContext: 'device_operation');

    // Method 2: Using snackbar
    ErrorSnackBar.show(context, error, errorContext: 'device_operation');

    // Method 3: Using dialog for critical errors
    ErrorDialog.show(
      context,
      error,
      title: 'Operation Failed',
      errorContext: 'device_operation',
      actionText: 'Retry',
      onAction: () {
        // Retry logic here
      },
    );
  }
}

/// Documentation and examples of error codes and their translations
class ErrorTranslationDocumentation {
  static const Map<String, String> examples = {
    // HTTP Status Codes
    '400': AppMessages.validationError,
    '401': AppMessages.unauthorizedError,
    '403': AppMessages.forbiddenError,
    '404': AppMessages.notFoundError,
    '500': AppMessages.serverError,

    // API Error Codes
    'DEVICE_NOT_FOUND': AppMessages.deviceNotFound,
    'DEVICE_ALREADY_EXISTS': AppMessages.deviceAlreadyExists,
    'TOKEN_EXPIRED': AppMessages.tokenExpired,
    'VALIDATION_ERROR': AppMessages.validationError,

    // Common Error Patterns
    'connection timeout': AppMessages.timeoutError,
    'network error': AppMessages.networkError,
    'unauthorized': AppMessages.unauthorizedError,
  };

  /// Usage examples for different scenarios
  static void demonstrateUsage() {
    // Example 1: Basic translation
    final error1 = ErrorTranslationService.translateError('404');
    print('404 translates to: $error1');

    // Example 2: Context-aware translation
    final error2 = ErrorTranslationService.getContextualErrorMessage(
      'Device not found',
      'device_delete',
    );
    print('Device error translates to: $error2');

    // Example 3: Complex error object
    final complexError = {
      'error': {'message': 'Token has expired', 'code': 'TOKEN_EXPIRED'},
    };
    final error3 = ErrorTranslationService.translateError(complexError);
    print('Complex error translates to: $error3');
  }
}
