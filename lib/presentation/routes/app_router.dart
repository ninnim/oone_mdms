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
          ),
          GoRoute(
            path: '/devices/details/:deviceId',
            name: 'device-details',
            builder: (context, state) {
              final deviceId = state.pathParameters['deviceId']!;
              final deviceData = state.extra as Device?;
              return DeviceDetailsRouteWrapper(
                deviceId: deviceId,
                device: deviceData,
              );
            },
          ),
          GoRoute(
            path: '/devices/details/:deviceId/billing/:billingId',
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

          // Settings Routes Group
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsRouteWrapper(),
          ),
          GoRoute(
            path: '/my-details',
            name: 'my-details',
            builder: (context, state) => const SettingsRouteWrapper(),
          ),
          GoRoute(
            path: '/my-profile',
            name: 'my-profile',
            builder: (context, state) => const SettingsRouteWrapper(),
          ),
          GoRoute(
            path: '/security',
            name: 'security',
            builder: (context, state) => const SettingsRouteWrapper(),
          ),
          GoRoute(
            path: '/integrations',
            name: 'integrations',
            builder: (context, state) => const SettingsRouteWrapper(),
          ),
          GoRoute(
            path: '/billing',
            name: 'billing',
            builder: (context, state) => const SettingsRouteWrapper(),
          ),

          // TOU Management Sub-routes
          GoRoute(
            path: '/time-of-use',
            name: 'time-of-use',
            builder: (context, state) => const TouManagementRouteWrapper(),
          ),
          GoRoute(
            path: '/time-bands',
            name: 'time-bands',
            builder: (context, state) => const TouManagementRouteWrapper(),
          ),
          GoRoute(
            path: '/special-days',
            name: 'special-days',
            builder: (context, state) => const TouManagementRouteWrapper(),
          ),
          GoRoute(
            path: '/seasons',
            name: 'seasons',
            builder: (context, state) => const TouManagementRouteWrapper(),
          ),

          // Analytics Sub-routes
          GoRoute(
            path: '/reports',
            name: 'reports',
            builder: (context, state) => const AnalyticsRouteWrapper(),
          ),
          GoRoute(
            path: '/dashboards',
            name: 'dashboards',
            builder: (context, state) => const AnalyticsRouteWrapper(),
          ),
          GoRoute(
            path: '/insights',
            name: 'insights',
            builder: (context, state) => const AnalyticsRouteWrapper(),
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
    // Create a unique identifier for the billing record since it doesn't have an ID field
    // Using TimeOfUseId and StartTime to create a unique identifier
    final timeOfUseId = billingRecord['TimeOfUseId']?.toString() ?? '';
    final startTime = billingRecord['StartTime']?.toString() ?? '';

    // Create a composite billing ID
    String billingId;
    if (timeOfUseId.isNotEmpty && startTime.isNotEmpty) {
      // Create a simple composite ID: timeOfUseId_startTime
      final cleanStartTime = startTime.replaceAll(RegExp(r'[^\w\-]'), '_');
      billingId = '${timeOfUseId}_$cleanStartTime';
    } else {
      // Fallback: try to find any unique identifier
      billingId =
          billingRecord['Id']?.toString() ??
          billingRecord['id']?.toString() ??
          (timeOfUseId.isNotEmpty
              ? timeOfUseId
              : 'record_${DateTime.now().millisecondsSinceEpoch}');
    }

    final url = '/devices/details/${device.id}/billing/$billingId';
    context.go(url);
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
    return DevicesScreen(
      onBreadcrumbUpdate: (breadcrumbs) {
        // Breadcrumbs are now handled by the router system
      },
      onBreadcrumbNavigate: (index) {
        // Navigation handled by breadcrumb widget directly
      },
      onSetBreadcrumbHandler: (handler) {
        // Not needed with router system
      },
      onDeepLinkUpdate: (deviceId, view, {billingId}) {
        // Navigate using GoRouter when device context changes
        if (view == 'details' && deviceId != null) {
          context.go('/devices/details/$deviceId');
        } else if (view == 'billing' && deviceId != null && billingId != null) {
          context.go('/devices/details/$deviceId/billing/$billingId');
        }
      },
      onDeepLinkClear: () {
        // Navigate back to devices list
        context.go('/devices');
      },
    );
  }
}

