import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_flow/providers/data_providers.dart';
import 'package:gym_flow/screens/checkin/check_in_screen.dart';
import 'package:gym_flow/widgets/app_card.dart';

/// Today's check-in status card on the dashboard.
class DailyCheckInCard extends ConsumerWidget {
  const DailyCheckInCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final checkin = ref.watch(todayCheckinProvider);

    return AppCard(
      onTap: () {
        Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CheckInScreen()));
      },
      child: checkin.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, __) => const Text('Failed to load check-in'),
        data: (value) {
          final done = value != null;
          return Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (done ? theme.colorScheme.tertiaryContainer
                          : theme.colorScheme.primary)
                      .withValues(alpha: 0.5),
                ),
                child: Icon(
                  done ? Icons.check_rounded : Icons.mood_rounded,
                  size: 20,
                  color: done
                      ? theme.colorScheme.tertiary
                      : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily Check-in',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      done
                          ? 'Today\'s check-in completed'
                          : 'How are you feeling today?',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          );
        },
      ),
    );
  }
}