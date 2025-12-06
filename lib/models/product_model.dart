class Product {
  final int? id;
  final String name;
  final double price;
  final int stock;
  final int categoryId;
  final String? categoryName;
  final String? image;
  final String? barcode;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.categoryId,
    this.categoryName,
    this.image,
    this.barcode,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      price: double.parse(json['price'].toString()),
      stock: json['stock'] ?? 0,
      categoryId: json['category_id'],
      categoryName: json['category_name'],
      image: json['image'],
      barcode: json['barcode'],
      description: json['description'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'stock': stock,
      'category_id': categoryId,
      'category_name': categoryName,
      'image': image,
      'barcode': barcode,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'stock': stock,
      'category_id': categoryId,
      'image': image,
      'barcode': barcode,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isLowStock => stock < 10;
  bool get isOutOfStock => stock == 0;
}