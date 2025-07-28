import 'package:flutter/material.dart';
import '../../../core/models/site.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class SiteSummaryCard extends StatelessWidget {
  final List<Site> sites;

  const SiteSummaryCard({super.key, required this.sites});

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();

    return Container(
      // margin: const EdgeInsets.only(bottom: AppSizes.spacing16),
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
          // Row(
          //   children: [
          //     Icon(
          //       Icons.business_outlined,
          //       color: AppColors.primary,
          //       size: 24,
          //     ),
          //     const SizedBox(width: AppSizes.spacing12),
          //     Text(
          //       'Site Summary',
          //       style: TextStyle(
          //         fontSize: AppSizes.fontSizeLarge,
          //         fontWeight: FontWeight.bold,
          //         color: AppColors.textPrimary,
          //       ),
          //     ),
          //   ],
          // ),
          // const SizedBox(height: AppSizes.spacing16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Sites',
                  stats.totalSites.toString(),
                  Icons.business,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSizes.spacing12),
              Expanded(
                child: _buildStatCard(
                  'Total Main Sites',
                  stats.totalMainSites.toString(),
                  Icons.location_city,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: AppSizes.spacing12),
              Expanded(
                child: _buildStatCard(
                  'Total Sub Sites',
                  stats.totalSubSites.toString(),
                  Icons.domain,
                  AppColors.info,
                ),
              ),
              const SizedBox(width: AppSizes.spacing12),
              Expanded(
                child: _buildStatCard(
                  'Active Sites',
                  stats.activeSites.toString(),
                  Icons.check_circle_outline,
                  AppColors.warning,
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

  SiteStats _calculateStats() {
    int totalSites = sites.length;
    int totalMainSites = sites.where((site) => site.isMainSite).length;
    int totalSubSites = sites.where((site) => site.isSubSite).length;
    int activeSites = sites.where((site) => site.active).length;

    return SiteStats(
      totalSites: totalSites,
      totalMainSites: totalMainSites,
      totalSubSites: totalSubSites,
      activeSites: activeSites,
    );
  }
}

class SiteStats {
  final int totalSites;
  final int totalMainSites;
  final int totalSubSites;
  final int activeSites;

  SiteStats({
    required this.totalSites,
    required this.totalMainSites,
    required this.totalSubSites,
    required this.activeSites,
  });
}
