import 'package:flutter/material.dart';


class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});

//PANTALLA DE RESEÑAS//
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reseñas"),
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, size: 80, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text("Aún no hay reseñas", style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
} 

// Este apartado aun esta en desarrollo, se planea que en un futuro se pueda mostrar las reseñas de los productos y servicios de todos los usuarios activos en la plataforma.