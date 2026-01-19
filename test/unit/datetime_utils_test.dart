// Unit tests for Date/Time utilities
import 'package:flutter_test/flutter_test.dart';

// Mock DateTimeUtils class with common formatting and calculation functions
class DateTimeUtils {
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} ${formatTime(dateTime)}';
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  static String formatTimerDisplay(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()}w ago';
    } else {
      return formatDate(dateTime);
    }
  }

  static String getDayOfWeek(DateTime date) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[date.weekday - 1];
  }

  static String getShortDayOfWeek(DateTime date) {
    return getDayOfWeek(date).substring(0, 3);
  }

  static String getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  static String getShortMonthName(int month) {
    return getMonthName(month).substring(0, 3);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  static DateTime startOfWeek(DateTime date) {
    final daysToSubtract = date.weekday - 1;
    return startOfDay(date.subtract(Duration(days: daysToSubtract)));
  }

  static DateTime endOfWeek(DateTime date) {
    final daysToAdd = 7 - date.weekday;
    return endOfDay(date.add(Duration(days: daysToAdd)));
  }

  static int daysBetween(DateTime from, DateTime to) {
    final fromDate = startOfDay(from);
    final toDate = startOfDay(to);
    return toDate.difference(fromDate).inDays;
  }

  static int weeksBetween(DateTime from, DateTime to) {
    return (daysBetween(from, to) / 7).floor();
  }

  static List<DateTime> getWeekDays(DateTime referenceDate) {
    final start = startOfWeek(referenceDate);
    return List.generate(7, (index) => start.add(Duration(days: index)));
  }
}

