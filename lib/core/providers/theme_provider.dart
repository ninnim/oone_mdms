import 'package:flutter/material.dart';

enum AppThemeMode { light, dark, system }

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _themeMode = AppThemeMode.system;

  AppThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == AppThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return _themeMode == AppThemeMode.dark;
  }

  bool get isLightMode => !isDarkMode;

  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      // Use a more isolated approach to prevent navigation issues
      Future.microtask(() {
        if (mounted) notifyListeners();
      });
    }
  }

  // Helper to check if provider is still mounted
  bool get mounted => hasListeners;

  // Helper methods for easy access
  Future<void> setLightMode() => setThemeMode(AppThemeMode.light);
  Future<void> setDarkMode() => setThemeMode(AppThemeMode.dark);
  Future<void> setSystemMode() => setThemeMode(AppThemeMode.system);
}