class DeviceDetailsRouteWrapper extends StatefulWidget {
  final String deviceId;
  final Device? device;

  const DeviceDetailsRouteWrapper({
    super.key,
    required this.deviceId,
    this.device,
  });

  @override
  State<DeviceDetailsRouteWrapper> createState() =>
      _DeviceDetailsRouteWrapperState();
}

class _DeviceDetailsRouteWrapperState extends State<DeviceDetailsRouteWrapper> {
  Device? _device;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.device != null) {
      _device = widget.device;
      _isLoading = false;
    } else {
      _loadDevice();
    }
  }

  Future<void> _loadDevice() async {
    try {
      final deviceService = DeviceService(ApiService());
      final response = await deviceService.getDeviceById(widget.deviceId);

      if (response.success && response.data != null) {
        setState(() {
          _device = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Device not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load device: $e';
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
              Text('Loading device details...'),
            ],
          ),
        ),
      );
    }

    if (_error != null || _device == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text(_error ?? 'Device not found'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/devices'),
                child: Text('Back to Devices'),
              ),
            ],
          ),
        ),
      );
    }

    // Wrap the Device360DetailsScreen in a Scaffold to prevent layout overflow
    return Scaffold(
      body: Device360DetailsScreen(
        device: _device!,
        onBack: () => context.go('/devices'),
        onNavigateToBillingReadings: (device, billingRecord) {
          // Use the updated AppRouter method instead of the old logic
          AppRouter.goToDeviceBillingReadings(context, device, billingRecord);
        },
      ),
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
      // Check both possible data structures: DeviceBilling and Billing
      final billingData =
          billingResponse.data!['DeviceBilling'] ??
          billingResponse.data!['Billing'];
      Map<String, dynamic>? foundBillingRecord;

      if (billingData != null && billingData is List) {
        try {
          foundBillingRecord = billingData.firstWhere((record) {
            // First try to match by original ID fields
            if (record['Id']?.toString() == widget.billingId ||
                record['id']?.toString() == widget.billingId) {
              return true;
            }

            // Then try to match by our composite ID format
            final timeOfUseId = record['TimeOfUseId']?.toString() ?? '';
            final startTime = record['StartTime']?.toString() ?? '';

            if (timeOfUseId.isNotEmpty && startTime.isNotEmpty) {
              final cleanStartTime = startTime.replaceAll(
                RegExp(r'[^\w\-]'),
                '_',
              );
              final compositeId = '${timeOfUseId}_$cleanStartTime';
              if (compositeId == widget.billingId) {
                return true;
              }
            }

            // Also try matching just the TimeOfUseId
            if (timeOfUseId.isNotEmpty && timeOfUseId == widget.billingId) {
              return true;
            }

            return false;
          });
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

    // Wrap in Scaffold to prevent layout issues
    return Scaffold(
      body: DeviceBillingReadingsScreen(
        device: _device!,
        billingRecord: _billingRecord!,
        onBack: () => context.go('/devices/details/${widget.deviceId}'),
      ),
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

// Updated MainLayout to work with routing and hierarchical sidebar
class MainLayoutWithRouter extends StatefulWidget {
  final Widget child;

  const MainLayoutWithRouter({super.key, required this.child});

  @override
  State<MainLayoutWithRouter> createState() => _MainLayoutWithRouterState();
}

class _MainLayoutWithRouterState extends State<MainLayoutWithRouter> {
  bool _sidebarCollapsed = false;

  // Track expanded state for each group
  final Map<String, bool> _expandedGroups = {
    'device-management': false,
    'settings': false,
    'analytics': false,
    'tou-management': false,
  };

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.toString();
    final selectedScreen = _getSelectedScreenFromLocation(currentLocation);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          _buildSidebar(selectedScreen),
          Expanded(
            child: Column(
              children: [
                _buildBreadcrumbHeader(context),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getSelectedScreenFromLocation(String location) {
    if (location.startsWith('/dashboard')) return 'dashboard';
    if (location.startsWith('/devices')) return 'devices';
    if (location.startsWith('/device-groups')) return 'device-groups';
    if (location.startsWith('/tou-management')) return 'tou-management';
    if (location.startsWith('/tickets')) return 'tickets';
    if (location.startsWith('/analytics')) return 'analytics';
    if (location.startsWith('/settings')) return 'settings';

    // TOU Management sub-routes
    if (location.startsWith('/time-of-use')) return 'time-of-use';
    if (location.startsWith('/time-bands')) return 'time-bands';
    if (location.startsWith('/special-days')) return 'special-days';
    if (location.startsWith('/seasons')) return 'seasons';

    // Analytics sub-routes
    if (location.startsWith('/reports')) return 'reports';
    if (location.startsWith('/dashboards')) return 'dashboards';
    if (location.startsWith('/insights')) return 'insights';

    // Settings sub-routes
    if (location.startsWith('/my-details')) return 'my-details';
    if (location.startsWith('/my-profile')) return 'my-profile';
    if (location.startsWith('/security')) return 'security';
    if (location.startsWith('/integrations')) return 'integrations';
    if (location.startsWith('/billing')) return 'billing';

    return 'devices'; // default
  }

  Widget _buildSidebar(String selectedScreen) {
    return Container(
      width: _sidebarCollapsed ? 80 : 280,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(right: BorderSide(color: Color(0xFFE1E5E9), width: 1)),
      ),
      child: Column(
        children: [
          _buildSidebarHeader(),
          Expanded(
            child: _sidebarCollapsed
                ? _buildCollapsedSidebarMenu(selectedScreen)
                : _buildSidebarMenu(selectedScreen),
          ),
          _buildSidebarFooter(),
        ],
      ),
    );
  }

  Widget _buildCollapsedSidebarMenu(String selectedScreen) {
    // Auto-expand groups when their children are selected (same as expanded mode)
    if (['devices', 'device-groups'].contains(selectedScreen)) {
      _expandedGroups['device-management'] = true;
    }
    if ([
      'time-of-use',
      'time-bands',
      'special-days',
      'seasons',
    ].contains(selectedScreen)) {
      _expandedGroups['tou-management'] = true;
    }
    if (['reports', 'dashboards', 'insights'].contains(selectedScreen)) {
      _expandedGroups['analytics'] = true;
    }
    if ([
      'my-details',
      'my-profile',
      'security',
      'integrations',
      'billing',
    ].contains(selectedScreen)) {
      _expandedGroups['settings'] = true;
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      children: [
        // Dashboard
        _buildCollapsedMenuItem(
          'dashboard',
          Icons.dashboard,
          selectedScreen == 'dashboard',
        ),

        const SizedBox(height: 8),

        // Device Management Group
        _buildCollapsedGroupHeader('device-management', Icons.devices, [
          'devices',
          'device-groups',
        ], selectedScreen),

        if (_expandedGroups['device-management'] == true) ...[
          const SizedBox(height: 4),
          _buildCollapsedSubMenuItem(
            'devices',
            Icons.devices_other,
            selectedScreen == 'devices',
          ),
          _buildCollapsedSubMenuItem(
            'device-groups',
            Icons.group_work,
            selectedScreen == 'device-groups',
          ),
        ],

        const SizedBox(height: 8),

        // TOU Management Group
        _buildCollapsedGroupHeader('tou-management', Icons.schedule, [
          'time-of-use',
          'time-bands',
          'special-days',
          'seasons',
        ], selectedScreen),

        if (_expandedGroups['tou-management'] == true) ...[
          const SizedBox(height: 4),
          _buildCollapsedSubMenuItem(
            'time-of-use',
            Icons.access_time,
            selectedScreen == 'time-of-use',
          ),
          _buildCollapsedSubMenuItem(
            'time-bands',
            Icons.timeline,
            selectedScreen == 'time-bands',
          ),
          _buildCollapsedSubMenuItem(
            'special-days',
            Icons.event_note,
            selectedScreen == 'special-days',
          ),
          _buildCollapsedSubMenuItem(
            'seasons',
            Icons.wb_sunny,
            selectedScreen == 'seasons',
          ),
        ],

        const SizedBox(height: 8),

        // Tickets
        _buildCollapsedMenuItem(
          'tickets',
          Icons.support_agent,
          selectedScreen == 'tickets',
          badge: '3',
        ),

        const SizedBox(height: 8),

        // Analytics Group
        _buildCollapsedGroupHeader('analytics', Icons.analytics, [
          'reports',
          'dashboards',
          'insights',
        ], selectedScreen),

        if (_expandedGroups['analytics'] == true) ...[
          const SizedBox(height: 4),
          _buildCollapsedSubMenuItem(
            'reports',
            Icons.description,
            selectedScreen == 'reports',
          ),
          _buildCollapsedSubMenuItem(
            'dashboards',
            Icons.dashboard_customize,
            selectedScreen == 'dashboards',
          ),
          _buildCollapsedSubMenuItem(
            'insights',
            Icons.lightbulb,
            selectedScreen == 'insights',
          ),
        ],

        const SizedBox(height: 8),

        // Settings Group
        _buildCollapsedGroupHeader('settings', Icons.settings, [
          'my-details',
          'my-profile',
          'security',
          'integrations',
          'billing',
        ], selectedScreen),

        if (_expandedGroups['settings'] == true) ...[
          const SizedBox(height: 4),
          _buildCollapsedSubMenuItem(
            'my-details',
            Icons.person,
            selectedScreen == 'my-details',
          ),
          _buildCollapsedSubMenuItem(
            'my-profile',
            Icons.account_circle,
            selectedScreen == 'my-profile',
          ),
          _buildCollapsedSubMenuItem(
            'security',
            Icons.security,
            selectedScreen == 'security',
          ),
          _buildCollapsedSubMenuItem(
            'integrations',
            Icons.integration_instructions,
            selectedScreen == 'integrations',
          ),
          _buildCollapsedSubMenuItem(
            'billing',
            Icons.receipt_long,
            selectedScreen == 'billing',
          ),
        ],
      ],
    );
  }

  Widget _buildCollapsedGroupHeader(
    String groupId,
    IconData icon,
    List<String> childIds,
    String selectedScreen,
  ) {
    final isExpanded = _expandedGroups[groupId] ?? false;
    final hasSelectedChild = childIds.contains(selectedScreen);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _expandedGroups[groupId] = !isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: hasSelectedChild
                  ? const Color(0xFF2563eb).withOpacity(0.15)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: hasSelectedChild
                  ? Border.all(color: const Color(0xFF2563eb).withOpacity(0.3))
                  : Border.all(color: const Color(0xFFE1E5E9)),
              boxShadow: [
                BoxShadow(
                  color: hasSelectedChild
                      ? const Color(0xFF2563eb).withOpacity(0.1)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: hasSelectedChild ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    icon,
                    color: hasSelectedChild
                        ? const Color(0xFF2563eb)
                        : const Color(0xFF64748b),
                    size: 24,
                  ),
                ),
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: hasSelectedChild
                          ? const Color(0xFF2563eb)
                          : const Color(0xFF64748b),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isExpanded ? Icons.remove : Icons.add,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedSubMenuItem(String id, IconData icon, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4, left: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/$id'),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF2563eb).withOpacity(0.15)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: const Color(0xFF2563eb).withOpacity(0.3))
                  : Border.all(color: const Color(0xFFE1E5E9).withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? const Color(0xFF2563eb).withOpacity(0.1)
                      : Colors.black.withOpacity(0.02),
                  blurRadius: isSelected ? 6 : 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF2563eb)
                    : const Color(0xFF64748b),
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedMenuItem(
    String id,
    IconData icon,
    bool isSelected, {
    String? badge,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/$id'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF2563eb).withOpacity(0.15)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: const Color(0xFF2563eb).withOpacity(0.3))
                  : Border.all(color: const Color(0xFFE1E5E9)),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? const Color(0xFF2563eb).withOpacity(0.1)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: isSelected ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    icon,
                    color: isSelected
                        ? const Color(0xFF2563eb)
                        : const Color(0xFF64748b),
                    size: 24,
                  ),
                ),
                if (badge != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFef4444),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE1E5E9), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF2563eb),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.electric_bolt,
              color: Colors.white,
              size: 20,
            ),
          ),
          if (!_sidebarCollapsed) ...[
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'MDMS Clone',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1e293b),
                ),
              ),
            ),
            // const SizedBox(width: 8),
            // Material(
            //   color: Colors.transparent,
            //   child: InkWell(
            //     onTap: () {
            //       setState(() {
            //         _sidebarCollapsed = !_sidebarCollapsed;
            //       });
            //     },
            //     borderRadius: BorderRadius.circular(6),
            //     child: Container(
            //       padding: const EdgeInsets.all(6),
            //       child: const Icon(
            //         Icons.menu_open,
            //         color: Color(0xFF64748b),
            //         size: 18,
            //       ),
            //     ),
            //   ),
            // ),
          ],
          // else ...[
          //   const Spacer(),
          //   Material(
          //     color: Colors.transparent,
          //     child: InkWell(
          //       onTap: () {
          //         setState(() {
          //           _sidebarCollapsed = !_sidebarCollapsed;
          //         });
          //       },
          //       borderRadius: BorderRadius.circular(6),
          //       child: Container(
          //         padding: const EdgeInsets.all(6),
          //         child: const Icon(
          //           Icons.menu,
          //           color: Color(0xFF64748b),
          //           size: 18,
          //         ),
          //       ),
          //     ),
          //   ),
          // ],
        ],
      ),
    );
  }

  Widget _buildSidebarMenu(String selectedScreen) {
    // Auto-expand groups when their children are selected
    if (['devices', 'device-groups'].contains(selectedScreen)) {
      _expandedGroups['device-management'] = true;
    }
    if ([
      'time-of-use',
      'time-bands',
      'special-days',
      'seasons',
    ].contains(selectedScreen)) {
      _expandedGroups['tou-management'] = true;
    }
    if (['reports', 'dashboards', 'insights'].contains(selectedScreen)) {
      _expandedGroups['analytics'] = true;
    }
    if ([
      'my-details',
      'my-profile',
      'security',
      'integrations',
      'billing',
    ].contains(selectedScreen)) {
      _expandedGroups['settings'] = true;
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      children: [
        // Dashboard
        _buildMenuItem(
          'dashboard',
          'Dashboard',
          Icons.dashboard,
          selectedScreen == 'dashboard',
        ),

        const SizedBox(height: 8),

        // Device Management Group
        _buildGroupHeader(
          'device-management',
          'Device Management',
          Icons.devices,
          ['devices', 'device-groups'],
          selectedScreen,
        ),

        if (_expandedGroups['device-management'] == true) ...[
          _buildSubMenuWithConnector([
            _buildSubMenuItem(
              'devices',
              'Devices',
              Icons.devices_other,
              selectedScreen == 'devices',
            ),
            _buildSubMenuItem(
              'device-groups',
              'Device Groups',
              Icons.group_work,
              selectedScreen == 'device-groups',
            ),
          ]),
        ],

        const SizedBox(height: 8),

        // TOU Management Group
        _buildGroupHeader('tou-management', 'TOU Management', Icons.schedule, [
          'time-of-use',
          'time-bands',
          'special-days',
          'seasons',
        ], selectedScreen),

        if (_expandedGroups['tou-management'] == true) ...[
          _buildSubMenuWithConnector([
            _buildSubMenuItem(
              'time-of-use',
              'Time of Use',
              Icons.access_time,
              selectedScreen == 'time-of-use',
            ),
            _buildSubMenuItem(
              'time-bands',
              'Time Bands',
              Icons.timeline,
              selectedScreen == 'time-bands',
            ),
            _buildSubMenuItem(
              'special-days',
              'Special Days',
              Icons.event_note,
              selectedScreen == 'special-days',
            ),
            _buildSubMenuItem(
              'seasons',
              'Seasons',
              Icons.wb_sunny,
              selectedScreen == 'seasons',
            ),
          ]),
        ],

        const SizedBox(height: 8),

        // Tickets
        _buildMenuItem(
          'tickets',
          'Tickets',
          Icons.support_agent,
          selectedScreen == 'tickets',
          badge: '3',
        ),

        const SizedBox(height: 8),

        // Analytics Group
        _buildGroupHeader('analytics', 'Analytics', Icons.analytics, [
          'reports',
          'dashboards',
          'insights',
        ], selectedScreen),

        if (_expandedGroups['analytics'] == true) ...[
          _buildSubMenuWithConnector([
            _buildSubMenuItem(
              'reports',
              'Reports',
              Icons.description,
              selectedScreen == 'reports',
            ),
            _buildSubMenuItem(
              'dashboards',
              'Dashboards',
              Icons.dashboard_customize,
              selectedScreen == 'dashboards',
            ),
            _buildSubMenuItem(
              'insights',
              'Insights',
              Icons.lightbulb,
              selectedScreen == 'insights',
            ),
          ]),
        ],

        const SizedBox(height: 8),

        // Settings Group
        _buildGroupHeader('settings', 'Settings', Icons.settings, [
          'my-details',
          'my-profile',
          'security',
          'integrations',
          'billing',
        ], selectedScreen),

        if (_expandedGroups['settings'] == true) ...[
          _buildSubMenuWithConnector([
            _buildSubMenuItem(
              'my-details',
              'My details',
              Icons.person,
              selectedScreen == 'my-details',
            ),
            _buildSubMenuItem(
              'my-profile',
              'My profile',
              Icons.account_circle,
              selectedScreen == 'my-profile',
            ),
            _buildSubMenuItem(
              'security',
              'Security',
              Icons.security,
              selectedScreen == 'security',
            ),
            _buildSubMenuItem(
              'integrations',
              'Integrations',
              Icons.integration_instructions,
              selectedScreen == 'integrations',
            ),
            _buildSubMenuItem(
              'billing',
              'Billing',
              Icons.receipt_long,
              selectedScreen == 'billing',
            ),
          ]),
        ],
      ],
    );
  }

  Widget _buildGroupHeader(
    String groupId,
    String title,
    IconData icon,
    List<String> childIds,
    String selectedScreen,
  ) {
    final isExpanded = _expandedGroups[groupId] ?? false;
    final hasSelectedChild = childIds.contains(selectedScreen);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _expandedGroups[groupId] = !isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(8),
          hoverColor: const Color(0xFF2563eb).withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: hasSelectedChild
                  ? const Color(0xFF2563eb).withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: hasSelectedChild
                  ? Border.all(color: const Color(0xFF2563eb).withOpacity(0.5))
                  : null,
              boxShadow: hasSelectedChild
                  ? [
                      BoxShadow(
                        color: const Color(0xFF2563eb).withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: hasSelectedChild
                      ? const Color(0xFF2563eb)
                      : const Color(0xFF64748b),
                  size: 20,
                ),
                if (!_sidebarCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: hasSelectedChild
                            ? const Color(0xFF2563eb)
                            : const Color(0xFF64748b),
                        fontSize: 14,
                        fontWeight: hasSelectedChild
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: hasSelectedChild
                        ? const Color(0xFF2563eb)
                        : const Color(0xFF64748b),
                    size: 16,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    String id,
    String title,
    IconData icon,
    bool isSelected, {
    String? badge,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/$id'),
          borderRadius: BorderRadius.circular(8),
          hoverColor: const Color(0xFF2563eb).withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF2563eb).withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: const Color(0xFF2563eb).withOpacity(0.5))
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF2563eb).withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? const Color(0xFF2563eb)
                      : const Color(0xFF64748b),
                  size: 20,
                ),
                if (!_sidebarCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF2563eb)
                            : const Color(0xFF64748b),
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
                if (!_sidebarCollapsed && badge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFef4444),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubMenuItem(
    String id,
    String title,
    IconData icon,
    bool isSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/$id'),
          borderRadius: BorderRadius.circular(8),
          hoverColor: const Color(0xFF2563eb).withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF2563eb).withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: const Color(0xFF2563eb).withOpacity(0.5))
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF2563eb).withOpacity(0.1),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? const Color(0xFF2563eb)
                      : const Color(0xFF64748b),
                  size: 16,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF2563eb)
                          : const Color(0xFF64748b),
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubMenuWithConnector(List<Widget> subMenuItems) {
    return Column(
      children: [
        for (int i = 0; i < subMenuItems.length; i++) ...[
          Row(
            children: [
              // Connecting line structure
              const SizedBox(width: 20),
              SizedBox(
                width: 16,
                height: 32,
                child: CustomPaint(
                  painter: ConnectorLinePainter(
                    isLast: i == subMenuItems.length - 1,
                    isFirst: i == 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: subMenuItems[i]),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSidebarFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE1E5E9), width: 1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF2563eb),
            child: Text(
              'A',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (!_sidebarCollapsed) ...[
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin User',
                    style: TextStyle(
                      color: Color(0xFF1e293b),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'admin@mdms.com',
                    style: TextStyle(color: Color(0xFF64748b), fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.more_vert, color: Color(0xFF64748b), size: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildBreadcrumbHeader(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE1E5E9), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row with title and actions
          Row(
            children: [
              // Collapse/Expand Sidebar Button
              IconButton(
                onPressed: () {
                  setState(() {
                    _sidebarCollapsed = !_sidebarCollapsed;
                  });
                },
                icon: Icon(
                  _sidebarCollapsed ? Icons.menu : Icons.menu_open,
                  color: const Color(0xFF64748b),
                ),
                tooltip: _sidebarCollapsed
                    ? 'Expand Sidebar'
                    : 'Collapse Sidebar',
              ),
              const SizedBox(width: 8),
              Text(
                _getPageTitle(currentLocation),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1e293b),
                ),
              ),
              const Spacer(),
              // URL Display
              // Container(
              //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              //   decoration: BoxDecoration(
              //     color: const Color(0xFFF1F5F9),
              //     borderRadius: BorderRadius.circular(6),
              //     border: Border.all(color: const Color(0xFFE1E5E9)),
              //   ),
              //   child: Row(
              //     mainAxisSize: MainAxisSize.min,
              //     children: [
              //       const Icon(Icons.link, size: 16, color: Color(0xFF64748b)),
              //       const SizedBox(width: 6),
              //       Text(
              //         currentLocation,
              //         style: const TextStyle(
              //           fontSize: 12,
              //           color: Color(0xFF64748b),
              //           fontFamily: 'monospace',
              //         ),
              //       ),
              //       const SizedBox(width: 6),
              //       GestureDetector(
              //         onTap: () => _copyUrlToClipboard(context, currentLocation),
              //         child: const Icon(Icons.copy, size: 14, color: Color(0xFF2563eb)),
              //       ),
              //     ],
              //   ),
              // ),
              // const SizedBox(width: 16),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined),
                color: const Color(0xFF64748b),
              ),
              const SizedBox(width: 8),
              // User Avatar with Dropdown
              PopupMenuButton<String>(
                offset: const Offset(0, 40),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF2563eb),
                      child: Text(
                        'A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFF64748b),
                      size: 16,
                    ),
                  ],
                ),
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'appearance',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.palette_outlined,
                          size: 18,
                          color: Color(0xFF64748b),
                        ),
                        const SizedBox(width: 12),
                        const Text('Appearance'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.logout,
                          size: 18,
                          color: Color(0xFFef4444),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Logout',
                          style: TextStyle(color: const Color(0xFFef4444)),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'appearance':
                      // Handle appearance settings
                      context.go('/settings');
                      break;
                    case 'logout':
                      // Handle logout
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Logout functionality will be implemented',
                          ),
                          backgroundColor: Color(0xFF2563eb),
                        ),
                      );
                      break;
                  }
                },
              ),
            ],
          ),
          // Breadcrumb navigation row
          if (_shouldShowBreadcrumbs(currentLocation)) ...[
            const SizedBox(height: 12),
            const BreadcrumbNavigation(),
          ],
        ],
      ),
    );
  }

  String _getPageTitle(String location) {
    if (location.startsWith('/dashboard')) return 'Dashboard';
    if (location.startsWith('/devices')) {
      if (location.contains('/details') && location.contains('/billing')) {
        return 'Device Billing Readings';
      } else if (location.contains('/details')) {
        return 'Device Details';
      }
      return 'Devices';
    }
    if (location.startsWith('/device-groups')) return 'Device Groups';
    if (location.startsWith('/tou-management')) return 'TOU Management';
    if (location.startsWith('/tickets')) return 'Tickets';
    if (location.startsWith('/analytics')) return 'Analytics';
    if (location.startsWith('/settings')) return 'Settings';
    return 'MDMS Clone';
  }

  bool _shouldShowBreadcrumbs(String location) {
    // Show breadcrumbs for detail pages and sub-pages
    return location.contains('/details') ||
        location.contains('/billing') ||
        location.split('/').length > 2;
  }

  // void _copyUrlToClipboard(BuildContext context, String route) {
  //   // Get the full URL with current domain
  //   final fullUrl = 'http://localhost:8088$route';

  //   // Copy to clipboard using Flutter's Clipboard
  //   Clipboard.setData(ClipboardData(text: fullUrl))
  //       .then((_) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Text('URL copied: $fullUrl'),
  //             duration: const Duration(seconds: 2),
  //             backgroundColor: const Color(0xFF10b981),
  //           ),
  //         );
  //       })
  //       .catchError((_) {
  //         // Fallback if clipboard fails
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Text('URL: $fullUrl'),
  //             duration: const Duration(seconds: 3),
  //             backgroundColor: const Color(0xFF2563eb),
  //           ),
  //         );
  //       });
  // }
}

// Custom painter for connecting lines in expandable menu groups
class ConnectorLinePainter extends CustomPainter {
  final bool isLast;
  final bool isFirst;

  ConnectorLinePainter({required this.isLast, required this.isFirst});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    // Draw vertical connecting line (except for last item)
    if (!isLast) {
      canvas.drawLine(
        Offset(centerX, centerY),
        Offset(centerX, size.height),
        paint,
      );
    }

    // Draw vertical line from top (except for first item)
    if (!isFirst) {
      canvas.drawLine(Offset(centerX, 0), Offset(centerX, centerY), paint);
    }

    // Draw horizontal line to menu item
    canvas.drawLine(
      Offset(centerX, centerY),
      Offset(size.width, centerY),
      paint,
    );

    // Draw small circle at connection point
    final circlePaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(centerX, centerY), 2.0, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for hierarchy lines
class HierarchyLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw vertical line
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height / 2),
      paint,
    );

    // Draw horizontal line
    canvas.drawLine(
      Offset(size.width / 2, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
