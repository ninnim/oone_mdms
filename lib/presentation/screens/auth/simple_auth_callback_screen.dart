import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:html' as html;
import '../../../core/services/keycloak_service.dart';

class SimpleAuthCallbackScreen extends StatefulWidget {
  @override
  _SimpleAuthCallbackScreenState createState() =>
      _SimpleAuthCallbackScreenState();
}

class _SimpleAuthCallbackScreenState extends State<SimpleAuthCallbackScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleCallback();
    });
  }

  Future<void> _handleCallback() async {
    try {
      // Get current URL and extract query parameters
      final currentUrl = html.window.location.href;
      final uri = Uri.parse(currentUrl);
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];

      print('Callback URL: $currentUrl');
      print('Authorization code: $code');
      print('Error: $error');

      if (error != null) {
        print('OAuth error: $error');
        if (mounted) {
          context.go('/auth');
        }
        return;
      }

      if (code == null) {
        print('No authorization code found');
        if (mounted) {
          context.go('/auth');
        }
        return;
      }

      // Get the KeycloakService and handle the callback
      final keycloakService = Provider.of<KeycloakService>(
        context,
        listen: false,
      );
      final success = await keycloakService.handleCallback(code);

      if (success) {
        print('OAuth callback processed successfully');

        // Clean the URL by replacing the current history state
        // This removes the callback parameters from the browser's address bar
        try {
          final cleanUrl = '${html.window.location.origin}/dashboard';
          html.window.history.replaceState(null, '', cleanUrl);
          print('Callback: URL cleaned to: $cleanUrl');
        } catch (e) {
          print('Callback: Error cleaning URL: $e');
        }

        // Redirect to dashboard
        if (mounted) {
          context.go('/dashboard');
        }
      } else {
        print('OAuth callback processing failed');
        if (mounted) {
          context.go('/auth');
        }
      }
    } catch (e) {
      print('Error processing OAuth callback: $e');
      if (mounted) {
        context.go('/auth');
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
              const Color(0xFF2563eb),
              const Color(0xFF2563eb).withOpacity(0.8),
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Processing authentication...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
