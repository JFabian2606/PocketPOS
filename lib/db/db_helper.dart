// SQLite v2 - Base de datos local para PocketPOS
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'package:pocketpos/models/models.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pocketpos.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE products(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            price REAL NOT NULL,
            stock INTEGER NOT NULL,
            category TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // Insertar producto
  static Future<int> insertProduct(Product p) async {
    final db = await database;
    return await db.insert('products', p.toJson()..remove('id'));
  }

  // Obtener todos los productos
  static Future<List<Product>> getProducts() async {
    final db = await database;
    final result = await db.query('products');
    return result.map((e) => Product.fromJson(e)).toList();
  }

  // Actualizar producto
  static Future<int> updateProduct(Product p) async {
    final db = await database;
    return await db.update(
      'products',
      p.toJson(),
      where: 'id = ?',
      whereArgs: [p.id],
    );
  }

  // Eliminar producto
  static Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }
}
