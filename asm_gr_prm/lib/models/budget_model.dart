class BudgetModel {
  final int? id;
  final String month; // "2026-07"
  final double amount;
  final int userId;

  BudgetModel({
    this.id,
    required this.month,
    required this.amount,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'month': month,
      'amount': amount,
      'userId': userId,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'],
      month: map['month'],
      amount: (map['amount'] as num).toDouble(),
      userId: map['userId'],
    );
  }

  BudgetModel copyWith({
    int? id,
    String? month,
    double? amount,
    int? userId,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      month: month ?? this.month,
      amount: amount ?? this.amount,
      userId: userId ?? this.userId,
    );
  }
}
