import 'package:flutter/material.dart';
import 'package:pocketpos/screens/screens.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PocketPOS',
      initialRoute: 'home',
      routes: {
        'home': (_) => const HomeScreen(),
        'products': (_) => const ProductsScreen(),
        'product-form': (_) => const ProductFormScreen(),
      },
      theme: ThemeData.light().copyWith(
        appBarTheme: const AppBarTheme(backgroundColor: Colors.lightBlue),
      ),
    );
  }
}
