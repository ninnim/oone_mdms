import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/device_group.dart';
import '../common/status_chip.dart';
import '../common/kanban_view.dart';

class DeviceGroupKanbanView extends StatelessWidget {
  final List<DeviceGroup> deviceGroups;
  final Function(DeviceGroup) onDeviceGroupSelected;
  final bool isLoading;
  final bool enableDragDrop;
  final bool enablePagination;
  final int itemsPerPage;
  final Function(DeviceGroup, String, String)? onDeviceGroupMoved;

  const DeviceGroupKanbanView({
    super.key,
    required this.deviceGroups,
    required this.onDeviceGroupSelected,
    this.isLoading = false,
    this.enableDragDrop = false, // Disabled by default for device groups
    this.enablePagination = false, // Disable pagination by default as requested
    this.itemsPerPage =
        25, // Default pagination size (not used when pagination disabled)
    this.onDeviceGroupMoved,
  });

  @override
  Widget build(BuildContext context) {
    // Define device group status columns for the kanban board
    final columns = [
      KanbanColumn<DeviceGroup>(
        id: 'Active',
        title: 'Active',
        color: AppColors.success,
        icon: Icons.check_circle,
      ),
      KanbanColumn<DeviceGroup>(
        id: 'Inactive',
        title: 'Inactive',
        color: AppColors.error,
        icon: Icons.cancel,
      ),
    ];

    return KanbanView<DeviceGroup>(
      columns: columns,
      items: deviceGroups,
      cardBuilder: _buildDeviceGroupCard,
      getItemColumn: (group) => group.active == true ? 'Active' : 'Inactive',
      onItemTapped: onDeviceGroupSelected,
      onItemMoved: onDeviceGroupMoved,
      enableDragDrop: enableDragDrop,
      enablePagination: enablePagination,
      itemsPerPage: itemsPerPage,
      isLoading: isLoading,
      emptyState: _buildEmptyState(),
    );
  }

  Widget _buildDeviceGroupCard(DeviceGroup group) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Device group header
          Row(
            children: [
              Expanded(
                child: Text(
                  group.name ?? 'Unnamed Group',
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeMedium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              StatusChip(
                text: group.active == true ? 'Active' : 'Inactive',
                type: group.active == true
                    ? StatusChipType.success
                    : StatusChipType.error,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing8),

          // Description
          if (group.description?.isNotEmpty == true) ...[
            Text(
              group.description!,
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSizes.spacing8),
          ],

          // Device count details
          Row(
            children: [
              Icon(
                Icons.device_hub,
                size: AppSizes.iconSmall,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: AppSizes.spacing4),
              Expanded(
                child: Text(
                  '${group.devices?.length ?? 0} devices',
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeSmall,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing4),

          // Group ID (if available)
          if (group.id != null) ...[
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: AppSizes.iconSmall,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: AppSizes.spacing4),
                Expanded(
                  child: Text(
                    'ID: ${group.id}',
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeSmall,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacing8),
          ] else ...[
            const SizedBox(height: AppSizes.spacing8),
          ],

          // Actions - Match device kanban style exactly
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status indicator like device link status
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacing6,
                  vertical: AppSizes.spacing2,
                ),
                decoration: BoxDecoration(
                  color: _getGroupStatusColor(group.active).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  border: Border.all(
                    color: _getGroupStatusColor(group.active).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '${group.devices?.length ?? 0} devices',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeExtraSmall,
                    color: _getGroupStatusColor(group.active),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Quick action button - Match device kanban style exactly
              GestureDetector(
                onTap: () => onDeviceGroupSelected(group),
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.spacing4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    size: AppSizes.iconSmall,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getGroupStatusColor(bool? active) {
    if (active == true) {
      return AppColors.success;
    } else {
      return AppColors.error;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: AppSizes.spacing16),
          Text(
            'No Device Groups',
            style: TextStyle(
              fontSize: AppSizes.fontSizeLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.spacing8),
          Text(
            'Create your first device group to get started',
            style: TextStyle(
              fontSize: AppSizes.fontSizeMedium,
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
