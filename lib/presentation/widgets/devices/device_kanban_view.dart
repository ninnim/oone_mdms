import 'package:flutter/material.dart';
import '../../../core/models/device.dart';
import '../common/kanban_view.dart';
import 'device_kanban_adapter.dart';

class DeviceKanbanView extends StatelessWidget {
  final List<Device> devices;
  final Function(Device) onDeviceSelected;
  final Function(Device)? onDeviceEdit;
  final Function(Device)? onDeviceDelete;
  final Function(Device)? onDeviceView;
  final Function(Device)? onManageChannels;
  final bool isLoading;
  final bool enablePagination;
  final int itemsPerPage;

  const DeviceKanbanView({
    super.key,
    required this.devices,
    required this.onDeviceSelected,
    this.onDeviceEdit,
    this.onDeviceDelete,
    this.onDeviceView,
    this.onManageChannels,
    this.isLoading = false,
    this.enablePagination = true,
    this.itemsPerPage = 25,
  });

  @override
  Widget build(BuildContext context) {
    // Convert devices to KanbanItems
    final kanbanItems = devices
        .map((device) => DeviceKanbanItem(device))
        .toList();

    // Configure actions
    final actions = DeviceKanbanConfig.getActions(
      onView: onDeviceView,
      onEdit: onDeviceEdit,
      onDelete: onDeviceDelete,
      onManageChannels: onManageChannels,
    );

    return KanbanView<DeviceKanbanItem>(
      items: kanbanItems,
      columns: DeviceKanbanConfig.columns,
      actions: actions,
      onItemTap: (item) => onDeviceSelected(item.device),
      isLoading: isLoading,
      enablePagination: enablePagination,
      itemsPerPage: itemsPerPage,
    );
  }
}
