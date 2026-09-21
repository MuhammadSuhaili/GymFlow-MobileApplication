import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flow/models/body_measurement.dart';
import 'package:gym_flow/services/monthly_report_service.dart';

MonthlySession _session({
  required String day,
  int sets = 3,
  int reps = 30,
  double volume = 1800,
  int duration = 40,
  String? programId,
  List<int> rpes = const [],
}) =>
    MonthlySession(
      date: DateTime.parse(day),
      completedSets: sets,
      totalReps: reps,
      volume: volume,
      durationMinutes: duration,
      programId: programId,
      rpes: rpes,
    );

LiftSample _lift(String day, double w, int r) =>
    LiftSample(date: DateTime.parse(day), weight: w, reps: r);

BodyMeasurement _m(
  String day, {
  double? weightKg,
  double? bodyFat,
  double? chestCm,
  double? waistCm,
  double? armCm,
  double? thighCm,
  double? hipsCm,
  String? notes,
  String? id,
}) =>
    BodyMeasurement(
      id: id ?? 'm$day',
      date: DateTime.parse(day),
      weightKg: weightKg,
      bodyFat: bodyFat,
      chestCm: chestCm,
      waistCm: waistCm,
      armCm: armCm,
      thighCm: thighCm,
      hipsCm: hipsCm,
      notes: notes,
    );

class _InputBuilder {
  final year = 2026;
  List<MonthlySession> month = [];
  List<MonthlySession> previous = [];
  List<BodyMeasurement> measurements = [];
  BodyMeasurement? latestRecent;
  ({int current, int best}) streak = (current: 0, best: 0);
  MonthlyProgramInput? program;
  List<ExerciseMonthData> exercises = [];

  MonthlyReportInputs build() => MonthlyReportInputs(
        year: year,
        month: 1,
        monthSessions: month,
        previousMonthSessions: previous,
        monthMeasurements: measurements,
        latestRecentMeasurement: latestRecent,
        currentStreak: streak,
        program: program,
        exercises: exercises,
      );
}

