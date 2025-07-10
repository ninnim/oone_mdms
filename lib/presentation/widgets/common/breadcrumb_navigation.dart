import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/device.dart';

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
      bool isLast = i == pathSegments.length - 1;

      // Build correct navigation path based on route structure
      String navigationPath = _buildNavigationPath(pathSegments, i);

      breadcrumbs.add(
        BreadcrumbItem(title: title, path: navigationPath, isLast: isLast),
      );
    }

    return Row(
      children: [
        for (int i = 0; i < breadcrumbs.length; i++) ...[
          if (i > 0) ...[
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 16, color: Color(0xFF64748b)),
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
      case 'tou-management':
        return 'TOU Management';
      case 'tickets':
        return 'Tickets';
      case 'analytics':
        return 'Analytics';
      case 'settings':
        return 'Settings';
      case 'details':
        return 'Device Details';
      case 'billing':
        return 'Billing Readings';
      default:
        // For IDs, try to get more context
        if (index > 0) {
          final prevSegment = pathSegments[index - 1];
          if (prevSegment == 'details') {
            // Try to get device serial number from state if available
            final routeState = GoRouterState.of(context);
            final device = routeState.extra as Device?;
            if (device != null) {
              return device.serialNumber.isNotEmpty
                  ? device.serialNumber
                  : 'Device #$segment';
            }
            return 'Device #$segment';
          } else if (prevSegment == 'billing') {
            return 'Billing #$segment';
          }
        }
        return segment.toUpperCase();
    }
  }

  String _buildNavigationPath(List<String> pathSegments, int currentIndex) {
    // Build path up to current index
    List<String> pathParts = pathSegments.sublist(0, currentIndex + 1);

    // Handle different route patterns
    if (pathParts.length == 1 && pathParts[0] == 'devices') {
      return '/devices';
    } else if (pathParts.length >= 3 &&
        pathParts[0] == 'devices' &&
        pathParts[1] == 'details') {
      if (currentIndex == 0) {
        return '/devices';
      } else if (currentIndex == 1) {
        return '/devices';
      } else if (currentIndex == 2) {
        // Device details level - device ID
        return '/devices/details/${pathParts[2]}';
      } else if (pathParts.length >= 4 && pathParts[3] == 'billing') {
        if (currentIndex == 3) {
          // Just the billing segment, go back to device details
          return '/devices/details/${pathParts[2]}';
        } else if (currentIndex >= 4) {
          // Billing ID level
          return '/devices/details/${pathParts[2]}/billing/${pathParts[4]}';
        }
      }
    }

    // Default: build path from segments
    return '/${pathParts.join('/')}';
  }

  Widget _buildBreadcrumbItem(BuildContext context, BreadcrumbItem item) {
    return GestureDetector(
      onTap: item.isLast ? null : () => context.go(item.path),
      child: Text(
        item.title,
        style: TextStyle(
          fontSize: 14, // Reduced from 18 to 14
          fontWeight: FontWeight.w500, // Reduced from w600 to w500
          color: item.isLast
              ? const Color(0xFF1e293b)
              : const Color(0xFF2563eb),
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
