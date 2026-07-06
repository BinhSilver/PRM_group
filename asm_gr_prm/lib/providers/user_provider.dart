import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  static const String _displayNameKey = 'displayName';

  UserModel? currentUser = UserModel(
    id: 0,
    username: 'guest',
    displayName: 'Người dùng',
    createdAt: DateTime(2026, 1, 1),
  );

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDisplayName = prefs.getString(_displayNameKey);
    if (savedDisplayName == null || savedDisplayName.trim().isEmpty) return;

    currentUser = currentUser?.copyWith(displayName: savedDisplayName.trim());
    notifyListeners();
  }

  Future<void> updateDisplayName(String name) async {
    final user = currentUser;
    if (user == null) return;

    final newName = name.trim();
    if (newName.isEmpty) return;
    currentUser = user.copyWith(displayName: newName);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_displayNameKey, newName);

    notifyListeners();
  }

  void setCurrentUser(UserModel user) {
    currentUser = user;
    notifyListeners();
  }

  void logout() {
    notifyListeners();
  }
}
