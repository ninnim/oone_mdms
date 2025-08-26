import '../../../core/models/device.dart';
// import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_colors.dart';
import '../common/kanban_view.dart';
import '../common/status_chip.dart';
import 'package:flutter/material.dart';

/// Adapter class to make Device compatible with KanbanItem
class DeviceKanbanItem extends KanbanItem {
  final Device device;

  DeviceKanbanItem(this.device);

  @override
  String get id => device.id ?? '';

  @override
  String get title =>
      device.name.isNotEmpty ? device.name : device.serialNumber;

  @override
  String get status =>
      device.status.isEmpty ? 'none' : device.status.toLowerCase();

  @override
  String? get subtitle => device.serialNumber;

  @override
  String? get badge => device.deviceGroup?.name;

  @override
  Widget? get statusBadge => StatusChip(
    text: device.linkStatus,
    type: _getLinkStatusChipType(),
    compact: true,
  );

  @override
  IconData? get icon {
    switch (device.status.toLowerCase()) {
      case 'commissioned':
        return Icons.check_circle_outline;
      case 'decommissioned':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Color? get itemColor {
    switch (device.status.toLowerCase()) {
      case 'commissioned':
        return AppColors.success; // Green
      case 'decommissioned':
        return AppColors.error; // Red
      default:
        return AppColors.textSecondary; // Gray
    }
  }

  @override
  List<KanbanDetail> get details => [
    KanbanDetail(icon: Icons.memory, label: 'Model', value: device.model),
    KanbanDetail(
      icon: Icons.business,
      label: 'Manufacturer',
      value: device.manufacturer,
    ),
    KanbanDetail(icon: Icons.category, label: 'Type', value: device.deviceType),
    if (device.address != null)
      KanbanDetail(
        icon: Icons.location_on,
        label: 'Address',
        value: device.address!.getFormattedAddress().isNotEmpty
            ? device.address!.getFormattedAddress()
            : device.addressText,
      ),
  ];

  /// Get StatusChipType for link status display
  StatusChipType _getLinkStatusChipType() {
    switch (device.linkStatus.toLowerCase()) {
      case 'multidrive':
        return StatusChipType.success;
      case 'e-power':
        return StatusChipType.warning;
      case 'online':
        return StatusChipType.commissioned;
      case 'offline':
        return StatusChipType.error;
      case 'connected':
        return StatusChipType.success;
      case 'disconnected':
        return StatusChipType.error;
      case 'none':
        return StatusChipType.none;
      default:
        return StatusChipType.none;
    }
  }

  @override
  bool get isActive => device.active;
}

/// Kanban configuration for devices
class DeviceKanbanConfig {
  static List<KanbanColumn> get columns => [
    const KanbanColumn(
      key: 'commissioned',
      title: 'Commissioned',
      icon: Icons.check_circle_outline,
      color: AppColors.success, // Green
      emptyMessage: 'No commissioned devices',
    ),
    const KanbanColumn(
      key: 'decommissioned',
      title: 'Decommissioned',
      icon: Icons.cancel_outlined,
      color: AppColors.error, // Red
      emptyMessage: 'No decommissioned devices',
    ),
    const KanbanColumn(
      key: 'none',
      title: 'None',
      icon: Icons.help_outline,
      color: AppColors.textSecondary, // Gray
      emptyMessage: 'No devices without status',
    ),
  ];

  static List<KanbanAction> getActions({
    Function(Device)? onView,
    Function(Device)? onEdit,
    Function(Device)? onDelete,
    Function(Device)? onManageChannels,
  }) {
    final actions = <KanbanAction>[];

    if (onView != null) {
      actions.add(
        KanbanAction(
          key: 'view',
          label: 'View Details',
          icon: Icons.visibility,
          color: AppColors.primary,
          onTap: (item) => onView((item as DeviceKanbanItem).device),
        ),
      );
    }

    if (onEdit != null) {
      actions.add(
        KanbanAction(
          key: 'edit',
          label: 'Edit',
          icon: Icons.edit,
          color: AppColors.warning,
          onTap: (item) => onEdit((item as DeviceKanbanItem).device),
        ),
      );
    }

    if (onManageChannels != null) {
      actions.add(
        KanbanAction(
          key: 'channels',
          label: 'Manage Channels',
          icon: Icons.tune,
          color: AppColors.info,
          onTap: (item) => onManageChannels((item as DeviceKanbanItem).device),
        ),
      );
    }

    if (onDelete != null) {
      actions.add(
        KanbanAction(
          key: 'delete',
          label: 'Delete',
          icon: Icons.delete,
          color: AppColors.error,
          onTap: (item) => onDelete((item as DeviceKanbanItem).device),
        ),
      );
    }

    return actions;
  }
}
