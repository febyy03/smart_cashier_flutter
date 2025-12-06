import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final _authService = AuthService.instance;
  
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isKasir => _user?.isKasir ?? false;

  // Initialize - check if user is already logged in
  Future<void> initialize() async {
    _isLoading = true;
    // Avoid calling notifyListeners synchronously during widget build.
    // Schedule the first notification to the next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    _user = await _authService.loadUser();

    _isLoading = false;
    notifyListeners();
  }

  // Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.login(email, password);
    
    if (result['success']) {
      _user = result['user'];
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String role = 'kasir',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.register(
      name: name,
      email: email,
      password: password,
      role: role,
    );
    
    _isLoading = false;
    if (!result['success']) {
      _errorMessage = result['message'];
    }
    notifyListeners();
    return result['success'];
  }

  // Reset Password
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.resetPassword(email);
    
    _isLoading = false;
    if (!result['success']) {
      _errorMessage = result['message'];
    }
    notifyListeners();
    return result['success'];
  }

  // Logout
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}