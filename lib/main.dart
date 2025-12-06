import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/transaction_provider.dart';
import 'services/database_service.dart';
import 'screens/login_page.dart';
import 'screens/kasir_dashboard.dart';
import 'screens/admin_dashboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Smart Cashier',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
        ),
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginPage(),
          '/kasir-dashboard': (context) => const KasirDashboard(),
          '/admin-dashboard': (context) => const AdminDashboard(),
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // ignore: use_build_context_synchronously
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Capture providers / services that we will use after async gaps so
    // we don't access `BuildContext` synchronously after an `await`.
    // It's safe here because we use `listen: false`, however the analyzer
    // may still warn about using BuildContext across async gaps — silence
    // that specific lint for this line.
    // ignore: use_build_context_synchronously
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final dbService = DatabaseService.instance;

    await authProvider.initialize();

    // Capture navigator before async gaps to avoid using `context` later.
    // ignore: use_build_context_synchronously
    final navigator = Navigator.of(context);

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (authProvider.isLoggedIn) {
      // Initialize demo data if needed
      await productProvider.loadCategories();
      await productProvider.loadProducts();

      // Initialize demo data if database is empty
      await dbService.initializeDemoData();

      // Reload data after demo initialization
      await productProvider.loadCategories();
      await productProvider.loadProducts();

      if (authProvider.isAdmin) {
        navigator.pushReplacementNamed('/admin-dashboard');
      } else {
        navigator.pushReplacementNamed('/kasir-dashboard');
      }
    } else {
      navigator.pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade700,
              Colors.blue.shade400,
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_cart,
                size: 100,
                color: Colors.white,
              ),
              SizedBox(height: 24),
              Text(
                'Smart Cashier',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Kasir Cerdas dengan AI',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 48),
              CircularProgressIndicator(
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}