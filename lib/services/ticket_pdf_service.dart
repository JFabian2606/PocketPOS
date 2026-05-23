import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pocketpos/models/models.dart';

class TicketPdfService {
  /// Genera la plantilla del PDF del ticket (SCRUM-53)
  static Future<Uint8List> generateTicket(
      List<CartItem> items, PaymentMethod paymentMethod, double total, double receivedCash) async {
    final pdf = pw.Document();

    final copFormat = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    // Roll80 es el formato estándar para impresoras térmicas (80mm)
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(15),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Cabecera
              pw.Center(
                child: pw.Text('POCKET POS', 
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 5),
              pw.Center(child: pw.Text('Ticket de Venta')),
              pw.SizedBox(height: 10),
              pw.Text('Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 5),

              // Detalles de productos
              ...items.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text('${item.quantity}x ${item.product.name}'),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(copFormat.format(item.subtotal), textAlign: pw.TextAlign.right),
                      ),
                    ],
                  ),
                );
              }),

              pw.SizedBox(height: 5),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 5),

              // Totales
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.Text(copFormat.format(total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                ],
              ),
              pw.SizedBox(height: 10),

              // Información de pago
              pw.Text('Método de Pago: ${paymentMethod.name.toUpperCase()}'),
              if (paymentMethod == PaymentMethod.efectivo) ...[
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Recibido:'),
                    pw.Text(copFormat.format(receivedCash)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Cambio:'),
                    pw.Text(copFormat.format(receivedCash - total)),
                  ],
                ),
              ],
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 5),
              pw.Center(child: pw.Text('¡Gracias por su compra!', style: const pw.TextStyle(fontSize: 10))),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Despliega la previsualización del PDF para impresión o exportación (SCRUM-54)
  static Future<void> showTicket(
      List<CartItem> items, PaymentMethod paymentMethod, double total, double receivedCash) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async =>
          await generateTicket(items, paymentMethod, total, receivedCash),
      name: 'Ticket_Venta_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  /// Verifica y solicita el permiso de almacenamiento en Android (SCRUM-65)
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (!status.isGranted) {
        final result = await Permission.storage.request();
        return result.isGranted;
      }
    }
    return true;
  }

  /// Guarda el PDF temporalmente en el dispositivo (SCRUM-62)
  static Future<File> saveTicketToTempFile(
      List<CartItem> items, PaymentMethod paymentMethod, double total, double receivedCash) async {
    final pdfBytes = await generateTicket(items, paymentMethod, total, receivedCash);
    final tempDir = await getTemporaryDirectory();
    final fileName = 'Ticket_Venta_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${tempDir.path}/$fileName');
    return await file.writeAsBytes(pdfBytes);
  }

  /// Comparte el PDF utilizando share_plus (SCRUM-63)
  static Future<void> shareTicketPdf(
      List<CartItem> items, PaymentMethod paymentMethod, double total, double receivedCash, BuildContext context) async {
    final hasPermission = await requestStoragePermission();
    if (!context.mounted) return;
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permiso de almacenamiento denegado para compartir el PDF'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final file = await saveTicketToTempFile(items, paymentMethod, total, receivedCash);
      await Share.shareXFiles([XFile(file.path)], text: 'Ticket de Venta PocketPOS');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al compartir el PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Comparte el recibo en formato de texto plano (SCRUM-64)
  static Future<void> shareTicketText(
      List<CartItem> items, PaymentMethod paymentMethod, double total, double receivedCash) async {
    final copFormat = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    final buffer = StringBuffer();
    buffer.writeln('=============================');
    buffer.writeln('         POCKET POS          ');
    buffer.writeln('      Ticket de Venta        ');
    buffer.writeln('=============================');
    buffer.writeln('Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}');
    buffer.writeln('-----------------------------');
    buffer.writeln('Detalle de compra:');
    
    for (final item in items) {
      buffer.writeln('${item.quantity}x ${item.product.name.padRight(16)} ${copFormat.format(item.subtotal)}');
    }
    
    buffer.writeln('-----------------------------');
    buffer.writeln('TOTAL:             ${copFormat.format(total)}');
    buffer.writeln('Método de Pago:    ${paymentMethod.name.toUpperCase()}');
    
    if (paymentMethod == PaymentMethod.efectivo) {
      buffer.writeln('Recibido:          ${copFormat.format(receivedCash)}');
      buffer.writeln('Cambio:            ${copFormat.format(receivedCash - total)}');
    }
    buffer.writeln('=============================');
    buffer.writeln('¡Gracias por su compra!');

    await Share.share(buffer.toString(), subject: 'Ticket de Venta PocketPOS');
  }
}
