import 'package:flutter/material.dart';
import 'package:mdms_clone/presentation/themes/app_theme.dart';
import 'package:mdms_clone/presentation/widgets/common/status_chip.dart';
// import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/models/device.dart';
import '../../../widgets/common/blunest_data_table.dart';

class DeviceChannelTableColumns {
  static List<BluNestTableColumn<DeviceChannel>> getColumns({
    required bool isEditMode,
    required Set<String> selectedChannelIds,
    required Function(DeviceChannel, bool?) onChannelSelect,
    required Function(DeviceChannel, String) onCumulativeChanged,
    required Map<String, TextEditingController> channelControllers,
    Function(DeviceChannel)? onView,
    Function(DeviceChannel)? onEdit,
    Function(DeviceChannel)? onDelete,
    required BuildContext context,
    required List<DeviceChannel> channels, // Added to get index
  }) {
    return [
      // Row Number Column
      BluNestTableColumn<DeviceChannel>(
        key: 'no',
        title: 'No.',
        flex: 1,
        builder: (channel) {
          final index = channels.indexOf(channel) + 1;
          return Text(
            index.toString(),
            style: TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              fontWeight: FontWeight.w500,
              color: context.textSecondaryColor,
            ),
          );
        },
        sortable: false,
      ),

      // Channel Code
      BluNestTableColumn<DeviceChannel>(
        key: 'code',
        title: 'Code',
        flex: 2,
        builder: (channel) => StatusChip(
          text: channel.channel?.code ?? 'N/A',
          type: StatusChipType.info,
          compact: true,
        ),
        sortable: true,
      ),

      // Channel Name
      BluNestTableColumn<DeviceChannel>(
        key: 'channel',
        title: 'Channel',
        flex: 4,
        builder: (channel) => Text(
          channel.channel?.name ?? 'N/A',
          style: TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            fontWeight: FontWeight.w500,
            color: context.textPrimaryColor,
          ),
        ),
        sortable: true,
      ),

      // Cumulative (editable in edit mode)
      BluNestTableColumn<DeviceChannel>(
        key: 'cumulative',
        title: 'Cumulative',
        flex: 2,
        builder: (channel) => isEditMode
            ? SizedBox(
                width: 120,
                child: TextFormField(
                  controller: channelControllers[channel.id],
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: AppSizes.fontSizeSmall),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                      borderSide: BorderSide(color: context.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                      borderSide: BorderSide(color: context.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                      borderSide: BorderSide(color: context.primaryColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.spacing8,
                      vertical: AppSizes.spacing8,
                    ),
                    isDense: true,
                  ),
                  onChanged: (value) => onCumulativeChanged(channel, value),
                ),
              )
            : Text(
                channel.cumulative.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: AppSizes.fontSizeSmall,
                  color: context.textPrimaryColor,
                ),
              ),
        sortable: true,
      ),

      // Units
      BluNestTableColumn<DeviceChannel>(
        key: 'units',
        title: 'Units',
        flex: 1,
        builder: (channel) => Text(
          channel.channel?.units ?? 'N/A',
          style: TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            color: context.textSecondaryColor,
          ),
        ),
        sortable: true,
      ),

      // Flow Direction
      BluNestTableColumn<DeviceChannel>(
        key: 'flowDirection',
        title: 'Flow Direction',
        flex: 2,
        builder: (channel) => Text(
          channel.channel?.flowDirection ?? 'N/A',
          style: TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            color: context.textSecondaryColor,
          ),
        ),
        sortable: true,
      ),

      // Phase
      BluNestTableColumn<DeviceChannel>(
        key: 'phase',
        title: 'Phase',
        flex: 1,
        builder: (channel) => Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacing8,
            vertical: AppSizes.spacing4,
          ),
          decoration: BoxDecoration(
            color: _getPhaseColor(channel.channel?.phase, context),
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          ),
          child: Text(
            channel.channel?.phase ?? 'N/A',
            style: TextStyle(
              fontSize: AppSizes.fontSizeExtraSmall,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        sortable: true,
      ),
      // // Active Status
      // BluNestTableColumn<DeviceChannel>(
      //   key: 'active',
      //   title: 'Active',
      //   flex: 1,
      //   builder: (channel) => StatusChip(
      //     text: channel.active ? 'Active' : 'Inactive',
      //     type: channel.active
      //         ? StatusChipType.success
      //         : StatusChipType.secondary,
      //     compact: true,
      //   ),
      //   sortable: true,
      // ),
      // Apply Metric
      BluNestTableColumn<DeviceChannel>(
        key: 'applyMetric',
        title: 'Apply Metric',
        flex: 1,
        builder: (channel) => StatusChip(
          text: channel.applyMetric ? 'Yes' : 'No',
          type: channel.applyMetric
              ? StatusChipType.success
              : StatusChipType.secondary,
          compact: true,
        ),
        sortable: true,
      ),

      // Actions (only in non-edit mode)
      // if (!isEditMode)
      //   BluNestTableColumn<DeviceChannel>(
      //     key: 'actions',
      //     title: 'Actions',
      //     flex: 1,
      //     builder: (channel) => Row(
      //       mainAxisSize: MainAxisSize.min,
      //       children: [
      //         if (onView != null)
      //           IconButton(
      //             icon: const Icon(Icons.visibility, size: 16),
      //             onPressed: () => onView(channel),
      //             color: context.primaryColor,
      //             tooltip: 'View Details',
      //           ),
      //         if (onEdit != null)
      //           IconButton(
      //             icon: const Icon(Icons.edit, size: 16),
      //             onPressed: () => onEdit(channel),
      //             color: context.warningColor,
      //             tooltip: 'Edit Channel',
      //           ),
      //         if (onDelete != null)
      //           IconButton(
      //             icon: const Icon(Icons.delete, size: 16),
      //             onPressed: () => onDelete(channel),
      //             color: context.errorColor,
      //             tooltip: 'Delete Channel',
      //           ),
      //       ],
      //     ),
      //     sortable: false,
      //   ),
    ];
  }

  static Color _getPhaseColor(String? phase, BuildContext context) {
    switch (phase?.toUpperCase()) {
      case 'L1':
      case 'R':
        return context.primaryColor;
      case 'L2':
      case 'S':
        return context.successColor;
      case 'L3':
      case 'T':
        return context.warningColor;
      case 'N':
        return context.textSecondaryColor;
      default:
        return context.textSecondaryColor;
    }
  }
}
