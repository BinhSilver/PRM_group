import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // Tên các bảng (Tránh lặp lại logic chuỗi)
  static const String tableTransactions = 'transactions';
  static const String tableCategories = 'categories';
  static const String tableUsers = 'users';
  static const String tableBudgets = 'budgets';

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('money_manager.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await _createDB(db, version);
        await _seedData(db); // Thêm dữ liệu mẫu
      },
      onConfigure: _onConfigure,
    );
  }

  // Chèn dữ liệu mẫu ban đầu
  Future _seedData(Database db) async {
    // Thêm User mẫu
    await db.insert(tableUsers, {
      'id': 1,
      'username': 'testuser',
      'password': '123',
      'displayName': 'Người dùng thử nghiệm'
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    await seedDefaultCategories(userId: 1, db: db);
  }

  Future<void> seedDefaultCategories({required int userId, Database? db}) async {
    final executor = db ?? await database;
    
    final defaultCategories = [
      // Chi tiêu (Expenses)
      {'name': 'Ăn uống', 'type': 'expense', 'icon': 'restaurant', 'userId': userId},
      {'name': 'Di chuyển', 'type': 'expense', 'icon': 'directions_car', 'userId': userId},
      {'name': 'Mua sắm', 'type': 'expense', 'icon': 'shopping_cart', 'userId': userId},
      {'name': 'Giải trí', 'type': 'expense', 'icon': 'movie', 'userId': userId},
      {'name': 'Sức khỏe', 'type': 'expense', 'icon': 'medical_services', 'userId': userId},
      {'name': 'Giáo dục', 'type': 'expense', 'icon': 'school', 'userId': userId},
      {'name': 'Hóa đơn', 'type': 'expense', 'icon': 'receipt_long', 'userId': userId},
      {'name': 'Nhà cửa', 'type': 'expense', 'icon': 'home', 'userId': userId},
      {'name': 'Du lịch', 'type': 'expense', 'icon': 'flight', 'userId': userId},
      {'name': 'Gia đình', 'type': 'expense', 'icon': 'family_restroom', 'userId': userId},
      {'name': 'Khác', 'type': 'expense', 'icon': 'more_horiz', 'userId': userId},

      // Thu nhập (Income)
      {'name': 'Lương', 'type': 'income', 'icon': 'payments', 'userId': userId},
      {'name': 'Tiền thưởng', 'type': 'income', 'icon': 'card_giftcard', 'userId': userId},
      {'name': 'Làm thêm', 'type': 'income', 'icon': 'work', 'userId': userId},
      {'name': 'Kinh doanh', 'type': 'income', 'icon': 'storefront', 'userId': userId},
      {'name': 'Đầu tư', 'type': 'income', 'icon': 'trending_up', 'userId': userId},
      {'name': 'Hoàn tiền', 'type': 'income', 'icon': 'assignment_return', 'userId': userId},
      {'name': 'Khác', 'type': 'income', 'icon': 'add_card', 'userId': userId},
    ];

    for (final category in defaultCategories) {
      await executor.insert(
        tableCategories,
        category,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  // Bật tính năng khóa ngoại (Foreign Keys)
  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _createDB(Database db, int version) async {
    // 1. Bảng users
    await db.execute('''
      CREATE TABLE $tableUsers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        displayName TEXT,
        createdAt TEXT
      )
    ''');

    // 2. Bảng categories
    await db.execute('''
      CREATE TABLE $tableCategories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT,
        userId INTEGER,
        FOREIGN KEY (userId) REFERENCES $tableUsers(id) ON DELETE CASCADE,
        UNIQUE(name, type, userId)
      )
    ''');

    // 3. Bảng transactions
    await db.execute('''
      CREATE TABLE $tableTransactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        categoryId INTEGER,
        note TEXT,
        date TEXT NOT NULL,
        userId INTEGER NOT NULL,
        FOREIGN KEY (categoryId) REFERENCES $tableCategories(id) ON DELETE SET NULL,
        FOREIGN KEY (userId) REFERENCES $tableUsers(id) ON DELETE CASCADE
      )
    ''');

    // 4. Bảng budgets
    await db.execute('''
      CREATE TABLE $tableBudgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        month TEXT NOT NULL,
        amount REAL NOT NULL,
        userId INTEGER NOT NULL,
        FOREIGN KEY (userId) REFERENCES $tableUsers(id) ON DELETE CASCADE
      )
    ''');
  }

  // --- CRUD TRANSACTIONS ---

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    return await db.insert(tableTransactions, transaction.toMap());
  }

  Future<List<TransactionModel>> getTransactionsByUser(int userId) async {
    final db = await instance.database;
    final maps = await db.query(
      tableTransactions,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );

    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<TransactionModel?> getTransactionById(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      tableTransactions,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return TransactionModel.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    return await db.update(
      tableTransactions,
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete(
      tableTransactions,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- CRUD CATEGORIES ---
  Future<List<Map<String, dynamic>>> getCategoriesByType(String type, int userId) async {
    final db = await instance.database;
    return await db.query(
      tableCategories,
      where: 'type = ? AND userId = ?',
      whereArgs: [type, userId],
      orderBy: 'id ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllCategories() async {
    final db = await instance.database;
    return await db.query(tableCategories);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
