import '../../../core/models/site.dart';
import '../../../core/constants/app_colors.dart';
import '../common/kanban_view.dart';
import '../common/status_chip.dart';
import 'package:flutter/material.dart';

/// Adapter class to make Site compatible with KanbanItem
class SiteKanbanItem extends KanbanItem {
  final Site site;

  SiteKanbanItem(this.site);

  @override
  String get id => site.id?.toString() ?? '';

  @override
  String get title => site.name;

  @override
  String get status {
    // Simple status-based grouping
    return site.active ? 'active' : 'inactive';
  }

  @override
  String? get subtitle => site.description.isNotEmpty ? site.description : null;

  @override
  String? get badge => site.isMainSite
      ? 'Main Site'
      : site.subSiteCount > 0
      ? '${site.subSiteCount} sub-sites'
      : null;

  @override
  Widget? get statusBadge => StatusChip(
    text: site.active ? 'Active' : 'Inactive',
    type: site.active ? StatusChipType.success : StatusChipType.error,
    compact: true,
  );

  @override
  IconData? get icon => site.isMainSite ? Icons.business : Icons.location_city;

  @override
  Color? get itemColor => site.active
      ? const Color(0xFF059669) // Green for active
      : const Color(0xFFDC2626); // Red for inactive

  @override
  List<KanbanDetail> get details {
    final details = <KanbanDetail>[
      KanbanDetail(
        icon: Icons.category,
        label: 'Type',
        value: site.isMainSite ? 'Main Site' : 'Sub Site',
      ),
    ];

    if (site.isSubSite && site.parentId != 0) {
      details.add(
        KanbanDetail(
          icon: Icons.account_tree,
          label: 'Parent ID',
          value: site.parentId.toString(),
        ),
      );
    }

    if (site.subSiteCount > 0) {
      details.add(
        KanbanDetail(
          icon: Icons.location_city,
          label: 'Sub Sites',
          value: site.subSiteCount.toString(),
          valueColor: AppColors.info,
        ),
      );
    }

    return details;
  }

  @override
  List<Widget> get smartChips {
    final chips = <Widget>[];

    // Add site type chip
    chips.add(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: site.isMainSite
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.info.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: site.isMainSite
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.info.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          site.isMainSite ? 'Main Site' : 'Sub Site',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: site.isMainSite ? AppColors.primary : AppColors.info,
          ),
        ),
      ),
    );

    // Add sub-sites count chip for main sites
    if (site.isMainSite && site.subSiteCount > 0) {
      chips.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Text(
            '${site.subSiteCount} sub-sites',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.success,
            ),
          ),
        ),
      );
    }

    // Add parent info chip for sub sites
    if (site.isSubSite && site.parentId > 0) {
      chips.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: Text(
            'Parent: ${site.parentId}',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.warning,
            ),
          ),
        ),
      );
    }

    return chips;
  }

  @override
  bool get isActive => site.active;
}

/// Kanban configuration for sites
class SiteKanbanConfig {
  static List<KanbanColumn> get columns => [
    const KanbanColumn(
      key: 'active',
      title: 'Active Sites',
      icon: Icons.business,
      color: Color(0xFF059669), // Green
      emptyMessage: 'No active sites',
    ),
    const KanbanColumn(
      key: 'inactive',
      title: 'Inactive Sites',
      icon: Icons.business_outlined,
      color: Color(0xFFDC2626), // Red
      emptyMessage: 'No inactive sites',
    ),
  ];

  static List<KanbanAction> getActions({
    Function(Site)? onView,
    Function(Site)? onEdit,
    Function(Site)? onDelete,
    Function(Site)? onViewSubSites,
  }) {
    final actions = <KanbanAction>[];

    if (onView != null) {
      actions.add(
        KanbanAction(
          key: 'view',
          label: 'View Details',
          icon: Icons.visibility,
          color: AppColors.primary,
          onTap: (item) => onView((item as SiteKanbanItem).site),
        ),
      );
    }

    if (onEdit != null) {
      actions.add(
        KanbanAction(
          key: 'edit',
          label: 'Edit',
          icon: Icons.edit,
          color: AppColors.warning,
          onTap: (item) => onEdit((item as SiteKanbanItem).site),
        ),
      );
    }

    if (onViewSubSites != null) {
      actions.add(
        KanbanAction(
          key: 'subsites',
          label: 'View Sub Sites',
          icon: Icons.location_city,
          color: AppColors.info,
          onTap: (item) => onViewSubSites((item as SiteKanbanItem).site),
        ),
      );
    }

    if (onDelete != null) {
      actions.add(
        KanbanAction(
          key: 'delete',
          label: 'Delete',
          icon: Icons.delete,
          color: AppColors.error,
          onTap: (item) => onDelete((item as SiteKanbanItem).site),
        ),
      );
    }

    return actions;
  }
}
