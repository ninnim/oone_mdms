// Example Usage of New Reusable Widgets
// 
// This file demonstrates how to use the new reusable widgets:
// 1. AppToast - Animated toast messages
// 2. AppConfirmDialog - Confirmation dialogs  
// 3. AppTabsWidget & AppPillTabs - Custom tab styles
//
// All widgets use centralized constants from AppColors and AppSizes

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/app_confirm_dialog.dart';
import '../../widgets/common/app_tabs.dart';
import '../../widgets/common/app_button.dart';

// ===============================================
// 1. TOAST USAGE EXAMPLES
// ===============================================

class ToastExamples {
  // Success Toast
  static void showSuccessToast(BuildContext context) {
    AppToast.showSuccess(
      context,
      title: 'Success',
      message: 'Operation completed successfully!',
    );
  }

  // Error Toast
  static void showErrorToast(BuildContext context) {
    AppToast.showError(
      context,
      title: 'Error',
      message: 'Something went wrong. Please try again.',
    );
  }

  // Warning Toast
  static void showWarningToast(BuildContext context) {
    AppToast.showWarning(
      context,
      title: 'Warning',
      message: 'This action cannot be undone.',
    );
  }

  // Info Toast
  static void showInfoToast(BuildContext context) {
    AppToast.showInfo(
      context,
      title: 'Information',
      message: 'Here is some useful information.',
    );
  }

  // Custom Duration Toast
  static void showCustomDurationToast(BuildContext context) {
    AppToast.show(
      context,
      title: 'Custom',
      message: 'This toast will stay for 6 seconds',
      type: ToastType.info,
      duration: const Duration(seconds: 6),
    );
  }
}

// ===============================================
// 2. CONFIRM DIALOG USAGE EXAMPLES
// ===============================================

class ConfirmDialogExamples {
  // Delete Confirmation
  static Future<void> showDeleteConfirmation(BuildContext context) async {
    final result = await AppConfirmDialog.show(
      context,
      title: 'Delete Item',
      message: 'Are you sure you want to delete this item? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      confirmType: AppButtonType.danger,
      icon: Icons.delete_outline,
    );

    if (result == true && context.mounted) {
      ToastExamples.showSuccessToast(context);
    }
  }

  // Save Changes Confirmation
  static Future<void> showSaveConfirmation(BuildContext context) async {
    final result = await AppConfirmDialog.show(
      context,
      title: 'Save Changes',
      message: 'Do you want to save your changes before leaving?',
      confirmText: 'Save',
      cancelText: 'Discard',
      confirmType: AppButtonType.primary,
      icon: Icons.save_outlined,
    );

    if (result == true && context.mounted) {
      ToastExamples.showSuccessToast(context);
    }
  }

  // Logout Confirmation
  static Future<void> showLogoutConfirmation(BuildContext context) async {
    final result = await AppConfirmDialog.show(
      context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmText: 'Logout',
      cancelText: 'Stay',
      confirmType: AppButtonType.secondary,
      icon: Icons.logout,
    );

    if (result == true && context.mounted) {
      ToastExamples.showInfoToast(context);
    }
  }
}

// ===============================================
// 3. TABS USAGE EXAMPLES
// ===============================================

