import 'package:gym_flow/core/extensions/date_extensions.dart';
import 'package:gym_flow/data/database/app_database.dart';
import 'package:gym_flow/models/workout_draft.dart';
import 'package:gym_flow/models/workout_session.dart';
import 'package:gym_flow/models/workout_set.dart';
import 'package:sqflite/sqflite.dart';

class MonthlyStats {
  final int workouts;
  final int daysScheduled;
  final double? avgEnergy;
  final double? avgSleepMinutes;
  final double? avgSoreness;
  final double totalVolume;
  final double? startWeight;
  final double? endWeight;

  const MonthlyStats({
    this.workouts = 0,
    this.daysScheduled = 0,
    this.avgEnergy,
    this.avgSleepMinutes,
    this.avgSoreness,
    this.totalVolume = 0,
    this.startWeight,
    this.endWeight,
  });
}

/// A completed session together with aggregated set stats.
class WorkoutHistoryItem {
  final WorkoutSession session;
  final int completedSets;
  final int totalReps;

  const WorkoutHistoryItem({
    required this.session,
    required this.completedSets,
    required this.totalReps,
  });
}

class WeeklyVolumePoint {
  final DateTime weekStart;
  final double volume;
  final int workouts;
  const WeeklyVolumePoint(this.weekStart, this.volume, this.workouts);
}

class StrengthPoint {
  final DateTime date;
  final double weight;
  final int reps;
  const StrengthPoint(this.date, this.weight, this.reps);
}

class ExerciseSessionPoint {
  final DateTime date;
  final String title;
  final int completedSets;
  final double bestWeight;
  final int bestReps;
  final double volume;
  const ExerciseSessionPoint({
    required this.date,
    required this.title,
    required this.completedSets,
    required this.bestWeight,
    required this.bestReps,
    required this.volume,
  });
}

/// Aggregated stats for one completed session within a date range.
class SessionAggregate {
  final DateTime date;
  final int completedSets;
  final int totalReps;
  final double volume;
  final int durationMinutes;
  final String? programId;
  final List<int> rpes;

  const SessionAggregate({
    required this.date,
    required this.completedSets,
    required this.totalReps,
    required this.volume,
    required this.durationMinutes,
    this.programId,
    this.rpes = const [],
  });
}

class WorkoutRepository {
  final AppDatabase _db;

  WorkoutRepository(this._db);

