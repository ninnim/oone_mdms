import 'package:flutter/material.dart';
import 'package:mdms_clone/core/constants/app_colors.dart';
import 'package:mdms_clone/presentation/widgets/common/app_lottie_state_widget.dart';
import 'package:mdms_clone/presentation/widgets/common/app_toast.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/keycloak_service.dart';
import 'dart:html' as html;

class SimpleAuthRedirectScreen extends StatefulWidget {
  const SimpleAuthRedirectScreen({super.key});

  @override
  State<SimpleAuthRedirectScreen> createState() =>
      _SimpleAuthRedirectScreenState();
}

class _SimpleAuthRedirectScreenState extends State<SimpleAuthRedirectScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndRedirect();
    });
  }

  Future<void> _checkAuthAndRedirect() async {
    try {
      final keycloakService = Provider.of<KeycloakService>(
        context,
        listen: false,
      );

      // Check if we have an authorization code in the URL (callback scenario)
      final uri = Uri.parse(html.window.location.href);
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];

      print('SimpleAuthRedirectScreen: Current URL: ${uri.toString()}');
      print('SimpleAuthRedirectScreen: Code: $code, Error: $error');

      if (error != null) {
        print('SimpleAuthRedirectScreen: OAuth error: $error');
        if (mounted) {
          AppToast.showError(context, error: 'Authentication error: $error');
        }
        return;
      }

      if (code != null) {
        print('SimpleAuthRedirectScreen: Processing authorization code...');
        final success = await keycloakService.handleCallback(code);

        if (success && keycloakService.isAuthenticated) {
          print(
            'SimpleAuthRedirectScreen: Authentication successful, cleaning URL and redirecting to dashboard...',
          );

          // Clean the URL by replacing the current history state
          // This removes the callback parameters from the browser's address bar
          try {
            final cleanUrl = '${html.window.location.origin}';
            html.window.history.replaceState(null, '', cleanUrl);
            print('SimpleAuthRedirectScreen: URL cleaned to: $cleanUrl');
          } catch (e) {
            print('SimpleAuthRedirectScreen: Error cleaning URL: $e');
          }

          // Navigate to dashboard using GoRouter
          if (mounted) {
            context.go('/dashboard');
          }
          return;
        } else {
          print(
            'SimpleAuthRedirectScreen: Authentication failed after callback',
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Authentication failed'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      // No code present, check if already authenticated
      if (keycloakService.isAuthenticated) {
        print(
          'SimpleAuthRedirectScreen: Already authenticated, redirecting to dashboard...',
        );
        if (mounted) {
          context.go('/dashboard');
        }
        return;
      }

      // Not authenticated and no code, initiate OAuth flow
      print('SimpleAuthRedirectScreen: Starting OAuth flow...');
      await keycloakService.login();
    } catch (e) {
      print('SimpleAuthRedirectScreen: Error: $e');
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
      body: AppLottieStateWidget.loading(
        title: 'Loading Authentication',
        message: 'Please wait while we authenticate you.',
        lottieSize: 100,
        titleColor: AppColors.primary,
        messageColor: AppColors.secondary,
      ),
      // Container(
      //   width: double.infinity,
      //   height: double.infinity,
      //   decoration: BoxDecoration(
      //     gradient: LinearGradient(
      //       begin: Alignment.topLeft,
      //       end: Alignment.bottomRight,
      //       colors: [
      //         const Color(0xFF2563eb),
      //         const Color(0xFF2563eb).withOpacity(0.8),
      //       ],
      //     ),
      //   ),
      //   child: const Center(
      //     child: Column(
      //       mainAxisAlignment: MainAxisAlignment.center,
      //       children: [
      //         Icon(Icons.security_rounded, size: 80, color: Colors.white),
      //         SizedBox(height: 32),
      //         CircularProgressIndicator(
      //           valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      //           strokeWidth: 3,
      //         ),
      //         SizedBox(height: 32),
      //         Text(
      //           'Connecting to authentication service...',
      //           style: TextStyle(
      //             color: Colors.white,
      //             fontSize: 18,
      //             fontWeight: FontWeight.w600,
      //           ),
      //         ),
      //         SizedBox(height: 16),
      //         Text(
      //           'Please wait while we process your authentication.',
      //           style: TextStyle(color: Colors.white70, fontSize: 14),
      //           textAlign: TextAlign.center,
      //         ),
      //       ],
      //     ),
      //   ),
      // ),
    );
  }
}
