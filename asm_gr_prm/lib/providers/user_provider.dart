import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/user_repository.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated }

class UserProvider extends ChangeNotifier {
  static const String _displayNameKey = 'displayName';
  static String _avatarBase64Key(int userId) => 'avatarBase64_$userId';

  final UserRepository _userRepository = UserRepository();
  final AuthService _authService = AuthService();

  AuthState _authState = AuthState.initial;
  UserModel? _currentUser;
  String? _avatarBase64;
  String? _errorMessage;

  // ───────────── Getters ─────────────

  AuthState get authState => _authState;
  UserModel? get currentUser => _currentUser;
  String? get avatarBase64 => _avatarBase64;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _authState == AuthState.authenticated;
  bool get isLoading => _authState == AuthState.loading;

  // ───────────── Auto-login ─────────────

  /// Kiểm tra phiên đã lưu khi khởi động app.
  Future<void> tryAutoLogin() async {
    _authState = AuthState.loading;
    notifyListeners();

    try {
      final userId = await _authService.getStoredUserId();
      if (userId == null) {
        _authState = AuthState.unauthenticated;
        notifyListeners();
        return;
      }

      final user = await _userRepository.getUserById(userId);
      if (user == null) {
        await _authService.clearSession();
        _authState = AuthState.unauthenticated;
        notifyListeners();
        return;
      }

      // Áp dụng displayName đã lưu local nếu có
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString(_displayNameKey);
      _avatarBase64 = prefs.getString(_avatarBase64Key(user.id));
      _currentUser = (savedName != null && savedName.trim().isNotEmpty)
          ? user.copyWith(displayName: savedName.trim())
          : user;

      _authState = AuthState.authenticated;
    } catch (e) {
      debugPrint('Auto-login error: $e');
      _authState = AuthState.unauthenticated;
    }

    notifyListeners();
  }

  // ───────────── Đăng ký ─────────────

  /// Đăng ký và tự động đăng nhập.
  /// Trả về null nếu thành công, trả về message lỗi nếu thất bại.
  Future<String?> register({
    required String username,
    required String password,
    required String displayName,
  }) async {
    _authState = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _userRepository.registerUser(
        username: username,
        password: password,
        displayName: displayName,
      );

      _currentUser = user;
      _avatarBase64 = null;
      _authState = AuthState.authenticated;

      // Lưu session (mặc định không remember sau đăng ký)
      await _authService.saveSession(
        userId: user.id,
        username: user.username,
        rememberMe: false,
      );

      notifyListeners();
      return null;
    } on AuthException catch (e) {
      _authState = AuthState.unauthenticated;
      _errorMessage = e.message;
      notifyListeners();
      return e.message;
    } catch (e) {
      _authState = AuthState.unauthenticated;
      // Hiện thị lỗi cụ thể để dễ debug
      final msg = _friendlyError(e);
      _errorMessage = msg;
      notifyListeners();
      return msg;
    }
  }

  // ───────────── Đăng nhập ─────────────

  /// Đăng nhập với username và password.
  /// Trả về null nếu thành công, trả về message lỗi nếu thất bại.
  Future<String?> login({
    required String username,
    required String password,
    bool rememberMe = false,
  }) async {
    _authState = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _userRepository.loginUser(
        username: username,
        password: password,
      );

      _currentUser = user;
      final prefs = await SharedPreferences.getInstance();
      _avatarBase64 = prefs.getString(_avatarBase64Key(user.id));
      _authState = AuthState.authenticated;

      await _authService.saveSession(
        userId: user.id,
        username: user.username,
        rememberMe: rememberMe,
      );

      notifyListeners();
      return null;
    } on AuthException catch (e) {
      _authState = AuthState.unauthenticated;
      _errorMessage = e.message;
      notifyListeners();
      return e.message;
    } catch (e) {
      _authState = AuthState.unauthenticated;
      final msg = _friendlyError(e);
      _errorMessage = msg;
      notifyListeners();
      return msg;
    }
  }

  // ───────────── Đăng xuất ─────────────

  Future<void> logout() async {
    await _authService.clearSession();
    _currentUser = null;
    _avatarBase64 = null;
    _errorMessage = null;
    _authState = AuthState.unauthenticated;
    notifyListeners();
  }

  // ───────────── Cập nhật hồ sơ ─────────────

  Future<void> updateDisplayName(String name) async {
    final user = _currentUser;
    if (user == null) return;

    final newName = name.trim();
    if (newName.isEmpty) return;
    _currentUser = user.copyWith(displayName: newName);

    try {
      await _userRepository.updateDisplayName(user.id, newName);
    } catch (e) {
      debugPrint('Error updating display name in DB: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_displayNameKey, newName);

    notifyListeners();
  }

  Future<void> updateAvatarBase64(String? avatarBase64) async {
    final user = _currentUser;
    if (user == null) return;

    _avatarBase64 = avatarBase64;

    final prefs = await SharedPreferences.getInstance();
    final key = _avatarBase64Key(user.id);
    if (avatarBase64 == null || avatarBase64.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, avatarBase64);
    }

    notifyListeners();
  }

  /// Đổi mật khẩu. Trả về null nếu thành công, message lỗi nếu thất bại.
  Future<String?> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final user = _currentUser;
    if (user == null) return 'Chưa đăng nhập.';

    try {
      await _userRepository.updatePassword(
        userId: user.id,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Đã xảy ra lỗi. Vui lòng thử lại.';
    }
  }

  // ───────────── Helpers ─────────────

  Future<String?> getStoredUsername() => _authService.getStoredUsername();

  void setCurrentUser(UserModel user) {
    _currentUser = user;
    _avatarBase64 = null;
    notifyListeners();
  }

  /// Load từ DB (dùng cho migration / legacy).
  Future<void> loadUser([UserModel? dbUser]) async {
    _currentUser = dbUser ?? await _userRepository.getOrCreateDefaultUser();

    final prefs = await SharedPreferences.getInstance();
    final savedDisplayName = prefs.getString(_displayNameKey);
    _avatarBase64 = prefs.getString(_avatarBase64Key(_currentUser!.id));
    if (savedDisplayName != null && savedDisplayName.trim().isNotEmpty) {
      _currentUser = _currentUser!.copyWith(
        displayName: savedDisplayName.trim(),
      );
    }

    _authState = AuthState.authenticated;
    notifyListeners();
  }

  // ───────────── Error Mapping ─────────────

  /// Chuyển exception sang thông báo thân thiện bằng tiếng Việt.
  String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('unique') || msg.contains('constraint')) {
      return 'Tên đăng nhập đã tồn tại. Vui lòng chọn tên khác.';
    }
    if (msg.contains('network') || msg.contains('socket')) {
      return 'Lỗi kết nối mạng. Vui lòng thử lại.';
    }
    if (msg.contains('database') || msg.contains('sql')) {
      return 'Lỗi cơ sở dữ liệu. Vui lòng khởi động lại ứng dụng.';
    }
    debugPrint('[AuthError] $e');
    return 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.';
  }
}
