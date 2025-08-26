import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../common/blunest_data_table.dart';
import '../../../core/constants/app_colors.dart';
import '../../themes/app_theme.dart';
import '../../../core/models/billing.dart';

class BillingReadingsTableColumns {
  static List<BluNestTableColumn<DeviceBillingReading>> getColumns({
    int currentPage = 1,
    int itemsPerPage = 25,
    List<DeviceBillingReading>? readings,
  }) {
    return [
      // No. (Row Number)
      BluNestTableColumn<DeviceBillingReading>(
        key: 'no',
        title: 'No.',
        flex: 1,
        sortable: false,
        builder: (reading) {
          final index = readings?.indexOf(reading) ?? 0;
          final rowNumber = ((currentPage - 1) * itemsPerPage) + index + 1;
          return Container(
            child: Builder(
              builder: (context) => Text(
                '$rowNumber',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          );
        },
      ),

      // Billing Date
      BluNestTableColumn<DeviceBillingReading>(
        key: 'billingDate',
        title: 'Billing Date',
        flex: 2,
        sortable: true,
        builder: (reading) => Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Builder(
            builder: (context) => Text(
              DateFormat('MMM d, y HH:mm').format(reading.billingDate),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),

      // Accumulative Value
      BluNestTableColumn<DeviceBillingReading>(
        key: 'accumulativeValue',
        title: 'Value',
        flex: 2,
        sortable: true,
        builder: (reading) {
          final value = reading.accumulativeValue;
          final units = reading.metricLabels.units;

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Builder(
              builder: (context) => Text(
                '${value.toStringAsFixed(2)} $units',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.primaryColor,
                ),
              ),
            ),
          );
        },
      ),

      // Phase
      BluNestTableColumn<DeviceBillingReading>(
        key: 'phase',
        title: 'Phase',
        flex: 1,
        sortable: true,
        builder: (reading) => Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            reading.metricLabels.phase,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),

      // Units
      BluNestTableColumn<DeviceBillingReading>(
        key: 'units',
        title: 'Units',
        flex: 1,
        sortable: true,
        builder: (reading) => Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              reading.metricLabels.units,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.secondary,
              ),
            ),
          ),
        ),
      ),

      // Flow Direction
      BluNestTableColumn<DeviceBillingReading>(
        key: 'flowDirection',
        title: 'Flow Direction',
        flex: 2,
        sortable: true,
        builder: (reading) {
          final flowDirection = reading.metricLabels.flowDirection;
          Color chipColor = AppColors.secondary;

          switch (flowDirection.toUpperCase()) {
            case 'RECEIVED':
              chipColor = AppColors.success;
              break;
            case 'DELIVERED':
              chipColor = AppColors.warning;
              break;
            case 'NONE':
              chipColor = AppColors.secondary;
              break;
          }

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: chipColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                flowDirection,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: chipColor,
                ),
              ),
            ),
          );
        },
      ),

      // Time of Use
      BluNestTableColumn<DeviceBillingReading>(
        key: 'timeOfUse',
        title: 'Time of Use',
        flex: 2,
        sortable: true,
        builder: (reading) => Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              reading.timeOfUse.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    ];
  }
}
