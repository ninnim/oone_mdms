import 'package:flutter/material.dart';
import 'package:mdms_clone/presentation/widgets/common/status_chip.dart';
//import '../../../core/constants/app_colors.dart';
import '../../themes/app_theme.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/device.dart';
import '../common/blunest_data_table.dart';

class DeviceTableColumns {
  static List<BluNestTableColumn<Device>> getColumns({
    Function(Device)? onView,
    Function(Device)? onEdit,
    Function(Device)? onDelete,
    int currentPage = 1,
    int itemsPerPage = 25,
    List<Device>? devices,
    required BuildContext context,
  }) {
    return [
      // No. (Row Number)
      BluNestTableColumn<Device>(
        key: 'no',
        title: 'No.',
        flex: 1,
        sortable: false,
        builder: (device) {
          final index = devices?.indexOf(device) ?? 0;
          final rowNumber = ((currentPage - 1) * itemsPerPage) + index + 1;
          return Container(
            alignment: Alignment.centerLeft,
            child: Text(
              '$rowNumber',
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                fontWeight: FontWeight.w500,
                color: context?.textSecondaryColor,
              ),
            ),
          );
        },
      ),

      // Serial Number
      BluNestTableColumn<Device>(
        key: 'serialNumber',
        title: 'Serial Number',
        flex: 2,
        sortable: true,
        builder: (device) => Container(
          alignment: Alignment.centerLeft,
          child: Text(
            device.serialNumber.isNotEmpty ? device.serialNumber : 'N/A',
            style: TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              fontWeight: FontWeight.w600,
              color: context?.textPrimaryColor,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),

      // Model
      BluNestTableColumn<Device>(
        key: 'model',
        title: 'Model',
        flex: 2,
        sortable: true,
        builder: (device) => Container(
          alignment: Alignment.centerLeft,
          child: Text(
            device.model.isNotEmpty ? device.model : 'N/A',
            style: TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              color: context?.textPrimaryColor,
            ),
          ),
        ),
      ),

      // Manufacturer
      BluNestTableColumn<Device>(
        key: 'manufacturer',
        title: 'Manufacturer',
        flex: 2,
        sortable: true,
        builder: (device) => Container(
          alignment: Alignment.centerLeft,
          child: Text(
            device.manufacturer.isNotEmpty ? device.manufacturer : 'N/A',
            style: TextStyle(fontSize: 13, color: context?.textPrimaryColor),
          ),
        ),
      ),

      // Device Type
      BluNestTableColumn<Device>(
        key: 'deviceType',
        title: 'Device Type',
        flex: 2,
        sortable: true,
        builder: (device) => Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: device.deviceType == 'Smart Meter'
                    ? context.primaryColor.withOpacity(0.1)
                    : context.textSecondaryColor.withOpacity(0.1),
              ),
              child: Icon(
                device.deviceType == 'Smart Meter'
                    ? Icons.electrical_services
                    : Icons.device_hub,
                size: 14,
                color: device.deviceType == 'Smart Meter'
                    ? context.primaryColor
                    : context.textSecondaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                device.deviceType.isNotEmpty ? device.deviceType : 'N/A',
                style: TextStyle(fontSize: 13, color: context.textPrimaryColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),

      // Status
      BluNestTableColumn<Device>(
        key: 'status',
        title: 'Status',
        flex: 2,
        sortable: true,

        builder: (device) => Container(
          alignment: Alignment.centerLeft,
          //height: AppSizes.spacing40,
          child: StatusChip(
            text: device.status,
            type: device.status == 'Commissioned'
                ? StatusChipType.success
                : device.status == 'Discommissioned'
                ? StatusChipType.construction
                : device.status == 'None'
                ? StatusChipType.none
                : StatusChipType.none,
            //  height: AppSizes.spacing40,
            compact: true,
            //padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing8),
          ),

          //child: _buildStatusChip(device.status),
        ),
      ),

      // Link Status
      BluNestTableColumn<Device>(
        key: 'linkStatus',
        title: 'Link Status',
        flex: 2,
        sortable: true,
        builder: (device) => Container(
          alignment: Alignment.centerLeft,

          //  height: AppSizes.spacing40,
          child: StatusChip(
            text: device.linkStatus,
            type: device.linkStatus == 'MULTIDRIVE'
                ? StatusChipType.commissioned
                : device.linkStatus == 'E-POWER'
                ? StatusChipType.warning
                : device.linkStatus == 'None'
                ? StatusChipType.none
                : StatusChipType.none,
            compact: true,
            //  height: AppSizes.spacing40,
            //padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing8),
          ),
          // child: _buildLinkStatusChip(device.linkStatus),
        ),
      ),

      // Address
      BluNestTableColumn<Device>(
        key: 'address',
        title: 'Address',
        flex: 3,
        sortable: true,
        builder: (device) => Container(
          //height: AppSizes.spacing40,
          //  padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing8),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: context.textSecondaryColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  device.addressText.isNotEmpty
                      ? device.addressText
                      : 'No address',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textPrimaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),

      // Actions
      BluNestTableColumn<Device>(
        key: 'actions',
        title: 'Actions',
        flex: 1,
        sortable: false,
        isActions: true,
        builder: (device) => Container(
          alignment: Alignment.centerRight,
          height: AppSizes.spacing40,
          //padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing8),
          child: PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: context.textSecondaryColor,
              size: 16,
            ),
            //  elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'view',
                child: Row(
                  children: [
                    Icon(
                      Icons.visibility,
                      size: 16,
                      color: context.primaryColor,
                    ),
                    SizedBox(width: 8),
                    Text('View Details'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16, color: context.warningColor),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16, color: context.errorColor),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: context.errorColor)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'view':
                  onView?.call(device);
                  break;
                case 'edit':
                  onEdit?.call(device);
                  break;
                case 'delete':
                  onDelete?.call(device);
                  break;
              }
            },
          ),
        ),
      ),
    ];
  }

  // Legacy getter for backward compatibility
  static List<BluNestTableColumn<Device>> columns({
    Function(Device)? onView,
    Function(Device)? onEdit,
    Function(Device)? onDelete,
    int currentPage = 1,
    int itemsPerPage = 25,
    required BuildContext context,
  }) => getColumns(
    onView: onView,
    onEdit: onEdit,
    onDelete: onDelete,
    currentPage: currentPage,
    itemsPerPage: itemsPerPage,
    context: context,
  );
}
