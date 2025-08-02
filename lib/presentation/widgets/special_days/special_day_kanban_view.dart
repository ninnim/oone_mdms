import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/special_day.dart';
import '../common/status_chip.dart';

class SpecialDayKanbanView {
  static Map<String, List<SpecialDay>> prepareKanbanData(
    List<SpecialDay> specialDays,
  ) {
    return {
      'Active': specialDays.where((sd) => sd.active).toList(),
      'Inactive': specialDays.where((sd) => !sd.active).toList(),
    };
  }

  static Widget buildSpecialDayCard(
    SpecialDay specialDay, {
    Function(SpecialDay)? onEdit,
    Function(SpecialDay)? onDelete,
    Function(SpecialDay)? onView,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacing12),
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with name and status
          Row(
            children: [
              Expanded(
                child: Text(
                  specialDay.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: AppSizes.fontSizeMedium,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              StatusChip(
                text: specialDay.active ? 'Active' : 'Inactive',
                compact: true,
                type: specialDay.active
                    ? StatusChipType.success
                    : StatusChipType.secondary,
              ),
            ],
          ),

          const SizedBox(height: AppSizes.spacing8),

          // Description
          Text(
            specialDay.description.isEmpty
                ? 'No description'
                : specialDay.description,
            style: const TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: AppSizes.spacing12),

          // Details count with enhanced display (matching Seasons month display)
          SizedBox(
            width: double.infinity,
            child: Container(
              alignment: Alignment.centerLeft,
              child: StatusChip(
                text: '${specialDay.detailsCount}',
                type: StatusChipType.info,
                compact: true,
              ),
            ),
            //  Container(
            //   padding: const EdgeInsets.symmetric(
            //     horizontal: AppSizes.spacing8,
            //     vertical: AppSizes.spacing4,
            //   ),
            //   decoration: BoxDecoration(
            //     color: AppColors.primary.withValues(alpha: 0.1),
            //     borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            //     border: Border.all(
            //       color: AppColors.primary.withValues(alpha: 0.2),
            //     ),
            //   ),
            //   child: Row(
            //     mainAxisSize: MainAxisSize.min,
            //     children: [
            //       Icon(Icons.event_note, size: 14, color: AppColors.primary),
            //       const SizedBox(width: AppSizes.spacing4),
            //       Text(
            //         '${specialDay.detailsCount} detail${specialDay.detailsCount == 1 ? '' : 's'}',
            //         style: const TextStyle(
            //           fontSize: AppSizes.fontSizeSmall,
            //           color: AppColors.primary,
            //           fontWeight: FontWeight.w500,
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
          ),

          const SizedBox(height: AppSizes.spacing12),

          // Actions dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                alignment: Alignment.center,
                height: AppSizes.spacing40,
                child: PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(
                            Icons.visibility,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: AppSizes.spacing8),
                          Text('View Details'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16, color: AppColors.warning),
                          SizedBox(width: AppSizes.spacing8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: AppColors.error),
                          SizedBox(width: AppSizes.spacing8),
                          Text(
                            'Delete',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'view':
                        onView?.call(specialDay);
                        break;
                      case 'edit':
                        onEdit?.call(specialDay);
                        break;
                      case 'delete':
                        onDelete?.call(specialDay);
                        break;
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
