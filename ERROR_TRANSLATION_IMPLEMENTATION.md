# Error Translation System Implementation

## Overview

This implementation provides a comprehensive, dynamic error translation system that converts technical API errors and exceptions into user-friendly messages. The system is designed to be used throughout the Flutter application for consistent error handling and user experience.

## Key Features

✅ **Dynamic Error Translation** - Automatically translates any error type to user-friendly messages
✅ **Context-Aware Messages** - Provides different messages based on the operation context
✅ **Multi-Language Ready** - Centralized message system ready for internationalization
✅ **API Integration** - Seamlessly handles Dio/HTTP errors and API responses
✅ **Reusable Components** - Pre-built widgets for displaying errors consistently
✅ **Extensible** - Easy to add new error patterns and translations

## Architecture

### Core Components

1. **`AppMessages`** - Centralized constants for all user-friendly messages
2. **`ErrorTranslationService`** - Main service for translating errors
3. **`ErrorMessageWidget`** - Reusable widget for displaying errors
4. **`AppToast.showError()`** - Enhanced toast with error translation
5. **`ErrorSnackBar`** & **`ErrorDialog`** - Additional error display options

### File Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── app_messages.dart          # All user-friendly messages
│   └── services/
│       └── error_translation_service.dart  # Error translation logic
└── presentation/
    └── widgets/
        └── common/
            ├── error_message_widget.dart    # Error display widgets
            ├── app_toast.dart              # Enhanced with error handling
            └── error_translation_examples.dart  # Usage examples
```

## Usage Examples

### 1. Basic Error Translation

```dart
// Translate any error to user-friendly message
final userMessage = ErrorTranslationService.translateError(error);
print(userMessage); // "Network connection failed. Please check your internet connection."
```

### 2. Context-Aware Translation

```dart
// Get contextual error message for specific operations
final message = ErrorTranslationService.getContextualErrorMessage(
  error, 
  'device_create'
);
```

### 3. Error Toast Display

```dart
// Show user-friendly error toast
AppToast.showError(
  context,
  error: apiError,
  title: 'Operation Failed',
  errorContext: 'device_delete',
);
```

### 4. Error Widget Display

```dart
// Display error with retry option
ErrorMessageWidget(
  error: exception,
  context: 'device_operation',
  onRetry: () => _retryOperation(),
)
```

### 5. Service Integration

```dart
class DeviceService {
  Future<ApiResponse<Device>> createDevice(Device device) async {
    try {
      // API call logic
      return ApiResponse.success(createdDevice);
    } catch (e) {
      final userMessage = ErrorTranslationService.getContextualErrorMessage(
        e, 
        'device_create'
      );
      return ApiResponse.error(userMessage);
    }
  }
}
```

## Error Translation Mappings

### HTTP Status Codes
- `400` → "Please check your input and try again."
- `401` → "You are not authorized to perform this action."
- `403` → "Access denied. You don't have permission for this action."
- `404` → "The requested resource was not found."
- `500` → "Server error occurred. Please try again later."

### API Error Codes
- `DEVICE_NOT_FOUND` → "Device not found. Please check the device ID."
- `DEVICE_ALREADY_EXISTS` → "A device with this serial number already exists."
- `TOKEN_EXPIRED` → "Authentication token has expired. Please log in again."
- `VALIDATION_ERROR` → "Please check your input and try again."

### Error Patterns
- Contains "connection" → Network error message
- Contains "timeout" → Timeout error message
- Contains "device" + "not found" → Device not found message
- Contains "auth" or "login" → Authentication error message

## Context-Aware Messages

The system provides different messages based on operation context:

```dart
// Different contexts provide specialized messages
'device_create' → "Failed to create device. Please check your input and try again."
'device_delete' → "Failed to delete device. Please try again."
'device_commission' → "Failed to commission device. Please try again."
'login' → "Login failed. Please check your credentials."
```

## Widget Components

### ErrorMessageWidget
- **Full Display**: Complete error card with icon, title, message, and retry button
- **Compact Display**: Inline error with minimal footprint
- **Customizable**: Padding, retry button, styling options

### Enhanced AppToast
- **showError()**: Automatically translates errors
- **showSuccess()**: For success messages
- **showWarning()**: For warning messages
- **showInfo()**: For information messages

### ErrorSnackBar & ErrorDialog
- **ErrorSnackBar.show()**: Bottom notification with translation
- **ErrorDialog.show()**: Modal dialog for critical errors

## API Response Integration

The system automatically extracts error messages from various API response formats:

```json
// Format 1: Simple message
{
  "message": "Device not found"
}

