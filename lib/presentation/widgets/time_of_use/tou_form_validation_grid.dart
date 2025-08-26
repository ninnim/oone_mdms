import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';
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
    print('🔄 Validation Grid: didUpdateWidget called');

    // Update visible channels when widget changes
    if (widget.selectedChannelIds != oldWidget.selectedChannelIds) {
      print('📊 Validation Grid: Selected channel IDs changed');
      _visibleChannelIds =
          (widget.selectedChannelIds?.toSet() ??
          widget.availableChannels.map((c) => c.id).toSet());
    }

    // Update filter channel ID when it changes from parent
    if (widget.selectedFilterChannelId != oldWidget.selectedFilterChannelId) {
      print(
        '🔍 Validation Grid: Filter channel ID changed from ${oldWidget.selectedFilterChannelId} to ${widget.selectedFilterChannelId}',
      );
      _selectedFilterChannelId = widget.selectedFilterChannelId;

      // Force legend and grid color update by triggering rebuild
      setState(() {
        // State update to trigger rebuild with new filter
      });
    }

    // Check for time of use details changes
    if (widget.timeOfUseDetails != oldWidget.timeOfUseDetails) {
      print(
        '📋 Validation Grid: TOU details changed - Old: ${oldWidget.timeOfUseDetails.length}, New: ${widget.timeOfUseDetails.length}',
      );
    }

    // Check for time bands changes
    if (widget.availableTimeBands != oldWidget.availableTimeBands) {
      print(
        '⏰ Validation Grid: Available time bands changed - Old: ${oldWidget.availableTimeBands.length}, New: ${widget.availableTimeBands.length}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate available space for the grid
        final availableHeight = constraints.maxHeight;
        final availableWidth = constraints.maxWidth;

        return Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              if (widget.showLegend) _buildLegend(),
              Expanded(
                child: _buildResponsiveGrid(availableWidth, availableHeight),
              ),
            ],
          ),
        );
      },
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
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.borderColor)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.spacing6),
                decoration: BoxDecoration(
                  color: context.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                child: Icon(
                  Icons.grid_view_rounded,
                  color: context.primaryColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppSizes.spacing8),
              Text(
                'TOU Validation Grid',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeMedium,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimaryColor,
                ),
              ),
              const Spacer(),
              // Show filtered channel info if applicable
              if (filteredChannelName != null) ...[
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.spacing8,
                      vertical: AppSizes.spacing4,
                    ),
                    decoration: BoxDecoration(
                      color: context.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                      border: Border.all(
                        color: context.warningColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.filter_alt,
                          size: 12,
                          color: context.warningColor,
                        ),
                        const SizedBox(width: AppSizes.spacing4),
                        Expanded(
                          child: Text(
                            filteredChannelName,
                            style: TextStyle(
                              fontSize: AppSizes.fontSizeSmall,
                              fontWeight: FontWeight.w500,
                              color: context.warningColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
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
                  color: context.infoColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                child: Text(
                  '24h × 7d',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeSmall,
                    fontWeight: FontWeight.w500,
                    color: context.infoColor,
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
      decoration: BoxDecoration(
        color: context.backgroundColor,
        border: Border(bottom: BorderSide(color: context.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Channel and Time Band Legend - Responsive
          LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                alignment: Alignment.centerLeft,
                child: _buildResponsiveLegend(constraints.maxWidth),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveLegend(double availableWidth) {
    // Get the channels that have data
    final channelsWithData = <int, List<TimeBand>>{};

    // Group time bands by channel, considering filter
    for (final detail in widget.timeOfUseDetails) {
      // Apply channel filtering logic
      bool shouldInclude = false;

      if (_selectedFilterChannelId != null) {
        shouldInclude = detail.channelId == _selectedFilterChannelId;
      } else {
        shouldInclude = _visibleChannelIds.contains(detail.channelId);
      }

      if (shouldInclude) {
        final timeBand = widget.availableTimeBands.cast<TimeBand?>().firstWhere(
          (tb) => tb?.id == detail.timeBandId,
          orElse: () => null,
        );

        if (timeBand != null) {
          channelsWithData.putIfAbsent(detail.channelId, () => <TimeBand>[]);
          if (!channelsWithData[detail.channelId]!.any(
            (tb) => tb.id == timeBand.id,
          )) {
            channelsWithData[detail.channelId]!.add(timeBand);
          }
        }
      }
    }

    if (channelsWithData.isEmpty) {
      print(
        '🎨 Legend: No channels with data to display (filter: $_selectedFilterChannelId)',
      );
      return const SizedBox.shrink();
    }

    print(
      '🎨 Legend: Displaying ${channelsWithData.length} channels (filter: $_selectedFilterChannelId): ${channelsWithData.keys.toList()}',
    );

    // Determine layout based on available width
    final isCompact = availableWidth < 600;
    final titleFontSize = isCompact ? 12.0 : 18.0;
    final itemFontSize = isCompact ? 12.0 : 14.0;
    final colorBoxSize = isCompact ? 12.0 : 14.0;
    final spacing = isCompact ? 8.0 : 12.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Channel Time Band Colors:',
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.w600,
            color: context.textPrimaryColor,
          ),
        ),
        SizedBox(height: isCompact ? 4 : 6),

        // Display channels in a responsive layout
        Wrap(
          spacing: spacing,
          runSpacing: isCompact ? 4 : 6,
          children: channelsWithData.entries.map((entry) {
            final channelId = entry.key;
            final timeBands = entry.value;

            // Get channel info
            final channel = widget.availableChannels
                .cast<Channel?>()
                .firstWhere((c) => c?.id == channelId, orElse: () => null);

            final channelDisplayName = channel?.code.isNotEmpty == true
                ? channel!.code
                : channel?.name ?? 'CH$channelId';

            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 4 : 6,
                vertical: isCompact ? 2 : 3,
              ),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      channelDisplayName,
                      style: TextStyle(
                        fontSize: itemFontSize,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: isCompact ? 4 : 6),

                  // Time band colors
                  ...timeBands.asMap().entries.map((tbEntry) {
                    final tbIndex = tbEntry.key;
                    final timeBand = tbEntry.value;
                    final color = _getChannelTimeBandColor(channelId, tbIndex);

                    return Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Tooltip(
                        message: timeBand.name,
                        child: Container(
                          width: colorBoxSize,
                          height: colorBoxSize,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(
                              color: context.borderColor,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Method to get consistent colors for channel time bands in legend
  Color _getChannelTimeBandColor(int channelId, int timeBandIndex) {
    // Create a list of distinct colors for time bands
    final colors = [
      context.primaryColor, // Blue
      context.successColor, // Green
      context.warningColor, // Orange
      context.errorColor, // Red
      context.infoColor, // Cyan
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF795548), // Brown
      const Color(0xFF607D8B), // Blue Grey
    ];

    // Use channel ID and time band index to ensure consistent coloring
    final colorIndex = (channelId.hashCode + timeBandIndex) % colors.length;
    return colors[colorIndex];
  }

  Widget _buildResponsiveGrid(double availableWidth, double availableHeight) {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final hours = List.generate(24, (index) => index);

    // Calculate responsive sizes based on available space
    final isCompact = availableWidth < 600;
    final hourColumnWidth = isCompact ? 24.0 : 32.0;
    final cellHeight = isCompact ? 22.0 : 28.0;
    final headerHeight = isCompact ? 22.0 : 28.0;
    final fontSize = isCompact ? 12.0 : 18.0;
    final padding = isCompact ? 2.0 : 4.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: availableHeight - 120, // Account for header and legend
          minWidth: availableWidth,
        ),
        child: IntrinsicHeight(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header row
              _buildGridHeader(days, hourColumnWidth, headerHeight, fontSize),

              // Grid rows - with proper overflow handling
              ...hours.map(
                (hour) => _buildResponsiveGridRow(
                  hour,
                  hourColumnWidth,
                  cellHeight,
                  fontSize,
                  availableWidth,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridHeader(
    List<String> days,
    double hourColumnWidth,
    double headerHeight,
    double fontSize,
  ) {
    return Row(
      children: [
        SizedBox(width: hourColumnWidth),
        ...days.map(
          (day) => Expanded(
            child: Container(
              height: headerHeight,
              alignment: Alignment.center,
              child: Text(
                day,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimaryColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveGridRow(
    int hour,
    double hourColumnWidth,
    double cellHeight,
    double fontSize,
    double availableWidth,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        // Hour label
        SizedBox(
          width: hourColumnWidth,
          height: cellHeight,
          child: Center(
            child: Text(
              '${hour.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: fontSize,
                color: context.textSecondaryColor,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),

        // Day cells - with proper flex and overflow handling
        ...List.generate(
          7,
          (dayIndex) => Expanded(
            flex: 1,
            child: _buildResponsiveGridCell(hour, dayIndex, cellHeight),
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveGridCell(int hour, int dayIndex, double cellHeight) {
    final validation = _validateTimeSlot(hour, dayIndex);
    final color = _getCellColor(validation);

    return Container(
      height: cellHeight,
      margin: const EdgeInsets.all(0.5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
        border: validation.hasConflict
            ? Border.all(color: context.errorColor, width: 1.5)
            : validation.timeBands.length > 1
            ? Border.all(color: context.warningColor, width: 1)
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
      final timeBandId = validation.timeBands.first;
      final color = _getTimeBandColorForGrid(timeBandId);

      return Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.8),
          borderRadius: BorderRadius.circular(2),
        ),
      );
    } else if (validation.timeBands.length > 1) {
      // Multiple time bands - striped pattern
      final colors = validation.timeBands
          .map((id) => _getTimeBandColorForGrid(id).withOpacity(0.8))
          .toList();

      return CustomPaint(painter: _MiniStripePainter(colors: colors));
    }

    return null;
  }

  // Get time band color for grid cells - matches legend colors
  Color _getTimeBandColorForGrid(int timeBandId) {
    // Find which channel this time band belongs to and its index within that channel
    for (final detail in widget.timeOfUseDetails) {
      // Apply same filtering logic as in validation
      bool shouldInclude = false;

      if (_selectedFilterChannelId != null) {
        // If a specific channel is selected in filter, only consider that channel
        shouldInclude = detail.channelId == _selectedFilterChannelId;
      } else {
        // If no specific filter selected, consider all visible channels
        shouldInclude = _visibleChannelIds.contains(detail.channelId);
      }

      if (detail.timeBandId == timeBandId && shouldInclude) {
        // Get all time bands for this channel (considering filter)
        final channelTimeBands =
            widget.timeOfUseDetails
                .where((d) {
                  if (_selectedFilterChannelId != null) {
                    return d.channelId == detail.channelId &&
                        d.channelId == _selectedFilterChannelId;
                  } else {
                    return d.channelId == detail.channelId &&
                        _visibleChannelIds.contains(d.channelId);
                  }
                })
                .map((d) => d.timeBandId)
                .toSet()
                .toList()
              ..sort(); // Sort for consistent indexing

        final timeBandIndex = channelTimeBands.indexOf(timeBandId);
        if (timeBandIndex >= 0) {
          return _getChannelTimeBandColor(detail.channelId, timeBandIndex);
        }
      }
    }

    // Fallback to original method if not found
    return _getTimeBandColor(timeBandId);
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
      return context.errorColor.withOpacity(0.4);
    }
    if (validation.isEmpty) {
      return context.surfaceColor; // Use surface color for empty slots
    }
    if (validation.timeBands.length > 1) {
      // Multiple time bands (overlap but no conflict)
      return context.warningColor.withOpacity(0.3);
    }
    if (validation.timeBands.isNotEmpty) {
      // Single time band coverage
      return context.successColor.withOpacity(0.2);
    }
    return context.surfaceColor;
  }

  Color _getTimeBandColor(int timeBandId) {
    // Get consistent colors for time bands
    final timeBand = widget.availableTimeBands.cast<TimeBand?>().firstWhere(
      (tb) => tb?.id == timeBandId,
      orElse: () => null,
    );

    if (timeBand == null) return context.textSecondaryColor;

    // Generate consistent color based on time band ID
    final colors = [
      context.primaryColor,
      context.successColor,
      context.warningColor,
      context.infoColor,
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






