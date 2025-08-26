import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF3b82f6);
  static const Color primaryDark = Color(0xFF2563eb);
  static const Color primaryLight = Color(0xFF60a5fa);

  // Secondary Colors
  static const Color secondary = Color(0xFF64748b);
  static const Color secondaryLight = Color(0xFF94a3b8);
  static const Color secondaryDark = Color(0xFF475569);

  // Status Colors
  static const Color success = Color(0xFF10b981);
  static const Color warning = Color(0xFFf59e0b);
  static const Color error = Color(0xFFef4444);
  static const Color info = Color(0xFF06b6d4);

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFf8fafc);
  static const Color lightSurface = Color(0xFFffffff);
  static const Color lightSurfaceVariant = Color(0xFFf1f5f9);
  static const Color lightTextPrimary = Color(0xFF0f172a);
  static const Color lightTextSecondary = Color(0xFF64748b);
  static const Color lightTextTertiary = Color(0xFF94a3b8);
  static const Color lightBorder = Color(0xFFe2e8f0);

  // Dark Theme Colors (soft, not too dark)
  static const Color darkBackground = Color(0xFF0f1419);
  static const Color darkSurface = Color(0xFF1a202c);
  static const Color darkSurfaceVariant = Color(0xFF2d3748);
  static const Color darkTextPrimary = Color(0xFFf7fafc);
  static const Color darkTextSecondary = Color(0xFFa0aec0);
  static const Color darkTextTertiary = Color(0xFF718096);
  static const Color darkBorder = Color(0xFF4a5568);

  // Sidebar Colors - Light
  static const Color lightSidebarBg = Color(0xFF1e293b);
  static const Color lightSidebarText = Color(0xFFe2e8f0);
  static const Color lightSidebarTextActive = Color(0xFFffffff);

  // Sidebar Colors - Dark
  static const Color darkSidebarBg = Color(0xFF2d3748);
  static const Color darkSidebarText = Color(0xFFe2e8f0);
  static const Color darkSidebarTextActive = Color(0xFFffffff);

  // Backward compatibility - these will be replaced by theme-aware getters
  @Deprecated('Use theme-aware colors from AppTheme')
  static const Color background = lightBackground;
  @Deprecated('Use theme-aware colors from AppTheme')
  static const Color surface = lightSurface;
  @Deprecated('Use theme-aware colors from AppTheme')
  static const Color surfaceVariant = lightSurfaceVariant;
  @Deprecated('Use theme-aware colors from AppTheme')
  static const Color textPrimary = lightTextPrimary;
  @Deprecated('Use theme-aware colors from AppTheme')
  static const Color textSecondary = lightTextSecondary;
  @Deprecated('Use theme-aware colors from AppTheme')
  static const Color textTertiary = lightTextTertiary;
  @Deprecated('Use theme-aware colors from AppTheme')
  static const Color textDisabled = Color(0xFFcbd5e1);
  @Deprecated('Use theme-aware colors from AppTheme')
  static const Color textInverse = Color(0xFFffffff);
  @Deprecated('Use theme-aware colors from AppTheme')
  static const Color border = lightBorder;
  @Deprecated('Use theme-aware colors from AppTheme')
  static const Color borderLight = Color(0xFFf1f5f9);
  @Deprecated('Use theme-aware colors from AppTheme')
  static const Color sidebarBg = lightSidebarBg;
  @Deprecated('Use theme-aware colors from AppTheme')
  static const Color sidebarBgDark = Color(0xFF0f172a);
  @Deprecated('Use theme-aware colors from AppTheme')
  static const Color sidebarText = lightSidebarText;
  @Deprecated('Use theme-aware colors from AppTheme')
  static const Color sidebarTextActive = lightSidebarTextActive;

  // Status-specific colors
  static const Color commissioned = success;
  static const Color renovation = warning;
  static const Color vacant = error;
  static const Color occupied = primary;
  static const Color construction = secondary;

  // Additional colors for tickets and components
  static const Color onPrimary = Color(0xFFffffff);
  static const Color onSecondary = Color(0xFFffffff);
  static const Color onSuccess = Color(0xFFffffff);
  static const Color onWarning = Color(0xFF000000);
  static const Color onError = Color(0xFFffffff);
}
