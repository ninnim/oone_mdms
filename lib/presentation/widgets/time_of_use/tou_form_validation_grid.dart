import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/time_of_use.dart';
import '../../../core/models/time_band.dart';

/// Compact TOU validation grid for form dialogs
class TOUFormValidationGrid extends StatefulWidget {
  final List<TimeOfUseDetail> timeOfUseDetails;
  final List<TimeBand> availableTimeBands;
  final List<Channel> availableChannels;
  final List<int>? selectedChannelIds; // Filter for specific channels
  final int? selectedFilterChannelId; // For dropdown filter from parent
  final double? height;
  final bool showLegend;

  const TOUFormValidationGrid({
    super.key,
    required this.timeOfUseDetails,
    required this.availableTimeBands,
    required this.availableChannels,
    this.selectedChannelIds,
    this.selectedFilterChannelId,
    this.height = 400,
    this.showLegend = true,
  });

  @override
  State<TOUFormValidationGrid> createState() => _TOUFormValidationGridState();
}

class _TOUFormValidationGridState extends State<TOUFormValidationGrid> {
  Set<int> _visibleChannelIds = <int>{};
  int? _selectedFilterChannelId; // For dropdown filter

  @override
  void initState() {
    super.initState();
    // Initialize with all available channels if no specific selection provided
    _visibleChannelIds =
        (widget.selectedChannelIds?.toSet() ??
        widget.availableChannels.map((c) => c.id).toSet());

    // Use the filter channel ID from parent if provided
    _selectedFilterChannelId = widget.selectedFilterChannelId;
  }

