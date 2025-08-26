import 'package:flutter/material.dart';
import '../../../core/models/season.dart';
import '../../themes/app_theme.dart';
import '../../../core/constants/app_sizes.dart';

class SeasonSummaryCard extends StatelessWidget {
  final List<Season> seasons;

  const SeasonSummaryCard({super.key, required this.seasons});

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: context.borderColor),
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
                  'Total Seasons',
                  stats.totalSeasons.toString(),
                  Icons.calendar_month,
                  context.primaryColor,
                  context,
                ),
              ),
              const SizedBox(width: AppSizes.spacing12),
              Expanded(
                child: _buildStatCard(
                  'Active',
                  stats.activeSeasons.toString(),
                  Icons.check_circle_outline,
                  context.successColor,
                  context,
                ),
              ),
              const SizedBox(width: AppSizes.spacing12),
              Expanded(
                child: _buildStatCard(
                  'Inactive',
                  stats.inactiveSeasons.toString(),
                  Icons.pause_circle_outline,
                  context.errorColor,
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
              color: context.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  SeasonStats _calculateStats() {
    int totalSeasons = seasons.length;
    int activeSeasons = seasons.where((season) => season.active).length;
    int inactiveSeasons = seasons.where((season) => !season.active).length;

    return SeasonStats(
      totalSeasons: totalSeasons,
      activeSeasons: activeSeasons,
      inactiveSeasons: inactiveSeasons,
    );
  }
}

class SeasonStats {
  final int totalSeasons;
  final int activeSeasons;
  final int inactiveSeasons;

  SeasonStats({
    required this.totalSeasons,
    required this.activeSeasons,
    required this.inactiveSeasons,
  });
}
