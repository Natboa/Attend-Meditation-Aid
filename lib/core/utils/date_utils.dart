extension AttendDateUtils on DateTime {
  /// Day of year (1–366). Used for deterministic poem-of-day selection.
  int get dayOfYear {
    final startOfYear = DateTime(year, 1, 1);
    return difference(startOfYear).inDays + 1;
  }

  /// True if this DateTime is on the same calendar day as [other].
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}

/// Returns the greeting based on the current hour.
String timeOfDayGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}
