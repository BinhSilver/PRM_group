class SpendingJarModel {
  final int? id;
  final String name;
  final String month; // "2026-07"
  final double amount;
  final int userId;
  final int? categoryId;
  final String icon;
  final int colorValue;

  const SpendingJarModel({
    this.id,
    required this.name,
    required this.month,
    required this.amount,
    required this.userId,
    this.categoryId,
    this.icon = 'savings',
    this.colorValue = 0xFFE91E8F,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'month': month,
      'amount': amount,
      'userId': userId,
      'categoryId': categoryId,
      'icon': icon,
      'colorValue': colorValue,
    };
  }

  factory SpendingJarModel.fromMap(Map<String, dynamic> map) {
    return SpendingJarModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      month: map['month'] as String,
      amount: (map['amount'] as num).toDouble(),
      userId: map['userId'] as int,
      categoryId: map['categoryId'] as int?,
      icon: map['icon'] as String? ?? 'savings',
      colorValue: map['colorValue'] as int? ?? 0xFFE91E8F,
    );
  }

  SpendingJarModel copyWith({
    int? id,
    String? name,
    String? month,
    double? amount,
    int? userId,
    int? categoryId,
    String? icon,
    int? colorValue,
  }) {
    return SpendingJarModel(
      id: id ?? this.id,
      name: name ?? this.name,
      month: month ?? this.month,
      amount: amount ?? this.amount,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      icon: icon ?? this.icon,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}
