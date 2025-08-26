import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mdms_clone/core/constants/app_sizes.dart';
// import '../../../core/constants/app_colors.dart';
import '../../themes/app_theme.dart';
import '../common/blunest_data_table.dart';

class DynamicMetricsTableColumns {
  /// Generates dynamic columns based on the fields in the metrics data
  static List<BluNestTableColumn<Map<String, dynamic>>> generateColumns({
    required List<Map<String, dynamic>> metrics,
    int currentPage = 1,
    int itemsPerPage = 25,
    required BuildContext context,
    List<String> hiddenColumns = const [],
  }) {
    final List<BluNestTableColumn<Map<String, dynamic>>> columns = [];

    // Always add row number column first
    columns.add(
      _buildRowNumberColumn(currentPage, itemsPerPage, metrics, context),
    );

    // Add date column after row number if we have timestamp data
    if (metrics.isNotEmpty && metrics.first.containsKey('Timestamp')) {
      columns.add(_buildDateColumn(context));
    }

    if (metrics.isEmpty) {
      return columns;
    }

    // Get all unique field names from the metrics data, excluding Timestamp as it's handled separately
    final Set<String> allFields = <String>{};
    for (final metric in metrics) {
      allFields.addAll(metric.keys.where((key) => key != 'Timestamp'));
    }

    // Convert to sorted list for consistent column order
    final List<String> sortedFields = allFields.toList()..sort();

    // Generate columns for each field
    for (final fieldName in sortedFields) {
      if (!hiddenColumns.contains(fieldName)) {
        columns.add(_buildDynamicColumn(fieldName, metrics, context));
      }
    }

    return columns;
  }

