import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:pocketpos/db/db_helper.dart';

class ExportService {
  static Future<void> exportSalesToCSV(BuildContext context) async {
    try {
      final db = DBHelper();
      final ventas = await db.getVentas();
      final productos = await db.getProducts();
      
      // Crear un mapa para buscar el nombre del producto rápidamente
      final Map<int, String> productNames = {
        for (var p in productos) p.id!: p.name
      };

      // Encabezados del CSV
      final List<String> csvRows = [
        'ID Venta,Fecha,Producto,Cantidad,Total,Método de Pago'
      ];

      // Formateador de moneda (opcional, o podemos dejarlo crudo)
      for (var venta in ventas) {
        final id = venta['id'].toString();
        final date = venta['created_at'].toString();
        final productId = venta['product_id'] as int;
        final productName = productNames[productId] ?? 'Producto Eliminado';
        final qty = venta['quantity'].toString();
        final total = venta['total'].toString();
        final payment = venta['payment_method'].toString();

        // Escapar comas en el nombre del producto si existen
        final safeProductName = productName.contains(',') ? '"$productName"' : productName;

        csvRows.add('$id,$date,$safeProductName,$qty,$total,$payment');
      }

      final String csvString = csvRows.join('\n');

      // Guardar el archivo localmente
      final tempDir = await getTemporaryDirectory();
      final now = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final File file = File('${tempDir.path}/Reporte_Ventas_$now.csv');
      
      await file.writeAsString(csvString);

      if (!context.mounted) return;
      
      // Compartir el archivo
      await Share.shareXFiles(
        [XFile(file.path)], 
        text: 'Reporte de ventas en CSV',
      );

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
