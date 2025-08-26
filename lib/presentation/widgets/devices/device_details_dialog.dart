import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/device.dart';
import '../common/app_card.dart';
import '../common/app_button.dart';
import '../../themes/app_theme.dart';

class DeviceDetailsDialog extends StatelessWidget {
  final Device device;

  const DeviceDetailsDialog({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppSizes.spacing24),
                decoration: BoxDecoration(
                  color: context.surfaceVariantColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppSizes.radiusMedium),
                    topRight: Radius.circular(AppSizes.radiusMedium),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.devices,
                      size: AppSizes.iconLarge,
                      color: context.primaryColor,
                    ),
                    const SizedBox(width: AppSizes.spacing16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Device Details',
                            style: TextStyle(
                              fontSize: AppSizes.fontSizeLarge,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: AppSizes.spacing4),
                          Text(
                            device.serialNumber.isNotEmpty
                                ? device.serialNumber
                                : 'N/A',
                            style: TextStyle(
                              fontSize: AppSizes.fontSizeMedium,
                              color: context.textPrimaryColor.withOpacity(0.7),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: context.textPrimaryColor.withOpacity(0.7),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizes.spacing24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Information
                      _buildSection(context, 'Basic Information', [
                        _buildDetailRow(
                          context,
                          'Serial Number',
                          device.serialNumber,
                        ),
                        _buildDetailRow(context, 'Model', device.model),
                        _buildDetailRow(
                          context,
                          'Manufacturer',
                          device.manufacturer,
                        ),
                        _buildDetailRow(
                          context,
                          'Device Type',
                          device.deviceType,
                        ),
                      ]),

                      const SizedBox(height: AppSizes.spacing24),

                      // Status Information
                      _buildSection(context, 'Status Information', [
                        _buildDetailRow(
                          context,
                          'Status',
                          device.status,
                          statusChip: _buildStatusChip(context, device.status),
                        ),
                        _buildDetailRow(
                          context,
                          'Link Status',
                          device.linkStatus,
                          statusChip: _buildLinkStatusChip(
                            context,
                            device.linkStatus,
                          ),
                        ),
                      ]),

                      const SizedBox(height: AppSizes.spacing24),

                      // Location Information
                      if (device.address != null ||
                          device.addressText.isNotEmpty)
                        _buildSection(context, 'Location Information', [
                          _buildDetailRow(
                            context,
                            'Address',
                            device.addressText,
                          ),
                          if (device.address?.street?.isNotEmpty == true)
                            _buildDetailRow(
                              context,
                              'Street',
                              device.address!.street!,
                            ),
                          if (device.address?.city?.isNotEmpty == true)
                            _buildDetailRow(
                              context,
                              'City',
                              device.address!.city!,
                            ),
                          if (device.address?.state?.isNotEmpty == true)
                            _buildDetailRow(
                              context,
                              'State',
                              device.address!.state!,
                            ),
                          if (device.address?.postalCode?.isNotEmpty == true)
                            _buildDetailRow(
                              context,
                              'Postal Code',
                              device.address!.postalCode!,
                            ),
                        ]),
                    ],
                  ),
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(AppSizes.spacing24),
                decoration: BoxDecoration(
                  color: context.surfaceVariantColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(AppSizes.radiusMedium),
                    bottomRight: Radius.circular(AppSizes.radiusMedium),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(
                      onPressed: () => Navigator.of(context).pop(),
                      text: 'Close',
                      type: AppButtonType.secondary,
                      //  size: AppButtonSize.medium,
                    ),
                    const SizedBox(width: AppSizes.spacing12),
                    AppButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // TODO: Navigate to full device details page
                      },
                      text: 'View Full Details',
                      type: AppButtonType.primary,
                      //  size: AppButtonSize.medium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: AppSizes.fontSizeMedium,
            fontWeight: FontWeight.bold,
            color: context.textPrimaryColor,
          ),
        ),
        const SizedBox(height: AppSizes.spacing12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.spacing16),
          decoration: BoxDecoration(
            color: context.surfaceVariantColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    Widget? statusChip,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                fontWeight: FontWeight.w500,
                color: context.textPrimaryColor.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.spacing16),
          Expanded(
            child:
                statusChip ??
                Text(
                  value.isNotEmpty ? value : 'N/A',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeSmall,
                    color: context.textPrimaryColor,
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    Color backgroundColor;
    Color textColor;
    String displayText;

    switch (status.toLowerCase()) {
      case 'commissioned':
        backgroundColor = context.successColor.withOpacity(0.1);
        textColor = context.successColor;
        displayText = 'Commissioned';
        break;
      case 'none':
        backgroundColor = context.secondaryColor.withOpacity(0.1);
        textColor = context.secondaryColor;
        displayText = 'None';
        break;
      case 'error':
        backgroundColor = context.errorColor.withOpacity(0.1);
        textColor = context.errorColor;
        displayText = 'Error';
        break;
      default:
        backgroundColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF6B7280);
        displayText = status.isNotEmpty ? status : 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: AppSizes.fontSizeSmall,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildLinkStatusChip(BuildContext context, String linkStatus) {
    Color backgroundColor;
    Color textColor;
    String displayText;

    switch (linkStatus.toLowerCase()) {
      case 'multidrive':
        backgroundColor = context.primaryColor.withOpacity(0.1);
        textColor = context.primaryColor;
        displayText = 'MULTIDRIVE';
        break;
      case 'e-power':
        backgroundColor = context.warningColor.withOpacity(0.1);
        textColor = context.warningColor;
        displayText = 'E-POWER';
        break;
      case 'none':
        backgroundColor = context.secondaryColor.withOpacity(0.1);
        textColor = context.secondaryColor;
        displayText = 'None';
        break;
      default:
        backgroundColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF6B7280);
        displayText = linkStatus.isNotEmpty ? linkStatus : 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: AppSizes.fontSizeSmall,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}
