import 'package:flutter/material.dart';
// import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/error_translation_service.dart';
import '../../themes/app_theme.dart';

enum ToastType { success, warning, error, info }

class ToastData {
  final String title;
  final String message;
  final ToastType type;
  final Duration duration;

  ToastData({
    required this.title,
    required this.message,
    required this.type,
    this.duration = const Duration(seconds: 4),
  });
}

class AppToast {
  static OverlayEntry? _currentToast;

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    required ToastType type,
    Duration duration = const Duration(seconds: 4),
  }) {
    // Remove existing toast if any
    _safeRemoveCurrentToast();

    final overlay = Overlay.of(context);
    final toastData = ToastData(
      title: title,
      message: message,
      type: type,
      duration: duration,
    );

    _currentToast = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + AppSizes.spacing16,
        right: AppSizes.spacing16,
        child: ToastWidget(
          data: toastData,
          onDismiss: () {
            _safeRemoveCurrentToast();
          },
        ),
      ),
    );

    overlay.insert(_currentToast!);

    // Auto-remove after duration
    Future.delayed(duration, () {
      _safeRemoveCurrentToast();
    });
  }

  /// Safely removes the current toast and cleans up the reference
  static void _safeRemoveCurrentToast() {
    if (_currentToast != null) {
      try {
        if (_currentToast!.mounted) {
          _currentToast!.remove();
        }
      } catch (e) {
        // Ignore errors if the overlay is already removed
      } finally {
        _currentToast = null;
      }
    }
  }

  /// Check if a toast is currently showing
  static bool get isShowing => _currentToast != null && _currentToast!.mounted;

  /// Force show a new toast even if one is already showing
  static void forceShow(
    BuildContext context, {
    required String title,
    required String message,
    required ToastType type,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      title: title,
      message: message,
      type: type,
      duration: duration,
    );
  }

  /// Shows a success toast with a friendly message
  static void showSuccess(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      title: title ?? 'Success',
      message: message,
      type: ToastType.success,
      duration: duration,
    );
  }

  /// Shows an error toast with user-friendly translated message
  static void showError(
    BuildContext context, {
    required dynamic error,
    String? title,
    String? errorContext,
    Duration duration = const Duration(seconds: 5),
  }) {
    final userFriendlyMessage = ErrorTranslationService.translateError(
      error,
      context: errorContext,
    );

    show(
      context,
      title: title ?? 'Error',
      message: userFriendlyMessage,
      type: ToastType.error,
      duration: duration,
    );
  }

  /// Shows a warning toast
  static void showWarning(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      title: title ?? 'Warning',
      message: message,
      type: ToastType.warning,
      duration: duration,
    );
  }

  /// Shows an info toast
  static void showInfo(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      title: title ?? 'Info',
      message: message,
      type: ToastType.info,
      duration: duration,
    );
  }

  static void dismiss() {
    _safeRemoveCurrentToast();
  }
}

class ToastWidget extends StatefulWidget {
  final ToastData data;
  final VoidCallback onDismiss;

  const ToastWidget({super.key, required this.data, required this.onDismiss});

  @override
  State<ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<ToastWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _progressController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    // Slide animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    // Progress animation
    _progressController = AnimationController(
      duration: widget.data.duration,
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.linear),
    );

    // Start animations
    _slideController.forward();
    _progressController.forward();

    // Auto dismiss when progress completes
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _dismiss() async {
    // Prevent multiple dismissals
    if (!mounted || _slideController.isDismissed) return;

    // Stop the progress animation
    _progressController.stop();

    try {
      // Animate out
      await _slideController.reverse();

      // Call the dismiss callback if still mounted
      if (mounted) {
        widget.onDismiss();
      }
    } catch (e) {
      // If animation fails, just call dismiss
      if (mounted) {
        widget.onDismiss();
      }
    }
  }

  Color _getBackgroundColor() {
    switch (widget.data.type) {
      case ToastType.success:
        return Theme.of(context).colorScheme.surface;
      case ToastType.warning:
        return Theme.of(context).colorScheme.surface;
      case ToastType.error:
        return Theme.of(context).colorScheme.surface;
      case ToastType.info:
        return Theme.of(context).colorScheme.surface;
    }
  }

  Color _getProgressColor() {
    switch (widget.data.type) {
      case ToastType.success:
        return context.successColor;
      case ToastType.warning:
        return context.warningColor;
      case ToastType.error:
        return Theme.of(context).colorScheme.error;
      case ToastType.info:
        return context.primaryColor;
    }
  }

  Color _getIconColor() {
    switch (widget.data.type) {
      case ToastType.success:
        return context.successColor;
      case ToastType.warning:
        return context.warningColor;
      case ToastType.error:
        return Theme.of(context).colorScheme.error;
      case ToastType.info:
        return context.primaryColor;
    }
  }

  IconData _getIcon() {
    switch (widget.data.type) {
      case ToastType.success:
        return Icons.check_circle;
      case ToastType.warning:
        return Icons.warning;
      case ToastType.error:
        return Icons.error;
      case ToastType.info:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 400,
          margin: const EdgeInsets.only(bottom: AppSizes.spacing8),
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            border: Border.all(
              color: _getProgressColor().withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Content
              Padding(
                padding: const EdgeInsets.all(AppSizes.spacing16),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getIconColor().withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusSmall,
                        ),
                      ),
                      child: Icon(
                        _getIcon(),
                        color: _getIconColor(),
                        size: AppSizes.iconMedium,
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacing12),
                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.data.title,
                            style: TextStyle(
                              fontSize: AppSizes.fontSizeMedium,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: AppSizes.spacing2),
                          Text(
                            widget.data.message,
                            style: TextStyle(
                              fontSize: AppSizes.fontSizeSmall,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Close button
                    GestureDetector(
                      //onTap: dispose,
                      onTap: _dismiss,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface
                              .withValues(alpha: 0.5)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusSmall,
                          ),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Progress bar
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return Container(
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(AppSizes.radiusLarge),
                        bottomRight: Radius.circular(AppSizes.radiusLarge),
                      ),
                    ),
                    child: LinearProgressIndicator(
                      value: _progressAnimation.value,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(),
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(AppSizes.radiusLarge),
                        bottomRight: Radius.circular(AppSizes.radiusLarge),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
