import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_locator.dart';
import '../widgets/product_categories.dart';
import '../domain/entities/product.dart';
import 'product_info_screen.dart';
import '../widgets/category_filter_dialog.dart';

/// Ámbito de búsqueda seleccionado en la barra de filtros superior.
enum SearchScope { productos, prestamos, cuentas }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController searchController = TextEditingController();
  List<Product> searchResults = [];
  List<Map<String, dynamic>> accountResults = [];
  List<String> activeFilters = [];
  bool isSearching = false;
  SearchScope _scope = SearchScope.productos;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final queryText = searchController.text.trim();

    setState(() {
      isSearching = queryText.isNotEmpty;
    });

    if (queryText.isEmpty) {
      setState(() {
        searchResults = [];
        accountResults = [];
      });
      return;
    }

    switch (_scope) {
      case SearchScope.productos:
        AppLocator.products.searchProducts(queryText).listen((products) {
          if (mounted) {
            setState(() {
              searchResults = products;
            });
          }
        });
        break;

      case SearchScope.cuentas:
        _searchAccounts(queryText);
        break;

      case SearchScope.prestamos:
        break;
    }
  }

  /// Busca cuentas públicamente únicamente por @nickname o Nombre Completo.
  /// No consulta ni expone correos electrónicos para proteger la seguridad.
  void _searchAccounts(String query) {
    // Normalizamos quitando el icono @ si el usuario lo incluye en la búsqueda
    final cleanQuery = query.startsWith('@') ? query.substring(1) : query;
    final lowerQuery = cleanQuery.toLowerCase();

    FirebaseFirestore.instance
        .collection('users') // Nombre de la colección de usuarios en Firestore
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;

      final results = snapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return data;
      }).where((user) {
        final uid = (user['uid'] ?? '').toString();
        
        // Genera un nickname único por defecto basado en su UID para usuarios no configurados
        final defaultNick = 'user_${uid.length >= 6 ? uid.substring(0, 6) : uid}';

        final nickName = (user['nickName'] ?? user['nickname'] ?? defaultNick).toString().toLowerCase();
        final fullName = (user['fullName'] ?? user['name'] ?? '').toString().toLowerCase();

        // Filtra únicamente por coincidencias en Nickname o Nombre Público
        return nickName.contains(lowerQuery) || fullName.contains(lowerQuery);
      }).toList();

      setState(() {
        accountResults = results;
      });
    }, onError: (e) {
      debugPrint("Error al buscar cuentas: $e");
    });
  }

  List<Product> get filteredResults {
    if (activeFilters.isEmpty) return searchResults;
    return searchResults.where((product) {
      final productCategories = product.category.split(',').map((c) => c.trim()).toList();
      return activeFilters.any((filter) => productCategories.contains(filter));
    }).toList();
  }

  void _openFilterMenu() async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryFilterDialog(
        allItems: ProductCategories.all,
        initialSelection: activeFilters,
        singleSelection: true,
      ),
    );
    if (result != null) {
      setState(() {
        activeFilters = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedProducts = filteredResults;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text("Buscar", style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildScopeSelector(theme),
            const SizedBox(height: 16),
            if (_scope == SearchScope.prestamos)
              Expanded(child: _buildScopePlaceholder(theme))
            else ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: _scope == SearchScope.cuentas
                            ? "Buscar cuenta por @nickname o nombre..."
                            : "Buscar producto...",
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  searchController.clear();
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                  if (_scope == SearchScope.productos) ...[
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: activeFilters.isNotEmpty ? theme.colorScheme.primaryContainer : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.colorScheme.outline),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.filter_list,
                          color: activeFilters.isNotEmpty ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                        ),
                        onPressed: _openFilterMenu,
                        tooltip: "Filtrar por categorías",
                      ),
                    ),
                  ],
                ],
              ),
              if (_scope == SearchScope.productos && activeFilters.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Filtros activos: ${activeFilters.join(', ')}",
                      style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Expanded(
                child: _buildSearchResultsView(theme, displayedProducts),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultsView(ThemeData theme, List<Product> displayedProducts) {
    if (!isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _scope == SearchScope.cuentas ? Icons.person_search : Icons.search,
              size: 80,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              _scope == SearchScope.cuentas ? "Busca cuentas por @nickname o nombre" : "Busca tus productos",
              style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              "Los resultados aparecerán aquí...",
              style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    // RESULTADOS DE BÚSQUEDA PARA CUENTAS
    if (_scope == SearchScope.cuentas) {
      if (accountResults.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 60, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text("No se encontraron cuentas coincidentes",
                  style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        );
      }

      return ListView.builder(
        itemCount: accountResults.length,
        itemBuilder: (context, index) {
          final account = accountResults[index];
          final String uid = account['uid'] ?? '';

          // Fallback seguro escalable sin depender de datos privados
          final String defaultNick = 'user_${uid.length >= 6 ? uid.substring(0, 6) : uid}';
          final String nick = (account['nickName'] ?? account['nickname'] ?? defaultNick).toString();
          final String name = (account['fullName'] ?? account['name'] ?? 'Usuario PyMES').toString();
          final String label = (account['label'] ?? 'Comercio / Usuario').toString();
          final String? photoUrl = account['photoUrl'];

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
              child: (photoUrl == null || photoUrl.isEmpty)
                  ? Icon(Icons.person, color: theme.colorScheme.onPrimaryContainer)
                  : null,
            ),
            title: Text("@$nick", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("$name • $label"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navegar a los productos o al perfil público del usuario
            },
          );
        },
      );
    }

    // RESULTADOS DE BÚSQUEDA PARA PRODUCTOS
    if (displayedProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text("No se encontraron productos",
                style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: displayedProducts.length,
      itemBuilder: (context, index) {
        final product = displayedProducts[index];
        return ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product.imageUrl.isNotEmpty
                  ? Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.image, color: theme.colorScheme.onSurfaceVariant),
                    )
                  : Icon(Icons.image, color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          title: Text(product.name),
          subtitle: Text("\$${product.price.toStringAsFixed(2)}"),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProductInfoScreen(product: product)),
            );
          },
        );
      },
    );
  }

  Widget _buildScopeSelector(ThemeData theme) {
    return Row(
      children: [
        Expanded(child: _buildScopeChip(theme, SearchScope.productos, "Productos", Icons.inventory_2_outlined)),
        const SizedBox(width: 8),
        Expanded(child: _buildScopeChip(theme, SearchScope.prestamos, "Préstamos", Icons.request_quote_outlined)),
        const SizedBox(width: 8),
        Expanded(child: _buildScopeChip(theme, SearchScope.cuentas, "Cuentas", Icons.account_balance_wallet_outlined)),
      ],
    );
  }

  Widget _buildScopeChip(ThemeData theme, SearchScope scope, String label, IconData icon) {
    final selected = _scope == scope;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        setState(() {
          _scope = scope;
        });
        _onSearchChanged();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScopePlaceholder(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.request_quote_outlined,
            size: 80,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            "Búsqueda de préstamos",
            style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            "Próximamente",
            style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}