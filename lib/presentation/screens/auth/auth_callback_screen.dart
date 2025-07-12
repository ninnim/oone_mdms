import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/keycloak_service.dart';

class AuthCallbackScreen extends StatefulWidget {
  final String? code;
  final String? state;
  final String? error;

  const AuthCallbackScreen({Key? key, this.code, this.state, this.error})
    : super(key: key);

  @override
  State<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends State<AuthCallbackScreen> {
  bool _isProcessing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleCallback();
    });
  }

  Future<void> _handleCallback() async {
    try {
      // Check for error first
      if (widget.error != null) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Authentication failed: ${widget.error}';
        });
        return;
      }

      // Check for authorization code
      if (widget.code == null) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'No authorization code received';
        });
        return;
      }

      final keycloakService = Provider.of<KeycloakService>(
        context,
        listen: false,
      );

      // Handle the OAuth callback
      await keycloakService.handleCallback(widget.code!);

      // If we get here, authentication was successful
      if (mounted) {
        // Redirect to dashboard
        context.go('/dashboard');
      }
    } catch (e) {
      print('Error handling OAuth callback: $e');
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Authentication failed: $e';
      });
    }
  }

  void _retryAuthentication() {
    context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Icon(
                  _isProcessing
                      ? Icons.sync_rounded
                      : _errorMessage != null
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 32),

                if (_isProcessing) ...[
                  // Loading indicator
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 32),

                  // Loading text
                  Text(
                    'Processing authentication...',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Please wait while we complete your login.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ] else if (_errorMessage != null) ...[
                  // Error message
                  Text(
                    'Authentication Failed',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    _errorMessage!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Retry button
                  ElevatedButton(
                    onPressed: _retryAuthentication,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Try Again',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
