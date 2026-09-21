import 'package:flutter/material.dart';

import '../../core/profile/profile_controller.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  static const List<String> _languages = ["English", "Español", "Português", "Français"];

  @override
  Widget build(BuildContext context) {
    final profile = ProfileController.instance;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
        title: Text("Language", style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
      ),
      body: AnimatedBuilder(
        animation: profile,
        builder: (context, _) {
          return ListView(
            children: _languages.map((lang) {
              final selected = profile.language == lang;
              return ListTile(
                title: Text(lang),
                trailing: selected ? const Icon(Icons.check_circle, color: Colors.orange) : null,
                onTap: () {
                  profile.setLanguage(lang);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
