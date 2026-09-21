import 'package:flutter/material.dart';

import '../../core/profile/profile_controller.dart';
import '../../widgets/app_side_menu.dart';

import '../promo_codes_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ProfileController _profile = ProfileController.instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: AppSideMenu(
        currentLocation: MenuLocation.notifications,
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
        title: Text("Notifications", style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      // Escucha al ProfileController: cualquier cambio en un switch se
      // refleja al instante aquí y también en la tarjeta de "Notifications"
      // de la pantalla de Perfil (ON/OFF).
      body: AnimatedBuilder(
        animation: _profile,
        builder: (context, _) {
          final n = _profile.notifications;
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _section(context, "Common"),
              _switchTile("General Notification", n.generalNotification, (v) => _profile.setNotification('generalNotification', v)),
              _switchTile("Sound", n.sound, (v) => _profile.setNotification('sound', v)),
              _switchTile("Vibrate", n.vibrate, (v) => _profile.setNotification('vibrate', v)),
              _section(context, "System & services update"),
              _switchTile("App updates", n.appUpdates, (v) => _profile.setNotification('appUpdates', v)),
              _switchTile("Bill Reminder", n.billReminder, (v) => _profile.setNotification('billReminder', v)),
              _switchTile("Promotion", n.promotion, (v) => _profile.setNotification('promotion', v)),
              _switchTile("Discount Available", n.discountAvailable, (v) => _profile.setNotification('discountAvailable', v)),
              _switchTile("Payment Request", n.paymentRequest, (v) => _profile.setNotification('paymentRequest', v)),
              _section(context, "Others"),
              _switchTile("New Service Available", n.newServiceAvailable, (v) => _profile.setNotification('newServiceAvailable', v)),
              _switchTile("New Tips Available", n.newTipsAvailable, (v) => _profile.setNotification('newTipsAvailable', v)),
            ],
          );
        },
      ),
    );
  }

  Widget _section(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).colorScheme.onSurface)),
    );
  }

  Widget _switchTile(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: Colors.orange,
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontSize: 14)),
    );
  }
}
