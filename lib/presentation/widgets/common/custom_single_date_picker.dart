import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../themes/app_theme.dart';
import '../../../core/constants/app_sizes.dart';
import 'app_input_field.dart';
import 'app_button.dart';

class CustomSingleDatePicker extends StatefulWidget {
  final DateTime? initialDate;
  final Function(DateTime) onDateSelected;
  final String? label;
  final String? hintText;
  final bool enabled;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool isRequired;
  final String? errorText; // Add error text parameter
  final bool hasError; // Add error state parameter

  const CustomSingleDatePicker({
    super.key,
    this.initialDate,
    required this.onDateSelected,
    this.label,
    this.hintText,
    this.enabled = true,
    this.firstDate,
    this.lastDate,
    this.isRequired = false,
    this.errorText,
    this.hasError = false,
  });

  @override
  State<CustomSingleDatePicker> createState() => _CustomSingleDatePickerState();
}

class _CustomSingleDatePickerState extends State<CustomSingleDatePicker> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  void didUpdateWidget(CustomSingleDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate != oldWidget.initialDate) {
      _selectedDate = widget.initialDate;
    }
  }

  Future<void> _showDatePickerDialog() async {
    if (!widget.enabled) return;

    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) => _DatePickerDialog(
        initialDate: _selectedDate ?? DateTime.now(),
        firstDate: widget.firstDate ?? DateTime(1900),
        lastDate: widget.lastDate ?? DateTime(2100),
      ),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      widget.onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          RichText(
            text: TextSpan(
              text: widget.label!,
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: colorScheme.onSurface,
              ),
              children: [
                if (widget.isRequired)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: context.errorColor),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.spacing8),
        ],
        GestureDetector(
          onTap: widget.enabled ? _showDatePickerDialog : null,
          child: Container(
            height: AppSizes.inputHeight,
            padding: EdgeInsets.symmetric(
              horizontal: AppSizes.spacing16,
              vertical: 0, // Remove vertical padding for better centering
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: widget.hasError
                    ? context.errorColor
                    : context.borderColor, // Use consistent border color
                width: 1, // Correct error border width
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
              color: context.surfaceColor,
              // : context.disabledColor,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: AppSizes.iconSmall,
                        color: widget.enabled
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedDate != null
                              ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                              : widget.hintText ?? 'Select date',
                          style: TextStyle(
                            fontSize: AppSizes
                                .fontSizeMedium, // Match AppInputField font size
                            height: 1.4, // Match AppInputField line height
                            color: _selectedDate != null
                                ? colorScheme.onSurface
                                : colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  size: AppSizes.iconSmall,
                  color: widget.enabled
                      ? context.surfaceVariantColor
                      : context.surfaceVariantColor.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
        if (widget.hasError && widget.errorText != null) ...[
          const SizedBox(height: AppSizes.spacing4),
          Text(
            widget.errorText!,
            style: TextStyle(
              color: context.errorColor,
              fontSize: AppSizes.fontSizeSmall,
            ),
          ),
        ],
        const SizedBox(
          height: AppSizes.spacing4,
        ), // Error space for consistency
      ],
    );
  }
}

class _DatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const _DatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_DatePickerDialog> createState() => _DatePickerDialogState();
}

