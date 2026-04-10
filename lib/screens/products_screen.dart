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
  List<Product> products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final data = await DBHelper.getProducts();
    setState(() => products = data);
  }

  Future<void> _deleteProduct(int id) async {
    await DBHelper.deleteProduct(id);
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
      body: products.isEmpty
          ? const Center(child: Text('No hay productos. Agrega uno.'))
          : ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final p = products[index];
                return ListTile(
                  leading: const Icon(Icons.shopping_bag_outlined),
                  title: Text(p.name),
                  subtitle: Text(
                      'Categoría: ${p.category} | Stock: ${p.stock}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(copFormat.format(p.price),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          await Navigator.pushNamed(context, 'product-form',
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
