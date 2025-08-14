class ApiConstants {
  // Base URL
  static const String baseUrl = 'https://mdms.oone.bz';

  // Headers
  static const String tokenHeader =
      '4)-g\$xR&M0siAov3Fl4O'; // x-hasura-admin-secret
  static const String contentType = 'application/json';
  static const String authorization = 'Bearer ';
  static const String accept = 'application/json';
  static const String tenant = 'x-hasura-tenant';
  static const String user = 'x-hasura-user';
  static const String role = 'x-hasura-role';
  static const String allowedRoles = 'x-hasura-allowed-roles';

  // Default header values (used as fallbacks when token parsing fails)
  static const String defaultTenant =
      '025aa4a1-8617-4e24-b890-2e69a09180ee'; // Updated from your token
  static const String defaultUser = 'admin';
  static const String defaultRole = 'super-admin';

  // Endpoints
  static const String devices = '/api/rest/Device';
  static const String deviceGroups = '/api/rest/v1/DeviceGroup';
  static const String deviceFilter = '/api/rest/v1/Device/Filter';
  static const String deviceMetrics = '/core/api/rest/v1/Device/Metric';
  static const String deviceBilling = '/api/rest/v1/Device/{id}/Billing';
  static const String deviceBillingReadings =
      '/api/rest/v1/Device/{id}/BillingReadings';
  static const String linkHes = '/core/api/rest/v1/Device/LinkHes';
  static const String pingDevice = '/api/rest/v1/Device/{id}/Ping';
  static const String commissionDevice = '/api/rest/v1/Device/{id}/Commission';

  // Schedules (placeholder - implement when schedule_spec.json is provided)
  static const String schedules = '/api/rest/v1/Schedule';

  // Location/Maps
  static const String googleApi = '/esb/googleapi';
  static const String googleApiDetail = '/esb/googleapi/detail';
  static const String googleApiGeocode = '/esb/googleapi/geocode';

  // Pagination
  static const int defaultLimit = 25;
  static const int defaultOffset = 0;

  // Search
  static const String defaultSearch = '%%';
}
