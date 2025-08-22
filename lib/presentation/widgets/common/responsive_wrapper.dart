import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/responsive_helper.dart';

/// A comprehensive wrapper widget that handles responsive design and overflow prevention
///
/// Features:
/// - Automatic responsive breakpoints
/// - Overflow prevention with scrollable content
/// - Adaptive padding and spacing
/// - Cross-platform consistent behavior
/// - Smooth scrolling physics
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final bool enableScrolling;
  final ScrollPhysics? scrollPhysics;
  final EdgeInsets? padding;
  final BoxConstraints? constraints;
  final OverflowStrategy overflowStrategy;
  final Axis scrollDirection;
  final bool shrinkWrap;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.enableScrolling = true,
    this.scrollPhysics,
    this.padding,
    this.constraints,
    this.overflowStrategy = OverflowStrategy.scroll,
    this.scrollDirection = Axis.vertical,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    // Apply responsive padding if not provided
    final effectivePadding = padding ?? ResponsiveHelper.getPadding(context);

    // Apply responsive constraints if scrolling is enabled
    if (enableScrolling) {
      final responsiveConstraints =
          constraints ?? ResponsiveHelper.getScrollableConstraints(context);

      content = ConstrainedBox(
        constraints: responsiveConstraints,
        child: enableScrolling
            ? SingleChildScrollView(
                physics: scrollPhysics ?? const BouncingScrollPhysics(),
                scrollDirection: scrollDirection,
                child: content,
              )
            : content,
      );
    }

    // Apply padding
    if (effectivePadding != EdgeInsets.zero) {
      content = Padding(padding: effectivePadding, child: content);
    }

    return content;
  }
}

/// A responsive dialog wrapper that handles overflow and provides consistent styling
class ResponsiveDialogWrapper extends StatelessWidget {
  final Widget child;
  final bool enableHeaderFooter;
  final Widget? header;
  final Widget? footer;
  final EdgeInsets? contentPadding;

  const ResponsiveDialogWrapper({
    super.key,
    required this.child,
    this.enableHeaderFooter = true,
    this.header,
    this.footer,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final dialogConstraints = ResponsiveHelper.getDialogConstraints(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: ConstrainedBox(
        constraints: dialogConstraints,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (header != null) header!,
            Expanded(
              child: ResponsiveWrapper(padding: contentPadding, child: child),
            ),
            if (footer != null) footer!,
          ],
        ),
      ),
    );
  }
}

/// A responsive container that adapts to screen size and prevents overflow
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final bool enableBackground;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final BoxShadow? shadow;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.enableBackground = true,
    this.backgroundColor,
    this.borderRadius,
    this.margin,
    this.padding,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return Container(
      margin:
          margin ??
          (isMobile
              ? const EdgeInsets.all(AppSizes.spacing8)
              : const EdgeInsets.all(AppSizes.spacing16)),
      padding: padding ?? ResponsiveHelper.getPadding(context),
      decoration: enableBackground
          ? BoxDecoration(
              color: backgroundColor ?? Theme.of(context).colorScheme.surface,
              borderRadius:
                  borderRadius ??
                  BorderRadius.circular(
                    ResponsiveHelper.getCardBorderRadius(context),
                  ),
              boxShadow: shadow != null
                  ? [shadow!]
                  : [if (!isMobile) AppSizes.shadowMedium],
            )
          : null,
      child: ResponsiveWrapper(child: child),
    );
  }
}

/// Extension to easily make any widget responsive
extension ResponsiveWidgetExtension on Widget {
  /// Wrap this widget with responsive behavior
  Widget responsive({
    bool enableScrolling = true,
    ScrollPhysics? scrollPhysics,
    EdgeInsets? padding,
    BoxConstraints? constraints,
    OverflowStrategy overflowStrategy = OverflowStrategy.scroll,
  }) {
    return ResponsiveWrapper(
      enableScrolling: enableScrolling,
      scrollPhysics: scrollPhysics,
      padding: padding,
      constraints: constraints,
      overflowStrategy: overflowStrategy,
      child: this,
    );
  }

  /// Wrap this widget in a responsive container
  Widget responsiveContainer({
    bool enableBackground = true,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    EdgeInsets? margin,
    EdgeInsets? padding,
    BoxShadow? shadow,
  }) {
    return ResponsiveContainer(
      enableBackground: enableBackground,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      margin: margin,
      padding: padding,
      shadow: shadow,
      child: this,
    );
  }

  /// Wrap this widget in a responsive dialog
  Widget responsiveDialog({
    Widget? header,
    Widget? footer,
    EdgeInsets? contentPadding,
  }) {
    return ResponsiveDialogWrapper(
      header: header,
      footer: footer,
      contentPadding: contentPadding,
      child: this,
    );
  }
}

/// Helper for creating responsive layouts
class ResponsiveLayout extends StatelessWidget {
  final Widget? mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? fallback;

  const ResponsiveLayout({
    super.key,
    this.mobile,
    this.tablet,
    this.desktop,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (context.isMobile && mobile != null) {
      return mobile!;
    } else if (context.isTablet && tablet != null) {
      return tablet!;
    } else if (context.isDesktop && desktop != null) {
      return desktop!;
    } else if (fallback != null) {
      return fallback!;
    } else {
      // Return the first non-null widget as fallback
      return mobile ?? tablet ?? desktop ?? const SizedBox.shrink();
    }
  }
}
