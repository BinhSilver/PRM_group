class CategoryModel {
  final int? id;
  final String name;
  final String type; // "income" or "expense"
  final String? icon;
  final int? userId;

  CategoryModel({
    this.id,
    required this.name,
    required this.type,
    this.icon,
    this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'icon': icon,
      'userId': userId,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      icon: map['icon'],
      userId: map['userId'],
    );
  }

  CategoryModel copyWith({
    int? id,
    String? name,
    String? type,
    String? icon,
    int? userId,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      userId: userId ?? this.userId,
    );
  }
}
