import 'package:flutter/material.dart';
import 'package:mdms_clone/presentation/widgets/common/app_toast.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/appearance_provider.dart';
import '../../../core/constants/app_sizes.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/app_button.dart';

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  Color? _selectedColor;
  bool _isCustomizing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing24),
        child: Consumer2<ThemeProvider, AppearanceProvider>(
          builder: (context, themeProvider, appearanceProvider, child) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: AppSizes.spacing32),

                  // Theme Mode Section
                  _buildThemeModeSection(themeProvider),
                  const SizedBox(height: AppSizes.spacing32),

                  // Color Customization Section
                  _buildColorCustomizationSection(appearanceProvider),
                  const SizedBox(height: AppSizes.spacing32),

                  // Preview Section
                  _buildPreviewSection(appearanceProvider),
                  const SizedBox(height: AppSizes.spacing32),

                  // Action Buttons
                  _buildActionButtons(appearanceProvider),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appearance',
          style: TextStyle(
            fontSize: AppSizes.fontSizeXXLarge,
            fontWeight: FontWeight.bold,
            color: context.textPrimaryColor,
          ),
        ),
        const SizedBox(height: AppSizes.spacing8),
        Text(
          'Customize the look and feel of your application',
          style: TextStyle(
            fontSize: AppSizes.fontSizeMedium,
            color: context.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeModeSection(ThemeProvider themeProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme Mode',
              style: TextStyle(
                fontSize: AppSizes.fontSizeLarge,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppSizes.spacing16),
            Text(
              'Choose how the application should appear',
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: context.textSecondaryColor,
              ),
            ),
            const SizedBox(height: AppSizes.spacing20),

            // Theme Mode Options
            Row(
              children: [
                Expanded(
                  child: _buildThemeModeOption(
                    themeProvider,
                    AppThemeMode.light,
                    'Light',
                    Icons.light_mode,
                    'Perfect for bright environments',
                  ),
                ),
                const SizedBox(width: AppSizes.spacing12),
                Expanded(
                  child: _buildThemeModeOption(
                    themeProvider,
                    AppThemeMode.dark,
                    'Dark',
                    Icons.dark_mode,
                    'Easy on the eyes in low light',
                  ),
                ),
                const SizedBox(width: AppSizes.spacing12),
                Expanded(
                  child: _buildThemeModeOption(
                    themeProvider,
                    AppThemeMode.system,
                    'System',
                    Icons.settings_suggest,
                    'Follows your device settings',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeModeOption(
    ThemeProvider themeProvider,
    AppThemeMode mode,
    String title,
    IconData icon,
    String description,
  ) {
    final isSelected = themeProvider.themeMode == mode;

    return GestureDetector(
      onTap: () => themeProvider.setThemeMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSizes.spacing16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? context.primaryColor : context.borderColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          color: isSelected
              ? context.primaryColor.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? context.primaryColor
                  : context.textSecondaryColor,
            ),
            const SizedBox(height: AppSizes.spacing8),
            Text(
              title,
              style: TextStyle(
                fontSize: AppSizes.fontSizeMedium,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? context.primaryColor
                    : context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppSizes.spacing4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: context.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorCustomizationSection(
    AppearanceProvider appearanceProvider,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Primary Color',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeLarge,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimaryColor,
                  ),
                ),
                const Spacer(),
                if (appearanceProvider.hasCustomColor)
                  TextButton.icon(
                    onPressed: () {
                      appearanceProvider.resetToDefaultColor();
                      setState(() {
                        _selectedColor = null;
                        _isCustomizing = false;
                      });
                    },
                    icon: const Icon(Icons.restore, size: 16),
                    label: const Text('Reset to Default'),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.spacing16),
            Text(
              'Choose a primary color that reflects your brand or preference',
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: context.textSecondaryColor,
              ),
            ),
            const SizedBox(height: AppSizes.spacing20),

            // Color Presets
            _buildColorPresets(appearanceProvider),
            const SizedBox(height: AppSizes.spacing20),

            // Custom Color Picker
            _buildCustomColorPicker(appearanceProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPresets(AppearanceProvider appearanceProvider) {
    final presetColors = [
      const Color(0xFF3B82F6), // Blue (default)
      const Color(0xFF996699), // Purple (oone)
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEF4444), // Red
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF84CC16), // Lime
      const Color(0xFFEC4899), // Pink
      const Color(0xFF6B7280), // Gray
      const Color(0xFF0EA5E9), // Sky
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color Presets',
          style: TextStyle(
            fontSize: AppSizes.fontSizeMedium,
            fontWeight: FontWeight.w500,
            color: context.textPrimaryColor,
          ),
        ),
        const SizedBox(height: AppSizes.spacing12),
        Wrap(
          spacing: AppSizes.spacing8,
          runSpacing: AppSizes.spacing8,
          children: presetColors.map((color) {
            final isSelected =
                appearanceProvider.primaryColor.value == color.value;
            return GestureDetector(
              onTap: () => appearanceProvider.setPrimaryColor(color),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  border: Border.all(
                    color: isSelected
                        ? context.textPrimaryColor
                        : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 24)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomColorPicker(AppearanceProvider appearanceProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Custom Color',
          style: TextStyle(
            fontSize: AppSizes.fontSizeMedium,
            fontWeight: FontWeight.w500,
            color: context.textPrimaryColor,
          ),
        ),
        const SizedBox(height: AppSizes.spacing12),

        if (!_isCustomizing) ...[
          AppButton(
            text: 'Choose Custom Color',
            type: AppButtonType.outline,
            icon: Icon(Icons.palette, size: 18),
            onPressed: () {
              setState(() {
                _isCustomizing = true;
                _selectedColor = appearanceProvider.primaryColor;
              });
            },
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(AppSizes.spacing16),
            decoration: BoxDecoration(
              border: Border.all(color: context.borderColor),
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            ),
            child: Column(
              children: [
                // Color picker would go here - for simplicity, using basic color options
                Text(
                  'Color Picker Implementation',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: AppSizes.spacing16),
                Row(
                  children: [
                    AppButton(
                      text: 'Cancel',
                      type: AppButtonType.outline,
                      onPressed: () {
                        setState(() {
                          _isCustomizing = false;
                          _selectedColor = null;
                        });
                      },
                    ),
                    const SizedBox(width: AppSizes.spacing8),
                    AppButton(
                      text: 'Apply Color',
                      type: AppButtonType.primary,
                      onPressed: _selectedColor != null
                          ? () {
                              appearanceProvider.setPrimaryColor(
                                _selectedColor!,
                              );
                              setState(() {
                                _isCustomizing = false;
                                _selectedColor = null;
                              });
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPreviewSection(AppearanceProvider appearanceProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preview',
              style: TextStyle(
                fontSize: AppSizes.fontSizeLarge,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppSizes.spacing16),
            Text(
              'See how your customizations will look',
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: context.textSecondaryColor,
              ),
            ),
            const SizedBox(height: AppSizes.spacing20),

            // Preview widgets
            _buildPreviewWidgets(appearanceProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewWidgets(AppearanceProvider appearanceProvider) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          // Header preview
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: appearanceProvider.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.widgets, color: Colors.white, size: 20),
              ),
              const SizedBox(width: AppSizes.spacing12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sample Application',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeMedium,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  Text(
                    'With your custom theme',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeSmall,
                      color: context.textSecondaryColor,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacing12,
                  vertical: AppSizes.spacing6,
                ),
                decoration: BoxDecoration(
                  color: appearanceProvider.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                child: Text(
                  'Active',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeSmall,
                    color: appearanceProvider.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing16),

          // Button previews
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appearanceProvider.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Primary Button'),
                ),
              ),
              const SizedBox(width: AppSizes.spacing8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: appearanceProvider.primaryColor,
                    side: BorderSide(color: appearanceProvider.primaryColor),
                  ),
                  child: const Text('Outlined Button'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AppearanceProvider appearanceProvider) {
    return Row(
      children: [
        AppButton(
          text: 'Reset All',
          type: AppButtonType.outline,
          onPressed: () {
            appearanceProvider.resetToDefaultColor();
            setState(() {
              _selectedColor = null;
              _isCustomizing = false;
            });
          },
        ),
        const SizedBox(width: AppSizes.spacing12),
        AppButton(
          text: 'Save Changes',
          type: AppButtonType.primary,
          onPressed: () {
            // Save preferences
            appearanceProvider.savePreferences();
            AppToast.showInfo(
              context,
              message: 'Appearance settings saved!',

              //  backgroundColor: appearanceProvider.primaryColor,
            );
            // );
          },
        ),
      ],
    );
  }
}
