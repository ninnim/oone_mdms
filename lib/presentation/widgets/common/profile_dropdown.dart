import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mdms_clone/presentation/widgets/common/app_toast.dart';
import 'package:provider/provider.dart';
import '../../../core/services/keycloak_service.dart';
import '../../../core/services/tenant_service.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/models/tenant.dart';
import '../../../presentation/themes/app_theme.dart';

class ProfileDropdown extends StatefulWidget {
  final Function(String) onNavigate;
  final Function() onSignOut;

  const ProfileDropdown({
    super.key,
    required this.onNavigate,
    required this.onSignOut,
  });

  @override
  State<ProfileDropdown> createState() => _ProfileDropdownState();
}

class _ProfileDropdownState extends State<ProfileDropdown> {
  bool _showTenantDropdown = false;
  bool _isTenantSectionHovered = false;
  String? _lastTenantId;

  @override
  void initState() {
    super.initState();
    // Initialize tenant service if not already done
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tenantService = context.read<TenantService>();
      if (tenantService.currentUserResponse == null) {
        tenantService.initialize();
      }
      _lastTenantId = tenantService.currentTenant?.tenantId;
    });
  }

  @override
  void didUpdateWidget(ProfileDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Force rebuild when widget updates
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<KeycloakService, TenantService, ThemeProvider>(
      builder: (context, keycloakService, tenantService, themeProvider, child) {
        final user = keycloakService.currentUser ?? {};
        final userName = user['name'] ?? user['preferred_username'] ?? 'User';
        final userEmail =
            user['email'] ?? user['preferred_username'] ?? 'user@domain.com';
        final userInitials = _getUserInitials(userName);
        final currentTenantName = _getTenantDisplayName(tenantService);

        // Check if tenant changed and force rebuild
        final currentTenantId = tenantService.currentTenant?.tenantId;
        if (currentTenantId != _lastTenantId && currentTenantId != null) {
          _lastTenantId = currentTenantId;
          // Close tenant dropdown if it was open
          if (_showTenantDropdown) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _showTenantDropdown = false;
                });
              }
            });
          }
        }

        return PopupMenuButton<String>(
          offset: const Offset(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: context.surfaceColor,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  userInitials,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_down,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
                size: 16,
              ),
            ],
          ),
          itemBuilder: (context) => [
            // User Profile Header
            PopupMenuItem<String>(
              enabled: false,
              height: 80,
              child: Container(
                width: 320, // Increased width for better tenant display
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        userInitials,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            userName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userEmail,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified,
                                  size: 12,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  currentTenantName,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const PopupMenuDivider(),

            // Theme Mode Selection
            PopupMenuItem<String>(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme Mode',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: context.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _ThemeButton(
                        icon: Icons.light_mode,
                        label: 'Light',
                        isSelected:
                            themeProvider.themeMode == AppThemeMode.light,
                        onTap: () {
                          Navigator.of(context).pop(); // Close dropdown first
                          themeProvider.setLightMode();
                        },
                      ),
                      const SizedBox(width: 4),
                      _ThemeButton(
                        icon: Icons.dark_mode,
                        label: 'Dark',
                        isSelected:
                            themeProvider.themeMode == AppThemeMode.dark,
                        onTap: () {
                          Navigator.of(context).pop(); // Close dropdown first
                          themeProvider.setDarkMode();
                        },
                      ),
                      const SizedBox(width: 4),
                      _ThemeButton(
                        icon: Icons.computer,
                        label: 'System',
                        isSelected:
                            themeProvider.themeMode == AppThemeMode.system,
                        onTap: () {
                          Navigator.of(context).pop(); // Close dropdown first
                          themeProvider.setSystemMode();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),

            // Switch Tenant Section with Dropdown
            PopupMenuItem<String>(
              enabled: true,
              value:
                  null, // No value to prevent PopupMenu from closing on this item
              child: StatefulBuilder(
                builder: (context, setMenuState) {
                  return _buildTenantSection(
                    context,
                    tenantService,
                    setMenuState,
                  );
                },
              ),
            ),
            const PopupMenuDivider(),

            // Language
            PopupMenuItem<String>(
              value: 'language',
              child: Row(
                children: [
                  Icon(
                    Icons.language,
                    size: 18,
                    color: context.textSecondaryColor,
                  ),
                  const SizedBox(width: 12),
                  const Text('Language'),
                  const Spacer(),
                  Text(
                    'English',
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Appearance
            PopupMenuItem<String>(
              value: 'appearance',
              child: Row(
                children: [
                  Icon(
                    Icons.palette_outlined,
                    size: 18,
                    color: context.textSecondaryColor,
                  ),
                  const SizedBox(width: 12),
                  const Text('Appearance'),
                ],
              ),
            ),
            const PopupMenuDivider(),

            // Sign Out
            PopupMenuItem<String>(
              value: 'logout',
              child: const Row(
                children: [
                  Icon(Icons.logout, size: 18, color: Color(0xFFdc2626)),
                  SizedBox(width: 12),
                  Text('Sign Out', style: TextStyle(color: Color(0xFFdc2626))),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            switch (value) {
              case 'appearance':
                widget.onNavigate('/appearance');
                break;
              case 'language':
                // TODO: Handle language selection
                break;
              case 'logout':
                widget.onSignOut();
                
                break;
            }
          },
        );
      },
    );
  }

  Widget _buildTenantSection(
    BuildContext context,
    TenantService tenantService,
    StateSetter setMenuState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setMenuState(() {
              _showTenantDropdown = !_showTenantDropdown;
            });
            // Also update the main widget state for consistency
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  // This ensures the main widget state is also updated
                });
              }
            });
            if (_showTenantDropdown && tenantService.allTenants.isEmpty) {
              tenantService.getAllTenants();
            }
          },
          onHover: (isHovered) {
            setMenuState(() {
              _isTenantSectionHovered = isHovered;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: _isTenantSectionHovered
                  ? Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.05)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.apartment,
                  size: 18,
                  color: _isTenantSectionHovered
                      ? Theme.of(context).colorScheme.primary
                      : context.textSecondaryColor,
                ),
                const SizedBox(width: 12),
                Text(
                  'Switch Organizations',
                  style: TextStyle(
                    color: _isTenantSectionHovered
                        ? Theme.of(context).colorScheme.primary
                        : null,
                    fontWeight: _isTenantSectionHovered
                        ? FontWeight.w500
                        : FontWeight.w400,
                  ),
                ),
                const Spacer(),
                Icon(
                  _showTenantDropdown
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 16,
                  color: _isTenantSectionHovered
                      ? Theme.of(context).colorScheme.primary
                      : context.textSecondaryColor,
                ),
              ],
            ),
          ),
        ),
        if (_showTenantDropdown) ...[
          const SizedBox(height: 8),
          if (tenantService.isLoading)
            Center(
              child: Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            )
          else if (tenantService.error != null)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: context.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Error loading Organizations',
                style: TextStyle(color: context.errorColor, fontSize: 12),
              ),
            )
          else
            Container(
              constraints: const BoxConstraints(
                maxHeight: 180,
              ), // Limit to ~3 items
              child: SingleChildScrollView(
                child: Column(
                  children: tenantService.allTenants
                      .map(
                        (tenant) => GestureDetector(
                          onTap: () {
                            _switchTenant(
                              context,
                              tenantService,
                              tenant,
                              setMenuState,
                            );
                          },
                          child: _buildTenantItem(
                            context,
                            tenant,
                            tenantService.currentTenant?.tenantId ==
                                tenant.tenantId,
                            () {
                              _switchTenant(
                                context,
                                tenantService,
                                tenant,
                                setMenuState,
                              );
                            },
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildTenantItem(
    BuildContext context,
    Tenant tenant,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Add haptic feedback for better UX
            HapticFeedback.lightImpact();
            // Call the onTap callback
            onTap();
          },
          borderRadius: BorderRadius.circular(6),
          hoverColor: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: 0.05),
          splashColor: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: 0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                  : null,
              borderRadius: BorderRadius.circular(6),
              border: isSelected
                  ? Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: tenant.status == 'active'
                        ? context.successColor
                        : context.textSecondaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tenant.tenant,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : context.textPrimaryColor,
                        ),
                      ),
                      Text(
                        tenant.type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _switchTenant(
    BuildContext context,
    TenantService tenantService,
    Tenant tenant,
    StateSetter setMenuState,
  ) async {
    try {
      // Close the dropdown immediately
      //   Navigator.of(context).pop();

      // Show loading indicator

      AppToast.showInfo(context, message: 'Switching to ${tenant.tenant}...');

      final success = await tenantService.switchTenant(tenant.tenantId);

      if (success) {
        // Force state update immediately using both state setters
        // if (mounted) {
        //   setState(() {
        //     _showTenantDropdown = false;
        //   });
        // }

        // // Also update the menu state
        // setMenuState(() {
        //   _showTenantDropdown = false;
        // });

        // Wait for state to propagate
        await Future.delayed(const Duration(milliseconds: 300));

        // Navigate to dashboard to ensure clean state refresh
        //widget.onNavigate('/dashboard');

        // Clear any existing snackbars and show success
        //context.mounted
        if (context.mounted) {
          AppToast.showSuccess(
            context,
            message: 'Successfully switched to ${tenant.tenant}',
            //   backgroundColor: context.successColor,
          );
        }
        // ScaffoldMessenger.of(context).clearSnackBars();
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text('Successfully switched to ${tenant.tenant}'),
        //     backgroundColor: context.successColor,
        //     duration: const Duration(seconds: 2),
        //   ),
        // );
      } else {
        AppToast.showError(
          context,
          error: ('Failed to switch Organizations: ${tenantService.error}'),
        );
        // ScaffoldMessenger.of(context).clearSnackBars();
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text('Failed to switch tenant: ${tenantService.error}'),
        //     backgroundColor: context.errorColor,
        //     duration: const Duration(seconds: 3),
        //   ),
        // );
      }
    } catch (e) {
      AppToast.showError(context, error: ('Error switching Organizations: $e'));
      // ScaffoldMessenger.of(context).clearSnackBars();
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Error switching tenant: $e'),
      //     backgroundColor: context.errorColor,
      //     duration: const Duration(seconds: 3),
      //   ),
      // );
    }
  }

  // Display Current tenant
  String _getTenantDisplayName(TenantService tenantService) {
    try {
      return tenantService.currentTenant?.tenant ?? 'MDMS Organizations';
    } catch (e) {
      return 'MDMS Organizations';
    }
  }

  String _getUserInitials(String displayName) {
    final parts = displayName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.length == 1 && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }
}

class _ThemeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: isSelected
                ? Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : context.textSecondaryColor,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : context.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
