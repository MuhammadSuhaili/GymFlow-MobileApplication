import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_flow/models/notification_setting.dart';
import 'package:gym_flow/providers/app_providers.dart';
import 'package:gym_flow/providers/settings_providers.dart';
import 'package:gym_flow/widgets/app_card.dart';

/// Notification reminder settings: enable/disable each reminder and pick
/// the daily time. Scheduling is a no-op on web, so this screen works
/// everywhere while notifications only fire on Android/iOS.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  static String timeLabel(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(notificationSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: settings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load settings: $e')),
        data: (items) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(
              'Choose when GymFlow reminds you. Reminders are scheduled '
              'locally on Android and iOS, and are disabled on the web.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            for (final setting in items) ...[
              _NotificationTile(setting: setting),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final NotificationSetting setting;

  const _NotificationTile({required this.setting});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              _iconFor(setting.type),
              color: theme.colorScheme.primary,
            ),
            title: Text(
              setting.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(setting.description),
            trailing: Switch(
              value: setting.enabled,
              onChanged: (v) => _toggle(context, ref, v),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule_rounded),
            title: const Text('Time'),
            subtitle: Text(
              NotificationSettingsScreen.timeLabel(setting.hour, setting.minute),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _pickTime(context, ref),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.workout:
        return Icons.fitness_center_rounded;
      case NotificationType.dailyCheckIn:
        return Icons.check_circle_outline_rounded;
      case NotificationType.rest:
        return Icons.self_improvement_rounded;
      case NotificationType.schedule:
        return Icons.calendar_month_rounded;
    }
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool enabled) async {
    final repo = ref.read(settingsRepositoryProvider);
    if (enabled) {
      await repo.requestNotificationPermission();
    }
    await repo.updateNotificationSetting(setting.copyWith(enabled: enabled));
    ref.read(refreshTriggerProvider.notifier).bump();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        enabled
            ? '${setting.title} enabled at '
                '${NotificationSettingsScreen.timeLabel(setting.hour, setting.minute)}'
            : '${setting.title} disabled',
      ),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: setting.hour, minute: setting.minute),
    );
    if (picked == null || !context.mounted) return;
    final repo = ref.read(settingsRepositoryProvider);
    await repo.updateNotificationSetting(
      setting.copyWith(hour: picked.hour, minute: picked.minute),
    );
    ref.read(refreshTriggerProvider.notifier).bump();
  }
}