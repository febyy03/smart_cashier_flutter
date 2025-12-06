import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService {
  static final AuthService instance = AuthService._init();
  AuthService._init();

  User? _currentUser;
  User? get currentUser => _currentUser;

  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      log('Login response status: ${response.statusCode}', name: 'AuthService');
      log('Login response body: ${response.body}', name: 'AuthService');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Normalize response shapes:
        // - { data: { user: {...}, token: '...' } }
        // - { user: {...}, token: '...' }
        // - { ...user fields... }
        Map<String, dynamic> payload = {};
        if (data is Map<String, dynamic>) {
          // If 'data' contains nested payload, prefer it
          if (data['data'] is Map<String, dynamic>) {
            payload = Map<String, dynamic>.from(data['data']);
          } else {
            payload = Map<String, dynamic>.from(data);
          }
        }

        // Extract user map. Common keys: 'user' or direct user fields.
        Map<String, dynamic>? userMap;
        if (payload['user'] is Map<String, dynamic>) {
          userMap = Map<String, dynamic>.from(payload['user']);
        } else {
          // If payload looks like user fields (has 'email' and 'id'), assume it's the user
          if (payload.containsKey('email') && payload.containsKey('id')) {
            userMap = payload;
          }
        }

        if (userMap != null) {
          _currentUser = User.fromJson(userMap);
        } else {
          // Last resort: try decoding top-level data as user
          try {
            _currentUser = User.fromJson(payload);
          } catch (_) {
            _currentUser = null;
          }
        }

        // Token extraction: check multiple possible keys including Laravel Sanctum 'plainTextToken'
        String? token;
        token ??= payload['token'] as String?;
        token ??= payload['access_token'] as String?;
        token ??= payload['bearer_token'] as String?;
        token ??= payload['plainTextToken'] as String?;
        token ??= payload['plain_text_token'] as String?;
        token ??= data['token'] as String?;
        token ??= data['access_token'] as String?;
        token ??= data['plainTextToken'] as String?;

        if (token != null && _currentUser != null) {
          await _saveAuthData(token, _currentUser!);
        }

        return {'success': true, 'user': _currentUser};
      } else {
        final error = jsonDecode(response.body);
        // Laravel validation errors are often in 'errors' key
        final errorMessage = error['message'] ?? error['error'] ??
                           (error['errors'] != null ? error['errors'].toString() : 'Login failed');
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      log('Login error: $e', name: 'AuthService');
      // If backend is unavailable, allow demo login
      return await _demoLogin(email, password);
    }
  }

  // Demo login for offline mode
  Future<Map<String, dynamic>> _demoLogin(String email, String password) async {
    // Simple demo credentials
    if (email == 'demo@kasir.com' && password == 'demo123') {
      _currentUser = User(
        id: 1,
        name: 'Demo Kasir',
        email: email,
        role: 'kasir',
      );

      // Save demo user data
      await _saveAuthData('demo_token', _currentUser!);

      return {'success': true, 'user': _currentUser, 'demo': true};
    } else if (email == 'admin@kasir.com' && password == 'admin123') {
      _currentUser = User(
        id: 2,
        name: 'Demo Admin',
        email: email,
        role: 'admin',
      );

      // Save demo user data
      await _saveAuthData('demo_token', _currentUser!);

      return {'success': true, 'user': _currentUser, 'demo': true};
    }

    return {'success': false, 'message': 'Invalid credentials. For demo mode, use:\nKasir: demo@kasir.com / demo123\nAdmin: admin@kasir.com / admin123'};
  }

  // Register
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String role = 'kasir',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': password, // Laravel often requires confirmation
          'role': role,
        }),
      );

      log('Register response status: ${response.statusCode}', name: 'AuthService');
      log('Register response body: ${response.body}', name: 'AuthService');

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Try to parse returned body for user/token and save them if present
        try {
          final data = jsonDecode(response.body);
          Map<String, dynamic> payload = {};
          if (data is Map<String, dynamic>) {
            payload = data['data'] is Map<String, dynamic>
                ? Map<String, dynamic>.from(data['data'])
                : Map<String, dynamic>.from(data);
          }

          Map<String, dynamic>? userMap;
          if (payload['user'] is Map<String, dynamic>) {
            userMap = Map<String, dynamic>.from(payload['user']);
          } else if (payload.containsKey('email') && payload.containsKey('id')) {
            userMap = payload;
          }

          String? token;
          token ??= payload['token'] as String?;
          token ??= payload['access_token'] as String?;
          token ??= payload['plainTextToken'] as String?;

          if (userMap != null && token != null) {
            final user = User.fromJson(userMap);
            await _saveAuthData(token, user);
          }
        } catch (_) {
          // ignore parse errors — registration still succeeded
        }

        return {'success': true, 'message': 'Registration successful'};
      } else if (response.statusCode == 422) {
        // Laravel validation errors
        final decoded = jsonDecode(response.body);
        final errors = decoded['errors'] ?? decoded['message'] ?? 'Validation failed';
        return {'success': false, 'message': errors.toString()};
      } else {
        final decoded = jsonDecode(response.body);
        final message = decoded['message'] ?? decoded['error'] ?? 'Registration failed';
        return {'success': false, 'message': message};
      }
    } catch (e) {
      log('Register error: $e', name: 'AuthService');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Reset Password
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Password reset link sent to email'};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Reset failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        await http.post(
          Uri.parse('${Constants.apiBaseUrl}/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }
    } catch (e) {
      // Ignore logout errors - Laravel might not require logout endpoint
      log('Logout API call failed: $e', name: 'AuthService');
    }

    _currentUser = null;
    await _clearAuthData();
  }

  // Save auth data to SharedPreferences
  Future<void> _saveAuthData(String token, User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_data', jsonEncode(user.toJson()));
  }

  // Clear auth data
  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  // Get saved token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // Load user from storage
  Future<User?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    
    if (userData != null) {
      _currentUser = User.fromJson(jsonDecode(userData));
      return _currentUser;
    }
    return null;
  }

  // Get authorization headers
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }
}