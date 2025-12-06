import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/transaction_item_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('smart_cashier.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id $idType,
        name $textType,
        icon TEXT,
        created_at TEXT
      )
    ''');

    // Products table
    await db.execute('''
      CREATE TABLE products (
        id $idType,
        name $textType,
        price $realType,
        stock $intType,
        category_id $intType,
        image TEXT,
        barcode TEXT,
        description TEXT,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id $idType,
        user_id $intType,
        subtotal $realType,
        tax REAL DEFAULT 0,
        discount REAL DEFAULT 0,
        total $realType,
        payment_method TEXT DEFAULT 'cash',
        created_at TEXT
      )
    ''');

    // Transaction items table
    await db.execute('''
      CREATE TABLE transaction_items (
        id $idType,
        transaction_id $intType,
        product_id $intType,
        price $realType,
        quantity $intType,
        subtotal $realType,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');
  }

  // Category CRUD
  Future<int> createCategory(Category category) async {
    final db = await instance.database;
    return await db.insert('categories', category.toDatabase());
  }

  Future<List<Category>> getAllCategories() async {
    final db = await instance.database;
    final result = await db.query('categories', orderBy: 'name ASC');
    return result.map((json) => Category.fromJson(json)).toList();
  }

  // Product CRUD
  Future<int> createProduct(Product product) async {
    final db = await instance.database;
    return await db.insert('products', product.toDatabase());
  }

  Future<List<Product>> getAllProducts() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT p.*, c.name as category_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      ORDER BY p.name ASC
    ''');
    return result.map((json) => Product.fromJson(json)).toList();
  }

  Future<Product?> getProductById(int id) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT p.*, c.name as category_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE p.id = ?
    ''', [id]);
    
    if (result.isNotEmpty) {
      return Product.fromJson(result.first);
    }
    return null;
  }

  Future<int> updateProduct(Product product) async {
    final db = await instance.database;
    return await db.update(
      'products',
      product.toDatabase(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT p.*, c.name as category_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE p.name LIKE ? OR p.barcode LIKE ?
      ORDER BY p.name ASC
    ''', ['%$query%', '%$query%']);
    return result.map((json) => Product.fromJson(json)).toList();
  }

  Future<List<Product>> getLowStockProducts() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT p.*, c.name as category_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE p.stock < 10
      ORDER BY p.stock ASC
    ''');
    return result.map((json) => Product.fromJson(json)).toList();
  }

  // Transaction CRUD
  Future<int> createTransaction(Transaction transaction) async {
    final db = await instance.database;
    
    // Insert transaction
    final transactionId = await db.insert(
      'transactions',
      transaction.toDatabase(),
    );

    // Insert transaction items
    for (var item in transaction.items) {
      await db.insert('transaction_items', {
        ...item.toDatabase(),
        'transaction_id': transactionId,
      });

      // Update product stock
      await db.rawUpdate('''
        UPDATE products 
        SET stock = stock - ? 
        WHERE id = ?
      ''', [item.quantity, item.productId]);
    }

    return transactionId;
  }

  Future<List<Transaction>> getAllTransactions() async {
    final db = await instance.database;
    final result = await db.query(
      'transactions',
      orderBy: 'created_at DESC',
    );

    List<Transaction> transactions = [];
    for (var json in result) {
      final items = await getTransactionItems(json['id'] as int);
      transactions.add(Transaction.fromJson({
        ...json,
        'items': items.map((item) => item.toJson()).toList(),
      }));
    }

    return transactions;
  }

  Future<List<TransactionItem>> getTransactionItems(int transactionId) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT ti.*, p.name as product_name
      FROM transaction_items ti
      LEFT JOIN products p ON ti.product_id = p.id
      WHERE ti.transaction_id = ?
    ''', [transactionId]);

    return result.map((json) => TransactionItem.fromJson(json)).toList();
  }

  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await instance.database;
    final result = await db.query(
      'transactions',
      where: 'created_at BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'created_at DESC',
    );

    List<Transaction> transactions = [];
    for (var json in result) {
      final items = await getTransactionItems(json['id'] as int);
      transactions.add(Transaction.fromJson({
        ...json,
        'items': items.map((item) => item.toJson()).toList(),
      }));
    }

    return transactions;
  }

  Future<void> clearAllData() async {
    final db = await instance.database;
    await db.delete('transaction_items');
    await db.delete('transactions');
    await db.delete('products');
    await db.delete('categories');
  }

  // Initialize demo data
  Future<void> initializeDemoData() async {
    final db = await instance.database;

    // Check if demo data already exists
    final categoryCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM categories')
    ) ?? 0;

    if (categoryCount > 0) return; // Demo data already exists

    // Insert demo categories
    final categoryIds = <int>[];
    final demoCategories = [
      {'name': 'Makanan', 'icon': '🍕'},
      {'name': 'Minuman', 'icon': '🥤'},
      {'name': 'Snack', 'icon': '🍿'},
    ];

    for (var category in demoCategories) {
      final id = await db.insert('categories', {
        'name': category['name'],
        'icon': category['icon'],
        'created_at': DateTime.now().toIso8601String(),
      });
      categoryIds.add(id);
    }

    // Insert demo products
    final demoProducts = [
      {'name': 'Nasi Goreng', 'price': 15000.0, 'stock': 50, 'category_id': categoryIds[0], 'barcode': '1001'},
      {'name': 'Ayam Bakar', 'price': 20000.0, 'stock': 30, 'category_id': categoryIds[0], 'barcode': '1002'},
      {'name': 'Es Teh', 'price': 5000.0, 'stock': 100, 'category_id': categoryIds[1], 'barcode': '2001'},
      {'name': 'Jus Jeruk', 'price': 8000.0, 'stock': 80, 'category_id': categoryIds[1], 'barcode': '2002'},
      {'name': 'Keripik Kentang', 'price': 10000.0, 'stock': 40, 'category_id': categoryIds[2], 'barcode': '3001'},
      {'name': 'Coklat Batang', 'price': 12000.0, 'stock': 60, 'category_id': categoryIds[2], 'barcode': '3002'},
    ];

    for (var product in demoProducts) {
      await db.insert('products', {
        'name': product['name'],
        'price': product['price'],
        'stock': product['stock'],
        'category_id': product['category_id'],
        'barcode': product['barcode'],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}