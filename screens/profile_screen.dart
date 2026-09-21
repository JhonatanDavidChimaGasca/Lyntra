import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../core/app_locator.dart';
import '../core/profile/profile_controller.dart';
import '../core/profile/theme_controller.dart';
import '../widgets/app_side_menu.dart';

import 'login_screen.dart';
import 'promo_codes_screen.dart';
import 'profile_screens/edit_profile_screen.dart';
import 'profile_screens/notifications_screen.dart';
import 'profile_screens/language_screen.dart';
import 'profile_screens/security_screen.dart';
import 'profile_screens/theme_screen.dart';
import 'profile_screens/help_support_screen.dart';
import 'profile_screens/contact_us_screen.dart';
import 'profile_screens/privacy_policy_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ProfileController _profile = ProfileController.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = AppLocator.auth.currentUser;
      if (user != null && _profile.fullName == "Usuario PyMES") {
        _profile.updatePersonalInfo(
          fullName: user.displayName ?? _profile.fullName,
          label: user.email ?? _profile.label,
        );
        if (user.photoUrl != null) _profile.setPhotoUrl(user.photoUrl!);
      }
    });
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (xfile != null) {
        _profile.setPhotoFile(File(xfile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No se pudo actualizar la foto: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: AppSideMenu(
        currentLocation: MenuLocation.profile,
        onPromocionesTap: () {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PromoCodesScreen()));
        },
      ),
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: theme.colorScheme.onSurface),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text("Perfil", style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: _profile,
        builder: (context, _) {
          final bool hasCountry = _profile.countryFlagEmoji.isNotEmpty;
          final bool hasGender = _profile.gender.isNotEmpty;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SocialFanMenu(links: _profile.connectedSocialLinks),
                  Row(
                    children: [
                      if (hasCountry)
                        Text(_profile.countryFlagEmoji, style: const TextStyle(fontSize: 24))
                      else
                        const Opacity(
                          opacity: 0.4,
                          child: Icon(Icons.public, size: 24, color: Colors.grey),
                        ),
                      const SizedBox(width: 10),
                      if (hasGender)
                        Icon(_profile.genderIcon, size: 26, color: theme.colorScheme.primary)
                      else
                        const Opacity(
                          opacity: 0.4,
                          child: Icon(Icons.wc, size: 26, color: Colors.grey),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundImage: _profile.avatarImage,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: _pickPhoto,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            shape: BoxShape.circle,
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                          child: Icon(Icons.edit, size: 18, color: theme.colorScheme.onSurface),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  _profile.fullName,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  "${_profile.label} | ${_profile.phoneCode} ${_profile.phoneNumber}",
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              
              // TARJETA 1: Edit Profile, Notifications, Language (Animación Entrada 1)
              _AnimatedSlideUp(
                delayMilliseconds: 100,
                child: _buildCard(theme, [
                  _buildRow(
                    theme,
                    icon: Icons.badge_outlined,
                    label: "Edit profile information",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                  ),
                  _buildRow(
                    theme,
                    icon: Icons.notifications_none,
                    label: "Notifications",
                    trailing: _profile.notifications.generalNotification ? "ON" : "OFF",
                    trailingColor: Colors.orange,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                  ),
                  _buildRow(
                    theme,
                    icon: Icons.translate,
                    label: "Language",
                    trailing: _profile.language,
                    trailingColor: Colors.orange,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageScreen())),
                    isLast: true,
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              
              // TARJETA 2: Security, Theme (Animación Entrada 2)
              _AnimatedSlideUp(
                delayMilliseconds: 250,
                child: _buildCard(theme, [
                  _buildRow(
                    theme,
                    icon: Icons.security,
                    label: "Security",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityScreen())),
                  ),
                  AnimatedBuilder(
                    animation: ThemeController.instance,
                    builder: (context, _) => _buildRow(
                      theme,
                      icon: Icons.dark_mode_outlined,
                      label: "Theme",
                      trailing: ThemeController.instance.label,
                      trailingColor: Colors.orange,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ThemeScreen())),
                      isLast: true,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              
              // TARJETA 3: Help, Contact, Privacy (Animación Entrada 3)
              _AnimatedSlideUp(
                delayMilliseconds: 400,
                child: _buildCard(theme, [
                  _buildRow(
                    theme,
                    icon: Icons.people_outline,
                    label: "Help & Support",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen())),
                  ),
                  _buildRow(
                    theme,
                    icon: Icons.chat_bubble_outline,
                    label: "Contact us",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactUsScreen())),
                  ),
                  _buildRow(
                    theme,
                    icon: Icons.lock_outline,
                    label: "Privacy policy",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                    isLast: true,
                  ),
                ]),
              ),
              const SizedBox(height: 24),
              
              // BOTÓN CERRAR SESIÓN (Animación Entrada 4)
              _AnimatedSlideUp(
                delayMilliseconds: 550,
                child: Center(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await AppLocator.auth.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text("Cerrar sesión", style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCard(ThemeData theme, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    String? trailing,
    Color? trailingColor,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast ? null : Border(bottom: BorderSide(color: theme.dividerColor)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.onSurface),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface))),
            if (trailing != null)
              Text(trailing, style: TextStyle(color: trailingColor ?? theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// Widget auxiliar para la animación de deslizar de abajo hacia arriba con retardo (fade + slide up)
class _AnimatedSlideUp extends StatelessWidget {
  final Widget child;
  final int delayMilliseconds;

  const _AnimatedSlideUp({
    required this.child,
    this.delayMilliseconds = 0,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delayMilliseconds),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - value)), // Desplazamiento desde 40px abajo hacia 0px
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}


// Mini-menú de redes sociales conectadas
const Map<String, dynamic> _socialIcons = {
  'instagram': FontAwesomeIcons.instagram,
  'x': FontAwesomeIcons.xTwitter,
  'facebook': FontAwesomeIcons.facebook,
  'tiktok': FontAwesomeIcons.tiktok,
  'whatsapp': FontAwesomeIcons.whatsapp,
};

const Map<String, Color> _socialColors = {
  'instagram': Color(0xFFE1306C),
  'x': Colors.black,
  'facebook': Color(0xFF1877F2),
  'tiktok': Colors.black,
  'whatsapp': Color(0xFF25D366),
};

class _SocialFanMenu extends StatefulWidget {
  final Map<String, String> links;
  const _SocialFanMenu({required this.links});

  @override
  State<_SocialFanMenu> createState() => _SocialFanMenuState();
}

class _SocialFanMenuState extends State<_SocialFanMenu> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  bool _open = false;

  static const double _buttonSize = 44;
  static const double _itemSpacing = 52;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (widget.links.isEmpty) return;
    setState(() => _open = !_open);
    _open ? _controller.forward() : _controller.reverse();
  }

  Future<void> _openLink(String rawUrl) async {
    var url = rawUrl.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No se pudo abrir $url")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.links.entries.toList();

    if (entries.isEmpty) {
      return Opacity(
        opacity: 0.4,
        child: Container(
          width: _buttonSize,
          height: _buttonSize,
          decoration: const BoxDecoration(
            color: Colors.grey,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.share, color: Colors.white, size: 20),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final height = _buttonSize + (_controller.value * entries.length * _itemSpacing);
        return SizedBox(
          width: _buttonSize,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              for (var i = 0; i < entries.length; i++) _buildItem(i, entries.length, entries[i].key, entries[i].value),
              Positioned(
                bottom: 0,
                child: _MainToggleButton(open: _open, onTap: _toggle),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItem(int index, int total, String platformKey, String url) {
    final start = (index / total) * 0.4;
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1.0, curve: Curves.easeOutBack),
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final value = animation.value.clamp(0.0, 1.0);
        final riseOffset = (_buttonSize + index * _itemSpacing) * value;
        return Positioned(
          bottom: riseOffset,
          child: Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.6 + 0.4 * value,
              alignment: Alignment.bottomCenter,
              child: IgnorePointer(
                ignoring: value < 0.5,
                child: _SocialIconButton(platformKey: platformKey, onTap: () => _openLink(url)),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MainToggleButton extends StatefulWidget {
  final bool open;
  final VoidCallback onTap;
  const _MainToggleButton({required this.open, required this.onTap});

  @override
  State<_MainToggleButton> createState() => _MainToggleButtonState();
}

class _MainToggleButtonState extends State<_MainToggleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _pressed ? 0.15 : 0.3),
                blurRadius: _pressed ? 2 : 6,
                offset: Offset(0, _pressed ? 1 : 3),
              ),
            ],
          ),
          child: AnimatedRotation(
            turns: widget.open ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(widget.open ? Icons.close : Icons.share, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _SocialIconButton extends StatefulWidget {
  final String platformKey;
  final VoidCallback onTap;
  const _SocialIconButton({required this.platformKey, required this.onTap});

  @override
  State<_SocialIconButton> createState() => _SocialIconButtonState();
}

class _SocialIconButtonState extends State<_SocialIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final icon = _socialIcons[widget.platformKey] ?? Icons.link;
    final color = _socialColors[widget.platformKey] ?? Colors.grey;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _pressed ? 0.1 : 0.28),
                blurRadius: _pressed ? 2 : 5,
                offset: Offset(0, _pressed ? 1 : 3),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}