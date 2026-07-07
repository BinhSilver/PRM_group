import '../models/transaction_model.dart';
import 'database_helper.dart';

class TransactionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await _dbHelper.database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<int> countTransactions(int userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM transactions WHERE userId = ?',
      [userId],
    );
    return result.first['count'] as int? ?? 0;
  }

  Future<List<TransactionModel>> getTransactions(
    int userId, {
    String? search,
    String? type,
    int? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy = 'date',
    String? sortOrder = 'DESC',
  }) async {
    final db = await _dbHelper.database;

    String whereClause = 'userId = ?';
    List<dynamic> whereArgs = [userId];

    if (search != null && search.isNotEmpty) {
      whereClause += ' AND (title LIKE ? OR note LIKE ?)';
      whereArgs.add('%$search%');
      whereArgs.add('%$search%');
    }

    if (type != null) {
      whereClause += ' AND type = ?';
      whereArgs.add(type);
    }

    if (categoryId != null) {
      whereClause += ' AND categoryId = ?';
      whereArgs.add(categoryId);
    }

    if (startDate != null) {
      whereClause += ' AND date >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClause += ' AND date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: '$sortBy $sortOrder',
    );

    return List.generate(maps.length, (i) {
      return TransactionModel.fromMap(maps[i]);
    });
  }

  Future<TransactionModel?> getTransaction(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return TransactionModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await _dbHelper.database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, double>> getFinancialSummary(
    int userId, {
    String? month,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _dbHelper.database;

    String whereClause = 'userId = ?';
    List<dynamic> whereArgs = [userId];

    if (month != null) {
      whereClause += " AND strftime('%Y-%m', date) = ?";
      whereArgs.add(month);
    }

    if (startDate != null) {
      whereClause += ' AND date >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClause += ' AND date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final List<Map<String, dynamic>> incomeResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE $whereClause AND type = ?',
      [...whereArgs, 'income'],
    );

    final List<Map<String, dynamic>> expenseResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE $whereClause AND type = ?',
      [...whereArgs, 'expense'],
    );

    double totalIncome = incomeResult.first['total'] ?? 0.0;
    double totalExpense = expenseResult.first['total'] ?? 0.0;
    double balance = totalIncome - totalExpense;

    return {
      'income': totalIncome,
      'expense': totalExpense,
      'balance': balance,
    };
  }
}
