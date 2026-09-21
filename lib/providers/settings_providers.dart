import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_flow/core/constants/app_constants.dart';
import 'package:gym_flow/data/repositories/settings_repository.dart';
import 'package:gym_flow/models/notification_setting.dart';
import 'package:gym_flow/providers/app_providers.dart';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
    ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  Future<void> load() async {
    final repo = ref.read(settingsRepositoryProvider);
    state = await repo.getThemeMode();
  }

  Future<void> set(ThemeMode mode) async {
    await ref.read(settingsRepositoryProvider).setThemeMode(mode);
    state = mode;
  }
}

final unitSystemProvider = NotifierProvider<UnitSystemNotifier, String>(
    UnitSystemNotifier.new);

class UnitSystemNotifier extends Notifier<String> {
  @override
  String build() => unitSystems.first;

  Future<void> load() async {
    state = await ref.read(settingsRepositoryProvider).getUnitSystem();
  }

  Future<void> set(String unit) async {
    await ref.read(settingsRepositoryProvider).setUnitSystem(unit);
    state = unit;
  }
}

final notificationSettingsProvider =
    FutureProvider<List<NotificationSetting>>((ref) async {
  ref.watch(refreshTriggerProvider);
  return ref.read(settingsRepositoryProvider).getNotificationSettings();
});