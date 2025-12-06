import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../utils/constants.dart';
import 'auth_service.dart';

class ApiService {
  static final ApiService instance = ApiService._init();
  ApiService._init();

  final _authService = AuthService.instance;
  String _extractServerMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded.containsKey('message')) {
        return decoded['message'].toString();
      }
      if (decoded is Map && decoded.containsKey('error')) {
        return decoded['error'].toString();
      }
    } catch (_) {
      // ignore json parse errors
    }
    return response.body.toString();
  }

  // Products
  Future<List<Product>> fetchProducts() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final url = '${Constants.apiBaseUrl}/products';
      log('Fetching products from: $url', name: 'ApiService');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      log('Products response status: ${response.statusCode}', name: 'ApiService');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        // Laravel typically returns data in 'data' key for collections
        final data = decoded['data'] ?? decoded;
        log('Products response data: $data', name: 'ApiService');

        if (data is List) {
          return data.map<Product>((json) => Product.fromJson(json)).toList();
        }
      } else {
        final serverMsg = _extractServerMessage(response);
        log('fetchProducts failed: ${response.statusCode} - $serverMsg', name: 'ApiService');
        if (response.statusCode == 405) {
          log('GET is not allowed on /products. Check backend routes or use POST.', name: 'ApiService');
        }
      }
      return [];
    } catch (e) {
      log('Error fetching products: $e', name: 'ApiService');
      return [];
    }
  }

  Future<Map<String, dynamic>> createProduct(Product product) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}/products'),
        headers: headers,
        body: jsonEncode(product.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'] ?? decoded;
        return {
          'success': true,
          'data': data != null ? Product.fromJson(data) : null,
        };
      } else if (response.statusCode == 422) {
        // Laravel validation errors
        final decoded = jsonDecode(response.body);
        final errors = decoded['errors'] ?? decoded['message'] ?? 'Validation failed';
        return {'success': false, 'message': errors.toString()};
      } else {
        final decoded = jsonDecode(response.body);
        final message = decoded['message'] ?? decoded['error'] ?? 'Failed to create product';
        return {'success': false, 'message': message};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateProduct(Product product) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.put(
        Uri.parse('${Constants.apiBaseUrl}/products/${product.id}'),
        headers: headers,
        body: jsonEncode(product.toJson()),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'];
        return {
          'success': true,
          'data': data != null ? Product.fromJson(data) : null,
        };
      }
      return {'success': false, 'message': 'Failed to update product'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteProduct(int id) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('${Constants.apiBaseUrl}/products/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'message': 'Failed to delete product'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Categories
  Future<List<Category>> fetchCategories() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${Constants.apiBaseUrl}/categories'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'] ?? decoded;
        if (data is List) {
          return data.map<Category>((json) => Category.fromJson(json)).toList();
        }
      } else {
        final serverMsg = _extractServerMessage(response);
        log('fetchCategories failed: ${response.statusCode} - $serverMsg', name: 'ApiService');
      }
      return [];
    } catch (e) {
      log('Error fetching categories: $e', name: 'ApiService');
      return [];
    }
  }

  // Transactions
  Future<Map<String, dynamic>> createTransaction(Transaction transaction) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final url = '${Constants.apiBaseUrl}/transactions';
      final requestBody = jsonEncode(transaction.toJson());

      log('Creating transaction at: $url', name: 'ApiService');
      log('Request body: $requestBody', name: 'ApiService');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: requestBody,
      );

      log('Transaction creation response status: ${response.statusCode}', name: 'ApiService');
      log('Response body: ${response.body}', name: 'ApiService');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        // Laravel typically returns created resource in 'data' key
        final data = decoded['data'] ?? decoded;
        return {
          'success': true,
          'data': data != null ? Transaction.fromJson(data) : null,
        };
      } else if (response.statusCode == 422) {
        // Laravel validation errors
        final decoded = jsonDecode(response.body);
        final errors = decoded['errors'] ?? decoded['message'] ?? 'Validation failed';
        return {'success': false, 'message': errors.toString()};
      } else {
        final decoded = jsonDecode(response.body);
        final message = decoded['message'] ?? decoded['error'] ?? 'Failed to create transaction';
        return {'success': false, 'message': message};
      }
    } catch (e) {
      log('Error creating transaction: $e', name: 'ApiService');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<List<Transaction>> fetchTransactions({DateTime? startDate, DateTime? endDate}) async {
    try {
      final headers = await _authService.getAuthHeaders();
      String url = '${Constants.apiBaseUrl}/transactions';

      if (startDate != null && endDate != null) {
        url += '?start_date=${startDate.toIso8601String()}&end_date=${endDate.toIso8601String()}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        // Laravel returns paginated data in 'data' key
        final data = decoded['data'] ?? decoded;
        if (data is List) {
          return data.map<Transaction>((json) => Transaction.fromJson(json)).toList();
        }
      } else {
        final serverMsg = _extractServerMessage(response);
        log('fetchTransactions failed: ${response.statusCode} - $serverMsg', name: 'ApiService');
      }
      return [];
    } catch (e) {
      log('Error fetching transactions: $e', name: 'ApiService');
      return [];
    }
  }

  // AI Recommendations
  Future<List<Product>> getRecommendations({
    List<int>? productIds,
    int? customerId,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}/recommendations/customer'),
        headers: headers,
        body: jsonEncode({
          'product_ids': productIds,
          'customer_id': customerId,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'];
        if (data is List) {
          return data.map<Product>((json) => Product.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      log('Error fetching recommendations: $e', name: 'ApiService');
      return [];
    }
  }

  Future<List<Product>> getPopularProducts() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${Constants.apiBaseUrl}/recommendations/popular'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'];
        if (data is List) {
          return data.map<Product>((json) => Product.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      log('Error fetching popular products: $e', name: 'ApiService');
      return [];
    }
  }

  // Reports
  Future<Map<String, dynamic>> getDailyReport(DateTime date) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${Constants.apiBaseUrl}/reports/daily?date=${date.toIso8601String()}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'] ?? decoded;
        if (data is Map<String, dynamic>) return data;
        if (data is Map) return Map<String, dynamic>.from(data);
      } else {
        final serverMsg = _extractServerMessage(response);
        log('getDailyReport failed: ${response.statusCode} - $serverMsg', name: 'ApiService');
      }
      return {};
    } catch (e) {
      log('Error fetching daily report: $e', name: 'ApiService');
      return {};
    }
  }

  Future<Map<String, dynamic>> getWeeklyReport(DateTime startDate) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${Constants.apiBaseUrl}/reports/weekly?start_date=${startDate.toIso8601String()}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'];
        if (data is Map<String, dynamic>) return data;
        if (data is Map) return Map<String, dynamic>.from(data);
      }
      return {};
    } catch (e) {
      log('Error fetching weekly report: $e', name: 'ApiService');
      return {};
    }
  }

  Future<Map<String, dynamic>> getMonthlyReport(int year, int month) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${Constants.apiBaseUrl}/reports/monthly?year=$year&month=$month'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'];
        if (data is Map<String, dynamic>) return data;
        if (data is Map) return Map<String, dynamic>.from(data);
      }
      return {};
    } catch (e) {
      log('Error fetching monthly report: $e', name: 'ApiService');
      return {};
    }
  }
}