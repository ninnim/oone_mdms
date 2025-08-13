import 'package:flutter/material.dart';
import 'package:mdms_clone/presentation/widgets/common/status_chip.dart';
import '../../../core/constants/app_colors.dart';
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
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
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
            style: const TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
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
            style: const TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              color: AppColors.textPrimary,
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
            style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
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
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
              ),
              child: Icon(
                device.deviceType == 'Smart Meter'
                    ? Icons.electrical_services
                    : Icons.device_hub,
                size: 14,
                color: device.deviceType == 'Smart Meter'
                    ? Colors.blue.shade600
                    : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                device.deviceType.isNotEmpty ? device.deviceType : 'N/A',
                style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
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
              const Icon(Icons.location_on, size: 16, color: Color(0xFF6B7280)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  device.addressText.isNotEmpty
                      ? device.addressText
                      : 'No address',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF374151),
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
            icon: const Icon(
              Icons.more_vert,
              color: Color(0xFF9CA3AF),
              size: 16,
            ),
            //  elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'view',
                child: Row(
                  children: [
                    Icon(Icons.visibility, size: 16, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('View Details'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16, color: AppColors.warning),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: AppColors.error)),
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
  }) => getColumns(
    onView: onView,
    onEdit: onEdit,
    onDelete: onDelete,
    currentPage: currentPage,
    itemsPerPage: itemsPerPage,
  );

  static Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    String displayText;

    switch (status.toLowerCase()) {
      case 'commissioned':
        backgroundColor = AppColors.success.withOpacity(0.1);
        textColor = AppColors.success;
        displayText = 'Commissioned';
        break;
      case 'none':
        backgroundColor = AppColors.secondary.withOpacity(0.1);
        textColor = AppColors.secondary;
        displayText = 'None';
        break;
      case 'error':
        backgroundColor = AppColors.error.withOpacity(0.1);
        textColor = AppColors.error;
        displayText = 'Error';
        break;
      default:
        backgroundColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF6B7280);
        displayText = status.isNotEmpty ? status : 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  static Widget _buildLinkStatusChip(String linkStatus) {
    Color backgroundColor;
    Color textColor;
    String displayText;

    switch (linkStatus.toLowerCase()) {
      case 'multidrive':
        backgroundColor = AppColors.primary.withOpacity(0.1);
        textColor = AppColors.primary;
        displayText = 'MULTIDRIVE';
        break;
      case 'e-power':
        backgroundColor = AppColors.warning.withOpacity(0.1);
        textColor = AppColors.warning;
        displayText = 'E-POWER';
        break;
      case 'none':
        backgroundColor = AppColors.secondary.withOpacity(0.1);
        textColor = AppColors.secondary;
        displayText = 'None';
        break;
      default:
        backgroundColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF6B7280);
        displayText = linkStatus.isNotEmpty ? linkStatus : 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}
