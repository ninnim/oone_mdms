import 'package:flutter/material.dart';
// import '../../../core/constants/app_colors.dart';
import '../../themes/app_theme.dart';
import '../../../core/constants/app_sizes.dart';

enum TimeInterval {
  fifteenMin('15mn', Duration(minutes: 15)),
  thirtyMin('30mn', Duration(minutes: 30)),
  oneHour('1H', Duration(hours: 1)),
  sixHours('6H', Duration(hours: 6)),
  oneWeek('1W', Duration(days: 7)),
  thirtyDays('30D', Duration(days: 30)),
  oneYear('1Y', Duration(days: 365));

  const TimeInterval(this.label, this.duration);
  final String label;
  final Duration duration;
}

class TimeIntervalFilter extends StatefulWidget {
  final TimeInterval selectedInterval;
  final Function(TimeInterval) onIntervalChanged;
  final bool enabled;

  const TimeIntervalFilter({
    super.key,
    required this.selectedInterval,
    required this.onIntervalChanged,
    this.enabled = true,
  });

  @override
  State<TimeIntervalFilter> createState() => _TimeIntervalFilterState();
}

class _TimeIntervalFilterState extends State<TimeIntervalFilter> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: TimeInterval.values.map((interval) {
          final isSelected = widget.selectedInterval == interval;
          return GestureDetector(
            onTap: widget.enabled
                ? () => widget.onIntervalChanged(interval)
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isSelected ? context.primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                interval.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : widget.enabled
                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}




