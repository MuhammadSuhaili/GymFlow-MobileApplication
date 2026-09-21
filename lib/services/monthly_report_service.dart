import 'package:gym_flow/core/extensions/date_extensions.dart';
import 'package:gym_flow/models/body_measurement.dart';
import 'package:gym_flow/models/progress_models.dart';

/// A completed session inside the reporting month (plain data, decoupled from
/// the database layer so the report logic stays deterministic and testable).
class MonthlySession {
  final DateTime date;
  final int completedSets;
  final int totalReps;
  final double volume;
  final int durationMinutes;
  final String? programId;
  final List<int> rpes;

  const MonthlySession({
    required this.date,
    required this.completedSets,
    required this.totalReps,
    required this.volume,
    required this.durationMinutes,
    this.programId,
    this.rpes = const [],
  });
}

/// Best weight + reps an exercise reached in a single lift-logged day.
class LiftSample {
  final DateTime date;
  final double weight;
  final int reps;

  const LiftSample({
    required this.date,
    required this.weight,
    required this.reps,
  });
}

/// All available lift history for one exercise, split between the month and
/// everything before it.
class ExerciseMonthData {
  final String exerciseId;
  final String exerciseName;
  final List<LiftSample> inMonth;
  final List<LiftSample> beforeMonth;

  const ExerciseMonthData({
    required this.exerciseId,
    required this.exerciseName,
    this.inMonth = const [],
    this.beforeMonth = const [],
  });
}

/// The active program's role during the reporting month. `scheduledDates` are
/// the deterministic calendar days an exercise was planned, already confined
/// to the month by the caller.
class MonthlyProgramInput {
  final String programId;
  final String name;
  final String goal;
  final int durationWeeks;
  final List<DateTime> scheduledDates;
  final List<MonthlySession> programSessions;

  const MonthlyProgramInput({
    required this.programId,
    required this.name,
    required this.goal,
    required this.durationWeeks,
    this.scheduledDates = const [],
    this.programSessions = const [],
  });
}

/// Everything the report needs, gathered by the provider layer.
class MonthlyReportInputs {
  final int year;
  final int month;
  final List<MonthlySession> monthSessions;
  final List<MonthlySession> previousMonthSessions;
  final List<BodyMeasurement> monthMeasurements;
  final BodyMeasurement? latestRecentMeasurement;
  final ({int current, int best}) currentStreak;
  final MonthlyProgramInput? program;
  final List<ExerciseMonthData> exercises;

  const MonthlyReportInputs({
    required this.year,
    required this.month,
    this.monthSessions = const [],
    this.previousMonthSessions = const [],
    this.monthMeasurements = const [],
    this.latestRecentMeasurement,
    this.currentStreak = (current: 0, best: 0),
    this.program,
    this.exercises = const [],
  });

  DateTime get monthStart => DateTime(year, month, 1);

  DateTime get monthEnd => DateTime(year, month + 1, 0);
}

/// How an exercise performed this month relative to its own previous best.
enum ExerciseProgressionStatus {
  weightUp,
  repsUp,
  maintained,
  firstLiftThisMonth,
  belowPreviousBest,
}

extension ExerciseProgressionStatusLabel on ExerciseProgressionStatus {
  String get label {
    switch (this) {
      case ExerciseProgressionStatus.weightUp:
        return 'Heavier weight';
      case ExerciseProgressionStatus.repsUp:
        return 'More reps';
      case ExerciseProgressionStatus.maintained:
        return 'Maintained';
      case ExerciseProgressionStatus.firstLiftThisMonth:
        return 'First lifts this month';
      case ExerciseProgressionStatus.belowPreviousBest:
        return 'Below previous best';
    }
  }
}

/// Best lift an exercise reached during the month, compared to its previous
/// best (before the month).
class ExerciseMonthBest {
  final String exerciseId;
  final String exerciseName;
  final double monthBestWeight;
  final int monthBestReps;
  final double monthVolume;
  final int monthSessions;
  final double? previousBestWeight;
  final int? previousBestReps;
  final ExerciseProgressionStatus status;

