import 'package:flutter/material.dart';
import 'package:pocketpos/db/db_helper.dart';
import 'package:pocketpos/models/models.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;
  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _db = DBHelper();
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _catCtrl = TextEditingController();

  Product? _editProduct;
  bool _isEdit = false;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    // Primero intentar con el parámetro directo del constructor
    if (widget.product != null) {
      _editProduct = widget.product;
      _isEdit = true;
      _nameCtrl.text = _editProduct!.name;
      _priceCtrl.text = _editProduct!.price.toString();
      _stockCtrl.text = _editProduct!.stock.toString();
      _catCtrl.text = _editProduct!.category;
    }
  }

  Future<void> _loadCategories() async {
    final products = await _db.getProducts();
    setState(() {
      _categories = products.map((p) => p.category).toSet().toList();
      _categories.sort();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fallback: también soportar route arguments (compatibilidad hacia atrás)
    if (_editProduct == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Product) {
        setState(() {
          _editProduct = args;
          _isEdit = true;
          _nameCtrl.text = _editProduct!.name;
          _priceCtrl.text = _editProduct!.price.toString();
          _stockCtrl.text = _editProduct!.stock.toString();
          _catCtrl.text = _editProduct!.category;
        });
      }
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

    try {
      if (_isEdit) {
        await _db.updateProduct(product);
      } else {
        await _db.insertProduct(product);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error de base de datos al guardar.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                  final price = double.tryParse(v);
                  if (price == null) return 'Ingrese un número válido';
                  if (price < 0) return 'El precio debe ser positivo';
                  return null;
                },
              ),
              TextFormField(
                controller: _stockCtrl,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Campo requerido';
                  final stock = int.tryParse(v);
                  if (stock == null) return 'Ingrese un número entero';
                  if (stock < 0) return 'El stock debe ser positivo';
                  return null;
                },
              ),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return _categories;
                  }
                  return _categories.where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  _catCtrl.text = selection;
                },
                fieldViewBuilder: (BuildContext context, TextEditingController textEditingController,
                    FocusNode focusNode, VoidCallback onFieldSubmitted) {
                  if (textEditingController.text.isEmpty && _catCtrl.text.isNotEmpty) {
                    textEditingController.text = _catCtrl.text;
                  }
                  textEditingController.addListener(() {
                    _catCtrl.text = textEditingController.text;
                  });
                  return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      hintText: 'Selecciona o escribe una nueva',
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
                  );
                },
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
