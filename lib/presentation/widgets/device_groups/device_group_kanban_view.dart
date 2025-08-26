import 'package:flutter/material.dart';
import '../../../core/models/device_group.dart';
import '../common/kanban_view.dart';
import 'device_group_kanban_adapter.dart';

class DeviceGroupKanbanView extends StatelessWidget {
  final List<DeviceGroup> deviceGroups;
  final Function(DeviceGroup) onDeviceGroupSelected;
  final Function(DeviceGroup)? onDeviceGroupEdit;
  final Function(DeviceGroup)? onDeviceGroupDelete;
  final Function(DeviceGroup)? onDeviceGroupView;
  final Function(DeviceGroup)? onManageDevices;
  final bool isLoading;
  final bool enablePagination;
  final int itemsPerPage;

  const DeviceGroupKanbanView({
    super.key,
    required this.deviceGroups,
    required this.onDeviceGroupSelected,
    this.onDeviceGroupEdit,
    this.onDeviceGroupDelete,
    this.onDeviceGroupView,
    this.onManageDevices,
    this.isLoading = false,
    this.enablePagination = true,
    this.itemsPerPage = 25,
  });

  @override
  Widget build(BuildContext context) {
    // Convert device groups to KanbanItems
    final kanbanItems = deviceGroups
        .map((group) => DeviceGroupKanbanItem(group))
        .toList();

    // Configure actions
    final actions = DeviceGroupKanbanConfig.getActions(
      onView: onDeviceGroupView,
      context: context,
      onEdit: onDeviceGroupEdit,
      onDelete: onDeviceGroupDelete,
      onManageDevices: onManageDevices,
    );

    return KanbanView<DeviceGroupKanbanItem>(
      items: kanbanItems,
      columns: DeviceGroupKanbanConfig.columns,
      actions: actions,
      onItemTap: (item) => onDeviceGroupSelected(item.deviceGroup),
      isLoading: isLoading,
      enablePagination: enablePagination,
      itemsPerPage: itemsPerPage,
    );
  }
}
