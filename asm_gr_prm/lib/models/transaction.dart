class TransactionModel {
  final int? id;
  final String title;
  final double amount;
  final String type; // "income" hoặc "expense"
  final int? categoryId;
  final String? note;
  final String date;
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
      'date': date,
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
      date: map['date'],
      userId: map['userId'],
    );
  }
}
