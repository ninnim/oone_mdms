import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/site.dart';
import '../common/status_chip.dart';

class SiteKanbanView extends StatelessWidget {
  final List<Site> sites;
  final Function(Site) onEdit;
  final Function(Site) onDelete;
  final Function(Site) onView;
  final bool isLoading;

  const SiteKanbanView({
    super.key,
    required this.sites,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (sites.isEmpty) {
      return const Center(
        child: Text(
          'No sites found',
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
      );
    }

    // Group sites by active status (main sites vs sub sites)
    final siteGroups = <String, List<Site>>{};
    for (final site in sites) {
      final type = site.parentId == 0 ? 'Main Sites' : 'Sub Sites';
      siteGroups.putIfAbsent(type, () => []).add(site);
    }

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surface.withOpacity(0.1)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.border.withOpacity(0.3)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sites by Type',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSizes.spacing24),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: siteGroups.entries.map((entry) {
                  return Container(
                    width: 300,
                    margin: const EdgeInsets.only(right: AppSizes.spacing24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Column header
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.spacing16,
                            vertical: AppSizes.spacing8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? AppColors.primaryDark.withOpacity(0.2)
                                : AppColors.primaryLight.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusMedium,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                entry.key,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${entry.value.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacing16),
                        // Cards
                        Expanded(
                          child: ListView.builder(
                            itemCount: entry.value.length,
                            itemBuilder: (context, index) {
                              final site = entry.value[index];
                              return _SiteKanbanCard(
                                site: site,
                                onEdit: () => onEdit(site),
                                onDelete: () => onDelete(site),
                                onView: () => onView(site),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SiteKanbanCard extends StatelessWidget {
  final Site site;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onView;

  const _SiteKanbanCard({
    required this.site,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacing16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surface.withOpacity(0.1)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.border.withOpacity(0.3)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Single row with site info and actions
            Row(
              children: [
                // Site info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        site.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${site.id ?? 'N/A'} • ${site.parentId == 0 ? 'Main Site' : 'Sub Site'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.spacing8),
                // Actions dropdown
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (value) {
                    switch (value) {
                      case 'view':
                        onView();
                        break;
                      case 'edit':
                        onEdit();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 16),
                          SizedBox(width: 8),
                          Text('View Details'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacing8),
            // Status chip
            StatusChip(
              text: site.active ? 'Active' : 'Inactive',
              type: site.active
                  ? StatusChipType.success
                  : StatusChipType.secondary,
            ),
          ],
        ),
      ),
    );
  }
}
