/// 🔧 BACKEND - Date Utility Functions
///
/// Đây là PURE BACKEND - date processing utilities
/// Không có UI logic hay Riverpod dependency
/// Provides clean date operations cho business logic
class DateUtils {
  /// ✅ BACKEND UTILITY LOGIC - Date Calculations

  /// Check if date is today
  static bool isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  /// Check if date is tomorrow
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  /// Check if date is this week
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return date.isAfter(startOfWeek) && date.isBefore(endOfWeek);
  }

  /// Check if date is this month
  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  /// Check if date is overdue
  static bool isOverdue(DateTime date) {
    return DateTime.now().isAfter(date);
  }

  /// Get days until date (negative if overdue)
  static int getDaysUntil(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    return targetDate.difference(today).inDays;
  }

  /// ✅ BACKEND UTILITY LOGIC - Date Formatting

  /// Get human readable relative date
  static String getRelativeDate(DateTime date) {
    final daysUntil = getDaysUntil(date);

    if (daysUntil == 0) return 'Today';
    if (daysUntil == 1) return 'Tomorrow';
    if (daysUntil == -1) return 'Yesterday';

    // For future dates beyond tomorrow, show the actual date
    // instead of "In X days" for better clarity
    if (daysUntil > 1) return formatDate(date);

    if (daysUntil < -1 && daysUntil >= -7) return '${-daysUntil} days ago';
    if (daysUntil < -7) return '${(-daysUntil / 7).floor()} weeks ago';

    return formatDate(date);
  }

  /// Format date as string
  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Format date with time
  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// ✅ BACKEND UTILITY LOGIC - Date Grouping

  /// Group dates by time period
  static String getDateGroup(DateTime date) {
    if (isToday(date)) return 'Today';
    if (isTomorrow(date)) return 'Tomorrow';
    if (isThisWeek(date)) return 'This Week';
    if (isThisMonth(date)) return 'This Month';
    if (isOverdue(date)) return 'Overdue';
    return 'Later';
  }

  /// ✅ BACKEND UTILITY LOGIC - Date Ranges

  /// Get start of week
  static DateTime getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  /// Get end of week
  static DateTime getEndOfWeek(DateTime date) {
    return getStartOfWeek(date).add(const Duration(days: 6));
  }

  /// Get start of month
  static DateTime getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get end of month
  static DateTime getEndOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// ✅ BACKEND UTILITY LOGIC - Business Logic

  /// Check if date is in business hours
  static bool isBusinessHours(DateTime date) {
    return date.hour >= 9 && date.hour <= 17 && date.weekday <= 5;
  }

  /// Get next business day
  static DateTime getNextBusinessDay(DateTime date) {
    DateTime nextDay = date.add(const Duration(days: 1));
    while (nextDay.weekday > 5) {
      nextDay = nextDay.add(const Duration(days: 1));
    }
    return nextDay;
  }

  /// Get working days count between dates
  static int getWorkingDaysBetween(DateTime start, DateTime end) {
    int workingDays = 0;
    DateTime current = start;

    while (current.isBefore(end)) {
      if (current.weekday <= 5) {
        workingDays++;
      }
      current = current.add(const Duration(days: 1));
    }

    return workingDays;
  }
}
