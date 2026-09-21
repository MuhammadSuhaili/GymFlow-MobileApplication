import 'package:gym_flow/data/database/app_database.dart';
import 'package:gym_flow/models/body_measurement.dart';
import 'package:sqflite/sqflite.dart';

class MeasurementRepository {
  final AppDatabase _db;

  MeasurementRepository(this._db);

  Future<List<BodyMeasurement>> getAll() async {
    final db = await _db.database;
    final rows =
        await db.query('body_measurements', orderBy: 'date ASC');
    return rows.map(BodyMeasurement.fromMap).toList();
  }

  Future<BodyMeasurement?> latest() async {
    final db = await _db.database;
    final rows = await db.query(
      'body_measurements',
      orderBy: 'date DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BodyMeasurement.fromMap(rows.first);
  }

  Future<void> save(BodyMeasurement measurement) async {
    final db = await _db.database;
    final map = measurement.toMap();
    if (map['created_at'] == null) {
      map['created_at'] = DateTime.now().toIso8601String();
    }
    await db.insert(
      'body_measurements',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('body_measurements', where: 'id = ?', whereArgs: [id]);
  }
}