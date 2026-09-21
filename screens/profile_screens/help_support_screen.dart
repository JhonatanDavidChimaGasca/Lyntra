import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const List<Map<String, String>> _faqs = [
    {
      "q": "¿Cómo edito mi perfil?",
      "a": "Ve a Perfil > Edit profile information, actualiza tus datos y toca SUBMIT.",
    },
    {
      "q": "¿Cómo cambio mi foto?",
      "a": "Toca el ícono de lápiz sobre tu foto de perfil y elige una imagen de tu galería.",
    },
    {
      "q": "¿Cómo activo o desactivo notificaciones?",
      "a": "Ve a Perfil > Notifications y ajusta cada interruptor según lo que quieras recibir.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
        title: Text("Help & Support", style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: _faqs
            .map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f["q"]!, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                      const SizedBox(height: 4),
                      Text(f["a"]!, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}
