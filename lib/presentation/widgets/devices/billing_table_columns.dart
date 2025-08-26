import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mdms_clone/core/constants/app_sizes.dart';
import '../common/blunest_data_table.dart';
import '../../../core/constants/app_colors.dart';

class BillingTableColumns {
  static List<BluNestTableColumn<Map<String, dynamic>>> getColumns({
    int currentPage = 1,
    int itemsPerPage = 25,
    List<Map<String, dynamic>>? billingRecords,
    Function(Map<String, dynamic>)? onRowTapped,
  }) {
    return [
      // No. (Row Number)
      BluNestTableColumn<Map<String, dynamic>>(
        key: 'no',
        title: 'No.',
        flex: 1,
        sortable: false,
        builder: (record) {
          final index = billingRecords?.indexOf(record) ?? 0;
          final rowNumber = ((currentPage - 1) * itemsPerPage) + index + 1;
          return Container(
            alignment: Alignment.centerLeft,
            height: AppSizes.spacing40,
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

      // Billing Period
      BluNestTableColumn<Map<String, dynamic>>(
        key: 'period',
        title: 'Billing Period',
        flex: 3,
        sortable: true,
        builder: (record) {
          final startTime =
              DateTime.tryParse(record['StartTime'] ?? '') ?? DateTime.now();
          final endTime =
              DateTime.tryParse(record['EndTime'] ?? '') ?? DateTime.now();

          return Container(
            height: AppSizes.spacing40,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '${DateFormat('MMM d, y').format(startTime)} - ${DateFormat('MMM d, y').format(endTime)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1e293b),
              ),
            ),
          );
        },
      ),

      // Time of Use
      BluNestTableColumn<Map<String, dynamic>>(
        key: 'timeOfUse',
        title: 'Time of Use',
        flex: 2,
        sortable: true,
        builder: (record) {
          final timeOfUse = record['TimeOfUse'] ?? {};
          final touName = timeOfUse['Code'] ?? 'N/A';

          return Container(
            height: AppSizes.spacing40,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                touName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          );
        },
      ),

      // Start Date
      BluNestTableColumn<Map<String, dynamic>>(
        key: 'startDate',
        title: 'Start Date',
        flex: 2,
        sortable: true,
        builder: (record) {
          final startTime =
              DateTime.tryParse(record['StartTime'] ?? '') ?? DateTime.now();

          return Container(
            height: AppSizes.spacing40,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              DateFormat('MMM d, y HH:mm').format(startTime),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748b),
              ),
            ),
          );
        },
      ),

      // End Date
      BluNestTableColumn<Map<String, dynamic>>(
        key: 'endDate',
        title: 'End Date',
        flex: 2,
        sortable: true,
        builder: (record) {
          final endTime =
              DateTime.tryParse(record['EndTime'] ?? '') ?? DateTime.now();

          return Container(
            height: AppSizes.spacing40,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              DateFormat('MMM d, y HH:mm').format(endTime),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748b),
              ),
            ),
          );
        },
      ),

      // Duration
      BluNestTableColumn<Map<String, dynamic>>(
        key: 'duration',
        title: 'Duration',
        flex: 2,
        sortable: true,
        builder: (record) {
          final startTime =
              DateTime.tryParse(record['StartTime'] ?? '') ?? DateTime.now();
          final endTime =
              DateTime.tryParse(record['EndTime'] ?? '') ?? DateTime.now();
          final duration = endTime.difference(startTime);

          String durationText;
          if (duration.inDays > 0) {
            durationText = '${duration.inDays} days';
          } else if (duration.inHours > 0) {
            durationText = '${duration.inHours} hours';
          } else {
            durationText = '${duration.inMinutes} minutes';
          }

          return Container(
            height: AppSizes.spacing40,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              durationText,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1e293b),
              ),
            ),
          );
        },
      ),

      // Actions
      BluNestTableColumn<Map<String, dynamic>>(
        key: 'actions',
        title: 'Actions',
        flex: 1,
        sortable: false,
        builder: (record) {
          return Container(
            alignment: Alignment.center,
            height: AppSizes.spacing40,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Center(
              child: IconButton(
                onPressed: () => onRowTapped?.call(record),
                icon: const Icon(Icons.visibility, size: 16),
                tooltip: 'View Billing Readings',
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(32, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          );
        },
      ),
    ];
  }
}



