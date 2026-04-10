import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpos/models/models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pocketpos/db/db_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DBHelper - Operaciones básicas de lectura/escritura', () {
    final db = DBHelper();

    test('Insertar un producto', () async {
      final product = Product(
        name: 'Agua',
        price: 1500,
        stock: 20,
        category: 'Bebidas',
      );
      final id = await db.insertProduct(product);
      expect(id, greaterThan(0));
    });

    test('Obtener todos los productos', () async {
      final products = await db.getProducts();
      expect(products, isNotEmpty);
    });

    test('Actualizar un producto', () async {
      final products = await db.getProducts();
      final updated = Product(
        id: products.first.id,
        name: 'Agua Fría',
        price: 2000,
        stock: 15,
        category: 'Bebidas',
      );
      final rows = await db.updateProduct(updated);
      expect(rows, 1);
    });

    test('Eliminar un producto', () async {
      final products = await db.getProducts();
      final rows = await db.deleteProduct(products.first.id!);
      expect(rows, 1);
    });

    test('Insertar una venta', () async {
      final id = await db.insertVenta({
        'product_id': 1,
        'quantity': 3,
        'total': 4500.0,
        'created_at': DateTime.now().toIso8601String(),
      });
      expect(id, greaterThan(0));
    });

    test('Obtener todas las ventas', () async {
      final ventas = await db.getVentas();
      expect(ventas, isA<List>());
    });
  });
}
