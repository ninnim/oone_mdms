import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

enum QuickDateRange {
  sixHours('6H', Duration(hours: 6)),
  twelveHours('12H', Duration(hours: 12)),
  twentyFourHours('24H', Duration(hours: 24)),
  oneWeek('1W', Duration(days: 7)),
  oneMonth('1M', Duration(days: 30)),
  oneYear('1Y', Duration(days: 365));

  const QuickDateRange(this.label, this.duration);
  final String label;
  final Duration duration;
}

class EnhancedDateRangePicker extends StatefulWidget {
  final DateTimeRange? initialRange;
  final Function(DateTimeRange) onRangeSelected;
  final bool enabled;

  const EnhancedDateRangePicker({
    super.key,
    this.initialRange,
    required this.onRangeSelected,
    this.enabled = true,
  });

  @override
  State<EnhancedDateRangePicker> createState() =>
      _EnhancedDateRangePickerState();
}

class _EnhancedDateRangePickerState extends State<EnhancedDateRangePicker> {
  DateTimeRange? _selectedRange;
  QuickDateRange? _selectedQuickRange;
  bool _isDropdownOpen = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _selectedRange = widget.initialRange;
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    if (!widget.enabled) return;

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isDropdownOpen = true;
    });
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {
        _isDropdownOpen = false;
      });
    }
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 4,
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 4.0),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 400),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildQuickSelectionSection(),
                  const Divider(height: 1),
                  _buildCustomRangeSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSelectionSection() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Time Range',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.spacing12),
          Wrap(
            spacing: AppSizes.spacing8,
            runSpacing: AppSizes.spacing8,
            children: QuickDateRange.values.map((range) {
              final isSelected = _selectedQuickRange == range;
              return InkWell(
                onTap: () => _selectQuickRange(range),
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing12,
                    vertical: AppSizes.spacing8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(
                    range.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? AppColors.textInverse
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomRangeSection() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Custom Range',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.spacing12),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  'From',
                  _selectedRange?.start ??
                      DateTime.now().subtract(const Duration(days: 7)),
                  (date) {
                    final end = _selectedRange?.end ?? DateTime.now();
                    if (date.isBefore(end)) {
                      _selectCustomRange(DateTimeRange(start: date, end: end));
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSizes.spacing12),
              Expanded(
                child: _buildDateField(
                  'To',
                  _selectedRange?.end ?? DateTime.now(),
                  (date) {
                    final start =
                        _selectedRange?.start ??
                        DateTime.now().subtract(const Duration(days: 7));
                    if (date.isAfter(start)) {
                      _selectCustomRange(
                        DateTimeRange(start: start, end: date),
                      );
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

  Widget _buildDateField(
    String label,
    DateTime date,
    Function(DateTime) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSizes.spacing4),
        InkWell(
          onTap: () async {
            final selectedDate = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(
                      context,
                    ).colorScheme.copyWith(primary: AppColors.primary),
                  ),
                  child: child!,
                );
              },
            );
            if (selectedDate != null) {
              onChanged(selectedDate);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacing12,
              vertical: AppSizes.spacing8,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSizes.spacing8),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _selectQuickRange(QuickDateRange range) {
    final now = DateTime.now();
    final start = now.subtract(range.duration);
    final dateRange = DateTimeRange(start: start, end: now);

    setState(() {
      _selectedQuickRange = range;
      _selectedRange = dateRange;
    });

    widget.onRangeSelected(dateRange);
    _closeDropdown();
  }

  void _selectCustomRange(DateTimeRange range) {
    setState(() {
      _selectedQuickRange = null; // Clear quick selection
      _selectedRange = range;
    });

    widget.onRangeSelected(range);
    _closeDropdown();
  }

  String _formatDisplayRange() {
    if (_selectedRange == null) {
      return 'Select date range';
    }

    final start = _selectedRange!.start;
    final end = _selectedRange!.end;

    return '${_formatDate(start)} - ${_formatDate(end)}';
  }

  String _formatDate(DateTime date) {
    final months = [
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: widget.enabled ? _toggleDropdown : null,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacing16,
            vertical: AppSizes.spacing12,
          ),
          decoration: BoxDecoration(
            color: widget.enabled
                ? AppColors.surface
                : AppColors.surfaceVariant,
            border: Border.all(
              color: _isDropdownOpen ? AppColors.primary : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today,
                size: 18,
                color: widget.enabled
                    ? AppColors.textSecondary
                    : AppColors.textTertiary,
              ),
              const SizedBox(width: AppSizes.spacing8),
              Text(
                _formatDisplayRange(),
                style: TextStyle(
                  fontSize: 14,
                  color: widget.enabled
                      ? AppColors.textPrimary
                      : AppColors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: AppSizes.spacing8),
              Icon(
                _isDropdownOpen
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 18,
                color: widget.enabled
                    ? AppColors.textSecondary
                    : AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
