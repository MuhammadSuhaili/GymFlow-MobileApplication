import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_flow/core/theme/app_theme.dart';
import 'package:gym_flow/models/exercise.dart';
import 'package:gym_flow/providers/data_providers.dart';
import 'package:gym_flow/providers/program_providers.dart';
import 'package:gym_flow/screens/programs/programs_screen.dart';
import 'package:gym_flow/screens/workout/workout_session_screen.dart';
import 'package:gym_flow/widgets/app_card.dart';

/// Today's scheduled workout card on the dashboard.
class TodayWorkoutCard extends ConsumerWidget {
  const TodayWorkoutCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final today = ref.watch(todayWorkoutProvider);
    final completed = ref.watch(completedTodayProvider);

    return AppCard(
      child: today.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, __) => Text('Failed to load schedule',
            style: theme.textTheme.bodySmall),
        data: (value) {
          if (value == null) {
            return _NoWorkoutCard(theme: theme);
          }
          if (value.day.isRest) {
            return _RestDay(theme: theme);
          }
          final alreadyCompleted = completed.valueOrNull != null;
          return _ScheduledWorkout(
            theme: theme,
            title: value.day.title,
            exercises: value.exercises,
            programId: value.program.id,
            workoutDayId: value.day.id,
            alreadyCompleted: alreadyCompleted,
          );
        },
      ),
    );
  }
}

class _NoWorkoutCard extends StatelessWidget {
  final ThemeData theme;
  const _NoWorkoutCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.event_busy_rounded,
            color: theme.colorScheme.onSurfaceVariant, size: 32),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Today\'s Workout',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('No active program yet.',
                  style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const ProgramsScreen())),
          child: const Text('Create Program'),
        ),
      ],
    );
  }
}

class _RestDay extends StatelessWidget {
  final ThemeData theme;
  const _RestDay({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          child: Icon(Icons.self_improvement_rounded,
              size: 20, color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Today\'s Workout',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('Rest day — recover well!',
                  style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScheduledWorkout extends StatelessWidget {
  final ThemeData theme;
  final String title;
  final List<Exercise> exercises;
  final String programId;
  final String workoutDayId;
  final bool alreadyCompleted;

  const _ScheduledWorkout({
    required this.theme,
    required this.title,
    required this.exercises,
    required this.programId,
    required this.workoutDayId,
    required this.alreadyCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Today\'s Workout',
                      style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(title,
                      style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800, letterSpacing: 1.1)),
                ],
              ),
            ),
            if (alreadyCompleted)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.successSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: AppColors.success, size: 16),
                    SizedBox(width: 4),
                    Text('Done',
                        style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (exercises.isNotEmpty)
          Text('${exercises.length} exercises • ${_muscles(exercises)}',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: alreadyCompleted
                ? null
                : () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => WorkoutSessionScreen(
                        programId: programId,
                        workoutDayId: workoutDayId,
                        title: title,
                      ),
                    ));
                  },
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(
                alreadyCompleted ? 'Workout Completed' : 'Start Workout'),
          ),
        ),
      ],
    );
  }

  String _muscles(List<Exercise> exercises) {
    final unique = exercises.map((e) => e.primaryMuscle).toSet();
    if (unique.length > 2) {
      return '${unique.take(2).join(' • ')} +${unique.length - 2}';
    }
    return unique.join(' • ');
  }
}