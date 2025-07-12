import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/keycloak_service.dart';

class AuthRedirectScreen extends StatefulWidget {
  const AuthRedirectScreen({Key? key}) : super(key: key);

  @override
  State<AuthRedirectScreen> createState() => _AuthRedirectScreenState();
}

class _AuthRedirectScreenState extends State<AuthRedirectScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirectToKeycloak();
    });
  }

  Future<void> _redirectToKeycloak() async {
    try {
      final keycloakService = Provider.of<KeycloakService>(
        context,
        listen: false,
      );
      await keycloakService.login();
    } catch (e) {
      print('Error redirecting to Keycloak: $e');
      // Handle error - could show an error dialog or redirect to error page
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo or Icon
              Icon(Icons.security_rounded, size: 80, color: Colors.white),
              const SizedBox(height: 32),

              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
              const SizedBox(height: 32),

              // Loading text
              Text(
                'Redirecting to authentication...',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Please wait while we redirect you to the login page.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
