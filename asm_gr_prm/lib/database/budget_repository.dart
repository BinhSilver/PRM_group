import '../models/budget_model.dart';
import 'database_helper.dart';

class BudgetRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insertBudget(BudgetModel budget) async {
    final db = await _dbHelper.database;
    return await db.insert('budgets', budget.toMap());
  }

  Future<int> updateBudget(BudgetModel budget) async {
    final db = await _dbHelper.database;
    return await db.update(
      'budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  Future<int> deleteBudget(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  Future<BudgetModel?> getBudgetByMonth(int userId, String month) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'budgets',
      where: 'userId = ? AND month = ?',
      whereArgs: [userId, month],
    );
    if (maps.isNotEmpty) return BudgetModel.fromMap(maps.first);
    return null;
  }

  Future<List<BudgetModel>> getAllBudgets(int userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'budgets',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'month DESC',
    );
    return maps.map((m) => BudgetModel.fromMap(m)).toList();
  }
}
