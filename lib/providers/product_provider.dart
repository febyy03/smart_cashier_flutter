import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';

class ProductProvider with ChangeNotifier {
  final _dbService = DatabaseService.instance;
  final _apiService = ApiService.instance;

  List<Product> _products = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Product> get products => _products;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load products from local database
  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _products = await _dbService.getAllProducts();
    } catch (e) {
      _errorMessage = 'Error loading products: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Sync products from API
  Future<void> syncProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final apiProducts = await _apiService.fetchProducts();
      
      // Clear local database and insert new data
      for (var product in apiProducts) {
        await _dbService.createProduct(product);
      }
      
      await loadProducts();
    } catch (e) {
      _errorMessage = 'Error syncing products: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load categories
  Future<void> loadCategories() async {
    try {
      _categories = await _dbService.getAllCategories();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error loading categories: $e';
    }
  }

  // Sync categories from API
  Future<void> syncCategories() async {
    try {
      final apiCategories = await _apiService.fetchCategories();
      
      for (var category in apiCategories) {
        await _dbService.createCategory(category);
      }
      
      await loadCategories();
    } catch (e) {
      _errorMessage = 'Error syncing categories: $e';
    }
  }

  // Add product
  Future<bool> addProduct(Product product) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Save to local database first
      await _dbService.createProduct(product);

      // Try to sync with API (don't fail if API unavailable)
      try {
        await _apiService.createProduct(product);
      } catch (apiError) {
        debugPrint('API sync failed for product creation, but local save succeeded: $apiError');
      }

      await loadProducts();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error adding product: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update product
  Future<bool> updateProduct(Product product) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _dbService.updateProduct(product);

      // Try to sync with API
      try {
        await _apiService.updateProduct(product);
      } catch (apiError) {
        debugPrint('API sync failed for product update, but local update succeeded: $apiError');
      }

      await loadProducts();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error updating product: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete product
  Future<bool> deleteProduct(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _dbService.deleteProduct(id);

      // Try to sync with API
      try {
        await _apiService.deleteProduct(id);
      } catch (apiError) {
        debugPrint('API sync failed for product deletion, but local deletion succeeded: $apiError');
      }

      await loadProducts();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error deleting product: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Search products
  Future<List<Product>> searchProducts(String query) async {
    return await _dbService.searchProducts(query);
  }

  // Get low stock products
  Future<List<Product>> getLowStockProducts() async {
    return await _dbService.getLowStockProducts();
  }

  // Get products by category
  List<Product> getProductsByCategory(int categoryId) {
    return _products.where((p) => p.categoryId == categoryId).toList();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}