  Future<void> saveSession(
    WorkoutSession session,
    List<WorkoutSet> sets,
  ) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.insert('workout_sessions', session.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.delete('workout_sets',
          where: 'session_id = ?', whereArgs: [session.id]);
      for (final set in sets) {
        await txn.insert('workout_sets', set.toMap());
      }
    });
  }

  Future<void> updateSession(WorkoutSession session) async {
    final db = await _db.database;
    await db.update('workout_sessions', session.toMap(),
        where: 'id = ?', whereArgs: [session.id]);
  }

  Future<void> deleteSession(String sessionId) async {
    final db = await _db.database;
    await db.delete('workout_sessions',
        where: 'id = ?', whereArgs: [sessionId]);
  }

  Future<List<WorkoutSession>> getHistory({int limit = 500}) async {
    final db = await _db.database;
    final rows = await db.query(
      'workout_sessions',
      where: 'status = ?',
      whereArgs: ['completed'],
      orderBy: 'date DESC',
      limit: limit,
    );
    return rows.map(WorkoutSession.fromMap).toList();
  }

  Future<List<WorkoutSession>> getSessionsBetween(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _db.database;
    final rows = await db.query(
      'workout_sessions',
      where: "status = 'completed' AND date BETWEEN ? AND ?",
      whereArgs: [start.isoDate, end.isoDate],
      orderBy: 'date ASC',
    );
    return rows.map(WorkoutSession.fromMap).toList();
  }

  /// Aggregates per completed session in [start..end] (ascending): set count,
  /// total reps, stored volume, duration, program id and the RPE values of
  /// completed sets — used by the monthly report.
  Future<List<SessionAggregate>> sessionAggregates(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT
        s.id AS id,
        s.date,
        s.duration_minutes,
        s.total_volume_kg,
        s.program_id,
        SUM(CASE WHEN ws.completed = 1 THEN 1 ELSE 0 END) AS completed_sets,
        COALESCE(SUM(CASE WHEN ws.completed = 1 THEN ws.reps ELSE 0 END), 0) AS total_reps,
        GROUP_CONCAT(CASE WHEN ws.completed = 1 AND ws.rpe IS NOT NULL THEN ws.rpe END) AS rpe_list
      FROM workout_sessions s
      LEFT JOIN workout_sets ws ON ws.session_id = s.id
      WHERE s.status = 'completed' AND s.date BETWEEN ? AND ?
      GROUP BY s.id
      ORDER BY s.date ASC
    ''', [start.isoDate, end.isoDate]);
    return rows.map((r) {
      final rpeText = r['rpe_list'] as String?;
      return SessionAggregate(
        date: DateTime.parse(r['date'] as String),
        completedSets: (r['completed_sets'] as num?)?.toInt() ?? 0,
        totalReps: (r['total_reps'] as num?)?.toInt() ?? 0,
        volume: (r['total_volume_kg'] as num?)?.toDouble() ?? 0,
        durationMinutes: (r['duration_minutes'] as num?)?.toInt() ?? 0,
        programId: r['program_id'] as String?,
        rpes: rpeText == null || rpeText.isEmpty
            ? const []
            : rpeText
                .split(',')
                .where((v) => v.trim().isNotEmpty)
                .map((v) => int.tryParse(v.trim()))
                .whereType<int>()
                .toList(),
      );
    }).toList();
  }

  Future<WorkoutSession?> getSession(String id) async {
    final db = await _db.database;
    final rows =
        await db.query('workout_sessions', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return WorkoutSession.fromMap(rows.first);
  }

  Future<List<WorkoutSet>> getSetsForSession(String sessionId) async {
    final db = await _db.database;
    final rows = await db.query(
      'workout_sets',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'order_index',
    );
    return rows.map(WorkoutSet.fromMap).toList();
  }

  /// Completed sessions with per-session set counts and total reps.
  Future<List<WorkoutHistoryItem>> getHistoryWithStats({int limit = 500}) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT
        s.*,
        SUM(CASE WHEN ws.completed = 1 THEN 1 ELSE 0 END) AS completed_sets,
        COALESCE(SUM(CASE WHEN ws.completed = 1 THEN ws.reps ELSE 0 END), 0) AS total_reps
      FROM workout_sessions s
      LEFT JOIN workout_sets ws ON ws.session_id = s.id
      WHERE s.status = ?
      GROUP BY s.id
      ORDER BY s.date DESC
      LIMIT ?
    ''', ['completed', limit]);
    return rows.map((r) => WorkoutHistoryItem(
          session: WorkoutSession.fromMap(r),
          completedSets: (r['completed_sets'] as num?)?.toInt() ?? 0,
          totalReps: (r['total_reps'] as num?)?.toInt() ?? 0,
        )).toList();
  }

  /// Sets of the most recent completed session for an exercise — used as a
  /// reference during a new workout.
  Future<List<WorkoutSet>> lastSetsForExercise(String exerciseRefId) async {
    final performance = await lastPerformance(exerciseRefId);
    return performance?.sets ?? const [];
  }

  /// Most recent completed session for an exercise, with its date and sets.
  /// Returns null when the exercise has never been completed.
  Future<({DateTime date, List<WorkoutSet> sets})?> lastPerformance(
      String exerciseRefId) async {
    final db = await _db.database;
    final sessions = await db.rawQuery('''
      SELECT ws.session_id, s.date
      FROM workout_sets ws
      INNER JOIN workout_sessions s ON s.id = ws.session_id
      WHERE ws.exercise_ref_id = ? AND s.status = 'completed'
      ORDER BY s.date DESC
      LIMIT 1
    ''', [exerciseRefId]);
    if (sessions.isEmpty) return null;
    final sessionId = sessions.first['session_id'] as String;
    final date = DateTime.parse(sessions.first['date'] as String);
    final rows = await db.query(
      'workout_sets',
      where: 'session_id = ? AND exercise_ref_id = ?',
      whereArgs: [sessionId, exerciseRefId],
      orderBy: 'order_index',
    );
    final sets = rows.map(WorkoutSet.fromMap).toList();
    if (sets.isEmpty) return null;
    return (date: date, sets: sets);
  }

  // ---- Drafts ----

  Future<void> saveDraft(WorkoutDraft draft) async {
    final db = await _db.database;
    await db.insert('workout_drafts', draft.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<WorkoutDraft?> getDraftForDay(String workoutDayId) async {
    final db = await _db.database;
    final rows = await db.query(
      'workout_drafts',
      where: 'workout_day_id = ?',
      whereArgs: [workoutDayId],
      orderBy: 'started_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return WorkoutDraft.fromMap(rows.first);
  }

  Future<void> clearDraft(String id) async {
    final db = await _db.database;
    await db.delete('workout_drafts', where: 'id = ?', whereArgs: [id]);
  }

  Future<WorkoutSession?> completedOn(DateTime date) async {
    final db = await _db.database;
    final rows = await db.query(
      'workout_sessions',
      where: "status = 'completed' AND date = ?",
      whereArgs: [date.isoDate],
      orderBy: 'date DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return WorkoutSession.fromMap(rows.first);
  }

  Future<int> countCompletedBetween(DateTime start, DateTime end) async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) AS count FROM workout_sessions
      WHERE status = 'completed' AND date BETWEEN ? AND ?
    ''', [start.isoDate, end.isoDate]);
    return (result.first['count'] as num?)?.toInt() ?? 0;
  }

  Future<double> totalVolumeBetween(DateTime start, DateTime end) async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(total_volume_kg), 0) AS total FROM workout_sessions
      WHERE status = 'completed' AND date BETWEEN ? AND ?
    ''', [start.isoDate, end.isoDate]);
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<int> totalDurationBetween(DateTime start, DateTime end) async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(duration_minutes), 0) AS total FROM workout_sessions
      WHERE status = 'completed' AND date BETWEEN ? AND ?
    ''', [start.isoDate, end.isoDate]);
    return (result.first['total'] as num?)?.toInt() ?? 0;
  }

  /// Consecutive-day current streak and all-time best streak based purely on
  /// completed workouts (rest days are ignored).
  Future<({int current, int best})> getStreak() async {
    final sessions = await getHistory(limit: 2000);
    final dates = sessions.map((s) => s.date.dateOnly).toSet().toList()
      ..sort();
    if (dates.isEmpty) return (current: 0, best: 0);

    var best = 1;
    var current = 1;
    for (var i = 1; i < dates.length; i++) {
      final diff = dates[i].difference(dates[i - 1]).inDays;
      if (diff == 1) {
        current++;
        if (current > best) best = current;
      } else {
        current = 1;
      }
    }

    var currentStreak = 0;
    final today = DateTime.now().dateOnly;
    final yesterday = today.subtract(const Duration(days: 1));
    if (dates.contains(today) || dates.contains(yesterday)) {
      if (dates.contains(today)) currentStreak = 1;
      var cursor = dates.contains(today) ? today : yesterday;
      while (true) {
        final prev = cursor.subtract(const Duration(days: 1));
        if (dates.contains(prev)) {
          currentStreak++;
          cursor = prev;
        } else {
          break;
        }
      }
    }
    return (current: currentStreak, best: best);
  }

  /// Weekly target reach: returns (completed, target) for current week.
  Future<(int completed, int target)> weeklyProgress(int target) async {
    final weekStart = DateTime.now().startOfWeek;
    final completed = await countCompletedBetween(
        weekStart, weekStart.add(const Duration(days: 6)));
    return (completed, target);
  }

  /// Volume & workout counts per week for the last [weeks] weeks.
  Future<List<WeeklyVolumePoint>> weeklyVolume(int weeks) async {
    final now = DateTime.now();
    final points = <WeeklyVolumePoint>[];
    for (var i = weeks - 1; i >= 0; i--) {
      final weekStart =
          now.startOfWeek.subtract(Duration(days: i * 7));
      final volume = await totalVolumeBetween(
          weekStart, weekStart.add(const Duration(days: 6)));
      final workouts = await countCompletedBetween(
          weekStart, weekStart.add(const Duration(days: 6)));
      points.add(WeeklyVolumePoint(weekStart, volume, workouts));
    }
    return points;
  }

  /// Best recorded weight per set for an exercise over time (strength graph).
  Future<List<StrengthPoint>> strengthProgress(String exerciseRefId) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT s.date, MAX(ws.weight) AS weight, wsr.reps AS reps
      FROM workout_sets ws
      INNER JOIN workout_sessions s ON s.id = ws.session_id
      INNER JOIN (
        SELECT session_id, exercise_ref_id, order_index, weight, reps, row_number()
          OVER (PARTITION BY session_id, exercise_ref_id ORDER BY weight DESC, reps DESC) AS rn
        FROM workout_sets
      ) wsr ON wsr.session_id = ws.session_id AND wsr.exercise_ref_id = ws.exercise_ref_id AND wsr.rn = 1
      WHERE ws.exercise_ref_id = ? AND s.status = 'completed'
      GROUP BY s.date
      ORDER BY s.date ASC
    ''', [exerciseRefId]);
    return rows
        .map((r) => StrengthPoint(
              DateTime.parse(r['date'] as String),
              (r['weight'] as num).toDouble(),
              (r['reps'] as num).toInt(),
            ))
        .toList();
  }

  /// Exercise names ever logged in completed workouts — real data, used to
  /// populate the strength progress picker.
  Future<List<({String id, String name})>> exercisesPracticed() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT ws.exercise_ref_id AS id, MAX(ws.exercise_name) AS name
      FROM workout_sets ws
      INNER JOIN workout_sessions s ON s.id = ws.session_id
      WHERE s.status = 'completed' AND ws.completed = 1
      GROUP BY ws.exercise_ref_id
      ORDER BY name COLLATE NOCASE ASC
    ''');
    return rows
        .map((r) => (
              id: r['id'] as String,
              name: (r['name'] as String?) ?? 'Exercise',
            ))
        .toList();
  }

  /// Per-session aggregates for an exercise across completed workouts.
  Future<List<ExerciseSessionPoint>> exerciseSessions(
      String exerciseRefId) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT ws.session_id, s.date, s.title, ws.weight, ws.reps, ws.completed
      FROM workout_sets ws
      INNER JOIN workout_sessions s ON s.id = ws.session_id
      WHERE ws.exercise_ref_id = ? AND s.status = 'completed'
      ORDER BY s.date ASC, ws.order_index ASC
    ''', [exerciseRefId]);

    final bySession = <String, Map<String, Object?>>{};
    final order = <String>[];
    for (final row in rows) {
      final id = row['session_id'] as String;
      if (!bySession.containsKey(id)) {
        bySession[id] = {'date': row['date'], 'title': row['title']};
        order.add(id);
      }
    }
    // Re-group cleanly because row maps share no session key structure.
    final grouped =
        <String, List<({double weight, int reps, bool completed})>>{};
    for (final row in rows) {
      final id = row['session_id'] as String;
      grouped.putIfAbsent(id, () => []).add((
        weight: (row['weight'] as num).toDouble(),
        reps: (row['reps'] as num).toInt(),
        completed: (row['completed'] as num?)?.toInt() == 1,
      ));
    }

    final points = <ExerciseSessionPoint>[];
    for (final id in order) {
      final sets = grouped[id] ?? const [];
      final done = sets.where((s) => s.completed).toList();
      if (done.isEmpty) continue;
      var bestWeight = 0.0;
      var bestReps = 0;
      var volume = 0.0;
      for (final s in done) {
        volume += s.weight * s.reps;
        if (s.weight > bestWeight) {
          bestWeight = s.weight;
          bestReps = s.reps;
        }
      }
      final meta = bySession[id]!;
      points.add(ExerciseSessionPoint(
        date: DateTime.parse(meta['date'] as String),
        title: (meta['title'] as String?) ?? 'Workout',
        completedSets: done.length,
        bestWeight: bestWeight,
        bestReps: bestReps,
        volume: volume,
      ));
    }
    return points;
  }

  /// Last performance and best performance for an exercise, used for
  /// progressive overload suggestions.
  Future<(StrengthPoint? last, StrengthPoint? best)> performanceFor(
      String exerciseRefId) async {
    final points = await strengthProgress(exerciseRefId);
    if (points.isEmpty) return (null, null);
    final best = points.reduce((a, b) => b.weight > a.weight ? b : a);
    return (points.last, best);
  }

  /// Consistency per week for the last [weeks] weeks based on a weekly target.
  Future<List<(DateTime weekStart, int completed, int target)>>
      consistency(int weeks, int weeklyTarget) async {
    final now = DateTime.now();
    final list = <(DateTime, int, int)>[];
    for (var i = weeks - 1; i >= 0; i--) {
      final weekStart =
          now.startOfWeek.subtract(Duration(days: i * 7));
      final completed = await countCompletedBetween(
          weekStart, weekStart.add(const Duration(days: 6)));
      list.add((weekStart, completed, weeklyTarget));
    }
    return list;
  }

  Future<MonthlyStats> monthlyStats(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0);

    final db = await _db.database;
    final sessions = await getSessionsBetween(start, end);

    final result = await db.rawQuery('''
      SELECT
        COALESCE(SUM(total_volume_kg), 0) AS volume,
        COALESCE(SUM(duration_minutes), 0) AS duration,
        AVG(energy) AS avg_energy,
        AVG(sleep_hours * 60 + sleep_minutes) AS avg_sleep,
        AVG(soreness) AS avg_soreness
      FROM daily_checkins
      WHERE date BETWEEN ? AND ?
    ''', [start.isoDate, end.isoDate]);
    final summary = result.isEmpty ? null : result.first;

    // Starting & closing weight using body measurements and check-ins.
    double? startWeight;
    double? endWeight;
    final mRows = await db.query('body_measurements',
        where: 'date BETWEEN ? AND ?',
        whereArgs: [start.isoDate, end.isoDate],
        orderBy: 'date ASC');
    final first = mRows.isEmpty ? null : mRows.first['weight_kg'];
    final last = mRows.isEmpty ? null : mRows.last['weight_kg'];
    startWeight = first as double?;
    endWeight = last as double?;

    return MonthlyStats(
      workouts: sessions.length,
      totalVolume: (summary?['volume'] as num?)?.toDouble() ?? 0,
      avgEnergy: (summary?['avg_energy'] as num?)?.toDouble(),
      avgSleepMinutes: (summary?['avg_sleep'] as num?)?.toDouble(),
      avgSoreness: (summary?['avg_soreness'] as num?)?.toDouble(),
      startWeight: startWeight,
      endWeight: endWeight,
    );
  }
}