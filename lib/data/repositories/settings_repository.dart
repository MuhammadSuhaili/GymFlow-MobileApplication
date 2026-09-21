import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:gym_flow/core/constants/app_constants.dart';
import 'package:gym_flow/data/database/app_database.dart';
import 'package:gym_flow/models/notification_setting.dart';
import 'package:gym_flow/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class SettingsRepository {
  final AppDatabase _db;
  final shared = SharedPreferencesAsync();

  SettingsRepository(this._db);

  // ---- Theme & units (shared preferences) ----

  Future<ThemeMode> getThemeMode() async {
    final value = await shared.getString(PreferencesKeys.themeMode);
    return ThemeMode.values.firstWhere(
      (m) => m.name == value,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await shared.setString(PreferencesKeys.themeMode, mode.name);
  }

  Future<String> getUnitSystem() async {
    final value = await shared.getString(PreferencesKeys.unitSystem);
    return value ?? unitSystems.first;
  }

  Future<void> setUnitSystem(String unit) async {
    await shared.setString(PreferencesKeys.unitSystem, unit);
  }

  // ---- Notification settings ----

  Future<List<NotificationSetting>> getNotificationSettings() async {
    final db = await _db.database;
    final rows = await db.query('notification_settings', orderBy: 'hour');
    if (rows.isEmpty) {
      await _seedNotificationDefaults();
      return getNotificationSettings();
    }
    return rows.map(NotificationSetting.fromMap).toList();
  }

  Future<void> _seedNotificationDefaults() async {
    final db = await _db.database;
    const defaults = [
      NotificationSetting(
          id: 'n_workout', type: NotificationType.workout, enabled: false, hour: 17, minute: 0),
      NotificationSetting(
          id: 'n_checkin', type: NotificationType.dailyCheckIn, enabled: false, hour: 19, minute: 0),
      NotificationSetting(
          id: 'n_rest', type: NotificationType.rest, enabled: false, hour: 9, minute: 0),
      NotificationSetting(
          id: 'n_schedule', type: NotificationType.schedule, enabled: false, hour: 7, minute: 0),
    ];
    await db.transaction((txn) async {
      for (final setting in defaults) {
        await txn.insert('notification_settings', setting.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> updateNotificationSetting(NotificationSetting setting) async {
    final db = await _db.database;
    await db.insert(
      'notification_settings',
      setting.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if (setting.enabled) {
      await NotificationService.instance.scheduleDaily(
        id: setting.type.index + 100,
        title: setting.title,
        body: setting.description,
        hour: setting.hour,
        minute: setting.minute,
      );
    } else {
      await NotificationService.instance.cancel(setting.type.index + 100);
    }
  }

  Future<void> requestNotificationPermission() async {
    await NotificationService.instance.requestPermissions();
  }

  // ---- Data backup / reset ----

  static const _backupTables = [
    'users',
    'programs',
    'program_weeks',
    'workout_days',
    'workout_day_exercises',
    'exercises',
    'workout_sessions',
    'workout_sets',
    'daily_checkins',
    'body_measurements',
    'notification_settings',
  ];

  /// Exports the whole database as a JSON snapshot (used as a backup).
  Future<String> exportJson() async {
    final db = await _db.database;
    final snapshot = <String, List<Map<String, Object?>>>{};
    for (final table in _backupTables) {
      snapshot[table] = await db.query(table);
    }
    return jsonEncode({
      'exported_at': DateTime.now().toIso8601String(),
      'app': 'gym_flow',
      'data': snapshot,
    });
  }

  Future<void> resetAllData() async {
    final db = await _db.database;
    await db.transaction((txn) async {
      for (final table in [
        'workout_sets',
        'workout_sessions',
        'workout_day_exercises',
        'workout_days',
        'program_weeks',
        'programs',
        'daily_checkins',
        'body_measurements',
      ]) {
        await txn.delete(table);
      }
    });
    await NotificationService.instance.cancelAll();
  }
}