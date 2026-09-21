import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flow/models/workout_set.dart';
import 'package:gym_flow/services/progression_service.dart';

WorkoutSet _set({
  double weight = 40,
  int reps = 10,
  int? rpe,
  bool completed = true,
}) =>
    WorkoutSet(
      id: 's${weight.hashCode}_${reps}_$rpe',
      sessionId: 's1',
      exerciseRefId: 'e1',
      exerciseName: 'Bench Press',
      orderIndex: 0,
      weight: weight,
      reps: reps,
      rpe: rpe,
      completed: completed,
    );

void main() {
  group('suggestedIncrement — practical plate increments', () {
    test('light weights round to a real available increment', () {
      expect(suggestedIncrement(20), 21.25);
      expect(suggestedIncrement(40), 42.5);
    });

    test('moderate and heavy weights use 2.5 / 5 kg plates', () {
      expect(suggestedIncrement(60), 62.5);
      expect(suggestedIncrement(100), 105);
    });

    test('invalid weight returns zero (never suggested)', () {
      expect(suggestedIncrement(0), 0);
      expect(suggestedIncrement(-5), 0);
    });
  });

  group('suggest — rule based on real recorded data', () {
    test('Case D: no previous workout shows no recommendation', () {
      final s = suggest(
        previousSets: const [],
        targetSets: 3,
        minReps: 8,
        maxReps: 10,
      );
      expect(s.outcome, ProgressionOutcome.noPreviousData);
      expect(s.suggestedWeight, isNull);
      expect(s.message, 'No previous workout data.');
    });

    test('Case C: reps below target keep the weight', () {
      final s = suggest(
        previousSets: [
          _set(weight: 40, reps: 6),
          _set(weight: 40, reps: 5),
        ],
        targetSets: 3,
        minReps: 8,
        maxReps: 10,
      );
      expect(s.outcome, ProgressionOutcome.belowTarget);
      expect(s.suggestedWeight, 40);
      expect(s.message, contains('Keep 40 kg'));
    });

    test('Case B: target reached but RPE high — no increase', () {
      final s = suggest(
        previousSets: [
          _set(weight: 40, reps: 10, rpe: 10),
          _set(weight: 40, reps: 10, rpe: 9),
        ],
        targetSets: 3,
        minReps: 8,
        maxReps: 10,
      );
      expect(s.outcome, ProgressionOutcome.maintainHighRpe);
      expect(s.suggestedWeight, 40);
      expect(s.avgRpe, 10);
      expect(s.message, contains('Maintain 40 kg'));
    });

    test('Case A: upper end reached at manageable RPE — small increase', () {
      final s = suggest(
        previousSets: [
          _set(weight: 40, reps: 10, rpe: 7),
          _set(weight: 40, reps: 10, rpe: 7),
          _set(weight: 40, reps: 10, rpe: 7),
        ],
        targetSets: 3,
        minReps: 8,
        maxReps: 10,
      );
      expect(s.outcome, ProgressionOutcome.increaseWeight);
      expect(s.suggestedWeight, 42.5);
      expect(s.previousWeight, 40);
      expect(s.previousBestReps, 10);
      expect(s.avgRpe, 7);
      expect(s.message, contains('42.5 kg'));
    });

    test('Case A with no RPE recorded still suggests (reps are objective)', () {
      final s = suggest(
        previousSets: [_set(weight: 40, reps: 12)],
        targetSets: 3,
        minReps: 8,
        maxReps: 10,
      );
      expect(s.outcome, ProgressionOutcome.increaseWeight);
      expect(s.suggestedWeight, 42.5);
    });

    test('in range, not at upper end, manageable RPE — keep weight', () {
      final s = suggest(
        previousSets: [_set(weight: 40, reps: 8, rpe: 7)],
        targetSets: 3,
        minReps: 8,
        maxReps: 10,
      );
      expect(s.outcome, ProgressionOutcome.maintainReachTarget);
      expect(s.suggestedWeight, 40);
    });

    test('missing target rep range — no recommendation', () {
      final s = suggest(
        previousSets: [_set(weight: 40, reps: 10)],
        targetSets: null,
        minReps: null,
        maxReps: null,
      );
      expect(s.outcome, ProgressionOutcome.noTargetRange);
      expect(s.message, 'Set a rep range to receive a progression suggestion.');
    });

    test('invalid/incomplete previous data — never guess', () {
      final noValidWeight = suggest(
        previousSets: [
          _set(weight: 0, reps: 10),
          _set(weight: 0, reps: 10),
        ],
        minReps: 8,
        maxReps: 10,
      );
      expect(noValidWeight.outcome, ProgressionOutcome.insufficientData);
      expect(noValidWeight.message, 'Not enough data for progression.');

      final nothingCompleted = suggest(
        previousSets: [_set(weight: 40, reps: 10, completed: false)],
        minReps: 8,
        maxReps: 10,
      );
      expect(nothingCompleted.outcome, ProgressionOutcome.noPreviousData);
    });

    test('invalid rep range is treated as missing', () {
      final s = suggest(
        previousSets: [_set(weight: 40, reps: 10)],
        minReps: 10,
        maxReps: 8,
      );
      expect(s.outcome, ProgressionOutcome.noTargetRange);
    });

    test('suggestion never mutates previous data (user stays in control)', () {
      final previous = [
        _set(weight: 40, reps: 10, rpe: 6),
        _set(weight: 40, reps: 10, rpe: 6),
      ];
      final before = previous.map((s) => '${s.weight}/${s.reps}/${s.rpe}').toList();
      final s = suggest(
        previousSets: previous,
        targetSets: 3,
        minReps: 8,
        maxReps: 10,
      );
      expect(s.outcome, ProgressionOutcome.increaseWeight);
      expect(previous.map((x) => '${x.weight}/${x.reps}/${x.rpe}').toList(),
          before);
      // The suggested value is only advice — the working weight stays intact.
      expect(s.suggestedWeight, isNot(previous.first.weight));
    });
  });

  group('statusBetween — descriptive post-session labels', () {
    test('heavier weight → Improved', () {
      expect(
        statusBetween(
            previousWeight: 40, previousReps: 10, currentWeight: 42.5, currentReps: 10),
        ProgressionStatus.improved,
      );
    });

    test('same weight, more reps → Reps Improved', () {
      expect(
        statusBetween(
            previousWeight: 40, previousReps: 8, currentWeight: 40, currentReps: 10),
        ProgressionStatus.repsImproved,
      );
    });

    test('same weight and reps → Maintained', () {
      expect(
        statusBetween(
            previousWeight: 40, previousReps: 10, currentWeight: 40, currentReps: 10),
        ProgressionStatus.maintained,
      );
    });

    test('fewer reps at same weight → No Improvement', () {
      expect(
        statusBetween(
            previousWeight: 40, previousReps: 10, currentWeight: 40, currentReps: 8),
        ProgressionStatus.noImprovement,
      );
    });

    test('lighter weight → No Improvement', () {
      expect(
        statusBetween(
            previousWeight: 40, previousReps: 10, currentWeight: 37.5, currentReps: 12),
        ProgressionStatus.noImprovement,
      );
    });
  });

  group('bestSet', () {
    test('picks highest reps among valid completed sets', () {
      final best = bestSet([
        _set(weight: 40, reps: 8),
        _set(weight: 40, reps: 10),
        _set(weight: 40, reps: 9),
      ]);
      expect(best, isNotNull);
      expect(best!.reps, 10);
    });

    test('ignores uncompleted sets and zero-weight sets', () {
      final best = bestSet([
        _set(weight: 40, reps: 10, completed: false),
        _set(weight: 0, reps: 12),
      ]);
      expect(best, isNull);
    });
  });
}