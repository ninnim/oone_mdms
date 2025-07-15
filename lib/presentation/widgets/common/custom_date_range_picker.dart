import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';

class CustomDateRangePicker extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final Function(DateTime startDate, DateTime endDate) onDateRangeSelected;
  final String? hintText;
  final bool enabled;

  const CustomDateRangePicker({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
    required this.onDateRangeSelected,
    this.hintText,
    this.enabled = true,
  });

  @override
  State<CustomDateRangePicker> createState() => _CustomDateRangePickerState();
}

class _CustomDateRangePickerState extends State<CustomDateRangePicker> {
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime _displayMonth = DateTime.now();
  DateTime? _tempStartDate;
  DateTime? _tempEndDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    if (_startDate != null) {
      _displayMonth = DateTime(_startDate!.year, _startDate!.month);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.enabled ? _showDateRangePicker : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.enabled
                ? (isDark ? const Color(0xFF4a5568) : AppColors.border)
                : (isDark ? const Color(0xFF2d3748) : AppColors.borderLight),
          ),
          borderRadius: BorderRadius.circular(6),
          color: widget.enabled
              ? (isDark ? const Color(0xFF2d3748) : AppColors.surface)
              : (isDark ? const Color(0xFF1e293b) : AppColors.surfaceVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: widget.enabled
                  ? (isDark ? Colors.white70 : AppColors.textSecondary)
                  : (isDark ? Colors.white30 : AppColors.textTertiary),
            ),
            const SizedBox(width: 8),
            Text(
              _getDisplayText(),
              style: TextStyle(
                fontSize: 14,
                color: widget.enabled
                    ? (isDark ? Colors.white : AppColors.textPrimary)
                    : (isDark ? Colors.white54 : AppColors.textTertiary),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: widget.enabled
                  ? (isDark ? Colors.white70 : AppColors.textSecondary)
                  : (isDark ? Colors.white30 : AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  String _getDisplayText() {
    if (_startDate == null || _endDate == null) {
      return widget.hintText ?? 'Select date range';
    }

    final formatter = DateFormat('MMM d, yyyy');
    return '${formatter.format(_startDate!)} - ${formatter.format(_endDate!)}';
  }

  void _showDateRangePicker() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: isDark
                  ? const Color(0xFF2d3748)
                  : AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 360,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with month navigation
                    _buildHeader(setDialogState, isDark),
                    const SizedBox(height: 24),

                    // Selected date display
                    _buildSelectedDateDisplay(setDialogState, isDark),
                    const SizedBox(height: 24),

                    // Calendar
                    _buildCalendar(setDialogState, isDark),
                    const SizedBox(height: 24),

                    // Action buttons
                    _buildActionButtons(isDark),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(StateSetter setDialogState, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            setDialogState(() {
              _displayMonth = DateTime(
                _displayMonth.year,
                _displayMonth.month - 1,
              );
            });
          },
          icon: Icon(
            Icons.chevron_left,
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
        Text(
          DateFormat('MMMM yyyy').format(_displayMonth),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        IconButton(
          onPressed: () {
            setDialogState(() {
              _displayMonth = DateTime(
                _displayMonth.year,
                _displayMonth.month + 1,
              );
            });
          },
          icon: Icon(
            Icons.chevron_right,
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedDateDisplay(StateSetter setDialogState, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? const Color(0xFF4a5568) : AppColors.border,
              ),
              borderRadius: BorderRadius.circular(8),
              color: isDark
                  ? const Color(0xFF1e293b)
                  : AppColors.surfaceVariant,
            ),
            child: Text(
              _tempStartDate != null
                  ? DateFormat('MMM d, yyyy').format(_tempStartDate!)
                  : (_startDate != null
                        ? DateFormat('MMM d, yyyy').format(_startDate!)
                        : 'Start Date'),
              style: TextStyle(
                fontSize: 14,
                color: (_tempStartDate ?? _startDate) != null
                    ? (isDark ? Colors.white : AppColors.textPrimary)
                    : (isDark ? Colors.white70 : AppColors.textSecondary),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () {
            setDialogState(() {
              _tempStartDate = DateTime.now();
              _tempEndDate = DateTime.now();
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? const Color(0xFF4a5568) : AppColors.border,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Today',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar(StateSetter setDialogState, bool isDark) {
    return Column(
      children: [
        // Week day headers
        Row(
          children: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sat', 'Su']
              .map(
                (day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white70
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),

        // Calendar grid
        ..._buildCalendarWeeks(setDialogState, isDark),
      ],
    );
  }

  List<Widget> _buildCalendarWeeks(StateSetter setDialogState, bool isDark) {
    final firstDayOfMonth = DateTime(
      _displayMonth.year,
      _displayMonth.month,
      1,
    );

    // Get the first Monday of the calendar view
    final firstMondayOfCalendar = firstDayOfMonth.subtract(
      Duration(days: (firstDayOfMonth.weekday - 1) % 7),
    );

    final weeks = <Widget>[];
    var currentWeekStart = firstMondayOfCalendar;

    // Generate 6 weeks to cover all possible month layouts
    for (int week = 0; week < 6; week++) {
      final weekDays = <Widget>[];

      for (int day = 0; day < 7; day++) {
        final currentDay = currentWeekStart.add(Duration(days: day));
        final isCurrentMonth = currentDay.month == _displayMonth.month;
        final isToday = _isSameDay(currentDay, DateTime.now());
        final isSelected =
            _isSameDay(currentDay, _tempStartDate) ||
            _isSameDay(currentDay, _tempEndDate);
        final isInRange = _isInSelectedRange(currentDay);
        final hasEvent = _hasEvent(currentDay); // You can customize this

        weekDays.add(
          Expanded(
            child: GestureDetector(
              onTap: () => _selectDate(currentDay, setDialogState),
              child: Container(
                height: 40,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (isInRange
                            ? AppColors.primary.withOpacity(0.1)
                            : Colors.transparent),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        currentDay.day.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isToday
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : (isCurrentMonth
                                    ? (isDark
                                          ? Colors.white
                                          : AppColors.textPrimary)
                                    : (isDark
                                          ? Colors.white30
                                          : AppColors.textTertiary)),
                        ),
                      ),
                    ),
                    if (hasEvent && !isSelected)
                      Positioned(
                        bottom: 6,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      weeks.add(Row(children: weekDays));

      currentWeekStart = currentWeekStart.add(const Duration(days: 7));

      // Break if we've covered the month and some of the next month
      if (week >= 4 && currentWeekStart.month != _displayMonth.month) {
        break;
      }
    }

    return weeks;
  }

  bool _isSameDay(DateTime date1, DateTime? date2) {
    if (date2 == null) return false;
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool _isInSelectedRange(DateTime date) {
    if (_tempStartDate == null || _tempEndDate == null) return false;

    final start = _tempStartDate!.isBefore(_tempEndDate!)
        ? _tempStartDate!
        : _tempEndDate!;
    final end = _tempStartDate!.isBefore(_tempEndDate!)
        ? _tempEndDate!
        : _tempStartDate!;

    return date.isAfter(start.subtract(const Duration(days: 1))) &&
        date.isBefore(end.add(const Duration(days: 1)));
  }

  bool _hasEvent(DateTime date) {
    // Customize this based on your needs
    // For the example image, there are events on certain days
    return date.day == 11 || date.day == 24;
  }

  void _selectDate(DateTime date, StateSetter setDialogState) {
    setDialogState(() {
      if (_tempStartDate == null || _tempEndDate != null) {
        // Start new selection
        _tempStartDate = date;
        _tempEndDate = null;
      } else {
        // Complete the range
        _tempEndDate = date;

        // Ensure start is before end
        if (_tempStartDate!.isAfter(_tempEndDate!)) {
          final temp = _tempStartDate;
          _tempStartDate = _tempEndDate;
          _tempEndDate = temp;
        }
      }
    });
  }

  Widget _buildActionButtons(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () {
              // Navigator.of(context).pop();
              Navigator.of(context, rootNavigator: true).pop();
              // Reset temp selections
              _tempStartDate = null;
              _tempEndDate = null;
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isDark ? const Color(0xFF4a5568) : AppColors.border,
                ),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _tempStartDate != null && _tempEndDate != null
                ? () {
                    setState(() {
                      _startDate = _tempStartDate;
                      _endDate = _tempEndDate;
                    });
                    widget.onDateRangeSelected(_startDate!, _endDate!);
                    // Navigator.of(context).pop();
                    Navigator.of(context, rootNavigator: true).pop();
                    _tempStartDate = null;
                    _tempEndDate = null;
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Apply',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }
}
