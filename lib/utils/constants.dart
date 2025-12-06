import 'package:flutter/foundation.dart';

class Constants {
  // API Configuration
  // Use different base URLs depending on platform. `10.0.2.2` is for Android
  // emulator; for web (Chrome) use localhost. For a physical device, replace
  // with your machine IP (e.g. 'http://192.168.1.100:8000/api').
  static String get apiBaseUrl {
    if (kIsWeb) return 'http://localhost:8000/api';
    return 'http://10.0.2.2:8000/api';
  }
  // For physical device, use: 'http://YOUR_COMPUTER_IP:8000/api'
  
  // App Configuration
  static const String appName = 'Smart Cashier';
  static const String appVersion = '1.0.0';
  
  // Tax & Discount
  static const double defaultTaxRate = 0.10; // 10%
  static const double maxDiscountPercent = 50.0;
  
  // Stock Alerts
  static const int lowStockThreshold = 10;
  static const int criticalStockThreshold = 5;
  
  // Pagination
  static const int itemsPerPage = 20;
  
  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String timeFormat = 'HH:mm';
  
  // Currency
  static const String currencySymbol = 'Rp';
  static const String currencyCode = 'IDR';
  
  // Payment Methods
  static const List<String> paymentMethods = [
    'cash',
    'card',
    'qris',
    'transfer',
  ];
  
  // User Roles
  static const String roleAdmin = 'admin';
  static const String roleKasir = 'kasir';
}