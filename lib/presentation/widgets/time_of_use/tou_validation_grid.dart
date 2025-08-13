import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/time_of_use.dart';
import '../../../core/models/time_band.dart';
import '../common/app_button.dart';

/// TOU Validation Grid Widget - inspired by modern scheduling UIs
class TOUValidationGrid extends StatefulWidget {
  final List<TimeOfUseDetail> timeOfUseDetails;
  final List<TimeBand> availableTimeBands;
  final List<Channel> availableChannels;
  final Function(List<int> channelIds)? onChannelFilterChanged;
  final Function(List<int> timeBandIds)? onTimeBandFilterChanged;
  final TOUValidationViewMode viewMode;
  final Function(TOUValidationViewMode)? onViewModeChanged;

  const TOUValidationGrid({
    super.key,
    required this.timeOfUseDetails,
    required this.availableTimeBands,
    required this.availableChannels,
    this.onChannelFilterChanged,
    this.onTimeBandFilterChanged,
    this.viewMode = TOUValidationViewMode.weekly,
    this.onViewModeChanged,
  });

  @override
  State<TOUValidationGrid> createState() => _TOUValidationGridState();
}

class _TOUValidationGridState extends State<TOUValidationGrid> {
  List<int> _selectedChannels = [];
  List<int> _selectedTimeBands = [];
  bool _showConflicts = true;
  bool _showGaps = true;
  bool _showOverlaps = true;

  @override
  void initState() {
    super.initState();
    // Initialize with all channels and time bands selected
    _selectedChannels = widget.availableChannels.map((c) => c.id).toList();
    _selectedTimeBands = widget.availableTimeBands.map((tb) => tb.id).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildFilterChips(),
          _buildValidationLegend(),
          Expanded(child: _buildValidationGrid()),
          _buildValidationSummary(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.spacing8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
            child: const Icon(
              Icons.grid_view_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSizes.spacing12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOU Validation Grid',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeLarge,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSizes.spacing4),
                Text(
                  'Visualize time band coverage, conflicts, and gaps',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeSmall,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _buildViewModeToggle(),
        ],
      ),
    );
  }

