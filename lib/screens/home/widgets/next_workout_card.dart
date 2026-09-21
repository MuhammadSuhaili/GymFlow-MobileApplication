import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_flow/core/utils/formatters.dart';
import 'package:gym_flow/providers/program_providers.dart';
import 'package:gym_flow/screens/programs/program_detail_screen.dart';
import 'package:gym_flow/services/progression_service.dart';
import 'package:gym_flow/widgets/app_card.dart';

/// Compact "Next Workout" preview showing the previous performance of today's
/// scheduled exercise and (when configured) the next progression suggestion.
/// View-only — never starts a workout automatically.
class NextWorkoutCard extends ConsumerWidget {
  const NextWorkoutCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final today = ref.watch(todayWorkoutProvider);
    final items = ref.watch(nextWorkoutProvider);

    final itemList = items.valueOrNull ?? const <NextWorkoutItem>[];
    if (itemList.isEmpty) return const SizedBox.shrink();

    NextWorkoutItem item = itemList.first;
    for (final i in itemList) {
      if (i.hasSuggestion && i.suggestion != null) {
        item = i;
        break;
      }
    }

    final suggestion = item.suggestion;
    final program = today.valueOrNull?.program;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Next Workout',
              style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.fitness_center_rounded, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(item.exercise.name,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (item.previousBestWeight != null)
            Text(
              'Previous: ${Formatters.weightKg(item.previousBestWeight!)} × '
              '${item.previousBestReps}',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
          if (suggestion != null &&
              suggestion.outcome == ProgressionOutcome.increaseWeight)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Suggested: ${_weightNum(suggestion.suggestedWeight ?? 0)} kg '
                '× ${suggestion.minReps}–${suggestion.maxReps}',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700),
              ),
            )
          else if (suggestion != null &&
              suggestion.outcome != ProgressionOutcome.noTargetRange &&
              suggestion.outcome != ProgressionOutcome.noPreviousData)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(suggestion.message,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: program == null
                  ? null
                  : () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            ProgramDetailScreen(program: program),
                      )),
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('View Workout'),
            ),
          ),
        ],
      ),
    );
  }

  String _weightNum(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}