// Format 2: Error object
{
  "error": {
    "message": "Invalid credentials",
    "code": "AUTH_FAILED"
  }
}

// Format 3: Error code only
{
  "code": "DEVICE_NOT_FOUND"
}
```

## Extensibility

### Adding New Error Messages

1. **Add to AppMessages class**:
```dart
static const String newErrorType = 'User-friendly message for new error type.';
```

2. **Add to error mappings**:
```dart
static const Map<String, String> apiErrorMessages = {
  'NEW_ERROR_CODE': AppMessages.newErrorType,
  // ...existing mappings
};
```

3. **Add error patterns**:
```dart
static const Map<String, String> errorPatterns = {
  'new pattern': AppMessages.newErrorType,
  // ...existing patterns
};
```

### Adding New Contexts

Add new context handling in `getContextualErrorMessage()`:

```dart
case 'new_operation':
  return baseMessage == AppMessages.defaultError 
      ? 'Failed to perform new operation. Please try again.'
      : baseMessage;
```

## Best Practices

### 1. Always Use Error Translation
```dart
// ✅ Good - Always translate errors
try {
  await apiCall();
} catch (e) {
  AppToast.showError(context, error: e, errorContext: 'operation_name');
}

// ❌ Bad - Showing raw technical errors
catch (e) {
  AppToast.show(context, title: 'Error', message: e.toString(), type: ToastType.error);
}
```

### 2. Provide Context
```dart
// ✅ Good - Specific context
ErrorTranslationService.getContextualErrorMessage(error, 'device_create');

// ❌ Less helpful - Generic context
ErrorTranslationService.translateError(error);
```

### 3. Use Appropriate Display Method
```dart
// ✅ Toast for non-critical errors
AppToast.showError(context, error: error);

// ✅ Dialog for critical errors requiring user action
ErrorDialog.show(context, error: error, onAction: () => retryOperation());

// ✅ Widget for persistent error states
ErrorMessageWidget(error: error, onRetry: () => reload());
```

### 4. Centralize Error Handling
```dart
// ✅ Good - Handle errors in service layer
class DeviceService {
  Future<ApiResponse<T>> _handleApiCall<T>(Future<T> Function() apiCall, String context) async {
    try {
      final result = await apiCall();
      return ApiResponse.success(result);
    } catch (e) {
      final message = ErrorTranslationService.getContextualErrorMessage(e, context);
      return ApiResponse.error(message);
    }
  }
}
```

## Testing

Test error translation with various error types:

```dart
void testErrorTranslation() {
  // Test HTTP errors
  assert(ErrorTranslationService.translateError('404') == AppMessages.notFoundError);
  
  // Test API errors
  assert(ErrorTranslationService.translateError('DEVICE_NOT_FOUND') == AppMessages.deviceNotFound);
  
  // Test context-aware translation
  final contextMessage = ErrorTranslationService.getContextualErrorMessage(
    'Unknown error', 
    'device_create'
  );
  assert(contextMessage.contains('create device'));
}
```

## Migration Guide

### Updating Existing Code

1. **Replace direct error displays**:
```dart
// Before
AppToast.show(context, title: 'Error', message: 'Error: $e', type: ToastType.error);

// After
AppToast.showError(context, error: e, errorContext: 'operation_name');
```

2. **Update service error handling**:
```dart
// Before
} catch (e) {
  return ApiResponse.error('Failed to load data: $e');
}

// After
} catch (e) {
  final message = ErrorTranslationService.getContextualErrorMessage(e, 'data_load');
  return ApiResponse.error(message);
}
```

3. **Replace error widgets**:
```dart
// Before
Text('Error: ${error.toString()}', style: TextStyle(color: Colors.red))

// After
ErrorMessageWidget(error: error, context: 'operation_name')
```

## Summary

This error translation system provides:

- ✅ **Consistent UX** - All errors display in user-friendly format
- ✅ **Developer Friendly** - Easy to use, minimal code changes required
- ✅ **Maintainable** - Centralized message management
- ✅ **Extensible** - Easy to add new error types and translations
- ✅ **Context-Aware** - Different messages for different operations
- ✅ **Multi-Platform** - Works across all Flutter platforms

The system is now fully integrated and ready for use throughout the MDMS application.
