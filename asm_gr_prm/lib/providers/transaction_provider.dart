import 'dart:async';

import 'package:flutter/material.dart';

import '../database/transaction_repository.dart';
import '../models/transaction_model.dart';
import '../widgets/time_filter_widget.dart';

class TransactionProvider with ChangeNotifier {
  final TransactionRepository _repository = TransactionRepository();

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _searchQuery;
  String? _selectedType;
  int? _selectedCategoryId;
  DateTime? _startDate;
  DateTime? _endDate;
  String _sortBy = 'date';
  String _sortOrder = 'DESC';
  TimeFilterType _timeFilterType = TimeFilterType.all;

  double _totalIncome = 0;
  double _totalExpense = 0;
  double _balance = 0;

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  double get totalIncome => _totalIncome;
  double get totalExpense => _totalExpense;
  double get balance => _balance;

  String? get selectedType => _selectedType;
  int? get selectedCategoryId => _selectedCategoryId;
  String get sortBy => _sortBy;
  String get sortOrder => _sortOrder;
  TimeFilterType get timeFilterType => _timeFilterType;

  Timer? _searchDebounce;

  Future<void> fetchTransactions(int userId) async {
    _isLoading = true;
    notifyListeners();

    _calculateDateRange();

    try {
      _transactions = await _repository.getTransactions(
        userId,
        search: _searchQuery,
        type: _selectedType,
        categoryId: _selectedCategoryId,
        startDate: _startDate,
        endDate: _endDate,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      final summary = await _repository.getFinancialSummary(userId);
      _totalIncome = summary['income'] ?? 0;
      _totalExpense = summary['expense'] ?? 0;
      _balance = summary['balance'] ?? 0;
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _calculateDateRange() {
    final now = DateTime.now();
    switch (_timeFilterType) {
      case TimeFilterType.all:
        _startDate = null;
        _endDate = null;
        break;
      case TimeFilterType.today:
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case TimeFilterType.week:
        _startDate = now.subtract(Duration(days: now.weekday - 1));
        _startDate = DateTime(
          _startDate!.year,
          _startDate!.month,
          _startDate!.day,
        );
        _endDate = now.add(Duration(days: 7 - now.weekday));
        _endDate = DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
          23,
          59,
          59,
        );
        break;
      case TimeFilterType.month:
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case TimeFilterType.year:
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
    }
  }

  void setFilters({
    required int userId,
    String? type,
    required TimeFilterType timeType,
  }) {
    _selectedType = type;
    _timeFilterType = timeType;
    fetchTransactions(userId);
  }

  void setSearchQuery(int userId, String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _searchQuery = query;
      fetchTransactions(userId);
    });
  }

  void setTypeFilter(int userId, String? type) {
    _selectedType = type;
    fetchTransactions(userId);
  }

  void setCategoryFilter(int userId, int? categoryId) {
    _selectedCategoryId = categoryId;
    fetchTransactions(userId);
  }

  void setSort(int userId, String sortBy, String sortOrder) {
    _sortBy = sortBy;
    _sortOrder = sortOrder;
    fetchTransactions(userId);
  }

  void setDateRange(int userId, DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    fetchTransactions(userId);
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    await _repository.insertTransaction(transaction);
    await fetchTransactions(transaction.userId);
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await _repository.updateTransaction(transaction);
    await fetchTransactions(transaction.userId);
  }

  Future<void> deleteTransaction(int id, int userId) async {
    await _repository.deleteTransaction(id);
    await fetchTransactions(userId);
  }
}