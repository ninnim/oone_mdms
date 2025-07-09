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
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.textInverse,
        onSecondary: AppColors.textInverse,
        onSurface: AppColors.textPrimary,
        onError: AppColors.textInverse,
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: AppSizes.fontSizeXLarge,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 1,
        shadowColor: AppColors.textSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSizes.radiusLarge)),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          borderSide: const BorderSide(color: AppColors.border),
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
          color: AppColors.textTertiary,
          fontSize: AppSizes.fontSizeMedium,
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textInverse,
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
          side: const BorderSide(color: AppColors.border),
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
        backgroundColor: AppColors.surfaceVariant,
        labelStyle: const TextStyle(
          color: AppColors.textPrimary,
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
        headingRowColor: MaterialStateProperty.all(AppColors.surfaceVariant),
        dataRowColor: MaterialStateProperty.all(AppColors.surface),
        dividerThickness: 1,
        headingTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: AppSizes.fontSizeSmall,
          fontWeight: FontWeight.w600,
        ),
        dataTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: AppSizes.fontSizeSmall,
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: AppSizes.fontSizeHeading,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: AppSizes.fontSizeTitle,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          color: AppColors.textPrimary,
          fontSize: AppSizes.fontSizeXXLarge,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: AppSizes.fontSizeXLarge,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: AppSizes.fontSizeLarge,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: AppColors.textPrimary,
          fontSize: AppSizes.fontSizeMedium,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: AppSizes.fontSizeLarge,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: AppSizes.fontSizeMedium,
        ),
        bodySmall: TextStyle(
          color: AppColors.textSecondary,
          fontSize: AppSizes.fontSizeSmall,
        ),
        labelLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: AppSizes.fontSizeMedium,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: AppSizes.fontSizeSmall,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: AppColors.textTertiary,
          fontSize: AppSizes.fontSizeSmall,
        ),
      ),
    );
  }
}

// Text Styles for consistent typography
class AppTextStyles {
  static const TextStyle heading = TextStyle(
    fontSize: AppSizes.fontSizeHeading,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle title = TextStyle(
    fontSize: AppSizes.fontSizeTitle,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: AppSizes.fontSizeXLarge,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: AppSizes.fontSizeMedium,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: AppSizes.fontSizeMedium,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: AppSizes.fontSizeSmall,
    color: AppColors.textTertiary,
  );

  static const TextStyle button = TextStyle(
    fontSize: AppSizes.fontSizeMedium,
    fontWeight: FontWeight.w600,
    color: AppColors.textInverse,
  );

  static const TextStyle sidebarTitle = TextStyle(
    fontSize: AppSizes.fontSizeLarge,
    fontWeight: FontWeight.w600,
    color: AppColors.sidebarText,
  );

  static const TextStyle sidebarItem = TextStyle(
    fontSize: AppSizes.fontSizeMedium,
    color: AppColors.sidebarText,
  );
}
