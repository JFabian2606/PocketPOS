import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pocketpos/db/db_helper.dart';
import 'package:pocketpos/models/models.dart';
import 'package:pocketpos/providers/cart_provider.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito de Compras'),
        elevation: 0,
        actions: [
          if (!cart.isEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Vaciar carrito',
              onPressed: () => _confirmClear(context, cart),
            ),
        ],
      ),
      body: cart.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('El carrito está vacío',
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                  child: Icon(Icons.shopping_bag_outlined)),
                              const SizedBox(width: 10),
                              // Nombre y precio unitario
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.product.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text(
                                        'Unitario: ${copFormat.format(item.product.price)}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54)),
                                    Text(
                                        'Subtotal: ${copFormat.format(item.subtotal)}',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              // Controles cantidad
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline,
                                        color: Colors.orange),
                                    onPressed: () => context
                                        .read<CartProvider>()
                                        .decrementProduct(item.product),
                                  ),
                                  Text('${item.quantity}',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline,
                                        color: Colors.green),
                                    onPressed: () => context
                                        .read<CartProvider>()
                                        .addProduct(item.product),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    tooltip: 'Eliminar ítem',
                                    onPressed: () => context
                                        .read<CartProvider>()
                                        .removeProduct(item.product),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // ── Panel de total ───────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total:',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          Text(
                            copFormat.format(cart.total),
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.lightBlue),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // SCRUM-38: Selector de método de pago
                      DropdownButtonFormField<PaymentMethod>(
                        value: _paymentMethod,
                        decoration: const InputDecoration(
                          labelText: 'Método de Pago',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: PaymentMethod.values.map((method) {
                          return DropdownMenuItem(
                            value: method,
                            child: Text(method.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _paymentMethod = val;
                              _cashCtrl.clear();
                            });
                          }
                        },
                      ),
                      
                      // SCRUM-40: Mostrar campo "monto recibido" si es Efectivo
                      if (_paymentMethod == PaymentMethod.efectivo) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _cashCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Monto Recibido',
                            border: OutlineInputBorder(),
                            isDense: true,
                            prefixText: '\$ ',
                          ),
                          onChanged: (val) => setState(() {}),
                        ),
                        if (_cashCtrl.text.isNotEmpty && double.tryParse(_cashCtrl.text) != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Cambio:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      const SizedBox(height: 16),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => _processPayment(context, cart),
                          child: const Text('Confirmar venta',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _processPayment(BuildContext context, CartProvider cart) async {
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
      await db.processSale(cart.items, _paymentMethod);
      
      // SCRUM-36: Mostrar pantalla/dialog de confirmación de venta exitosa
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Venta Exitosa'),
            ],
          ),
          content: Text('Se ha registrado la venta por un total de ${NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(cart.total)}.'),
          actions: [
            TextButton(
              onPressed: () {
                cart.clear();
                Navigator.pop(context); // Cierra dialog
                Navigator.pop(context); // Vuelve a la pantalla principal
              },
              child: const Text('Aceptar'),
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
      builder: (_) => AlertDialog(
        title: const Text('Vaciar carrito'),
        content:
            const Text('¿Estás seguro de que deseas eliminar todos los ítems?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              cart.clear();
              Navigator.pop(context);
            },
            child: const Text('Vaciar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
