import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketpos/providers/cart_provider.dart';
import 'package:pocketpos/screens/screens.dart';
import 'package:pocketpos/services/sync_service.dart';
import 'package:pocketpos/theme/app_theme.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://perhcltxwvfvkyouurqe.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBlcmhjbHR4d3Zmdmt5b3V1cnFlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA2MjkyMjQsImV4cCI6MjA5NjIwNTIyNH0.BaEeJABUz6AmmBgIWiEEU8JBrkYSS8DFBAd_RLPVjD4',
  );

  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  // Inicializar servicio de sincronización
  SyncService().initialize();

  final String initialRoute = onboardingComplete 
      ? (isLoggedIn ? 'home' : 'login')
      : 'onboarding';

  runApp(MyApp(initialRoute: initialRoute));
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
          'onboarding': (_) => const OnboardingScreen(),
          'login': (_) => const LoginScreen(),
          'home': (_) => const MainNavigation(), // Utilizar MainNavigation en lugar de HomeScreen directo
          'products': (_) => const ProductsScreen(),
          'product-form': (_) => const ProductFormScreen(),
          'cart': (_) => const CartScreen(),
          'sales-report': (_) => const SalesReportScreen(),
        },
        theme: AppTheme.lightTheme,
      ),
    );
  }
}
