import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/device.dart';
import '../../../core/models/device_group.dart';

class BreadcrumbNavigation extends StatelessWidget {
  const BreadcrumbNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.toString();
    final pathSegments = currentLocation
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList();

    List<BreadcrumbItem> breadcrumbs = [];

    for (int i = 0; i < pathSegments.length; i++) {
      final segment = pathSegments[i];

      // Convert path segments to readable names
      String title = _getReadableTitle(context, segment, pathSegments, i);

      // Skip empty titles (IDs we don't want to show)
      if (title.isEmpty) continue;

      // Build correct navigation path based on route structure
      // Use the original path segments and index, not the filtered breadcrumbs
      String navigationPath = _buildNavigationPath(pathSegments, i);

      breadcrumbs.add(
        BreadcrumbItem(title: title, path: navigationPath, isLast: false),
      );
    }

    // Mark the last breadcrumb as last
    if (breadcrumbs.isNotEmpty) {
      breadcrumbs.last = BreadcrumbItem(
        title: breadcrumbs.last.title,
        path: breadcrumbs.last.path,
        isLast: true,
      );
    }

    return Row(
      children: [
        for (int i = 0; i < breadcrumbs.length; i++) ...[
          if (i > 0) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              size: AppSizes.iconSmall,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
          ],
          _buildBreadcrumbItem(context, breadcrumbs[i]),
        ],
      ],
    );
  }

  String _getReadableTitle(
    BuildContext context,
    String segment,
    List<String> pathSegments,
    int index,
  ) {
    switch (segment) {
      case 'devices':
        return 'Devices';
      case 'device-groups':
        return 'Device Groups';
      case 'dashboard':
        return 'Dashboard';
      case 'tou-management':
        return 'TOU Management';
      case 'tickets':
        return 'Tickets';
      case 'analytics':
        return 'Analytics';
      case 'settings':
        return 'Settings';
      case 'details':
        return 'Details';
      case 'billing':
        return 'Billing';
      default:
        // For IDs, check context and return appropriate display name
        if (index > 0 && pathSegments.length > index) {
          final prevSegment = index > 0 ? pathSegments[index - 1] : '';
          final nextSegment = index < pathSegments.length - 1
              ? pathSegments[index + 1]
              : '';

          // Device ID in device details route - don't show ID, return null to skip
          if (prevSegment == 'details' ||
              nextSegment == 'details' ||
              nextSegment == 'billing') {
            // Try to get device serial number from state if available
            final routeState = GoRouterState.of(context);
            final extra = routeState.extra;

            // Check if it's a Device
            if (extra is Device && extra.serialNumber.isNotEmpty) {
              return extra.serialNumber;
            }

            // Check if it's a DeviceGroup - don't show device group name in breadcrumb
            if (extra is DeviceGroup) {
              return '';
            }

            // Don't show raw ID - return null to skip this breadcrumb
            return '';
          }

          // Billing ID in billing route - don't show ID
          if (prevSegment == 'billing') {
            return '';
          }
        }

        // For other segments, capitalize first letter
        if (segment.isNotEmpty) {
          return segment[0].toUpperCase() + segment.substring(1).toLowerCase();
        }

        return segment.toUpperCase();
    }
  }

  String _buildNavigationPath(List<String> pathSegments, int currentIndex) {
    // Special handling for device-related routes
    if (pathSegments.isNotEmpty && pathSegments[0] == 'devices') {
      // If clicking on "Devices" (index 0), always go to devices list
      if (currentIndex == 0) {
        return '/devices';
      }

      // For device details routes like /devices/details/device-id or /devices/details/device-id/billing/billing-id
      if (pathSegments.length >= 3 && pathSegments[1] == 'details') {
        final deviceId = pathSegments[2];

        // If clicking on "Details" (index 1), go to device details
        if (currentIndex == 1) {
          return '/devices/details/$deviceId';
        }

        // If clicking on device ID (index 2), go to device details
        if (currentIndex == 2) {
          return '/devices/details/$deviceId';
        }

        // For billing routes
        if (pathSegments.length >= 4 && pathSegments[3] == 'billing') {
          // If clicking on "Billing" (index 3), go to device details (billing tab will be selected there)
          if (currentIndex == 3) {
            return '/devices/details/$deviceId';
          }

          // If clicking on billing ID (index 4), go to billing details
          if (currentIndex >= 4 && pathSegments.length > 4) {
            final billingId = pathSegments[4];
            return '/devices/details/$deviceId/billing/$billingId';
          }
        }
      }
    }

    // Default fallback: build path from segments
    List<String> pathParts = pathSegments.sublist(0, currentIndex + 1);
    return '/${pathParts.join('/')}';
  }

  Widget _buildBreadcrumbItem(BuildContext context, BreadcrumbItem item) {
    return GestureDetector(
      onTap: item.isLast ? null : () => context.go(item.path),
      child: Text(
        item.title,
        style: TextStyle(
          fontSize: AppSizes.fontSizeMedium,
          fontWeight: FontWeight.w500,
          color: item.isLast ? AppColors.textPrimary : AppColors.primary,
          decoration: item.isLast ? null : TextDecoration.underline,
        ),
      ),
    );
  }
}

class BreadcrumbItem {
  final String title;
  final String path;
  final bool isLast;

  BreadcrumbItem({
    required this.title,
    required this.path,
    required this.isLast,
  });
}
