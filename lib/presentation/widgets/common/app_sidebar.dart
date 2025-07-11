import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class AppSidebar extends StatefulWidget {
  final List<SidebarItem> items;
  final String? selectedItem;
  final Function(String)? onItemSelected;
  final bool collapsed;
  final VoidCallback? onToggleCollapse;

  const AppSidebar({
    super.key,
    required this.items,
    this.selectedItem,
    this.onItemSelected,
    this.collapsed = false,
    this.onToggleCollapse,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  // Track expanded state for each group
  final Map<String, bool> _expandedGroups = {
    'device-management':
        true, // Start expanded by default since 'devices' is selected
  };

  @override
  void initState() {
    super.initState();
    // Auto-expand groups that contain the selected item
    _updateExpandedGroupsForSelection();
  }

  @override
  void didUpdateWidget(AppSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedItem != widget.selectedItem) {
      _updateExpandedGroupsForSelection();
    }
  }

  void _updateExpandedGroupsForSelection() {
    // Auto-expand Device Management if devices or device-groups is selected
    if (widget.selectedItem == 'devices' ||
        widget.selectedItem == 'device-groups') {
      setState(() {
        _expandedGroups['device-management'] = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.collapsed
          ? AppSizes.sidebarCollapsedWidth
          : AppSizes.sidebarWidth,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBg,
        border: Border(right: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildMenuItems()),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
            child: const Icon(
              Icons.dashboard,
              color: AppColors.textInverse,
              size: AppSizes.iconMedium,
            ),
          ),
          if (!widget.collapsed) ...[
            const SizedBox(width: AppSizes.spacing12),
            const Expanded(
              child: Text(
                'MDMS Clone',
                style: TextStyle(
                  color: AppColors.sidebarTextActive,
                  fontSize: AppSizes.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          if (widget.onToggleCollapse != null)
            IconButton(
              onPressed: widget.onToggleCollapse,
              icon: Icon(
                widget.collapsed ? Icons.menu : Icons.menu_open,
                color: AppColors.sidebarText,
                size: AppSizes.iconMedium,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuItems() {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing8,
        vertical: AppSizes.spacing16,
      ),
      children: [
        // Dashboard
        Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.spacing4),
          child: _buildMenuItem(
            SidebarItem(
              id: 'dashboard',
              title: 'Dashboard',
              icon: Icons.dashboard,
            ),
            widget.selectedItem == 'dashboard',
          ),
        ),

        // Device Management Group
        _buildGroupHeader(
          'device-management',
          'Device Management',
          Icons.devices,
          ['devices', 'device-groups'],
        ),

        if (_expandedGroups['device-management'] == true) ...[
          _buildSubMenuItem(
            SidebarItem(
              id: 'devices',
              title: 'Devices',
              icon: Icons.devices_other,
            ),
            widget.selectedItem == 'devices',
          ),
          _buildSubMenuItem(
            SidebarItem(
              id: 'device-groups',
              title: 'Device Groups',
              icon: Icons.group_work,
            ),
            widget.selectedItem == 'device-groups',
          ),
        ],

        // TOU Management
        Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.spacing4),
          child: _buildMenuItem(
            SidebarItem(
              id: 'tou-management',
              title: 'TOU Management',
              icon: Icons.schedule,
            ),
            widget.selectedItem == 'tou-management',
          ),
        ),

        // Tickets
        Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.spacing4),
          child: _buildMenuItem(
            SidebarItem(
              id: 'tickets',
              title: 'Tickets',
              icon: Icons.support_agent,
              badge: '3',
            ),
            widget.selectedItem == 'tickets',
          ),
        ),

        // Analytics
        Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.spacing4),
          child: _buildMenuItem(
            SidebarItem(
              id: 'analytics',
              title: 'Analytics',
              icon: Icons.analytics,
            ),
            widget.selectedItem == 'analytics',
          ),
        ),

        // Settings
        Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.spacing4),
          child: _buildMenuItem(
            SidebarItem(
              id: 'settings',
              title: 'Settings',
              icon: Icons.settings,
            ),
            widget.selectedItem == 'settings',
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(SidebarItem item, bool isSelected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onItemSelected?.call(item.id),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacing12,
            vertical: AppSizes.spacing12,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            border: isSelected
                ? Border.all(color: AppColors.primary.withOpacity(0.3))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                color: isSelected ? AppColors.primary : AppColors.sidebarText,
                size: AppSizes.iconMedium,
              ),
              if (!widget.collapsed) ...[
                const SizedBox(width: AppSizes.spacing12),
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.sidebarText,
                      fontSize: AppSizes.fontSizeMedium,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
              if (!widget.collapsed && item.badge != null) ...[
                const SizedBox(width: AppSizes.spacing8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing8,
                    vertical: AppSizes.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  ),
                  child: Text(
                    item.badge!,
                    style: const TextStyle(
                      color: AppColors.textInverse,
                      fontSize: AppSizes.fontSizeSmall,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupHeader(
    String groupId,
    String title,
    IconData icon,
    List<String> childIds,
  ) {
    final isExpanded = _expandedGroups[groupId] ?? false;
    final hasSelectedChild = childIds.contains(widget.selectedItem);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spacing4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _expandedGroups[groupId] = !isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacing12,
              vertical: AppSizes.spacing12,
            ),
            decoration: BoxDecoration(
              color: hasSelectedChild
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              border: hasSelectedChild
                  ? Border.all(color: AppColors.primary.withOpacity(0.3))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: hasSelectedChild
                      ? AppColors.primary
                      : AppColors.sidebarText,
                  size: AppSizes.iconMedium,
                ),
                if (!widget.collapsed) ...[
                  const SizedBox(width: AppSizes.spacing12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: hasSelectedChild
                            ? AppColors.primary
                            : AppColors.sidebarText,
                        fontSize: AppSizes.fontSizeMedium,
                        fontWeight: hasSelectedChild
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.spacing8),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: hasSelectedChild
                        ? AppColors.primary
                        : AppColors.sidebarText,
                    size: AppSizes.iconSmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubMenuItem(SidebarItem item, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spacing4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onItemSelected?.call(item.id),
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          child: Container(
            margin: EdgeInsets.only(
              left: widget.collapsed ? 0 : AppSizes.spacing24,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacing12,
              vertical: AppSizes.spacing8,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              border: isSelected
                  ? Border.all(color: AppColors.primary.withOpacity(0.3))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: isSelected ? AppColors.primary : AppColors.sidebarText,
                  size: AppSizes.iconSmall,
                ),
                if (!widget.collapsed) ...[
                  const SizedBox(width: AppSizes.spacing12),
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.sidebarText,
                        fontSize: AppSizes.fontSizeSmall,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
                if (!widget.collapsed && item.badge != null) ...[
                  const SizedBox(width: AppSizes.spacing8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.spacing8,
                      vertical: AppSizes.spacing4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    ),
                    child: Text(
                      item.badge!,
                      style: const TextStyle(
                        color: AppColors.textInverse,
                        fontSize: AppSizes.fontSizeSmall,
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

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: Text(
              'A',
              style: const TextStyle(
                color: AppColors.textInverse,
                fontSize: AppSizes.fontSizeSmall,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (!widget.collapsed) ...[
            const SizedBox(width: AppSizes.spacing12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin User',
                    style: TextStyle(
                      color: AppColors.sidebarTextActive,
                      fontSize: AppSizes.fontSizeSmall,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'admin@mdms.com',
                    style: TextStyle(
                      color: AppColors.sidebarText,
                      fontSize: AppSizes.fontSizeSmall,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.more_vert,
              color: AppColors.sidebarText,
              size: AppSizes.iconSmall,
            ),
          ],
        ],
      ),
    );
  }
}

class SidebarItem {
  final String id;
  final String title;
  final IconData icon;
  final String? badge;

  SidebarItem({
    required this.id,
    required this.title,
    required this.icon,
    this.badge,
  });
}

// Predefined sidebar items
class SidebarItems {
  static List<SidebarItem> get defaultItems => [
    SidebarItem(id: 'dashboard', title: 'Dashboard', icon: Icons.dashboard),
    SidebarItem(id: 'devices', title: 'Devices', icon: Icons.devices),
    SidebarItem(
      id: 'device-groups',
      title: 'Device Groups',
      icon: Icons.group_work,
    ),
    SidebarItem(
      id: 'tou-management',
      title: 'TOU Management',
      icon: Icons.schedule,
    ),
    SidebarItem(
      id: 'tickets',
      title: 'Tickets',
      icon: Icons.support_agent,
      badge: '3',
    ),
    SidebarItem(id: 'analytics', title: 'Analytics', icon: Icons.analytics),
    SidebarItem(id: 'settings', title: 'Settings', icon: Icons.settings),
  ];
}
