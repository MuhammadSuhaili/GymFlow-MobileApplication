import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_flow/core/extensions/date_extensions.dart';
import 'package:gym_flow/providers/data_providers.dart';
import 'package:gym_flow/providers/program_providers.dart';
import 'package:gym_flow/screens/exercises/exercise_library_screen.dart';
import 'package:gym_flow/screens/workout/history_screen.dart';
import 'package:gym_flow/screens/workout/workout_session_screen.dart';
import 'package:gym_flow/widgets/app_card.dart';

/// Workout tab: today's session plus quick actions.
class WorkoutTodayScreen extends ConsumerWidget {
  const WorkoutTodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final today = ref.watch(todayWorkoutProvider);
    final completed = ref.watch(completedTodayProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Workout')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          today.when(
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: LinearProgressIndicator(),
              ),
            ),
            error: (_, __) => Text('Failed to load',
                style: theme.textTheme.bodySmall),
            data: (value) {
              if (value == null) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Create an active program to start training.'),
                  ),
                );
              }
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateTime.now().displayWeekday,
                        style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(
                      value.day.isRest ? 'Rest Day' : value.day.title,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    if (!value.day.isRest)
                      Text(
                        '${value.exercises.length} exercises scheduled',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: value.day.isRest ||
                                completed.valueOrNull != null
                            ? null
                            : () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => WorkoutSessionScreen(
                                    programId: value.program.id,
                                    workoutDayId: value.day.id,
                                    title: value.day.title,
                                  ),
                                ));
                              },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(
                          value.day.isRest
                              ? 'Rest Day'
                              : completed.valueOrNull != null
                                  ? 'Workout Completed'
                                  : 'Start Workout',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text('Quick Actions',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          AppCard(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const HistoryScreen())),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.history_rounded,
                  color: theme.colorScheme.primary),
              title: const Text('Workout History'),
              subtitle: const Text('View past sessions and details'),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
          const SizedBox(height: 10),
          AppCard(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ExerciseLibraryScreen())),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.menu_book_rounded,
                  color: theme.colorScheme.primary),
              title: const Text('Exercise Library'),
              subtitle: const Text('Explore movements and instructions'),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
        ],
      ),
    );
  }
}