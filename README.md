# Smart Cashier Flutter Application

Aplikasi kasir cerdas dengan fitur AI untuk rekomendasi produk, manajemen transaksi, dan laporan penjualan.

## 🚀 Fitur Utama

### 1. **Autentikasi Pengguna**
- ✅ Login & Register
- ✅ Reset Password
- ✅ Role-based Access (Admin & Kasir)
- ✅ Token Management

### 2. **Manajemen Produk**
- ✅ CRUD Produk (Create, Read, Update, Delete)
- ✅ Kategori Produk
- ✅ Manajemen Stok
- ✅ Pencarian Produk
- ✅ Barcode Support

### 3. **Transaksi Penjualan**
- ✅ Input Transaksi Cepat
- ✅ Keranjang Belanja
- ✅ Hitung Total Otomatis (dengan Pajak & Diskon)
- ✅ Multiple Payment Methods (Cash, Card, QRIS)
- ✅ Struk Penjualan

### 4. **AI Rekomendasi Produk**
- ✅ Rekomendasi untuk Pelanggan
- ✅ Produk Populer
- ✅ Frequently Bought Together
- ✅ High Stock Priority

### 5. **Laporan Penjualan**
- ✅ Laporan Harian/Mingguan/Bulanan
- ✅ Filter Laporan
- ✅ Export PDF/Excel
- ✅ Grafik & Analytics

### 6. **Notifikasi & Reminder**
- ✅ Stok Menipis
- ✅ Promo & Penawaran

### 7. **Dashboard**
- ✅ Dashboard Admin
- ✅ Dashboard Kasir
- ✅ Real-time Statistics

### 8. **Fitur Tambahan**
- ✅ Dark Mode
- ✅ Offline Data Storage (SQLite)
- ✅ Multi-device Sync
- ✅ Barcode Scanner

## 📋 Prerequisites

- Flutter SDK (>=2.18.0 <3.0.0)
- Dart SDK
- Android Studio / VS Code
- Laravel Backend API (untuk produksi)

## 🛠️ Installation

### 1. Clone Repository

```bash
git clone <repository-url>
cd smart_cashier_flutter
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Konfigurasi API

Edit file `lib/utils/constants.dart`:

```dart
// Untuk emulator Android
static const String apiBaseUrl = 'http://10.0.2.2:8000/api';

// Untuk device fisik, ganti dengan IP komputer Anda
// static const String apiBaseUrl = 'http://192.168.1.5:8000/api';
```

### 4. Run Application

```bash
flutter run
```

## 📁 Struktur Folder

```
lib/
├── models/              # Data models
│   ├── user_model.dart
│   ├── product_model.dart
│   ├── category_model.dart
│   ├── transaction_model.dart
│   └── transaction_item_model.dart
├── providers/           # State management
│   ├── auth_provider.dart
│   ├── product_provider.dart
│   └── transaction_provider.dart
├── screens/             # UI screens
│   ├── login_page.dart
│   ├── register_page.dart
│   ├── kasir_dashboard.dart
│   ├── admin_dashboard.dart
│   ├── sales_screen.dart
│   ├── product_list_screen.dart
│   └── transaction_history_screen.dart
├── services/            # Business logic
│   ├── auth_service.dart
│   ├── api_service.dart
│   └── database_service.dart
├── utils/               # Helpers
│   └── constants.dart
└── main.dart           # Entry point
```

## 🔑 Default Credentials

**Admin:**
- Email: admin@smartcashier.com
- Password: admin123

**Kasir:**
- Email: kasir@smartcashier.com
- Password: kasir123

## 🌐 API Endpoints

### Authentication
- `POST /api/login` - Login user
- `POST /api/register` - Register new user
- `POST /api/reset-password` - Reset password
- `POST /api/logout` - Logout user

### Products
- `GET /api/products` - Get all products
- `POST /api/products` - Create product
- `PUT /api/products/{id}` - Update product
- `DELETE /api/products/{id}` - Delete product
- `GET /api/categories` - Get categories

### Transactions
- `POST /api/transactions` - Create transaction
- `GET /api/transactions` - Get all transactions
- `GET /api/transactions/{id}` - Get transaction detail

### AI Recommendations
- `POST /api/recommendations/customer` - Get customer recommendations
- `GET /api/recommendations/popular` - Get popular products
- `GET /api/recommendations/upsell` - Get upsell recommendations

### Reports
- `GET /api/reports/daily` - Daily report
- `GET /api/reports/weekly` - Weekly report
- `GET /api/reports/monthly` - Monthly report
- `POST /api/reports/export` - Export report

## 💾 Local Database (SQLite)

Aplikasi menggunakan SQLite untuk penyimpanan offline:

**Tables:**
- `categories` - Kategori produk
- `products` - Data produk
- `transactions` - Transaksi penjualan
- `transaction_items` - Item transaksi

## 🎨 Tech Stack

- **Framework:** Flutter
- **Language:** Dart
- **State Management:** Provider
- **Local Database:** SQLite (sqflite)
- **Storage:** SharedPreferences
- **HTTP Client:** http package
- **Charts:** fl_chart
- **PDF Generation:** pdf package
- **Barcode Scanner:** flutter_barcode_scanner

## 📱 Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## 🤝 Contributing

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 📞 Support

For support, email support@smartcashier.com or create an issue in this repository.

---

**Note:** Aplikasi ini memerlukan Laravel backend API untuk berfungsi penuh. Untuk development, Anda dapat menggunakan mode offline dengan SQLite saja.