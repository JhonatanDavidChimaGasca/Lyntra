import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_locator.dart';
import '../domain/entities/promo_code.dart';


class AddPromoCodeScreen extends StatefulWidget {
  const AddPromoCodeScreen({super.key});

  @override
  State<AddPromoCodeScreen> createState() => _AddPromoCodeScreenState();
}

class _AddPromoCodeScreenState extends State<AddPromoCodeScreen> {
  final TextEditingController codeController = TextEditingController();
  final TextEditingController discountController = TextEditingController();
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now().add(const Duration(days: 30));
  bool isLoading = false;

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
        title: Text("Agregar Promoción", style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("INFORMACIÓN DE LA PROMOCIÓN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: "Código promocional",
                hintText: "Ej: DESCUENTO20",
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: discountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: "Descuento (%)",
                hintText: "Ej: 20",
                border: OutlineInputBorder(),
                suffixText: "%",
              ),
            ),
            const SizedBox(height: 20),
            
            const Text("FECHAS DE VIGENCIA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text("Fecha de inicio"),
              subtitle: Text(_formatDate(startDate)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _selectDate(true),
            ),
            
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text("Fecha de finalización"),
              subtitle: Text(_formatDate(endDate)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _selectDate(false),
            ),
            
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _savePromoCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Crear Promoción", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? startDate : endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
          if (endDate.isBefore(startDate)) {
            endDate = startDate.add(const Duration(days: 1));
          }
        } else {
          endDate = picked;
        }
      });
    }
  }

  void _savePromoCode() async {
    if (codeController.text.isEmpty || discountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor completa todos los campos"), backgroundColor: Colors.red),
      );
      return;
    }

    if (endDate.isBefore(startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La fecha de fin debe ser posterior a la fecha de inicio"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final promoCode = PromoCode(
        id: '',
        code: codeController.text.toUpperCase(),
        status: 'Habilitado',
        startDate: startDate,
        endDate: endDate,
        userId: AppLocator.auth.currentUserId,
        discount: double.parse(discountController.text),
      );

      bool confirmedByServer = true;
      try {
        await AppLocator.promoCodes.addPromoCode(promoCode).timeout(const Duration(seconds: 8));
      } on TimeoutException {
        // El documento ya se escribió en el caché local (por eso aparece en la lista),
        // pero el servidor tardó en confirmar. No dejamos el botón cargando para siempre.
        confirmedByServer = false;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(confirmedByServer
              ? "Código promocional creado exitosamente"
              : "Código creado, pero la confirmación del servidor está tardando (revisa tu conexión)"),
          backgroundColor: confirmedByServer ? Colors.green : Colors.orange,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al crear promoción: $e"), backgroundColor: Colors.red),
      );
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}