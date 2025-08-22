import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';

/// Helper class for implementing responsive behavior across screens
class ResponsiveHelper {
  /// Check if the current screen size is mobile (tablet or smaller)
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width <= AppSizes.tabletBreakpoint;
  }

  /// Check if the current screen size is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width <= AppSizes.tabletBreakpoint &&
        width > AppSizes.mobileBreakpoint;
  }

  /// Check if the current screen size is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width > AppSizes.tabletBreakpoint;
  }

  /// Get the appropriate spacing for the current screen size
  static double getSpacing(BuildContext context) {
    return isMobile(context) ? AppSizes.paddingSmall : AppSizes.paddingLarge;
  }

  /// Get the appropriate padding for the current screen size
  static EdgeInsets getPadding(BuildContext context) {
    return isMobile(context)
        ? const EdgeInsets.all(AppSizes.paddingSmall)
        : const EdgeInsets.all(AppSizes.paddingLarge);
  }

  /// Get the appropriate column count for grid layouts
  static int getGridColumnCount(
    BuildContext context, {
    int desktopColumns = 3,
    int tabletColumns = 2,
    int mobileColumns = 1,
  }) {
    if (isDesktop(context)) return desktopColumns;
    if (isTablet(context)) return tabletColumns;
    return mobileColumns;
  }

  /// Get the appropriate cross axis count for responsive grid
  static int getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 1;
  }

  /// Get appropriate app bar height for mobile
  static double getAppBarHeight(BuildContext context) {
    return isMobile(context)
        ? AppSizes.appBarHeightMobile
        : AppSizes.appBarHeight;
  }

  /// Get appropriate elevation for cards based on screen size
  static double getCardElevation(BuildContext context) {
    return isMobile(context) ? 1.0 : 2.0;
  }

  /// Get appropriate border radius for cards based on screen size
  static double getCardBorderRadius(BuildContext context) {
    return isMobile(context) ? AppSizes.radiusSmall : AppSizes.radiusMedium;
  }

  /// Determine if we should show compact UI elements
  static bool shouldUseCompactUI(BuildContext context) {
    return isMobile(context);
  }

  /// Get appropriate dialog constraints
  static BoxConstraints getDialogConstraints(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    if (isMobile(context)) {
      return BoxConstraints(
        maxWidth: screenSize.width * 0.95,
        maxHeight: screenSize.height * 0.85,
        minWidth: screenSize.width * 0.95,
      );
    } else if (isTablet(context)) {
      return BoxConstraints(
        maxWidth: screenSize.width * 0.8,
        maxHeight: screenSize.height * 0.85,
        minWidth: 600,
      );
    } else {
      // Desktop: More generous sizing for larger screens
      final maxWidth = (screenSize.width * 0.85).clamp(800.0, 1400.0);
      return BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: screenSize.height * 0.9,
        minWidth: 800,
      );
    }
  }

  /// Get customizable dialog constraints with specific parameters
  static BoxConstraints getCustomDialogConstraints(
    BuildContext context, {
    double mobileWidthRatio = 0.95,
    double tabletWidthRatio = 0.8,
    double desktopWidthRatio = 0.85,
    double maxDesktopWidth = 1400.0,
    double minDesktopWidth = 800.0,
    double heightRatio = 0.9,
  }) {
    final screenSize = MediaQuery.of(context).size;

    if (isMobile(context)) {
      return BoxConstraints(
        maxWidth: screenSize.width * mobileWidthRatio,
        maxHeight: screenSize.height * 0.85, // Keep mobile height conservative
        minWidth: screenSize.width * mobileWidthRatio,
      );
    } else if (isTablet(context)) {
      return BoxConstraints(
        maxWidth: screenSize.width * tabletWidthRatio,
        maxHeight: screenSize.height * heightRatio,
        minWidth: 600,
      );
    } else {
      final maxWidth = (screenSize.width * desktopWidthRatio).clamp(
        minDesktopWidth,
        maxDesktopWidth,
      );
      return BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: screenSize.height * heightRatio,
        minWidth: minDesktopWidth,
      );
    }
  }

  /// Get appropriate dialog margin
  static EdgeInsets getDialogMargin(BuildContext context) {
    return isMobile(context)
        ? const EdgeInsets.all(AppSizes.paddingSmall)
        : const EdgeInsets.all(AppSizes.paddingLarge);
  }

  /// Get scrollable container constraints to prevent overflow
  static BoxConstraints getScrollableConstraints(
    BuildContext context, {
    double? maxHeight,
    double? minHeight,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final defaultMaxHeight = isMobile(context)
        ? screenHeight * 0.4
        : screenHeight * 0.5;

    return BoxConstraints(
      maxHeight: maxHeight ?? defaultMaxHeight,
      minHeight: minHeight ?? 100,
    );
  }

  /// Wrap content with responsive scrolling behavior
  static Widget wrapWithScrolling(
    Widget child, {
    ScrollPhysics? physics,
    EdgeInsets? padding,
  }) {
    return SingleChildScrollView(
      physics: physics ?? const BouncingScrollPhysics(),
      padding: padding,
      child: child,
    );
  }

  /// Get safe area padding for dialogs
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return EdgeInsets.only(
      top: mediaQuery.padding.top,
      bottom: mediaQuery.padding.bottom,
    );
  }

  /// Create a responsive scrollable container that prevents overflow
  static Widget createScrollableContainer({
    required Widget child,
    required BuildContext context,
    double? maxHeight,
    double? minHeight,
    EdgeInsets? padding,
    BoxDecoration? decoration,
    ScrollPhysics? physics,
  }) {
    final constraints = getScrollableConstraints(
      context,
      maxHeight: maxHeight,
      minHeight: minHeight,
    );

    return Container(
      constraints: constraints,
      padding: padding,
      decoration: decoration,
      child: SingleChildScrollView(
        physics: physics ?? const BouncingScrollPhysics(),
        child: child,
      ),
    );
  }

  /// Get responsive table/grid configuration
  static ({int columns, double spacing, double childAspectRatio})
  getTableConfig(
    BuildContext context, {
    int? mobileColumns,
    int? tabletColumns,
    int? desktopColumns,
  }) {
    if (isMobile(context)) {
      return (
        columns: mobileColumns ?? 1,
        spacing: AppSizes.spacing8,
        childAspectRatio: 0.8,
      );
    } else if (isTablet(context)) {
      return (
        columns: tabletColumns ?? 2,
        spacing: AppSizes.spacing12,
        childAspectRatio: 1.0,
      );
    } else {
      return (
        columns: desktopColumns ?? 3,
        spacing: AppSizes.spacing16,
        childAspectRatio: 1.2,
      );
    }
  }

  /// Get responsive font scaling
  static double getScaledFontSize(BuildContext context, double baseFontSize) {
    final mediaQuery = MediaQuery.of(context);
    final scale = mediaQuery.textScaler.scale(baseFontSize);

    // Clamp the scaled font size to prevent extreme scaling
    return scale.clamp(baseFontSize * 0.8, baseFontSize * 1.3);
  }

  /// Handle overflow gracefully with fallback options
  static Widget handleOverflow({
    required Widget child,
    required BuildContext context,
    OverflowStrategy strategy = OverflowStrategy.scroll,
  }) {
    switch (strategy) {
      case OverflowStrategy.scroll:
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: child,
        );
      case OverflowStrategy.clip:
        return ClipRect(child: child);
      case OverflowStrategy.ellipsis:
        return child; // Let the child widget handle ellipsis
      case OverflowStrategy.wrap:
        return Wrap(children: [child]);
    }
  }
}

