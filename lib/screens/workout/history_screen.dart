import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_flow/core/extensions/date_extensions.dart';
import 'package:gym_flow/core/utils/formatters.dart';
import 'package:gym_flow/data/repositories/workout_repository.dart';
import 'package:gym_flow/providers/data_providers.dart';
import 'package:gym_flow/screens/workout/history_detail_screen.dart';
import 'package:gym_flow/widgets/empty_state.dart';

/// Workout history grouped by date.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final history = ref.watch(workoutHistoryDetailedProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Workout History')),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.history_rounded,
              title: 'No workout history yet.',
              message:
                  'Finish your first workout and it will show up here.',
            );
          }
          final grouped = <String, List<WorkoutHistoryItem>>{};
          for (final item in items) {
            final key = item.session.date.isoDate;
            grouped.putIfAbsent(key, () => []).add(item);
          }
          final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: dates.map((date) {
              final day = DateTime.parse(date);
              final itemsByDay = grouped[date]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Row(
                      children: [
                        Text(day.displayMonthDay,
                            style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800)),
                        const SizedBox(width: 8),
                        Text(day.displayWeekday,
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  ...itemsByDay.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SessionTile(item: item),
                      )),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final WorkoutHistoryItem item;

  const _SessionTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = item.session;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.fitness_center_rounded,
              color: theme.colorScheme.primary, size: 22),
        ),
        title: Text(session.title,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          Formatters.duration(session.durationMinutes)
          + ' • ${item.completedSets} sets'
          + ' • ${Formatters.volumeKg(session.totalVolumeKg)}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) =>
                HistoryDetailScreen(sessionId: session.id))),
      ),
    );
  }
}