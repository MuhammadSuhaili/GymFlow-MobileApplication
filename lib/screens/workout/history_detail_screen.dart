import 'package:flutter/material.dart';
import 'package:gym_flow/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_flow/core/extensions/date_extensions.dart';
import 'package:gym_flow/core/utils/formatters.dart';
import 'package:gym_flow/models/workout_set.dart';
import 'package:gym_flow/providers/data_providers.dart';
import 'package:gym_flow/widgets/empty_state.dart';

/// Details of a past workout session (sets + notes).
class HistoryDetailScreen extends ConsumerWidget {
  final String sessionId;

  const HistoryDetailScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(sessionByIdProvider(sessionId));
    final sets = ref.watch(setsBySessionProvider(sessionId));

    return Scaffold(
      appBar: AppBar(title: const Text('Workout Details')),
      body: session.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed: $e')),
        data: (s) {
          if (s == null) {
            return const EmptyState(
                icon: Icons.search_off_rounded,
                title: 'Session not found',
                message: 'It may have been deleted.');
          }
          final grouped = <String, List<_SetRowData>>{};
          int totalReps = 0;
          for (final WorkoutSet workoutSet in sets.valueOrNull ?? const []) {
            if (workoutSet.completed) totalReps += workoutSet.reps;
            grouped
                .putIfAbsent(workoutSet.exerciseName, () => [])
                .add(_SetRowData(
                  index: workoutSet.orderIndex + 1,
                  weight: workoutSet.weight,
                  reps: workoutSet.reps,
                  rpe: workoutSet.rpe,
                  completed: workoutSet.completed,
                ));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.title,
                                    style: theme.textTheme.titleLarge
                                        ?.copyWith(
                                            fontWeight: FontWeight.w800)),
                                Text(s.date.displayFull,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme
                                            .colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          Text(Formatters.duration(s.durationMinutes),
                              style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.primary)),
                        ],
                      ),
                      const Divider(height: 24),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _Stat('Volume',
                              Formatters.volumeKg(s.totalVolumeKg)),
                          _Stat('Total Reps', '$totalReps'),
                          _Stat('Total Sets',
                              '${sets.valueOrNull?.length ?? 0}'),
                          _Stat('Exercises', '${grouped.length}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (s.notes != null && s.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notes',
                            style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(s.notes!,
                            style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              for (final entry in grouped.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.key,
                              style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          for (final row in entry.value)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 28,
                                    child: Text('${row.index}.',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                                fontWeight:
                                                    FontWeight.w700)),
                                  ),
                                  Text(
                                    '${Formatters.weightNum(row.weight)} kg × ${row.reps}'
                                    '${row.rpe != null ? ' | RPE ${row.rpe}' : ''}',
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            decoration: row.completed
                                                ? null
                                                : TextDecoration
                                                    .lineThrough),
                                  ),
                                  const Spacer(),
                                  if (row.completed)
                                    Icon(Icons.check_circle_rounded,
                                        color: AppColors.success, size: 18),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SetRowData {
  final int index;
  final double weight;
  final int reps;
  final int? rpe;
  final bool completed;

  const _SetRowData({
    required this.index,
    required this.weight,
    required this.reps,
    this.rpe,
    this.completed = true,
  });
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        Text(label,
            style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}