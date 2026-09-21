import 'package:flutter/material.dart';

import '../core/app_locator.dart';
import '../domain/entities/promo_code.dart';
import 'add_promo_code_screen.dart';

class PromoCodesScreen extends StatefulWidget {
  const PromoCodesScreen({super.key});

  @override
  State<PromoCodesScreen> createState() => _PromoCodesScreenState();
}

class _PromoCodesScreenState extends State<PromoCodesScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Promociones", style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPromoCodeScreen())),
          ),
        ],
      ),
      body: StreamBuilder<List<PromoCode>>(
        stream: AppLocator.promoCodes.getPromoCodes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final promoCodes = snapshot.data ?? [];

          if (promoCodes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_offer, size: 80, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text("No tienes códigos promocionales", style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Text("Toca el botón + para crear tu primera promoción", style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: promoCodes.length,
            itemBuilder: (context, index) {
              final promoCode = promoCodes[index];
              final status = promoCode.getStatus();
              Color statusColor;
              
              switch (status) {
                case 'Habilitado':
                  statusColor = Colors.green;
                  break;
                case 'Expirado':
                  statusColor = Colors.red;
                  break;
                default:
                  statusColor = Colors.orange;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.local_offer, color: statusColor),
                  ),
                  title: Text(promoCode.code, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Descuento: ${promoCode.discount}%"),
                      Text("Válido: ${_formatDate(promoCode.startDate)} - ${_formatDate(promoCode.endDate)}", 
                           style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}