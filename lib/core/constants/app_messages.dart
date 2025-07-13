/// Centralized message constants for user-friendly error handling and translations
class AppMessages {
  // Private constructor to prevent instantiation
  AppMessages._();

  // === General Error Messages ===
  static const String defaultError =
      'An unexpected error occurred. Please try again.';
  static const String networkError =
      'Network connection failed. Please check your internet connection.';
  static const String timeoutError = 'Request timed out. Please try again.';
  static const String serverError =
      'Server error occurred. Please try again later.';
  static const String unauthorizedError =
      'You are not authorized to perform this action.';
  static const String forbiddenError =
      'Access denied. You don\'t have permission for this action.';
  static const String notFoundError = 'The requested resource was not found.';
  static const String validationError =
      'Please check your input and try again.';
  static const String conflictError =
      'This action conflicts with existing data.';
  static const String tooManyRequestsError =
      'Too many requests. Please wait and try again.';

  // === Device-specific Error Messages ===
  static const String deviceNotFound =
      'Device not found. Please check the device ID.';
  static const String deviceAlreadyExists =
      'A device with this serial number already exists.';
  static const String deviceCommissionFailed =
      'Failed to commission device. Please try again.';
  static const String deviceDecommissionFailed =
      'Failed to decommission device. Please try again.';
  static const String deviceUpdateFailed =
      'Failed to update device information.';
  static const String deviceDeleteFailed =
      'Failed to delete device. Please try again.';
  static const String deviceLinkHesFailed =
      'Failed to link device to HES system.';
  static const String devicePingFailed =
      'Failed to ping device. Device may be offline.';
  static const String deviceInvalidStatus =
      'Invalid device status. Please check device configuration.';
  static const String deviceLocationUpdateFailed =
      'Failed to update device location.';

  // === Authentication Error Messages ===
  static const String loginFailed =
      'Login failed. Please check your credentials.';
  static const String sessionExpired =
      'Your session has expired. Please log in again.';
  static const String tokenInvalid =
      'Authentication token is invalid. Please log in again.';
  static const String tokenExpired =
      'Authentication token has expired. Please log in again.';
  static const String refreshTokenFailed =
      'Failed to refresh authentication token.';
  static const String logoutFailed = 'Failed to log out. Please try again.';

  // === Form Validation Messages ===
  static const String requiredField = 'This field is required.';
  static const String invalidEmail = 'Please enter a valid email address.';
  static const String invalidSerialNumber =
      'Please enter a valid serial number.';
  static const String invalidCoordinates = 'Please enter valid coordinates.';
  static const String invalidDateRange = 'Please select a valid date range.';
  static const String passwordTooShort =
      'Password must be at least 8 characters long.';

  // === Success Messages ===
  static const String deviceCreatedSuccess = 'Device created successfully.';
  static const String deviceUpdatedSuccess = 'Device updated successfully.';
  static const String deviceDeletedSuccess = 'Device deleted successfully.';
  static const String deviceCommissionedSuccess =
      'Device commissioned successfully.';
  static const String deviceDecommissionedSuccess =
      'Device decommissioned successfully.';
  static const String deviceLinkedSuccess =
      'Device linked to HES successfully.';
  static const String settingsSavedSuccess = 'Settings saved successfully.';
  static const String operationSuccess = 'Operation completed successfully.';

  // === Loading Messages ===
  static const String loading = 'Loading...';
  static const String loadingDevices = 'Loading devices...';
  static const String loadingData = 'Loading data...';
  static const String processing = 'Processing...';
  static const String saving = 'Saving...';
  static const String deleting = 'Deleting...';
  static const String commissioning = 'Commissioning device...';
  static const String decommissioning = 'Decommissioning device...';

  // === Confirmation Messages ===
  static const String confirmDelete =
      'Are you sure you want to delete this item?';
  static const String confirmDeleteDevice =
      'Are you sure you want to delete this device?';
  static const String confirmCommission =
      'Are you sure you want to commission this device?';
  static const String confirmDecommission =
      'Are you sure you want to decommission this device?';
  static const String confirmUnsavedChanges =
      'You have unsaved changes. Are you sure you want to leave?';

  // === Info Messages ===
  static const String noDataAvailable = 'No data available.';
  static const String noDevicesFound = 'No devices found.';
  static const String noResultsFound = 'No results found for your search.';
  static const String featureComingSoon = 'This feature is coming soon.';
  static const String dataUpToDate = 'Data is up to date.';

  // === API Error Code Mappings ===
  static const Map<String, String> apiErrorMessages = {
    // HTTP Status Codes
    '400': validationError,
    '401': unauthorizedError,
    '403': forbiddenError,
    '404': notFoundError,
    '409': conflictError,
    '429': tooManyRequestsError,
    '500': serverError,
    '502': serverError,
    '503': serverError,
    '504': timeoutError,

    // Custom API Error Codes
    'DEVICE_NOT_FOUND': deviceNotFound,
    'DEVICE_ALREADY_EXISTS': deviceAlreadyExists,
    'DEVICE_COMMISSION_FAILED': deviceCommissionFailed,
    'DEVICE_DECOMMISSION_FAILED': deviceDecommissionFailed,
    'DEVICE_UPDATE_FAILED': deviceUpdateFailed,
    'DEVICE_DELETE_FAILED': deviceDeleteFailed,
    'DEVICE_LINK_HES_FAILED': deviceLinkHesFailed,
    'DEVICE_PING_FAILED': devicePingFailed,
    'DEVICE_INVALID_STATUS': deviceInvalidStatus,
    'DEVICE_LOCATION_UPDATE_FAILED': deviceLocationUpdateFailed,

    'INVALID_CREDENTIALS': loginFailed,
    'SESSION_EXPIRED': sessionExpired,
    'TOKEN_INVALID': tokenInvalid,
    'TOKEN_EXPIRED': tokenExpired,
    'REFRESH_TOKEN_FAILED': refreshTokenFailed,

    'VALIDATION_ERROR': validationError,
    'REQUIRED_FIELD': requiredField,
    'INVALID_EMAIL': invalidEmail,
    'INVALID_SERIAL_NUMBER': invalidSerialNumber,
    'INVALID_COORDINATES': invalidCoordinates,
    'INVALID_DATE_RANGE': invalidDateRange,

    'NETWORK_ERROR': networkError,
    'TIMEOUT_ERROR': timeoutError,
    'SERVER_ERROR': serverError,
  };

  // === Common Error Patterns ===
  static const Map<String, String> errorPatterns = {
    'connection': networkError,
    'timeout': timeoutError,
    'unauthorized': unauthorizedError,
    'forbidden': forbiddenError,
    'not found': notFoundError,
    'validation': validationError,
    'conflict': conflictError,
    'server error': serverError,
    'bad request': validationError,
    'internal server error': serverError,
    'service unavailable': serverError,
    'gateway timeout': timeoutError,
  };
}
