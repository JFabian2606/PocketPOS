import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pocketpos/db/db_helper.dart';
import 'package:flutter/foundation.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  void initialize() {
    // Escuchar cambios de conectividad
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    
    // Ejecutar una validación inicial al arrancar
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
    // Comprobar si hay alguna conexión válida para sincronizar
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
    if (_isSyncing) return; // Evitar múltiples sincronizaciones simultáneas
    _isSyncing = true;

    try {
      final dbHelper = DBHelper();
      final pendingVentas = await dbHelper.getPendingVentas();

      if (pendingVentas.isEmpty) {
        if (kDebugMode) {
          print('No hay ventas pendientes de sincronización.');
        }
        _isSyncing = false;
        return;
      }

      if (kDebugMode) {
        print('Sincronizando ${pendingVentas.length} ventas...');
      }

      // Simular subida de datos al servidor (API endpoint)
      await Future.delayed(const Duration(seconds: 2));

      // Extraer IDs de las ventas procesadas exitosamente
      List<int> syncedIds = pendingVentas.map((v) => v['id'] as int).toList();

      // Marcar como sincronizadas en la base de datos local
      await dbHelper.markVentasAsSynced(syncedIds);

      if (kDebugMode) {
        print('Sincronización completada con éxito.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error durante la sincronización: $e');
      }
    } finally {
      _isSyncing = false;
    }
  }
}
