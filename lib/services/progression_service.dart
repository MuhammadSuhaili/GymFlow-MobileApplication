/// Deterministic, rule-based progressive-overload logic.
///
/// The result is **always advisory** — the app never changes a program, weight
/// or rep range on its own. Suggestions are based only on real recorded data
/// and are never medical or guaranteed recommendations.
library;

import 'package:gym_flow/models/workout_set.dart';

/// Outcome of evaluating the previous performance of an exercise.
enum ProgressionOutcome {
  /// No completed session exists for this exercise.
  noPreviousData,

  /// History exists but no usable target rep range is configured.
  noTargetRange,

  /// History exists but has no set with a valid weight (incomplete data).
  insufficientData,

  /// Reps are below the target range — keep the weight, aim for more reps.
  belowTarget,

  /// Target range was reached but at high effort (RPE >= 9) — keep the weight.
  maintainHighRpe,

  /// In range but not at the upper end yet — keep the weight for now.
  maintainReachTarget,

  /// Upper end of the range reached at manageable effort — suggest a
  /// small, practical weight increase.
  increaseWeight,
}

/// A non-binding next-workout suggestion derived from previous performance.
class ProgressionSuggestion {
  final ProgressionOutcome outcome;

  /// Weight the user should try next (equals the previous working weight for
  /// every "keep weight" outcome). Null when there is no usable data.
  final double? suggestedWeight;

  /// Working weight from the previous session (best set).
  final double? previousWeight;

  /// Best reps from the previous session.
  final int? previousBestReps;

  /// Average RPE of the previous session (null when none recorded).
  final int? avgRpe;

  /// Target sets/rep range used for the evaluation (null when unavailable).
  final int? targetSets;
  final int? minReps;
  final int? maxReps;

  const ProgressionSuggestion({
    required this.outcome,
    this.suggestedWeight,
    this.previousWeight,
    this.previousBestReps,
    this.avgRpe,
    this.targetSets,
    this.minReps,
    this.maxReps,
  });

  double? get previousVolumeKg {
    final w = previousWeight;
    final r = previousBestReps;
    if (w == null || r == null) return null;
    return w * r;
  }

  static const String noPreviousMessage = 'No previous workout data.';
  static const String insufficientMessage =
      'Not enough data for progression.';
  static const String noTargetMessage =
      'Set a rep range to receive a progression suggestion.';

  /// Short, friendly top-line message describing what to do next.
  String get message {
    switch (outcome) {
      case ProgressionOutcome.noPreviousData:
        return ProgressionSuggestion.noPreviousMessage;
      case ProgressionOutcome.insufficientData:
        return ProgressionSuggestion.insufficientMessage;
      case ProgressionOutcome.noTargetRange:
        return ProgressionSuggestion.noTargetMessage;
      case ProgressionOutcome.belowTarget:
        return 'Keep ${_fmt(suggestedWeight)} kg and aim to improve your '
            'reps up to $minReps–$maxReps.';
      case ProgressionOutcome.maintainHighRpe:
        return 'Maintain ${_fmt(suggestedWeight)} kg — the reps were done at '
            'high effort. Focus on hitting $minReps–$maxReps reps before '
            'adding weight.';
      case ProgressionOutcome.maintainReachTarget:
        return 'Maintain ${_fmt(suggestedWeight)} kg and work toward the '
            'upper end of $minReps–$maxReps reps first.';
      case ProgressionOutcome.increaseWeight:
        return 'Consider trying ${_fmt(suggestedWeight)} kg for '
            '$minReps–$maxReps reps.';
    }
  }

  /// Evidence line built exclusively from recorded data.
  String? get reason {
    final w = previousWeight;
    final r = previousBestReps;
    if (outcome == ProgressionOutcome.noPreviousData ||
        outcome == ProgressionOutcome.noTargetRange ||
        w == null) {
      return null;
    }
    if (outcome == ProgressionOutcome.insufficientData) return null;
    final rpePart = avgRpe != null ? ' · Avg RPE $avgRpe' : '';
    return 'Previous session: ${_fmt(w)} kg × $r$rpePart';
  }
}

/// Best (top) completed set of a session: highest reps, ties broken by
/// heavier weight. Only sets with a valid weight count.
WorkoutSet? bestSet(List<WorkoutSet> sets) {
  final valid =
      sets.where((s) => s.completed && s.weight > 0).toList();
  if (valid.isEmpty) return null;
  WorkoutSet best = valid.first;
  for (final s in valid.skip(1)) {
    if (s.reps > best.reps ||
        (s.reps == best.reps && s.weight > best.weight)) {
      best = s;
    }
  }
  return best;
}

