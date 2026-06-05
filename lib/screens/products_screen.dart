import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pocketpos/db/db_helper.dart';
import 'package:pocketpos/models/models.dart';
import 'package:pocketpos/providers/cart_provider.dart';
import 'package:pocketpos/screens/product_form_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';


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
    try {
      final data = await _db.getProducts();
      setState(() {
        _allProducts = data;
        _applyFilters();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar productos de la base de datos.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
    try {
      await _db.deleteProduct(id);
      _loadProducts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al eliminar el producto de la base de datos.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final copFormat = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    final cart = context.watch<CartProvider>();
    // Creamos la lista de categorías incluyendo "Todas" para los chips
    final displayCategories = ['Todas', ..._categories];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F1), // lumiere-cream
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F6F1).withValues(alpha: 0.95),
        elevation: 0,
        title: const Text('PocketPOS', style: TextStyle(color: Color(0xFF2D2926), fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: Color(0xFF2D2926)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: FutureBuilder<SharedPreferences>(
              future: SharedPreferences.getInstance(),
              builder: (context, snapshot) {
                final photo = snapshot.data?.getString('userPhoto') ?? '';
                final name = snapshot.data?.getString('userName') ?? 'AD';
                return CircleAvatar(
                  backgroundColor: const Color(0xFFA66D3F).withValues(alpha: 0.2),
                  radius: 16,
                  backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                  child: photo.isEmpty ? Text(name.substring(0, 2).toUpperCase(), style: const TextStyle(color: Color(0xFFA66D3F), fontWeight: FontWeight.bold, fontSize: 12)) : null,
                );
              }
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E1DA)),
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Buscar productos...',
                  hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF9E9E9E), size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => _searchCtrl.clear(),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // Category Chips
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              itemCount: displayCategories.length,
              itemBuilder: (context, index) {
                final category = displayCategories[index];
                final isSelected = (category == 'Todas' && _selectedCategory == null) || (category == _selectedCategory);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category == 'Todas' ? null : category;
                        _applyFilters();
                      });
                    },
                    selectedColor: const Color(0xFFA66D3F),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF717171),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? Colors.transparent : const Color(0xFFE5E1DA),
                      ),
                    ),
                    showCheckmark: false,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Sort Filter Dropdown (Optional mini dropdown below chips, or keep it hidden for clean UI)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                DropdownButton<String>(
                  value: _sortBy,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.sort, size: 16, color: Color(0xFF717171)),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF717171), fontWeight: FontWeight.bold),
                  items: const [
                    DropdownMenuItem(value: 'nombre', child: Text('Ordenar por Nombre')),
                    DropdownMenuItem(value: 'precio_asc', child: Text('Precio: Menor a Mayor')),
                    DropdownMenuItem(value: 'precio_desc', child: Text('Precio: Mayor a Menor')),
                  ],
                  onChanged: (val) {
                    setState(() => _sortBy = val!);
                    _applyFilters();
                  },
                ),
              ],
            ),
          ),

          // Product Grid
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('No se encontraron productos.', style: TextStyle(color: Color(0xFF717171))))
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final p = _filtered[index];
                      // Determine stock status logic
                      Color stockColor = Colors.green;
                      String stockText = '• En Stock (${p.stock})';
                      if (p.stock <= 0) {
                        stockColor = Colors.red;
                        stockText = '• Agotado';
                      } else if (p.stock <= 5) {
                        stockColor = Colors.orange;
                        stockText = '• Stock Bajo (${p.stock})';
                      }

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Image Placeholder
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1EBE4),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.local_cafe_outlined, // Generic icon
                                  size: 40,
                                  color: Colors.black26,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Product Details
                            Text(
                              p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D2926)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stockText,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: stockColor),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  copFormat.format(p.price),
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF2D2926)),
                                ),
                                InkWell(
                                  onTap: p.stock > 0
                                      ? () {
                                          final success = context.read<CartProvider>().addProduct(p);
                                          if (success) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('${p.name} added to cart'),
                                                duration: const Duration(seconds: 1),
                                                behavior: SnackBarBehavior.floating,
                                                backgroundColor: const Color(0xFFA66D3F),
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Not enough stock for ${p.name}'),
                                                backgroundColor: Colors.orange,
                                                duration: const Duration(seconds: 2),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        }
                                      : null,
                                  onLongPress: () async {
                                    // Utilizado para editar o borrar en vez de los iconos
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProductFormScreen(product: p),
                                      ),
                                    );
                                    _loadProducts();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: p.stock > 0 ? const Color(0xFFA66D3F) : Colors.grey.shade300,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                                  ),
                                ),
                              ],
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
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ProductFormScreen(),
            ),
          );
          _loadProducts();
        },
        backgroundColor: const Color(0xFFA66D3F),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