  @override
  void didUpdateWidget(TOUFormValidationGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update visible channels when widget changes
    if (widget.selectedChannelIds != oldWidget.selectedChannelIds) {
      _visibleChannelIds =
          (widget.selectedChannelIds?.toSet() ??
          widget.availableChannels.map((c) => c.id).toSet());
    }

    // Update filter channel ID when it changes from parent
    if (widget.selectedFilterChannelId != oldWidget.selectedFilterChannelId) {
      _selectedFilterChannelId = widget.selectedFilterChannelId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (widget.showLegend) _buildLegend(),
          Expanded(child: _buildGrid()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    // Get the name of the filtered channel if one is selected
    String? filteredChannelName;
    if (_selectedFilterChannelId != null) {
      final filteredChannel = widget.availableChannels
          .cast<Channel?>()
          .firstWhere(
            (channel) => channel?.id == _selectedFilterChannelId,
            orElse: () => null,
          );
      filteredChannelName = filteredChannel?.name;
    }

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.spacing6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppSizes.spacing8),
              const Text(
                'TOU Validation Grid',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeMedium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              // Show filtered channel info if applicable
              if (filteredChannelName != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing8,
                    vertical: AppSizes.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.filter_alt,
                        size: 12,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: AppSizes.spacing4),
                      Text(
                        filteredChannelName,
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeSmall,
                          fontWeight: FontWeight.w500,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.spacing8),
              ],
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacing8,
                  vertical: AppSizes.spacing4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                child: Text(
                  '24h × 7d',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeSmall,
                    fontWeight: FontWeight.w500,
                    color: AppColors.info,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing12,
        vertical: AppSizes.spacing8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Text(
            'Legend:',
            style: TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: AppSizes.spacing12),
          _buildLegendItem('Covered', AppColors.success.withValues(alpha: 0.8)),
          _buildLegendItem('Overlap', AppColors.warning.withValues(alpha: 0.8)),
          _buildLegendItem('Conflict', AppColors.error.withValues(alpha: 0.8)),
          _buildLegendItem('Empty', AppColors.surface),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.spacing12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSizes.spacing4),
          Text(
            label,
            style: const TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final hours = List.generate(24, (index) => index);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spacing8),
      child: Column(
        children: [
          // Header row
          Row(
            children: [
              const SizedBox(width: 24), // Hour column width
              ...days.map(
                (day) => Expanded(
                  child: Container(
                    height: 20,
                    alignment: Alignment.center,
                    child: Text(
                      day,
                      style: const TextStyle(
                        fontSize: AppSizes.fontSizeSmall,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Grid rows
          ...hours.map((hour) => _buildGridRow(hour)),
        ],
      ),
    );
  }

  Widget _buildGridRow(int hour) {
    return Row(
      children: [
        // Hour label
        SizedBox(
          width: 24,
          height: 20,
          child: Text(
            '${hour.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontFamily: 'monospace',
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // Day cells
        ...List.generate(
          7,
          (dayIndex) => Expanded(child: _buildGridCell(hour, dayIndex)),
        ),
      ],
    );
  }

  Widget _buildGridCell(int hour, int dayIndex) {
    final validation = _validateTimeSlot(hour, dayIndex);
    final color = _getCellColor(validation);

    return Container(
      height: AppSizes.spacing20,
      margin: const EdgeInsets.all(0.5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
        border: validation.hasConflict
            ? Border.all(color: AppColors.error, width: 1.5)
            : validation.timeBands.length > 1
            ? Border.all(color: AppColors.warning, width: 1)
            : null,
      ),
      child: _buildCellContent(validation),
    );
  }

  Widget? _buildCellContent(TimeSlotValidation validation) {
    if (validation.isEmpty) {
      return null; // Empty cell
    }

    if (validation.timeBands.length == 1) {
      // Single time band - solid color
      return Container(
        decoration: BoxDecoration(
          color: _getTimeBandColor(
            validation.timeBands.first,
          ).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(2),
        ),
      );
    } else if (validation.timeBands.length > 1) {
      // Multiple time bands - striped pattern
      return CustomPaint(
        painter: _MiniStripePainter(
          colors: validation.timeBands
              .map((id) => _getTimeBandColor(id).withValues(alpha: 0.8))
              .toList(),
        ),
      );
    }

    return null;
  }

  // Validation logic
  TimeSlotValidation _validateTimeSlot(int hour, int dayIndex) {
    // Start with all details
    var filteredDetails = widget.timeOfUseDetails.where(
      (detail) => detail.active,
    );

    // Apply channel filtering based on selected filter channel
    if (_selectedFilterChannelId != null) {
      // If a specific channel is selected in the filter, only show that channel
      filteredDetails = filteredDetails.where(
        (detail) => detail.channelId == _selectedFilterChannelId,
      );
    } else {
      // If no specific filter selected, show all visible channels
      filteredDetails = filteredDetails.where(
        (detail) => _visibleChannelIds.contains(detail.channelId),
      );
    }

    final applicableDetails = filteredDetails.where((detail) {
      final timeBand = widget.availableTimeBands.cast<TimeBand?>().firstWhere(
        (tb) => tb?.id == detail.timeBandId,
        orElse: () => null,
      );

      if (timeBand == null || !timeBand.active) return false;

      return _isTimeBandActiveAt(timeBand, hour, dayIndex);
    }).toList();

    // Group by channel to detect conflicts properly
    final channelGroups = <int, List<TimeOfUseDetail>>{};
    for (final detail in applicableDetails) {
      channelGroups.putIfAbsent(detail.channelId, () => []).add(detail);
    }

    // Check for conflicts within the same channel
    bool hasConflict = false;
    for (final channelDetails in channelGroups.values) {
      if (channelDetails.length > 1) {
        // Multiple time bands for same channel at same time = conflict
        final uniqueTimeBands = channelDetails.map((d) => d.timeBandId).toSet();
        if (uniqueTimeBands.length > 1) {
          hasConflict = true;
          break;
        }
      }
    }

    return TimeSlotValidation(
      hour: hour,
      dayIndex: dayIndex,
      timeBands: applicableDetails.map((d) => d.timeBandId).toList(),
      channels: applicableDetails.map((d) => d.channelId).toList(),
      hasConflict: hasConflict,
      isEmpty: applicableDetails.isEmpty,
      channelGroups: channelGroups,
    );
  }

  bool _isTimeBandActiveAt(TimeBand timeBand, int hour, int dayIndex) {
    // Check day of week if specified
    if (timeBand.daysOfWeek.isNotEmpty) {
      // API uses 0-based indexing: 0=Sunday, 1=Monday, etc.
      // Grid dayIndex also uses 0-based: 0=Sunday, 1=Monday, etc.
      // So we can use dayIndex directly
      if (!timeBand.daysOfWeek.contains(dayIndex)) return false;
    }

    // Check time range - parse string times like "17:00:00"
    try {
      final startHour = _parseTimeString(timeBand.startTime);
      final endHour = _parseTimeString(timeBand.endTime);

      // Handle 24-hour coverage (00:00:00 to 23:59:59)
      if (startHour == 0 && endHour == 24) {
        return true; // Covers all 24 hours
      }

      if (startHour <= endHour) {
        return hour >= startHour && hour < endHour;
      } else {
        // Spans midnight
        return hour >= startHour || hour < endHour;
      }
    } catch (e) {
      return false;
    }
  }

  int _parseTimeString(String timeString) {
    final parts = timeString.split(':');
    if (parts.isNotEmpty) {
      final hour = int.parse(parts[0]);
      final minute = parts.length > 1 ? int.parse(parts[1]) : 0;
      final second = parts.length > 2 ? int.parse(parts[2]) : 0;

      // Handle 23:59:59 as covering the full hour (24-hour format)
      if (hour == 23 && minute == 59 && second == 59) {
        return 24; // Treat as end of day
      }
      return hour;
    }
    return 0;
  }

  Color _getCellColor(TimeSlotValidation validation) {
    if (validation.hasConflict) {
      return AppColors.error.withValues(alpha: 0.4);
    }
    if (validation.isEmpty) {
      return AppColors.surface; // Use surface color for empty slots
    }
    if (validation.timeBands.length > 1) {
      // Multiple time bands (overlap but no conflict)
      return AppColors.warning.withValues(alpha: 0.3);
    }
    if (validation.timeBands.isNotEmpty) {
      // Single time band coverage
      return AppColors.success.withValues(alpha: 0.2);
    }
    return AppColors.surface;
  }

  Color _getTimeBandColor(int timeBandId) {
    // Get consistent colors for time bands
    final timeBand = widget.availableTimeBands.cast<TimeBand?>().firstWhere(
      (tb) => tb?.id == timeBandId,
      orElse: () => null,
    );

    if (timeBand == null) return AppColors.textTertiary;

    // Generate consistent color based on time band ID
    final colors = [
      AppColors.primary,
      AppColors.success,
      AppColors.warning,
      AppColors.info,
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF795548), // Brown
      const Color(0xFF607D8B), // Blue Grey
      const Color(0xFFE91E63), // Pink
      const Color(0xFF009688), // Teal
      const Color(0xFFFF5722), // Deep Orange
    ];
    return colors[timeBandId % colors.length];
  }
}

// Supporting classes
class TimeSlotValidation {
  final int hour;
  final int dayIndex;
  final List<int> timeBands;
  final List<int> channels;
  final bool hasConflict;
  final bool isEmpty;
  final Map<int, List<TimeOfUseDetail>> channelGroups;

  TimeSlotValidation({
    required this.hour,
    required this.dayIndex,
    required this.timeBands,
    required this.channels,
    required this.hasConflict,
    required this.isEmpty,
    required this.channelGroups,
  });
}

class _MiniStripePainter extends CustomPainter {
  final List<Color> colors;

  _MiniStripePainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    if (colors.isEmpty) return;

    final stripeWidth = size.width / colors.length;
    for (int i = 0; i < colors.length; i++) {
      final paint = Paint()..color = colors[i];
      canvas.drawRect(
        Rect.fromLTWH(i * stripeWidth, 0, stripeWidth, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
