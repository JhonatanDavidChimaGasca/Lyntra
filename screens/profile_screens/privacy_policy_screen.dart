import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
        title: Text("Privacy policy", style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            "Tu privacidad es importante para nosotros. Los datos de perfil que "
            "ingreses (nombre, correo, teléfono, dirección y foto) se guardan "
            "únicamente para personalizar tu experiencia dentro de la app y no "
            "se comparten con terceros sin tu consentimiento. Puedes editar o "
            "eliminar esta información en cualquier momento desde Perfil > Edit "
            "profile information.",
            style: TextStyle(color: theme.colorScheme.onSurface, height: 1.5),
          ),
        ),
      ),
    );
  }
}
