# Dynamic Token and Header Management System

## Overview

This system provides automatic, dynamic extraction and management of JWT tokens for API headers, ensuring all API requests include the correct tenant, roles, and authorization information with automatic token refresh capabilities.

## Architecture

### Core Components

1. **TokenManagementService**: Extracts and manages token data, handles role selection, and schedules auto-refresh
2. **KeycloakService**: Handles OAuth2 authentication and token refresh
3. **ApiService**: Intercepts HTTP requests and injects dynamic headers
4. **ServiceLocator**: Manages service dependencies and initialization

## Features

### 1. Dynamic Header Extraction
- **x-hasura-tenant**: Extracted from JWT token fields (`tenant`, `hasura.tenant`, `x-hasura-tenant`)
- **x-hasura-allowed-roles**: Extracted from JWT token fields (`allowed_roles`, `hasura.allowed_roles`, `realm_access.roles`)
- **x-hasura-role**: Last selected role or highest priority role
- **Authorization**: Bearer token from Keycloak

### 2. Auto Token Refresh
- Monitors token expiry and schedules refresh 1 minute before expiration
- Handles refresh failures gracefully with fallback mechanisms
- Updates cached token data automatically

### 3. Role Management
- Extracts all allowed roles from token
- Remembers last selected role across sessions
- Provides role selection interface for users

### 4. Error Handling
- Graceful degradation when token parsing fails
- Fallback to Keycloak-only authorization when needed
- User-friendly error messages via toast notifications

## Usage

### 1. Initialize Services

```dart
// Initialize all services at app startup
final serviceLocator = ServiceLocator();
await serviceLocator.initialize();

// Services are now ready for use
final apiService = serviceLocator.apiService;
final tokenService = serviceLocator.tokenManagementService;
```

### 2. Make API Calls

```dart
// All API calls automatically include dynamic headers
final response = await apiService.get('/api/rest/Device');

// Headers are automatically set:
// - x-hasura-tenant: [extracted from token]
// - x-hasura-allowed-roles: [extracted from token]
// - x-hasura-role: [selected or highest priority role]
// - Authorization: Bearer [token]
```

### 3. Monitor Token Status

```dart
// Listen to token changes
tokenService.addListener(() {
  print('Token updated: ${tokenService.currentTenant}');
  print('Available roles: ${tokenService.allowedRoles}');
  print('Selected role: ${tokenService.selectedRole}');
});
```

### 4. Handle Role Changes

```dart
// Change selected role
await tokenService.setSelectedRole('admin');

// Get current headers for debugging
final headers = await tokenService.getApiHeaders();
print('Current headers: $headers');
```

### 5. Manual Token Refresh

```dart
// Force token refresh
final success = await keycloakService.refreshToken();
if (success) {
  print('Token refreshed successfully');
}
```

## Token Data Flow

```
1. User authenticates via Keycloak
   ↓
2. JWT token stored securely
   ↓
3. TokenManagementService extracts:
   - Tenant ID
   - Allowed roles
   - Token expiry
   ↓
4. Auto-refresh scheduled
   ↓
5. ApiService intercepts requests
   ↓
6. Dynamic headers added to all API calls
   ↓
7. API receives properly formatted headers
```

## Header Priority

The system tries multiple fields to extract data, using the first available:

### Tenant Extraction
1. `tenant`
2. `hasura.tenant`
3. `x-hasura-tenant`

### Role Extraction
1. `allowed_roles`
2. `hasura.allowed_roles`
3. `realm_access.roles`

### Selected Role Priority
1. Last user-selected role (stored in preferences)
2. Role with highest priority index in allowed_roles array
3. First role in the array

## Configuration

### API Constants

```dart
// Header keys
static const String tenant = 'x-hasura-tenant';
static const String allowedRoles = 'x-hasura-allowed-roles';
static const String role = 'x-hasura-role';
static const String user = 'x-hasura-user';
static const String tokenHeader = 'Authorization';

// Default values (fallback)
static const String defaultTenant = '0a12968d-2a38-48ee-b60a-ce2498040825';
static const String defaultRole = 'super-admin';
static const String defaultUser = 'admin';
```

### JWT Token Fields

The system looks for these fields in JWT tokens:

```json
{
  "tenant": "tenant-id",
  "allowed_roles": ["admin", "user"],
  "hasura": {
    "tenant": "tenant-id",
    "allowed_roles": ["admin", "user"]
  },
  "realm_access": {
    "roles": ["admin", "user"]
  },
  "exp": 1625097600
}
```

## Error Scenarios

### 1. Token Parsing Fails
- Falls back to Keycloak authorization only
- Uses default tenant and role values
- Logs error for debugging

### 2. Token Refresh Fails
- Continues with current token until manual refresh
- Shows user-friendly error message
- Maintains service availability

### 3. Role Selection Fails
- Uses first available role as fallback
- Maintains last valid selection
- Allows manual role switching

## Testing

Use `TokenManagementTestScreen` to verify:

1. Service initialization
2. Token extraction accuracy
3. Header generation
4. Role selection functionality
5. Auto-refresh behavior
6. API call integration

## Best Practices

1. **Initialize Early**: Call `ServiceLocator().initialize()` in main app startup
2. **Handle Errors**: Always wrap API calls in try-catch blocks
3. **Monitor Changes**: Listen to TokenManagementService for real-time updates
4. **Test Thoroughly**: Use test screen to verify token behavior
5. **Log Debugging**: Enable debug prints for troubleshooting
6. **Secure Storage**: All tokens are stored using flutter_secure_storage

## Security Considerations

1. **Token Storage**: Uses secure storage for all sensitive data
2. **Auto-Refresh**: Minimizes token exposure time
3. **Validation**: Validates token structure before extraction
4. **Fallback**: Graceful degradation when security fails
5. **Logging**: No sensitive data in production logs

## Migration Guide

### From Static Headers

**Before:**
```dart
// Static headers in ApiService
headers: {
  'x-hasura-tenant': 'static-tenant',
  'x-hasura-role': 'static-role',
}
```

**After:**
```dart
// Initialize services
await ServiceLocator().initialize();

// Use dynamic headers automatically
final response = await apiService.get('/api/endpoint');
```

### Existing API Calls

No changes needed! All existing API calls will automatically use dynamic headers once services are initialized.

## Troubleshooting

### Headers Not Updated
1. Check service initialization: `ServiceLocator().isInitialized`
2. Verify token validity: `keycloakService.isAuthenticated`
3. Check debug logs for extraction errors
4. Use test screen to verify header generation

### Token Refresh Issues
1. Verify Keycloak configuration
2. Check refresh token validity
3. Review network connectivity
4. Check token endpoint configuration

### Role Selection Problems
1. Verify JWT token contains role fields
2. Check allowed_roles array structure
3. Ensure role exists in token data
4. Use test screen to debug role extraction

## Performance Impact

- **Minimal**: Headers cached until token changes
- **Efficient**: Only parses token when updated
- **Optimized**: Background refresh scheduling
- **Lightweight**: Minimal memory footprint
