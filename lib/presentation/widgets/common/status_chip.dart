import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/device.dart';

enum StatusChipType {
  commissioned,
  renovation,
  vacant,
  occupied,
  construction,
  none,
  success,
  warning,
  error,
  info,
  secondary,
  danger,
}

class StatusChip extends StatelessWidget {
  final String text;
  final StatusChipType type;
  final bool compact;

  const StatusChip({
    super.key,
    required this.text,
    required this.type,
    this.compact = false,
  });

  // Factory constructors for common device statuses
  factory StatusChip.fromDeviceStatus(String status, {bool compact = false}) {
    final deviceStatus = DeviceStatus.fromString(status);
    StatusChipType chipType;

    switch (deviceStatus) {
      case DeviceStatus.commissioned:
        chipType = StatusChipType.commissioned;
        break;
      case DeviceStatus.renovation:
        chipType = StatusChipType.renovation;
        break;
      case DeviceStatus.construction:
        chipType = StatusChipType.construction;
        break;
      case DeviceStatus.none:
        chipType = StatusChipType.none;
        break;
    }

    return StatusChip(text: status, type: chipType, compact: compact);
  }

  factory StatusChip.fromLinkStatus(String linkStatus, {bool compact = false}) {
    final status = LinkStatus.fromString(linkStatus);
    StatusChipType chipType;

    switch (status) {
      case LinkStatus.multidrive:
        chipType = StatusChipType.success;
        break;
      case LinkStatus.connected:
        chipType = StatusChipType.success;
        break;
      case LinkStatus.disconnected:
        chipType = StatusChipType.error;
        break;
      case LinkStatus.none:
        chipType = StatusChipType.none;
        break;
    }

    return StatusChip(text: linkStatus, type: chipType, compact: compact);
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getColors(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSizes.spacing8 : AppSizes.spacing12,
        vertical: compact ? AppSizes.spacing4 : AppSizes.spacing8,
      ),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(color: colors.borderColor, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: colors.textColor,
          fontSize: compact ? AppSizes.fontSizeSmall : AppSizes.fontSizeMedium,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  _StatusColors _getColors(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (type) {
      case StatusChipType.commissioned:
        // Green for commissioned devices
        return _StatusColors(
          backgroundColor: colorScheme.primary.withOpacity(0.1),
          borderColor: colorScheme.primary.withOpacity(0.3),
          textColor: colorScheme.primary,
        );
      case StatusChipType.renovation:
        // Orange for renovation
        final renovationColor = AppColors.warning;
        return _StatusColors(
          backgroundColor: renovationColor.withOpacity(0.1),
          borderColor: renovationColor.withOpacity(0.3),
          textColor: renovationColor,
        );
      case StatusChipType.vacant:
        // Blue for vacant
        final vacantColor = AppColors.info;
        return _StatusColors(
          backgroundColor: vacantColor.withOpacity(0.1),
          borderColor: vacantColor.withOpacity(0.3),
          textColor: vacantColor,
        );
      case StatusChipType.occupied:
        // Purple for occupied
        final occupiedColor = AppColors.primary;
        return _StatusColors(
          backgroundColor: occupiedColor.withOpacity(0.1),
          borderColor: occupiedColor.withOpacity(0.3),
          textColor: occupiedColor,
        );
      case StatusChipType.construction:
        // Amber for construction
        final constructionColor = AppColors.warning;
        return _StatusColors(
          backgroundColor: constructionColor.withOpacity(0.1),
          borderColor: constructionColor.withOpacity(0.3),
          textColor: constructionColor,
        );
      case StatusChipType.success:
        // Green for success
        final successColor = AppColors.success;
        return _StatusColors(
          backgroundColor: successColor.withOpacity(0.1),
          borderColor: successColor.withOpacity(0.3),
          textColor: successColor,
        );
      case StatusChipType.warning:
        // Orange for warning
        final warningColor = AppColors.warning;
        return _StatusColors(
          backgroundColor: warningColor.withOpacity(0.1),
          borderColor: warningColor.withOpacity(0.3),
          textColor: warningColor,
        );
      case StatusChipType.error:
        // Red for error
        return _StatusColors(
          backgroundColor: colorScheme.error.withOpacity(0.1),
          borderColor: colorScheme.error.withOpacity(0.3),
          textColor: colorScheme.error,
        );
      case StatusChipType.info:
        // Blue for info
        return _StatusColors(
          backgroundColor: colorScheme.primary.withOpacity(0.1),
          borderColor: colorScheme.primary.withOpacity(0.3),
          textColor: colorScheme.primary,
        );
      case StatusChipType.secondary:
        // Gray for secondary
        final secondaryColor = AppColors.secondary;
        return _StatusColors(
          backgroundColor: secondaryColor.withOpacity(0.1),
          borderColor: secondaryColor.withOpacity(0.3),
          textColor: secondaryColor,
        );
      case StatusChipType.danger:
        // Red for danger
        final dangerColor = AppColors.error;
        return _StatusColors(
          backgroundColor: dangerColor.withOpacity(0.1),
          borderColor: dangerColor.withOpacity(0.3),
          textColor: dangerColor,
        );
      case StatusChipType.none:
        return _StatusColors(
          backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderColor: colorScheme.outline.withOpacity(0.3),
          textColor: colorScheme.onSurfaceVariant,
        );
    }
  }
}

class _StatusColors {
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  _StatusColors({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });
}

// Progress indicator chip for percentage values
class ProgressChip extends StatelessWidget {
  final double percentage;
  final bool compact;

  const ProgressChip({
    super.key,
    required this.percentage,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColorForPercentage(context, percentage);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSizes.spacing8 : AppSizes.spacing12,
        vertical: compact ? AppSizes.spacing4 : AppSizes.spacing8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 20 : 24,
            height: compact ? 4 : 6,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.spacing8),
          Text(
            '${percentage.toInt()}%',
            style: TextStyle(
              color: color,
              fontSize: compact
                  ? AppSizes.fontSizeSmall
                  : AppSizes.fontSizeMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForPercentage(BuildContext context, double percentage) {
    final colorScheme = Theme.of(context).colorScheme;

    if (percentage >= 80) return AppColors.success;
    if (percentage >= 60) return AppColors.warning;
    if (percentage >= 40) return const Color(0xFFf59e0b); // Warning orange
    return colorScheme.error; // Error red
  }
}
