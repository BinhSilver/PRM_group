import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dịch vụ xác thực: quản lý phiên đăng nhập và mã hóa mật khẩu.
class AuthService {
  static const _keyUserId = 'auth_user_id';
  static const _keyRememberMe = 'auth_remember_me';
  static const _keyUsername = 'auth_username';

  // ───────────── Password Hashing ─────────────

  /// Hash mật khẩu bằng SHA-256 chuẩn.
  /// Kết hợp với salt cố định để tăng bảo mật.
  static String hashPassword(String password) {
    const salt = 'flutter_money_app_salt_2026';
    final content = utf8.encode('$salt:$password:$salt');
    final digest = sha256.convert(content);
    return digest.toString(); // 64 ký tự hex, độ dài cố định
  }

  /// Kiểm tra mật khẩu có khớp với hash đã lưu không.
  static bool verifyPassword(String plainPassword, String storedHash) {
    final hash = hashPassword(plainPassword);
    return hash == storedHash;
  }

  // ───────────── Session Management ─────────────

  /// Lưu phiên đăng nhập sau khi đăng nhập thành công.
  Future<void> saveSession({
    required int userId,
    required String username,
    required bool rememberMe,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRememberMe, rememberMe);
    await prefs.setInt(_keyUserId, userId);
    await prefs.setString(_keyUsername, username);
  }

  /// Lấy userId đã lưu trong phiên.
  /// Trả về null nếu chưa đăng nhập hoặc không "remember me".
  Future<int?> getStoredUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_keyRememberMe) ?? false;
    if (!rememberMe) return null;
    return prefs.getInt(_keyUserId);
  }

  /// Lấy username đã lưu (dùng để pre-fill form login).
  Future<String?> getStoredUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  /// Lấy trạng thái "remember me".
  Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRememberMe) ?? false;
  }

  /// Xóa toàn bộ dữ liệu phiên (khi đăng xuất).
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyRememberMe);
    await prefs.remove(_keyUsername);
  }
}
