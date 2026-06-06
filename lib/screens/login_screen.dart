import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketpos/db/db_helper.dart';
import 'package:pocketpos/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _errorMsg = 'Por favor ingresa un correo válido');
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
      await GoogleSignIn.instance.initialize(
        serverClientId: '807442391311-i77vkm59cmhckjcdq4e4f5v9nca5o80l.apps.googleusercontent.com',
      );
      final GoogleSignInAccount account = await GoogleSignIn.instance.authenticate(
        scopeHint: ['email'],
      );
      final GoogleSignInAuthentication googleAuth = account.authentication;
        final idToken = googleAuth.idToken;

        if (idToken == null) {
          throw 'No ID Token found.';
        }

        // Sign in to Supabase
        await Supabase.instance.client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
        );

        // Guardar preferencias locales
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userEmail', account.email);
        await prefs.setString('userName', account.displayName ?? 'Usuario Google');
        await prefs.setString('userPhoto', account.photoUrl ?? '');
        await prefs.setString('userRole', 'user');
        
        await prefs.setString('authProvider', 'google');

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, 'home');
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMsg = 'Error de Google Sign In: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Brand Header
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8DCCF),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.point_of_sale, color: AppTheme.terracotta, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PocketPOS',
                    style: AppTheme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Accede a tu terminal',
                    style: AppTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.gray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Email Field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Correo Electrónico', style: AppTheme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: AppTheme.darkCharcoal)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'Ingresa tu correo',
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Contraseña', style: AppTheme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: AppTheme.darkCharcoal)),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              '¿Olvidaste tu contraseña?',
                              style: AppTheme.textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.gray,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          hintText: 'Ingresa tu contraseña',
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ],
                  ),
                  if (_errorMsg != null) ...[
                    const SizedBox(height: 12),
                    Text(_errorMsg!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                  const SizedBox(height: 24),

                  // Sign In Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Iniciar Sesión'),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppTheme.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'O CONTINUAR CON',
                          style: AppTheme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppTheme.border)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Social Logins
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _loginWithGoogle,
                      icon: Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
                        height: 20,
                      ),
                      label: const Text('Google'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: AppTheme.darkCharcoal,
                        side: const BorderSide(color: AppTheme.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Registration Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('¿No tienes una cuenta? ', style: AppTheme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, 'register'),
                        child: Text('Regístrate', style: AppTheme.textTheme.bodySmall?.copyWith(color: AppTheme.terracotta, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Footer Links
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('TÉRMINOS DE USO', style: AppTheme.textTheme.bodySmall?.copyWith(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      const SizedBox(width: 16),
                      Text('PRIVACIDAD', style: AppTheme.textTheme.bodySmall?.copyWith(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      const SizedBox(width: 16),
                      Text('SEGURIDAD', style: AppTheme.textTheme.bodySmall?.copyWith(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('© 2026 ASAP', style: AppTheme.textTheme.bodySmall?.copyWith(fontSize: 10, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
