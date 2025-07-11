import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/devices/device_360_details_screen.dart';
import '../screens/devices/device_billing_readings_screen.dart';
import '../screens/devices/devices_screen.dart';
import '../widgets/common/breadcrumb_navigation.dart';
import '../../core/models/device.dart';
import '../../core/services/device_service.dart';
import '../../core/services/api_service.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/devices',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return MainLayoutWithRouter(child: child);
        },
        routes: [
          // Dashboard Routes
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardRouteWrapper(),
          ),

          // Device Routes
          GoRoute(
            path: '/devices',
            name: 'devices',
            builder: (context, state) => const DevicesRouteWrapper(),
            routes: [
              GoRoute(
                path: 'details/:deviceId',
                name: 'device-details',
                builder: (context, state) {
                  final deviceId = state.pathParameters['deviceId']!;
                  final deviceData = state.extra as Device?;
                  return DeviceDetailsRouteWrapper(
                    deviceId: deviceId,
                    device: deviceData,
                  );
                },
                routes: [
                  GoRoute(
                    path: 'billing/:billingId',
                    name: 'device-billing-readings',
                    builder: (context, state) {
                      final deviceId = state.pathParameters['deviceId']!;
                      final billingId = state.pathParameters['billingId']!;

                      return DeviceBillingReadingsRouteWrapper(
                        deviceId: deviceId,
                        billingId: billingId,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // Device Groups Routes
          GoRoute(
            path: '/device-groups',
            name: 'device-groups',
            builder: (context, state) => const DeviceGroupsRouteWrapper(),
          ),

          // TOU Management Routes
          GoRoute(
            path: '/tou-management',
            name: 'tou-management',
            builder: (context, state) => const TouManagementRouteWrapper(),
          ),

          // Tickets Routes
          GoRoute(
            path: '/tickets',
            name: 'tickets',
            builder: (context, state) => const TicketsRouteWrapper(),
          ),

          // Analytics Routes
          GoRoute(
            path: '/analytics',
            name: 'analytics',
            builder: (context, state) => const AnalyticsRouteWrapper(),
          ),

          // Settings Routes
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsRouteWrapper(),
          ),
        ],
      ),
    ],
  );

  // Helper methods for navigation
  static void goToDevices(BuildContext context) {
    context.go('/devices');
  }

  static void goToDeviceDetails(BuildContext context, Device device) {
    context.go('/devices/details/${device.id}', extra: device);
  }

  static void goToDeviceBillingReadings(
    BuildContext context,
    Device device,
    Map<String, dynamic> billingRecord,
  ) {
    final billingId =
        billingRecord['Id']?.toString() ??
        billingRecord['id']?.toString() ??
        'unknown';

    context.go('/devices/details/${device.id}/billing/$billingId');
  }

  static void goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    }
  }
}

// Route Wrappers to maintain existing screen functionality
class DashboardRouteWrapper extends StatelessWidget {
  const DashboardRouteWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // We'll update this when we need to implement it
    return const Scaffold(
      body: Center(child: Text('Dashboard Route - To be implemented')),
    );
  }
}

class DevicesRouteWrapper extends StatelessWidget {
  const DevicesRouteWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return DevicesScreenWithRouter();
  }
}

// Wrapper to integrate existing DevicesScreen with routing
class DevicesScreenWithRouter extends StatefulWidget {
  const DevicesScreenWithRouter({super.key});

  @override
  State<DevicesScreenWithRouter> createState() =>
      _DevicesScreenWithRouterState();
}

class _DevicesScreenWithRouterState extends State<DevicesScreenWithRouter> {
  @override
  Widget build(BuildContext context) {
    return const DevicesScreen();
  }
}

class DeviceDetailsRouteWrapper extends StatelessWidget {
  final String deviceId;
  final Device? device;

  const DeviceDetailsRouteWrapper({
    super.key,
    required this.deviceId,
    this.device,
  });

  @override
  Widget build(BuildContext context) {
    if (device == null) {
      // If device is null, we need to fetch it by ID
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Device360DetailsScreen(
      device: device!,
      onBack: () => AppRouter.goToDevices(context),
      onNavigateToBillingReadings: (device, billingRecord) {
        AppRouter.goToDeviceBillingReadings(context, device, billingRecord);
      },
    );
  }
}

class DeviceBillingReadingsRouteWrapper extends StatefulWidget {
  final String deviceId;
  final String billingId;

  const DeviceBillingReadingsRouteWrapper({
    super.key,
    required this.deviceId,
    required this.billingId,
  });

