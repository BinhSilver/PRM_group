import 'package:flutter/material.dart';

import '../database/category_repository.dart';
import '../database/spending_jar_repository.dart';
import '../models/category_model.dart';
import '../models/spending_jar_model.dart';

class SpendingJarProvider extends ChangeNotifier {
  final SpendingJarRepository _jarRepo = SpendingJarRepository();
  final CategoryRepository _categoryRepo = CategoryRepository();

  List<SpendingJarModel> _jars = [];
  List<CategoryModel> _expenseCategories = [];
  final Map<int, double> _spentByJar = {};
  String _selectedMonth = _currentMonthKey();
  bool _isLoading = false;

  List<SpendingJarModel> get jars => _jars;
  List<CategoryModel> get expenseCategories => _expenseCategories;
  String get selectedMonth => _selectedMonth;
  double get monthlyBudget => allocatedBudget;
  bool get isLoading => _isLoading;

  double get allocatedBudget {
    return _jars.fold<double>(0, (sum, jar) => sum + jar.amount);
  }

  double get unallocatedBudget => 0;

  double get totalSpentInJars {
    return _spentByJar.values.fold<double>(0, (sum, spent) => sum + spent);
  }

  double get remainingInJars => allocatedBudget - totalSpentInJars;

  static String _currentMonthKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  Future<void> loadJars(int userId, {String? month}) async {
    _isLoading = true;
    notifyListeners();

    _selectedMonth = month ?? _selectedMonth;
    _jars = await _jarRepo.getJarsByMonth(userId, _selectedMonth);
    _spentByJar
      ..clear()
      ..addAll(await _jarRepo.getSpentByJar(_jars));

    var categories = await _categoryRepo.getCategories(userId);
    if (!categories.any((category) => category.type == 'expense')) {
      await _categoryRepo.insertDefaultCategories(userId);
      categories = await _categoryRepo.getCategories(userId);
    }
    _expenseCategories = categories
        .where((category) => category.type == 'expense')
        .toList();

    _isLoading = false;
    notifyListeners();
  }

  double getSpent(SpendingJarModel jar) {
    final id = jar.id;
    if (id == null) return 0;
    return _spentByJar[id] ?? 0;
  }

  double getRemaining(SpendingJarModel jar) {
    return jar.amount - getSpent(jar);
  }

  double getProgress(SpendingJarModel jar) {
    if (jar.amount <= 0) return 0;
    return (getSpent(jar) / jar.amount).clamp(0.0, 1.0);
  }

  Future<String?> createJar({
    required int userId,
    required String name,
    required double amount,
    required int categoryId,
    String icon = 'savings',
    int colorValue = 0xFFE91E8F,
  }) async {
    final nameError = validateName(name);
    if (nameError != null) return nameError;

    final validationError = await _validateAllocation(
      userId: userId,
      amount: amount,
      categoryId: categoryId,
    );
    if (validationError != null) return validationError;

    final jar = SpendingJarModel(
      name: name.trim(),
      month: _selectedMonth,
      amount: amount,
      userId: userId,
      categoryId: categoryId,
      icon: icon,
      colorValue: colorValue,
    );

    try {
      await _jarRepo.insertJar(jar);
      await loadJars(userId, month: _selectedMonth);
      return null;
    } catch (_) {
      return 'Tên hũ đã tồn tại trong tháng này.';
    }
  }

  Future<String?> updateJar({
    required int userId,
    required SpendingJarModel jar,
    required String name,
    required double amount,
    required int categoryId,
    String? icon,
    int? colorValue,
  }) async {
    final nameError = validateName(name);
    if (nameError != null) return nameError;

    final validationError = await _validateAllocation(
      userId: userId,
      amount: amount,
      categoryId: categoryId,
      excludeJarId: jar.id,
    );
    if (validationError != null) return validationError;

    try {
      await _jarRepo.updateJar(
        SpendingJarModel(
          id: jar.id,
          name: name.trim(),
          month: jar.month,
          amount: amount,
          userId: jar.userId,
          categoryId: categoryId,
          icon: icon ?? jar.icon,
          colorValue: colorValue ?? jar.colorValue,
        ),
      );
      await loadJars(userId, month: _selectedMonth);
      return null;
    } catch (_) {
      return 'Không thể cập nhật hũ. Vui lòng thử lại.';
    }
  }

  Future<void> deleteJar(int id, int userId) async {
    await _jarRepo.deleteJar(id);
    await loadJars(userId, month: _selectedMonth);
  }

  Future<String?> _validateAllocation({
    required int userId,
    required double amount,
    required int categoryId,
    int? excludeJarId,
  }) async {
    if (amount <= 0) {
      return 'Số tiền hũ phải lớn hơn 0.';
    }

    final category = await _categoryRepo.getCategoryById(categoryId);
    if (category == null ||
        category.type != 'expense' ||
        (category.userId != null && category.userId != userId)) {
      return 'Vui lòng chọn đúng loại chi tiêu.';
    }

    final duplicatedCategory = await _jarRepo.hasJarForCategory(
      userId,
      _selectedMonth,
      categoryId,
      excludeJarId: excludeJarId,
    );
    if (duplicatedCategory) {
      return 'Danh mục này đã có hũ trong tháng hiện tại.';
    }

    return null;
  }

  String? validateName(String name) {
    if (name.trim().isEmpty) return 'Vui lòng nhập tên hũ.';
    return null;
  }
}