  const ExerciseMonthBest({
    required this.exerciseId,
    required this.exerciseName,
    required this.monthBestWeight,
    required this.monthBestReps,
    required this.monthVolume,
    required this.monthSessions,
    this.previousBestWeight,
    this.previousBestReps,
    required this.status,
  });
}

/// Program info shown on the report (created mid-month is allowed; the caller
/// only passes a program that actually existed during the month).
class MonthlyProgramStats {
  final String programId;
  final String name;
  final String goal;
  final int durationWeeks;
  final int scheduledWorkouts;
  final int completedWorkouts;

  const MonthlyProgramStats({
    required this.programId,
    required this.name,
    required this.goal,
    required this.durationWeeks,
    required this.scheduledWorkouts,
    required this.completedWorkouts,
  });
}

/// Body composition changes between the first and last measurement of the
/// month. Deltas are only computed when both entries contain the field.
class MeasurementChanges {
  final DateTime firstDate;
  final DateTime lastDate;
  final double? startWeightKg;
  final double? endWeightKg;
  final double? bodyFatStart;
  final double? bodyFatEnd;
  final double? chestStart;
  final double? chestEnd;
  final double? waistStart;
  final double? waistEnd;
  final double? armStart;
  final double? armEnd;
  final double? thighStart;
  final double? thighEnd;
  final double? hipsStart;
  final double? hipsEnd;
  final String? notes;

  const MeasurementChanges({
    required this.firstDate,
    required this.lastDate,
    this.startWeightKg,
    this.endWeightKg,
    this.bodyFatStart,
    this.bodyFatEnd,
    this.chestStart,
    this.chestEnd,
    this.waistStart,
    this.waistEnd,
    this.armStart,
    this.armEnd,
    this.thighStart,
    this.thighEnd,
    this.hipsStart,
    this.hipsEnd,
    this.notes,
  });

  /// A single snapshot in the month: values are shown but no deltas are
  /// computed (matching the "latest value only" rule).
  bool get isSingle => firstDate.isSameDay(lastDate);

  double? get weightDelta => isSingle ? null : _delta(startWeightKg, endWeightKg);
  double? get bodyFatDelta => isSingle ? null : _delta(bodyFatStart, bodyFatEnd);
  double? get chestDelta => isSingle ? null : _delta(chestStart, chestEnd);
  double? get waistDelta => isSingle ? null : _delta(waistStart, waistEnd);
  double? get armDelta => isSingle ? null : _delta(armStart, armEnd);
  double? get thighDelta => isSingle ? null : _delta(thighStart, thighEnd);
  double? get hipsDelta => isSingle ? null : _delta(hipsStart, hipsEnd);

  static double? _delta(double? a, double? b) =>
      (a == null || b == null) ? null : b - a;
}

/// The complete monthly report for one calendar month.
class MonthlyReport {
  final int year;
  final int month;

  // Overview
  final int workouts;
  final int completedSets;
  final int totalReps;
  final double volume;
  final int totalDurationMinutes;
  final int avgDurationMinutes;
  final double? latestWeightKg;
  final int longestStreakInMonth;
  final int currentStreakDays;
  final int bestStreakDays;

  // Comparison vs previous month (null deltas when the previous month has no
  // data for that figure).
  final int previousWorkouts;
  final int previousCompletedSets;
  final int previousTotalReps;
  final double previousVolume;
  final int previousAvgDurationMinutes;
  final double? workoutsDeltaPercent;
  final double? completedSetsDeltaPercent;
  final double? totalRepsDeltaPercent;
  final double? volumeDeltaPercent;
  final double? avgDurationDeltaPercent;

  // Consistency
  final bool consistencyAvailable;
  final int consistencyScheduled;
  final int consistencyCompleted;
  final double? consistencyPercent;

  // Weekly charts
  final List<ProgressBucket> volumeBuckets;
  final List<ProgressBucket> frequencyBuckets;

  // RPE
  final double? avgRpe;
  final int rpeSetCount;

