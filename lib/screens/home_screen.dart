import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'Usuario';
  String _userEmail = '';
  String _userPhoto = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
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
      await GoogleSignIn().signOut();
    }
    
    await prefs.clear();

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, 'login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PocketPOS'),
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.blueAccent),
              accountName: Text(_userName),
              accountEmail: Text(_userEmail),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: _userPhoto.isNotEmpty ? NetworkImage(_userPhoto) : null,
                child: _userPhoto.isEmpty ? const Icon(Icons.person, size: 40, color: Colors.blue) : null,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.point_of_sale, size: 80, color: Colors.lightBlue),
            const SizedBox(height: 20),
            const Text('Sistema de Punto de Venta',
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, 'products'),
              child: const Text('Ver Productos'),
            ),
          ],
        ),
      ),
    );
  }
}
