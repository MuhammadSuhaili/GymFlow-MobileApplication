import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_flow/data/repositories/exercise_repository.dart';
import 'package:gym_flow/data/repositories/program_repository.dart';
import 'package:gym_flow/data/repositories/user_repository.dart';
import 'package:gym_flow/data/repositories/workout_repository.dart';
import 'package:gym_flow/models/exercise.dart';
import 'package:gym_flow/models/program.dart';
import 'package:gym_flow/models/program_week.dart';
import 'package:gym_flow/models/user.dart';
import 'package:gym_flow/models/workout_day.dart';
import 'package:gym_flow/providers/app_providers.dart';
import 'package:gym_flow/services/progression_service.dart';

final userProvider = FutureProvider<User>((ref) async {
  ref.watch(refreshTriggerProvider);
  return ref.watch(userRepositoryProvider).getUser();
});

final programsProvider = FutureProvider<List<Program>>((ref) async {
  ref.watch(refreshTriggerProvider);
  return ref.watch(programRepositoryProvider).listPrograms();
});

final activeProgramProvider = FutureProvider<Program?>((ref) async {
  ref.watch(refreshTriggerProvider);
  return ref.watch(programRepositoryProvider).getActiveProgram();
});

final programByIdProvider = FutureProvider.family<Program?, String>((ref, id) async {
  ref.watch(refreshTriggerProvider);
  return ref.watch(programRepositoryProvider).getProgram(id);
});

/// Current (active) week inside a program.
final currentWeekProvider =
    FutureProvider.family<ProgramWeek, Program>((ref, program) async {
  return ref.watch(programRepositoryProvider).getCurrentWeek(program);
});

final programWeeksProvider =
    FutureProvider.family<List<ProgramWeek>, String>((ref, programId) async {
  ref.watch(refreshTriggerProvider);
  return ref.watch(programRepositoryProvider).getWeeks(programId);
});

final weekDaysProvider =
    FutureProvider.family<List<WorkoutDay>, String>((ref, weekId) async {
  ref.watch(refreshTriggerProvider);
  return ref.watch(programRepositoryProvider).getDaysForWeek(weekId);
});

final dayExercisesProvider =
    FutureProvider.family<List<Exercise>, String>((ref, dayId) async {
  ref.watch(refreshTriggerProvider);
  return ref.watch(programRepositoryProvider).getExercisesForDay(dayId);
});

/// Target configuration (sets / rep range) of each exercise on a workout day.
final dayExerciseConfigsProvider =
    FutureProvider.family<List<ProgramDayExercise>, String>((ref, dayId) async {
  ref.watch(refreshTriggerProvider);
  return ref.watch(programRepositoryProvider).getDayExerciseMappings(dayId);
});

/// Every target configuration across all program days for an exercise.
final exerciseConfigsProvider =
    FutureProvider.family<List<ProgramDayExercise>, String>(
        (ref, exerciseId) async {
  ref.watch(refreshTriggerProvider);
  return ref
      .watch(programRepositoryProvider)
      .getDayExerciseMappingsForExercise(exerciseId);
});

/// Today's scheduled workout for the active program.
final todayWorkoutProvider = FutureProvider<ProgramWorkoutDay?>((ref) async {
  ref.watch(refreshTriggerProvider);
  final program = await ref.watch(activeProgramProvider.future);
  if (program == null) return null;
  final day = await ref
      .watch(programRepositoryProvider)
      .getTodayWorkout(program);
  if (day == null) return null;
  final exercises =
      await ref.watch(programRepositoryProvider).getExercisesForDay(day.id);
  return ProgramWorkoutDay(program: program, day: day, exercises: exercises);
});

class ProgramWorkoutDay {
  final Program program;
  final WorkoutDay day;
  final List<Exercise> exercises;

  const ProgramWorkoutDay({
    required this.program,
    required this.day,
    required this.exercises,
  });
}

final exercisesProvider =
    FutureProvider.family<List<Exercise>, String?>((ref, muscle) async {
  ref.watch(refreshTriggerProvider);
  return ref.watch(exerciseRepositoryProvider).getAll(muscleGroup: muscle);
});

final exerciseByIdProvider =
    FutureProvider.family<Exercise?, String>((ref, id) async {
  return ref.watch(exerciseRepositoryProvider).getById(id);
});

final weeklyTargetProvider = FutureProvider<int?>((ref) async {
  final program = await ref.watch(activeProgramProvider.future);
  if (program == null) return null;
  return ref.watch(programRepositoryProvider).getWeeklyTarget(program);
});

final weeklyProgressProvider = FutureProvider<(int, int)>((ref) async {
  final target = await ref.watch(weeklyTargetProvider.future);
  if (target == null) return (0, 0);
  return ref.watch(workoutRepositoryProvider).weeklyProgress(target);
});

