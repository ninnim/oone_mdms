# Quick Fix for Dark/Light Mode Theming

## Issue
It appears that several files have been reverted to use hardcoded `AppColors` instead of theme-aware colors. Here's a quick summary of what needs to be fixed:

## Files That Need Theme-Aware Updates

### 1. Status Chip (Critical)
`lib/presentation/widgets/common/status_chip.dart`
- Remove `import '../../../core/constants/app_colors.dart';`
- Update `_getColors()` method to accept `BuildContext` and use `Theme.of(context).colorScheme`

### 2. App Input Field (Critical)
`lib/presentation/widgets/common/app_input_field.dart`
- Remove `import '../../../core/constants/app_colors.dart';`
- Replace all `AppColors.*` references with `colorScheme.*` equivalents

### 3. Data Table (Critical)
`lib/presentation/widgets/common/data_table.dart`
- Remove `import '../../../core/constants/app_colors.dart';`
- Update all color references to use theme colors

## Quick Color Mapping Reference

```dart
// OLD (AppColors) → NEW (Theme-aware)
AppColors.surface → colorScheme.surface
AppColors.surfaceVariant → colorScheme.surfaceVariant  
AppColors.textPrimary → colorScheme.onSurface
AppColors.textSecondary → colorScheme.onSurfaceVariant
AppColors.textTertiary → colorScheme.onSurfaceVariant
AppColors.border → colorScheme.outline
AppColors.primary → colorScheme.primary
AppColors.error → colorScheme.error

// Access pattern:
final colorScheme = Theme.of(context).colorScheme;
```

## Status: ✅ Fixed Files - ALL COMPLETE!
- ✅ create_ticket_modal.dart - Fully theme-aware
- ✅ app_card.dart - Theme-aware (from previous work)
- ✅ Table column utilities - Accept BuildContext (from previous work)
- ✅ status_chip.dart - NOW FULLY THEME-AWARE! ✨
- ✅ app_input_field.dart - NOW FULLY THEME-AWARE! ✨  
- ✅ data_table.dart - NOW FULLY THEME-AWARE! ✨

## Status: ❌ Need Fixing  
- ALL CRITICAL WIDGETS HAVE BEEN FIXED! 🎉

## Next Steps
1. Apply theme-aware updates to the three remaining critical components
2. Test theme switching functionality
3. Address remaining files as needed

The core approach is to:
1. Remove AppColors imports
2. Add `final colorScheme = Theme.of(context).colorScheme;` 
3. Replace AppColors references with colorScheme equivalents
4. For status colors, use semantic Color constants while adapting to theme for backgrounds/borders
