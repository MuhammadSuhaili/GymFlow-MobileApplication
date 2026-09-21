import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'package:gym_flow/data/database/seed_data.dart';

/// Singleton wrapper around the Sqflite database.
/// Uses the WASM-backed sqlite implementation on web so the same code runs
/// everywhere while keeping native `sqflite` on Android/iOS.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const int _version = 6;
  static const String dbName = 'gymflow.db';

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    if (kIsWeb) {
      await sqfliteFfiWebLoadSqlite3Wasm(SqfliteFfiWebOptions());
      databaseFactory = databaseFactoryFfiWeb;
    }

    final dbPath = kIsWeb
        ? dbName
        : join(await _getDatabasesPath(), dbName);

    return databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _version,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          final batch = db.batch();
          _createAll(batch);
          await batch.commit(noResult: true);
          await _seed(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('''
              CREATE TABLE workout_drafts (
                id TEXT PRIMARY KEY,
                program_id TEXT,
                workout_day_id TEXT,
                title TEXT NOT NULL,
                started_at TEXT NOT NULL,
                data TEXT NOT NULL
              )
            ''');
          }
          if (oldVersion < 3) {
            await db.execute(
                'ALTER TABLE body_measurements ADD COLUMN hips_cm REAL');
            await db.execute(
                'ALTER TABLE body_measurements ADD COLUMN notes TEXT');
            await db.execute(
                'ALTER TABLE body_measurements ADD COLUMN created_at TEXT');
          }
          if (oldVersion < 4) {
            // Optional per-exercise target configuration for progression.
            await db.execute(
                'ALTER TABLE workout_day_exercises ADD COLUMN target_sets INTEGER');
            await db.execute(
                'ALTER TABLE workout_day_exercises ADD COLUMN min_reps INTEGER');
            await db.execute(
                'ALTER TABLE workout_day_exercises ADD COLUMN max_reps INTEGER');
            await db.execute(
                'ALTER TABLE workout_day_exercises ADD COLUMN starting_weight REAL');
            await db.execute(
                'ALTER TABLE workout_day_exercises ADD COLUMN notes TEXT');
            // Notification reminders. Existing installs never had this table
            // created in onCreate, so it must be added here.
            await db.execute('''
              CREATE TABLE IF NOT EXISTS notification_settings (
                id TEXT PRIMARY KEY,
                type TEXT NOT NULL UNIQUE,
                enabled INTEGER NOT NULL DEFAULT 0,
                hour INTEGER NOT NULL,
                minute INTEGER NOT NULL,
                label TEXT
              )
            ''');
          }
          if (oldVersion < 5) {
            // Stress was folded into mood; drop the now-unused column.
            await db.execute(
                'ALTER TABLE daily_checkins DROP COLUMN stress');
          }
          if (oldVersion < 6) {
            // Attach demo video URLs to the pre-seeded exercise library.
            for (final entry in SeedData.videoUrls.entries) {
              await db.update(
                'exercises',
                {'video_url': entry.value},
                where: 'id = ?',
                whereArgs: [entry.key],
              );
            }
          }
        },
      ),
    );
  }

  Future<String> _getDatabasesPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  void _createAll(Batch batch) {
    batch.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        height_cm REAL NOT NULL,
        weight_kg REAL NOT NULL,
        goal TEXT NOT NULL,
        experience TEXT NOT NULL,
        unit_system TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE programs (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        duration_weeks INTEGER NOT NULL,
        goal TEXT NOT NULL,
        template_name TEXT,
        is_active INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE program_weeks (
        id TEXT PRIMARY KEY,
        program_id TEXT NOT NULL,
        week_number INTEGER NOT NULL,
        month_number INTEGER NOT NULL,
        name TEXT NOT NULL,
        FOREIGN KEY (program_id) REFERENCES programs(id) ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE workout_days (
        id TEXT PRIMARY KEY,
        program_id TEXT NOT NULL,
        week_id TEXT NOT NULL,
        day_of_week INTEGER NOT NULL,
        title TEXT NOT NULL,
        is_rest INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (program_id) REFERENCES programs(id) ON DELETE CASCADE,
        FOREIGN KEY (week_id) REFERENCES program_weeks(id) ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE exercises (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        primary_muscle TEXT NOT NULL,
        secondary_muscle TEXT NOT NULL,
        equipment TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        instructions TEXT,
        video_url TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE workout_day_exercises (
        id TEXT PRIMARY KEY,
        workout_day_id TEXT NOT NULL,
        exercise_id TEXT NOT NULL,
        order_index INTEGER NOT NULL,
        target_sets INTEGER,
        min_reps INTEGER,
        max_reps INTEGER,
        starting_weight REAL,
        notes TEXT,
        FOREIGN KEY (workout_day_id) REFERENCES workout_days(id) ON DELETE CASCADE,
        FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE workout_sessions (
        id TEXT PRIMARY KEY,
        program_id TEXT,
        workout_day_id TEXT,
        title TEXT NOT NULL,
        date TEXT NOT NULL,
        start_time TEXT,
        end_time TEXT,
        duration_minutes INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'completed',
        notes TEXT,
        total_volume_kg REAL NOT NULL DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE workout_sets (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        exercise_ref_id TEXT NOT NULL,
        exercise_name TEXT NOT NULL,
        order_index INTEGER NOT NULL,
        weight REAL NOT NULL,
        reps INTEGER NOT NULL,
        rpe INTEGER,
        completed INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (session_id) REFERENCES workout_sessions(id) ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE workout_drafts (
        id TEXT PRIMARY KEY,
        program_id TEXT,
        workout_day_id TEXT,
        title TEXT NOT NULL,
        started_at TEXT NOT NULL,
        data TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE daily_checkins (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL UNIQUE,
        mood INTEGER NOT NULL,
        energy INTEGER NOT NULL,
        sleep_hours INTEGER NOT NULL,
        sleep_minutes INTEGER NOT NULL,
        sleep_quality INTEGER NOT NULL,
        soreness INTEGER NOT NULL,
        motivation INTEGER NOT NULL,
        weight_kg REAL,
        notes TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE body_measurements (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        weight_kg REAL,
        body_fat REAL,
        chest_cm REAL,
        waist_cm REAL,
        arm_cm REAL,
        thigh_cm REAL,
        hips_cm REAL,
        notes TEXT,
        created_at TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE notification_settings (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL UNIQUE,
        enabled INTEGER NOT NULL DEFAULT 0,
        hour INTEGER NOT NULL,
        minute INTEGER NOT NULL,
        label TEXT
      )
    ''');
  }

  Future<void> _seed(Database db) async {
    final batch = db.batch();
    for (final exercise in SeedData.exercises) {
      final row = exercise.toMap();
      final videoUrl = SeedData.videoUrlFor(exercise.id);
      if (videoUrl != null) row['video_url'] = videoUrl;
      batch.insert('exercises', row);
    }
    await batch.commit(noResult: true);

    // Default user profile.
    await db.insert(
      'users',
      UserSeed.defaultUser.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}