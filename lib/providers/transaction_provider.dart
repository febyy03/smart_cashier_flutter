import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'product_provider.dart';
import '../models/transaction_model.dart';
import '../models/transaction_item_model.dart';
import '../models/product_model.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';

class TransactionProvider with ChangeNotifier {
  final _dbService = DatabaseService.instance;
  final _apiService = ApiService.instance;

  List<Transaction> _transactions = [];
  final List<TransactionItem> _currentCart = [];
  double _subtotal = 0;
  double _tax = 0;
  double _discount = 0;
  double _total = 0;
  String _paymentMethod = 'cash';
  bool _isLoading = false;

  List<Transaction> get transactions => _transactions;
  List<TransactionItem> get currentCart => _currentCart;
  double get subtotal => _subtotal;
  double get tax => _tax;
  double get discount => _discount;
  double get total => _total;
  String get paymentMethod => _paymentMethod;
  bool get isLoading => _isLoading;
  int get cartItemCount => _currentCart.length;

  // Add item to cart
  void addToCart(Product product, int quantity) {
    if (product.id == null) {
      throw ArgumentError('Product must have a non-null id to be added to cart');
    }

    final existingIndex = _currentCart.indexWhere(
      (item) => item.productId == product.id!,
    );

    if (existingIndex >= 0) {
      // Update quantity
      final existing = _currentCart[existingIndex];
      _currentCart[existingIndex] = TransactionItem(
        productId: existing.productId,
        productName: existing.productName,
        price: existing.price,
        quantity: existing.quantity + quantity,
        subtotal: existing.price * (existing.quantity + quantity),
      );
    } else {
      // Add new item
      _currentCart.add(TransactionItem(
        productId: product.id!,
        productName: product.name,
        price: product.price,
        quantity: quantity,
        subtotal: product.price * quantity,
      ));
    }

    _calculateTotals();
    notifyListeners();
  }

  // Update item quantity
  void updateItemQuantity(int productId, int quantity) {
    final index = _currentCart.indexWhere((item) => item.productId == productId);
    
    if (index >= 0) {
      if (quantity <= 0) {
        _currentCart.removeAt(index);
      } else {
        final item = _currentCart[index];
        _currentCart[index] = TransactionItem(
          productId: item.productId,
          productName: item.productName,
          price: item.price,
          quantity: quantity,
          subtotal: item.price * quantity,
        );
      }
      
      _calculateTotals();
      notifyListeners();
    }
  }

  // Remove item from cart
  void removeFromCart(int productId) {
    _currentCart.removeWhere((item) => item.productId == productId);
    _calculateTotals();
    notifyListeners();
  }

  // Clear cart
  void clearCart() {
    _currentCart.clear();
    _subtotal = 0;
    _tax = 0;
    _discount = 0;
    _total = 0;
    notifyListeners();
  }

  // Set discount
  void setDiscount(double amount) {
    _discount = amount;
    _calculateTotals();
    notifyListeners();
  }

  // Set payment method
  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  // Calculate totals
  void _calculateTotals() {
    _subtotal = _currentCart.fold<double>(0.0, (sum, item) => sum + item.subtotal);
    _tax = _subtotal * 0.10; // 10% tax
    _total = _subtotal + _tax - _discount;
  }

  // Complete transaction
  Future<bool> completeTransaction(int userId, {BuildContext? context}) async {
    if (_currentCart.isEmpty) return false;

    _isLoading = true;
    notifyListeners();

    try {
      // If a BuildContext was provided, capture ProductProvider now (before any await)
      ProductProvider? productProvider;
      if (context != null) {
        productProvider = Provider.of<ProductProvider>(context, listen: false);
      }
      final transaction = Transaction(
        userId: userId,
        subtotal: _subtotal,
        tax: _tax,
        discount: _discount,
        total: _total,
        paymentMethod: _paymentMethod,
        createdAt: DateTime.now(),
        items: _currentCart,
      );

      // Save to local database first
      await _dbService.createTransaction(transaction);

      // Try to sync with API (don't fail if API is unavailable)
      try {
        await _apiService.createTransaction(transaction);
        debugPrint('Transaction synced with API successfully');
      } catch (apiError) {
        debugPrint('API sync failed, but local transaction saved: $apiError');
        // Continue - local transaction is still valid
      }

      // Reload products to reflect updated stock (if provider captured)
      if (productProvider != null) {
        try {
          await productProvider.loadProducts();
        } catch (e) {
          debugPrint('Failed to reload products after transaction: $e');
        }
      }

      // Clear cart after successful local save
      clearCart();

      // Reload transactions
      await loadTransactions();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
        debugPrint('Error completing transaction: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Load transactions
  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();

    try {
      _transactions = await _dbService.getAllTransactions();
    } catch (e) {
        debugPrint('Error loading transactions: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Get transactions by date range
  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    return await _dbService.getTransactionsByDateRange(start, end);
  }

  // Get today's transactions
  Future<List<Transaction>> getTodayTransactions() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return await getTransactionsByDateRange(start, end);
  }

  // Calculate daily revenue
  Future<double> getDailyRevenue() async {
    final todayTransactions = await getTodayTransactions();
    return todayTransactions.fold<double>(0.0, (sum, t) => sum + t.total);
  }
}