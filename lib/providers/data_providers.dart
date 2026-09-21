import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_flow/core/extensions/date_extensions.dart';
import 'package:gym_flow/data/repositories/checkin_repository.dart';
import 'package:gym_flow/data/repositories/workout_repository.dart';
import 'package:gym_flow/models/body_measurement.dart';
import 'package:gym_flow/models/daily_check_in.dart';
import 'package:gym_flow/models/progress_models.dart';
import 'package:gym_flow/models/workout_session.dart';
import 'package:gym_flow/models/workout_set.dart';
import 'package:gym_flow/providers/app_providers.dart';
import 'package:gym_flow/providers/program_providers.dart';

/// Check-in for a specific date (null when none).
final checkinByDateProvider =
    FutureProvider.family<DailyCheckIn?, DateTime>((ref, date) async {
  ref.watch(refreshTriggerProvider);
  return ref.watch(checkinRepositoryProvider).getByDate(date);
});

final todayCheckinProvider = FutureProvider<DailyCheckIn?>((ref) {
  return ref.watch(checkinByDateProvider(DateTime.now()).future);
});

final checkedInTodayProvider = FutureProvider<bool>((ref) async {
  final checkin = await ref.watch(todayCheckinProvider.future);
  return checkin != null;
});

final checkinsFilteredProvider =
    FutureProvider.family<List<DailyCheckIn>, CheckInFilter>(
        (ref, filter) async {
  ref.watch(refreshTriggerProvider);
  return ref.watch(checkinRepositoryProvider).applyFilter(filter, null);
});

final checkinsCustomProvider =
    FutureProvider.family<List<DailyCheckIn>, DateTimeRange?>(
        (ref, range) async {
  ref.watch(refreshTriggerProvider);
  if (range == null) return const [];
  return ref.watch(checkinRepositoryProvider).getBetween(
        range.start.dateOnlyWith,
        range.end.dateOnlyWith,
      );
});

extension on DateTime {
  DateTime get dateOnlyWith => DateTime(year, month, day);
}

// ---- Workouts ----

final workoutHistoryProvider = FutureProvider<List<WorkoutSession>>((ref) async {
  ref.watch(refreshTriggerProvider);
  return ref.watch(workoutRepositoryProvider).getHistory();
});

/// History with per-session set counts used by the history screen.
final workoutHistoryDetailedProvider =
    FutureProvider<List<WorkoutHistoryItem>>((ref) async {
  ref.watch(refreshTriggerProvider);
  return ref.watch(workoutRepositoryProvider).getHistoryWithStats();
});

final completedTodayProvider = FutureProvider<WorkoutSession?>((ref) async {
  ref.watch(refreshTriggerProvider);
  return ref.watch(workoutRepositoryProvider).completedOn(DateTime.now());
});

final sessionByIdProvider =
    FutureProvider.family<WorkoutSession?, String>((ref, id) async {
  return ref.watch(workoutRepositoryProvider).getSession(id);
});

final setsBySessionProvider =
    FutureProvider.family<List<WorkoutSet>, String>((ref, sessionId) async {
  return ref.watch(workoutRepositoryProvider).getSetsForSession(sessionId);
});

final streakProvider = FutureProvider<({int current, int best})>((ref) async {
  ref.watch(refreshTriggerProvider);
  return ref.watch(workoutRepositoryProvider).getStreak();
});

// ---- Measurements ----

final measurementsProvider =
    FutureProvider<List<BodyMeasurement>>((ref) async {
  ref.watch(refreshTriggerProvider);
  return ref.watch(measurementRepositoryProvider).getAll();
});

final latestMeasurementProvider = FutureProvider<BodyMeasurement?>((ref) async {
  ref.watch(refreshTriggerProvider);
  return ref.watch(measurementRepositoryProvider).latest();
});

// ---- Charts ----

final weeklyVolumeProvider =
    FutureProvider<List<WeeklyVolumePoint>>((ref) async {
  ref.watch(refreshTriggerProvider);
  return ref.watch(workoutRepositoryProvider).weeklyVolume(8);
});

final strengthProgressProvider =
    FutureProvider.family<List<StrengthPoint>, String>(
        (ref, exerciseId) async {
  ref.watch(refreshTriggerProvider);
  return ref.watch(workoutRepositoryProvider).strengthProgress(exerciseId);
});

final performanceProvider =
    FutureProvider.family<(StrengthPoint?, StrengthPoint?), String>(
        (ref, exerciseId) async {
  ref.watch(refreshTriggerProvider);
  return ref.watch(workoutRepositoryProvider).performanceFor(exerciseId);
});

/// Sets from the most recent session that included this exercise — shown as
/// a reference (never applied automatically).
final lastSetsForExerciseProvider =
    FutureProvider.family<List<WorkoutSet>, String>((ref, exerciseId) async {
  ref.watch(refreshTriggerProvider);
  return ref.watch(workoutRepositoryProvider).lastSetsForExercise(exerciseId);
});

/// Most recent completed session for an exercise (date + sets), or null when
/// the exercise has never been completed.
final lastPerformanceProvider =
    FutureProvider.family<({DateTime date, List<WorkoutSet> sets})?, String>(
        (ref, exerciseId) async {
  ref.watch(refreshTriggerProvider);
  return ref.watch(workoutRepositoryProvider).lastPerformance(exerciseId);
});

