import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../../themes/app_theme.dart';

enum AppButtonType { primary, secondary, outline, text, danger }

enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  final String? text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final AppButtonSize size;
  final bool isLoading;
  final Widget? icon;
  final bool fullWidth;

  const AppButton({
    super.key,
    this.text,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.small,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: _getHeight(),
      child: _buildButton(context),
    );
  }

  double _getHeight() {
    switch (size) {
      case AppButtonSize.small:
        return AppSizes.buttonHeightSmall;
      case AppButtonSize.medium:
        return AppSizes.buttonHeightSmall;
      case AppButtonSize.large:
        return 52;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppSizes.spacing16,
          vertical: AppSizes.spacing8,
        );
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: AppSizes.spacing24,
          vertical: AppSizes.spacing12,
        );
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppSizes.spacing32,
          vertical: AppSizes.spacing16,
        );
    }
  }

  double _getFontSize() {
    switch (size) {
      case AppButtonSize.small:
        return AppSizes.fontSizeSmall;
      case AppButtonSize.medium:
        return AppSizes.fontSizeMedium;
      case AppButtonSize.large:
        return AppSizes.fontSizeLarge;
    }
  }

  Widget _buildButton(BuildContext context) {
    final content = _buildContent();

    switch (type) {
      case AppButtonType.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.primaryColor, //context.primaryColor,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: _getPadding(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            ),
            elevation: 0,
          ),
          child: content,
        );

      case AppButtonType.secondary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Theme.of(context).colorScheme.onSecondary,
            padding: _getPadding(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            ),
            elevation: 0,
          ),
          child: content,
        );

      case AppButtonType.outline:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: context.primaryColor,
            side: BorderSide(color: context.borderColor),
            padding: _getPadding(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            ),
          ),
          child: content,
        );

      case AppButtonType.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: context.primaryColor,
            padding: _getPadding(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            ),
          ),
          child: content,
        );

      case AppButtonType.danger:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
            padding: _getPadding(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            ),
            elevation: 0,
          ),
          child: content,
        );
    }
  }

  Widget _buildContent() {
    if (isLoading) {
      return SizedBox(
        width: _getFontSize(),
        height: _getFontSize(),
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    final textWidget = Text(
      text ?? '',
      style: TextStyle(fontSize: _getFontSize(), fontWeight: FontWeight.w600),
    );

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon!,
          const SizedBox(width: AppSizes.spacing8),
          textWidget,
        ],
      );
    }

    return textWidget;
  }
}
