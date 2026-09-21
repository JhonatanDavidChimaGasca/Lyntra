import 'package:flutter/material.dart';

import '../../widgets/app_side_menu.dart';
import '../promo_codes_screen.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _twoFactor = false;

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _changePassword() {
    if (!_formKey.currentState!.validate()) return;
    if (_newPasswordCtrl.text != _confirmPasswordCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Las contraseñas no coinciden")),
      );
      return;
    }
    _currentPasswordCtrl.clear();
    _newPasswordCtrl.clear();
    _confirmPasswordCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Contraseña actualizada")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: AppSideMenu(
        currentLocation: MenuLocation.security,
        onPromocionesTap: () {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PromoCodesScreen()));
        },
      ),
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
        leading: IconButton(
          icon: Icon(Icons.menu, color: theme.colorScheme.onSurface),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text("Seguridad", style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text("Cambiar contraseña", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _currentPasswordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Contraseña actual", border: OutlineInputBorder()),
              validator: (v) => (v == null || v.isEmpty) ? "Requerido" : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _newPasswordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Nueva contraseña", border: OutlineInputBorder()),
              validator: (v) => (v == null || v.length < 6) ? "Mínimo 6 caracteres" : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmPasswordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Confirmar nueva contraseña", border: OutlineInputBorder()),
              validator: (v) => (v == null || v.isEmpty) ? "Requerido" : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _changePassword,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text("Actualizar contraseña"),
              ),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              value: _twoFactor,
              onChanged: (v) => setState(() => _twoFactor = v),
              activeColor: Colors.orange,
              title: const Text("Verificación en dos pasos"),
              subtitle: const Text("Añade una capa extra de seguridad a tu cuenta"),
            ),
          ],
        ),
      ),
    );
  }
}
