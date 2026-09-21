import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_flow/core/utils/formatters.dart';
import 'package:gym_flow/providers/data_providers.dart';
import 'package:gym_flow/providers/program_providers.dart';
import 'package:gym_flow/screens/profile/profile_screen.dart';
import 'package:gym_flow/widgets/stat_card.dart';

/// Quick stats row on the dashboard.
class QuickStatsCard extends ConsumerWidget {
  const QuickStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(userProvider);
    final history = ref.watch(workoutHistoryProvider);
    final streak = ref.watch(streakProvider);
    final week = ref.watch(thisWeekStatsProvider);

    final weight =
        user.valueOrNull?.weightKg ?? 0;
    final weeklyWorkouts =
        week.valueOrNull?.workouts ?? 0;
    final streakValue = streak.valueOrNull?.current ?? 0;
    final totalMin = history.valueOrNull
            ?.fold<int>(0, (sum, s) => sum + s.durationMinutes) ??
        0;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 2x2 grid of stats
            Expanded(
              child: Column(
                children: [
                  _StatTile(
                    label: 'Weight',
                    value: '${Formatters.weightKg(weight)}',
                    icon: Icons.monitor_weight_outlined,
                  ),
                  const SizedBox(height: 10),
                  _StatTile(
                    label: 'Streak',
                    value: '$streakValue days',
                    icon: Icons.local_fire_department_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                children: [
                  _StatTile(
                    label: 'Workouts',
                    value: '$weeklyWorkouts',
                    icon: Icons.fitness_center_rounded,
                  ),
                  const SizedBox(height: 10),
                  _StatTile(
                    label: 'Total Time',
                    value: Formatters.duration(totalMin),
                    icon: Icons.timer_outlined,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const ProfileScreen())),
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: Text('Update profile details',
                  style: theme.textTheme.labelMedium),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return StatCard(icon: icon, value: value, label: label, iconColor: color);
  }
}