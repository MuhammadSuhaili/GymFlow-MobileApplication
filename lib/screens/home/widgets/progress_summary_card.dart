import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_flow/core/utils/formatters.dart';
import 'package:gym_flow/providers/data_providers.dart';
import 'package:gym_flow/screens/progress/progress_screen.dart';
import 'package:gym_flow/widgets/section_card.dart';

/// Compact progress summary on the dashboard with a link to the full
/// Progress screen.
class ProgressSummaryCard extends ConsumerWidget {
  const ProgressSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final week = ref.watch(thisWeekStatsProvider);
    final streak = ref.watch(streakProvider);

    final workouts = week.valueOrNull?.workouts ?? 0;
    final volume = week.valueOrNull?.volume ?? 0;
    final streakValue = streak.valueOrNull?.current ?? 0;

    return SectionCard(
      title: 'Progress',
      subtitle: 'Your recent activity at a glance.',
      trailing: FilledButton.tonal(
        onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProgressScreen())),
        child: const Text('View Progress'),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat(context, '$workouts', 'Workouts this week'),
          _divider(theme),
          _stat(context, Formatters.volumeKg(volume), 'Volume'),
          _divider(theme),
          _stat(context, '$streakValue-day', 'Streak'),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value,
            style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary)),
        const SizedBox(height: 2),
        Text(label,
            style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _divider(ThemeData theme) => Container(
        width: 1,
        height: 30,
        color: theme.colorScheme.outlineVariant,
      );
}