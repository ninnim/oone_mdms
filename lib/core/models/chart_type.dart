import 'package:flutter/material.dart';

enum ChartType { line, bar, area }

extension ChartTypeExtension on ChartType {
  String get displayName {
    switch (this) {
      case ChartType.line:
        return 'Line Chart';
      case ChartType.bar:
        return 'Bar Chart';
      case ChartType.area:
        return 'Area Chart';
    }
  }

  IconData get icon {
    switch (this) {
      case ChartType.line:
        return Icons.show_chart;
      case ChartType.bar:
        return Icons.bar_chart;
      case ChartType.area:
        return Icons.area_chart;
    }
  }
}