// ---- Progress & analytics ----

/// Exercises with at least one completed set — real picker data.
final exercisesPracticedProvider =
    FutureProvider<List<({String id, String name})>>((ref) async {
  ref.watch(refreshTriggerProvider);
  return ref.watch(workoutRepositoryProvider).exercisesPracticed();
});

/// Aggregated workout statistics + chart buckets for a time range.
final progressOverviewProvider =
    FutureProvider.family<ProgressOverview, TimeRange>((ref, range) async {
  ref.watch(refreshTriggerProvider);
  final all = await ref
      .watch(workoutRepositoryProvider)
      .getHistoryWithStats(limit: 2000);
  final start = range.start(DateTime.now());
  final items = all
      .where((i) => !i.session.date.dateOnly.isBefore(start))
      .toList()
    ..sort((a, b) => a.session.date.compareTo(b.session.date));

  var sets = 0;
  var reps = 0;
  var volume = 0.0;
  var duration = 0;
  for (final item in items) {
    sets += item.completedSets;
    reps += item.totalReps;
    volume += item.session.totalVolumeKg;
    duration += item.session.durationMinutes;
  }

  return ProgressOverview(
    workouts: items.length,
    completedSets: sets,
    totalReps: reps,
    volume: volume,
    avgDurationMinutes: items.isEmpty ? 0 : (duration / items.length).round(),
    earliest: items.isEmpty ? null : items.first.session.date,
    buckets: _buildBuckets(items, range),
  );
});

/// Completed workouts + volume for the current calendar week (for Home).
final thisWeekStatsProvider =
    FutureProvider<({int workouts, double volume})>((ref) async {
  ref.watch(refreshTriggerProvider);
  final now = DateTime.now();
  final start = now.startOfWeek;
  final end = start.add(const Duration(days: 6));
  final repo = ref.watch(workoutRepositoryProvider);
  return (
    workouts: await repo.countCompletedBetween(start, end),
    volume: await repo.totalVolumeBetween(start, end),
  );
});

/// Per-session aggregates for an exercise (weight/reps/volume over time).
final exerciseSessionsProvider =
    FutureProvider.family<List<ExerciseSessionPoint>, String>(
        (ref, exerciseRefId) async {
  ref.watch(refreshTriggerProvider);
  return ref.watch(workoutRepositoryProvider).exerciseSessions(exerciseRefId);
});

/// Splits workout history into day (range <= 31 days) or week buckets.
List<ProgressBucket> _buildBuckets(
  List<WorkoutHistoryItem> items,
  TimeRange range,
) {
  if (items.isEmpty) {
    return range.isDaily
        ? _dailyBuckets(range.start(DateTime.now()), DateTime.now(), {})
        : const [];
  }
  final source = range.isAllTime
      ? items.first.session.date.dateOnly
      : range.start(DateTime.now());
  final today = DateTime.now().dateOnly;
  final byDay = <DateTime, List<WorkoutHistoryItem>>{};
  for (final item in items) {
    byDay.putIfAbsent(item.session.date.dateOnly, () => []).add(item);
  }

  if (range.isDaily) {
    return _dailyBuckets(source, today, byDay);
  }

  final buckets = <ProgressBucket>[];
  var cursor = source.startOfWeek;
  final last = today.startOfWeek;
  while (!cursor.isAfter(last)) {
    final weekEnd = cursor.add(const Duration(days: 6));
    var workouts = 0;
    var volume = 0.0;
    for (var d = cursor; !d.isAfter(weekEnd); d = d.add(const Duration(days: 1))) {
      final dayItems = byDay[d.dateOnly];
      if (dayItems == null) continue;
      for (final item in dayItems) {
        workouts++;
        volume += item.session.totalVolumeKg;
      }
    }
    buckets.add(ProgressBucket(
      start: cursor,
      label: '${cursor.day}/${cursor.month}',
      workouts: workouts,
      volume: volume,
    ));
    cursor = cursor.add(const Duration(days: 7));
  }
  return buckets;
}

List<ProgressBucket> _dailyBuckets(
  DateTime start,
  DateTime today,
  Map<DateTime, List<WorkoutHistoryItem>> byDay,
) {
  final buckets = <ProgressBucket>[];
  for (var d = start; !d.isAfter(today); d = d.add(const Duration(days: 1))) {
    final items = byDay[d.dateOnly] ?? const [];
    buckets.add(ProgressBucket(
      start: d,
      label: '${d.day}/${d.month}',
      workouts: items.length,
      volume: items.fold<double>(
          0, (acc, item) => acc + item.session.totalVolumeKg),
    ));
  }
  return buckets;
}

final consistencyProvider = FutureProvider<List<(DateTime, int, int)>>(
    (ref) async {
  ref.watch(refreshTriggerProvider);
  final target = await ref.watch(weeklyTargetProvider.future);
  return ref.watch(workoutRepositoryProvider).consistency(8, target ?? 5);
});

final monthlyStatsProvider =
    FutureProvider.family<MonthlyStats, (int, int)>(
        (ref, args) async {
  ref.watch(refreshTriggerProvider);
  return ref.watch(workoutRepositoryProvider).monthlyStats(args.$1, args.$2);
});