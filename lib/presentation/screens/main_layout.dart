import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/common/app_sidebar.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import 'devices/devices_screen.dart';
import 'device_groups/device_groups_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'tou_management/tou_management_screen.dart';
import 'settings/settings_screen.dart';
import 'analytics/analytics_screen.dart';
import 'tickets/tickets_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  String _selectedScreen = 'devices'; // Start with devices as per requirements
  bool _sidebarCollapsed = false;
  List<String> _breadcrumbs = []; // Add breadcrumb state
  Function(int)? _currentBreadcrumbNavigateHandler; // Store current handler

  // Deep link state tracking
  String? _currentDeviceId;
  String? _currentBillingId;
  String _currentView = 'list'; // 'list', 'details', 'billing', etc.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          AppSidebar(
            items: SidebarItems.defaultItems,
            selectedItem: _selectedScreen,
            onItemSelected: (itemId) {
              setState(() {
                _selectedScreen = itemId;
                // Clear device context when switching screens
                if (itemId != 'devices') {
                  _clearDeviceContext();
                }
              });
            },
            collapsed: _sidebarCollapsed,
            onToggleCollapse: () {
              setState(() {
                _sidebarCollapsed = !_sidebarCollapsed;
              });
            },
          ),
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          _buildTopBar(),
          Expanded(child: _buildScreen()),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: AppSizes.appBarHeight,
            child: Row(
              children: [
                Text(
                  'dd',
                  // _getScreenTitle(),
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeXLarge,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),

                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_outlined),
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSizes.spacing8),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.search),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          // Breadcrumbs section
          if (_breadcrumbs.isNotEmpty) ...[
            //  const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildBreadcrumbs(),
            ),
          ],
        ],
      ),
    );
  }

  String _getScreenTitle() {
    switch (_selectedScreen) {
      case 'dashboard':
        return 'Dashboard';
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
      default:
        return 'MDMS Clone';
    }
  }

  Widget _buildScreen() {
    switch (_selectedScreen) {
      case 'dashboard':
        return const DashboardScreen();
      case 'devices':
        return DevicesScreen(
          onBreadcrumbUpdate: _updateBreadcrumbs,
          onBreadcrumbNavigate: _onBreadcrumbNavigate,
          onSetBreadcrumbHandler: _setBreadcrumbNavigateHandler,
          onDeepLinkUpdate: _updateDeviceContext,
          onDeepLinkClear: _clearDeviceContext,
        );
      case 'device-groups':
        return const DeviceGroupsScreen();
      case 'tou-management':
        return const TouManagementScreen();
      case 'tickets':
        return const TicketsScreen();
      case 'analytics':
        return const AnalyticsScreen();
      case 'settings':
        return const SettingsScreen();
      default:
        return const DevicesScreen();
    }
  }

  // Method to update breadcrumbs from child screens
  void _updateBreadcrumbs(List<String> breadcrumbs) {
    setState(() {
      _breadcrumbs = breadcrumbs;
    });
  }

  // Method to set the current breadcrumb navigation handler
  void _setBreadcrumbNavigateHandler(Function(int)? handler) {
    _currentBreadcrumbNavigateHandler = handler;
  }

  // Method to handle breadcrumb navigation
  void _onBreadcrumbNavigate(int index) {
    _currentBreadcrumbNavigateHandler?.call(index);
  }

  Widget _buildBreadcrumbs() {
    return Row(
      children: [
        for (int i = 0; i < _breadcrumbs.length; i++) ...[
          if (i > 0) ...[
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 16, color: Color(0xFF64748b)),
            const SizedBox(width: 8),
          ],
          GestureDetector(
            onTap: i == _breadcrumbs.length - 1
                ? null
                : () => _onBreadcrumbNavigate(i),
            child: Text(
              _breadcrumbs[i],
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: i == _breadcrumbs.length - 1
                    ? const Color(0xFF1e293b)
                    : const Color(0xFF2563eb),
                decoration: i == _breadcrumbs.length - 1
                    ? null
                    : TextDecoration.underline,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Method to get current route path
  String _getCurrentUrl() {
    switch (_selectedScreen) {
      case 'dashboard':
        return '/dashboard';

      case 'devices':
        if (_currentDeviceId != null) {
          // Device details page
          if (_currentView == 'details') {
            return '/devices/$_currentDeviceId/details';
          } else if (_currentView == 'billing' && _currentBillingId != null) {
            // Billing details page
            return '/devices/$_currentDeviceId/billing/$_currentBillingId';
          }
        }
        // Default devices list
        return '/devices';

      case 'device-groups':
        return '/device-groups';

      case 'tou-management':
        return '/tou-management';

      case 'tickets':
        return '/tickets';

      case 'analytics':
        return '/analytics';

      case 'settings':
        return '/settings';

      default:
        return '/devices';
    }
  }

  // Method to copy URL to clipboard
  void _copyUrlToClipboard() async {
    final url = _getCurrentUrl();

    try {
      await Clipboard.setData(ClipboardData(text: url));

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deep link copied: $url'),
            duration: const Duration(seconds: 3),
            backgroundColor: const Color(0xFF10b981),
          ),
        );
      }
    } catch (e) {
      // Fallback if clipboard fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('URL: $url'),
            duration: const Duration(seconds: 4),
            backgroundColor: const Color(0xFF2563eb),
          ),
        );
      }
    }
  }

  // Methods to update deep link context
  void _updateDeviceContext(
    String? deviceId,
    String view, {
    String? billingId,
  }) {
    setState(() {
      _currentDeviceId = deviceId;
      _currentView = view;
      _currentBillingId = billingId;
    });
  }

  void _clearDeviceContext() {
    setState(() {
      _currentDeviceId = null;
      _currentBillingId = null;
      _currentView = 'list';
    });
  }
}
