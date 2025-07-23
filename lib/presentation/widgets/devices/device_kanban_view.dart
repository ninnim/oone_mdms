import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/device.dart';
import '../common/status_chip.dart';
import '../common/kanban_view.dart';

class DeviceKanbanView extends StatelessWidget {
  final List<Device> devices;
  final Function(Device) onDeviceSelected;
  final bool isLoading;
  final bool enableDragDrop;
  final bool enablePagination;
  final int itemsPerPage;
  final Function(Device, String, String)? onDeviceMoved;

  const DeviceKanbanView({
    super.key,
    required this.devices,
    required this.onDeviceSelected,
    this.isLoading = false,
    this.enableDragDrop = false, // Disabled by default for devices
    this.enablePagination = true, // Enable pagination by default for new Kanban
    this.itemsPerPage = 25, // Better default for pagination
    this.onDeviceMoved,
  });

  @override
  Widget build(BuildContext context) {
    // Define device status columns for the kanban board
    final columns = [
      KanbanColumn<Device>(
        id: 'Commissioned',
        title: 'Commissioned',
        color: AppColors.success,
        icon: Icons.check_circle,
      ),
      KanbanColumn<Device>(
        id: 'Decommissioned',
        title: 'Decommissioned',
        color: AppColors.error,
        icon: Icons.cancel,
      ),
      KanbanColumn<Device>(
        id: 'None',
        title: 'Unassigned',
        color: AppColors.textSecondary,
        icon: Icons.help_outline,
      ),
      // KanbanColumn<Device>(
      //   id: 'Renovation',
      //   title: 'Renovation',
      //   color: AppColors.warning,
      //   icon: Icons.build,
      // ),
    ];

    return KanbanView<Device>(
      columns: columns,
      items: devices,
      cardBuilder: _buildDeviceCard,
      getItemColumn: (device) =>
          device.status.isNotEmpty ? device.status : 'None',
      onItemTapped: onDeviceSelected,
      onItemMoved: onDeviceMoved,
      enableDragDrop: enableDragDrop,
      enablePagination: enablePagination,
      itemsPerPage: itemsPerPage,
      isLoading: isLoading,
      emptyState: _buildEmptyState(),
    );
  }

  Widget _buildDeviceCard(Device device) {
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
          // Device header
          Row(
            children: [
              Expanded(
                child: Text(
                  device.serialNumber,
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeMedium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              StatusChip(
                text: device.status.isNotEmpty ? device.status : 'None',
                type: _getStatusChipType(device.status),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing8),

          // Device name
          if (device.name.isNotEmpty) ...[
            Text(
              device.name,
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSizes.spacing8),
          ],

          // Device details
          Row(
            children: [
              Icon(
                Icons.memory,
                size: AppSizes.iconSmall,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: AppSizes.spacing4),
              Expanded(
                child: Text(
                  device.deviceType.isNotEmpty
                      ? device.deviceType
                      : 'Unknown Type',
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeSmall,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing4),

          // Model
          if (device.model.isNotEmpty) ...[
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
                    device.model,
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeSmall,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacing4),
          ],

          // Address
          if (device.addressText.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: AppSizes.iconSmall,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: AppSizes.spacing4),
                Expanded(
                  child: Text(
                    device.addressText,
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeSmall,
                      color: AppColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacing8),
          ],

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Link status indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacing6,
                  vertical: AppSizes.spacing2,
                ),
                decoration: BoxDecoration(
                  color: _getLinkStatusColor(
                    device.linkStatus,
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  border: Border.all(
                    color: _getLinkStatusColor(
                      device.linkStatus,
                    ).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  device.linkStatus.isNotEmpty ? device.linkStatus : 'None',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeExtraSmall,
                    color: _getLinkStatusColor(device.linkStatus),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Quick action button
              GestureDetector(
                onTap: () => onDeviceSelected(device),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.devices_other, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: AppSizes.spacing16),
          const Text(
            'No devices found',
            style: TextStyle(
              fontSize: AppSizes.fontSizeLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.spacing8),
          const Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: AppSizes.fontSizeMedium,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  StatusChipType _getStatusChipType(String status) {
    switch (status.toLowerCase()) {
      case 'commissioned':
        return StatusChipType.success;
      case 'decommissioned':
        return StatusChipType.danger;
      case 'renovation':
        return StatusChipType.warning;
      default:
        return StatusChipType.secondary;
    }
  }

  Color _getLinkStatusColor(String linkStatus) {
    switch (linkStatus.toLowerCase()) {
      case 'multidrive':
        return AppColors.success;
      case 'e-power':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }
}
