import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';

class AppearanceProvider extends ChangeNotifier {
  static const String _primaryColorKey = 'primary_color';
  // Use the app's current primary color as default
  static const Color _defaultPrimaryColor = AppColors.primary;

  Color _primaryColor = _defaultPrimaryColor;
  bool _hasCustomColor = false;

  Color get primaryColor => _primaryColor;
  bool get hasCustomColor => _hasCustomColor;

  // Return the default app color if no customization, otherwise return custom color
  Color get effectivePrimaryColor =>
      _hasCustomColor ? _primaryColor : AppColors.primary;

  AppearanceProvider() {
    _loadPreferences();
  }

  /// Load saved preferences from local storage
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final colorValue = prefs.getInt(_primaryColorKey);

      if (colorValue != null && colorValue != _defaultPrimaryColor.value) {
        _primaryColor = Color(colorValue);
        _hasCustomColor = true;
        // Only notify if there's actually a custom color - use microtask
        Future.microtask(() {
          if (mounted) notifyListeners();
        });
      }
    } catch (e) {
      debugPrint('Error loading appearance preferences: $e');
    }
  }

  /// Save preferences to local storage
  Future<void> savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_primaryColorKey, _primaryColor.value);
      debugPrint('Appearance preferences saved: ${_primaryColor.value}');
    } catch (e) {
      debugPrint('Error saving appearance preferences: $e');
    }
  }

  /// Set a new primary color
  Future<void> setPrimaryColor(Color color) async {
    if (_primaryColor != color) {
      _primaryColor = color;
      _hasCustomColor = color.value != _defaultPrimaryColor.value;

      // Auto-save when color changes
      await savePreferences();

      // Use microtask to prevent navigation issues during rebuild
      Future.microtask(() {
        if (mounted) notifyListeners();
      });
    }
  }

  /// Reset to default color
  Future<void> resetToDefaultColor() async {
    if (_hasCustomColor) {
      _primaryColor = _defaultPrimaryColor;
      _hasCustomColor = false;

      // Clear from storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_primaryColorKey);

      // Use microtask to prevent navigation issues during rebuild
      Future.microtask(() {
        if (mounted) notifyListeners();
      });
    }
  }

  // Helper to check if provider is still mounted
  bool get mounted => hasListeners;

  /// Reset to default - alias for consistency
  Future<void> resetToDefault() async {
    await resetToDefaultColor();
  }

  /// Generate a color scheme based on the primary color
  ColorScheme generateLightColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.light,
    );
  }

  /// Generate a dark color scheme based on the primary color
  ColorScheme generateDarkColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.dark,
    );
  }

  /// Get harmonious colors for UI elements
  Color get primaryColorLight => _primaryColor.withOpacity(0.1);
  Color get primaryColorDark =>
      HSLColor.fromColor(_primaryColor).withLightness(0.3).toColor();

  /// Generate accent colors
  List<Color> get accentColors {
    final hsl = HSLColor.fromColor(_primaryColor);
    return [
      hsl.withHue((hsl.hue + 30) % 360).toColor(), // Analogous
      hsl.withHue((hsl.hue + 60) % 360).toColor(), // Triadic
      hsl.withHue((hsl.hue + 180) % 360).toColor(), // Complementary
    ];
  }

  /// Check if the current color is dark or light for contrast
  bool get isPrimaryColorDark {
    final luminance = _primaryColor.computeLuminance();
    return luminance < 0.5;
  }

  /// Get appropriate text color for the primary color
  Color get primaryTextColor =>
      isPrimaryColorDark ? Colors.white : Colors.black;
}
