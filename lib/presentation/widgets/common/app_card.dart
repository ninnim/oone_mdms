import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../../themes/app_theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final double? elevation;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.elevation,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      elevation: elevation ?? 1,
      color: backgroundColor ?? context.surfaceColor,
      shadowColor: context.textSecondaryColor.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius:
            borderRadius ?? BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppSizes.spacing16),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius:
            borderRadius ?? BorderRadius.circular(AppSizes.radiusLarge),
        child: card,
      );
    }

    return card;
  }
}

class AppCardHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget? leading;

  const AppCardHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: AppSizes.spacing12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: AppSizes.fontSizeLarge,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimaryColor,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSizes.spacing4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeSmall,
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class AppCardContent extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  const AppCardContent({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children,
    );
  }
}

class AppCardDivider extends StatelessWidget {
  final double? height;
  final Color? color;

  const AppCardDivider({super.key, this.height, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 1,
      color: color ?? context.borderColor,
      margin: const EdgeInsets.symmetric(vertical: AppSizes.spacing12),
    );
  }
}
