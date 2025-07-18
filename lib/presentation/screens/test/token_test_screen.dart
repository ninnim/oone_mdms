import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/token_management_service.dart';
import '../../../core/services/keycloak_service.dart';
import '../../../core/services/device_service.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_lottie_state_widget.dart';

/// Test screen to verify token management and dynamic headers
class TokenTestScreen extends StatefulWidget {
  const TokenTestScreen({super.key});

  @override
  State<TokenTestScreen> createState() => _TokenTestScreenState();
}

class _TokenTestScreenState extends State<TokenTestScreen> {
  String _testResults = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    setState(() {
      _testResults = 'Initializing token test screen...\n';
    });
    _checkTokenStatus();
  }

  void _checkTokenStatus() {
    final tokenService = Provider.of<TokenManagementService>(
      context,
      listen: false,
    );
    final keycloakService = Provider.of<KeycloakService>(
      context,
      listen: false,
    );

    setState(() {
      _testResults += '\n=== TOKEN STATUS ===\n';
      _testResults += 'Is Valid: ${tokenService.isTokenValid}\n';
      _testResults += 'Current Tenant: ${tokenService.currentTenant}\n';
      _testResults += 'Current Role: ${tokenService.currentRole}\n';
      _testResults +=
          'Access Token: ${keycloakService.accessToken?.substring(0, 50) ?? 'null'}...\n';
    });
  }

  Future<void> _testApiCall() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _testResults += '\n=== TESTING API CALL ===\n';
    });

    try {
      final deviceService = Provider.of<DeviceService>(context, listen: false);

      _testResults += 'Making API call to fetch devices...\n';
      final devices = await deviceService.getDevices(offset: 0, limit: 5);

      setState(() {
        _testResults +=
            'SUCCESS: Fetched ${devices.data?.length ?? 0} devices\n';
        if (devices.data?.isNotEmpty == true) {
          _testResults += 'First device: ${devices.data!.first.serialNumber}\n';
        }
      });
    } catch (e) {
      setState(() {
        _testResults += 'ERROR: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testTokenRefresh() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _testResults += '\n=== TESTING TOKEN REFRESH ===\n';
    });

    try {
      final keycloakService = Provider.of<KeycloakService>(
        context,
        listen: false,
      );

      _testResults += 'Requesting token refresh...\n';
      await keycloakService.refreshToken();

      setState(() {
        _testResults += 'SUCCESS: Token refreshed\n';
      });

      // Check status again after refresh
      _checkTokenStatus();
    } catch (e) {
      setState(() {
        _testResults += 'ERROR: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearResults() {
    setState(() {
      _testResults = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Token & Headers Test'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dynamic Token & Header Management Test',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Control buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppButton(
                  text: 'Check Token Status',
                  onPressed: _checkTokenStatus,
                  type: AppButtonType.secondary,
                ),
                AppButton(
                  text: 'Test API Call',
                  onPressed: _testApiCall,
                  isLoading: _isLoading,
                ),
                AppButton(
                  text: 'Test Token Refresh',
                  onPressed: _testTokenRefresh,
                  type: AppButtonType.secondary,
                  isLoading: _isLoading,
                ),
                AppButton(
                  text: 'Clear Results',
                  onPressed: _clearResults,
                  type: AppButtonType.danger,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Results area
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.2),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testResults.isEmpty
                        ? 'No test results yet...'
                        : _testResults,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Status indicators
            Consumer<TokenManagementService>(
              builder: (context, tokenService, child) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          tokenService.isTokenValid
                              ? Icons.check_circle
                              : Icons.error,
                          color: tokenService.isTokenValid
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Token Status: ${tokenService.isTokenValid ? 'Valid' : 'Invalid'}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        Text(
                          'Role: ${tokenService.currentRole}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
