import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pocketpos/db/db_helper.dart';
import 'package:pocketpos/models/models.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _db = DBHelper();
  final _searchCtrl = TextEditingController();

  List<Product> _allProducts = [];
  List<Product> _filtered = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchCtrl.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final data = await _db.getProducts();
    setState(() {
      _allProducts = data;
      _filtered = data;
    });
  }

  // Filtra en tiempo real por nombre
  void _applyFilters() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _allProducts
          .where((p) => p.name.toLowerCase().contains(query))
          .toList();
    });
  }

  Future<void> _deleteProduct(int id) async {
    await _db.deleteProduct(id);
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final copFormat = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── SearchBar ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _applyFilters();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
              ),
            ),
          ),

          // ── Lista filtrada ───────────────────────────────────
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('No se encontraron productos.'))
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final p = _filtered[index];
                      return ListTile(
                        leading: const Icon(Icons.shopping_bag_outlined),
                        title: Text(p.name),
                        subtitle: Text(
                            'Categoría: ${p.category} | Stock: ${p.stock}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(copFormat.format(p.price),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                await Navigator.pushNamed(
                                    context, 'product-form',
                                    arguments: p);
                                _loadProducts();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteProduct(p.id!),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, 'product-form');
          _loadProducts();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
