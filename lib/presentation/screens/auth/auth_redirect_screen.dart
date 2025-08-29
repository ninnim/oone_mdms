import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mdms_clone/presentation/widgets/common/app_toast.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../../core/services/keycloak_service.dart';
import 'dart:html' as html;

class SimpleAuthRedirectScreen extends StatefulWidget {
  const SimpleAuthRedirectScreen({super.key});

  @override
  State<SimpleAuthRedirectScreen> createState() =>
      _SimpleAuthRedirectScreenState();
}

class _SimpleAuthRedirectScreenState extends State<SimpleAuthRedirectScreen>
    with TickerProviderStateMixin {
  late AnimationController _dotAnimationController;
  late AnimationController _pulseController;
  Offset _mousePosition = const Offset(0, 0);
  bool _showAccessDialog = false;
  String? _userAccessMessage;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _dotAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndRedirect();
    });
  }

  @override
  void dispose() {
    _dotAnimationController.dispose();
    _pulseController.dispose();
    super.dispose();
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



      if (error != null) {
       
        if (mounted) {
          AppToast.showError(context, error: 'Authentication error: $error');
        }
        return;
      }

      if (code != null) {
        if (kDebugMode) {
          print('SimpleAuthRedirectScreen: Processing authorization code...');
        }
        final success = await keycloakService.handleCallback(code);

        if (success && keycloakService.isAuthenticated) {
         

          // Verify MDMS access from token
          final hasAccess = await _verifyMDMSAccess(keycloakService);

          if (!hasAccess) {
            // Show access denied dialog
            setState(() {
              _showAccessDialog = true;
            });
            return;
          }

          // Clean the URL by replacing the current history state
          try {
            final cleanUrl = '${html.window.location.origin}';
            html.window.history.replaceState(null, '', cleanUrl);
            
          } catch (e) {
            if (kDebugMode) {
              print('SimpleAuthRedirectScreen: Error cleaning URL: $e');
            }
          }

          // Navigate to dashboard using GoRouter
          if (mounted) {
            context.go('/dashboard');
          }
          return;
        } else {
         
          if (mounted) {
            AppToast.showError(
              context,
              error: 'Authentication failed. Please try again.',
            );
          }
          return;
        }
      }

      // No code present, check if already authenticated
      if (keycloakService.isAuthenticated) {
       

        // Verify MDMS access for existing authentication
        final hasAccess = await _verifyMDMSAccess(keycloakService);

        if (!hasAccess) {
          setState(() {
            _showAccessDialog = true;
          });
          return;
        }

        if (mounted) {
          context.go('/dashboard');
        }
        return;
      }

      // Not authenticated and no code, initiate OAuth flow
      
      await keycloakService.login();
    } catch (e) {
      if (kDebugMode) {
        print('SimpleAuthRedirectScreen: Error: $e');
      }
      if (mounted) {
        AppToast.showError(
          context,
          error: 'Authentication error: Please try again.',
        );
      }
    }
  }

  /// Verify if user has MDMS access from the token
  Future<bool> _verifyMDMSAccess(KeycloakService keycloakService) async {
    try {
      final accessToken = keycloakService.accessToken;
      if (accessToken == null) {
        
        return false;
      }

      // Decode the JWT token
      final decodedToken = JwtDecoder.decode(accessToken);
      

      // Check if 'active_org' field exists and contains 'mdms'
      final activeOrg = decodedToken['active_org'];
      if (activeOrg == null) {
        if (kDebugMode) {
          print('SimpleAuthRedirectScreen: No active_org found in token');
        }
        _userAccessMessage =
            'No organization information found in your account.';
        return false;
      }

      final activeOrgString = activeOrg.toString().toLowerCase();
    

      // Check if MDMS is mentioned in the active_org
      if (!activeOrgString.contains('mdms')) {
       
        _userAccessMessage = 'Your account is not activated for MDMS system.';
        return false;
      }

      
      return true;
    } catch (e) {
    
      _userAccessMessage = 'Unable to verify account permissions.';
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MouseRegion(
        onHover: (event) {
          setState(() {
            _mousePosition = event.localPosition;
          });
        },
        child: Stack(
          children: [
            // Animated Dot Background
            AnimatedBuilder(
              animation: _dotAnimationController,
              builder: (context, child) {
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        Theme.of(
                          context,
                        ).colorScheme.secondary.withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: CustomPaint(
                    size: Size(
                      MediaQuery.of(context).size.width,
                      MediaQuery.of(context).size.height,
                    ),
                    painter: DotPatternPainter(
                      animation: _dotAnimationController,
                      mousePosition: _mousePosition,
                    ),
                  ),
                );
              },
            ),

            // Main Content
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // MDMS Logo/Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.dashboard_rounded,
                          size: 40,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Title
                      Text(
                        'MDMS',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),

                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        'Master Data Management System',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Loading Indicator
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Loading Text
                      Text(
                        'Authenticating...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Access Denied Dialog
            if (_showAccessDialog)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Container(
                      margin: const EdgeInsets.all(32),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Error Icon
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: Icon(
                              Icons.block_rounded,
                              size: 32,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Title
                          Text(
                            'Access Not Activated',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                          ),

                          const SizedBox(height: 16),

                          // Message
                          Text(
                            (_userAccessMessage?.isNotEmpty ?? false)
                                ? _userAccessMessage!
                                : 'Your account is not activated for MDMS system. Please contact your administrator or activate your account.',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.8),
                                ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 32),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _showAccessDialog = false;
                                    });
                                    // Logout and go back to login
                                    final keycloakService =
                                        Provider.of<KeycloakService>(
                                          context,
                                          listen: false,
                                        );
                                    keycloakService.logout();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    side: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                                  ),
                                  child: const Text('Back to Login'),
                                ),
                              ),

                              const SizedBox(width: 16),

                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _showAccessDialog = false;
                                    });
                                    // Redirect to external activation platform
                                    html.window.open(
                                      'https://onboard.oone.bz',
                                      '_self',
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    foregroundColor: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                  ),
                                  child: const Text('Activate Account'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for animated dot pattern background
class DotPatternPainter extends CustomPainter {
  final Animation<double> animation;
  final Offset? mousePosition;

  DotPatternPainter({required this.animation, this.mousePosition});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    const dotSize = 2.0;
    const spacing = 40.0;

    // Calculate dots in a grid pattern
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        // Add animation offset
        final animatedOffset = Offset(
          x + (animation.value * 20) % spacing,
          y + (animation.value * 15) % spacing,
        );

        // Calculate distance from mouse for interactive effect
        double opacity = 0.1;
        if (mousePosition != null) {
          final distance = (animatedOffset - mousePosition!).distance;
          if (distance < 100) {
            opacity = (1 - distance / 100) * 0.5;
          }
        }

        paint.color = Colors.white.withOpacity(opacity + 0.05);

        canvas.drawCircle(animatedOffset, dotSize + (opacity * 2), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
