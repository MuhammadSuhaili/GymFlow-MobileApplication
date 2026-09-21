import 'package:gym_flow/core/extensions/date_extensions.dart';
import 'package:gym_flow/data/database/app_database.dart';
import 'package:gym_flow/models/daily_check_in.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

enum CheckInFilter { today, thisWeek, thisMonth, all, custom }

class CheckInRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  CheckInRepository(this._db);

  Future<List<DailyCheckIn>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('daily_checkins', orderBy: 'date DESC');
    return rows.map(DailyCheckIn.fromMap).toList();
  }

  Future<List<DailyCheckIn>> getBetween(DateTime start, DateTime end) async {
    final db = await _db.database;
    final rows = await db.query(
      'daily_checkins',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [start.isoDate, end.isoDate],
      orderBy: 'date DESC',
    );
    return rows.map(DailyCheckIn.fromMap).toList();
  }

  Future<DailyCheckIn?> getByDate(DateTime date) async {
    final db = await _db.database;
    final rows = await db.query(
      'daily_checkins',
      where: 'date = ?',
      whereArgs: [date.isoDate],
    );
    if (rows.isEmpty) return null;
    return DailyCheckIn.fromMap(rows.first);
  }

  /// Inserts a new check-in for [date] or updates the existing one for that
  /// date (one check-in per day, always editable).
  Future<void> save(DailyCheckIn checkIn) async {
    final db = await _db.database;
    final existing = await getByDate(checkIn.date);
    await db.insert(
      'daily_checkins',
      checkIn.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if (existing == null && checkIn.weightKg != null) {
      // A checked-in weight is also tracked as a body measurement.
      final row = await db.query(
        'body_measurements',
        where: 'date = ?',
        whereArgs: [checkIn.date.isoDate],
      );
      if (row.isEmpty) {
        await db.insert('body_measurements', {
          'id': _uuid.v4(),
          'date': checkIn.date.isoDate,
          'weight_kg': checkIn.weightKg,
        });
      }
    }
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('daily_checkins', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> hasCheckedInToday() async =>
      await getByDate(DateTime.now()) != null;

  /// (value, count) of a rating field across a date range for averages.
  Future<double?> average(
      String column, DateTime start, DateTime end) async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT AVG($column) AS avg FROM daily_checkins
      WHERE date BETWEEN ? AND ?
    ''', [start.isoDate, end.isoDate]);
    return (result.first['avg'] as num?)?.toDouble();
  }

  Future<List<DailyCheckIn>> applyFilter(
      CheckInFilter filter, DateTime? customRange) {
    final now = DateTime.now();
    switch (filter) {
      case CheckInFilter.today:
        return getBetween(now.dateOnly, now.dateOnly);
      case CheckInFilter.thisWeek:
        return getBetween(now.startOfWeek, now.endOfWeek);
      case CheckInFilter.thisMonth:
        return getBetween(now.startOfMonth, now.endOfMonth);
      case CheckInFilter.all:
        return getAll();
      case CheckInFilter.custom:
        final range = customRange ?? now.dateOnly;
        return getBetween(range.dateOnly, range.dateOnly);
    }
  }
}