void main() {
  group('overview aggregates', () {
    test('empty month produces an empty report', () {
      final r = buildMonthlyReport(_InputBuilder().build());
      expect(r.isEmpty, isTrue);
      expect(r.workouts, 0);
      expect(r.volume, 0);
      expect(r.completedSets, 0);
      expect(r.totalReps, 0);
      expect(r.avgDurationMinutes, 0);
      expect(r.totalDurationMinutes, 0);
      expect(r.longestStreakInMonth, 0);
    });

    test('a single session is counted', () {
      final b = _InputBuilder()
        ..month = [
          _session(day: '2026-01-07', sets: 5, reps: 50, volume: 3000, duration: 45)
        ];
      final r = buildMonthlyReport(b.build());
      expect(r.isEmpty, isFalse);
      expect(r.workouts, 1);
      expect(r.completedSets, 5);
      expect(r.totalReps, 50);
      expect(r.volume, 3000);
      expect(r.totalDurationMinutes, 45);
      expect(r.avgDurationMinutes, 45);
    });

    test('multiple sessions are summed', () {
      final b = _InputBuilder()
        ..month = [
          _session(day: '2026-01-05', sets: 3, reps: 30, volume: 1800, duration: 40),
          _session(day: '2026-01-08', sets: 4, reps: 40, volume: 2400, duration: 50),
          _session(day: '2026-01-12', sets: 5, reps: 50, volume: 3200, duration: 45),
        ];
      final r = buildMonthlyReport(b.build());
      expect(r.workouts, 3);
      expect(r.completedSets, 12);
      expect(r.totalReps, 120);
      expect(r.volume, 7400);
      expect(r.totalDurationMinutes, 135);
      expect(r.avgDurationMinutes, 45);
    });

    test('average duration is rounded to whole minutes', () {
      final b = _InputBuilder()
        ..month = [
          _session(day: '2026-01-05', duration: 40),
          _session(day: '2026-01-06', duration: 45),
          _session(day: '2026-01-08', duration: 45),
        ];
      final r = buildMonthlyReport(b.build());
      expect(r.totalDurationMinutes, 130);
      expect(r.avgDurationMinutes, 43);
    });
  });

  group('month over month comparison', () {
    test('no previous-month data when the previous month is empty', () {
      final b = _InputBuilder()
        ..month = [_session(day: '2026-01-07')];
      final r = buildMonthlyReport(b.build());
      expect(r.hasPreviousMonthData, isFalse);
      expect(r.workoutsDeltaPercent, isNull);
      expect(r.volumeDeltaPercent, isNull);
      expect(r.completedSetsDeltaPercent, isNull);
      expect(r.totalRepsDeltaPercent, isNull);
      expect(r.avgDurationDeltaPercent, isNull);
    });

    test('increases produce positive deltas', () {
      final b = _InputBuilder()
        ..previous = [
          _session(day: '2025-12-02', volume: 1500),
          _session(day: '2025-12-04', volume: 1500),
          _session(day: '2025-12-06', volume: 1500),
          _session(day: '2025-12-08', volume: 1500),
        ]
        ..month = [
          _session(day: '2026-01-03', volume: 1500),
          _session(day: '2026-01-05', volume: 1500),
          _session(day: '2026-01-07', volume: 1500),
          _session(day: '2026-01-09', volume: 1500),
          _session(day: '2026-01-11', volume: 1500),
          _session(day: '2026-01-13', volume: 1500),
        ];
      final r = buildMonthlyReport(b.build());
      expect(r.hasPreviousMonthData, isTrue);
      expect(r.workoutsDeltaPercent, 50.0);
      expect(r.volumeDeltaPercent, 50.0);
      expect(r.previousWorkouts, 4);
    });

    test('decreases produce negative deltas', () {
      final b = _InputBuilder()
        ..previous = [_session(day: '2025-12-02', volume: 2000)]
        ..month = [_session(day: '2026-01-07', volume: 1500)];
      final r = buildMonthlyReport(b.build());
      expect(r.volumeDeltaPercent, -25.0);
    });

    test('an empty current month is -100% against a real previous month', () {
      final b = _InputBuilder()..previous = [_session(day: '2025-12-02')];
      final r = buildMonthlyReport(b.build());
      expect(r.hasPreviousMonthData, isTrue);
      expect(r.workoutsDeltaPercent, -100.0);
      expect(r.volumeDeltaPercent, -100.0);
    });

    test('average duration delta is computed in percent', () {
      final b = _InputBuilder()
        ..previous = [
          _session(day: '2025-12-02', duration: 45),
          _session(day: '2025-12-04', duration: 45),
        ]
        ..month = [
          _session(day: '2026-01-03', duration: 50),
          _session(day: '2026-01-05', duration: 50),
        ];
      final r = buildMonthlyReport(b.build());
      expect(r.previousAvgDurationMinutes, 45);
      expect(r.avgDurationDeltaPercent, closeTo(11.1, 0.1));
    });
  });

  group('consistency', () {
    MonthlyProgramInput program({int scheduled = 8, String id = 'p1'}) =>
        MonthlyProgramInput(
          programId: id,
          name: 'Hypertrophy',
          goal: 'Muscle gain',
          durationWeeks: 12,
          scheduledDates: [
            for (var i = 0; i < scheduled; i++) DateTime(2026, 1, 3 + i * 3)
          ],
        );

    test('not available without a program', () {
      final r = buildMonthlyReport(_InputBuilder().build());
      expect(r.consistencyAvailable, isFalse);
      expect(r.consistencyPercent, isNull);
    });

    test('full schedule completion is 100%', () {
      final b = _InputBuilder()
        ..month = [
          for (var i = 0; i < 8; i++)
            _session(day: '2026-01-${(3 + i * 3).toString().padLeft(2, '0')}')
        ]
        ..program = program(scheduled: 8);
      final r = buildMonthlyReport(b.build());
      expect(r.consistencyAvailable, isTrue);
      expect(r.consistencyScheduled, 8);
      expect(r.consistencyPercent, 1.0);
    });

    test('partial completion is a fraction', () {
      final b = _InputBuilder()
        ..month = [for (var i = 0; i < 4; i++) _session(day: '2026-01-0${i + 1}')]
        ..program = program(scheduled: 8);
      final r = buildMonthlyReport(b.build());
      expect(r.consistencyPercent, 0.5);
      expect(r.consistencyCompleted, 4);
    });

    test('over-target completion clamps to 100%', () {
      final b = _InputBuilder()
        ..month = [
          for (var i = 0; i < 10; i++)
            _session(day: '2026-01-${(i + 1).toString().padLeft(2, '0')}')
        ]
        ..program = program(scheduled: 8);
      final r = buildMonthlyReport(b.build());
      expect(r.consistencyPercent, 1.0);
    });

    test('program without scheduled days is not available', () {
      final b = _InputBuilder()..program = program(scheduled: 0);
      final r = buildMonthlyReport(b.build());
      expect(r.consistencyAvailable, isFalse);
      expect(r.consistencyScheduled, 0);
    });
  });

  group('streak inside the month', () {
    test('consecutive workout days build a streak', () {
      final b = _InputBuilder()
        ..month = [
          _session(day: '2026-01-05'),
          _session(day: '2026-01-06'),
          _session(day: '2026-01-07'),
        ];
      final r = buildMonthlyReport(b.build());
      expect(r.longestStreakInMonth, 3);
    });

    test('a gap resets the streak', () {
      final b = _InputBuilder()
        ..month = [
          _session(day: '2026-01-05'),
          _session(day: '2026-01-06'),
          _session(day: '2026-01-08'),
          _session(day: '2026-01-09'),
        ];
      final r = buildMonthlyReport(b.build());
      expect(r.longestStreakInMonth, 2);
    });

    test('a single day is a streak of one', () {
      final b = _InputBuilder()..month = [_session(day: '2026-01-07')];
      final r = buildMonthlyReport(b.build());
      expect(r.longestStreakInMonth, 1);
    });

    test('the ongoing global streak is passed through', () {
      final b = _InputBuilder()
        ..streak = (current: 4, best: 9)
        ..month = [_session(day: '2026-01-07')];
      final r = buildMonthlyReport(b.build());
      expect(r.currentStreakDays, 4);
      expect(r.bestStreakDays, 9);
    });
  });

  group('weekly charts', () {
    test('a week\u2019s workouts are bucketed into the right week', () {
      final b = _InputBuilder()
        ..month = [
          _session(day: '2026-01-07', volume: 1800),
          _session(day: '2026-01-08', volume: 1200),
          _session(day: '2026-01-14', volume: 2400),
        ];
      final r = buildMonthlyReport(b.build());
      expect(r.volumeBuckets.length, 2);
      expect(r.volumeBuckets[0].start, DateTime(2026, 1, 5));
      expect(r.volumeBuckets[0].volume, 3000);
      expect(r.volumeBuckets[0].workouts, 2);
      expect(r.volumeBuckets[1].start, DateTime(2026, 1, 12));
      expect(r.volumeBuckets[1].volume, 2400);
      expect(r.frequencyBuckets[0].workouts, 2);
      expect(r.frequencyBuckets[1].workouts, 1);
      expect(r.frequencyBuckets[0].start, DateTime(2026, 1, 5));
    });

    test('empty leading and trailing weeks are not fabricated', () {
      final b = _InputBuilder()..month = [_session(day: '2026-01-28')];
      final r = buildMonthlyReport(b.build());
      expect(r.volumeBuckets.length, 1);
      expect(r.volumeBuckets[0].start, DateTime(2026, 1, 26));
    });
  });

  group('exercise strength progress', () {
    test('month best uses the heaviest lift of the month', () {
      final b = _InputBuilder()
        ..exercises = [
          ExerciseMonthData(
            exerciseId: 'e1',
            exerciseName: 'Bench Press',
            inMonth: [_lift('2026-01-05', 60, 8), _lift('2026-01-12', 62.5, 8)],
            beforeMonth: [_lift('2025-12-05', 57.5, 8)],
          )
        ];
      final r = buildMonthlyReport(b.build());
      expect(r.exercises.length, 1);
      final e = r.exercises.first;
      expect(e.monthBestWeight, 62.5);
      expect(e.monthBestReps, 8);
      expect(e.previousBestWeight, 57.5);
      expect(e.monthSessions, 2);
      expect(e.monthVolume, 60 * 8 + 62.5 * 8);
    });

    test('equal weight breaks ties towards more reps', () {
      final b = _InputBuilder()
        ..exercises = [
          ExerciseMonthData(
            exerciseId: 'e1',
            exerciseName: 'Bench Press',
            inMonth: [_lift('2026-01-05', 60, 8), _lift('2026-01-08', 60, 10)],
          )
        ];
      final r = buildMonthlyReport(b.build());
      expect(r.exercises.first.monthBestWeight, 60);
      expect(r.exercises.first.monthBestReps, 10);
    });

    test('a lift with no prior history is a first lift of the month', () {
      final b = _InputBuilder()
        ..exercises = [
          ExerciseMonthData(
            exerciseId: 'e1',
            exerciseName: 'Squat',
            inMonth: [_lift('2026-01-07', 80, 5)],
          )
        ];
      final r = buildMonthlyReport(b.build());
      expect(r.exercises.first.status, ExerciseProgressionStatus.firstLiftThisMonth);
    });

    test('lifting heavier than the previous best is weightUp', () {
      final b = _InputBuilder()
        ..exercises = [
          ExerciseMonthData(
            exerciseId: 'e1',
            exerciseName: 'Bench Press',
            inMonth: [_lift('2026-01-07', 62.5, 8)],
            beforeMonth: [_lift('2025-12-20', 60, 8)],
          )
        ];
      expect(buildMonthlyReport(b.build()).exercises.first.status,
          ExerciseProgressionStatus.weightUp);
    });

    test('more reps at the same weight is repsUp', () {
      final b = _InputBuilder()
        ..exercises = [
          ExerciseMonthData(
            exerciseId: 'e1',
            exerciseName: 'Bench Press',
            inMonth: [_lift('2026-01-07', 60, 10)],
            beforeMonth: [_lift('2025-12-20', 60, 8)],
          )
        ];
      expect(buildMonthlyReport(b.build()).exercises.first.status,
          ExerciseProgressionStatus.repsUp);
    });

    test('same weight and reps is maintained', () {
      final b = _InputBuilder()
        ..exercises = [
          ExerciseMonthData(
            exerciseId: 'e1',
            exerciseName: 'Bench Press',
            inMonth: [_lift('2026-01-07', 60, 8)],
            beforeMonth: [_lift('2025-12-20', 60, 8)],
          )
        ];
      expect(buildMonthlyReport(b.build()).exercises.first.status,
          ExerciseProgressionStatus.maintained);
    });

    test('lighter than the previous best is belowPreviousBest', () {
      final b = _InputBuilder()
        ..exercises = [
          ExerciseMonthData(
            exerciseId: 'e1',
            exerciseName: 'Bench Press',
            inMonth: [_lift('2026-01-07', 57.5, 8)],
            beforeMonth: [_lift('2025-12-20', 60, 8)],
          )
        ];
      expect(buildMonthlyReport(b.build()).exercises.first.status,
          ExerciseProgressionStatus.belowPreviousBest);
    });

    test('exercises without in-month lifts are excluded', () {
      final b = _InputBuilder()
        ..exercises = [
          ExerciseMonthData(
            exerciseId: 'e1',
            exerciseName: 'Deadlift',
            beforeMonth: [_lift('2025-12-01', 100, 5)],
          )
        ];
      final r = buildMonthlyReport(b.build());
      expect(r.exercises, isEmpty);
    });

    test('highlights rank improvements first', () {
      final b = _InputBuilder()
        ..exercises = [
          ExerciseMonthData(
            exerciseId: 'e1',
            exerciseName: 'A-VeryHeavy',
            inMonth: [_lift('2026-01-07', 120, 3)],
          ),
          ExerciseMonthData(
            exerciseId: 'e2',
            exerciseName: 'B-Squats',
            inMonth: [_lift('2026-01-07', 80, 5)],
            beforeMonth: [_lift('2025-12-01', 75, 5)],
          ),
        ];
      final r = buildMonthlyReport(b.build());
      final first = r.exercises.first;
      expect(first.exerciseName, 'B-Squats');
      expect(first.status, ExerciseProgressionStatus.weightUp);
    });
  });

  group('body measurements', () {
    test('start and end weights produce a delta', () {
      final b = _InputBuilder()
        ..measurements = [
          _m('2026-01-03', weightKg: 82.5),
          _m('2026-01-27', weightKg: 81.0),
        ]
        ..latestRecent = _m('2026-01-27', weightKg: 81.0);
      final r = buildMonthlyReport(b.build());
      final m = r.measurements!;
      expect(m.startWeightKg, 82.5);
      expect(m.endWeightKg, 81.0);
      expect(m.weightDelta, -1.5);
      expect(r.latestWeightKg, 81.0);
    });

    test('a single measurement shows the value with no delta', () {
      final b = _InputBuilder()
        ..measurements = [_m('2026-01-20', weightKg: 82, bodyFat: 18)]
        ..latestRecent = _m('2026-01-20', weightKg: 82);
      final r = buildMonthlyReport(b.build());
      expect(r.measurements!.isSingle, isTrue);
      expect(r.measurements!.startWeightKg, 82);
      expect(r.measurements!.weightDelta, isNull);
      expect(r.latestWeightKg, 82);
    });

    test('missing fields yield null deltas but keep values', () {
      final b = _InputBuilder()
        ..measurements = [
          _m('2026-01-03', weightKg: 82, waistCm: 90),
          _m('2026-01-27', weightKg: 81, chestCm: 100),
        ];
      final r = buildMonthlyReport(b.build());
      final m = r.measurements!;
      expect(m.weightDelta, -1.0);
      expect(m.chestDelta, isNull);
      expect(m.chestStart, isNull);
      expect(m.chestEnd, 100);
      expect(m.waistDelta, isNull);
      expect(m.waistStart, 90);
    });

    test('no measurements in the month leaves the section empty', () {
      final r = buildMonthlyReport(_InputBuilder().build());
      expect(r.measurements, isNull);
      expect(r.latestWeightKg, isNull);
    });
  });

  group('RPE summary', () {
    test('average RPE is computed over rated sets only', () {
      final b = _InputBuilder()
        ..month = [
          _session(day: '2026-01-05', rpes: [8, 9]),
          _session(day: '2026-01-07', rpes: [10]),
          _session(day: '2026-01-09', rpes: []),
        ];
      final r = buildMonthlyReport(b.build());
      expect(r.rpeSetCount, 3);
      expect(r.avgRpe, closeTo(9.0, 0.01));
    });

    test('no RPE data leaves the average null', () {
      final b = _InputBuilder()..month = [_session(day: '2026-01-05', rpes: [])];
      final r = buildMonthlyReport(b.build());
      expect(r.rpeSetCount, 0);
      expect(r.avgRpe, isNull);
    });
  });

  group('program summary', () {
    test('program stats count scheduled and completed workouts separately', () {
      final b = _InputBuilder()
        ..month = [
          _session(day: '2026-01-03', programId: 'p1'),
          _session(day: '2026-01-05', programId: 'p1'),
          _session(day: '2026-01-07', programId: 'p1'),
          _session(day: '2026-01-09', programId: 'other'),
        ]
        ..program = MonthlyProgramInput(
          programId: 'p1',
          name: 'Hypertrophy',
          goal: 'Muscle gain',
          durationWeeks: 8,
          scheduledDates: [
            DateTime(2026, 1, 3),
            DateTime(2026, 1, 5),
            DateTime(2026, 1, 7),
            DateTime(2026, 1, 10),
          ],
          programSessions: [
            _session(day: '2026-01-03', programId: 'p1'),
            _session(day: '2026-01-05', programId: 'p1'),
            _session(day: '2026-01-07', programId: 'p1'),
          ],
        );
      final r = buildMonthlyReport(b.build());
      expect(r.program!.name, 'Hypertrophy');
      expect(r.program!.scheduledWorkouts, 4);
      expect(r.program!.completedWorkouts, 3);
      expect(r.consistencyCompleted, 4);
    });
  });
}