/// Practical weight increment used for the "increase" suggestion.
/// Rounds up to a real gym-available increment (1.25 / 2.5 / 5 kg plates)
/// close to ~2.5% of the current weight. Never returns zero.
double suggestedIncrement(double previousWeight) {
  if (previousWeight <= 0) return 0;
  final step = previousWeight < 40
      ? 1.25
      : previousWeight < 100
          ? 2.5
          : 5.0;
  final base = previousWeight * 0.025;
  final extra = (base / step).ceilToDouble() * step;
  return _round2(previousWeight + extra);
}

/// Evaluates previous completed sets against the configured target and
/// produces the next-session suggestion. Pure and deterministic.
ProgressionSuggestion suggest({
  List<WorkoutSet> previousSets = const [],
  int? targetSets,
  int? minReps,
  int? maxReps,
}) {
  if (previousSets.isEmpty) {
    return const ProgressionSuggestion(
        outcome: ProgressionOutcome.noPreviousData);
  }

  final best = bestSet(previousSets);
  if (best == null) {
    final nothingCompleted = previousSets.every((s) => !s.completed);
    // Nothing was actually completed → no usable previous performance.
    if (nothingCompleted) {
      return const ProgressionSuggestion(
          outcome: ProgressionOutcome.noPreviousData);
    }
    // Completed sets exist but none carry a valid weight → incomplete data.
    return const ProgressionSuggestion(
        outcome: ProgressionOutcome.insufficientData);
  }

  final hasTarget =
      minReps != null && maxReps != null && minReps > 0 && maxReps >= minReps;
  if (!hasTarget) {
    return const ProgressionSuggestion(
        outcome: ProgressionOutcome.noTargetRange);
  }

  final rpes = previousSets
      .where((s) => s.completed && s.rpe != null)
      .map((s) => s.rpe!)
      .toList();
  final avgRpe =
      rpes.isEmpty ? null : (rpes.reduce((a, b) => a + b) / rpes.length).round();

  final working = best.weight;
  final achieved = best.reps;
  final inRange = achieved >= minReps;
  final atUpper = achieved >= maxReps;
  final rpeHigh = avgRpe != null && avgRpe >= 9;

  if (!inRange) {
    return ProgressionSuggestion(
      outcome: ProgressionOutcome.belowTarget,
      suggestedWeight: working,
      previousWeight: working,
      previousBestReps: achieved,
      avgRpe: avgRpe,
      targetSets: targetSets,
      minReps: minReps,
      maxReps: maxReps,
    );
  }
  if (rpeHigh) {
    return ProgressionSuggestion(
      outcome: ProgressionOutcome.maintainHighRpe,
      suggestedWeight: working,
      previousWeight: working,
      previousBestReps: achieved,
      avgRpe: avgRpe,
      targetSets: targetSets,
      minReps: minReps,
      maxReps: maxReps,
    );
  }
  if (!atUpper) {
    return ProgressionSuggestion(
      outcome: ProgressionOutcome.maintainReachTarget,
      suggestedWeight: working,
      previousWeight: working,
      previousBestReps: achieved,
      avgRpe: avgRpe,
      targetSets: targetSets,
      minReps: minReps,
      maxReps: maxReps,
    );
  }
  return ProgressionSuggestion(
    outcome: ProgressionOutcome.increaseWeight,
    suggestedWeight: suggestedIncrement(working),
    previousWeight: working,
    previousBestReps: achieved,
    avgRpe: avgRpe,
    targetSets: targetSets,
    minReps: minReps,
    maxReps: maxReps,
  );
}

/// Descriptive comparison between a previous and a current session.
/// Labels are informational only — never judgmental.
enum ProgressionStatus { improved, maintained, repsImproved, noImprovement }

ProgressionStatus statusBetween({
  required double previousWeight,
  required int previousReps,
  required double currentWeight,
  required int currentReps,
}) {
  const threshold = 0.06;
  if (currentWeight > previousWeight + threshold) {
    return ProgressionStatus.improved;
  }
  if (currentWeight < previousWeight - threshold) {
    return ProgressionStatus.noImprovement;
  }
  if (currentReps > previousReps) {
    return ProgressionStatus.repsImproved;
  }
  if (currentReps >= previousReps) {
    return ProgressionStatus.maintained;
  }
  return ProgressionStatus.noImprovement;
}

String progressionStatusLabel(ProgressionStatus status) => switch (status) {
      ProgressionStatus.improved => 'Improved',
      ProgressionStatus.maintained => 'Maintained',
      ProgressionStatus.repsImproved => 'Reps Improved',
      ProgressionStatus.noImprovement => 'No Improvement',
    };

// ---- helpers ----

double _round2(double v) => (v * 100).roundToDouble() / 100;

String _fmt(double? v) {
  if (v == null) return '--';
  final rounded = _round2(v);
  return rounded == rounded.roundToDouble()
      ? rounded.toInt().toString()
      : rounded.toString();
}