  /// Builds the row number column
  static BluNestTableColumn<Map<String, dynamic>> _buildRowNumberColumn(
    int currentPage,
    int itemsPerPage,
    List<Map<String, dynamic>> metrics,
    BuildContext context,
  ) {
    return BluNestTableColumn<Map<String, dynamic>>(
      key: 'row_number',
      title: 'No.',
      flex: 1,
      sortable: false,
      alignment: Alignment.centerLeft, // Add alignment for header consistency
      builder: (metric) {
        final index = metrics.indexOf(metric);
        final rowNumber = ((currentPage - 1) * itemsPerPage) + index + 1;
        return Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: context.borderColor, width: 0.5),
              bottom: BorderSide(color: context.borderColor, width: 0.5),
            ),
          ),
          child: Text(
            '$rowNumber',
            style: TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              fontWeight: FontWeight.w500,
              color: context.textSecondaryColor,
              fontFamily: 'monospace',
            ),
          ),
        );
      },
    );
  }

  /// Builds the date column showing formatted timestamp
  static BluNestTableColumn<Map<String, dynamic>> _buildDateColumn(
    BuildContext context,
  ) {
    return BluNestTableColumn<Map<String, dynamic>>(
      key: 'date',
      title: 'Time Stamp',
      flex: 3,
      sortable: true,
      alignment: Alignment.centerLeft, // Add alignment for header consistency
      builder: (metric) {
        final timestamp = metric['Timestamp'];
        if (timestamp == null) {
          return Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: context.borderColor, width: 0.5),
                bottom: BorderSide(color: context.borderColor, width: 0.5),
              ),
            ),
            child: Text(
              'N/A',
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: context.textSecondaryColor.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }

        try {
          final DateTime dateTime = DateTime.parse(timestamp.toString());
          final String formattedDate = DateFormat(
            'yyyy-MM-dd HH:mm',
          ).format(dateTime);

          return Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: context.borderColor, width: 0.5),
                bottom: BorderSide(color: context.borderColor, width: 0.5),
              ),
            ),
            child: Text(
              formattedDate,
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                fontWeight: FontWeight.w500,
                color: context.textPrimaryColor,
                fontFamily: 'monospace',
              ),
            ),
          );
        } catch (e) {
          return Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: context.borderColor, width: 0.5),
                bottom: BorderSide(color: context.borderColor, width: 0.5),
              ),
            ),
            child: Text(
              timestamp.toString(),
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: context.textPrimaryColor,
              ),
            ),
          );
        }
      },
    );
  }

  /// Builds a dynamic column for a specific field
  static BluNestTableColumn<Map<String, dynamic>> _buildDynamicColumn(
    String fieldName,
    List<Map<String, dynamic>> metrics,
    BuildContext context,
  ) {
    return BluNestTableColumn<Map<String, dynamic>>(
      key: fieldName,
      title: _formatColumnTitle(fieldName),
      flex: _getColumnFlex(fieldName),
      sortable: true,
      alignment: _getColumnAlignment(
        fieldName,
      ), // Add alignment for header consistency
      builder: (metric) => Container(
        alignment: _getColumnAlignment(fieldName),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: context.borderColor, width: 0.5),
            bottom: BorderSide(color: context.borderColor, width: 0.5),
          ),
        ),
        child: _buildCellContent(metric[fieldName], fieldName, context),
      ),
    );
  }

  /// Formats the column title for better display - showing full names
  static String _formatColumnTitle(String fieldName) {
    // Special cases for common field names
    final Map<String, String> specialNames = {
      'ExportWhTotal': 'Export Wh Total',
      'ExportVarhTotal': 'Export Varh Total',
      'ImportWhTotal': 'Import Wh Total',
      'ImportVarhTotal': 'Import Varh Total',
      'ActivePowerTotal': 'Active Power Total',
      'ApparentEnergyDelivered': 'Apparent Energy Delivered',
      'ApparentEnergyReceived': 'Apparent Energy Received',
      'CurrentPhaseA': 'Current Phase A',
      'CurrentPhaseB': 'Current Phase B',
      'CurrentPhaseC': 'Current Phase C',
      'VoltagePhaseA': 'Voltage Phase A',
      'VoltagePhaseB': 'Voltage Phase B',
      'VoltagePhaseC': 'Voltage Phase C',
      'FrequencyTotal': 'Frequency Total',
      'PowerFactorTotal': 'Power Factor Total',
    };

    // Return special name if exists
    if (specialNames.containsKey(fieldName)) {
      return specialNames[fieldName]!;
    }

    // Convert camelCase to Title Case with spaces
    return fieldName
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .trim()
        .split(' ')
        .map(
          (word) =>
              word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '',
        )
        .join(' ');
  }

  /// Gets the flex value for different column types - increased for full names
  static int _getColumnFlex(String fieldName) {
    switch (fieldName.toLowerCase()) {
      case 'timestamp':
        return 4;
      case 'id':
        return 3;
      default:
        if (fieldName.toLowerCase().contains('total') ||
            fieldName.toLowerCase().contains('energy') ||
            fieldName.toLowerCase().contains('power')) {
          return 4;
        }
        if (fieldName.toLowerCase().contains('phase') ||
            fieldName.toLowerCase().contains('voltage') ||
            fieldName.toLowerCase().contains('current')) {
          return 3;
        }
        return 3;
    }
  }

  /// Gets the alignment for different column types
  static Alignment _getColumnAlignment(String fieldName) {
    switch (fieldName.toLowerCase()) {
      case 'timestamp':
        return Alignment.centerLeft;
      case 'id':
        return Alignment.centerLeft;
      default:
        if (_isNumericField(fieldName)) {
          return Alignment.centerRight;
        }
        return Alignment.centerLeft;
    }
  }

  /// Checks if a field is numeric based on its name
  static bool _isNumericField(String fieldName) {
    final numericPatterns = [
      'total',
      'power',
      'energy',
      'current',
      'voltage',
      'frequency',
      'factor',
      'wh',
      'varh',
      'phase',
      'apparent',
    ];
    return numericPatterns.any(
      (pattern) => fieldName.toLowerCase().contains(pattern),
    );
  }

  /// Builds the cell content with appropriate formatting
  static Widget _buildCellContent(
    dynamic value,
    String fieldName,
    BuildContext context,
  ) {
    if (value == null) {
      return Text(
        'N/A',
        style: TextStyle(
          fontSize: 13,
          color: context.textSecondaryColor.withOpacity(0.6),
          fontStyle: FontStyle.italic,
        ),
      );
    }

    if (fieldName.toLowerCase() == 'timestamp') {
      return _buildTimestampCell(value, context);
    }

    if (_isNumericField(fieldName) && value is num) {
      return _buildNumericCell(value, fieldName, context);
    }

    return _buildTextCell(value.toString(), context);
  }

  /// Builds a timestamp cell with proper formatting
  static Widget _buildTimestampCell(dynamic value, BuildContext context) {
    try {
      final DateTime dateTime = DateTime.parse(value.toString());
      final String formattedDate = DateFormat('MMM dd, yyyy').format(dateTime);
      final String formattedTime = DateFormat('HH:mm:ss').format(dateTime);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            formattedDate,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: context.textPrimaryColor,
            ),
          ),
          Text(
            formattedTime,
            style: TextStyle(
              fontSize: 11,
              color: context.textSecondaryColor.withOpacity(0.8),
            ),
          ),
        ],
      );
    } catch (e) {
      return _buildTextCell(value.toString(), context);
    }
  }

  /// Builds a numeric cell with proper formatting
  static Widget _buildNumericCell(
    num value,
    String fieldName,
    BuildContext context,
  ) {
    String formattedValue;
    Color textColor = context.textPrimaryColor;

    // Format based on field type
    if (fieldName.toLowerCase().contains('total') ||
        fieldName.toLowerCase().contains('energy')) {
      // Large energy values
      formattedValue = _formatLargeNumber(value);
    } else if (fieldName.toLowerCase().contains('power')) {
      // Power values
      formattedValue = _formatNumber(value, 2);
    } else if (fieldName.toLowerCase().contains('voltage')) {
      // Voltage values
      formattedValue = _formatNumber(value, 2);
    } else if (fieldName.toLowerCase().contains('current')) {
      // Current values
      formattedValue = _formatNumber(value, 2);
    } else if (fieldName.toLowerCase().contains('frequency')) {
      // Frequency values
      formattedValue = _formatNumber(value, 3);
    } else if (fieldName.toLowerCase().contains('factor')) {
      // Power factor values
      formattedValue = _formatNumber(value, 3);
      if (value < 0) textColor = context.errorColor;
    } else {
      // Default numeric formatting
      formattedValue = _formatNumber(value, 2);
    }

    return Text(
      formattedValue,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: textColor,
        fontFamily: 'monospace', // Better for numbers
      ),
      textAlign: TextAlign.right,
    );
  }

  /// Builds a text cell
  static Widget _buildTextCell(String value, BuildContext context) {
    return Text(
      value,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: context.textPrimaryColor,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
    );
  }

  /// Formats large numbers with commas and appropriate decimal places
  static String _formatLargeNumber(num value) {
    if (value.abs() >= 1000000000) {
      return NumberFormat('#,##0.00').format(value);
    } else if (value.abs() >= 1000000) {
      return NumberFormat('#,##0.00').format(value);
    } else if (value.abs() >= 1000) {
      return NumberFormat('#,##0.00').format(value);
    } else {
      return NumberFormat('#,##0.00').format(value);
    }
  }

  /// Formats numbers with specified decimal places and thousands separator
  static String _formatNumber(num value, int decimalPlaces) {
    final formatter = NumberFormat('#,##0.${'0' * decimalPlaces}');
    return formatter.format(value);
  }

  /// Gets all available column keys for hide/show functionality
  static List<String> getAllColumnKeys(List<Map<String, dynamic>> metrics) {
    final Set<String> allFields = <String>{};
    for (final metric in metrics) {
      allFields.addAll(metric.keys);
    }
    return ['row_number', ...allFields.toList()..sort()];
  }

  /// Gets human-readable column names for hide/show functionality
  static Map<String, String> getColumnDisplayNames(
    List<Map<String, dynamic>> metrics,
  ) {
    final Map<String, String> displayNames = {'row_number': 'Row Number'};

    final Set<String> allFields = <String>{};
    for (final metric in metrics) {
      allFields.addAll(metric.keys);
    }

    for (final field in allFields) {
      displayNames[field] = _formatColumnTitle(field);
    }

    return displayNames;
  }
}
