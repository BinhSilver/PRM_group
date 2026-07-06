import 'package:flutter/material.dart';
import '../database/budget_repository.dart';
import '../database/transaction_repository.dart';
import '../models/budget_model.dart';

class BudgetProvider extends ChangeNotifier {
  final BudgetRepository _budgetRepo = BudgetRepository();
  final TransactionRepository _txRepo = TransactionRepository();

  List<BudgetModel> _budgets = [];
  final Map<String, double> _spentByMonth = {}; // month -> total expense

  List<BudgetModel> get budgets => _budgets;

  Future<void> loadBudgets(int userId) async {
    _budgets = await _budgetRepo.getAllBudgets(userId);
    await _calculateSpent(userId);
    notifyListeners();
  }

  Future<void> _calculateSpent(int userId) async {
    _spentByMonth.clear();
    for (final b in _budgets) {
      final txs = await _txRepo.getTransactions(
        userId,
        type: 'expense',
        startDate: DateTime.parse('${b.month}-01'),
        endDate: DateTime.parse('${b.month}-01').add(const Duration(days: 32)),
      );
      final total = txs.fold<double>(0, (sum, t) => sum + t.amount);
      _spentByMonth[b.month] = total;
    }
  }

  double getSpent(String month) => _spentByMonth[month] ?? 0;

  bool isOverBudget(String month) {
    final budget = _budgets.firstWhere(
      (b) => b.month == month,
      orElse: () => BudgetModel(month: month, amount: 0, userId: 0),
    );
    return getSpent(month) > budget.amount;
  }

  Future<void> setBudget(int userId, String month, double amount) async {
    final existing = await _budgetRepo.getBudgetByMonth(userId, month);
    if (existing != null) {
      await _budgetRepo.updateBudget(existing.copyWith(amount: amount));
    } else {
      await _budgetRepo.insertBudget(
        BudgetModel(month: month, amount: amount, userId: userId),
      );
    }
    await loadBudgets(userId);
  }

  Future<void> deleteBudget(int id, int userId) async {
    await _budgetRepo.deleteBudget(id);
    await loadBudgets(userId);
  }
}
