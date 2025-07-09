import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

enum AppButtonType { primary, secondary, outline, text, danger }

enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final AppButtonSize size;
  final bool isLoading;
  final Widget? icon;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: _getHeight(),
      child: _buildButton(),
    );
  }

  double _getHeight() {
    switch (size) {
      case AppButtonSize.small:
        return 36;
      case AppButtonSize.medium:
        return AppSizes.buttonHeight;
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

  Widget _buildButton() {
    final content = _buildContent();

    switch (type) {
      case AppButtonType.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textInverse,
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
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.textInverse,
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
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.border),
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
            foregroundColor: AppColors.primary,
            padding: _getPadding(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
          ),
          child: content,
        );

      case AppButtonType.danger:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.textInverse,
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
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.textInverse),
        ),
      );
    }

    final textWidget = Text(
      text,
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
