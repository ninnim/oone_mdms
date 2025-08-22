import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/device.dart';
import '../common/app_card.dart';
import '../common/app_button.dart';

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
                decoration: const BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppSizes.radiusMedium),
                    topRight: Radius.circular(AppSizes.radiusMedium),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.devices,
                      size: AppSizes.iconLarge,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSizes.spacing16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Device Details',
                            style: const TextStyle(
                              fontSize: AppSizes.fontSizeLarge,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSizes.spacing4),
                          Text(
                            device.serialNumber.isNotEmpty
                                ? device.serialNumber
                                : 'N/A',
                            style: const TextStyle(
                              fontSize: AppSizes.fontSizeMedium,
                              color: AppColors.textSecondary,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: AppColors.textSecondary,
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
                      _buildSection('Basic Information', [
                        _buildDetailRow('Serial Number', device.serialNumber),
                        _buildDetailRow('Model', device.model),
                        _buildDetailRow('Manufacturer', device.manufacturer),
                        _buildDetailRow('Device Type', device.deviceType),
                      ]),

                      const SizedBox(height: AppSizes.spacing24),

                      // Status Information
                      _buildSection('Status Information', [
                        _buildDetailRow(
                          'Status',
                          device.status,
                          statusChip: _buildStatusChip(device.status),
                        ),
                        _buildDetailRow(
                          'Link Status',
                          device.linkStatus,
                          statusChip: _buildLinkStatusChip(device.linkStatus),
                        ),
                      ]),

                      const SizedBox(height: AppSizes.spacing24),

                      // Location Information
                      if (device.address != null ||
                          device.addressText.isNotEmpty)
                        _buildSection('Location Information', [
                          _buildDetailRow('Address', device.addressText),
                          if (device.address?.street?.isNotEmpty == true)
                            _buildDetailRow('Street', device.address!.street!),
                          if (device.address?.city?.isNotEmpty == true)
                            _buildDetailRow('City', device.address!.city!),
                          if (device.address?.state?.isNotEmpty == true)
                            _buildDetailRow('State', device.address!.state!),
                          if (device.address?.postalCode?.isNotEmpty == true)
                            _buildDetailRow(
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
                decoration: const BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.only(
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

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: AppSizes.fontSizeMedium,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.spacing12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.spacing16),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Widget? statusChip}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.spacing16),
          Expanded(
            child:
                statusChip ??
                Text(
                  value.isNotEmpty ? value : 'N/A',
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeSmall,
                    color: AppColors.textPrimary,
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    String displayText;

    switch (status.toLowerCase()) {
      case 'commissioned':
        backgroundColor = AppColors.success.withValues(alpha: 0.1);
        textColor = AppColors.success;
        displayText = 'Commissioned';
        break;
      case 'none':
        backgroundColor = AppColors.secondary.withValues(alpha: 0.1);
        textColor = AppColors.secondary;
        displayText = 'None';
        break;
      case 'error':
        backgroundColor = AppColors.error.withValues(alpha: 0.1);
        textColor = AppColors.error;
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
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
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

  Widget _buildLinkStatusChip(String linkStatus) {
    Color backgroundColor;
    Color textColor;
    String displayText;

    switch (linkStatus.toLowerCase()) {
      case 'multidrive':
        backgroundColor = AppColors.primary.withValues(alpha: 0.1);
        textColor = AppColors.primary;
        displayText = 'MULTIDRIVE';
        break;
      case 'e-power':
        backgroundColor = AppColors.warning.withValues(alpha: 0.1);
        textColor = AppColors.warning;
        displayText = 'E-POWER';
        break;
      case 'none':
        backgroundColor = AppColors.secondary.withValues(alpha: 0.1);
        textColor = AppColors.secondary;
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
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
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
