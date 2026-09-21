import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Importado para el formato de miles
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart'; // Importado para la compresión

import '../core/errors/image_error_box.dart';
import '../core/app_locator.dart';
import '../widgets/product_categories.dart';
import '../domain/entities/product.dart';
import '../domain/entities/product_draft.dart';
import '../widgets/category_filter_dialog.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> with WidgetsBindingObserver {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController brandController = TextEditingController();

  List<String> selectedCategories = []; 
  String selectedImageUrl = "";
  bool isLoading = false;
  String? _imageUploadError;

  Timer? _autosaveTimer;
  bool _isDraftLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDraft();

    for (final controller in [nameController, descriptionController, priceController, brandController]) {
      controller.addListener(_scheduleAutosave);
    }
  }

  Future<void> _loadDraft() async {
    try {
      final userId = AppLocator.auth.currentUserId;
      final draft = await AppLocator.productDraft.getDraft(userId);
      if (draft != null && mounted) {
        setState(() {
          nameController.text = draft.name;
          descriptionController.text = draft.description;
          brandController.text = draft.brand;
          
          if (draft.price.isNotEmpty) {
             String clean = draft.price.replaceAll(RegExp(r'[^0-9]'), '');
             String formatted = '';
             int count = 0;
             for (int i = clean.length - 1; i >= 0; i--) {
               if (count > 0 && count % 3 == 0) formatted = '.$formatted';
               formatted = clean[i] + formatted;
               count++;
             }
             priceController.text = formatted;
          }

          if (draft.category.isNotEmpty) {
            selectedCategories = draft.category
                .split(',')
                .map((e) => e.trim())
                .where((cat) => ProductCategories.all.contains(cat)) 
                .toList();
          }
          selectedImageUrl = draft.imageUrl;
        });
      }
    } catch (_) {
    } finally {
      _isDraftLoaded = true;
    }
  }

  void _scheduleAutosave() {
    if (!_isDraftLoaded) return;
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(milliseconds: 600), _saveDraftNow);
  }

  Future<void> _saveDraftNow() async {
    try {
      final userId = AppLocator.auth.currentUserId;
      final draft = ProductDraft(
        name: nameController.text,
        description: descriptionController.text,
        brand: brandController.text,
        price: priceController.text.replaceAll('.', ''),
        quantity: '1',
        category: selectedCategories.join(', '), 
        imageUrl: selectedImageUrl,
      );
      await AppLocator.productDraft.saveDraft(userId, draft);
    } catch (_) {}
  }

  Future<void> _clearDraft() async {
    try {
      await AppLocator.productDraft.clearDraft(AppLocator.auth.currentUserId);
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _saveDraftNow();
    }
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _saveDraftNow();
    WidgetsBinding.instance.removeObserver(this);
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    brandController.dispose();
    super.dispose();
  }

  void _openCategorySelector() async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryFilterDialog(
        allItems: ProductCategories.all,
        initialSelection: selectedCategories,
      ),
    );
    if (result != null) {
      setState(() {
        selectedCategories = result;
      });
      _scheduleAutosave();
    }
  }

  Future<void> _pickAndUploadFromDevice() async {
    try {
      setState(() {
        isLoading = true;
        _imageUploadError = null;
      });

      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
      
      if (picked == null) {
        setState(() => isLoading = false);
        return;
      }

      final extension = picked.name.split('.').last.toLowerCase();
      final unsupportedFormats = ['pdf', 'doc', 'docx', 'mp4']; 
      if (unsupportedFormats.contains(extension)) {
        throw Exception("El formato .$extension no es una imagen válida.");
      }

      final targetPath = '${picked.path}_compressed.jpg';
      XFile? compressedFile;
      
      try {
        compressedFile = await FlutterImageCompress.compressAndGetFile(
          picked.path,
          targetPath,
          quality: 80, // Compresion moderada
         minWidth: 1080, 
          minHeight: 1080,
        );
      } catch (e) {
        // Si falla la compresión, se intenta con el archivo original
        debugPrint("Error al comprimir: $e. Subiendo original.");
      }

      final fileToUpload = File(compressedFile?.path ?? picked.path);
      final path = 'products/${AppLocator.auth.currentUserId}/${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
      final ref = FirebaseStorage.instance.ref().child(path);

      await ref.putFile(fileToUpload);
      final url = await ref.getDownloadURL();

      setState(() {
        selectedImageUrl = url;
        _imageUploadError = null;
      });
      _scheduleAutosave();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagen subida correctamente'), backgroundColor: Colors.green),
      );
    } catch (e) {
      setState(() {
        _imageUploadError = "Formato no compatible o error de red. Detalles: ${e.toString().split(']').last.trim()}";
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _saveProduct() async {
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    final brand = brandController.text.trim();
    final priceText = priceController.text.replaceAll('.', '');

    // 1. Validar campos obligatorios vacíos
    if (name.isEmpty || priceText.isEmpty || selectedCategories.isEmpty || selectedImageUrl.isEmpty) { 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor completa los campos obligatorios: Nombre, Precio, Categorías e Imagen."), 
          backgroundColor: Colors.red
        ),
      );
      return;
    }

    // 2. Validar longitud del nombre del producto
    if (name.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El nombre del producto debe tener al menos 3 caracteres."), backgroundColor: Colors.red),
      );
      return;
    }

    // 3. Validar longitud opcional de la descripción
    if (description.isNotEmpty && description.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La descripción es muy corta. Debe tener al menos 10 caracteres."), backgroundColor: Colors.red),
      );
      return;
    }

    // 4. Validar formato y rango del precio
    double? parsedPrice = double.tryParse(priceText);
    if (parsedPrice == null || parsedPrice < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El precio debe ser de al menos \$ 100."), backgroundColor: Colors.red),
      );
      return;
    }

    // 5. Validar longitud de la marca (opcional)
    if (brand.isNotEmpty && brand.length > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El nombre de la marca es demasiado largo (máximo 50 caracteres)."), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final product = Product(
        id: '',
        name: name,
        category: selectedCategories.join(', '), 
        description: description,
        brand: brand,
        price: parsedPrice,
        quantity: 1, 
        imageUrl: selectedImageUrl,
        userId: AppLocator.auth.currentUserId,
        createdAt: DateTime.now(),
      );

      await AppLocator.products.addProduct(product);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Producto agregado exitosamente"), backgroundColor: Colors.green),
      );

      await _clearForm();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _clearForm() async {
    nameController.clear();
    descriptionController.clear();
    priceController.clear();
    brandController.clear();
    setState(() {
      selectedCategories = [];
      selectedImageUrl = "";
    });
    await _clearDraft();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text("Agregar Producto", style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("INFORMACIÓN DEL PRODUCTO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nombre del producto", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            const Text("Categorías (Filtros): ", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            InkWell(
              onTap: _openCategorySelector,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outline),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "Selecciona las categorías para este producto",
                        style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                "Advertencia: No abuse del uso de las categorías, se recomienda usarlas de manera adecuada para definir su producto. Se tomará acción en caso de uso indebido.",
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic),
              ),
            ),
            
            if (selectedCategories.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: selectedCategories.map((cat) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '#$cat',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 20),
            const Text("IMAGEN DEL PRODUCTO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),

            GestureDetector(
              onTap: _imageUploadError != null ? null : _pickAndUploadFromDevice,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.surfaceContainerLow,
                ),
                child: _imageUploadError != null
                    ? ImageErrorBox(
                        errorMessage: _imageUploadError!,
                        onRetry: () {
                          setState(() {
                            _imageUploadError = null;
                          });
                          _pickAndUploadFromDevice();
                        },
                      )
                    : selectedImageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              selectedImageUrl, 
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Text("El formato de la imagen cargada no es soportado por la vista previa.", textAlign: TextAlign.center),
                                );
                              },
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 50, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(height: 8),
                              Text("Toca para seleccionar imagen", style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14)),
                            ],
                          ),
              ),
            ),

            const SizedBox(height: 30),
            
            const Text("DATOS ADICIONALES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),

            TextField(
              controller: brandController,
              decoration: InputDecoration(
                label: Text.rich(
                  TextSpan(
                    text: 'Marca ',
                    children: [
                      TextSpan(text: '(Opcional)', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14)),
                      
                    ],
                  ),
                ),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                label: Text.rich(
                  TextSpan(
                    text: 'Descripción ',
                    children: [
                      TextSpan(text: '(Opcional)', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14)),
                    ],
                  ),
                ),
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            
            const SizedBox(height: 30),
            
            Divider(color: theme.dividerColor, thickness: 1.5),
            const SizedBox(height: 20),

            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsFormatter()],
              decoration: const InputDecoration(
                labelText: "Precio", 
                prefixText: "\$ ", 
                border: OutlineInputBorder()
              ),
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Guardar Producto", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    
    String numericOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (numericOnly.isEmpty) return const TextEditingValue(text: '');
    
    String formatted = '';
    int count = 0;
    for (int i = numericOnly.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        formatted = '.$formatted'; 
      }
      formatted = numericOnly[i] + formatted;
      count++;
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}