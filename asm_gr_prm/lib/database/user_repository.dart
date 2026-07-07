import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'database_helper.dart';

class UserRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ───────────── Đọc User ─────────────

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

  /// Kiểm tra username đã tồn tại chưa.
  Future<bool> isUsernameExists(String username) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'users',
      columns: ['id'],
      where: 'username = ?',
      whereArgs: [username.trim().toLowerCase()],
    );
    return maps.isNotEmpty;
  }

  // ───────────── Đăng ký ─────────────

  /// Đăng ký người dùng mới. Trả về [UserModel] nếu thành công.
  /// Ném [AuthException] nếu có lỗi.
  Future<UserModel> registerUser({
    required String username,
    required String password,
    required String displayName,
  }) async {
    // --- Validate đầu vào ---
    final trimmedDisplay = displayName.trim();
    if (trimmedDisplay.isEmpty) {
      throw AuthException('Tên hiển thị không được để trống.');
    }
    if (trimmedDisplay.length < 2) {
      throw AuthException('Tên hiển thị phải có ít nhất 2 ký tự.');
    }

    final normalizedUsername = username.trim().toLowerCase();
    if (normalizedUsername.isEmpty) {
      throw AuthException('Tên đăng nhập không được để trống.');
    }
    if (normalizedUsername.length < 3) {
      throw AuthException('Tên đăng nhập phải có ít nhất 3 ký tự.');
    }
    if (!RegExp(r'^[a-zA-Z0-9_\.]+').hasMatch(normalizedUsername)) {
      throw AuthException('Tên đăng nhập chỉ được chứa chữ cái, số, dấu _ hoặc .');
    }
    if (password.isEmpty) {
      throw AuthException('Mật khẩu không được để trống.');
    }
    if (password.length < 6) {
      throw AuthException('Mật khẩu phải có ít nhất 6 ký tự.');
    }

    // --- Kiểm tra trùng username ---
    final exists = await isUsernameExists(normalizedUsername);
    if (exists) {
      throw AuthException('Tên đăng nhập "$normalizedUsername" đã được sử dụng. Vui lòng chọn tên khác.');
    }

    final passwordHash = AuthService.hashPassword(password);
    final now = DateTime.now();

    final db = await _dbHelper.database;
    final id = await db.insert('users', {
      'username': normalizedUsername,
      'password': passwordHash,
      'displayName': trimmedDisplay,
      'createdAt': now.toIso8601String(),
    });

    return UserModel(
      id: id,
      username: normalizedUsername,
      displayName: trimmedDisplay,
      createdAt: now,
    );
  }


  // ───────────── Đăng nhập ─────────────

  /// Đăng nhập. Trả về [UserModel] nếu thành công.
  /// Ném [AuthException] nếu sai username hoặc password.
  Future<UserModel> loginUser({
    required String username,
    required String password,
  }) async {
    final normalizedUsername = username.trim().toLowerCase();
    final db = await _dbHelper.database;

    final maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [normalizedUsername],
    );

    if (maps.isEmpty) {
      throw AuthException('Tên đăng nhập không tồn tại.');
    }

    final storedHash = maps.first['password'] as String? ?? '';

    // Kiểm tra guest user (mật khẩu rỗng)
    if (storedHash.isEmpty) {
      throw AuthException('Tài khoản này chưa thiết lập mật khẩu.');
    }

    final isValid = AuthService.verifyPassword(password, storedHash);
    if (!isValid) {
      throw AuthException('Mật khẩu không chính xác.');
    }

    return UserModel.fromMap(maps.first);
  }

  // ───────────── Cập nhật ─────────────

  Future<void> updateDisplayName(int userId, String displayName) async {
    final db = await _dbHelper.database;
    await db.update(
      'users',
      {'displayName': displayName},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Đổi mật khẩu. Ném [AuthException] nếu mật khẩu cũ sai.
  Future<void> updatePassword({
    required int userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'users',
      columns: ['password'],
      where: 'id = ?',
      whereArgs: [userId],
    );
    if (maps.isEmpty) throw AuthException('Người dùng không tồn tại.');

    final storedHash = maps.first['password'] as String? ?? '';
    final isValid = AuthService.verifyPassword(oldPassword, storedHash);
    if (!isValid) throw AuthException('Mật khẩu hiện tại không chính xác.');

    final newHash = AuthService.hashPassword(newPassword);
    await db.update(
      'users',
      {'password': newHash},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // ───────────── Legacy (Guest) ─────────────

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
}

/// Exception cho các lỗi xác thực.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}