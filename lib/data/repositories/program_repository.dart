import 'package:gym_flow/data/database/app_database.dart';
import 'package:gym_flow/models/exercise.dart';
import 'package:gym_flow/models/program.dart';
import 'package:gym_flow/models/program_week.dart';
import 'package:gym_flow/models/workout_day.dart';
import 'package:gym_flow/models/workout_template.dart';
import 'package:uuid/uuid.dart';

/// A workout day enriched with its exercises (for the session UI).
class WorkoutDayWithExercises {
  final WorkoutDay day;
  final List<Exercise> exercises;

  const WorkoutDayWithExercises({required this.day, required this.exercises});
}

class ProgramRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  ProgramRepository(this._db);

  Future<List<Program>> listPrograms() async {
    final db = await _db.database;
    final rows = await db.query('programs', orderBy: 'created_at DESC');
    return rows.map(Program.fromMap).toList();
  }

  Future<Program?> getProgram(String id) async {
    final db = await _db.database;
    final rows = await db.query('programs', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Program.fromMap(rows.first);
  }

  Future<Program?> getActiveProgram() async {
    final db = await _db.database;
    final rows = await db.query(
      'programs',
      where: 'is_active = 1',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Program.fromMap(rows.first);
  }

  /// Creates a program with its weeks and weekly schedules (template or custom).
  Future<Program> createProgram({
    required String name,
    required int durationWeeks,
    required String goal,
    String? templateName,
    Map<int, String?>? schedule,
  }) async {
    final db = await _db.database;
    final programId = _uuid.v4();
    final now = DateTime.now();
    final program = Program(
      id: programId,
      name: name,
      durationWeeks: durationWeeks,
      goal: goal,
      templateName: templateName,
      isActive: false,
      createdAt: now,
    );

    final template = WorkoutTemplate.byId(templateName);
    final effectiveSchedule =
        schedule ?? Map<int, String?>.from(template.schedule);

    await db.transaction((txn) async {
      await txn.insert('programs', program.toMap());

      for (var week = 1; week <= durationWeeks; week++) {
        final weekId = _uuid.v4();
        await txn.insert(
          'program_weeks',
          ProgramWeek(
            id: weekId,
            programId: programId,
            weekNumber: week,
            monthNumber: ProgramWeek.monthFor(week),
            name: ProgramWeek.defaultName(week),
          ).toMap(),
        );

        for (var day = 1; day <= 7; day++) {
          final title = effectiveSchedule[day];
          final isRest = title == null || title.trim().isEmpty;
          await txn.insert(
            'workout_days',
            WorkoutDay(
              id: _uuid.v4(),
              programId: programId,
              weekId: weekId,
              dayOfWeek: day,
              title: isRest ? 'Rest' : title,
              isRest: isRest,
            ).toMap(),
          );
        }
      }
    });
    return program;
  }

  Future<void> updateProgram(Program program) async {
    final db = await _db.database;
    await db.update('programs', program.toMap(),
        where: 'id = ?', whereArgs: [program.id]);
  }

  /// Sets the given program active and deactivates the others.
  Future<void> setActive(String programId) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.update('programs', {'is_active': 0});
      await txn.update('programs', {'is_active': 1},
          where: 'id = ?', whereArgs: [programId]);
    });
  }

  Future<void> deleteProgram(String programId) async {
    final db = await _db.database;
    await db
        .delete('programs', where: 'id = ?', whereArgs: [programId]);
  }

  Future<List<ProgramWeek>> getWeeks(String programId) async {
    final db = await _db.database;
    final rows = await db.query(
      'program_weeks',
      where: 'program_id = ?',
      whereArgs: [programId],
      orderBy: 'week_number',
    );
    return rows.map(ProgramWeek.fromMap).toList();
  }

  Future<List<WorkoutDay>> getDaysForWeek(String weekId) async {
    final db = await _db.database;
    final rows = await db.query(
      'workout_days',
      where: 'week_id = ?',
      whereArgs: [weekId],
      orderBy: 'day_of_week',
    );
    return rows.map(WorkoutDay.fromMap).toList();
  }

  Future<List<WorkoutDayWithExercises>> getWeekWithExercises(
      String weekId) async {
    final days = await getDaysForWeek(weekId);
    final result = <WorkoutDayWithExercises>[];
    for (final day in days) {
      result.add(WorkoutDayWithExercises(
        day: day,
        exercises: await getExercisesForDay(day.id),
      ));
    }
    return result;
  }

  /// Updates a single day record in place.
  Future<void> updateDay(WorkoutDay day) async {
    final db = await _db.database;
    await db.update('workout_days', day.toMap(),
        where: 'id = ?', whereArgs: [day.id]);
  }

  /// Replaces the schedule of one week. Days are (re)created with stable ids
  /// so existing session references remain valid.
  Future<void> updateWeekSchedule(
    String programId,
    String weekId,
    List<WorkoutDay> days,
  ) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.delete('workout_days',
          where: 'week_id = ?', whereArgs: [weekId]);
      for (final day in days) {
        await txn.insert('workout_days', day.toMap());
      }
    });
  }

  /// Copies the schedule of one week to all other weeks in the program.
  Future<void> copyWeekToAll(String programId, String sourceWeekId) async {
    final source = await getDaysForWeek(sourceWeekId);
    final db = await _db.database;
    final weeks = await getWeeks(programId);
    await db.transaction((txn) async {
      for (final week in weeks) {
        if (week.id == sourceWeekId) continue;
        await txn
            .delete('workout_days', where: 'week_id = ?', whereArgs: [week.id]);
        for (final day in source) {
          await txn.insert('workout_days', day.copyWith(id: _uuid.v4(), weekId: week.id).toMap());
        }
      }
    });
  }

  Future<List<Exercise>> getExercisesForDay(String dayId) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT e.* FROM exercises e
      INNER JOIN workout_day_exercises wde ON wde.exercise_id = e.id
      WHERE wde.workout_day_id = ?
      ORDER BY wde.order_index
    ''', [dayId]);
    return rows.map(Exercise.fromMap).toList();
  }

  Future<List<ProgramDayExercise>> getDayExerciseMappings(String dayId) async {
    final db = await _db.database;
    final rows = await db.query(
      'workout_day_exercises',
      where: 'workout_day_id = ?',
      whereArgs: [dayId],
      orderBy: 'order_index',
    );
    return rows.map(ProgramDayExercise.fromMap).toList();
  }

  Future<void> addExercisesToDay(
      String dayId, List<String> exerciseIds) async {
    final db = await _db.database;
    final existing = await getDayExerciseMappings(dayId);
    var nextOrder = existing.isEmpty ? 0 : existing.last.orderIndex + 1;
    await db.transaction((txn) async {
      for (final exerciseId in exerciseIds) {
        final alreadyAdded =
            existing.any((m) => m.exerciseId == exerciseId);
        if (alreadyAdded) continue;
        await txn.insert(
          'workout_day_exercises',
          ProgramDayExercise(
            id: _uuid.v4(),
            workoutDayId: dayId,
            exerciseId: exerciseId,
            orderIndex: nextOrder++,
          ).toMap(),
        );
      }
    });
  }

  Future<void> removeExerciseFromDay(String dayId, String exerciseId) async {
    final db = await _db.database;
    await db.delete(
      'workout_day_exercises',
      where: 'workout_day_id = ? AND exercise_id = ?',
      whereArgs: [dayId, exerciseId],
    );
  }

  /// Updates the target configuration (sets/reps/starting weight/notes) of an
  /// exercise within a workout day.
  Future<void> updateExerciseConfig(ProgramDayExercise config) async {
    final db = await _db.database;
    await db.update(
      'workout_day_exercises',
      config.toMap(),
      where: 'id = ?',
      whereArgs: [config.id],
    );
  }

  /// Mappings for an exercise across every day it appears in.
  Future<List<ProgramDayExercise>> getDayExerciseMappingsForExercise(
      String exerciseId) async {
    final db = await _db.database;
    final rows = await db.query(
      'workout_day_exercises',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      orderBy: 'order_index',
    );
    return rows.map(ProgramDayExercise.fromMap).toList();
  }

  /// Number of completed sessions belonging to any day of the given week.
  Future<int> countCompletedForWeek(String weekId) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT COUNT(*) AS count FROM workout_sessions s
      INNER JOIN workout_days wd ON wd.id = s.workout_day_id
      WHERE wd.week_id = ? AND s.status = ?
    ''', [weekId, 'completed']);
    if (rows.isEmpty) return 0;
    return (rows.first['count'] as num?)?.toInt() ?? 0;
  }

  /// Week index of the program the user is currently on, based on the
  /// program creation date. Clamped between 1 and duration.
  Future<ProgramWeek> getCurrentWeek(Program program) async {
    final weeks = await getWeeks(program.id);
    if (weeks.isEmpty) throw Exception('Program has no weeks');
    final elapsed =
        DateTime.now().difference(program.createdAt).inDays;
    final index = (elapsed ~/ 7);
    final weekNumber = (index + 1).clamp(1, program.durationWeeks);
    return weeks.firstWhere(
      (w) => w.weekNumber == weekNumber,
      orElse: () => weeks.first,
    );
  }

  Future<WorkoutDay?> getTodayWorkout(Program program) async {
    final week = await getCurrentWeek(program);
    final days = await getDaysForWeek(week.id);
    final today = DateTime.now().weekday;
    for (final day in days) {
      if (day.dayOfWeek == today) return day;
    }
    return null;
  }

  /// Number of non-rest workout days in a given month (sum of its weeks).
  Future<int> getMonthlyTarget(Program program, int monthNumber) async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) AS count FROM workout_days wd
      INNER JOIN program_weeks pw ON pw.id = wd.week_id
      WHERE pw.program_id = ? AND pw.month_number = ? AND wd.is_rest = 0
    ''', [program.id, monthNumber]);
    if (result.isEmpty) return 0;
    return (result.first['count'] as num?)?.toInt() ?? 0;
  }

  /// Calendar dates of non-rest workout days inside [program] that fall in the
  /// inclusive [from]..[to] range, anchored deterministically to the program's
  /// creation date (week 1 starts on that day). Days before the creation date
  /// are never counted, so a program started mid-month only contributes the
  /// days it actually ran.
  Future<List<DateTime>> scheduledDates(
    Program program,
    DateTime from,
    DateTime to,
  ) async {
    final anchor = DateTime(
        program.createdAt.year, program.createdAt.month, program.createdAt.day);
    final result = <DateTime>[];
    final weeks = await getWeeks(program.id);
    for (final week in weeks) {
      final weekOffset = (week.weekNumber - 1) * 7;
      final days = await getDaysForWeek(week.id);
      for (final day in days) {
        if (day.isRest) continue;
        final date = anchor.add(Duration(
          days: weekOffset + (day.dayOfWeek - anchor.weekday),
        ));
        if (date.isBefore(from) || date.isAfter(to)) continue;
        result.add(DateTime(date.year, date.month, date.day));
      }
    }
    result.sort();
    return result;
  }

  /// Weekly workout target from the active week schedule.
  Future<int?> getWeeklyTarget(Program program) async {
    final week = await getCurrentWeek(program);
    final days = await getDaysForWeek(week.id);
    return days.where((d) => !d.isRest).length;
  }
}