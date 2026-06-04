import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketpos/providers/cart_provider.dart';
import 'package:pocketpos/screens/screens.dart';
import 'package:pocketpos/services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  // Inicializar servicio de sincronización
  SyncService().initialize();

  runApp(MyApp(initialRoute: isLoggedIn ? 'home' : 'login'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'PocketPOS',
        initialRoute: initialRoute,
        routes: {
          'login': (_) => const LoginScreen(),
          'home': (_) => const HomeScreen(),
          'products': (_) => const ProductsScreen(),
          'product-form': (_) => const ProductFormScreen(),
          'cart': (_) => const CartScreen(),
          'sales-report': (_) => const SalesReportScreen(),
        },
        theme: ThemeData.light().copyWith(
          appBarTheme: const AppBarTheme(backgroundColor: Colors.lightBlue),
        ),
      ),
    );
  }
}
