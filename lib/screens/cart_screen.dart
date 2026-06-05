import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pocketpos/db/db_helper.dart';
import 'package:pocketpos/models/models.dart';
import 'package:pocketpos/providers/cart_provider.dart';
import 'package:pocketpos/services/ticket_pdf_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  PaymentMethod _paymentMethod = PaymentMethod.efectivo;
  final TextEditingController _cashCtrl = TextEditingController();

  @override
  void dispose() {
    _cashCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final copFormat = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    // Cálculos de subtotal/tax para mostrar en UI
    final total = cart.total;
    final subtotal = total / 1.08; // asumiendo 8% de IVA implícito para UI
    final tax = total - subtotal;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F1), // lumiere-cream
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F6F1).withValues(alpha: 0.95),
        elevation: 0,
        title: const Text('PocketPOS', style: TextStyle(color: Color(0xFF2D2926), fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: Color(0xFF2D2926)),
        actions: [
          if (!cart.isEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Color(0xFF717171)),
              tooltip: 'Vaciar carrito',
              onPressed: () => _confirmClear(context, cart),
            ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: FutureBuilder<SharedPreferences>(
              future: SharedPreferences.getInstance(),
              builder: (context, snapshot) {
                final photo = snapshot.data?.getString('userPhoto') ?? '';
                final name = snapshot.data?.getString('userName') ?? 'AD';
                return CircleAvatar(
                  backgroundColor: const Color(0xFFA66D3F).withValues(alpha: 0.2),
                  radius: 16,
                  backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                  child: photo.isEmpty ? Text(name.substring(0, 2).toUpperCase(), style: const TextStyle(color: Color(0xFFA66D3F), fontWeight: FontWeight.bold, fontSize: 12)) : null,
                );
              }
            ),
          )
        ],
      ),
      body: cart.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Color(0xFFE5E1DA)),
                  SizedBox(height: 16),
                  Text('El carrito está vacío', style: TextStyle(fontSize: 16, color: Color(0xFF717171), fontWeight: FontWeight.w500)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Orden Actual', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D2926))),
                      Text('${cart.items.length} ARTÍCULOS', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF717171))),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Cart Items
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(color: const Color(0xFFF9F6F1), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.local_cafe_outlined, color: Color(0xFFA66D3F)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.product.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D2926))),
                                  const SizedBox(height: 2),
                                  Text('Categoría: ${item.product.category}', style: const TextStyle(fontSize: 10, color: Color(0xFF717171))),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(copFormat.format(item.subtotal), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D2926))),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFFF9F6F1), borderRadius: BorderRadius.circular(8)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () => context.read<CartProvider>().decrementProduct(item.product),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 6.0),
                                          child: Text('-', style: TextStyle(color: Color(0xFF717171), fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      Text('${item.quantity}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2D2926))),
                                      InkWell(
                                        onTap: () {
                                          final success = context.read<CartProvider>().addProduct(item.product);
                                          if (!success) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('No hay suficiente stock de ${item.product.name}'), backgroundColor: Colors.orange, duration: const Duration(seconds: 2)),
                                            );
                                          }
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 6.0),
                                          child: Text('+', style: TextStyle(color: Color(0xFF717171), fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Quick Actions (Placeholder visuals)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.print_outlined, size: 16),
                          label: const Text('Imprimir Ticket', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2D2926),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFE5E1DA)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.email_outlined, size: 16),
                          label: const Text('Enviar Recibo', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2D2926),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFE5E1DA)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Payment Method
                  const Text('MÉTODO DE PAGO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF717171), letterSpacing: 1.0)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildPaymentMethodCard(PaymentMethod.tarjeta, Icons.credit_card, 'Tarjeta'),
                      const SizedBox(width: 12),
                      _buildPaymentMethodCard(PaymentMethod.efectivo, Icons.money, 'Efectivo'),
                      const SizedBox(width: 12),
                      _buildPaymentMethodCard(PaymentMethod.transferencia, Icons.account_balance, 'Transf.'),
                    ],
                  ),
                  if (_paymentMethod == PaymentMethod.efectivo) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _cashCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Monto Recibido',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (val) => setState(() {}),
                    ),
                    if (_cashCtrl.text.isNotEmpty && double.tryParse(_cashCtrl.text) != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Cambio:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D2926))),
                          Text(
                            copFormat.format((double.tryParse(_cashCtrl.text) ?? 0) - cart.total),
                            style: TextStyle(
                              color: ((double.tryParse(_cashCtrl.text) ?? 0) - cart.total) < 0 ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                  const SizedBox(height: 24),

                  // Order Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F6F1), // brand-cream
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFA66D3F).withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('RESUMEN DE ORDEN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF717171), letterSpacing: 1.0)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal', style: TextStyle(fontSize: 14, color: Color(0xFF717171))),
                            Text(copFormat.format(cart.subtotal), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D2926))),
                          ],
                        ),
                        if (cart.discount > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Descuento', style: TextStyle(fontSize: 14, color: Colors.green)),
                              Text('- ${copFormat.format(cart.discount)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                        ],
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Divider(color: Color(0xFFE5E1DA), height: 1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D2926))),
                            Text(copFormat.format(cart.total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF2D2926))),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () => _processPayment(context, cart),
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Confirmar Venta'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFA66D3F),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                              shadowColor: const Color(0xFFA66D3F).withValues(alpha: 0.3),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => _showDiscountDialog(context, cart),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF717171),
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFE5E1DA)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Añadir Descuento', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Assign to Customer
                  TextButton(
                    onPressed: () {},
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.person_add_alt_1_outlined, size: 16, color: Color(0xFF717171)),
                            SizedBox(width: 8),
                            Text('Asignar a Cliente', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF717171))),
                          ],
                        ),
                        const Icon(Icons.chevron_right, size: 20, color: Color(0xFF717171)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method, IconData icon, String label) {
    final isSelected = _paymentMethod == method;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _paymentMethod = method;
            _cashCtrl.clear();
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF9F6F1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFFA66D3F) : const Color(0xFFE5E1DA),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 2, offset: const Offset(0, 1))],
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? const Color(0xFFA66D3F) : const Color(0xFF717171), size: 24),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF2D2926) : const Color(0xFF717171))),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processPayment(BuildContext context, CartProvider cart) async {
    final copFormat = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    if (_paymentMethod == PaymentMethod.efectivo) {
      final cash = double.tryParse(_cashCtrl.text) ?? 0;
      if (cash < cart.total) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El monto recibido es menor al total'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    try {
      final db = DBHelper();
      await db.processSale(cart.items, _paymentMethod, discount: cart.discount);
      
      // Guardar una copia inmutable de los detalles para el ticket (SCRUM-54)
      final List<CartItem> saleItems = List.unmodifiable(cart.items);
      final double saleSubtotal = cart.subtotal;
      final double saleDiscount = cart.discount;
      final double saleTotal = cart.total;
      final PaymentMethod saleMethod = _paymentMethod;
      final double cashReceived = double.tryParse(_cashCtrl.text) ?? 0;

      // SCRUM-36: Mostrar pantalla/dialog de confirmación de venta exitosa
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green, size: 60),
              SizedBox(height: 12),
              Text('¡Venta Exitosa!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Se ha registrado la venta por un total de ${copFormat.format(saleTotal)}.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              const Text(
                'Opciones del Recibo:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFFFEBEE),
                        child: Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
                      ),
                      title: const Text('Previsualizar PDF', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Ver e imprimir ticket', style: TextStyle(fontSize: 12)),
                      dense: true,
                      onTap: () {
                        TicketPdfService.showTicket(saleItems, saleMethod, saleTotal, cashReceived, discount: saleDiscount);
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE3F2FD),
                        child: Icon(Icons.share, color: Colors.blue, size: 20),
                      ),
                      title: const Text('Compartir PDF', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Enviar archivo digital', style: TextStyle(fontSize: 12)),
                      dense: true,
                      onTap: () {
                        TicketPdfService.shareTicketPdf(saleItems, saleMethod, saleTotal, cashReceived, dialogCtx, discount: saleDiscount);
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE8F5E9),
                        child: Icon(Icons.chat_bubble_outline, color: Colors.green, size: 20),
                      ),
                      title: const Text('Compartir Texto', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Enviar por WhatsApp / SMS', style: TextStyle(fontSize: 12)),
                      dense: true,
                      onTap: () {
                        TicketPdfService.shareTicketText(saleItems, saleMethod, saleTotal, cashReceived, discount: saleDiscount);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  cart.clear();
                  context.read<CartProvider>().recordSale();
                  Navigator.pop(dialogCtx); // Cierra dialog
                },
                child: const Text('Finalizar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      // SCRUM-35: Mostrar alerta si un producto no tiene stock suficiente
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _confirmClear(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Vaciar carrito'),
        content:
            const Text('¿Estás seguro de que deseas eliminar todos los ítems?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              cart.clear();
              Navigator.pop(dialogCtx);
            },
            child: const Text('Vaciar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDiscountDialog(BuildContext context, CartProvider cart) {
    final TextEditingController descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Añadir Descuento Fijo (\$)'),
        content: TextField(
          controller: descCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: 'Ej. 5000',
            prefixText: '\$ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final val = double.tryParse(descCtrl.text) ?? 0;
              cart.setDiscount(val);
              Navigator.pop(dialogCtx);
            },
            child: const Text('Aplicar', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }
}