  // Exercises
  final List<ExerciseMonthBest> exercises;

  // Program
  final MonthlyProgramStats? program;

  // Measurements
  final MeasurementChanges? measurements;

  const MonthlyReport({
    required this.year,
    required this.month,
    this.workouts = 0,
    this.completedSets = 0,
    this.totalReps = 0,
    this.volume = 0,
    this.totalDurationMinutes = 0,
    this.avgDurationMinutes = 0,
    this.latestWeightKg,
    this.longestStreakInMonth = 0,
    this.currentStreakDays = 0,
    this.bestStreakDays = 0,
    this.previousWorkouts = 0,
    this.previousCompletedSets = 0,
    this.previousTotalReps = 0,
    this.previousVolume = 0,
    this.previousAvgDurationMinutes = 0,
    this.workoutsDeltaPercent,
    this.completedSetsDeltaPercent,
    this.totalRepsDeltaPercent,
    this.volumeDeltaPercent,
    this.avgDurationDeltaPercent,
    this.consistencyAvailable = false,
    this.consistencyScheduled = 0,
    this.consistencyCompleted = 0,
    this.consistencyPercent,
    this.volumeBuckets = const [],
    this.frequencyBuckets = const [],
    this.avgRpe,
    this.rpeSetCount = 0,
    this.exercises = const [],
    this.program,
    this.measurements,
  });

  bool get isEmpty => workouts == 0;

  bool get hasPreviousMonthData => previousWorkouts > 0;
}

/// Builds the complete deterministic monthly report from plain inputs.
/// Every figure is derived from real records — nothing is fabricated and no
/// future data is ever pulled in.
MonthlyReport buildMonthlyReport(MonthlyReportInputs inputs) {
  final monthWorkouts = _aggregateSessions(inputs.monthSessions);
  final previous = _aggregateSessions(inputs.previousMonthSessions);

  // Comparison deltas are only produced when the previous month actually has
  // data; otherwise the UI shows "No previous-month data".
  final hasPrevious = previous.workouts > 0;
  final year = inputs.year;
  final month = inputs.month;

  return MonthlyReport(
    year: year,
    month: month,
    workouts: monthWorkouts.workouts,
    completedSets: monthWorkouts.sets,
    totalReps: monthWorkouts.reps,
    volume: monthWorkouts.volume,
    totalDurationMinutes: monthWorkouts.duration,
    avgDurationMinutes: monthWorkouts.avgDuration,
    latestWeightKg: inputs.latestRecentMeasurement?.weightKg,
    longestStreakInMonth: _longestStreakInMonth(inputs.monthSessions),
    currentStreakDays: inputs.currentStreak.current,
    bestStreakDays: inputs.currentStreak.best,
    previousWorkouts: previous.workouts,
    previousCompletedSets: previous.sets,
    previousTotalReps: previous.reps,
    previousVolume: previous.volume,
    previousAvgDurationMinutes: previous.avgDuration,
    workoutsDeltaPercent: hasPrevious
        ? _deltaPercent(monthWorkouts.workouts, previous.workouts)
        : null,
    completedSetsDeltaPercent: hasPrevious
        ? _deltaPercent(monthWorkouts.sets, previous.sets)
        : null,
    totalRepsDeltaPercent: hasPrevious
        ? _deltaPercent(monthWorkouts.reps, previous.reps)
        : null,
    volumeDeltaPercent: hasPrevious
        ? _deltaPercent(monthWorkouts.volume, previous.volume)
        : null,
    avgDurationDeltaPercent: hasPrevious
        ? _deltaPercent(monthWorkouts.avgDuration.toDouble(),
            previous.avgDuration.toDouble())
        : null,
    consistencyAvailable:
        inputs.program != null && inputs.program!.scheduledDates.isNotEmpty,
    consistencyScheduled: inputs.program?.scheduledDates.length ?? 0,
    consistencyCompleted: monthWorkouts.workouts,
    consistencyPercent: inputs.program != null &&
            inputs.program!.scheduledDates.isNotEmpty
        ? (monthWorkouts.workouts / inputs.program!.scheduledDates.length)
            .clamp(0.0, 1.0)
        : null,
    volumeBuckets: _weeklyBuckets(inputs, (s) => s.volume),
    frequencyBuckets: _weeklyBuckets(inputs, (s) => 1),
    avgRpe: _averageRpe(inputs.monthSessions).value,
    rpeSetCount: _averageRpe(inputs.monthSessions).count,
    exercises: _exerciseMonthBests(inputs.exercises),
    program: inputs.program == null
        ? null
        : MonthlyProgramStats(
            programId: inputs.program!.programId,
            name: inputs.program!.name,
            goal: inputs.program!.goal,
            durationWeeks: inputs.program!.durationWeeks,
            scheduledWorkouts: inputs.program!.scheduledDates.length,
            completedWorkouts: inputs.program!.programSessions.length,
          ),
    measurements: _measurementChanges(inputs.monthMeasurements),
  );
}

