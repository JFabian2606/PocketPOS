import 'package:flutter/material.dart';
import 'package:pocketpos/db/db_helper.dart';
import 'package:pocketpos/models/models.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _catCtrl = TextEditingController();

  Product? _editProduct;
  bool _isEdit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Product) {
      _editProduct = args;
      _isEdit = true;
      _nameCtrl.text = _editProduct!.name;
      _priceCtrl.text = _editProduct!.price.toString();
      _stockCtrl.text = _editProduct!.stock.toString();
      _catCtrl.text = _editProduct!.category;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final product = Product(
      id: _editProduct?.id,
      name: _nameCtrl.text.trim(),
      price: double.parse(_priceCtrl.text.trim()),
      stock: int.parse(_stockCtrl.text.trim()),
      category: _catCtrl.text.trim(),
    );

    if (_isEdit) {
      await DBHelper.updateProduct(product);
    } else {
      await DBHelper.insertProduct(product);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar Producto' : 'Agregar Producto'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _priceCtrl,
                decoration: const InputDecoration(labelText: 'Precio (COP)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Campo requerido';
                  if (double.tryParse(v) == null) return 'Ingrese un número válido';
                  return null;
                },
              ),
              TextFormField(
                controller: _stockCtrl,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Campo requerido';
                  if (int.tryParse(v) == null) return 'Ingrese un número entero';
                  return null;
                },
              ),
              TextFormField(
                controller: _catCtrl,
                decoration: const InputDecoration(labelText: 'Categoría'),
                validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _save,
                child: Text(_isEdit ? 'Guardar Cambios' : 'Agregar Producto'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
