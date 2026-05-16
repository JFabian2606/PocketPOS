import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketpos/db/db_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _initGoogleSignIn();
  }

  Future<void> _initGoogleSignIn() async {
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: '807442391311-i77vkm59cmhckjcdq4e4f5v9nca5o80l.apps.googleusercontent.com',
      );
    } catch (_) {
      // Si ya está inicializado puede tirar error, lo ignoramos
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (email.isEmpty || pass.isEmpty) {
      setState(() => _errorMsg = 'Por favor ingresa correo y contraseña');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      // Hash password with SHA-256 (SCRUM-43)
      final bytes = utf8.encode(pass);
      final hash = sha256.convert(bytes).toString();

      final db = DBHelper();
      final user = await db.authenticateUser(email, hash);

      if (user != null) {
        // Guardar sesión (SCRUM-44)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userEmail', user['email']);
        await prefs.setString('userRole', user['role']);

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, 'home');
      } else {
        setState(() {
          _isLoading = false;
          _errorMsg = 'Credenciales incorrectas';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMsg = 'Error interno: $e';
      });
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      // SCRUM-48: Implementar flujo GoogleSignIn (Nueva API v7+)
      final GoogleSignInAccount? account = await GoogleSignIn.instance.authenticate(
        scopeHint: ['email'],
      );
      if (account != null) {
        // SCRUM-49: Extraer info de Google y SCRUM-50: Persistir sesión
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userEmail', account.email);
        await prefs.setString('userName', account.displayName ?? 'Usuario Google');
        await prefs.setString('userPhoto', account.photoUrl ?? '');
        await prefs.setString('userRole', 'user');
        
        // Guardar método de autenticación para luego saber cómo cerrar sesión
        await prefs.setString('authProvider', 'google');

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, 'home');
      } else {
        setState(() => _isLoading = false);
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMsg = 'Error de Google Sign In: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Fondo estético
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF0D47A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.point_of_sale, size: 80, color: Colors.blueAccent),
                      const SizedBox(height: 20),
                      const Text(
                        'PocketPOS',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Bienvenido de nuevo',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                      const SizedBox(height: 30),
                      
                      // Campos de texto (SCRUM-42)
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email_outlined),
                          labelText: 'Correo electrónico',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _passCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline),
                          labelText: 'Contraseña',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      if (_errorMsg != null) ...[
                        const SizedBox(height: 15),
                        Text(_errorMsg!,
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                      const SizedBox(height: 30),
                      
                      // Botón de ingresar
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Ingresar',
                                  style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      Row(
                        children: const [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text('O', style: TextStyle(color: Colors.black54)),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Botón de Google
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          icon: Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
                            height: 24,
                          ),
                          label: const Text(
                            'Continuar con Google',
                            style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.black26),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isLoading ? null : _loginWithGoogle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
