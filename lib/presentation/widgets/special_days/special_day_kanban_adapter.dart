import '../../../core/models/special_day.dart';
import '../../../core/constants/app_colors.dart';
import '../common/kanban_view.dart';
import '../common/status_chip.dart';
import 'package:flutter/material.dart';

/// Adapter class to make SpecialDay compatible with KanbanItem
class SpecialDayKanbanItem extends KanbanItem {
  final SpecialDay specialDay;

  SpecialDayKanbanItem(this.specialDay);

  @override
  String get id => specialDay.id.toString();

  @override
  String get title => specialDay.name;

  @override
  String get status {
    if (!specialDay.active) {
      return 'inactive';
    }

    // For active special days, categorize by content
    if (specialDay.specialDayDetails.isEmpty) {
      return 'active_empty';
    }

    final hasActiveDetails = specialDay.activeDetailsCount > 0;
    return hasActiveDetails ? 'active_configured' : 'active_pending';
  }

  @override
  String? get subtitle =>
      specialDay.description.isNotEmpty ? specialDay.description : null;

  @override
  String? get badge => specialDay.specialDayDetails.isNotEmpty
      ? '${specialDay.specialDayDetails.length} details'
      : null;

  @override
  Widget? get statusBadge => StatusChip(
    text: specialDay.active ? 'Active' : 'Inactive',
    type: specialDay.active ? StatusChipType.success : StatusChipType.error,
    compact: true,
  );

  @override
  IconData? get icon => Icons.star;

  @override
  Color? get itemColor => specialDay.active
      ? const Color(0xFF059669) // Green for active
      : const Color(0xFFDC2626); // Red for inactive

  @override
  List<KanbanDetail> get details {
    final details = <KanbanDetail>[];

    if (specialDay.description.isNotEmpty) {
      details.add(
        KanbanDetail(
          icon: Icons.description,
          label: 'Description',
          value: specialDay.description,
        ),
      );
    }

    details.add(
      KanbanDetail(
        icon: Icons.list,
        label: 'Total Details',
        value: '${specialDay.detailsCount}',
        valueColor: AppColors.info,
      ),
    );

    if (specialDay.activeDetailsCount > 0) {
      details.add(
        KanbanDetail(
          icon: Icons.check_circle,
          label: 'Active Details',
          value: '${specialDay.activeDetailsCount}',
          valueColor: const Color(0xFF059669),
        ),
      );
    }

    final inactiveDetails =
        specialDay.detailsCount - specialDay.activeDetailsCount;
    if (inactiveDetails > 0) {
      details.add(
        KanbanDetail(
          icon: Icons.cancel,
          label: 'Inactive Details',
          value: '$inactiveDetails',
          valueColor: const Color(0xFFDC2626),
        ),
      );
    }

    // // Add date range info if we have details
    // if (specialDay.specialDayDetails.isNotEmpty) {
    //   final firstDetail = specialDay.specialDayDetails.first;
    //   details.add(
    //     KanbanDetail(
    //       icon: Icons.date_range,
    //       label: 'Example Date',
    //       value: firstDetail.dateRangeDisplay,
    //       valueColor: AppColors.primary,
    //     ),
    //   );
    // }

    return details;
  }

  @override
  List<Widget> get smartChips {
    final chips = <Widget>[];

    // Add date range chips for active details
    final activeDetails = specialDay.specialDayDetails
        .where((d) => d.active)
        .toList();

    if (activeDetails.isNotEmpty) {
      // Take first few active details to show as chips
      final detailsToShow = activeDetails.take(3).toList();

      for (final detail in detailsToShow) {
        final startDate = detail.startDate;
        final endDate = detail.endDate;
        final isSameYear = startDate.year == endDate.year;

        String dateText;
        if (startDate.year == endDate.year &&
            startDate.month == endDate.month &&
            startDate.day == endDate.day) {
          // Single day
          dateText = '${startDate.day}/${startDate.month}/${startDate.year}';
        } else if (isSameYear) {
          // Same year, different dates
          dateText =
              '${startDate.day}/${startDate.month} - ${endDate.day}/${endDate.month}/${endDate.year}';
        } else {
          // Different years
          dateText =
              '${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}';
        }

        chips.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              dateText,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ),
        );
      }

      // If there are more details, show a "+X more" chip
      if (activeDetails.length > 3) {
        chips.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Text(
              '+${activeDetails.length - 3} more',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.info,
              ),
            ),
          ),
        );
      }
    }

    return chips;
  }

  @override
  bool get isActive => specialDay.active;
}

/// Kanban configuration for special days
class SpecialDayKanbanConfig {
  static List<KanbanColumn> get columns => [
    const KanbanColumn(
      key: 'active_configured',
      title: 'Active & Configured',
      icon: Icons.check_circle,
      color: Color(0xFF059669), // Green
      emptyMessage: 'No active configured special days',
    ),
    const KanbanColumn(
      key: 'active_pending',
      title: 'Active & Pending',
      icon: Icons.schedule,
      color: Color(0xFFF59E0B), // Orange
      emptyMessage: 'No active pending special days',
    ),
    const KanbanColumn(
      key: 'active_empty',
      title: 'Active & Empty',
      icon: Icons.warning,
      color: Color(0xFF3B82F6), // Blue
      emptyMessage: 'No active empty special days',
    ),
    const KanbanColumn(
      key: 'inactive',
      title: 'Inactive',
      icon: Icons.cancel,
      color: Color(0xFFDC2626), // Red
      emptyMessage: 'No inactive special days',
    ),
  ];

  static List<KanbanAction> getActions({
    Function(SpecialDay)? onView,
    Function(SpecialDay)? onEdit,
    Function(SpecialDay)? onDelete,
    Function(SpecialDay)? onManageDetails,
  }) {
    final actions = <KanbanAction>[];

    if (onView != null) {
      actions.add(
        KanbanAction(
          key: 'view',
          label: 'View Details',
          icon: Icons.visibility,
          color: AppColors.primary,
          onTap: (item) => onView((item as SpecialDayKanbanItem).specialDay),
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
          onTap: (item) => onEdit((item as SpecialDayKanbanItem).specialDay),
        ),
      );
    }

    // if (onManageDetails != null) {
    //   actions.add(
    //     KanbanAction(
    //       key: 'details',
    //       label: 'Manage Details',
    //       icon: Icons.list,
    //       color: AppColors.info,
    //       onTap: (item) =>
    //           onManageDetails((item as SpecialDayKanbanItem).specialDay),
    //     ),
    //   );
    // }

    if (onDelete != null) {
      actions.add(
        KanbanAction(
          key: 'delete',
          label: 'Delete',
          icon: Icons.delete,
          color: AppColors.error,
          onTap: (item) => onDelete((item as SpecialDayKanbanItem).specialDay),
        ),
      );
    }

    return actions;
  }
}
