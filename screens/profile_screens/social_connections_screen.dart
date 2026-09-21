import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/profile/profile_controller.dart';
import '../../widgets/app_side_menu.dart';
import '../promo_codes_screen.dart';

class _SocialPlatformDef {
  final String key;
  final String label;
  final FaIconData icon;
  final Color color;
  final String hint;
  const _SocialPlatformDef(this.key, this.label, this.icon, this.color, this.hint);
}

// Definición fija de las 5 redes soportadas: ícono real de marca (paquete
// font_awesome_flutter), color de marca, y un ejemplo de cómo debería verse
// el enlace/usuario para guiar al usuario al escribir.
const List<_SocialPlatformDef> _platforms = [
  _SocialPlatformDef(
    'instagram',
    'Instagram',
    FontAwesomeIcons.instagram,
    Color(0xFFE1306C),
    'https://instagram.com/tu_usuario',
  ),
  _SocialPlatformDef(
    'x',
    'X (Twitter)',
    FontAwesomeIcons.xTwitter,
    Colors.black,
    'https://x.com/tu_usuario',
  ),
  _SocialPlatformDef(
    'facebook',
    'Facebook',
    FontAwesomeIcons.facebook,
    Color(0xFF1877F2),
    'https://facebook.com/tu_usuario',
  ),
  _SocialPlatformDef(
    'tiktok',
    'TikTok',
    FontAwesomeIcons.tiktok,
    Colors.black,
    'https://tiktok.com/@tu_usuario',
  ),
  _SocialPlatformDef(
    'whatsapp',
    'WhatsApp',
    FontAwesomeIcons.whatsapp,
    Color(0xFF25D366),
    'https://wa.me/573001234567',
  ),
];

/// Pantalla donde el usuario registra el enlace (o usuario) de cada red
/// social. No hay inicio de sesión ni verificación con la otra app: es un
/// campo de texto simple por red, tal como se guarda cualquier otro dato de
/// perfil. Una vez guardado, el ícono de esa red aparece en la pantalla de
/// Perfil dentro del mini-menú de redes conectadas.
class SocialConnectionsScreen extends StatefulWidget {
  const SocialConnectionsScreen({super.key});

  @override
  State<SocialConnectionsScreen> createState() => _SocialConnectionsScreenState();
}

class _SocialConnectionsScreenState extends State<SocialConnectionsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ProfileController _profile = ProfileController.instance;
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final p in _platforms) p.key: TextEditingController(text: _profile.socialLinks[p.key] ?? ''),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    _profile.updateSocialLinks({for (final p in _platforms) p.key: _controllers[p.key]!.text});
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Redes sociales actualizadas")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: AppSideMenu(
        currentLocation: MenuLocation.socialConnections,
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
          "Conexiones a redes sociales",
          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "Pega aquí el enlace (o tu usuario) de cada red. Solo se mostrará "
            "el ícono de las que dejes con un valor.",
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 20),
          for (final platform in _platforms) ...[
            _buildPlatformField(theme, platform),
            const SizedBox(height: 18),
          ],
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text("GUARDAR", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  // Ícono a la izquierda, título arriba del campo de texto (como se pidió).
  Widget _buildPlatformField(ThemeData theme, _SocialPlatformDef platform) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.only(top: 22),
          decoration: BoxDecoration(color: platform.color, shape: BoxShape.circle),
          child: FaIcon(platform.icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                platform.label,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _controllers[platform.key],
                keyboardType: TextInputType.url,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: platform.hint,
                  hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: platform.color, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
