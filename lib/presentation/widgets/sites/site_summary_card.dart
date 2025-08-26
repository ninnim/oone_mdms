import 'package:flutter/material.dart';
import '../../../core/models/site.dart';
import '../../themes/app_theme.dart';
import '../../../core/constants/app_sizes.dart';

class SiteSummaryCard extends StatelessWidget {
  final List<Site> sites;
  final bool isCompact;

  const SiteSummaryCard({
    super.key,
    required this.sites,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();

    if (isCompact) {
      return _buildCompactView(stats, context);
    }

    return Container(
      // margin: const EdgeInsets.only(bottom: AppSizes.spacing16),
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: context.borderColor),
        boxShadow: [
        AppSizes.shadowSmall,
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
                  context.primaryColor,
                  context,
                ),
              ),
              const SizedBox(width: AppSizes.spacing12),
              Expanded(
                child: _buildStatCard(
                  'Total Main',
                  stats.totalMainSites.toString(),
                  Icons.location_city,
                  context.successColor,
                  context,
                ),
              ),
              const SizedBox(width: AppSizes.spacing12),
              Expanded(
                child: _buildStatCard(
                  'Total Sub',
                  stats.totalSubSites.toString(),
                  Icons.domain,
                  context.infoColor,
                  context,
                ),
              ),
              const SizedBox(width: AppSizes.spacing12),
              Expanded(
                child: _buildStatCard(
                  'Active Sites',
                  stats.activeSites.toString(),
                  Icons.check_circle_outline,
                  context.warningColor,
                  context,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactView(SiteStats stats, BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildCompactStatCard(
            'Total',
            stats.totalSites.toString(),
            Icons.business,
            context.primaryColor,
            context,
          ),
        ),
        const SizedBox(width: AppSizes.spacing8),
        Expanded(
          child: _buildCompactStatCard(
            'Main',
            stats.totalMainSites.toString(),
            Icons.location_city,
            context.successColor,
            context,
          ),
        ),
        const SizedBox(width: AppSizes.spacing8),
        Expanded(
          child: _buildCompactStatCard(
            'Sub',
            stats.totalSubSites.toString(),
            Icons.domain,
            context.infoColor,
            context,
          ),
        ),
        const SizedBox(width: AppSizes.spacing8),
        Expanded(
          child: _buildCompactStatCard(
            'Active',
            stats.activeSites.toString(),
            Icons.check_circle_outline,
            context.warningColor,
            context,
          ),
        ),
      ],
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

  Widget _buildCompactStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    BuildContext context,
  ) {

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: AppSizes.spacing4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: AppSizes.fontSizeExtraSmall,
              color: context.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