// Standard Tab Widget Example
class StandardTabsExample extends StatelessWidget {
  const StandardTabsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return AppTabsWidget(
      tabs: [
        AppTab(
          label: 'Overview',
          icon: const Icon(Icons.dashboard, size: AppSizes.iconSmall),
          content: const Center(
            child: Text(
              'Overview Content',
              style: TextStyle(
                fontSize: AppSizes.fontSizeLarge,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        AppTab(
          label: 'Details',
          icon: const Icon(Icons.info, size: AppSizes.iconSmall),
          content: const Center(
            child: Text(
              'Details Content',
              style: TextStyle(
                fontSize: AppSizes.fontSizeLarge,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        AppTab(
          label: 'Settings',
          icon: const Icon(Icons.settings, size: AppSizes.iconSmall),
          content: const Center(
            child: Text(
              'Settings Content',
              style: TextStyle(
                fontSize: AppSizes.fontSizeLarge,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
      onTabChanged: (index) {
        print('Tab changed to index: $index');
      },
    );
  }
}

// Pill-style Tabs Example
class PillTabsExample extends StatelessWidget {
  const PillTabsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPillTabs(
      tabs: [
        AppTab(
          label: 'Dashboard',
          icon: const Icon(Icons.dashboard, size: AppSizes.iconSmall, color: Colors.white),
          content: Container(
            padding: EdgeInsets.all(AppSizes.spacing16),
            child: const Text(
              'Dashboard Content with custom styling',
              style: TextStyle(
                fontSize: AppSizes.fontSizeMedium,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        AppTab(
          label: 'Analytics',
          icon: const Icon(Icons.analytics, size: AppSizes.iconSmall, color: Colors.white),
          content: Container(
            padding: EdgeInsets.all(AppSizes.spacing16),
            child: const Text(
              'Analytics Content with charts and graphs',
              style: TextStyle(
                fontSize: AppSizes.fontSizeMedium,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        AppTab(
          label: 'Reports',
          icon: const Icon(Icons.assessment, size: AppSizes.iconSmall, color: Colors.white),
          content: Container(
            padding: EdgeInsets.all(AppSizes.spacing16),
            child: const Text(
              'Reports Content with data tables',
              style: TextStyle(
                fontSize: AppSizes.fontSizeMedium,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
      onTabChanged: (index) {
        print('Pill tab changed to index: $index');
      },
      // Custom colors
      selectedColor: AppColors.primary,
      unselectedColor: Colors.transparent,
      selectedTextColor: AppColors.onPrimary,
      unselectedTextColor: AppColors.textSecondary,
    );
  }
}

// ===============================================
// 4. INTEGRATION EXAMPLE - HOW TO USE IN EXISTING SCREENS
// ===============================================

class IntegrationExample extends StatelessWidget {
  const IntegrationExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Widget Integration Example'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'New Reusable Widgets Demo',
              style: TextStyle(
                fontSize: AppSizes.fontSizeXXLarge,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppSizes.spacing16),

            // Toast Buttons
            Text(
              'Toast Messages:',
              style: TextStyle(
                fontSize: AppSizes.fontSizeLarge,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppSizes.spacing8),
            Wrap(
              spacing: AppSizes.spacing8,
              runSpacing: AppSizes.spacing8,
              children: [
                AppButton(
                  text: 'Success',
                  type: AppButtonType.primary,
                  size: AppButtonSize.small,
                  onPressed: () => ToastExamples.showSuccessToast(context),
                ),
                AppButton(
                  text: 'Error',
                  type: AppButtonType.danger,
                  size: AppButtonSize.small,
                  onPressed: () => ToastExamples.showErrorToast(context),
                ),
                AppButton(
                  text: 'Warning',
                  type: AppButtonType.secondary,
                  size: AppButtonSize.small,
                  onPressed: () => ToastExamples.showWarningToast(context),
                ),
                AppButton(
                  text: 'Info',
                  type: AppButtonType.outline,
                  size: AppButtonSize.small,
                  onPressed: () => ToastExamples.showInfoToast(context),
                ),
              ],
            ),
            SizedBox(height: AppSizes.spacing24),

            // Dialog Buttons
            Text(
              'Confirmation Dialogs:',
              style: TextStyle(
                fontSize: AppSizes.fontSizeLarge,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppSizes.spacing8),
            Wrap(
              spacing: AppSizes.spacing8,
              runSpacing: AppSizes.spacing8,
              children: [
                AppButton(
                  text: 'Delete',
                  type: AppButtonType.danger,
                  size: AppButtonSize.small,
                  onPressed: () => ConfirmDialogExamples.showDeleteConfirmation(context),
                ),
                AppButton(
                  text: 'Save',
                  type: AppButtonType.primary,
                  size: AppButtonSize.small,
                  onPressed: () => ConfirmDialogExamples.showSaveConfirmation(context),
                ),
                AppButton(
                  text: 'Logout',
                  type: AppButtonType.outline,
                  size: AppButtonSize.small,
                  onPressed: () => ConfirmDialogExamples.showLogoutConfirmation(context),
                ),
              ],
            ),
            SizedBox(height: AppSizes.spacing24),

            // Tabs Example
            Text(
              'Custom Tabs:',
              style: TextStyle(
                fontSize: AppSizes.fontSizeLarge,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppSizes.spacing8),
            Expanded(
              child: const PillTabsExample(),
            ),
          ],
        ),
      ),
    );
  }
}

// ===============================================
// 5. HOW TO ADD TO EXISTING DEVICE SCREENS
// ===============================================

/*
// Example: Adding toast notifications to device actions
class DeviceActionExamples {
  static Future<void> deleteDevice(BuildContext context, Device device) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Delete Device',
      message: 'Are you sure you want to delete device "${device.serialNumber}"?',
      confirmText: 'Delete',
      confirmType: AppButtonType.danger,
      icon: Icons.delete_outline,
    );

    if (confirmed == true && context.mounted) {
      try {
        // Call your delete service
        await DeviceService().deleteDevice(device.id);
        
        AppToast.showSuccess(
          context,
          title: 'Success',
          message: 'Device deleted successfully',
        );
      } catch (e) {
        AppToast.showError(
          context,
          title: 'Error',
          message: 'Failed to delete device: $e',
        );
      }
    }
  }

  static Future<void> linkDevice(BuildContext context, Device device) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Link Device to HES',
      message: 'Link device "${device.serialNumber}" to the Head End System?',
      confirmText: 'Link',
      confirmType: AppButtonType.primary,
      icon: Icons.link,
    );

    if (confirmed == true && context.mounted) {
      try {
        // Call your link service
        await DeviceService().linkToHes(device.id);
        
        AppToast.showSuccess(
          context,
          title: 'Success',
          message: 'Device linked to HES successfully',
        );
      } catch (e) {
        AppToast.showError(
          context,
          title: 'Error',
          message: 'Failed to link device: $e',
        );
      }
    }
  }
}

// Example: Using custom tabs in device details screen
class DeviceDetailsTabsExample extends StatelessWidget {
  final Device device;
  
  const DeviceDetailsTabsExample({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return AppTabsWidget(
      tabs: [
        AppTab(
          label: 'Overview',
          icon: const Icon(Icons.info_outline, size: AppSizes.iconSmall),
          content: DeviceOverviewTab(device: device),
        ),
        AppTab(
          label: 'Metrics',
          icon: const Icon(Icons.analytics, size: AppSizes.iconSmall),
          content: DeviceMetricsTab(device: device),
        ),
        AppTab(
          label: 'Channels',
          icon: const Icon(Icons.settings_input_component, size: AppSizes.iconSmall),
          content: DeviceChannelsTab(device: device),
        ),
        AppTab(
          label: 'Billing',
          icon: const Icon(Icons.receipt_long, size: AppSizes.iconSmall),
          content: DeviceBillingTab(device: device),
        ),
        AppTab(
          label: 'Location',
          icon: const Icon(Icons.location_on, size: AppSizes.iconSmall),
          content: DeviceLocationTab(device: device),
        ),
      ],
      onTabChanged: (index) {
        // Track tab navigation for analytics
        print('Device details tab changed to: $index');
      },
    );
  }
}
*/
