class TransactionModel {
  final int? id;
  final String title;
  final double amount;
  final String type; // "income" or "expense"
  final int? categoryId;
  final String? note;
  final DateTime date;
  final int userId;

  TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    this.categoryId,
    this.note,
    required this.date,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type,
      'categoryId': categoryId,
      'note': note,
      'date': date.toIso8601String(),
      'userId': userId,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      type: map['type'],
      categoryId: map['categoryId'],
      note: map['note'],
      date: DateTime.parse(map['date']),
      userId: map['userId'],
    );
  }

  TransactionModel copyWith({
    int? id,
    String? title,
    double? amount,
    String? type,
    int? categoryId,
    String? note,
    DateTime? date,
    int? userId,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      date: date ?? this.date,
      userId: userId ?? this.userId,
    );
  }
}