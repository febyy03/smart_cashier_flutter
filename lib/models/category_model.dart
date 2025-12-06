class Category {
  final int? id;
  final String name;
  final String? icon;
  final DateTime? createdAt;

  Category({
    this.id,
    required this.name,
    this.icon,
    this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}