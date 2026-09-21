import 'package:flutter/material.dart';

import '../../core/profile/theme_controller.dart';
import '../../widgets/app_side_menu.dart';
import '../promo_codes_screen.dart';

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: AppSideMenu(
        currentLocation: MenuLocation.theme,
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
        title: Text(
          "Tema",
          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: ThemeController.instance,
        builder: (context, _) {
          final currentMode = ThemeController.instance.mode;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _themeOption(
                context,
                "Light mode",
                Icons.light_mode_outlined,
                currentMode == ThemeMode.light,
                () => ThemeController.instance.setMode(ThemeMode.light),
              ),
              _themeOption(
                context,
                "Dark mode",
                Icons.dark_mode_outlined,
                currentMode == ThemeMode.dark,
                () => ThemeController.instance.setMode(ThemeMode.dark),
              ),
              _themeOption(
                context,
                "System default",
                Icons.brightness_auto_outlined,
                currentMode == ThemeMode.system,
                () => ThemeController.instance.setMode(ThemeMode.system),
              ),
              const SizedBox(height: 12),
              Text(
                "Nota: para que el tema se aplique visualmente en toda la app, "
                "el MaterialApp en main.dart debe escuchar ThemeController.instance "
                "y usar su valor en la propiedad themeMode.",
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _themeOption(BuildContext context, String label, IconData icon, bool selected, VoidCallback onTap) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurface),
      title: Text(label, style: TextStyle(color: theme.colorScheme.onSurface)),
      trailing: selected ? Icon(Icons.check_circle, color: theme.colorScheme.primary) : null,
      onTap: onTap,
    );
  }
}
