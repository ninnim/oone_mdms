import 'dart:io';

void main() {
  final filesToUpdate = [
    'lib/presentation/screens/dashboard/dashboard_screen.dart',
    'lib/presentation/widgets/sites/site_table_columns.dart',
    'lib/presentation/widgets/time_bands/time_band_form_dialog.dart',
    'lib/presentation/widgets/special_days/special_day_form_dialog.dart',
    'lib/presentation/widgets/seasons/season_form_dialog.dart',
    'lib/presentation/widgets/devices/device_table_columns.dart',
    'lib/presentation/widgets/devices/device_summary_card.dart',
    'lib/presentation/widgets/devices/device_form_dialog.dart',
    'lib/presentation/widgets/common/app_data_table.dart',
    'lib/presentation/widgets/common/app_dropdown_field.dart',
    'lib/presentation/widgets/common/app_text_field.dart',
    'lib/presentation/widgets/common/status_chip.dart',
    'lib/presentation/screens/time_bands/time_bands_screen.dart',
    'lib/presentation/screens/special_days/special_days_screen.dart',
    'lib/presentation/screens/seasons/seasons_screen.dart',
    'lib/presentation/screens/devices/devices_screen.dart',
    'lib/presentation/screens/sites/sites_screen.dart',
  ];

  final colorMappings = {
    'AppColors.textPrimary': 'Theme.of(context).colorScheme.onSurface',
    'AppColors.textSecondary':
        'Theme.of(context).colorScheme.onSurface.withOpacity(0.7)',
    'AppColors.textTertiary':
        'Theme.of(context).colorScheme.onSurface.withOpacity(0.5)',
    'AppColors.surface': 'Theme.of(context).colorScheme.surface',
    'AppColors.background': 'Theme.of(context).scaffoldBackgroundColor',
    'AppColors.border': 'Theme.of(context).colorScheme.outline',
    'AppColors.surfaceVariant':
        'Theme.of(context).colorScheme.surfaceContainerHighest',
    'AppColors.lightSurface': 'Theme.of(context).colorScheme.surface',
    'AppColors.darkSurface': 'Theme.of(context).colorScheme.surface',
    'AppColors.lightTextPrimary': 'Theme.of(context).colorScheme.onSurface',
    'AppColors.darkTextPrimary': 'Theme.of(context).colorScheme.onSurface',
    'AppColors.lightTextSecondary':
        'Theme.of(context).colorScheme.onSurface.withOpacity(0.7)',
    'AppColors.darkTextSecondary':
        'Theme.of(context).colorScheme.onSurface.withOpacity(0.7)',
  };

  for (final filePath in filesToUpdate) {
    updateColorsInFile(filePath, colorMappings);
  }
}

void updateColorsInFile(String filePath, Map<String, String> colorMappings) {
  final file = File(filePath);
  if (!file.existsSync()) {
    print('File not found: $filePath');
    return;
  }

  String content = file.readAsStringSync();
  bool modified = false;

  for (final entry in colorMappings.entries) {
    if (content.contains(entry.key)) {
      content = content.replaceAll(entry.key, entry.value);
      modified = true;
    }
  }

  if (modified) {
    // Add theme import if not present
    if (!content.contains("import 'package:flutter/material.dart';") ||
        (!content.contains('Theme.of(context)') &&
            content.contains('Theme.of('))) {
      // Already contains material import
    } else if (content.contains('Theme.of(context)') &&
        !content.contains("import 'package:flutter/material.dart';")) {
      // Add import if using Theme.of(context) but no import
      content = "import 'package:flutter/material.dart';\n" + content;
    }

    file.writeAsStringSync(content);
    print('Updated: $filePath');
  }
}
