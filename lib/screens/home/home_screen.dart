import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_flow/core/extensions/date_extensions.dart';
import 'package:gym_flow/providers/app_providers.dart';
import 'package:gym_flow/providers/program_providers.dart';
import 'package:gym_flow/screens/home/widgets/daily_checkin_card.dart';
import 'package:gym_flow/screens/home/widgets/greeting_header.dart';
import 'package:gym_flow/screens/home/widgets/today_workout_card.dart';
import 'package:gym_flow/screens/home/widgets/weekly_progress_card.dart';
import 'package:gym_flow/screens/profile/notification_settings_screen.dart';

/// Home / Dashboard tab.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final userName = user.valueOrNull?.name ?? 'Athlete';
    final todayLabel = DateTime.now().displayFull;

    return Scaffold(
      appBar: AppBar(
        title: Text(todayLabel,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const NotificationSettingsScreen())),
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(refreshTriggerProvider.notifier).bump();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            GreetingHeader(userName: userName),
            const SizedBox(height: 24),
            const TodayWorkoutCard(),
            const SizedBox(height: 12),
            const DailyCheckInCard(),
            const SizedBox(height: 28),
            Text('Progress',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            const WeeklyProgressCard(),
          ],
        ),
      ),
    );
  }
}