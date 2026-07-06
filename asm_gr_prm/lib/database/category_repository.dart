import '../models/category_model.dart';
import 'database_helper.dart';

class CategoryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insertCategory(CategoryModel category) async {
    final db = await _dbHelper.database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<CategoryModel>> getCategories(int userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'userId = ? OR userId IS NULL',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) {
      return CategoryModel.fromMap(maps[i]);
    });
  }

  Future<CategoryModel?> getCategoryById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return CategoryModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateCategory(CategoryModel category) async {
    final db = await _dbHelper.database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> insertDefaultCategories(int userId) async {
    final db = await _dbHelper.database;
    final List<CategoryModel> defaultCategories = [
      CategoryModel(
        name: 'Ăn uống',
        type: 'expense',
        icon: 'utensils',
        userId: userId,
      ),
      CategoryModel(
        name: 'Di chuyển',
        type: 'expense',
        icon: 'car',
        userId: userId,
      ),
      CategoryModel(
        name: 'Mua sắm',
        type: 'expense',
        icon: 'shopping-bag',
        userId: userId,
      ),
      CategoryModel(
        name: 'Giải trí',
        type: 'expense',
        icon: 'gamepad',
        userId: userId,
      ),
      CategoryModel(
        name: 'Y tế',
        type: 'expense',
        icon: 'stethoscope',
        userId: userId,
      ),
      CategoryModel(
        name: 'Lương',
        type: 'income',
        icon: 'money-bill-wave',
        userId: userId,
      ),
      CategoryModel(
        name: 'Thưởng',
        type: 'income',
        icon: 'gift',
        userId: userId,
      ),
      CategoryModel(
        name: 'Đầu tư',
        type: 'income',
        icon: 'chart-line',
        userId: userId,
      ),
    ];

    for (var category in defaultCategories) {
      await db.insert('categories', category.toMap());
    }
  }
}