void main() {
  group('Date Formatting', () {
    test('formatDate formats correctly', () {
      expect(DateTimeUtils.formatDate(DateTime(2026, 1, 5)), '05/01/2026');
      expect(DateTimeUtils.formatDate(DateTime(2026, 12, 25)), '25/12/2026');
    });

    test('formatTime formats correctly', () {
      expect(DateTimeUtils.formatTime(DateTime(2026, 1, 1, 9, 30)), '09:30');
      expect(DateTimeUtils.formatTime(DateTime(2026, 1, 1, 14, 5)), '14:05');
    });

    test('formatDateTime combines date and time', () {
      expect(
        DateTimeUtils.formatDateTime(DateTime(2026, 1, 15, 10, 30)),
        '15/01/2026 10:30',
      );
    });
  });

  group('Duration Formatting', () {
    test('formatDuration for hours', () {
      expect(
        DateTimeUtils.formatDuration(const Duration(hours: 2, minutes: 30)),
        '2h 30m',
      );
    });

    test('formatDuration for minutes', () {
      expect(
        DateTimeUtils.formatDuration(const Duration(minutes: 45, seconds: 30)),
        '45m 30s',
      );
    });

    test('formatDuration for seconds only', () {
      expect(DateTimeUtils.formatDuration(const Duration(seconds: 45)), '45s');
    });

    test('formatTimerDisplay for workout timer', () {
      expect(
        DateTimeUtils.formatTimerDisplay(const Duration(minutes: 5)),
        '05:00',
      );
      expect(
        DateTimeUtils.formatTimerDisplay(
          const Duration(minutes: 45, seconds: 30),
        ),
        '45:30',
      );
      expect(
        DateTimeUtils.formatTimerDisplay(const Duration(seconds: 90)),
        '01:30',
      );
    });
  });

  group('Time Ago', () {
    test('timeAgo returns Just now for recent', () {
      expect(DateTimeUtils.timeAgo(DateTime.now()), 'Just now');
    });

    test('timeAgo returns minutes ago', () {
      expect(
        DateTimeUtils.timeAgo(
          DateTime.now().subtract(const Duration(minutes: 30)),
        ),
        '30m ago',
      );
    });

    test('timeAgo returns hours ago', () {
      expect(
        DateTimeUtils.timeAgo(
          DateTime.now().subtract(const Duration(hours: 5)),
        ),
        '5h ago',
      );
    });

    test('timeAgo returns days ago', () {
      expect(
        DateTimeUtils.timeAgo(DateTime.now().subtract(const Duration(days: 3))),
        '3d ago',
      );
    });

    test('timeAgo returns weeks ago', () {
      expect(
        DateTimeUtils.timeAgo(
          DateTime.now().subtract(const Duration(days: 14)),
        ),
        '2w ago',
      );
    });
  });

  group('Day and Month Names', () {
    test('getDayOfWeek returns correct day', () {
      // January 20, 2026 is a Tuesday
      expect(DateTimeUtils.getDayOfWeek(DateTime(2026, 1, 20)), 'Tuesday');
    });

    test('getShortDayOfWeek returns 3-letter abbreviation', () {
      expect(DateTimeUtils.getShortDayOfWeek(DateTime(2026, 1, 20)), 'Tue');
    });

    test('getMonthName returns correct month', () {
      expect(DateTimeUtils.getMonthName(1), 'January');
      expect(DateTimeUtils.getMonthName(6), 'June');
      expect(DateTimeUtils.getMonthName(12), 'December');
    });

    test('getShortMonthName returns 3-letter abbreviation', () {
      expect(DateTimeUtils.getShortMonthName(1), 'Jan');
      expect(DateTimeUtils.getShortMonthName(9), 'Sep');
    });
  });

  group('Date Comparisons', () {
    test('isSameDay returns true for same day', () {
      expect(
        DateTimeUtils.isSameDay(
          DateTime(2026, 1, 15, 10, 0),
          DateTime(2026, 1, 15, 18, 30),
        ),
        true,
      );
    });

    test('isSameDay returns false for different days', () {
      expect(
        DateTimeUtils.isSameDay(DateTime(2026, 1, 15), DateTime(2026, 1, 16)),
        false,
      );
    });

    test('isToday returns true for today', () {
      expect(DateTimeUtils.isToday(DateTime.now()), true);
    });

    test('isToday returns false for yesterday', () {
      expect(
        DateTimeUtils.isToday(DateTime.now().subtract(const Duration(days: 1))),
        false,
      );
    });

    test('isYesterday returns true for yesterday', () {
      expect(
        DateTimeUtils.isYesterday(
          DateTime.now().subtract(const Duration(days: 1)),
        ),
        true,
      );
    });
  });

  group('Date Boundaries', () {
    test('startOfDay returns midnight', () {
      final result = DateTimeUtils.startOfDay(DateTime(2026, 1, 15, 14, 30));
      expect(result.hour, 0);
      expect(result.minute, 0);
      expect(result.second, 0);
    });

    test('endOfDay returns 23:59:59', () {
      final result = DateTimeUtils.endOfDay(DateTime(2026, 1, 15, 10, 0));
      expect(result.hour, 23);
      expect(result.minute, 59);
      expect(result.second, 59);
    });

    test('startOfWeek returns Monday', () {
      // January 15, 2026 is a Thursday
      final result = DateTimeUtils.startOfWeek(DateTime(2026, 1, 15));
      expect(result.weekday, 1); // Monday
      expect(result.day, 12);
    });

    test('endOfWeek returns Sunday', () {
      final result = DateTimeUtils.endOfWeek(DateTime(2026, 1, 15));
      expect(result.weekday, 7); // Sunday
      expect(result.day, 18);
    });
  });

  group('Date Calculations', () {
    test('daysBetween calculates correctly', () {
      expect(
        DateTimeUtils.daysBetween(DateTime(2026, 1, 1), DateTime(2026, 1, 15)),
        14,
      );
    });

    test('weeksBetween calculates correctly', () {
      expect(
        DateTimeUtils.weeksBetween(DateTime(2026, 1, 1), DateTime(2026, 1, 29)),
        4,
      );
    });

    test('getWeekDays returns 7 days', () {
      final days = DateTimeUtils.getWeekDays(DateTime(2026, 1, 15));
      expect(days.length, 7);
      expect(days.first.weekday, 1); // Monday
      expect(days.last.weekday, 7); // Sunday
    });
  });
}