class _DatePickerDialogState extends State<_DatePickerDialog> {
  late DateTime _selectedDate;
  late DateTime _displayMonth;
  late int _selectedYear;
  final TextEditingController _dateController = TextEditingController();
  bool _showYearPicker = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _displayMonth = DateTime(_selectedDate.year, _selectedDate.month);
    _selectedYear = _selectedDate.year;
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  void _validateAndUpdateDate(String value) {
    try {
      if (value.length == 10) {
        final parts = value.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          final date = DateTime(year, month, day);

          // Validate date constraints
          if ((date.isAfter(widget.firstDate) ||
                  date.isAtSameMomentAs(widget.firstDate)) &&
              (date.isBefore(widget.lastDate) ||
                  date.isAtSameMomentAs(widget.lastDate))) {
            setState(() {
              _selectedDate = date;
              _displayMonth = DateTime(date.year, date.month);
              _selectedYear = date.year;
            });
          }
        }
      }
    } catch (e) {
      // Invalid date format, ignore
    }
  }

  void _selectYear(int year) {
    setState(() {
      _selectedYear = year;
      _displayMonth = DateTime(year, _displayMonth.month);
      _selectedDate = DateTime(year, _selectedDate.month, _selectedDate.day);
      _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
      _showYearPicker = false;
    });
  }

  Widget _buildYearPicker() {
    final startYear = widget.firstDate.year;
    final endYear = widget.lastDate.year;

    return SizedBox(
      height: 300,
      child: ListView.builder(
        itemCount: endYear - startYear + 1,
        itemBuilder: (context, index) {
          final year = startYear + index;
          final isSelected = year == _selectedYear;

          return ListTile(
            title: Text(
              year.toString(),
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? context.primaryColor : null,
              ),
            ),
            selected: isSelected,
            onTap: () => _selectYear(year),
          );
        },
      ),
    );
  }

  Widget _buildCalendar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: Column(
        children: [
          // Calendar header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: context.backgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radiusLarge),
                topRight: Radius.circular(AppSizes.radiusLarge),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _displayMonth = DateTime(
                        _displayMonth.year,
                        _displayMonth.month - 1,
                      );
                    });
                  },
                  icon: const Icon(Icons.chevron_left),
                  iconSize: 20,
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showYearPicker = !_showYearPicker;
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(_displayMonth),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _showYearPicker
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                        size: 20,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _displayMonth = DateTime(
                        _displayMonth.year,
                        _displayMonth.month + 1,
                      );
                    });
                  },
                  icon: const Icon(Icons.chevron_right),
                  iconSize: 20,
                ),
              ],
            ),
          ),

          // Calendar content
          if (_showYearPicker)
            _buildYearPicker()
          else
            Padding(
              padding: const EdgeInsets.all(8),
              child: _buildCalendarGrid(),
            ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(
      _displayMonth.year,
      _displayMonth.month + 1,
      0,
    ).day;
    final firstDayOfMonth = DateTime(
      _displayMonth.year,
      _displayMonth.month,
      1,
    );
    final startingWeekday = firstDayOfMonth.weekday;

    // Week days header
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      children: [
        // Week days header
        Row(
          children: weekDays
              .map(
                (day) => Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),

        // Calendar days
        ...List.generate(6, (weekIndex) {
          final List<Widget> dayWidgets = [];

          for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
            final cellIndex = weekIndex * 7 + dayIndex;
            final dayNumber = cellIndex - startingWeekday + 2;

            if (dayNumber < 1 || dayNumber > daysInMonth) {
              dayWidgets.add(const Expanded(child: SizedBox(height: 40)));
              continue;
            }

            final cellDate = DateTime(
              _displayMonth.year,
              _displayMonth.month,
              dayNumber,
            );
            final isSelected =
                _selectedDate.year == cellDate.year &&
                _selectedDate.month == cellDate.month &&
                _selectedDate.day == cellDate.day;
            final isToday =
                DateTime.now().year == cellDate.year &&
                DateTime.now().month == cellDate.month &&
                DateTime.now().day == cellDate.day;

            // Check date constraints
            final isEnabled =
                (cellDate.isAfter(widget.firstDate) ||
                    cellDate.isAtSameMomentAs(widget.firstDate)) &&
                (cellDate.isBefore(widget.lastDate) ||
                    cellDate.isAtSameMomentAs(widget.lastDate));

            dayWidgets.add(
              Expanded(
                child: GestureDetector(
                  onTap: isEnabled
                      ? () {
                          setState(() {
                            _selectedDate = cellDate;
                            _dateController.text = DateFormat(
                              'dd/MM/yyyy',
                            ).format(cellDate);
                          });
                        }
                      : null,
                  child: Container(
                    height: 40,
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.primaryColor
                          : isToday
                          ? context.primaryColor.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    ),
                    child: Center(
                      child: Text(
                        dayNumber.toString(),
                        style: TextStyle(
                          color: !isEnabled
                              ? context.textSecondaryColor
                              : isSelected
                              ? Colors.white
                              : isToday
                              ? context.primaryColor
                              : context.textPrimaryColor,
                          fontWeight: isSelected || isToday
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          // Only show rows that have at least one valid day
          final hasValidDay = dayWidgets.any((widget) {
            return widget is Expanded && widget.child is! SizedBox;
          });

          if (hasValidDay) {
            return Row(children: dayWidgets);
          } else {
            return const SizedBox.shrink();
          }
        }).whereType<Row>(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSizes.spacing16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: context.borderColor)),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppSizes.radiusLarge),
                  topRight: Radius.circular(AppSizes.radiusLarge),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Select Date',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: context.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(AppSizes.spacing16),
              child: Column(
                children: [
                  // Date input field
                  AppInputField(
                    controller: _dateController,
                    label: 'Enter Date',
                    hintText: 'dd/mm/yyyy',
                    onChanged: _validateAndUpdateDate,
                  ),
                  const SizedBox(height: 16),

                  // Calendar widget
                  _buildCalendar(),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(AppSizes.spacing16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: context.borderColor)),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppSizes.radiusLarge),
                  bottomRight: Radius.circular(AppSizes.radiusLarge),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    text: 'Cancel',
                    type: AppButtonType.outline,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: AppSizes.spacing12),
                  AppButton(
                    text: 'Select',
                    onPressed: () => Navigator.of(context).pop(_selectedDate),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
