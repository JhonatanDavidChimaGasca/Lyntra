import 'package:flutter/material.dart';

import '../core/app_locator.dart';
import '../core/profile/profile_controller.dart';
import '../domain/entities/product.dart';
import '../widgets/app_side_menu.dart';

import 'promo_codes_screen.dart';
import 'profile_screen.dart';
import 'product_info_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: AppSideMenu(
        currentLocation: MenuLocation.home,
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
        title: Text("Lyntra", style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              // Escucha al ProfileController para que, en cuanto el usuario
              // cargue o cambie su foto de perfil, este ícono se actualice
              // al instante sin necesidad de recargar la pantalla.
              child: AnimatedBuilder(
                animation: ProfileController.instance,
                builder: (context, _) {
                  return CircleAvatar(
                    backgroundImage: ProfileController.instance.avatarImage,
                    radius: 18,
                  );
                },
              ),
            ),
          )
        ],
      ),
      body: StreamBuilder<List<Product>>(
        stream: AppLocator.products.getProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory, size: 80, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text("No tienes productos aún", style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Text("Toca el botón + para agregar tu primer producto", style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            );
          }

          // Agrupar productos separando cada categoría
          Map<String, List<Product>> groupedProducts = {};
          for (var product in products) {
            // Separamos las categorías por coma y limpiamos los espacios
            final categories = product.category.split(',').map((c) => c.trim()).toList();

            // Agregamos el producto a la lista de cada categoría que tenga asignada
            for (var cat in categories) {
              if (cat.isNotEmpty) {
                if (!groupedProducts.containsKey(cat)) {
                  groupedProducts[cat] = [];
                }
                groupedProducts[cat]!.add(product);
              }
            }
          }

          return ListView(
            children: groupedProducts.entries.map((entry) {
              final categoryName = entry.key;
              final categoryProducts = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(categoryName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                        Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 200, // Altura fija del contenedor de la lista
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categoryProducts.length,
                      itemBuilder: (context, index) {
                        final product = categoryProducts[index];
                        return GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductInfoScreen(product: product))),
                          child: Container(
                            width: 140,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: theme.cardColor,
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), spreadRadius: 1, blurRadius: 3)],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Uso de Expanded para evitar overflow y adaptar la imagen
                                Expanded(
                                  flex: 3,
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12),
                                      ),
                                      clipBehavior: Clip.hardEdge,
                                      child: product.imageUrl.isNotEmpty
                                          ? Image.network(
                                              product.imageUrl,
                                              fit: BoxFit.cover, // Fuerza a que la imagen cubra todo el espacio sin deformarse
                                              width: double.infinity,
                                              height: double.infinity,
                                              alignment: Alignment.center,
                                              errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(context),
                                            )
                                          : _buildPlaceholderImage(context),
                                    ),
                                  ),
                                ),
                                // Uso de Expanded para la sección de texto
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          product.name,
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "\$${product.price.toStringAsFixed(2)}",
                                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholderImage(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(Icons.image, size: 40, color: theme.colorScheme.onSurfaceVariant),
    );
  }
}
