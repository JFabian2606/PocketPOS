import 'package:flutter/material.dart';
import 'package:pocketpos/models/models.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  double _discount = 0.0;

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.subtotal);

  double get discount => _discount;

  double get total => (subtotal - _discount) < 0 ? 0 : (subtotal - _discount);

  bool get isEmpty => _items.isEmpty;

  void setDiscount(double amount) {
    _discount = amount;
    notifyListeners();
  }

  /// Agrega un producto al carrito.
  /// Si ya existe, incrementa la cantidad en 1. Retorna true si fue exitoso,
  /// o false si no hay suficiente stock.
  bool addProduct(Product product) {
    final index = _items.indexWhere((i) => i.product.id == product.id);
    int currentQty = 0;
    if (index >= 0) {
      currentQty = _items[index].quantity;
    }

    if (currentQty + 1 > product.stock) {
      return false;
    }

    if (index >= 0) {
      _items[index] = _items[index].copyWith(quantity: currentQty + 1);
    } else {
      _items.add(CartItem(product: product));
    }
    notifyListeners();
    return true;
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
    _discount = 0.0;
    notifyListeners();
  }

  // Notificador global para eventos de venta completada (para actualizar el dashboard en tiempo real)
  static final ValueNotifier<int> salesNotifier = ValueNotifier<int>(0);

  void recordSale() {
    salesNotifier.value++;
  }
}
