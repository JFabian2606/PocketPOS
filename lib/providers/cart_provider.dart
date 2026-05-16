import 'package:flutter/material.dart';
import 'package:pocketpos/models/models.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get total => _items.fold(0.0, (sum, item) => sum + item.subtotal);

  bool get isEmpty => _items.isEmpty;

  /// Agrega un producto al carrito.
  /// Si ya existe, incrementa la cantidad en 1.
  void addProduct(Product product) {
    final index = _items.indexWhere((i) => i.product.id == product.id);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(quantity: _items[index].quantity + 1);
    } else {
      _items.add(CartItem(product: product));
    }
    notifyListeners();
  }

  /// Decrementa la cantidad. Si llega a 0, elimina el ítem.
  void decrementProduct(Product product) {
    final index = _items.indexWhere((i) => i.product.id == product.id);
    if (index < 0) return;
    if (_items[index].quantity > 1) {
      _items[index] = _items[index].copyWith(quantity: _items[index].quantity - 1);
    } else {
      _items.removeAt(index);
    }
    notifyListeners();
  }

  /// Elimina completamente un ítem del carrito.
  void removeProduct(Product product) {
    _items.removeWhere((i) => i.product.id == product.id);
    notifyListeners();
  }

  /// Vacía el carrito por completo.
  void clear() {
    _items.clear();
    notifyListeners();
  }
}