  Widget _buildViewModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewModeButton(
            'Week',
            TOUValidationViewMode.weekly,
            Icons.view_week_rounded,
          ),
          _buildViewModeButton(
            'Month',
            TOUValidationViewMode.monthly,
            Icons.calendar_month_rounded,
          ),
          _buildViewModeButton(
            'Year',
            TOUValidationViewMode.yearly,
            Icons.calendar_today_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeButton(
    String label,
    TOUValidationViewMode mode,
    IconData icon,
  ) {
    final isSelected = widget.viewMode == mode;
    return GestureDetector(
      onTap: () => widget.onViewModeChanged?.call(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacing12,
          vertical: AppSizes.spacing8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSizes.spacing4),
            Text(
              label,
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Channel Filter
          _buildFilterSection(
            'Channels',
            Icons.account_tree_outlined,
            widget.availableChannels
                .map(
                  (c) => FilterChipData(
                    id: c.id,
                    label: c.name,
                    isSelected: _selectedChannels.contains(c.id),
                  ),
                )
                .toList(),
            (id, selected) {
              setState(() {
                if (selected) {
                  _selectedChannels.add(id);
                } else {
                  _selectedChannels.remove(id);
                }
              });
              widget.onChannelFilterChanged?.call(_selectedChannels);
            },
          ),

          const SizedBox(height: AppSizes.spacing16),

          // Time Band Filter
          _buildFilterSection(
            'Time Bands',
            Icons.access_time_rounded,
            widget.availableTimeBands
                .map(
                  (tb) => FilterChipData(
                    id: tb.id,
                    label: tb.name,
                    isSelected: _selectedTimeBands.contains(tb.id),
                    color: _getTimeBandColor(tb.id),
                  ),
                )
                .toList(),
            (id, selected) {
              setState(() {
                if (selected) {
                  _selectedTimeBands.add(id);
                } else {
                  _selectedTimeBands.remove(id);
                }
              });
              widget.onTimeBandFilterChanged?.call(_selectedTimeBands);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(
    String title,
    IconData icon,
    List<FilterChipData> items,
    Function(int id, bool selected) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: AppSizes.spacing8),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                setState(() {
                  final allSelected = items.every((item) => item.isSelected);
                  for (final item in items) {
                    onChanged(item.id, !allSelected);
                  }
                });
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacing8,
                ),
                minimumSize: const Size(0, 32),
              ),
              child: Text(
                items.every((item) => item.isSelected)
                    ? 'Deselect All'
                    : 'Select All',
                style: const TextStyle(
                  fontSize: AppSizes.fontSizeSmall,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spacing8),
        Wrap(
          spacing: AppSizes.spacing8,
          runSpacing: AppSizes.spacing8,
          children: items
              .map((item) => _buildFilterChip(item, onChanged))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildFilterChip(FilterChipData item, Function(int, bool) onChanged) {
    return GestureDetector(
      onTap: () => onChanged(item.id, !item.isSelected),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacing12,
          vertical: AppSizes.spacing6,
        ),
        decoration: BoxDecoration(
          color: item.isSelected
              ? (item.color ?? AppColors.primary).withValues(alpha: 0.1)
              : AppColors.background,
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          border: Border.all(
            color: item.isSelected
                ? (item.color ?? AppColors.primary).withValues(alpha: 0.3)
                : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.color != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: item.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSizes.spacing6),
            ],
            Text(
              item.label,
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                fontWeight: FontWeight.w500,
                color: item.isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
            if (item.isSelected) ...[
              const SizedBox(width: AppSizes.spacing6),
              Icon(
                Icons.check_circle,
                size: 14,
                color: item.color ?? AppColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildValidationLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing16,
        vertical: AppSizes.spacing12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        children: [
          // Status Legend Row
          Row(
            children: [
              const Text(
                'Status: [UPDATED]',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeSmall,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: AppSizes.spacing16),
              _buildLegendItem('Covered', AppColors.success),
              _buildLegendItem('Overlap', AppColors.warning),
              _buildLegendItem('Conflict', AppColors.error),
              _buildLegendItem('Empty', AppColors.textTertiary),
              const Spacer(),
              _buildValidationToggle('Conflicts', _showConflicts, (value) {
                setState(() => _showConflicts = value);
              }),
              _buildValidationToggle('Gaps', _showGaps, (value) {
                setState(() => _showGaps = value);
              }),
              _buildValidationToggle('Overlaps', _showOverlaps, (value) {
                setState(() => _showOverlaps = value);
              }),
            ],
          ),

          // Dynamic Channel and Time Band Legend
          const SizedBox(height: AppSizes.spacing8),
          _buildDynamicChannelTimeBandLegend(),

          // Channel Legend Row (if multiple channels are selected)
          if (_selectedChannels.length > 1) ...[
            const SizedBox(height: AppSizes.spacing8),
            Row(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.palette_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSizes.spacing4),
                    const Text(
                      'Grid Colors by Channel:',
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeSmall,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppSizes.spacing16),
                ...widget.availableChannels
                    .where((channel) => _selectedChannels.contains(channel.id))
                    .map((channel) => _buildChannelLegendItem(channel))
                    .toList(),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing8,
                    vertical: AppSizes.spacing2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  ),
                  child: Text(
                    '${_selectedChannels.length} of ${widget.availableChannels.length} channels',
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeExtraSmall,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            // Add time band color row for multi-channel scenarios too
            const SizedBox(height: AppSizes.spacing8),
            Row(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSizes.spacing4),
                    const Text(
                      'Time Band Colors:',
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeSmall,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppSizes.spacing16),
                _buildTimeBandColorExample('Mon-Fri', 0),
                _buildTimeBandColorExample('Weekend', 1),
                _buildTimeBandColorExample('Holiday', 2),
                const Spacer(),
                Text(
                  'Grid shows time bands when no channels configured',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeExtraSmall,
                    color: AppColors.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ] else if (_selectedChannels.length == 1) ...[
            // Single Channel Context
            const SizedBox(height: AppSizes.spacing8),
            Row(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSizes.spacing4),
                    const Text(
                      'Grid Colors by Time Band:',
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeSmall,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppSizes.spacing16),
                // Show time band color examples since this is the current display mode
                _buildTimeBandColorExample('Mon-Fri', 0),
                _buildTimeBandColorExample('Weekend', 1),
                _buildTimeBandColorExample('Holiday', 2),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing8,
                    vertical: AppSizes.spacing2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Channel: ${widget.availableChannels.firstWhere((c) => c.id == _selectedChannels.first).name}',
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeExtraSmall,
                      fontWeight: FontWeight.w500,
                      color: AppColors.info,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Each time band gets a unique color',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeExtraSmall,
                    color: AppColors.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.spacing16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
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

  Widget _buildChannelLegendItem(Channel channel) {
    final color = _getChannelColor(channel.id);
    return Container(
      margin: const EdgeInsets.only(right: AppSizes.spacing8),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing8,
        vertical: AppSizes.spacing4,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 14,
            decoration: BoxDecoration(
              color: color, // EXACT same color as grid cells
              borderRadius: BorderRadius.circular(4), // Same as grid cells
            ),
          ),
          const SizedBox(width: AppSizes.spacing6),
          Text(
            'Ch ${channel.id}: ${channel.name}',
            style: const TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBandColorExample(String label, int colorIndex) {
    final color = _getTimeBandColor(colorIndex);
    return Container(
      margin: const EdgeInsets.only(right: AppSizes.spacing8),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing8,
        vertical: AppSizes.spacing4,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 14,
            decoration: BoxDecoration(
              color: color, // EXACT same color as grid cells
              borderRadius: BorderRadius.circular(4), // Same as grid cells
            ),
          ),
          const SizedBox(width: AppSizes.spacing6),
          Text(
            label,
            style: const TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicChannelTimeBandLegend() {
    // Always show something to verify the method is being called
    return Column(
      children: [
        // VERY VISIBLE DEBUG CONTAINER
        Container(
          width: double.infinity,
          height: 40,
          color: Colors.red,
          child: const Center(
            child: Text(
              'DYNAMIC LEGEND TEST - THIS SHOULD BE VISIBLE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),

        Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.color_lens_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Channel Time Band Colors',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Show channels and their time bands
              ..._buildChannelTimeBandRows(),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildChannelTimeBandRows() {
    final selectedChannels = widget.availableChannels
        .where((channel) => _selectedChannels.contains(channel.id))
        .toList();

    if (selectedChannels.isEmpty) {
      return [
        Text(
          'No channels selected - please select channels to see their time band colors',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textTertiary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ];
    }

    final rows = <Widget>[];

    for (final channel in selectedChannels) {
      final timeBands = _getTimeBandsForChannel(channel);

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Channel name
              SizedBox(
                width: 120,
                child: Text(
                  'Channel ${channel.code.isNotEmpty ? channel.code : channel.name}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Time bands with colors
              Expanded(
                child: timeBands.isEmpty
                    ? Text(
                        'No time bands assigned',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: timeBands.asMap().entries.map((entry) {
                          final index = entry.key;
                          final timeBand = entry.value;
                          final color = _getTimeBandColor(index);

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: color, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  timeBand.name,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        ),
      );
    }

    return rows;
  }

  List<TimeBand> _getTimeBandsForChannel(Channel channel) {
    // Get time bands that are used in the TOU details for this channel
    final channelDetails = widget.timeOfUseDetails
        .where((detail) => detail.channelId == channel.id)
        .toList();

    // Extract unique time band IDs from the details
    final timeBandIds = <int>{};
    for (final detail in channelDetails) {
      timeBandIds.add(detail.timeBandId);
    }

    // Get the corresponding TimeBand objects that are also in selected time bands
    return widget.availableTimeBands
        .where(
          (timeBand) =>
              timeBandIds.contains(timeBand.id) &&
              _selectedTimeBands.contains(timeBand.id),
        )
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Widget _buildValidationToggle(
    String label,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSizes.spacing12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: value,
              onChanged: (newValue) => onChanged(newValue ?? false),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

  Widget _buildValidationGrid() {
    switch (widget.viewMode) {
      case TOUValidationViewMode.weekly:
        return _buildWeeklyGrid();
      case TOUValidationViewMode.monthly:
        return _buildMonthlyGrid();
      case TOUValidationViewMode.yearly:
        return _buildYearlyGrid();
    }
  }

  Widget _buildWeeklyGrid() {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final hours = List.generate(24, (index) => index);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: Column(
        children: [
          // Header row
          Row(
            children: [
              const SizedBox(width: 60), // Hour column width
              ...days.map(
                (day) => Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSizes.spacing8,
                    ),
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
          ...hours.map((hour) => _buildGridRow(hour, days)),
        ],
      ),
    );
  }

  Widget _buildGridRow(int hour, List<String> days) {
    return Row(
      children: [
        // Hour label
        SizedBox(
          width: 60,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing8),
            alignment: Alignment.centerRight,
            child: Text(
              '${hour.toString().padLeft(2, '0')}:00',
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: AppColors.textSecondary,
                fontFamily: 'monospace',
              ),
            ),
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

    return Container(
      height: 32,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: Colors.transparent, // Let the content show its true colors
        borderRadius: BorderRadius.circular(4),
        border: validation.hasConflict && _showConflicts
            ? Border.all(color: AppColors.error, width: 2)
            : validation.isEmpty && _showGaps
            ? Border.all(
                color: AppColors.textTertiary.withValues(alpha: 0.5),
                width: 1,
              )
            : validation.timeBands.length > 1 && _showOverlaps
            ? Border.all(color: AppColors.warning, width: 1.5)
            : null,
      ),
      child: validation.timeBands.isNotEmpty
          ? _buildCellContent(validation)
          : Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
    );
  }

  Widget _buildCellContent(TimeSlotValidation validation) {
    // If multiple channels are selected, prioritize channel colors
    if (_selectedChannels.length > 1 && validation.channels.isNotEmpty) {
      if (validation.channels.length == 1) {
        return Container(
          decoration: BoxDecoration(
            color: _getChannelColor(validation.channels.first),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const SizedBox.expand(),
        );
      }

      // Multiple channels - show stripes with channel colors
      return CustomPaint(
        painter: StripePainter(
          colors: validation.channels.map(_getChannelColor).toList(),
        ),
        child: const SizedBox.expand(),
      );
    }

    // Single channel or no channel preference - use time band colors
    if (validation.timeBands.length == 1) {
      return Container(
        decoration: BoxDecoration(
          color: _getTimeBandColor(validation.timeBands.first),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const SizedBox.expand(),
      );
    }

    // Multiple time bands - show stripes
    return CustomPaint(
      painter: StripePainter(
        colors: validation.timeBands.map(_getTimeBandColor).toList(),
      ),
      child: const SizedBox.expand(),
    );
  }

  Widget _buildMonthlyGrid() {
    // Simplified monthly view - could be expanded
    return const Center(
      child: Text(
        'Monthly view coming soon',
        style: TextStyle(
          fontSize: AppSizes.fontSizeMedium,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildYearlyGrid() {
    // Simplified yearly view - could be expanded
    return const Center(
      child: Text(
        'Yearly view coming soon',
        style: TextStyle(
          fontSize: AppSizes.fontSizeMedium,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildValidationSummary() {
    final stats = _calculateValidationStats();

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          _buildStatChip(
            'Coverage',
            '${stats.coveragePercentage.toStringAsFixed(1)}%',
            AppColors.primary,
          ),
          _buildStatChip('Conflicts', '${stats.conflicts}', AppColors.error),
          _buildStatChip('Gaps', '${stats.gaps}', AppColors.warning),
          _buildStatChip('Overlaps', '${stats.overlaps}', AppColors.info),
          const Spacer(),
          AppButton(
            text: 'Export Report',
            type: AppButtonType.outline,
            size: AppButtonSize.small,
            icon: const Icon(Icons.download_rounded, size: 16),
            onPressed: _exportValidationReport,
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: AppSizes.spacing12),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing12,
        vertical: AppSizes.spacing6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              fontWeight: FontWeight.w700,
              color: color,
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

  // Helper methods
  TimeSlotValidation _validateTimeSlot(int hour, int dayIndex) {
    final applicableDetails = widget.timeOfUseDetails.where((detail) {
      if (!_selectedChannels.contains(detail.channelId) ||
          !_selectedTimeBands.contains(detail.timeBandId)) {
        return false;
      }

      final timeBand = detail.timeBand;
      if (timeBand == null || !timeBand.active) return false;

      // Check if time band applies to this hour and day
      return _isTimeBandActiveAt(timeBand, hour, dayIndex);
    }).toList();

    return TimeSlotValidation(
      hour: hour,
      dayIndex: dayIndex,
      timeBands: applicableDetails.map((d) => d.timeBandId).toList(),
      channels: applicableDetails.map((d) => d.channelId).toList(),
      hasConflict: applicableDetails.length > 1,
      isEmpty: applicableDetails.isEmpty,
    );
  }

  bool _isTimeBandActiveAt(TimeBand timeBand, int hour, int dayIndex) {
    // Check day of week
    if (timeBand.daysOfWeek.isNotEmpty) {
      final dayOfWeek = dayIndex == 0
          ? 7
          : dayIndex; // Convert Sunday from 0 to 7
      if (!timeBand.daysOfWeek.contains(dayOfWeek)) return false;
    }

    // Check time range - parse string times like "17:00:00"
    try {
      final startHour = _parseTimeString(timeBand.startTime);
      final endHour = _parseTimeString(timeBand.endTime);

      if (startHour <= endHour) {
        return hour >= startHour && hour < endHour;
      } else {
        // Spans midnight
        return hour >= startHour || hour < endHour;
      }
    } catch (e) {
      print('Error parsing time for timeBand ${timeBand.name}: $e');
      return false;
    }
  }

  int _parseTimeString(String timeString) {
    // Handle formats like "17:00:00" or "17:00"
    final parts = timeString.split(':');
    if (parts.isNotEmpty) {
      return int.parse(parts[0]);
    }
    return 0;
  }

  Color _getTimeBandColor(int timeBandId) {
    final colors = [
      AppColors.primary,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
      AppColors.info,
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF795548), // Brown
      const Color(0xFF607D8B), // Blue Grey
    ];
    return colors[timeBandId % colors.length];
  }

  Color _getChannelColor(int channelId) {
    // Use a distinct, vibrant color palette for channels
    final channelColors = [
      const Color(0xFF2196F3), // Bright Blue
      const Color(0xFF4CAF50), // Bright Green
      const Color(0xFFFF5722), // Deep Orange Red
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFFF9800), // Orange
      const Color(0xFF607D8B), // Blue Grey
      const Color(0xFFE91E63), // Pink
      const Color(0xFF009688), // Teal
      const Color(0xFF8BC34A), // Light Green
      const Color(0xFF795548), // Brown
      const Color(0xFF3F51B5), // Indigo
      const Color(0xFFCDDC39), // Lime
    ];
    return channelColors[channelId % channelColors.length];
  }

  ValidationStats _calculateValidationStats() {
    int totalSlots = 24 * 7; // Weekly view
    int coveredSlots = 0;
    int conflicts = 0;
    int gaps = 0;
    int overlaps = 0;

    for (int hour = 0; hour < 24; hour++) {
      for (int day = 0; day < 7; day++) {
        final validation = _validateTimeSlot(hour, day);
        if (validation.timeBands.isNotEmpty) {
          coveredSlots++;
        }
        if (validation.hasConflict) {
          conflicts++;
        }
        if (validation.isEmpty) {
          gaps++;
        }
        if (validation.timeBands.length > 1) {
          overlaps++;
        }
      }
    }

    return ValidationStats(
      coveragePercentage: (coveredSlots / totalSlots) * 100,
      conflicts: conflicts,
      gaps: gaps,
      overlaps: overlaps,
    );
  }

  void _exportValidationReport() {
    // TODO: Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality coming soon')),
    );
  }
}

// Supporting classes
enum TOUValidationViewMode { weekly, monthly, yearly }

class FilterChipData {
  final int id;
  final String label;
  final bool isSelected;
  final Color? color;

  FilterChipData({
    required this.id,
    required this.label,
    required this.isSelected,
    this.color,
  });
}

class TimeSlotValidation {
  final int hour;
  final int dayIndex;
  final List<int> timeBands;
  final List<int> channels;
  final bool hasConflict;
  final bool isEmpty;

  TimeSlotValidation({
    required this.hour,
    required this.dayIndex,
    required this.timeBands,
    required this.channels,
    required this.hasConflict,
    required this.isEmpty,
  });
}

class ValidationStats {
  final double coveragePercentage;
  final int conflicts;
  final int gaps;
  final int overlaps;

  ValidationStats({
    required this.coveragePercentage,
    required this.conflicts,
    required this.gaps,
    required this.overlaps,
  });
}

class StripePainter extends CustomPainter {
  final List<Color> colors;

  StripePainter({required this.colors});

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
