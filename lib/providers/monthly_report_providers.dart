import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_flow/core/extensions/date_extensions.dart';
import 'package:gym_flow/data/repositories/workout_repository.dart';
import 'package:gym_flow/models/body_measurement.dart';
import 'package:gym_flow/providers/app_providers.dart';
import 'package:gym_flow/services/monthly_report_service.dart';

final monthlyReportProvider =
    FutureProvider.family<MonthlyReport, ({int year, int month})>(
        (ref, selection) async {
  ref.watch(refreshTriggerProvider);

  final monthStart = DateTime(selection.year, selection.month, 1);
  final monthEnd = DateTime(selection.year, selection.month + 1, 0);
  final prev = DateTime(selection.year, selection.month - 1, 1);
  final prevStart = DateTime(prev.year, prev.month, 1);
  final prevEnd = DateTime(prev.year, prev.month + 1, 0);

  final repo = ref.watch(workoutRepositoryProvider);
  final currentRows = await repo.sessionAggregates(monthStart, monthEnd);
  final previousRows = await repo.sessionAggregates(prevStart, prevEnd);
  final monthSessions = currentRows.map(_toSession).toList();
  final previousSessions = previousRows.map(_toSession).toList();

  // Measurements within the month (ascending), plus the most recent known
  // measurement at or before the end of the month.
  final allMeasurements =
      await ref.watch(measurementRepositoryProvider).getAll();
  final monthMeasurements = allMeasurements
      .where((m) => !m.date.isBefore(monthStart) && !m.date.isAfter(monthEnd))
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  BodyMeasurement? latestRecent;
  for (final m in allMeasurements) {
    if (m.date.isAfter(monthEnd)) continue;
    if (latestRecent == null || m.date.isAfter(latestRecent.date)) {
      latestRecent = m;
    }
  }

  final streak = await repo.getStreak();

  // Active program — only reported when it actually covered (part of) the
  // month; otherwise consistency and the program card are simply omitted.
  MonthlyProgramInput? programInput;
  final active = await ref.watch(programRepositoryProvider).getActiveProgram();
  if (active != null && !active.createdAt.dateOnly.isAfter(monthEnd)) {
    final scheduled =
        await ref.watch(programRepositoryProvider).scheduledDates(
              active,
              monthStart,
              monthEnd,
            );
    programInput = MonthlyProgramInput(
      programId: active.id,
      name: active.name,
      goal: active.goal,
      durationWeeks: active.durationWeeks,
      scheduledDates: scheduled,
      programSessions: monthSessions
          .where((s) => s.programId == active.id)
          .toList(),
    );
  }

  // Lift history per exercise, split into "this month" and "before".
  final exercises = <ExerciseMonthData>[];
  final practiced = await repo.exercisesPracticed();
  for (final item in practiced) {
    final points = await repo.strengthProgress(item.id);
    if (points.isEmpty) continue;
    final inMonth = <LiftSample>[];
    final before = <LiftSample>[];
    for (final p in points) {
      final sample =
          LiftSample(date: p.date.dateOnly, weight: p.weight, reps: p.reps);
      if (!p.date.isBefore(monthStart) && !p.date.isAfter(monthEnd)) {
        inMonth.add(sample);
      } else if (p.date.isBefore(monthStart)) {
        before.add(sample);
      }
    }
    if (inMonth.isEmpty) continue;
    exercises.add(ExerciseMonthData(
      exerciseId: item.id,
      exerciseName: item.name,
      inMonth: inMonth,
      beforeMonth: before,
    ));
  }

  return buildMonthlyReport(MonthlyReportInputs(
    year: selection.year,
    month: selection.month,
    monthSessions: monthSessions,
    previousMonthSessions: previousSessions,
    monthMeasurements: monthMeasurements,
    latestRecentMeasurement: latestRecent,
    currentStreak: streak,
    program: programInput,
    exercises: exercises,
  ));
});

MonthlySession _toSession(SessionAggregate row) => MonthlySession(
      date: row.date.dateOnly,
      completedSets: row.completedSets,
      totalReps: row.totalReps,
      volume: row.volume,
      durationMinutes: row.durationMinutes,
      programId: row.programId,
      rpes: row.rpes,
    );