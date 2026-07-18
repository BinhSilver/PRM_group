import '../models/spending_jar_model.dart';
import 'database_helper.dart';

class SpendingJarRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insertJar(SpendingJarModel jar) async {
    final db = await _dbHelper.database;
    return db.insert(DatabaseHelper.tableSpendingJars, jar.toMap());
  }

  Future<int> updateJar(SpendingJarModel jar) async {
    final db = await _dbHelper.database;
    return db.update(
      DatabaseHelper.tableSpendingJars,
      jar.toMap(),
      where: 'id = ?',
      whereArgs: [jar.id],
    );
  }

  Future<int> deleteJar(int id) async {
    final db = await _dbHelper.database;
    return db.delete(
      DatabaseHelper.tableSpendingJars,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<SpendingJarModel?> getJarById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableSpendingJars,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return SpendingJarModel.fromMap(maps.first);
  }

  Future<List<SpendingJarModel>> getJarsByMonth(
    int userId,
    String month,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableSpendingJars,
      where: 'userId = ? AND month = ?',
      whereArgs: [userId, month],
      orderBy: 'id ASC',
    );

    return maps.map((map) => SpendingJarModel.fromMap(map)).toList();
  }

  Future<double> getAllocatedAmount(
    int userId,
    String month, {
    int? excludeJarId,
  }) async {
    final db = await _dbHelper.database;
    var where = 'userId = ? AND month = ?';
    final args = <Object?>[userId, month];

    if (excludeJarId != null) {
      where += ' AND id != ?';
      args.add(excludeJarId);
    }

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM ${DatabaseHelper.tableSpendingJars}
      WHERE $where
      ''', args);

    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<bool> hasJarForCategory(
    int userId,
    String month,
    int categoryId, {
    int? excludeJarId,
  }) async {
    final db = await _dbHelper.database;
    var where = 'userId = ? AND month = ? AND categoryId = ?';
    final args = <Object?>[userId, month, categoryId];

    if (excludeJarId != null) {
      where += ' AND id != ?';
      args.add(excludeJarId);
    }

    final result = await db.rawQuery('''
      SELECT COUNT(*) AS count
      FROM ${DatabaseHelper.tableSpendingJars}
      WHERE $where
      ''', args);

    final count = result.first['count'] as int? ?? 0;
    return count > 0;
  }

  Future<Map<int, double>> getSpentByJar(List<SpendingJarModel> jars) async {
    final spentByJar = <int, double>{};
    final db = await _dbHelper.database;

    for (final jar in jars) {
      final jarId = jar.id;
      final categoryId = jar.categoryId;
      if (jarId == null) continue;

      if (categoryId == null) {
        spentByJar[jarId] = 0;
        continue;
      }

      final result = await db.rawQuery(
        '''
        SELECT COALESCE(SUM(amount), 0) AS total
        FROM ${DatabaseHelper.tableTransactions}
        WHERE userId = ?
          AND categoryId = ?
          AND type = ?
          AND strftime('%Y-%m', date) = ?
        ''',
        [jar.userId, categoryId, 'expense', jar.month],
      );

      spentByJar[jarId] = (result.first['total'] as num?)?.toDouble() ?? 0;
    }

    return spentByJar;
  }
}
