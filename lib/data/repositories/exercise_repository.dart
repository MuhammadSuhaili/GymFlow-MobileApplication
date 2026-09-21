import 'package:gym_flow/data/database/app_database.dart';
import 'package:gym_flow/models/exercise.dart';

class ExerciseRepository {
  final AppDatabase _db;

  ExerciseRepository(this._db);

  Future<List<Exercise>> getAll({String? muscleGroup}) async {
    final db = await _db.database;
    final rows = await db.query(
      'exercises',
      where: muscleGroup == null
          ? null
          : 'primary_muscle = ? OR secondary_muscle LIKE ?',
      whereArgs: muscleGroup == null
          ? null
          : [muscleGroup, '%$muscleGroup%'],
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map(Exercise.fromMap).toList();
  }

  Future<List<String>> getMuscleGroups() async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      'SELECT DISTINCT primary_muscle FROM exercises ORDER BY primary_muscle',
    );
    return rows
        .map((row) => row['primary_muscle'] as String)
        .where((g) => g.isNotEmpty)
        .toList();
  }

  Future<Exercise?> getById(String id) async {
    final db = await _db.database;
    final rows = await db.query('exercises', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Exercise.fromMap(rows.first);
  }
}