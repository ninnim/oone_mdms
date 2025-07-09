import 'package:flutter/material.dart';
import '../widgets/common/app_sidebar.dart';
import '../widgets/common/app_card.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import 'devices/devices_screen.dart';
import 'device_groups/device_groups_screen.dart';
import 'dashboard/dashboard_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  String _selectedScreen = 'devices'; // Start with devices as per requirements
  bool _sidebarCollapsed = false;

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
      height: AppSizes.appBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Text(
            _getScreenTitle(),
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
        return const DevicesScreen();
      case 'device-groups':
        return const DeviceGroupsScreen();
      case 'tickets':
        return _buildPlaceholderScreen('Tickets');
      case 'analytics':
        return _buildPlaceholderScreen('Analytics');
      case 'settings':
        return _buildPlaceholderScreen('Settings');
      default:
        return const DevicesScreen();
    }
  }

  Widget _buildPlaceholderScreen(String title) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacing24),
      child: AppCard(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.construction, size: 64, color: AppColors.textTertiary),
              const SizedBox(height: AppSizes.spacing16),
              Text(
                '$title Screen',
                style: const TextStyle(
                  fontSize: AppSizes.fontSizeXLarge,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.spacing8),
              Text(
                'This screen is under construction',
                style: const TextStyle(
                  fontSize: AppSizes.fontSizeMedium,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
