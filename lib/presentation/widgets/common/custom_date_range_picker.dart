import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mdms_clone/core/constants/app_sizes.dart';
import 'package:mdms_clone/presentation/widgets/common/app_button.dart';
import 'package:mdms_clone/presentation/widgets/common/app_input_field.dart';
// import '../../../core/constants/app_colors.dart';
import '../../themes/app_theme.dart';

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
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  String? _selectedQuickOption;

  // Dropdown overlay variables
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Set default to current week (Monday to Sunday) if no initial dates are provided
    if (widget.initialStartDate != null && widget.initialEndDate != null) {
      _startDate = widget.initialStartDate;
      _endDate = widget.initialEndDate;
    } else {
      _startDate = now.subtract(Duration(days: now.weekday - 1));
      _endDate = _startDate!.add(const Duration(days: 6));
    }
    _displayMonth = DateTime(_startDate!.year, _startDate!.month);
    _startDateController.text = DateFormat('yyyy-MM-dd').format(_startDate!);
    _endDateController.text = DateFormat('yyyy-MM-dd').format(_endDate!);
  }

  @override
  void dispose() {
    _closeDropdown(); // Clean up overlay if still open
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: widget.enabled ? _toggleDropdown : null,
        child: Container(
          height: AppSizes.inputHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: context.borderColor,
              // (isDark ? const Color(0xFF2d3748) : AppColors.borderLight),
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            color: widget.enabled
                ? (isDark
                      ? const Color(0xFF2d3748)
                      : Theme.of(context).colorScheme.surface)
                : (isDark
                      ? const Color(0xFF1e293b)
                      : Theme.of(context).colorScheme.surfaceVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today,
                size: AppSizes.iconSmall,
                color: widget.enabled
                    ? (isDark
                          ? Colors.white70
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7))
                    : (isDark
                          ? Colors.white30
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5)),
              ),
              const SizedBox(width: 8),
              Text(
                _getDisplayText(),
                style: TextStyle(
                  fontSize: AppSizes.fontSizeSmall,
                  color: widget.enabled
                      ? (isDark
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface)
                      : (isDark
                            ? Colors.white54
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.5)),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                _isDropdownOpen
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: AppSizes.iconSmall,
                color: widget.enabled
                    ? (isDark
                          ? Colors.white70
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7))
                    : (isDark
                          ? Colors.white30
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5)),
              ),
            ],
          ),
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

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isDropdownOpen = true;
    });
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isDropdownOpen = false;
    });
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Invisible barrier to close dropdown when clicking outside
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDropdown,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Dropdown content
          Positioned(
            width: 500,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 50), // Offset below the field
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                child: _buildDropdownContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownContent() {
    return StatefulBuilder(
      builder: (context, setDropdownState) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side: Date inputs and quick select items
              SizedBox(
                width: 200,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Start and End Date in one row
                    Row(
                      children: [
                        Expanded(
                          child: AppInputField(
                            controller: _startDateController,
                            label: 'Start Date',
                            onChanged: (value) => _validateAndUpdateDate(
                              value,
                              true,
                              setDropdownState,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppInputField(
                            label: 'End Date',
                            controller: _endDateController,
                            onChanged: (value) => _validateAndUpdateDate(
                              value,
                              false,
                              setDropdownState,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Quick select items as scrollable list
                    Container(
                      height: 200, // Fixed height for scrollable area
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusLarge,
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            _buildQuickSelectItem(
                              'Today',
                              'today',
                              setDropdownState,
                            ),
                            _buildQuickSelectItem(
                              'This Week',
                              'this_week',
                              setDropdownState,
                            ),
                            _buildQuickSelectItem(
                              'Last Week',
                              'last_week',
                              setDropdownState,
                            ),
                            _buildQuickSelectItem(
                              'This Month',
                              'this_month',
                              setDropdownState,
                            ),
                            _buildQuickSelectItem(
                              'Last Month',
                              'last_month',
                              setDropdownState,
                            ),
                            _buildQuickSelectItem(
                              'This Year',
                              'this_year',
                              setDropdownState,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // const SizedBox(width: 24),
              // Right side: Calendar and controls
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with month navigation
                    _buildHeader(
                      setDropdownState,
                      Theme.of(context).brightness == Brightness.dark,
                    ),
                    const SizedBox(height: 24),
                    // Calendar
                    _buildCalendar(
                      setDropdownState,
                      Theme.of(context).brightness == Brightness.dark,
                    ),
                    const SizedBox(height: 24),
                    // Action buttons
                    _buildActionButtons(
                      Theme.of(context).brightness == Brightness.dark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickSelectItem(
    String label,
    String value,
    StateSetter setDropdownState,
  ) {
    final isSelected = _selectedQuickOption == value;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () {
            _handleQuickSelect(value, setDropdownState);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? context.primaryColor.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: isSelected
                  ? Border.all(color: context.primaryColor, width: 1)
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                color: isSelected
                    ? context.primaryColor
                    : (isDark
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleQuickSelect(String value, StateSetter setDropdownState) {
    setDropdownState(() {
      _selectedQuickOption = value;
      final now = DateTime.now();
      switch (value) {
        case 'today':
          _tempStartDate = DateTime(now.year, now.month, now.day);
          _tempEndDate = DateTime(now.year, now.month, now.day);
          break;
        case 'this_week':
          _tempStartDate = now.subtract(Duration(days: now.weekday - 1));
          _tempEndDate = _tempStartDate!.add(const Duration(days: 6));
          break;
        case 'last_week':
          _tempStartDate = now.subtract(Duration(days: now.weekday - 1 + 7));
          _tempEndDate = _tempStartDate!.add(const Duration(days: 6));
          break;
        case 'this_month':
          _tempStartDate = DateTime(now.year, now.month, 1);
          _tempEndDate = DateTime(now.year, now.month + 1, 0);
          break;
        case 'last_month':
          _tempStartDate = DateTime(now.year, now.month - 1, 1);
          _tempEndDate = DateTime(now.year, now.month, 0);
          break;
        case 'this_year':
          _tempStartDate = DateTime(now.year, 1, 1);
          _tempEndDate = DateTime(now.year, 12, 31);
          break;
      }
      _startDateController.text = DateFormat(
        'yyyy-MM-dd',
      ).format(_tempStartDate!);
      _endDateController.text = DateFormat('yyyy-MM-dd').format(_tempEndDate!);
      _displayMonth = DateTime(_tempStartDate!.year, _tempStartDate!.month);
    });
  }

  void _validateAndUpdateDate(
    String value,
    bool isStartDate,
    StateSetter setDialogState,
  ) {
    try {
      final date = DateFormat('yyyy-MM-dd').parseStrict(value);
      setDialogState(() {
        if (isStartDate) {
          _tempStartDate = date;
        } else {
          _tempEndDate = date;
        }
        _selectedQuickOption =
            null; // Clear quick select when manual input is used
        if (_tempStartDate != null) {
          _displayMonth = DateTime(_tempStartDate!.year, _tempStartDate!.month);
        }
      });
    } catch (e) {
      // Invalid date format, do not update
    }
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
            color: isDark
                ? Colors.white70
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        Text(
          DateFormat('MMMM yyyy').format(_displayMonth),
          style: TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            fontWeight: FontWeight.w600,
            color: isDark
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
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
            color: isDark
                ? Colors.white70
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                        fontSize: AppSizes.fontSizeSmall,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white70
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
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
    final firstMondayOfCalendar = firstDayOfMonth.subtract(
      Duration(days: (firstDayOfMonth.weekday - 1) % 7),
    );

    final weeks = <Widget>[];
    var currentWeekStart = firstMondayOfCalendar;

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
        final hasEvent = _hasEvent(currentDay);

        weekDays.add(
          Expanded(
            child: GestureDetector(
              onTap: () => _selectDate(currentDay, setDialogState),
              child: Container(
                height: 30,
                width: 5,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.primaryColor
                      : (isInRange
                            ? context.primaryColor.withOpacity(0.1)
                            : Colors.transparent),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        currentDay.day.toString(),
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeSmall,
                          fontWeight: isToday
                              ? FontWeight.w500
                              : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : (isCurrentMonth
                                    ? (isDark
                                          ? Colors.white
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurface)
                                    : (isDark
                                          ? Colors.white30
                                          : Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.5))),
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
                              color: context.primaryColor,
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
    return date.day == 11 || date.day == 24; // Customize based on your needs
  }

  void _selectDate(DateTime date, StateSetter setDialogState) {
    setDialogState(() {
      if (_tempStartDate == null || _tempEndDate != null) {
        _tempStartDate = date;
        _tempEndDate = null;
        _startDateController.text = DateFormat('yyyy-MM-dd').format(date);
        _endDateController.clear();
      } else {
        _tempEndDate = date;
        _endDateController.text = DateFormat('yyyy-MM-dd').format(date);
        if (_tempStartDate!.isAfter(_tempEndDate!)) {
          final temp = _tempStartDate;
          _tempStartDate = _tempEndDate;
          _tempEndDate = temp;
          _startDateController.text = DateFormat(
            'yyyy-MM-dd',
          ).format(_tempStartDate!);
          _endDateController.text = DateFormat(
            'yyyy-MM-dd',
          ).format(_tempEndDate!);
        }
      }
      _selectedQuickOption = null; // Clear quick select when calendar is used
      _displayMonth = DateTime(_tempStartDate!.year, _tempStartDate!.month);
    });
  }

  Widget _buildActionButtons(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: 100,
          height: 30,
          child: AppButton(
            type: AppButtonType.outline,
            size: AppButtonSize.small,
            onPressed: () {
              _closeDropdown();
              _tempStartDate = null;
              _tempEndDate = null;
              _selectedQuickOption = null;
              _startDateController.clear();
              _endDateController.clear();
            },
            text: 'Cancel',
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 100,
          height: 30,
          child: AppButton(
            type: AppButtonType.primary,
            size: AppButtonSize.small,
            onPressed: _tempStartDate != null && _tempEndDate != null
                ? () {
                    setState(() {
                      _startDate = _tempStartDate;
                      _endDate = _tempEndDate;
                    });
                    widget.onDateRangeSelected(_startDate!, _endDate!);
                    _closeDropdown();
                    _tempStartDate = null;
                    _tempEndDate = null;
                    _selectedQuickOption = null;
                  }
                : null,
            text: 'Apply',
          ),
        ),
      ],
    );
  }
}