// ---------------------------------------------------------------- helpers

class _SessionTotals {
  final int workouts;
  final int sets;
  final int reps;
  final double volume;
  final int duration;
  final int avgDuration;

  const _SessionTotals({
    required this.workouts,
    required this.sets,
    required this.reps,
    required this.volume,
    required this.duration,
    required this.avgDuration,
  });
}

_SessionTotals _aggregateSessions(List<MonthlySession> sessions) {
  var sets = 0;
  var reps = 0;
  var volume = 0.0;
  var duration = 0;
  for (final s in sessions) {
    sets += s.completedSets;
    reps += s.totalReps;
    volume += s.volume;
    duration += s.durationMinutes;
  }
  return _SessionTotals(
    workouts: sessions.length,
    sets: sets,
    reps: reps,
    volume: volume,
    duration: duration,
    avgDuration: sessions.isEmpty ? 0 : (duration / sessions.length).round(),
  );
}

/// Best consecutive-day run of completed workouts inside the month (rest days
/// are simply not workout days, matching the app-wide streak definition).
int _longestStreakInMonth(List<MonthlySession> sessions) {
  final dates = sessions.map((s) => s.date.dateOnly).toSet().toList()..sort();
  if (dates.isEmpty) return 0;
  var best = 1;
  var current = 1;
  for (var i = 1; i < dates.length; i++) {
    if (dates[i].difference(dates[i - 1]).inDays == 1) {
      current++;
      if (current > best) best = current;
    } else {
      current = 1;
    }
  }
  return best;
}

double? _deltaPercent(num current, num previous) {
  if (previous == 0) return null;
  return double.parse(
      (((current - previous) / previous) * 100).toStringAsFixed(1));
}

({double? value, int count}) _averageRpe(List<MonthlySession> sessions) {
  var sum = 0;
  var count = 0;
  for (final s in sessions) {
    for (final rpe in s.rpes) {
      sum += rpe;
      count++;
    }
  }
  if (count == 0) return (value: null, count: 0);
  return (
    value: double.parse((sum / count).toStringAsFixed(1)),
    count: count,
  );
}

/// Builds one bucket per week of the month that actually has data (leading or
/// trailing empty weeks are omitted rather than fabricated as zeros).
List<ProgressBucket> _weeklyBuckets(
  MonthlyReportInputs inputs,
  double Function(MonthlySession) valueOf,
) {
  final byDay = <DateTime, List<MonthlySession>>{};
  for (final s in inputs.monthSessions) {
    byDay.putIfAbsent(s.date.dateOnly, () => []).add(s);
  }
  final buckets = <ProgressBucket>[];
  var cursor = inputs.monthStart.startOfWeek;
  final last = inputs.monthEnd.endOfWeek;
  while (!cursor.isAfter(last)) {
    final weekEnd = cursor.add(const Duration(days: 6));
    var value = 0.0;
    var sessions = 0;
    for (var d = cursor; !d.isAfter(weekEnd); d = d.add(const Duration(days: 1))) {
      final daySessions = byDay[d.dateOnly];
      if (daySessions == null) continue;
      sessions += daySessions.length;
      for (final s in daySessions) {
        value += valueOf(s);
      }
    }
    if (sessions > 0) {
      buckets.add(ProgressBucket(
        start: cursor,
        label: '${cursor.day}/${cursor.month}',
        workouts: sessions,
        volume: value,
      ));
    }
    cursor = cursor.add(const Duration(days: 7));
  }
  return buckets;
}

