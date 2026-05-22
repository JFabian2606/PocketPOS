import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pocketpos/db/db_helper.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  final _db = DBHelper();
  List<Map<String, dynamic>> _ventasAgrupadas = [];
  bool _isLoading = true;

  double _totalIngresos = 0.0;
  int _totalTransacciones = 0;
  int _totalItems = 0;

  @override
  void initState() {
    super.initState();
    _loadSalesReport();
  }

  Future<void> _loadSalesReport() async {
    setState(() => _isLoading = true);
    final data = await _db.getVentasAgrupadasPorFecha();

    double totalIngresos = 0.0;
    int totalTransacciones = 0;
    int totalItems = 0;

    for (final day in data) {
      totalIngresos += (day['total_ventas'] as num).toDouble();
      totalTransacciones += (day['transacciones'] as num).toInt();
      totalItems += (day['cantidad_items'] as num).toInt();
    }

    setState(() {
      _ventasAgrupadas = data;
      _totalIngresos = totalIngresos;
      _totalTransacciones = totalTransacciones;
      _totalItems = totalItems;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final copFormat = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas por Fecha'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _loadSalesReport,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Dashboard Resumen General ─────────────────────
                _buildDashboardHeader(copFormat),

                const Divider(height: 1),

                // ── Lista de Ventas por Fecha ─────────────────────
                Expanded(
                  child: _ventasAgrupadas.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bar_chart_outlined,
                                  size: 80, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No se han registrado ventas',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadSalesReport,
                          child: ListView.builder(
                            itemCount: _ventasAgrupadas.length,
                            padding: const EdgeInsets.only(top: 8, bottom: 20),
                            itemBuilder: (context, index) {
                              final dayData = _ventasAgrupadas[index];
                              return VentaFechaTile(
                                data: dayData,
                                currencyFormat: copFormat,
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildDashboardHeader(NumberFormat copFormat) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen General',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSummaryCard(
                'Ingresos',
                copFormat.format(_totalIngresos),
                Icons.attach_money,
                Colors.green,
                Colors.green.shade800,
              ),
              const SizedBox(width: 8),
              _buildSummaryCard(
                'Transacciones',
                '$_totalTransacciones',
                Icons.receipt_long,
                Colors.blue,
                Colors.blue.shade800,
              ),
              const SizedBox(width: 8),
              _buildSummaryCard(
                'Artículos',
                '$_totalItems',
                Icons.shopping_bag,
                Colors.orange,
                Colors.orange.shade800,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color textColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class VentaFechaTile extends StatefulWidget {
  final Map<String, dynamic> data;
  final NumberFormat currencyFormat;

  const VentaFechaTile({
    super.key,
    required this.data,
    required this.currencyFormat,
  });

  @override
  State<VentaFechaTile> createState() => _VentaFechaTileState();
}

class _VentaFechaTileState extends State<VentaFechaTile> {
  bool _isExpanded = false;
  List<Map<String, dynamic>>? _detalles;
  bool _isLoading = false;

  Future<void> _loadDetails() async {
    if (_detalles != null) return;
    setState(() => _isLoading = true);
    final fecha = widget.data['fecha'] as String;
    final res = await DBHelper().getVentasPorFecha(fecha);
    setState(() {
      _detalles = res;
      _isLoading = false;
    });
  }

  String _formatDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final year = parts[0];
        final monthIndex = int.parse(parts[1]);
        final day = int.parse(parts[2]);

        const meses = [
          'enero',
          'febrero',
          'marzo',
          'abril',
          'mayo',
          'junio',
          'julio',
          'agosto',
          'septiembre',
          'octubre',
          'noviembre',
          'diciembre'
        ];

        if (monthIndex >= 1 && monthIndex <= 12) {
          return '$day de ${meses[monthIndex - 1]} de $year';
        }
      }
    } catch (_) {}
    return dateStr;
  }

  String _formatTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '';
    try {
      final dt = DateTime.parse(dateTimeStr).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      try {
        final parts = dateTimeStr.split('T');
        if (parts.length == 2) {
          return parts[1].substring(0, 5);
        }
      } catch (_) {}
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final fecha = widget.data['fecha'] as String;
    final total = (widget.data['total_ventas'] as num).toDouble();
    final transacciones = (widget.data['transacciones'] as num).toInt();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: CircleAvatar(
          backgroundColor: Colors.lightBlue.shade50,
          child: const Icon(Icons.calendar_today, color: Colors.lightBlue, size: 20),
        ),
        title: Text(
          _formatDate(fecha),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          'Total: ${widget.currencyFormat.format(total)} | $transacciones trans.',
          style: const TextStyle(color: Colors.black54, fontSize: 13),
        ),
        onExpansionChanged: (expanded) {
          setState(() => _isExpanded = expanded);
          if (expanded) {
            _loadDetails();
          }
        },
        children: [
          const Divider(height: 1),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_detalles == null || _detalles!.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No se encontraron detalles para este día.',
                style: TextStyle(color: Colors.black54),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _detalles!.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final det = _detalles![idx];
                final prodName = det['product_name'] as String;
                final qty = det['quantity'] as int;
                final itemTotal = (det['total'] as num).toDouble();
                final paymentMethod = det['payment_method'] as String;
                final time = _formatTime(det['created_at'] as String?);

                Color methodColor = Colors.green;
                if (paymentMethod.toLowerCase() == 'tarjeta') {
                  methodColor = Colors.blue;
                } else if (paymentMethod.toLowerCase() == 'transferencia') {
                  methodColor = Colors.purple;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                  child: Row(
                    children: [
                      // Hora
                      Text(
                        time,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Producto y Cantidad
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prodName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Cant: $qty x ${widget.currencyFormat.format(itemTotal / qty)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Método de Pago y Total
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            widget.currencyFormat.format(itemTotal),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: methodColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: methodColor.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              paymentMethod,
                              style: TextStyle(
                                color: methodColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
