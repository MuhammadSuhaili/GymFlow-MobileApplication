import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_flow/core/extensions/date_extensions.dart';
import 'package:gym_flow/core/utils/formatters.dart';
import 'package:gym_flow/data/repositories/workout_repository.dart';
import 'package:gym_flow/models/exercise.dart';
import 'package:gym_flow/models/workout_set.dart';
import 'package:gym_flow/providers/data_providers.dart';
import 'package:gym_flow/providers/program_providers.dart';
import 'package:gym_flow/services/progression_service.dart';
import 'package:gym_flow/widgets/empty_state.dart';
import 'package:gym_flow/widgets/line_chart.dart';
import 'package:gym_flow/widgets/section_card.dart';
import 'package:gym_flow/widgets/stat_card.dart';

/// Detailed progress for a single exercise: bests, charts and recent
/// sessions — all computed from real logged sets.
class ExerciseProgressScreen extends ConsumerWidget {
  final String exerciseId;
  final String exerciseName;

  const ExerciseProgressScreen({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final exercise = ref.watch(exerciseByIdProvider(exerciseId));
    final points = ref.watch(exerciseSessionsProvider(exerciseId));
    final previous = ref.watch(lastPerformanceProvider(exerciseId));
    final configs = ref.watch(exerciseConfigsProvider(exerciseId));

    return Scaffold(
      appBar: AppBar(title: Text(exerciseName)),
      body: points.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.show_chart_rounded,
              title: 'No workout data yet',
              message: 'Complete a workout to see your progress.',
            );
          }
          final muscle =
              exercise.valueOrNull?.primaryMuscle ?? '—';
          var bestWeight = 0.0;
          var bestReps = 0;
          var bestVolume = 0.0;
          for (final p in list) {
            if (p.bestWeight > bestWeight) bestWeight = p.bestWeight;
            if (p.bestReps > bestReps) bestReps = p.bestReps;
            if (p.volume > bestVolume) bestVolume = p.volume;
          }
          final recent = list.reversed.toList();
          final weightSpots = list
              .map((p) => FlSpot(
                  p.date.millisecondsSinceEpoch.toDouble() / 86400000,
                  p.bestWeight))
              .toList();
          final volumeSpots = list
              .map((p) => FlSpot(
                  p.date.millisecondsSinceEpoch.toDouble() / 86400000,
                  p.volume))
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              SectionCard(
                title: exerciseName,
                subtitle: '$muscle • ${list.length} '
                    'session${list.length == 1 ? '' : 's'} • last '
                    '${recent.first.date.displayMonthDay}',
                child: Row(
                  children: [
                    Expanded(
                      child: StatCard(
                          icon: Icons.fitness_center_rounded,
                          value: Formatters.weightKg(bestWeight),
                          label: 'Best Weight'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                          icon: Icons.exposure_rounded,
                          value: '$bestReps',
                          label: 'Best Reps'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                          icon: Icons.local_fire_department_rounded,
                          value: Formatters.volumeKg(bestVolume),
                          label: 'Best Volume'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Next Session',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              SectionCard(
                title: 'Suggested progression',
                child: _NextSessionContent(
                  performance: previous.valueOrNull,
                  configs: configs.valueOrNull ?? const [],
                  theme: theme,
                ),
              ),
              const SizedBox(height: 20),
              Text('Weight Progression',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              SectionCard(
                title: 'Best weight per session',
                child: SizedBox(
                  height: 170,
                  child: LineChartView(
                    spots: weightSpots,
                    color: theme.colorScheme.primary,
                    xFormatter: (v) => DateTime.fromMillisecondsSinceEpoch(
                            (v * 86400000).round())
                        .weekdayShort,
                    yFormatter: (v) => v.round().toString(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Volume Progression',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              SectionCard(
                title: 'Total volume per session',
                child: SizedBox(
                  height: 170,
                  child: LineChartView(
                    spots: volumeSpots,
                    color: theme.colorScheme.tertiary,
                    xFormatter: (v) => DateTime.fromMillisecondsSinceEpoch(
                            (v * 86400000).round())
                        .weekdayShort,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Recent Sessions',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              ...recent.take(10).map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SessionTile(point: p),
                  )),
            ],
          );
        },
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final ExerciseSessionPoint point;

  const _SessionTile({required this.point});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(point.date.displayFull,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    '${point.title} • ${point.completedSets} sets',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${Formatters.weightNum(point.bestWeight)} kg × '
                  '${point.bestReps}',
                  style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(Formatters.volumeKg(point.volume),
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Data-driven "next session" block for an exercise: previous performance plus
/// a non-binding overload suggestion if a rep range is configured.
class _NextSessionContent extends StatelessWidget {
  final ({DateTime date, List<WorkoutSet> sets})? performance;
  final List<ProgramDayExercise> configs;
  final ThemeData theme;

  const _NextSessionContent({
    required this.performance,
    required this.configs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final perf = performance;
    if (perf == null) {
      return _Line('No previous workout data.', theme: theme, italic: true);
    }

    ProgramDayExercise? config;
    for (final c in configs) {
      if (c.minReps != null && c.maxReps != null && c.maxReps! >= c.minReps!) {
        config = c;
        break;
      }
    }
    if (config == null) {
      return _Line(
        'Set a rep range in your program to receive a progression suggestion.',
        theme: theme,
        italic: true,
      );
    }

    final suggestion = suggest(
      previousSets: perf.sets,
      targetSets: config.targetSets,
      minReps: config.minReps,
      maxReps: config.maxReps,
    );

    if (suggestion.outcome == ProgressionOutcome.insufficientData) {
      return _Line('Not enough data for progression.',
          theme: theme, italic: true);
    }

    final best = bestSet(perf.sets);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_graph_rounded, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(suggestion.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              if (best != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Previous: ${_weightNum(best.weight)} kg × ${best.reps} '
                    '${suggestion.avgRpe != null ? '· Avg RPE ${suggestion.avgRpe}' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              if (suggestion.targetSets != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Target: ${suggestion.targetSets} sets × '
                    '${suggestion.minReps}–${suggestion.maxReps} reps',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
            ],
          ),
        ),
        if (suggestion.outcome == ProgressionOutcome.increaseWeight)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Next session suggestion: '
              '${_weightNum(suggestion.suggestedWeight ?? 0)} kg × '
              '${suggestion.minReps}–${suggestion.maxReps} reps',
              style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800),
            ),
          ),
        const SizedBox(height: 6),
        Text('Advisory only — based on your recorded data. You decide what '
            'to do in your program.',
            style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }

  String _weightNum(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

class _Line extends StatelessWidget {
  final String text;
  final ThemeData theme;
  final bool italic;

  const _Line(this.text, {required this.theme, this.italic = false});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal));
  }
}