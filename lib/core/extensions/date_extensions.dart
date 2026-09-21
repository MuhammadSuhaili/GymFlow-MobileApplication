import 'package:intl/intl.dart';

extension DateExtensions on DateTime {
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return year == y.year && month == y.month && day == y.day;
  }

  DateTime get dateOnly => DateTime(year, month, day);

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  String get isoDate =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  String get isoDateTime =>
      '$isoDate ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  String get displayMonthDay => DateFormat.MMMd().format(this);

  String get displayFull => DateFormat.yMMMMEEEEd().format(this);

  String get displayShort => DateFormat.yMMMd().format(this);

  String get displayWeekday => DateFormat.EEEE().format(this);

  String get monthLabel => DateFormat.yMMMM().format(this);

  String get weekdayShort {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[weekday - 1];
  }

  String get dayOfWeekFull {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[weekday - 1];
  }

  DateTime get startOfWeek => DateTime(year, month, day).subtract(
        Duration(days: weekday - 1),
      );

  DateTime get endOfWeek => startOfWeek.add(const Duration(days: 6));

  DateTime get startOfMonth => DateTime(year, month, 1);

  DateTime get endOfMonth => DateTime(year, month + 1, 0);

  static DateTime parseISO(String value) {
    final dateOnly = value.length == 10;
    final parsed = DateTime.parse(value);
    return dateOnly ? parsed : parsed;
  }
}

extension DateListExtension on DateTime {
  /// Day name for a given weekday number (1=Monday .. 7=Sunday).
  static String dayName(int weekdayNumber) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[(weekdayNumber - 1) % 7];
  }
}

/// Shortcuts for weekday numbers where 1 = Monday .. 7 = Sunday.
extension WeekdayNumberExtension on int {
  static const List<String> _short = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _full = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  String get weekdayShort => _short[(this - 1) % 7];

  String get dayOfWeekFull => _full[(this - 1) % 7];
}