/// Enum for different overflow handling strategies
enum OverflowStrategy { scroll, clip, ellipsis, wrap }

/// Mixin for screens that need responsive behavior
mixin ResponsiveMixin<T extends StatefulWidget> on State<T> {
  bool get isMobile => ResponsiveHelper.isMobile(context);
  bool get isTablet => ResponsiveHelper.isTablet(context);
  bool get isDesktop => ResponsiveHelper.isDesktop(context);
  bool get shouldUseCompactUI => ResponsiveHelper.shouldUseCompactUI(context);

  double get spacing => ResponsiveHelper.getSpacing(context);
  EdgeInsets get padding => ResponsiveHelper.getPadding(context);

  /// Override this method to implement responsive state changes
  void handleResponsiveStateChange() {
    // Override in implementing classes
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    handleResponsiveStateChange();
  }
}

/// Widget builder that provides responsive context
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, bool isMobile, bool isTablet)
  builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return builder(
      context,
      ResponsiveHelper.isMobile(context),
      ResponsiveHelper.isTablet(context),
    );
  }
}

/// Enum for different layout modes
enum LayoutMode { mobile, tablet, desktop }

/// Extension to get layout mode from context
extension ResponsiveContext on BuildContext {
  LayoutMode get layoutMode {
    if (ResponsiveHelper.isMobile(this)) return LayoutMode.mobile;
    if (ResponsiveHelper.isTablet(this)) return LayoutMode.tablet;
    return LayoutMode.desktop;
  }

  bool get isMobile => ResponsiveHelper.isMobile(this);
  bool get isTablet => ResponsiveHelper.isTablet(this);
  bool get isDesktop => ResponsiveHelper.isDesktop(this);
}
