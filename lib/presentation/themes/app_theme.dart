import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'SF Pro Display',

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.lightSurface,
        surfaceContainerHighest: AppColors.lightSurfaceVariant,
        error: AppColors.error,
        onPrimary: AppColors.onPrimary,
        onSecondary: AppColors.onSecondary,
        onSurface: AppColors.lightTextPrimary,
        onError: AppColors.onError,
        outline: AppColors.lightBorder,
        outlineVariant: AppColors.lightBorder,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.lightBackground,

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: AppSizes.fontSizeXLarge,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        color: AppColors.lightSurface,
        elevation: 1,
        shadowColor: AppColors.lightTextSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSizes.radiusLarge)),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacing16,
          vertical: AppSizes.spacing12,
        ),
        hintStyle: const TextStyle(
          color: AppColors.lightTextTertiary,
          fontSize: AppSizes.fontSizeMedium,
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacing24,
            vertical: AppSizes.spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: AppSizes.fontSizeMedium,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.lightBorder),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacing24,
            vertical: AppSizes.spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: AppSizes.fontSizeMedium,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacing16,
            vertical: AppSizes.spacing8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          ),
          textStyle: const TextStyle(
            fontSize: AppSizes.fontSizeMedium,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurfaceVariant,
        labelStyle: const TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: AppSizes.fontSizeSmall,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacing8,
          vertical: AppSizes.spacing4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        ),
      ),

      // Data Table Theme
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(AppColors.lightSurfaceVariant),
        dataRowColor: WidgetStateProperty.all(AppColors.lightSurface),
        dividerThickness: 1,
        headingTextStyle: const TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: AppSizes.fontSizeSmall,
          fontWeight: FontWeight.w600,
        ),
        dataTextStyle: const TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: AppSizes.fontSizeSmall,
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: AppSizes.fontSizeHeading,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: AppSizes.fontSizeTitle,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: AppSizes.fontSizeXXLarge,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: AppSizes.fontSizeXLarge,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: AppSizes.fontSizeLarge,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: AppSizes.fontSizeMedium,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: AppSizes.fontSizeLarge,
        ),
        bodyMedium: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: AppSizes.fontSizeMedium,
        ),
        bodySmall: TextStyle(
          color: AppColors.lightTextSecondary,
          fontSize: AppSizes.fontSizeSmall,
        ),
        labelLarge: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: AppSizes.fontSizeMedium,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: TextStyle(
          color: AppColors.lightTextSecondary,
          fontSize: AppSizes.fontSizeSmall,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: AppColors.lightTextTertiary,
          fontSize: AppSizes.fontSizeSmall,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'SF Pro Display',

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.darkSurface,
        surfaceContainerHighest: AppColors.darkSurfaceVariant,
        error: AppColors.error,
        onPrimary: AppColors.onPrimary,
        onSecondary: AppColors.onSecondary,
        onSurface: AppColors.darkTextPrimary,
        onError: AppColors.onError,
        outline: AppColors.darkBorder,
        outlineVariant: AppColors.darkBorder,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.darkBackground,

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: AppSizes.fontSizeXLarge,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        color: AppColors.darkSurface,
        elevation: 1,
        shadowColor: AppColors.darkTextSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSizes.radiusLarge)),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacing16,
          vertical: AppSizes.spacing12,
        ),
        hintStyle: const TextStyle(
          color: AppColors.darkTextTertiary,
          fontSize: AppSizes.fontSizeMedium,
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacing24,
            vertical: AppSizes.spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: AppSizes.fontSizeMedium,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.darkBorder),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacing24,
            vertical: AppSizes.spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: AppSizes.fontSizeMedium,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacing16,
            vertical: AppSizes.spacing8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          ),
          textStyle: const TextStyle(
            fontSize: AppSizes.fontSizeMedium,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        labelStyle: const TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: AppSizes.fontSizeSmall,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacing8,
          vertical: AppSizes.spacing4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        ),
      ),

      // Data Table Theme
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(AppColors.darkSurfaceVariant),
        dataRowColor: WidgetStateProperty.all(AppColors.darkSurface),
        dividerThickness: 1,
        headingTextStyle: const TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: AppSizes.fontSizeSmall,
          fontWeight: FontWeight.w600,
        ),
        dataTextStyle: const TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: AppSizes.fontSizeSmall,
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: AppSizes.fontSizeHeading,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: AppSizes.fontSizeTitle,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: AppSizes.fontSizeXXLarge,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: AppSizes.fontSizeXLarge,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: AppSizes.fontSizeLarge,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: AppSizes.fontSizeMedium,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: AppSizes.fontSizeLarge,
        ),
        bodyMedium: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: AppSizes.fontSizeMedium,
        ),
        bodySmall: TextStyle(
          color: AppColors.darkTextSecondary,
          fontSize: AppSizes.fontSizeSmall,
        ),
        labelLarge: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: AppSizes.fontSizeMedium,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: TextStyle(
          color: AppColors.darkTextSecondary,
          fontSize: AppSizes.fontSizeSmall,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: AppColors.darkTextTertiary,
          fontSize: AppSizes.fontSizeSmall,
        ),
      ),
    );
  }
}