List<ExerciseMonthBest> _exerciseMonthBests(List<ExerciseMonthData> data) {
  final result = <ExerciseMonthBest>[];
  for (final entry in data) {
    if (entry.inMonth.isEmpty) continue;
    final monthBest = _bestOf(entry.inMonth)!;
    final previous = _bestOf(entry.beforeMonth);
    final status = _status(monthBest, previous);
    result.add(ExerciseMonthBest(
      exerciseId: entry.exerciseId,
      exerciseName: entry.exerciseName,
      monthBestWeight: monthBest.weight,
      monthBestReps: monthBest.reps,
      monthVolume: entry.inMonth.fold<double>(
          0, (acc, s) => acc + s.weight * s.reps),
      monthSessions: entry.inMonth.length,
      previousBestWeight: previous?.weight,
      previousBestReps: previous?.reps,
      status: status,
    ));
  }
  result.sort((a, b) {
    final statusRank = _statusRank(a.status).compareTo(_statusRank(b.status));
    if (statusRank != 0) return statusRank;
    final byWeight = b.monthBestWeight.compareTo(a.monthBestWeight);
    if (byWeight != 0) return byWeight;
    return a.exerciseName.compareTo(b.exerciseName);
  });
  return result;
}

int _statusRank(ExerciseProgressionStatus status) {
  switch (status) {
    case ExerciseProgressionStatus.weightUp:
      return 0;
    case ExerciseProgressionStatus.repsUp:
      return 1;
    case ExerciseProgressionStatus.maintained:
      return 2;
    case ExerciseProgressionStatus.firstLiftThisMonth:
      return 3;
    case ExerciseProgressionStatus.belowPreviousBest:
      return 4;
  }
}

LiftSample? _bestOf(List<LiftSample> samples) {
  if (samples.isEmpty) return null;
  var best = samples.first;
  for (final s in samples.skip(1)) {
    if (s.weight > best.weight ||
        (s.weight == best.weight && s.reps > best.reps)) {
      best = s;
    }
  }
  return best;
}

ExerciseProgressionStatus _status(
  LiftSample monthBest,
  LiftSample? previous,
) {
  if (previous == null) return ExerciseProgressionStatus.firstLiftThisMonth;
  if (monthBest.weight > previous.weight) {
    return ExerciseProgressionStatus.weightUp;
  }
  if (monthBest.weight == previous.weight && monthBest.reps > previous.reps) {
    return ExerciseProgressionStatus.repsUp;
  }
  if (monthBest.weight == previous.weight &&
      monthBest.reps == previous.reps) {
    return ExerciseProgressionStatus.maintained;
  }
  return ExerciseProgressionStatus.belowPreviousBest;
}

MeasurementChanges? _measurementChanges(List<BodyMeasurement> measurements) {
  if (measurements.isEmpty) return null;
  final first = measurements.first;
  final last = measurements.last;
  return MeasurementChanges(
    firstDate: first.date,
    lastDate: last.date,
    startWeightKg: first.weightKg,
    endWeightKg: last.weightKg,
    bodyFatStart: first.bodyFat,
    bodyFatEnd: last.bodyFat,
    chestStart: first.chestCm,
    chestEnd: last.chestCm,
    waistStart: first.waistCm,
    waistEnd: last.waistCm,
    armStart: first.armCm,
    armEnd: last.armCm,
    thighStart: first.thighCm,
    thighEnd: last.thighCm,
    hipsStart: first.hipsCm,
    hipsEnd: last.hipsCm,
    notes: last.notes,
  );
}