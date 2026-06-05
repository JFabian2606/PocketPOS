import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _nitCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameCtrl.text = prefs.getString('businessName') ?? 'Mi Negocio';
      _addressCtrl.text = prefs.getString('businessAddress') ?? '';
      _phoneCtrl.text = prefs.getString('businessPhone') ?? '';
      _nitCtrl.text = prefs.getString('businessNit') ?? '';
      _messageCtrl.text = prefs.getString('businessMessage') ?? '¡Gracias por su compra!';
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('businessName', _nameCtrl.text);
    await prefs.setString('businessAddress', _addressCtrl.text);
    await prefs.setString('businessPhone', _phoneCtrl.text);
    await prefs.setString('businessNit', _nitCtrl.text);
    await prefs.setString('businessMessage', _messageCtrl.text);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Perfil de negocio guardado exitosamente'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _nitCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9F6F1),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F1), // lumiere-cream
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F6F1).withValues(alpha: 0.95),
        elevation: 0,
        title: const Text('Ajustes', style: TextStyle(color: Color(0xFF2D2926), fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: Color(0xFF2D2926)),
        actions: [
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Perfil del Negocio', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D2926))),
            const SizedBox(height: 4),
            const Text('Esta información aparecerá en los tickets y reportes.', style: TextStyle(fontSize: 14, color: Color(0xFF717171))),
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E1DA)),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Nombre del Negocio *'),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(hintText: 'Ej. Mi Tienda'),
                      validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildLabel('NIT / RUT / Documento'),
                    TextFormField(
                      controller: _nitCtrl,
                      decoration: const InputDecoration(hintText: 'Ej. 900.123.456-7'),
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Dirección'),
                    TextFormField(
                      controller: _addressCtrl,
                      decoration: const InputDecoration(hintText: 'Ej. Calle Falsa 123'),
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Teléfono'),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(hintText: 'Ej. 300 123 4567'),
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Mensaje de Agradecimiento (Pie del Ticket)'),
                    TextFormField(
                      controller: _messageCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(hintText: 'Ej. ¡Gracias por su compra! Vuelva pronto.'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _saveProfile,
                icon: const Icon(Icons.save),
                label: const Text('Guardar Cambios'),
              ),
            ),
            const SizedBox(height: 40),
            
            // Other settings could go here (e.g. Logout button could be moved from drawer to here eventually)
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2D2926), fontSize: 14)),
    );
  }
}
