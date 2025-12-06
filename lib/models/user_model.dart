class User {
  final int? id;
  final String email;
  final String name;
  final String role; // 'admin' or 'kasir'
  final String? token;
  final DateTime? createdAt;

  User({
    this.id,
    required this.email,
    required this.name,
    required this.role,
    this.token,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      role: json['role'] ?? 'kasir',
      token: json['token'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'token': token,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isKasir => role == 'kasir';
}