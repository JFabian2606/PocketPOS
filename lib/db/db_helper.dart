import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:pocketpos/models/models.dart';

class DBHelper {
  // Patrón Singleton
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pocketpos.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabla productos
    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        stock INTEGER NOT NULL,
        category TEXT NOT NULL
      )
    ''');

    // Tabla ventas
    await db.execute('''
      CREATE TABLE ventas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        total REAL NOT NULL,
        payment_method TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');

    // Tabla usuarios (SCRUM-41)
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'user'
      )
    ''');
    
    // Insertar usuario por defecto (admin)
    // El hash de '123456' en SHA-256 es '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92'
    await db.insert('users', {
      'email': 'admin@pocketpos.com',
      'password_hash': '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92',
      'role': 'admin'
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          "ALTER TABLE ventas ADD COLUMN payment_method TEXT NOT NULL DEFAULT 'Efectivo'");
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          email TEXT UNIQUE NOT NULL,
          password_hash TEXT NOT NULL,
          role TEXT NOT NULL DEFAULT 'user'
        )
      ''');
      await db.insert('users', {
        'email': 'admin@pocketpos.com',
        'password_hash': '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92',
        'role': 'admin'
      });
    }
  }

  // ── CRUD Productos ─────────────────────────────────────────

  Future<int> insertProduct(Product p) async {
    final db = await database;
    final map = p.toJson()..remove('id');
    return await db.insert('products', map);
  }

  Future<List<Product>> getProducts() async {
    final db = await database;
    final result = await db.query('products');
    return result.map((e) => Product.fromJson(e)).toList();
  }

  Future<int> updateProduct(Product p) async {
    final db = await database;
    return await db.update(
      'products',
      p.toJson(),
      where: 'id = ?',
      whereArgs: [p.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // ── CRUD Ventas ────────────────────────────────────────────

  Future<int> insertVenta(Map<String, dynamic> venta) async {
    final db = await database;
    return await db.insert('ventas', venta);
  }

  /// Procesa una venta completa (carrito):
  /// 1. Verifica stock (SCRUM-35)
  /// 2. Reduce stock (SCRUM-34)
  /// 3. Inserta cada venta con metodo de pago (SCRUM-33 / SCRUM-39)
  Future<void> processSale(List<CartItem> cartItems, PaymentMethod paymentMethod) async {
    final db = await database;

    await db.transaction((txn) async {
      for (final item in cartItems) {
        // Consultar stock actual
        final res = await txn.query('products',
            columns: ['stock'], where: 'id = ?', whereArgs: [item.product.id]);
        
        if (res.isEmpty) throw Exception('Producto no encontrado');
        final currentStock = res.first['stock'] as int;

        if (currentStock < item.quantity) {
          throw Exception('Stock insuficiente para ${item.product.name}');
        }

        // 1. Reducir stock
        final newStock = currentStock - item.quantity;
        await txn.update(
          'products',
          {'stock': newStock},
          where: 'id = ?',
          whereArgs: [item.product.id],
        );

        // 2. Insertar venta
        await txn.insert('ventas', {
          'product_id': item.product.id,
          'quantity': item.quantity,
          'total': item.subtotal,
          'payment_method': paymentMethod.name,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  Future<List<Map<String, dynamic>>> getVentas() async {
    final db = await database;
    return await db.query('ventas', orderBy: 'created_at DESC');
  }

  // ── CRUD Users ─────────────────────────────────────────────

  Future<Map<String, dynamic>?> authenticateUser(String email, String hash) async {
    final db = await database;
    final res = await db.query(
      'users',
      where: 'email = ? AND password_hash = ?',
      whereArgs: [email, hash],
    );
    if (res.isNotEmpty) return res.first;
    return null;
  }
}
