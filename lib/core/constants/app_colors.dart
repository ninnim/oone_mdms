import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF2563eb);
  static const Color primaryDark = Color(0xFF1d4ed8);
  static const Color primaryLight = Color(0xFF3b82f6);

  // Secondary Colors
  static const Color secondary = Color(0xFF64748b);
  static const Color secondaryLight = Color(0xFF94a3b8);
  static const Color secondaryDark = Color(0xFF475569);

  // Status Colors
  static const Color success = Color(0xFF10b981);
  static const Color warning = Color(0xFFf59e0b);
  static const Color error = Color(0xFFef4444);
  static const Color info = Color(0xFF06b6d4);

  // Background Colors
  static const Color background = Color(0xFFf8fafc);
  static const Color surface = Color(0xFFffffff);
  static const Color surfaceVariant = Color(0xFFf1f5f9);

  // Sidebar Colors
  static const Color sidebarBg = Color(0xFF1e293b);
  static const Color sidebarBgDark = Color(0xFF0f172a);
  static const Color sidebarText = Color(0xFFe2e8f0);
  static const Color sidebarTextActive = Color(0xFFffffff);

  // Text Colors
  static const Color textPrimary = Color(0xFF0f172a);
  static const Color textSecondary = Color(0xFF64748b);
  static const Color textTertiary = Color(0xFF94a3b8);
  static const Color textInverse = Color(0xFFffffff);

  // Border Colors
  static const Color border = Color(0xFFe2e8f0);
  static const Color borderLight = Color(0xFFf1f5f9);

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
