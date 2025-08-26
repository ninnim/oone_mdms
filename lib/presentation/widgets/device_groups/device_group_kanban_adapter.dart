import '../../../core/models/device_group.dart';
// import '../../../core/constants/app_colors.dart';
import '../../themes/app_theme.dart';
import '../common/kanban_view.dart';
import 'package:flutter/material.dart';

/// Adapter class to make DeviceGroup compatible with KanbanItem
class DeviceGroupKanbanItem extends KanbanItem {
  final DeviceGroup deviceGroup;

  DeviceGroupKanbanItem(this.deviceGroup);

  @override
  String get id => deviceGroup.id?.toString() ?? '';

  @override
  String get title => deviceGroup.name ?? 'Unnamed Group';

  @override
  String get status => (deviceGroup.active ?? false) ? 'active' : 'inactive';

  @override
  String? get subtitle => deviceGroup.description;

  @override
  String? get badge => deviceGroup.devices != null
      ? '${deviceGroup.devices!.length} devices'
      : null;

  @override
  IconData? get icon => Icons.group_work;

  @override
  Color? get itemColor => (deviceGroup.active ?? false)
      ? const Color(0xFF059669) // Green for active
      : const Color(0xFFDC2626); // Red for inactive

  @override
  List<KanbanDetail> get details {
    final details = <KanbanDetail>[];

    if (deviceGroup.devices != null) {
      final activeDevices = deviceGroup.devices!.where((d) => d.active).length;
      final inactiveDevices = deviceGroup.devices!.length - activeDevices;

      details.addAll([
        KanbanDetail(
          icon: Icons.devices,
          label: 'Total Devices',
          value: '${deviceGroup.devices!.length}',
        ),
        if (activeDevices > 0)
          KanbanDetail(
            icon: Icons.check_circle,
            label: 'Active',
            value: '$activeDevices',
            valueColor: const Color(0xFF059669),
          ),
        if (inactiveDevices > 0)
          KanbanDetail(
            icon: Icons.cancel,
            label: 'Inactive',
            value: '$inactiveDevices',
            valueColor: const Color(0xFFDC2626),
          ),
      ]);
    }

    return details;
  }

  @override
  bool get isActive => deviceGroup.active ?? false;
}

/// Kanban configuration for device groups
class DeviceGroupKanbanConfig {
  static List<KanbanColumn> get columns => [
    const KanbanColumn(
      key: 'active',
      title: 'Active',
      icon: Icons.check_circle,
      color: Color(0xFF059669), // Green
      emptyMessage: 'No active device groups',
    ),
    const KanbanColumn(
      key: 'inactive',
      title: 'Inactive',
      icon: Icons.cancel,
      color: Color(0xFFDC2626), // Red
      emptyMessage: 'No inactive device groups',
    ),
  ];

  static List<KanbanAction> getActions({
    Function(DeviceGroup)? onView,
    Function(DeviceGroup)? onEdit,
    Function(DeviceGroup)? onDelete,
    Function(DeviceGroup)? onManageDevices,
    required BuildContext context,
  }) {
    final actions = <KanbanAction>[];

    if (onView != null) {
      actions.add(
        KanbanAction(
          key: 'view',
          label: 'View Details',
          icon: Icons.visibility,
          color: context.primaryColor,
          onTap: (item) => onView((item as DeviceGroupKanbanItem).deviceGroup),
        ),
      );
    }

    if (onEdit != null) {
      actions.add(
        KanbanAction(
          key: 'edit',
          label: 'Edit',
          icon: Icons.edit,
          color: context.warningColor,
          onTap: (item) => onEdit((item as DeviceGroupKanbanItem).deviceGroup),
        ),
      );
    }

    if (onManageDevices != null) {
      actions.add(
        KanbanAction(
          key: 'devices',
          label: 'Manage Devices',
          icon: Icons.devices,
          color: context.infoColor,
          onTap: (item) =>
              onManageDevices((item as DeviceGroupKanbanItem).deviceGroup),
        ),
      );
    }

    if (onDelete != null) {
      actions.add(
        KanbanAction(
          key: 'delete',
          label: 'Delete',
          icon: Icons.delete,
          color: context.errorColor,
          onTap: (item) =>
              onDelete((item as DeviceGroupKanbanItem).deviceGroup),
        ),
      );
    }

    return actions;
  }
}



