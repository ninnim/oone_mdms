import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../themes/app_theme.dart';

enum DialogType { create, edit, view, delete, confirm }

class AppDialogHeader extends StatelessWidget {
  final DialogType type;
  final String title;
  final String? subtitle;
  final VoidCallback? onClose;
  final bool showCloseButton;

  const AppDialogHeader({
    super.key,
    required this.type,
    required this.title,
    this.subtitle,
    this.onClose,
    this.showCloseButton = true,
  });

  @override
  Widget build(BuildContext context) {
    // Use ResponsiveHelper instead of manual MediaQuery
    final isMobile = context.isMobile;
    final isTablet = context.isTablet;

    // Get dialog configuration based on type
    final config = _getDialogConfig(type);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.primaryColor.withValues(alpha: 0.08),
            context.primaryColor.withValues(alpha: 0.02),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: context.borderColor, width: 1.5),
        ),
      ),
      child: Padding(
        padding: ResponsiveHelper.getPadding(context),
        child: Row(
          children: [
            // Dialog Icon with Background
            Container(
              padding: EdgeInsets.all(
                ResponsiveHelper.shouldUseCompactUI(context)
                    ? AppSizes.spacing4
                    : AppSizes.spacing6,
              ),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getCardBorderRadius(context),
                ),
                border: Border.all(
                  color: context.primaryColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                config.icon,
                color: context.primaryColor,
                size: isMobile ? AppSizes.iconSmall : AppSizes.iconMedium,
              ),
            ),

            SizedBox(width: ResponsiveHelper.getSpacing(context)),

            // Title and Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isMobile
                          ? AppSizes.fontSizeSmall
                          : isTablet
                          ? AppSizes.fontSizeMedium
                          : AppSizes.fontSizeLarge,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryColor,
                      letterSpacing: -0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    SizedBox(
                      height: ResponsiveHelper.shouldUseCompactUI(context)
                          ? 2
                          : 4,
                    ),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: isMobile
                            ? AppSizes.fontSizeExtraSmall
                            : AppSizes.fontSizeSmall,
                        fontWeight: FontWeight.w500,
                        color: context.textSecondaryColor,
                        height: 1.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: ResponsiveHelper.shouldUseCompactUI(context)
                          ? 1
                          : 2,
                    ),
                  ],
                ],
              ),
            ),

            // Close Button with Enhanced Styling
            if (showCloseButton) ...[
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: _HoverableCloseButton(
                  onClose: onClose,
                  isMobile: isMobile,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _DialogConfig _getDialogConfig(DialogType type) {
    switch (type) {
      case DialogType.create:
        return _DialogConfig(
          icon: Icons.add_circle_outline,
          defaultSubtitle: 'Create a new item',
        );
      case DialogType.edit:
        return _DialogConfig(
          icon: Icons.edit_outlined,
          defaultSubtitle: 'Modify existing item',
        );
      case DialogType.view:
        return _DialogConfig(
          icon: Icons.visibility_outlined,
          defaultSubtitle: 'View item details',
        );
      case DialogType.delete:
        return _DialogConfig(
          icon: Icons.delete_outline,
          defaultSubtitle: 'Remove item permanently',
        );
      case DialogType.confirm:
        return _DialogConfig(
          icon: Icons.help_outline,
          defaultSubtitle: 'Confirm your action',
        );
    }
  }
}

class _DialogConfig {
  final IconData icon;
  final String defaultSubtitle;

  const _DialogConfig({required this.icon, required this.defaultSubtitle});
}

class _HoverableCloseButton extends StatefulWidget {
  final VoidCallback? onClose;
  final bool isMobile;

  const _HoverableCloseButton({required this.onClose, required this.isMobile});

  @override
  State<_HoverableCloseButton> createState() => _HoverableCloseButtonState();
}

class _HoverableCloseButtonState extends State<_HoverableCloseButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(
          ResponsiveHelper.shouldUseCompactUI(context)
              ? AppSizes.spacing4
              : AppSizes.spacing6,
        ),
        decoration: BoxDecoration(
          color: _isHovered
              ? Theme.of(context).colorScheme.error.withValues(alpha: 0.1)
              : context.surfaceColor,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getCardBorderRadius(context),
          ),
          border: Border.all(
            color: _isHovered
                ? Theme.of(context).colorScheme.error.withValues(alpha: 0.3)
                : context.borderColor,
            width: 1,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.error.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [AppSizes.shadowSmall],
        ),
        child: InkWell(
          onTap: widget.onClose,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getCardBorderRadius(context),
          ),
          splashColor: Theme.of(
            context,
          ).colorScheme.error.withValues(alpha: 0.2),
          highlightColor: Theme.of(
            context,
          ).colorScheme.error.withValues(alpha: 0.15),
          child: Icon(
            Icons.close,
            color: _isHovered
                ? Theme.of(context).colorScheme.error
                : context.textSecondaryColor,
            size: widget.isMobile ? AppSizes.iconSmall : AppSizes.iconMedium,
          ),
        ),
      ),
    );
  }
}