// ---- Optional progressive-overload data (Phase 4A) ----

/// One exercise of today's workout enriched with previous performance and a
/// non-binding next-session suggestion — used by the Home "Next Workout" card.
class NextWorkoutItem {
  final Exercise exercise;
  final DateTime? previousDate;
  final int? previousBestReps;
  final double? previousBestWeight;
  final ProgressionSuggestion? suggestion;

  const NextWorkoutItem({
    required this.exercise,
    this.previousDate,
    this.previousBestReps,
    this.previousBestWeight,
    this.suggestion,
  });

  bool get hasSuggestion =>
      suggestion != null && suggestion!.outcome != ProgressionOutcome.noPreviousData;
}

/// Exercises for today's scheduled workout, each with previous performance and
/// (when a rep range is configured) a progression suggestion.
final nextWorkoutProvider = FutureProvider<List<NextWorkoutItem>>((ref) async {
  ref.watch(refreshTriggerProvider);
  final today = await ref.watch(todayWorkoutProvider.future);
  if (today == null) return const [];
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  final dayConfigs =
      await ref.watch(programRepositoryProvider).getDayExerciseMappings(today.day.id);

  final items = <NextWorkoutItem>[];
  for (final exercise in today.exercises) {
    final performance = await workoutRepo.lastPerformance(exercise.id);
    final best = performance == null ? null : bestSet(performance.sets);
    ProgramDayExercise? config;
    for (final c in dayConfigs) {
      if (c.exerciseId == exercise.id) {
        config = c;
        break;
      }
    }
    final suggestion = performance == null
        ? null
        : suggest(
            previousSets: performance.sets,
            targetSets: config?.targetSets,
            minReps: config?.minReps,
            maxReps: config?.maxReps,
          );
    items.add(NextWorkoutItem(
      exercise: exercise,
      previousDate: performance?.date,
      previousBestReps: best?.reps,
      previousBestWeight: best?.weight,
      suggestion: suggestion,
    ));
  }
  return items;
});

/// Per-exercise progression availability for the current program week.
class ExerciseProgressionInfo {
  final String exerciseName;
  final int? previousBestReps;
  final double? previousBestWeight;

  const ExerciseProgressionInfo({
    required this.exerciseName,
    this.previousBestReps,
    this.previousBestWeight,
  });
}

/// Compact overview of an active program: week, today's workout, weekly
/// completion and which scheduled exercises already have previous data.
class ProgramIntelligence {
  final int currentWeekNumber;
  final int durationWeeks;
  final String todayTitle;
  final int completedThisWeek;
  final int weeklyTarget;
  final List<ExerciseProgressionInfo> exercisesWithProgress;

  const ProgramIntelligence({
    required this.currentWeekNumber,
    required this.durationWeeks,
    required this.todayTitle,
    required this.completedThisWeek,
    required this.weeklyTarget,
    required this.exercisesWithProgress,
  });

  int get remainingThisWeek => (weeklyTarget - completedThisWeek).clamp(0, weeklyTarget);
}

/// Program intelligence for the given program (current week, today's workout,
/// completed/remaining workouts this week, exercises with progression data).
final programIntelligenceProvider =
    FutureProvider.family<ProgramIntelligence, Program>((ref, program) async {
  ref.watch(refreshTriggerProvider);
  final programRepo = ref.watch(programRepositoryProvider);
  final workoutRepo = ref.watch(workoutRepositoryProvider);

  final week = await programRepo.getCurrentWeek(program);
  final days = await programRepo.getDaysForWeek(week.id);
  final completed = await programRepo.countCompletedForWeek(week.id);
  final target = days.where((d) => !d.isRest).length;

  final weekday = DateTime.now().weekday;
  WorkoutDay? todayDay;
  for (final d in days) {
    if (d.dayOfWeek == weekday) {
      todayDay = d;
      break;
    }
  }
  final todayTitle = todayDay == null
      ? 'No workout today'
      : todayDay.isRest
          ? 'Rest day'
          : todayDay.title;

  final scheduled = todayDay == null || todayDay.isRest
      ? const <Exercise>[]
      : await programRepo.getExercisesForDay(todayDay.id);

  final progress = <ExerciseProgressionInfo>[];
  for (final exercise in scheduled) {
    final performance = await workoutRepo.lastPerformance(exercise.id);
    if (performance == null) continue;
    final best = bestSet(performance.sets);
    progress.add(ExerciseProgressionInfo(
      exerciseName: exercise.name,
      previousBestReps: best?.reps,
      previousBestWeight: best?.weight,
    ));
  }

  return ProgramIntelligence(
    currentWeekNumber: week.weekNumber,
    durationWeeks: program.durationWeeks,
    todayTitle: todayTitle,
    completedThisWeek: completed,
    weeklyTarget: target,
    exercisesWithProgress: progress,
  );
});