// Theme-aware Text Styles
class AppTextStyles {
  static TextStyle heading(BuildContext context) => TextStyle(
    fontSize: AppSizes.fontSizeHeading,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle title(BuildContext context) => TextStyle(
    fontSize: AppSizes.fontSizeTitle,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle subtitle(BuildContext context) => TextStyle(
    fontSize: AppSizes.fontSizeXLarge,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle body(BuildContext context) => TextStyle(
    fontSize: AppSizes.fontSizeMedium,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle bodySecondary(BuildContext context) => TextStyle(
    fontSize: AppSizes.fontSizeMedium,
    color: Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary,
  );

  static TextStyle caption(BuildContext context) => TextStyle(
    fontSize: AppSizes.fontSizeSmall,
    color: Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextTertiary
        : AppColors.lightTextTertiary,
  );

  static TextStyle button(BuildContext context) => TextStyle(
    fontSize: AppSizes.fontSizeMedium,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).colorScheme.onPrimary,
  );

  static TextStyle sidebarTitle(BuildContext context) => TextStyle(
    fontSize: AppSizes.fontSizeLarge,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkSidebarText
        : AppColors.lightSidebarText,
  );

  static TextStyle sidebarItem(BuildContext context) => TextStyle(
    fontSize: AppSizes.fontSizeMedium,
    color: Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkSidebarText
        : AppColors.lightSidebarText,
  );
}

// Theme-aware Color Extensions
extension AppColorsExtension on BuildContext {
  Color get primaryColor => Theme.of(this).colorScheme.primary;
  Color get surfaceColor => Theme.of(this).colorScheme.surface;
  Color get backgroundColor => Theme.of(this).scaffoldBackgroundColor;
  Color get textPrimaryColor => Theme.of(this).colorScheme.onSurface;
  Color get textSecondaryColor => Theme.of(this).brightness == Brightness.dark
      ? AppColors.darkTextSecondary
      : AppColors.lightTextSecondary;
  Color get textTertiaryColor => Theme.of(this).brightness == Brightness.dark
      ? AppColors.darkTextTertiary
      : AppColors.lightTextTertiary;
  Color get borderColor => Theme.of(this).colorScheme.outline;
  Color get surfaceVariantColor =>
      Theme.of(this).colorScheme.surfaceContainerHighest;
  Color get sidebarBgColor => Theme.of(this).brightness == Brightness.dark
      ? AppColors.darkSidebarBg
      : AppColors.lightSidebarBg;
  Color get sidebarTextColor => Theme.of(this).brightness == Brightness.dark
      ? AppColors.darkSidebarText
      : AppColors.lightSidebarText;
  Color get errorColor => Theme.of(this).colorScheme.error;
  Color get successColor => AppColors.success;
  Color get warningColor => AppColors.warning;
  Color get secondaryColor => Theme.of(this).colorScheme.secondary;
  Color get infoColor => AppColors.info;
  Color get shadowColor => Theme.of(this).brightness == Brightness.dark
      ? Colors.black.withOpacity(0.2)
      : Colors.black.withOpacity(0.1);
}
