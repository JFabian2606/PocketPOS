import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      version: 5,
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
        category TEXT NOT NULL,
        user_email TEXT NOT NULL DEFAULT 'admin@pocketpos.com'
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
        sync_pending INTEGER NOT NULL DEFAULT 1,
        user_email TEXT NOT NULL DEFAULT 'admin@pocketpos.com',
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
      try {
        await db.execute(
            "ALTER TABLE ventas ADD COLUMN payment_method TEXT NOT NULL DEFAULT 'Efectivo'");
      } catch (e) {
        // Ignorar error si la columna ya existe
      }
    }
    if (oldVersion < 3) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            role TEXT NOT NULL DEFAULT 'user'
          )
        ''');
        
        // Verificar si el usuario ya existe para no duplicarlo
        final res = await db.query('users', where: 'email = ?', whereArgs: ['admin@pocketpos.com']);
        if (res.isEmpty) {
          await db.insert('users', {
            'email': 'admin@pocketpos.com',
            'password_hash': '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92',
            'role': 'admin'
          });
        }
      } catch (e) {
        // Ignorar si hubo un fallo en la creación por existencia previa
      }
    }
    if (oldVersion < 4) {
      try {
        await db.execute(
            "ALTER TABLE ventas ADD COLUMN sync_pending INTEGER NOT NULL DEFAULT 1");
      } catch (e) {
        // Ignorar error si la columna ya existe
      }
    }
    if (oldVersion < 5) {
      try {
        await db.execute("ALTER TABLE products ADD COLUMN user_email TEXT NOT NULL DEFAULT 'admin@pocketpos.com'");
        await db.execute("ALTER TABLE ventas ADD COLUMN user_email TEXT NOT NULL DEFAULT 'admin@pocketpos.com'");
      } catch (e) {
        // Ignorar
      }
    }
  }

  Future<String> _getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userEmail') ?? 'admin@pocketpos.com';
  }

  // ── CRUD Productos ─────────────────────────────────────────

  Future<int> insertProduct(Product p) async {
    final db = await database;
    final map = p.toJson()..remove('id');
    map['user_email'] = await _getCurrentUser();
    return await db.insert('products', map);
  }

  Future<List<Product>> getProducts() async {
    final db = await database;
    final user = await _getCurrentUser();
    final result = await db.query('products', where: 'user_email = ?', whereArgs: [user]);
    return result.map((e) => Product.fromJson(e)).toList();
  }

  Future<int> updateProduct(Product p) async {
    final db = await database;
    final user = await _getCurrentUser();
    return await db.update(
      'products',
      p.toJson(),
      where: 'id = ? AND user_email = ?',
      whereArgs: [p.id, user],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    final user = await _getCurrentUser();
    return await db.delete('products', where: 'id = ? AND user_email = ?', whereArgs: [id, user]);
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
  Future<void> processSale(List<CartItem> cartItems, PaymentMethod paymentMethod, {double discount = 0}) async {
    final db = await database;
    final totalSubtotal = cartItems.fold(0.0, (sum, item) => sum + item.subtotal);

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

        // 2. Insertar venta con descuento distribuido
        final itemDiscount = totalSubtotal > 0 ? (item.subtotal / totalSubtotal) * discount : 0;
        final finalTotal = item.subtotal - itemDiscount;
        final userEmail = await _getCurrentUser();
        
        await txn.insert('ventas', {
          'product_id': item.product.id,
          'quantity': item.quantity,
          'total': finalTotal,
          'payment_method': paymentMethod.name,
          'created_at': DateTime.now().toIso8601String(),
          'sync_pending': 1,
          'user_email': userEmail,
        });
      }
    });
  }

  Future<List<Map<String, dynamic>>> getVentas() async {
    final db = await database;
    final user = await _getCurrentUser();
    return await db.query('ventas', where: 'user_email = ?', whereArgs: [user], orderBy: 'created_at DESC');
  }

  Future<List<Map<String, dynamic>>> getVentasAgrupadasPorFecha() async {
    final db = await database;
    final user = await _getCurrentUser();
    return await db.rawQuery('''
      SELECT 
        substr(created_at, 1, 10) AS fecha,
        SUM(total) AS total_ventas,
        SUM(quantity) AS cantidad_items,
        COUNT(id) AS transacciones
      FROM ventas
      WHERE user_email = ?
      GROUP BY fecha
      ORDER BY fecha DESC
    ''', [user]);
  }

  Future<List<Map<String, dynamic>>> getVentasPorFecha(String date) async {
    final db = await database;
    final user = await _getCurrentUser();
    return await db.rawQuery('''
      SELECT 
        v.id,
        v.product_id,
        COALESCE(p.name, 'Producto Eliminado') as product_name,
        v.quantity,
        v.total,
        v.payment_method,
        v.created_at
      FROM ventas v
      LEFT JOIN products p ON v.product_id = p.id
      WHERE substr(v.created_at, 1, 10) = ? AND v.user_email = ?
      ORDER BY v.created_at DESC
    ''', [date, user]);
  }

  Future<List<Map<String, dynamic>>> getPendingVentas() async {
    final db = await database;
    final user = await _getCurrentUser();
    return await db.query('ventas', where: 'sync_pending = 1 AND user_email = ?', whereArgs: [user]);
  }

  Future<void> markVentasAsSynced(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.update(
      'ventas',
      {'sync_pending': 0},
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
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

  Future<bool> registerUser(String email, String hash) async {
    final db = await database;
    try {
      // Verificar si el correo ya existe
      final existing = await db.query('users', where: 'email = ?', whereArgs: [email]);
      if (existing.isNotEmpty) {
        return false; // El usuario ya existe
      }
      
      await db.insert('users', {
        'email': email,
        'password_hash': hash,
        'role': 'user' // Por defecto, todos los nuevos registros son usuarios normales
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
