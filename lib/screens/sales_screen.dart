import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/auth_provider.dart';
import '../models/product_model.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _searchResults = [];

  @override
  void initState() {
    super.initState();
    // Delay provider calls until after first frame to avoid use_build_context_synchronously
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      productProvider.loadProducts();
      setState(() {
        _searchResults = productProvider.products;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    if (query.isEmpty) {
      setState(() {
        _searchResults = productProvider.products;
      });
      return;
    }

    final results = await productProvider.searchProducts(query);
    setState(() {
      _searchResults = results;
    });
  }

  void _showQuantityDialog(Product product) {
    int quantity = 1;
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('Tambah: ${product.name}'),
          content: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  if (quantity > 1) {
                    setState(() => quantity--);
                  }
                },
              ),
              Text('$quantity'),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  setState(() => quantity++);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Provider.of<TransactionProvider>(context, listen: false)
                    .addToCart(product, quantity);
                Navigator.of(context).pop();
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentModal() {
    final tp = Provider.of<TransactionProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final TextEditingController amountController = TextEditingController();
    String method = tp.paymentMethod;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pembayaran', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Total: Rp ${tp.total.toStringAsFixed(0)}'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: method,
                items: ['cash', 'card', 'qris', 'transfer']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) {
                  method = v ?? 'cash';
                },
                decoration: const InputDecoration(labelText: 'Metode Pembayaran'),
              ),
              const SizedBox(height: 8),
              if (method == 'cash')
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Jumlah Tunai'),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Batal'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                        // Capture values and messenger before async gaps
                        tp.setPaymentMethod(method);
                        final scaffold = ScaffoldMessenger.of(context);
                        final totalBefore = tp.total;
                        double paid = 0;
                        if (method == 'cash') {
                          paid = double.tryParse(amountController.text) ?? 0;
                          if (paid < totalBefore) {
                            scaffold.showSnackBar(const SnackBar(content: Text('Jumlah tunai kurang')));
                            return;
                          }
                        }

                        final userId = auth.user?.id ?? 1; // fallback demo id
                        final modalNavigator = Navigator.of(ctx);
                        final success = await tp.completeTransaction(userId, context: context);
                        modalNavigator.pop();

                        if (success) {
                          String message = 'Transaksi berhasil';
                          if (method == 'cash') {
                            final change = paid - totalBefore;
                            message += '\nKembalian: Rp ${change.toStringAsFixed(0)}';
                          }
                          scaffold.showSnackBar(SnackBar(content: Text(message)));
                        } else {
                          scaffold.showSnackBar(const SnackBar(content: Text('Gagal menyelesaikan transaksi')));
                        }
                      },
                    child: const Text('Bayar'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final tp = Provider.of<TransactionProvider>(context);

    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi Penjualan'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: isWide
            ? Row(
                children: [
                  // Products
                  Expanded(child: _buildProductList(productProvider)),
                  const SizedBox(width: 12),
                  // Cart
                  SizedBox(width: 420, child: _buildCart(tp)),
                ],
              )
            : Column(
                children: [
                  Expanded(child: _buildProductList(productProvider)),
                  const SizedBox(height: 8),
                  SizedBox(height: 320, child: _buildCart(tp)),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: tp.currentCart.isEmpty ? null : _showPaymentModal,
        label: const Text('Checkout'),
        icon: const Icon(Icons.payment),
      ),
    );
  }

  Widget _buildProductList(ProductProvider productProvider) {
    final products = _searchController.text.isEmpty ? productProvider.products : _searchResults;

    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Cari produk atau barcode',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => _search(v),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: productProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (ctx, i) {
                    final p = products[i];
                    return ListTile(
                      leading: p.image != null
                          ? Image.network(p.image!, width: 48, height: 48, fit: BoxFit.cover)
                          : const Icon(Icons.inventory_2),
                      title: Text(p.name),
                      subtitle: Text('Rp ${p.price.toStringAsFixed(0)} | Stok: ${p.stock}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_shopping_cart),
                        onPressed: () => _showQuantityDialog(p),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCart(TransactionProvider tp) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Keranjang', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Expanded(
              child: tp.currentCart.isEmpty
                  ? const Center(child: Text('Keranjang kosong'))
                  : ListView.separated(
                      itemCount: tp.currentCart.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (ctx, i) {
                        final item = tp.currentCart[i];
                        return ListTile(
                          title: Text(item.productName),
                          subtitle: Text('Rp ${item.price.toStringAsFixed(0)} x ${item.quantity}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () => tp.updateItemQuantity(item.productId, item.quantity - 1),
                              ),
                              Text('${item.quantity}'),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => tp.updateItemQuantity(item.productId, item.quantity + 1),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => tp.removeFromCart(item.productId),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            Text('Subtotal: Rp ${tp.subtotal.toStringAsFixed(0)}'),
            const SizedBox(height: 4),
            Text('Pajak (10%): Rp ${tp.tax.toStringAsFixed(0)}'),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text('Diskon: Rp '),
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    initialValue: tp.discount.toStringAsFixed(0),
                    keyboardType: TextInputType.number,
                    onFieldSubmitted: (v) {
                      final d = double.tryParse(v) ?? 0;
                      tp.setDiscount(d);
                    },
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Total: Rp ${tp.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: tp.currentCart.isEmpty ? null : _showPaymentModal,
                child: const Text('Bayar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}