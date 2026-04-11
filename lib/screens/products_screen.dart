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

  String? _selectedCategory; // null = todas
  String _sortBy = 'nombre';  // 'nombre' | 'precio_asc' | 'precio_desc'

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
      _applyFilters();
    });
  }

  // Devuelve la lista de categorías únicas
  List<String> get _categories {
    final cats = _allProducts.map((p) => p.category).toSet().toList();
    cats.sort();
    return cats;
  }

  void _applyFilters() {
    final query = _searchCtrl.text.toLowerCase();

    List<Product> result = _allProducts.where((p) {
      final matchName = p.name.toLowerCase().contains(query);
      final matchCat =
          _selectedCategory == null || p.category == _selectedCategory;
      return matchName && matchCat;
    }).toList();

    // Ordenar
    if (_sortBy == 'precio_asc') {
      result.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'precio_desc') {
      result.sort((a, b) => b.price.compareTo(a.price));
    } else {
      result.sort((a, b) => a.name.compareTo(b.name));
    }

    setState(() => _filtered = result);
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
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
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

          // ── Filtros: Categoría y Precio ──────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                // Dropdown categoría
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Categoría',
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todas')),
                      ..._categories.map((c) =>
                          DropdownMenuItem(value: c, child: Text(c))),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedCategory = val);
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Dropdown ordenar por precio
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _sortBy,
                    decoration: InputDecoration(
                      labelText: 'Ordenar',
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'nombre', child: Text('Nombre')),
                      DropdownMenuItem(
                          value: 'precio_asc', child: Text('Precio ↑')),
                      DropdownMenuItem(
                          value: 'precio_desc', child: Text('Precio ↓')),
                    ],
                    onChanged: (val) {
                      setState(() => _sortBy = val!);
                      _applyFilters();
                    },
                  ),
                ),
              ],
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
