class UserModel {
  final int id;
  final String username;
  final String displayName;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.displayName,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'displayName': displayName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int,
      username: map['username'] as String,
      displayName: (map['displayName'] as String?) ?? 'Người dùng',
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  UserModel copyWith({
    int? id,
    String? username,
    String? displayName,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
