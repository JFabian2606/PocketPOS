import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pocketpos/db/db_helper.dart';
import 'package:pocketpos/models/models.dart';
import 'package:pocketpos/providers/cart_provider.dart';
import 'package:pocketpos/screens/sales_report_screen.dart';
import 'package:pocketpos/screens/products_screen.dart';
import 'package:pocketpos/screens/settings_screen.dart';
import 'package:pocketpos/services/export_service.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onJumpToCart;
  const HomeScreen({super.key, this.onJumpToCart});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'Usuario';
  String _userEmail = '';
  String _userPhoto = '';

  double _dailyIncome = 0;
  int _transactions = 0;
  double _avgOrder = 0;
  List<Map<String, dynamic>> _recentTransactions = [];
  List<Map<String, dynamic>> _stockAlerts = [];
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadDashboardData();
    CartProvider.salesNotifier.addListener(_loadDashboardData);
  }

  @override
  void dispose() {
    CartProvider.salesNotifier.removeListener(_loadDashboardData);
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    final db = DBHelper();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    
    final agrupadas = await db.getVentasAgrupadasPorFecha();
    double todayIncome = 0;
    int todayTrans = 0;
    for (var row in agrupadas) {
      if (row['fecha'] == today) {
        todayIncome = (row['total_ventas'] as num).toDouble();
        todayTrans = row['transacciones'] as int;
        break;
      }
    }
    
    final recent = await db.getVentasPorFecha(today);
    final products = await db.getProducts();
    
    final alerts = products.where((p) => p.stock <= 5).map((p) => {
      'name': p.name,
      'stock': p.stock,
      'progress': p.stock <= 0 ? 0.0 : p.stock / 10.0,
      'color': p.stock <= 0 ? Colors.red : Colors.orange,
    }).toList();
    
    alerts.sort((a, b) => (a['stock'] as int).compareTo(b['stock'] as int));

    if (mounted) {
      setState(() {
        _dailyIncome = todayIncome;
        _transactions = todayTrans;
        _avgOrder = todayTrans > 0 ? todayIncome / todayTrans : 0;
        _recentTransactions = recent.take(4).toList();
        _stockAlerts = alerts.take(3).toList();
        _isLoadingData = false;
      });
    }
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'Admin';
      _userEmail = prefs.getString('userEmail') ?? 'admin@pocketpos.com';
      _userPhoto = prefs.getString('userPhoto') ?? '';
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    final authProvider = prefs.getString('authProvider');

    if (authProvider == 'google') {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    
    await prefs.clear();

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushReplacementNamed('login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F1), // lumiere-cream
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F6F1).withValues(alpha: 0.9),
        elevation: 0,
        title: const Text('PocketPOS', style: TextStyle(color: Color(0xFF2D2926), fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: const Color(0xFFA66D3F).withValues(alpha: 0.2), // terracotta with opacity
              backgroundImage: _userPhoto.isNotEmpty ? NetworkImage(_userPhoto) : null,
              child: _userPhoto.isEmpty ? Text(
                _userName.isNotEmpty ? _userName.substring(0, 2).toUpperCase() : 'AD',
                style: const TextStyle(color: Color(0xFFA66D3F), fontWeight: FontWeight.bold, fontSize: 12),
              ) : null,
            ),
          )
        ],
        iconTheme: const IconThemeData(color: Color(0xFF2D2926)),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFFA66D3F)),
              accountName: Text(_userName),
              accountEmail: Text(_userEmail),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: _userPhoto.isNotEmpty ? NetworkImage(_userPhoto) : null,
                child: _userPhoto.isEmpty ? const Icon(Icons.person, size: 40, color: Color(0xFFA66D3F)) : null,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Color(0xFF717171)),
              title: const Text('Configuración Avanzada'),
              onTap: () {
                Navigator.pop(context); // Cierra el drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.download, color: Color(0xFF717171)),
              title: const Text('Exportar Datos'),
              onTap: () {
                Navigator.pop(context);
                ExportService.exportSalesToCSV(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline, color: Color(0xFF717171)),
              title: const Text('Soporte y Ayuda'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Ayuda Rápida'),
                    content: const Text(
                      '• Para vender: Ve a "Nueva Venta" o a la pestaña del Carrito.\n'
                      '• Para crear productos: Ve a "Catálogo" y presiona el botón +.\n'
                      '• Para editar o borrar: Mantén presionado un producto en el Catálogo.\n'
                      '• Para cambiar datos del ticket: Usa "Configuración Avanzada".'
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido')),
                    ],
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Text('Bienvenido de nuevo, $_userName', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D2926))),
              const SizedBox(height: 4),
              const Text("Esto es lo que sucede hoy en tu negocio.", style: TextStyle(fontSize: 14, color: Color(0xFF717171))),
              const SizedBox(height: 24),

              // Quick Action
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (widget.onJumpToCart != null) {
                      widget.onJumpToCart!();
                    }
                  },
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Nueva Venta'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA66D3F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Metrics Grid
              _isLoadingData ? const Center(child: CircularProgressIndicator()) : GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.3,
                children: [
                  _buildMetricCard(
                    title: 'Ingresos Hoy',
                    value: NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(_dailyIncome),
                    icon: Icons.attach_money,
                    iconBgColor: Colors.orange.shade50,
                    iconColor: Colors.orange.shade400,
                    badgeText: 'Hoy',
                    badgeColor: Colors.blue,
                  ),
                  _buildMetricCard(
                    title: 'Ventas',
                    value: _transactions.toString(),
                    icon: Icons.receipt_long,
                    iconBgColor: Colors.grey.shade100,
                    iconColor: const Color(0xFF717171),
                    badgeText: 'Hoy',
                    badgeColor: Colors.green,
                  ),
                  _buildMetricCard(
                    title: 'Ticket Promedio',
                    value: NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(_avgOrder),
                    icon: Icons.shopping_bag_outlined,
                    iconBgColor: Colors.blue.shade50,
                    iconColor: Colors.blue.shade400,
                    badgeText: 'Hoy',
                    badgeColor: Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Recent Transactions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ventas Recientes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D2926))),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SalesReportScreen()),
                      );
                    },
                    child: const Text('Ver Todo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFA66D3F))),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E1DA)),
                ),
                child: _isLoadingData 
                    ? const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
                    : _recentTransactions.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: Text('No hay ventas hoy', style: TextStyle(color: Color(0xFF717171)))),
                          )
                        : Column(
                            children: _recentTransactions.asMap().entries.map((entry) {
                              final int idx = entry.key;
                              final item = entry.value;
                              final timeStr = item['created_at'].toString().split('T').last.substring(0, 5);
                              
                              return Column(
                                children: [
                                  _buildTransactionItem(
                                    item['product_name'] ?? 'Producto',
                                    NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(item['total']),
                                    'Transacción #${item['id']} • $timeStr',
                                    item['payment_method'] ?? 'Efectivo',
                                    Colors.green,
                                  ),
                                  if (idx < _recentTransactions.length - 1)
                                    const Divider(height: 1, color: Color(0xFFE5E1DA)),
                                ],
                              );
                            }).toList(),
                          ),
              ),
              const SizedBox(height: 32),

              // Stock Alerts
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E1DA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Alertas de Stock', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D2926))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isLoadingData)
                      const Center(child: CircularProgressIndicator())
                    else if (_stockAlerts.isEmpty)
                      const Text('Todo el inventario está en buen estado.', style: TextStyle(color: Color(0xFF717171)))
                    else
                      ..._stockAlerts.map((alert) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildStockAlert(
                            alert['name'],
                            '${alert['stock']} uds. restantes',
                            alert['progress'],
                            alert['color'],
                          ),
                        );
                      }),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                           Navigator.push(
                             context,
                             MaterialPageRoute(builder: (_) => const ProductsScreen()),
                           );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE5E1DA)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          foregroundColor: const Color(0xFF717171),
                        ),
                        child: const Text('Gestionar Inventario', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String badgeText,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E1DA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(badgeText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor)),
              ),
            ],
          ),
          const Spacer(),
          Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF717171), letterSpacing: 1.2)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D2926))),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(String title, String price, String subtitle, String status, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: const Icon(Icons.receipt, color: Color(0xFF717171), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF2D2926))),
                    Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D2926))),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF717171))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockAlert(String title, String subtitle, double progress, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF2D2926))),
            Text(subtitle.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: color.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
