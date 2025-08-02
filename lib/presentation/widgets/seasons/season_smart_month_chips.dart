import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class SeasonSmartMonthChips {
  // /// Available column identifiers
  // static const List<String> availableColumns = [
  //   'name',
  //   'description',
  //   'monthRange',
  //   'active',
  //   'actions',
  // ];

  /// Reusable smart month chip widget that can be used in both table and kanban views
  static Widget buildSmartMonthChips(List<int> monthRange) {
    return _buildMonthChips(monthRange);
  }

  /// Build colored month chips for display with smart "More..." functionality
  static Widget _buildMonthChips(List<int> monthRange) {
    if (monthRange.isEmpty) {
      return const Text(
        'No months selected',
        style: TextStyle(
          fontSize: AppSizes.fontSizeSmall,
          color: AppColors.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    // Colors for each month - seasonal colors
    const monthColors = [
      Color(0xFF3B82F6), // Jan - Blue (Winter)
      Color(0xFF6366F1), // Feb - Indigo (Winter)
      Color(0xFF10B981), // Mar - Green (Spring)
      Color(0xFF059669), // Apr - Emerald (Spring)
      Color(0xFF84CC16), // May - Lime (Spring)
      Color(0xFFF59E0B), // Jun - Amber (Summer)
      Color(0xFFEF4444), // Jul - Red (Summer)
      Color(0xFFDC2626), // Aug - Red-600 (Summer)
      Color(0xFFF97316), // Sep - Orange (Autumn)
      Color(0xFFEA580C), // Oct - Orange-600 (Autumn)
      Color(0xFF8B5CF6), // Nov - Purple (Autumn)
      Color(0xFF1E40AF), // Dec - Blue-700 (Winter)
    ];

    // Use LayoutBuilder to determine available space and show "More..." automatically
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate available width and determine how many chips can fit
        const chipMinWidth = 45.0; // Minimum width per chip including spacing
        const moreButtonWidth = 65.0; // Width for "More..." button
        final availableWidth = constraints.maxWidth;

        // Calculate max chips that can fit (reserve space for "More..." if needed)
        int calculatedMaxVisible =
            ((availableWidth - moreButtonWidth) / chipMinWidth).floor();
        calculatedMaxVisible = calculatedMaxVisible.clamp(1, monthRange.length);

        // If we can fit all months, show them all
        if (monthRange.length <= calculatedMaxVisible ||
            availableWidth > (monthRange.length * chipMinWidth)) {
          return Wrap(
            spacing: 4,
            runSpacing: 4,
            children: monthRange.map((monthIndex) {
              final displayName = monthNames[monthIndex - 1];
              final color = monthColors[monthIndex - 1];

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  displayName,
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeExtraSmall,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              );
            }).toList(),
          );
        }

        // Show limited months with "More..." dropdown
        return StatefulBuilder(
          builder: (context, setState) {
            return Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                // Show first few months that can fit
                ...monthRange.take(calculatedMaxVisible).map((monthIndex) {
                  final displayName = monthNames[monthIndex - 1];
                  final color = monthColors[monthIndex - 1];

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: color.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      displayName,
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeExtraSmall,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  );
                }),
                // "More..." dropdown button
                if (monthRange.length > calculatedMaxVisible)
                  PopupMenuButton<int>(
                    offset: const Offset(0, 30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '+${monthRange.length - calculatedMaxVisible} more',
                            style: const TextStyle(
                              fontSize: AppSizes.fontSizeExtraSmall,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            size: 12,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem<int>(
                        enabled: false,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'All months:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: AppSizes.fontSizeSmall,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: monthRange.map((monthIndex) {
                                  final displayName =
                                      monthNames[monthIndex - 1];
                                  final color = monthColors[monthIndex - 1];

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: color.withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      displayName,
                                      style: TextStyle(
                                        fontSize: AppSizes.fontSizeExtraSmall,
                                        fontWeight: FontWeight.w600,
                                        color: color,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            );
          },
        );
      },
    );
  }

  /// Get month range display with full month names
  static String getFullMonthRangeDisplay(List<int> monthRange) {
    if (monthRange.isEmpty) return 'No months selected';

    const monthNames = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final monthNamesList = monthRange
        .where((month) => month >= 1 && month <= 12)
        .map((month) => monthNames[month])
        .toList();

    if (monthNamesList.length <= 2) {
      return monthNamesList.join(', ');
    } else if (monthNamesList.length <= 4) {
      return monthNamesList.join(', ');
    } else {
      return '${monthNamesList.take(3).join(', ')} and ${monthNamesList.length - 3} more';
    }
  }
}
