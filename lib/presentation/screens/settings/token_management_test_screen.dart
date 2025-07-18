import 'package:flutter/material.dart';
import 'package:mdms_clone/core/services/service_locator.dart';
import 'package:mdms_clone/presentation/widgets/common/app_button.dart';
import 'package:mdms_clone/presentation/widgets/common/app_toast.dart';
import 'package:mdms_clone/presentation/widgets/common/app_lottie_state_widget.dart';

/// Demo screen to test dynamic token and header management
class TokenManagementTestScreen extends StatefulWidget {
  const TokenManagementTestScreen({super.key});

  @override
  State<TokenManagementTestScreen> createState() =>
      _TokenManagementTestScreenState();
}

class _TokenManagementTestScreenState extends State<TokenManagementTestScreen> {
  final ServiceLocator _serviceLocator = ServiceLocator();

  Map<String, String>? _currentHeaders;
  String? _currentTenant;
  List<String>? _allowedRoles;
  String? _selectedRole;
  String? _tokenExpiry;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    setState(() => _isLoading = true);

    try {
      await _serviceLocator.initialize();

      // Listen to token management changes
      _serviceLocator.tokenManagementService.addListener(_updateTokenInfo);

      await _updateTokenInfo();

      AppToast.showSuccess(
        context,
        message: 'Services initialized successfully!',
      );
    } catch (e) {
      AppToast.showError(context, error: 'Failed to initialize services: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTokenInfo() async {
    try {
      final tokenService = _serviceLocator.tokenManagementService;

      final headers = tokenService.getApiHeaders();
      final tenant = tokenService.currentTenant;
      final roles = tokenService.allowedRoles;
      final selectedRole = tokenService.currentRole;
      final expiry = tokenService.tokenExpiry;

      setState(() {
        _currentHeaders = headers;
        _currentTenant = tenant;
        _allowedRoles = roles;
        _selectedRole = selectedRole;
        _tokenExpiry = expiry?.toLocal().toString();
      });
    } catch (e) {
      debugPrint('Error updating token info: $e');
    }
  }

  Future<void> _refreshToken() async {
    setState(() => _isLoading = true);

    try {
      final success = await _serviceLocator.keycloakService.refreshToken();

      if (success) {
        await _updateTokenInfo();
        AppToast.showSuccess(context, message: 'Token refreshed successfully!');
      } else {
        AppToast.showError(context, error: 'Failed to refresh token');
      }
    } catch (e) {
      AppToast.showError(context, error: 'Error refreshing token: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectRole(String? role) async {
    if (role == null) return;

    try {
      _serviceLocator.tokenManagementService.setRole(role);
      await _updateTokenInfo();
      AppToast.showSuccess(context, message: 'Role changed to: $role');
    } catch (e) {
      AppToast.showError(context, error: 'Error changing role: $e');
    }
  }

  Future<void> _testApiCall() async {
    setState(() => _isLoading = true);

    try {
      final response = await _serviceLocator.apiService.get('/api/rest/Device');

      AppToast.showSuccess(
        context,
        message: 'API call successful! Status: ${response.statusCode}',
      );
    } catch (e) {
      AppToast.showError(context, error: 'API call failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _serviceLocator.tokenManagementService.removeListener(_updateTokenInfo);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Token Management Test'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildServiceStatus(),
                  const SizedBox(height: 24),
                  _buildTokenInfo(),
                  const SizedBox(height: 24),
                  _buildRoleSelector(),
                  const SizedBox(height: 24),
                  _buildCurrentHeaders(),
                  const SizedBox(height: 24),
                  _buildActions(),
                ],
              ),
            ),
    );
  }

  Widget _buildServiceStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service Status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _serviceLocator.isInitialized
                      ? Icons.check_circle
                      : Icons.error,
                  color: _serviceLocator.isInitialized
                      ? Colors.green
                      : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  _serviceLocator.isInitialized
                      ? 'All services initialized'
                      : 'Services not initialized',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _serviceLocator.keycloakService.isAuthenticated
                      ? Icons.check_circle
                      : Icons.error,
                  color: _serviceLocator.keycloakService.isAuthenticated
                      ? Colors.green
                      : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  _serviceLocator.keycloakService.isAuthenticated
                      ? 'User authenticated'
                      : 'User not authenticated',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Token Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Current Tenant', _currentTenant ?? 'Not available'),
            _buildInfoRow('Selected Role', _selectedRole ?? 'Not selected'),
            _buildInfoRow('Token Expires', _tokenExpiry ?? 'Not available'),
            _buildInfoRow(
              'Available Roles',
              _allowedRoles?.join(', ') ?? 'None',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    if (_allowedRoles == null || _allowedRoles!.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Role Selection',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text('No roles available'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Role Selection',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Select Role',
                border: OutlineInputBorder(),
              ),
              items: _allowedRoles!.map((role) {
                return DropdownMenuItem(value: role, child: Text(role));
              }).toList(),
              onChanged: _selectRole,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentHeaders() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current API Headers',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (_currentHeaders == null || _currentHeaders!.isEmpty)
              const Text('No headers available')
            else
              ..._currentHeaders!.entries.map((entry) {
                return _buildInfoRow(entry.key, entry.value);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Actions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Refresh Token',
                    onPressed: _refreshToken,
                    isLoading: _isLoading,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppButton(
                    text: 'Test API Call',
                    onPressed: _testApiCall,
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: 'Update Token Info',
                onPressed: _updateTokenInfo,
                isLoading: _isLoading,
                type: AppButtonType.secondary,
                ////   variant: AppButtonVariant.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }
}
