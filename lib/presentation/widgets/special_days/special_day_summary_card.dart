import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/special_day.dart';

class SpecialDaySummaryCard extends StatelessWidget {
  final List<SpecialDay> specialDays;
  final bool isCompact;

  const SpecialDaySummaryCard({
    super.key,
    required this.specialDays,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();

    // Responsive sizing based on compact mode
    final padding = isCompact ? AppSizes.spacing8 : AppSizes.spacing16;
    final spacing = isCompact ? AppSizes.spacing8 : AppSizes.spacing12;
    final borderRadius = isCompact
        ? AppSizes.radiusSmall
        : AppSizes.radiusMedium;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: isCompact ? 4 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  stats.totalSpecialDays.toString(),
                  Icons.event_note,
                  context.primaryColor,
                  context,
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: _buildStatCard(
                  'Active',
                  stats.activeSpecialDays.toString(),
                  Icons.check_circle_outline,
                  context.successColor,
                  context,
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: _buildStatCard(
                  'Inactive',
                  stats.inactiveSpecialDays.toString(),
                  Icons.cancel_outlined,
                  context.errorColor,
                  context,
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: _buildStatCard(
                  'Total Details',
                  stats.totalDetails.toString(),
                  Icons.list_alt,
                  context.infoColor,
                  context,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    BuildContext context,
  ) {
    // Responsive sizing based on compact mode
    final iconSize = isCompact ? 16.0 : 20.0;
    final valueSize = isCompact ? 18.0 : 24.0;
    final titleSize = isCompact ? 11.0 : AppSizes.fontSizeSmall;
    final cardPadding = isCompact ? AppSizes.spacing6 : AppSizes.spacing8;
    final spacingBetween = isCompact ? AppSizes.spacing4 : AppSizes.spacing8;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: iconSize),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: valueSize,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: spacingBetween),
          Text(
            title,
            style: TextStyle(
              fontSize: titleSize,
              color: context.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  SpecialDayStats _calculateStats() {
    int totalSpecialDays = specialDays.length;
    int activeSpecialDays = specialDays
        .where((specialDay) => specialDay.active)
        .length;
    int inactiveSpecialDays = totalSpecialDays - activeSpecialDays;
    int totalDetails = specialDays.fold<int>(
      0,
      (sum, specialDay) => sum + specialDay.detailsCount,
    );

    return SpecialDayStats(
      totalSpecialDays: totalSpecialDays,
      activeSpecialDays: activeSpecialDays,
      inactiveSpecialDays: inactiveSpecialDays,
      totalDetails: totalDetails,
    );
  }
}

class SpecialDayStats {
  final int totalSpecialDays;
  final int activeSpecialDays;
  final int inactiveSpecialDays;
  final int totalDetails;

  SpecialDayStats({
    required this.totalSpecialDays,
    required this.activeSpecialDays,
    required this.inactiveSpecialDays,
    required this.totalDetails,
  });
}





