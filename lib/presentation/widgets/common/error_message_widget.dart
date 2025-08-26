import 'package:flutter/material.dart';
// import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/error_translation_service.dart';

/// Widget for displaying user-friendly error messages
class ErrorMessageWidget extends StatelessWidget {
  final dynamic error;
  final String? context;
  final VoidCallback? onRetry;
  final String? retryButtonText;
  final bool showRetryButton;
  final EdgeInsets padding;
  final bool compact;

  const ErrorMessageWidget({
    super.key,
    required this.error,
    this.context,
    this.onRetry,
    this.retryButtonText,
    this.showRetryButton = true,
    this.padding = const EdgeInsets.all(AppSizes.spacing16),
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final userFriendlyMessage = ErrorTranslationService.translateError(
      error,
      context: this.context,
    );

    if (compact) {
      return _buildCompactError(context, colorScheme, userFriendlyMessage);
    }

    return _buildFullError(context, colorScheme, userFriendlyMessage);
  }

  Widget _buildCompactError(
    BuildContext context,
    ColorScheme colorScheme,
    String message,
  ) {
    return Container(
      padding: padding,
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: AppSizes.iconSmall,
          ),
          const SizedBox(width: AppSizes.spacing8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: AppSizes.fontSizeSmall,
              ),
            ),
          ),
          if (showRetryButton && onRetry != null) ...[
            const SizedBox(width: AppSizes.spacing8),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacing8,
                ),
              ),
              child: Text(
                retryButtonText ?? 'Retry',
                style: const TextStyle(fontSize: AppSizes.fontSizeSmall),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFullError(
    BuildContext context,
    ColorScheme colorScheme,
    String message,
  ) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
                size: AppSizes.iconMedium,
              ),
              const SizedBox(width: AppSizes.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Error',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: AppSizes.fontSizeMedium,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacing4),
                    Text(
                      message,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: AppSizes.fontSizeSmall,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showRetryButton && onRetry != null) ...[
            const SizedBox(height: AppSizes.spacing16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: AppSizes.iconSmall),
                label: Text(retryButtonText ?? 'Try Again'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSizes.spacing12,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Snackbar helper for showing error messages
class ErrorSnackBar {
  static void show(
    BuildContext context,
    dynamic error, {
    String? errorContext,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    final userFriendlyMessage = ErrorTranslationService.translateError(
      error,
      context: errorContext,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white,
              size: AppSizes.iconSmall,
            ),
            const SizedBox(width: AppSizes.spacing8),
            Expanded(
              child: Text(
                userFriendlyMessage,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSizes.spacing16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
        action: action,
      ),
    );
  }
}

/// Error dialog helper for critical errors
class ErrorDialog {
  static Future<void> show(
    BuildContext context,
    dynamic error, {
    String? title,
    String? errorContext,
    String? actionText,
    VoidCallback? onAction,
  }) {
    final userFriendlyMessage = ErrorTranslationService.translateError(
      error,
      context: errorContext,
    );

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: AppSizes.iconMedium,
            ),
            const SizedBox(width: AppSizes.spacing8),
            Text(
              title ?? 'Error',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: AppSizes.fontSizeLarge,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          userFriendlyMessage,
          style: TextStyle(fontSize: AppSizes.fontSizeMedium, height: 1.4),
        ),
        actions: [
          if (onAction != null && actionText != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onAction();
              },
              child: Text(actionText),
            ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
