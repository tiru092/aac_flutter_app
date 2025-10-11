import '../utils/aac_logger.dart';
import 'data_services_initializer_robust.dart' as robust;

/// Import the concrete service types so the delegator can expose typed getters
import 'user_data_manager.dart';
import 'favorites_service.dart';
import 'phrase_history_service.dart';
import 'custom_categories_service.dart';

/// Thin delegator kept for compatibility with existing imports.
/// Forwards initialization and status logging to the robust singleton.
class DataServicesInitializer {
  DataServicesInitializer._();
  static final instance = DataServicesInitializer._();

  /// Forward to robust initializer
  Future<void> initialize() async {
    AACLogger.info('Delegator: forwarding initialize() to robust DataServicesInitializer');
    await robust.DataServicesInitializer.instance.initialize();
  }

  /// Forward log status
  void logServiceStatus() => robust.DataServicesInitializer.instance.logServiceStatus();

  /// Compatibility getters (typed to match original imports)
  UserDataManager? get userDataManager => robust.DataServicesInitializer.instance.userDataManager;
  FavoritesService? get favoritesService => robust.DataServicesInitializer.instance.favoritesService;
  PhraseHistoryService? get phraseHistoryService => robust.DataServicesInitializer.instance.phraseHistoryService;
  CustomCategoriesService? get customCategoriesService => robust.DataServicesInitializer.instance.customCategoriesService;
}
