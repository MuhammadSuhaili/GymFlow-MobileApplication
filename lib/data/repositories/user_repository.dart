import 'package:gym_flow/data/database/app_database.dart';
import 'package:gym_flow/models/user.dart';
import 'package:sqflite/sqflite.dart';

class UserRepository {
  final AppDatabase _db;

  UserRepository(this._db);

  Future<User> getUser() async {
    final db = await _db.database;
    final rows = await db.query('users', limit: 1);
    if (rows.isEmpty) {
      final user = User.defaults();
      await db.insert('users', user.toMap());
      return user;
    }
    return User.fromMap(rows.first);
  }

  Future<void> save(User user) async {
    final db = await _db.database;
    await db.insert('users', user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}