import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/constants/app_sizes.dart';
// import '../../../core/constants/app_colors.dart';
import '../../themes/app_theme.dart';

class ThemeSwitch extends StatelessWidget {
  final bool showLabel;
  final bool isCompact;

  const ThemeSwitch({super.key, this.showLabel = true, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactSwitch(context);
    }
    return _buildFullSwitch(context);
  }

  Widget _buildCompactSwitch(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return _CustomThemeDropdown(
          currentMode: themeProvider.themeMode,
          onThemeChanged: (mode) => _changeTheme(themeProvider, mode),
        );
      },
    );
  }

  // Separate method to handle theme changes without navigation
  void _changeTheme(ThemeProvider themeProvider, AppThemeMode mode) async {
    try {
      // Only change theme, no navigation or other side effects
      await themeProvider.setThemeMode(mode);
    } catch (e) {
      debugPrint('Theme switch error: $e');
    }
  }

  Widget _buildFullSwitch(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showLabel) ...[
                  Text('Theme', style: AppTextStyles.subtitle(context)),
                  const SizedBox(height: AppSizes.spacing12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: _buildThemeOption(
                        context,
                        themeProvider,
                        AppThemeMode.light,
                        'Light',
                        Icons.light_mode,
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacing8),
                    Expanded(
                      child: _buildThemeOption(
                        context,
                        themeProvider,
                        AppThemeMode.dark,
                        'Dark',
                        Icons.dark_mode,
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacing8),
                    Expanded(
                      child: _buildThemeOption(
                        context,
                        themeProvider,
                        AppThemeMode.system,
                        'System',
                        Icons.brightness_auto,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeProvider themeProvider,
    AppThemeMode mode,
    String label,
    IconData icon,
  ) {
    final isSelected = themeProvider.themeMode == mode;

    return InkWell(
      onTap: () {
        // Direct call - provider handles isolation
        _changeTheme(themeProvider, mode);
      },
      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: AppSizes.spacing12,
          horizontal: AppSizes.spacing8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? context.primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          border: isSelected
              ? Border.all(color: context.primaryColor)
              : Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
        ),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                size: 24,
                color: isSelected
                    ? context.primaryColor
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppSizes.spacing4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? context.primaryColor
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom theme dropdown that prevents navigation issues
class _CustomThemeDropdown extends StatefulWidget {
  final AppThemeMode currentMode;
  final Function(AppThemeMode) onThemeChanged;

  const _CustomThemeDropdown({
    required this.currentMode,
    required this.onThemeChanged,
  });

  @override
  State<_CustomThemeDropdown> createState() => _CustomThemeDropdownState();
}

class _CustomThemeDropdownState extends State<_CustomThemeDropdown> {
  bool _isOpen = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: _isOpen
                ? context.primaryColor.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: Icon(
            _getThemeIcon(widget.currentMode),
            color: context.textPrimaryColor,
            size: 20,
          ),
        ),
      ),
    );
  }

  IconData _getThemeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    setState(() {
      _isOpen = true;
    });

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 140,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 40),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.borderColor.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDropdownItem(
                    AppThemeMode.light,
                    'Light',
                    Icons.light_mode,
                  ),
                  const Divider(height: 1),
                  _buildDropdownItem(
                    AppThemeMode.dark,
                    'Dark',
                    Icons.dark_mode,
                  ),
                  const Divider(height: 1),
                  _buildDropdownItem(
                    AppThemeMode.system,
                    'System',
                    Icons.brightness_auto,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeDropdown() {
    if (mounted) {
      setState(() {
        _isOpen = false;
      });
    }
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildDropdownItem(AppThemeMode mode, String label, IconData icon) {
    final isSelected = widget.currentMode == mode;

    return InkWell(
      onTap: () {
        _closeDropdown();
        // Prevent any navigation by using a simple callback
        widget.onThemeChanged(mode);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? context.primaryColor
                  : context.textSecondaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? context.primaryColor
                      : context.textPrimaryColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check, size: 16, color: context.primaryColor),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _closeDropdown();
    super.dispose();
  }
}
