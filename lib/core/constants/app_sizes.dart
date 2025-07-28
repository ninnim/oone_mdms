import 'package:flutter/material.dart';

class AppSizes {
  // Spacing - 8px grid system
  static const double spacing2 = 2.0;
  static const double spacing4 = 4.0;
  static const double spacing6 = 6.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
  static const double spacing56 = 56.0;
  static const double spacing64 = 64.0;
  static const double rowHeight = 30.0;

  // Border Radius
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 6.0;
  static const double radiusLarge = 8.0;
  static const double radiusXLarge = 12.0;

  // Icon Sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 20.0;
  static const double iconLarge = 24.0;
  static const double iconXLarge = 32.0;

  // Font Sizes
  static const double fontSizeExtraSmall = 10.0;
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeXLarge = 18.0;
  static const double fontSizeXXLarge = 20.0;
  static const double fontSizeTitle = 24.0;
  static const double fontSizeHeading = 32.0;

  // Layout Dimensions
  static const double sidebarWidth = 250.0;
  static const double sidebarCollapsedWidth = 80.0;
  static const double appBarHeight = 64.0;
  static const double appBarHeightWithTabs = 72.0;
  static const double appBarHeightSmall = 56.0;
  static const double appBarHeightWithRoute = 56.0;
  static const double buttonHeightSmall = 36.0;
  static const double buttonHeight = 44.0;
  static const double inputWidth = 300.0;
  static const double inputHeight = 36.0;
  static const double cardMinHeight = 120.0;

  /// Button Dimensions
  static const double buttonWidth = 100.0;
  static const double buttonW = 120.0;

  // Breakpoints
  static const double mobileBreakpoint = 768.0;
  static const double tabletBreakpoint = 1024.0;
  static const double desktopBreakpoint = 1200.0;

  // Shadows
  static const BoxShadow shadowSmall = BoxShadow(
    color: Color(0x0A000000),
    offset: Offset(0, 1),
    blurRadius: 3,
  );

  static const BoxShadow shadowMedium = BoxShadow(
    color: Color(0x0F000000),
    offset: Offset(0, 2),
    blurRadius: 6,
  );

  static const BoxShadow shadowLarge = BoxShadow(
    color: Color(0x14000000),
    offset: Offset(0, 4),
    blurRadius: 12,
  );
}
