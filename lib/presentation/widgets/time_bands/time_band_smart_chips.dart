import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/season.dart';
import '../../../core/models/special_day.dart';

class TimeBandSmartChips {
  /// Build smart day-of-week chips for display
  static Widget buildDayOfWeekChips(List<int> daysOfWeek) {
    return _buildDayChips(daysOfWeek);
  }

  /// Build smart month-of-year chips for display
  static Widget buildMonthOfYearChips(List<int> monthsOfYear) {
    return _buildMonthChips(monthsOfYear);
  }

  /// Build colored day chips for display with smart "More..." functionality
  static Widget _buildDayChips(List<int> daysOfWeek) {
    if (daysOfWeek.isEmpty) {
      return const Text(
        'No days selected',
        style: TextStyle(
          fontSize: AppSizes.fontSizeSmall,
          color: AppColors.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    const dayNames = [
      'Sun', // 0
      'Mon', // 1
      'Tue', // 2
      'Wed', // 3
      'Thu', // 4
      'Fri', // 5
      'Sat', // 6
    ];

    // Colors for each day
    const dayColors = [
      Color(0xFFEF4444), // Sun - Red
      Color(0xFF3B82F6), // Mon - Blue
      Color(0xFF10B981), // Tue - Green
      Color(0xFFF59E0B), // Wed - Amber
      Color(0xFF8B5CF6), // Thu - Purple
      Color(0xFF06B6D4), // Fri - Cyan
      Color(0xFFEC4899), // Sat - Pink
    ];

    // Sort days for consistent display (0=Sunday to 6=Saturday)
    final sortedDays = List.from(daysOfWeek)..sort();

    // Use LayoutBuilder to determine available space and show "More..." automatically
    return LayoutBuilder(
      builder: (context, constraints) {
        const chipMinWidth = 40.0; // Minimum width per chip including spacing
        const moreButtonWidth = 65.0; // Width for "More..." button
        final availableWidth = constraints.maxWidth;

        // Calculate max chips that can fit
        int calculatedMaxVisible =
            ((availableWidth - moreButtonWidth) / chipMinWidth).floor();
        calculatedMaxVisible = calculatedMaxVisible.clamp(1, sortedDays.length);

        // If we can fit all days, show them all
        if (sortedDays.length <= calculatedMaxVisible ||
            availableWidth > (sortedDays.length * chipMinWidth)) {
          return Wrap(
            spacing: 4,
            runSpacing: 4,
            children: sortedDays.map((dayIndex) {
              final displayName = dayNames[dayIndex];
              final color = dayColors[dayIndex];

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
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

        // Show limited days with "More..." dropdown
        return StatefulBuilder(
          builder: (context, setState) {
            return Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                // Show first few days that can fit
                ...sortedDays.take(calculatedMaxVisible).map((dayIndex) {
                  final displayName = dayNames[dayIndex];
                  final color = dayColors[dayIndex];

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
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
                if (sortedDays.length > calculatedMaxVisible)
                  PopupMenuButton<int>(
                    offset: const Offset(0, 30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.success.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '+${sortedDays.length - calculatedMaxVisible} more',
                            style: const TextStyle(
                              fontSize: AppSizes.fontSizeExtraSmall,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            size: 12,
                            color: AppColors.success,
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
                                'All selected days:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: AppSizes.fontSizeSmall,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: sortedDays.map((dayIndex) {
                                  final displayName = dayNames[dayIndex];
                                  final color = dayColors[dayIndex];

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
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

  /// Build colored month chips for display with smart "More..." functionality
  static Widget _buildMonthChips(List<int> monthsOfYear) {
    if (monthsOfYear.isEmpty) {
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

    // Colors for each month - seasonal colors (same as seasons)
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

    // Sort months for consistent display
    final sortedMonths = List.from(monthsOfYear)..sort();

    // Use LayoutBuilder to determine available space and show "More..." automatically
    return LayoutBuilder(
      builder: (context, constraints) {
        const chipMinWidth = 45.0; // Minimum width per chip including spacing
        const moreButtonWidth = 65.0; // Width for "More..." button
        final availableWidth = constraints.maxWidth;

        // Calculate max chips that can fit
        int calculatedMaxVisible =
            ((availableWidth - moreButtonWidth) / chipMinWidth).floor();
        calculatedMaxVisible = calculatedMaxVisible.clamp(
          1,
          sortedMonths.length,
        );

        // If we can fit all months, show them all
        if (sortedMonths.length <= calculatedMaxVisible ||
            availableWidth > (sortedMonths.length * chipMinWidth)) {
          return Wrap(
            spacing: 4,
            runSpacing: 4,
            children: sortedMonths.map((monthIndex) {
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
                ...sortedMonths.take(calculatedMaxVisible).map((monthIndex) {
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
                if (sortedMonths.length > calculatedMaxVisible)
                  PopupMenuButton<int>(
                    offset: const Offset(0, 30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '+${sortedMonths.length - calculatedMaxVisible} more',
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
                                'All selected months:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: AppSizes.fontSizeSmall,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: sortedMonths.map((monthIndex) {
                                  final displayName =
                                      monthNames[monthIndex - 1];
                                  final color = monthColors[monthIndex - 1];

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: color.withOpacity(0.3),
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

  /// Build season chips with smart overflow and names
  static Widget buildSeasonChips(
    List<int> seasonIds,
    List<Season> availableSeasons,
  ) {
    if (seasonIds.isEmpty) {
      return const Text(
        'No seasons selected',
        style: TextStyle(
          fontSize: AppSizes.fontSizeSmall,
          color: AppColors.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    // Create a map for quick season lookup
    final seasonMap = {for (var season in availableSeasons) season.id: season};

    // Use LayoutBuilder to determine available space and show "More..." automatically
    return LayoutBuilder(
      builder: (context, constraints) {
        const chipMinWidth = 70.0; // Minimum width per chip including spacing
        const moreButtonWidth = 70.0; // Width for "More..." button
        final availableWidth = constraints.maxWidth;

        // Calculate max chips that can fit
        int calculatedMaxVisible =
            ((availableWidth - moreButtonWidth) / chipMinWidth).floor();
        calculatedMaxVisible = calculatedMaxVisible.clamp(1, seasonIds.length);

        // If we can fit all seasons, show them all
        if (seasonIds.length <= calculatedMaxVisible ||
            availableWidth > (seasonIds.length * chipMinWidth)) {
          return Wrap(
            spacing: 4,
            runSpacing: 4,
            children: seasonIds.map((seasonId) {
              final season = seasonMap[seasonId];
              final displayName = season?.name ?? 'Season $seasonId';

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.warning.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeExtraSmall,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
              );
            }).toList(),
          );
        }

        // Show limited seasons with "More..." dropdown
        return StatefulBuilder(
          builder: (context, setState) {
            return Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                // Show first few seasons that can fit
                ...seasonIds.take(calculatedMaxVisible).map((seasonId) {
                  final season = seasonMap[seasonId];
                  final displayName = season?.name ?? 'Season $seasonId';

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.warning.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: AppSizes.fontSizeExtraSmall,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  );
                }),
                // "More..." dropdown button
                if (seasonIds.length > calculatedMaxVisible)
                  PopupMenuButton<int>(
                    offset: const Offset(0, 30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.warning.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '+${seasonIds.length - calculatedMaxVisible} more',
                            style: const TextStyle(
                              fontSize: AppSizes.fontSizeExtraSmall,
                              fontWeight: FontWeight.w600,
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            size: 12,
                            color: AppColors.warning,
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
                                'All selected seasons:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: AppSizes.fontSizeSmall,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: seasonIds.map((seasonId) {
                                  final season = seasonMap[seasonId];
                                  final displayName =
                                      season?.name ?? 'Season $seasonId';

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.warning.withOpacity(
                                          0.3,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      displayName,
                                      style: const TextStyle(
                                        fontSize: AppSizes.fontSizeExtraSmall,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.warning,
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

  /// Build special day chips with smart overflow and names
  static Widget buildSpecialDayChips(
    List<int> specialDayIds,
    List<SpecialDay> availableSpecialDays,
  ) {
    if (specialDayIds.isEmpty) {
      return const Text(
        'No special days selected',
        style: TextStyle(
          fontSize: AppSizes.fontSizeSmall,
          color: AppColors.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    // Create a map for quick special day lookup
    final specialDayMap = {
      for (var specialDay in availableSpecialDays) specialDay.id: specialDay,
    };

    // Use LayoutBuilder to determine available space and show "More..." automatically
    return LayoutBuilder(
      builder: (context, constraints) {
        const chipMinWidth = 80.0; // Minimum width per chip including spacing
        const moreButtonWidth = 70.0; // Width for "More..." button
        final availableWidth = constraints.maxWidth;

        // Calculate max chips that can fit
        int calculatedMaxVisible =
            ((availableWidth - moreButtonWidth) / chipMinWidth).floor();
        calculatedMaxVisible = calculatedMaxVisible.clamp(
          1,
          specialDayIds.length,
        );

        // If we can fit all special days, show them all
        if (specialDayIds.length <= calculatedMaxVisible ||
            availableWidth > (specialDayIds.length * chipMinWidth)) {
          return Wrap(
            spacing: 4,
            runSpacing: 4,
            children: specialDayIds.map((specialDayId) {
              final specialDay = specialDayMap[specialDayId];
              final displayName =
                  specialDay?.name ?? 'Special Day $specialDayId';

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.secondary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeExtraSmall,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              );
            }).toList(),
          );
        }

        // Show limited special days with "More..." dropdown
        return StatefulBuilder(
          builder: (context, setState) {
            return Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                // Show first few special days that can fit
                ...specialDayIds.take(calculatedMaxVisible).map((specialDayId) {
                  final specialDay = specialDayMap[specialDayId];
                  final displayName =
                      specialDay?.name ?? 'Special Day $specialDayId';

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.secondary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: AppSizes.fontSizeExtraSmall,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                    ),
                  );
                }),
                // "More..." dropdown button
                if (specialDayIds.length > calculatedMaxVisible)
                  PopupMenuButton<int>(
                    offset: const Offset(0, 30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.secondary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '+${specialDayIds.length - calculatedMaxVisible} more',
                            style: const TextStyle(
                              fontSize: AppSizes.fontSizeExtraSmall,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            size: 12,
                            color: AppColors.secondary,
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
                                'All selected special days:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: AppSizes.fontSizeSmall,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: specialDayIds.map((specialDayId) {
                                  final specialDay =
                                      specialDayMap[specialDayId];
                                  final displayName =
                                      specialDay?.name ??
                                      'Special Day $specialDayId';

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.secondary.withOpacity(
                                          0.3,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      displayName,
                                      style: const TextStyle(
                                        fontSize: AppSizes.fontSizeExtraSmall,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.secondary,
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
}
