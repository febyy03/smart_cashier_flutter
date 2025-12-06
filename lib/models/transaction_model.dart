import 'transaction_item_model.dart';

class Transaction {
  final int? id;
  final int userId;
  final String? userName;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final String paymentMethod; // 'cash', 'card', 'qris'
  final DateTime createdAt;
  final List<TransactionItem> items;

  Transaction({
    this.id,
    required this.userId,
    this.userName,
    required this.subtotal,
    this.tax = 0,
    this.discount = 0,
    required this.total,
    this.paymentMethod = 'cash',
    required this.createdAt,
    this.items = const [],
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'],
      subtotal: double.parse(json['subtotal'].toString()),
      tax: double.parse(json['tax']?.toString() ?? '0'),
      discount: double.parse(json['discount']?.toString() ?? '0'),
      total: double.parse(json['total'].toString()),
      paymentMethod: json['payment_method'] ?? 'cash',
      createdAt: DateTime.parse(json['created_at']),
      items: json['items'] != null
          ? (json['items'] as List)
              .map((item) => TransactionItem.fromJson(item))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,
      'payment_method': paymentMethod,
      'created_at': createdAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'user_id': userId,
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,
      'payment_method': paymentMethod,
      'created_at': createdAt.toIso8601String(),
    };
  }
}