  @override
  State<DeviceBillingReadingsRouteWrapper> createState() =>
      _DeviceBillingReadingsRouteWrapperState();
}

class _DeviceBillingReadingsRouteWrapperState
    extends State<DeviceBillingReadingsRouteWrapper> {
  Device? _device;
  Map<String, dynamic>? _billingRecord;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final deviceService = DeviceService(ApiService());

      // Load device data
      final deviceResponse = await deviceService.getDeviceById(widget.deviceId);
      if (!deviceResponse.success || deviceResponse.data == null) {
        setState(() {
          _error = 'Device not found';
          _isLoading = false;
        });
        return;
      }

      // Load billing data for the device
      final billingResponse = await deviceService.getDeviceBilling(
        widget.deviceId,
      );
      if (!billingResponse.success || billingResponse.data == null) {
        setState(() {
          _error = 'Billing data not found';
          _isLoading = false;
        });
        return;
      }

      // Find the specific billing record by ID
      final billingData = billingResponse.data!['DeviceBilling'];
      Map<String, dynamic>? foundBillingRecord;

      if (billingData != null && billingData is List) {
        try {
          foundBillingRecord = billingData.firstWhere(
            (record) =>
                record['Id']?.toString() == widget.billingId ||
                record['id']?.toString() == widget.billingId,
          );
        } catch (e) {
          // Record not found
        }
      }

      if (foundBillingRecord == null) {
        setState(() {
          _error = 'Billing record not found';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _device = deviceResponse.data;
        _billingRecord = foundBillingRecord;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading billing data...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Error: $_error'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    context.go('/devices/details/${widget.deviceId}'),
                child: Text('Back to Device Details'),
              ),
            ],
          ),
        ),
      );
    }

    if (_device == null || _billingRecord == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/devices/details/${widget.deviceId}');
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    return DeviceBillingReadingsScreen(
      device: _device!,
      billingRecord: _billingRecord!,
      onBack: () => context.go('/devices/details/${widget.deviceId}'),
    );
  }
}

class DeviceGroupsRouteWrapper extends StatelessWidget {
  const DeviceGroupsRouteWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Device Groups Route - To be implemented')),
    );
  }
}

class TouManagementRouteWrapper extends StatelessWidget {
  const TouManagementRouteWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('TOU Management Route - To be implemented')),
    );
  }
}

class TicketsRouteWrapper extends StatelessWidget {
  const TicketsRouteWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Tickets Route - To be implemented')),
    );
  }
}

class AnalyticsRouteWrapper extends StatelessWidget {
  const AnalyticsRouteWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Analytics Route - To be implemented')),
    );
  }
}

class SettingsRouteWrapper extends StatelessWidget {
  const SettingsRouteWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Settings Route - To be implemented')),
    );
  }
}

// Updated MainLayout to work with routing
class MainLayoutWithRouter extends StatelessWidget {
  final Widget child;

  const MainLayoutWithRouter({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Sidebar will be updated to use routing
          _buildSidebar(context),
          Expanded(
            child: Column(
              children: [
                _buildBreadcrumbHeader(context),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    // Simplified sidebar for now - will be enhanced
    return Container(
      width: 250,
      color: const Color(0xFF1e293b),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: const Text(
              'MDMS Clone',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildSidebarItem(context, 'Devices', '/devices', Icons.devices),
          _buildSidebarItem(
            context,
            'Device Groups',
            '/device-groups',
            Icons.group,
          ),
          _buildSidebarItem(
            context,
            'TOU Management',
            '/tou-management',
            Icons.schedule,
          ),
          _buildSidebarItem(context, 'Tickets', '/tickets', Icons.support),
          _buildSidebarItem(
            context,
            'Analytics',
            '/analytics',
            Icons.analytics,
          ),
          _buildSidebarItem(context, 'Settings', '/settings', Icons.settings),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context,
    String title,
    String route,
    IconData icon,
  ) {
    final currentLocation = GoRouterState.of(context).uri.toString();
    final isActive = currentLocation.startsWith(route);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(icon, color: isActive ? Colors.white : Colors.grey),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        selected: isActive,
        selectedTileColor: const Color(0xFF2563eb),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        onTap: () => context.go(route),
      ),
    );
  }

  Widget _buildBreadcrumbHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE1E5E9), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(child: BreadcrumbNavigation()),
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined),
                color: const Color(0xFF64748b),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.search),
                color: const Color(0xFF64748b),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
