import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mdms_clone/presentation/widgets/common/app_lottie_state_widget.dart';
import 'package:provider/provider.dart';
import '../../../core/services/tenant_service.dart';
import '../../../core/models/tenant.dart';
import '../../../presentation/themes/app_theme.dart';
import 'app_toast.dart';

class TenantDropdownButton extends StatefulWidget {
  const TenantDropdownButton({super.key});

  @override
  State<TenantDropdownButton> createState() => _TenantDropdownButtonState();
}

class _TenantDropdownButtonState extends State<TenantDropdownButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<TenantService>(
      builder: (context, tenantService, child) {
        final currentTenant = tenantService.currentTenant;
        final tenantName = currentTenant?.tenant ?? 'No Organizations';

        return Container(
          margin: const EdgeInsets.only(right: 12),
          child: PopupMenuButton<String>(
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: context.surfaceColor,
            onSelected: (value) {
              // Add haptic feedback for better UX
              HapticFeedback.lightImpact();

              // Handle tenant selection
              final selectedTenant = tenantService.allTenants.firstWhere(
                (tenant) => tenant.tenantId == value,
              );
              _switchTenant(context, tenantService, selectedTenant);
            },
            itemBuilder: (context) => [
              // Header
              PopupMenuItem<String>(
                enabled: false,
                height: 60,
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Switch Organizations',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select a Organizations to switch to',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const PopupMenuDivider(),

              // Tenant List with scroll for more than 3 items
              if (tenantService.isLoading)
                PopupMenuItem<String>(
                  enabled: false,
                  child: Center(
                    child: AppLottieStateWidget.loading(lottieSize: 50),
                  ),
                )
              else if (tenantService.error != null)
                PopupMenuItem<String>(
                  enabled: false,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Error loading Organizations',
                      style: TextStyle(color: context.errorColor, fontSize: 14),
                    ),
                  ),
                )
              else if (tenantService.allTenants.length <= 3)
                // Show all tenants if 3 or fewer
                ...tenantService.allTenants.map(
                  (tenant) => PopupMenuItem<String>(
                    value: tenant.tenantId,
                    child: _buildTenantItem(
                      context,
                      tenant,
                      currentTenant?.tenantId == tenant.tenantId,
                    ),
                  ),
                )
              else
                // Show scrollable container if more than 3 tenants
                PopupMenuItem<String>(
                  enabled: false,
                  padding: EdgeInsets.zero,
                  child: Container(
                    width: 280,
                    height: 200, // Show ~3 items (65px each)
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: context.borderColor.withOpacity(0.3),
                        width: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Scrollbar(
                      thumbVisibility: true,
                      thickness: 3,
                      radius: const Radius.circular(2),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          children: tenantService.allTenants
                              .map(
                                (tenant) => Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      Navigator.pop(context);
                                      _switchTenant(
                                        context,
                                        tenantService,
                                        tenant,
                                      );
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      child: _buildTenantItem(
                                        context,
                                        tenant,
                                        currentTenant?.tenantId ==
                                            tenant.tenantId,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _isHovered
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : context.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isHovered
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                        : context.borderColor.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: _isHovered
                      ? [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified,
                      size: 16,
                      color: _isHovered
                          ? Theme.of(context).colorScheme.primary
                          : context.successColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tenantName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _isHovered
                            ? Theme.of(context).colorScheme.primary
                            : context.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: _isHovered
                          ? Theme.of(context).colorScheme.primary
                          : context.textSecondaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTenantItem(
    BuildContext context,
    Tenant tenant,
    bool isSelected,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tenant.tenant,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
    );
  }

  Future<void> _switchTenant(
    BuildContext context,
    TenantService tenantService,
    Tenant tenant,
  ) async {
    try {
      // Show loading toast
      AppToast.showInfo(context, message: 'Switching to ${tenant.tenant}...');

      final success = await tenantService.switchTenant(tenant.tenantId);

      if (success) {
        // Wait for state to propagate
        await Future.delayed(const Duration(milliseconds: 300));

        // Show success toast - stay on current page
        AppToast.showSuccess(
          context,
          message: 'Successfully switched to ${tenant.tenant}',
        );
      } else {
        AppToast.showError(
          context,
          error: tenantService.error ?? 'Failed to switch tenant',
        );
      }
    } catch (e) {
      AppToast.showError(context, error: 'Error switching tenant: $e');
    }
  }
}
