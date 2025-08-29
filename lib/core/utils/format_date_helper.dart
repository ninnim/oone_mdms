// Helper to format start of day
String formatStartOfDay(DateTime date) {
  final start = DateTime(date.year, date.month, date.day, 0, 0, 0, 0, 0);
  return start.toIso8601String();
}

// Helper to format end of day
String formatEndOfDay(DateTime date) {
  final end = DateTime(date.year, date.month, date.day, 23, 59, 59, 999, 999);
  return end.toIso8601String();
}