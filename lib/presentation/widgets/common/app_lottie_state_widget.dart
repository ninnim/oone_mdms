import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../themes/app_theme.dart';
import '../../../core/constants/app_sizes.dart';
import 'app_button.dart';

/// A reusable widget for displaying Lottie animations with dynamic content
/// Supports loading, error, coming soon, and no-data states
class AppLottieStateWidget extends StatelessWidget {
  final String lottiePath;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final double? lottieSize;
  final bool isLoading;
  final Color? titleColor;
  final Color? messageColor;

  const AppLottieStateWidget({
    super.key,
    required this.lottiePath,
    required this.title,
    required this.message,
    this.buttonText,
    this.onButtonPressed,
    this.lottieSize,
    this.isLoading = false,
    this.titleColor,
    this.messageColor,
  });

  /// Loading state widget
  const AppLottieStateWidget.loading({
    super.key,
    this.title = 'Loading...',
    this.message = '',
    this.buttonText,
    this.onButtonPressed,
    this.lottieSize,
    this.titleColor,
    this.messageColor,
  }) : lottiePath = 'lib/assets/lottie/Loading.json',
       isLoading = true;

  /// Error/404 state widget
  const AppLottieStateWidget.error({
    super.key,
    this.title = 'Oops! Something went wrong',
    this.message = 'We encountered an error while loading your data.',
    this.buttonText = 'Try Again',
    this.onButtonPressed,
    this.lottieSize,
    this.titleColor,
    this.messageColor,
  }) : lottiePath = 'lib/assets/lottie/error404.json',
       isLoading = true;

  /// Coming soon state widget
  const AppLottieStateWidget.comingSoon({
    super.key,
    this.title = 'Coming Soon',
    this.message =
        'This feature is under development and will be available soon.',
    this.buttonText,
    this.onButtonPressed,
    this.lottieSize,
    this.titleColor,
    this.messageColor,
  }) : lottiePath = 'lib/assets/lottie/Coming-Soon.json',
       isLoading = true;

  /// No data state widget
  const AppLottieStateWidget.noData({
    super.key,
    this.title = '',
    this.message = '',
    this.buttonText = 'Refresh',
    this.onButtonPressed,
    this.lottieSize,
    this.titleColor,
    this.messageColor,
  }) : lottiePath = 'lib/assets/lottie/No-Data.json',
       isLoading = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: EdgeInsets.all(AppSizes.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lottie Animation
            SizedBox(
              width: lottieSize ?? 200,
              height: lottieSize ?? 200,
              child: Lottie.asset(
                lottiePath,
                width: lottieSize ?? 200,
                height: lottieSize ?? 200,
                fit: BoxFit.contain,
                repeat: isLoading,
                animate: true,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback icon if Lottie fails to load
                  return Container(
                    width: lottieSize ?? 200,
                    height: lottieSize ?? 200,
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                    ),
                    child: Icon(
                      _getIconForState(),
                      size: (lottieSize ?? 200) * 0.4,
                      color: context.surfaceColor.withOpacity(0.7),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: AppSizes.spacing24),

            // Title
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: titleColor ?? context.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: AppSizes.spacing16),

            // Message
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: messageColor ?? (context.primaryColor.withOpacity(0.5)),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            // Button (optional)
            if (buttonText != null && onButtonPressed != null) ...[
              SizedBox(height: AppSizes.spacing24),
              AppButton(
                text: buttonText!,
                onPressed: onButtonPressed!,
                type: AppButtonType.primary,
                size: AppButtonSize.medium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIconForState() {
    if (lottiePath.contains('Loading.json')) {
      return Icons.refresh;
    } else if (lottiePath.contains('404') || lottiePath.contains('error')) {
      return Icons.error_outline;
    } else if (lottiePath.contains('Coming Soon.json')) {
      return Icons.schedule;
    } else if (lottiePath.contains('No-Data.json')) {
      return Icons.inbox;
    }
    return Icons.info_outline;
  }
}

/// Extension to provide quick access to common Lottie states
extension AppLottieStateWidgetExtension on AppLottieStateWidget {
  /// Create a centered loading overlay
  static Widget loadingOverlay({
    String? title,
    String? message,
    double? lottieSize,
  }) {
    return Container(
      color: Colors.black54,
      child: AppLottieStateWidget.loading(
        title: title ?? 'Loading...',
        message: message ?? 'Please wait...',
        lottieSize: lottieSize ?? 150,
      ),
    );
  }

  /// Create a simple error dialog content
  static Widget errorDialog({
    String? title,
    String? message,
    String? buttonText,
    VoidCallback? onRetry,
  }) {
    return AppLottieStateWidget.error(
      title: title ?? 'Error',
      message: message ?? 'Something went wrong.',
      buttonText: buttonText ?? 'Retry',
      onButtonPressed: onRetry,
      lottieSize: 120,
    );
  }
}
