import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class SidebarDrawer extends StatelessWidget {
  final Widget child;
  final VoidCallback? onClose;
  final double width;
  final bool showCloseButton;

  const SidebarDrawer({
    super.key,
    required this.child,
    this.onClose,
    this.width = 420,
    this.showCloseButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          width: width,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppSizes.radiusMedium),
              bottomLeft: Radius.circular(AppSizes.radiusMedium),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 24,
                offset: const Offset(-8, 0),
              ),
            ],
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: showCloseButton ? 56 : 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                ),
                child: child,
              ),
              if (showCloseButton)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: onClose,
                      tooltip: 'Close sidebar',
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
