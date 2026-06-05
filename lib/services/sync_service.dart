import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pocketpos/db/db_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pocketpos/models/models.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;
  final _supabase = Supabase.instance.client;

  void initialize() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    _checkInitialConnection();
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  Future<void> _checkInitialConnection() async {
    final results = await _connectivity.checkConnectivity();
    _updateConnectionStatus(results);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> results) async {
    bool isConnected = results.any((result) => 
      result == ConnectivityResult.mobile || 
      result == ConnectivityResult.wifi || 
      result == ConnectivityResult.ethernet
    );

    if (isConnected) {
      if (kDebugMode) {
        print('Conexión detectada. Iniciando sincronización...');
      }
      await syncPendingData();
    } else {
      if (kDebugMode) {
        print('Sin conexión de red válida para sincronizar.');
      }
    }
  }

  Future<void> syncPendingData() async {
    if (_isSyncing) return;
    
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (kDebugMode) print('No hay sesión de Supabase activa. Omitiendo sync.');
      return;
    }

    _isSyncing = true;

    try {
      final dbHelper = DBHelper();
      
      // --- 1. Sincronizar Productos (Descargar si está vacío localmente) ---
      final localProducts = await dbHelper.getProducts();
      if (localProducts.isEmpty) {
        if (kDebugMode) print('Descargando productos desde Supabase...');
        try {
          final remoteProducts = await _supabase.from('products').select().eq('user_email', user.email!);
          for (var rp in remoteProducts) {
             final product = Product(
               id: rp['id'],
               name: rp['name'],
               price: (rp['price'] as num).toDouble(),
               stock: rp['stock'],
               category: rp['category']
             );
             // Solo insertamos local, dbHelper maneja user_email
             await dbHelper.insertProduct(product);
          }
          if (kDebugMode) print('${remoteProducts.length} productos descargados.');
        } catch(e) {
           if (kDebugMode) print('Error descargando productos: $e');
        }
      } else {
        // Simple subida: Actualizar stock/precios en Supabase para los productos locales. 
        // (En una app real se usa una marca de tiempo 'updated_at')
        for (var p in localProducts) {
          try {
             // Upsert (insert or update)
             await _supabase.from('products').upsert({
               'id': p.id,
               'name': p.name,
               'price': p.price,
               'stock': p.stock,
               'category': p.category,
               'user_email': user.email
             });
          } catch(e) {
            // Ignorar errores menores de sync individual
          }
        }
      }

      // --- 2. Sincronizar Ventas Pendientes (Subir a Supabase) ---
      final pendingVentas = await dbHelper.getPendingVentas();

      if (pendingVentas.isEmpty) {
        if (kDebugMode) print('No hay ventas pendientes de sincronización.');
        _isSyncing = false;
        return;
      }

      if (kDebugMode) print('Sincronizando ${pendingVentas.length} ventas...');

      List<int> syncedIds = [];

      for (var venta in pendingVentas) {
        try {
           final Map<String, dynamic> supabaseData = {
              'product_id': venta['product_id'],
              'quantity': venta['quantity'],
              'total': venta['total'],
              'payment_method': venta['payment_method'],
              'created_at': venta['created_at'],
              'user_email': venta['user_email']
           };
           
           await _supabase.from('ventas').insert(supabaseData);
           syncedIds.add(venta['id'] as int);
        } catch(e) {
           if (kDebugMode) print('Error al sincronizar venta ${venta['id']}: $e');
        }
      }

      // Marcar como sincronizadas en la base de datos local
      if (syncedIds.isNotEmpty) {
        await dbHelper.markVentasAsSynced(syncedIds);
      }

      if (kDebugMode) print('Sincronización completada con éxito.');
      
    } catch (e) {
      if (kDebugMode) print('Error general durante la sincronización: $e');
    } finally {
      _isSyncing = false;
    }
  }
}
