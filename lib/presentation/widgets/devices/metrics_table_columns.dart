import 'package:flutter/material.dart';
import '../common/blunest_data_table.dart';
import '../../../core/constants/app_colors.dart';

class MetricsTableColumns {
  static List<BluNestTableColumn<Map<String, dynamic>>> getColumns({
    int currentPage = 1,
    int itemsPerPage = 25,
    List<Map<String, dynamic>>? metrics,
  }) {
    return [
      // No. (Row Number)
      BluNestTableColumn<Map<String, dynamic>>(
        key: 'no',
        title: 'No.',
        flex: 1,
        sortable: false,
        builder: (metric) {
          final index = metrics?.indexOf(metric) ?? 0;
          final rowNumber = ((currentPage - 1) * itemsPerPage) + index + 1;
          return Container(
            // alignment: Alignment.center,
            child: Text(
              '$rowNumber',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
          );
        },
      ),

      // Timestamp
      BluNestTableColumn<Map<String, dynamic>>(
        key: 'timestamp',
        title: 'Timestamp',
        flex: 2,
        sortable: true,
        builder: (metric) => Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            metric['Timestamp']?.toString() ?? 'N/A',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1e293b),
            ),
          ),
        ),
      ),

      // Value
      BluNestTableColumn<Map<String, dynamic>>(
        key: 'value',
        title: 'Value',
        flex: 1,
        sortable: true,
        builder: (metric) {
          final value = metric['Value'];
          final units = metric['Labels']?['Units'] ?? '';

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              value != null ? '$value $units'.trim() : 'N/A',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          );
        },
      ),

      // PreValue Value
      BluNestTableColumn<Map<String, dynamic>>(
        key: 'PreValue',
        title: 'PreValue',
        flex: 1,
        sortable: true,
        builder: (metric) {
          final PreValue = metric['PreValue'];
          final units = metric['Labels']?['Units'] ?? '';

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              PreValue != null ? '$PreValue $units'.trim() : 'N/A',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
          );
        },
      ),

      // Change
      BluNestTableColumn<Map<String, dynamic>>(
        key: 'change',
        title: 'Change',
        flex: 1,
        sortable: true,
        builder: (metric) {
          final value = metric['Value'];
          final PreValue = metric['PreValue'];

          if (value == null || PreValue == null) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Text(
                'N/A',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
            );
          }

          double change = 0;
          Color changeColor = Color(0xFF6B7280);
          IconData? changeIcon;

          try {
            final currentValue = double.parse(value.toString());
            final PreValueValue = double.parse(PreValue.toString());
            change = currentValue - PreValueValue;

            if (change > 0) {
              changeColor = AppColors.success;
              changeIcon = Icons.trending_up;
            } else if (change < 0) {
              changeColor = AppColors.error;
              changeIcon = Icons.trending_down;
            } else {
              changeIcon = Icons.trending_flat;
            }
          } catch (e) {
            // If parsing fails, show N/A
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Text(
                'N/A',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
            );
          }

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(changeIcon, size: 14, color: changeColor),
                const SizedBox(width: 4),
                Text(
                  change.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: changeColor,
                  ),
                ),
              ],
            ),
          );
        },
      ),

      // Phase
      BluNestTableColumn<Map<String, dynamic>>(
        key: 'phase',
        title: 'Phase',
        flex: 1,
        sortable: true,
        builder: (metric) {
          final phase = metric['Labels']?['Phase'] ?? metric['Phase'];

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              phase?.toString() ?? 'N/A',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1e293b),
              ),
            ),
          );
        },
      ),

      // Units
      BluNestTableColumn<Map<String, dynamic>>(
        key: 'units',
        title: 'Units',
        flex: 1,
        sortable: true,
        builder: (metric) {
          final units = metric['Labels']?['Units'] ?? metric['Units'];

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                units?.toString() ?? 'N/A',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondary,
                ),
              ),
            ),
          );
        },
      ),
    ];
  }
}
