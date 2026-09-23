import '../data/firebase/firebase_auth_repository.dart';
import '../data/firebase/firestore_product_repository.dart';
import '../data/firebase/firestore_promo_code_repository.dart';
import '../data/local/shared_prefs_product_draft_repository.dart';
import '../data/local/shared_prefs_settings_repository.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/product_draft_repository.dart';
import '../domain/repositories/product_repository.dart';
import '../domain/repositories/promo_code_repository.dart';
import '../domain/repositories/settings_repository.dart';

/// Punto único donde se conectan los puertos (interfaces de dominio) con
/// sus adaptadores concretos (Firebase, SharedPreferences...).
///
/// Es una alternativa deliberadamente simple a paquetes como get_it o
/// provider: el proyecto no traía ningún framework de inyección de
/// dependencias, así que en vez de agregar uno nuevo, esto son solo
/// variables estáticas de Dart. Las pantallas llaman, por ejemplo,
/// `AppLocator.products.getProducts()` en vez de `FirebaseService.getProducts()`
/// — no conocen ni les importa que detrás hay Firestore.
///
/// Si más adelante se prefiere algun otro framework este archivo es el único que tendrías que tocar.
class AppLocator {
  AppLocator._();

  static final AuthRepository auth = FirebaseAuthRepository();
  static final ProductRepository products = FirestoreProductRepository(auth);
  static final PromoCodeRepository promoCodes = FirestorePromoCodeRepository(auth);
  static final SettingsRepository settings = SharedPrefsSettingsRepository();
  static final ProductDraftRepository productDraft = SharedPrefsProductDraftRepository();
}
  
