import '../core/extensions/date_extensions.dart';

/// Time range filter used across progress screens.
enum TimeRange {
  sevenDays('7 Days', 7),
  thirtyDays('30 Days', 30),
  ninetyDays('90 Days', 90),
  allTime('All Time', null);

  const TimeRange(this.label, this.days);

  final String label;

  /// Number of days covered, `null` for all-time.
  final int? days;

  bool get isDaily => days != null && days! <= 31;

  bool get isAllTime => days == null;

  /// Inclusive first date for this range (local date).
  DateTime start(DateTime now) => days == null
      ? DateTime(2000, 1, 1)
      : now.dateOnly.subtract(Duration(days: days! - 1));
}

/// One bucket on a frequency/volume chart (a day or a week).
class ProgressBucket {
  final DateTime start;
  final String label;
  final int workouts;
  final double volume;

  const ProgressBucket({
    required this.start,
    required this.label,
    this.workouts = 0,
    this.volume = 0,
  });
}

/// Aggregated workout statistics for a time range plus chart buckets.
class ProgressOverview {
  final int workouts;
  final int completedSets;
  final int totalReps;
  final double volume;
  final int avgDurationMinutes;
  final DateTime? earliest;
  final List<ProgressBucket> buckets;

  const ProgressOverview({
    required this.workouts,
    required this.completedSets,
    required this.totalReps,
    required this.volume,
    required this.avgDurationMinutes,
    this.earliest,
    required this.buckets,
  });

  bool get isEmpty => workouts == 0;
}