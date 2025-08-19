import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/special_day.dart';

class SpecialDaySummaryCard extends StatelessWidget {
  final List<SpecialDay> specialDays;

  const SpecialDaySummaryCard({super.key, required this.specialDays});

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
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
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSizes.spacing12),
              Expanded(
                child: _buildStatCard(
                  'Active',
                  stats.activeSpecialDays.toString(),
                  Icons.check_circle_outline,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: AppSizes.spacing12),
              Expanded(
                child: _buildStatCard(
                  'Inactive',
                  stats.inactiveSpecialDays.toString(),
                  Icons.cancel_outlined,
                  AppColors.error,
                ),
              ),
              const SizedBox(width: AppSizes.spacing12),
              Expanded(
                child: _buildStatCard(
                  'Total Details',
                  stats.totalDetails.toString(),
                  Icons.list_alt,
                  AppColors.info,
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
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing8),
          Text(
            title,
            style: TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
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
