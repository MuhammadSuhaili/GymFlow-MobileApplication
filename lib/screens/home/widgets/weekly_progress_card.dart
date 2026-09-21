import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_flow/core/theme/app_theme.dart';
import 'package:gym_flow/core/utils/formatters.dart';
import 'package:gym_flow/providers/data_providers.dart';
import 'package:gym_flow/providers/program_providers.dart';
import 'package:gym_flow/widgets/section_card.dart';

/// Weekly workout completion + streak.
class WeeklyProgressCard extends ConsumerWidget {
  const WeeklyProgressCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progress = ref.watch(weeklyProgressProvider);
    final streak = ref.watch(streakProvider);

    return SectionCard(
      title: 'Weekly Progress',
      child: progress.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, __) => const Text('Failed to load progress'),
        data: (data) {
          final completed = data.$1;
          final target = data.$2;
          final percent = target == 0
              ? 0.0
              : (completed / target).clamp(0.0, 1.0).toDouble();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$completed / $target workouts',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Text(Formatters.percent(percent * 100),
                      style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 10,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              streak.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (s) => Row(
                  children: [
                    Icon(Icons.local_fire_department_rounded,
                        color: theme.colorScheme.primary, size: 18),
                    const SizedBox(width: 6),
                    Text('Current streak: ${s.current} days',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 16),
                    const Icon(Icons.emoji_events_outlined,
                        color: AppColors.gold, size: 18),
                    const SizedBox(width: 6),
                    Text('Best: ${s.best} days',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}