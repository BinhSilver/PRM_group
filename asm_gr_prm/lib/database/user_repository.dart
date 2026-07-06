import '../models/user_model.dart';
import 'database_helper.dart';

class UserRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<UserModel?> getUserById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<UserModel?> getUserByUsername(String username) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<UserModel> getOrCreateDefaultUser() async {
    final existing = await getUserByUsername('guest');
    if (existing != null) return existing;

    final db = await _dbHelper.database;
    final id = await db.insert('users', {
      'username': 'guest',
      'password': '',
      'displayName': 'Người dùng',
      'createdAt': DateTime.now().toIso8601String(),
    });

    return UserModel(
      id: id,
      username: 'guest',
      displayName: 'Người dùng',
      createdAt: DateTime.now(),
    );
  }

  Future<void> updateDisplayName(int userId, String displayName) async {
    final db = await _dbHelper.database;
    await db.update(
      'users',
      {'displayName': displayName},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}