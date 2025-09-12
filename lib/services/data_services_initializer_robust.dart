import 'package:firebase_auth/firebase_auth.dart';
import 'user_data_manager.dart';
import 'favorites_service.dart';
import 'phrase_history_service.dart';
import 'settings_service.dart';
import 'custom_categories_service.dart';
import '../utils/aac_logger.dart';

/// A robust, centralized initializer for all data-related services.
/// This class ensures that all services are initialized correctly with a single,
/// consistent Firebase UID.
class DataServicesInitializer {
  static final DataServicesInitializer _instance = DataServicesInitializer._internal();
  static DataServicesInitializer get instance => _instance;
  factory DataServicesInitializer() => _instance;
  DataServicesInitializer._internal();

  bool _isInitialized = false;
  String? _currentUid;

  // Service instances - Using nullable to allow reset
  UserDataManager? _userDataManager;
  FavoritesService? _favoritesService;
  PhraseHistoryService? _phraseHistoryService;
  SettingsService? _settingsService;
  CustomCategoriesService? _customCategoriesService;

  // Getters for service access - UserDataManager is required, others can be null
  UserDataManager get userDataManager {
    if (_userDataManager == null) throw Exception('UserDataManager not initialized');
    return _userDataManager!;
  }
  
  // Optional services - return null if not initialized instead of throwing
  FavoritesService? get favoritesService => _favoritesService;
  PhraseHistoryService? get phraseHistoryService => _phraseHistoryService;
  SettingsService? get settingsService => _settingsService;
  CustomCategoriesService? get customCategoriesService => _customCategoriesService;
  
  // Helper methods to check if services are available
  bool get hasFavoritesService => _favoritesService != null;
  bool get hasPhraseHistoryService => _phraseHistoryService != null;
  bool get hasSettingsService => _settingsService != null;
  bool get hasCustomCategoriesService => _customCategoriesService != null;

  /// Returns true if the services have been successfully initialized.
  bool get isInitialized => _isInitialized;

  /// Returns the current user's Firebase UID.
  /// Throws an exception if accessed before initialization.
  String get currentUid {
    if (!_isInitialized || _currentUid == null) {
      throw Exception('DataServicesInitializer not initialized or user not authenticated.');
    }
    return _currentUid!;
  }

  /// Initializes all data services. This is the single entry point.
  /// It fetches the Firebase user and uses the UID to initialize all dependent services.
  Future<void> initialize() async {
    if (_isInitialized) {
      AACLogger.info('Data services already initialized. Skipping.');
      return;
    }

    AACLogger.info('🚀 Robust DataServicesInitializer starting...');

    try {
      // 1. Get the authenticated Firebase user. This is the source of truth.
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.uid.isEmpty) {
        _isInitialized = false;
        AACLogger.warning('🚫 User not authenticated. Data services cannot be initialized.');
        throw Exception('Firebase user not authenticated - cannot initialize data services');
      }
      _currentUid = user.uid;
      AACLogger.info('✅ Authenticated user found with Firebase UID: $_currentUid');

      // 2. Initialize UserDataManager with the fetched UID - this is critical
      if (_userDataManager == null) {
        _userDataManager = UserDataManager();
        await _userDataManager!.initializeWithUid(_currentUid!);
        AACLogger.info('✅ UserDataManager initialized.');
      } else {
        AACLogger.info('✅ UserDataManager already initialized.');
      }

      // 3. Initialize other services - continue even if individual services fail
      if (_favoritesService == null) {
        _favoritesService = FavoritesService();
        try {
          await _favoritesService!.initializeWithUid(_currentUid!, _userDataManager!);
          AACLogger.info('✅ FavoritesService initialized.');
        } catch (e) {
          AACLogger.warning('⚠️ FavoritesService initialization failed (app will continue): $e');
          _favoritesService = null; // Clear failed service
        }
      } else {
        AACLogger.info('✅ FavoritesService already initialized.');
      }

      if (_phraseHistoryService == null) {
        _phraseHistoryService = PhraseHistoryService();
        try {
          await _phraseHistoryService!.initializeWithUid(_currentUid!, _userDataManager!);
          AACLogger.info('✅ PhraseHistoryService initialized.');
        } catch (e) {
          AACLogger.warning('⚠️ PhraseHistoryService initialization failed (app will continue): $e');
          _phraseHistoryService = null; // Clear failed service
        }
      } else {
        AACLogger.info('✅ PhraseHistoryService already initialized.');
      }

      if (_customCategoriesService == null) {
        _customCategoriesService = CustomCategoriesService();
        try {
          await _customCategoriesService!.initializeWithUid(_currentUid!, _userDataManager!);
          AACLogger.info('✅ CustomCategoriesService initialized.');
        } catch (e) {
          AACLogger.warning('⚠️ CustomCategoriesService initialization failed (app will continue): $e');
          _customCategoriesService = null; // Clear failed service
        }
      } else {
        AACLogger.info('✅ CustomCategoriesService already initialized.');
      }

      if (_settingsService == null) {
        _settingsService = SettingsService();
        try {
          await _settingsService!.initialize(_userDataManager!);
          AACLogger.info('✅ SettingsService initialized.');
        } catch (e) {
          AACLogger.warning('⚠️ SettingsService initialization failed (app will continue): $e');
          _settingsService = null; // Clear failed service
        }
      } else {
        AACLogger.info('✅ SettingsService already initialized.');
      }

      _isInitialized = true;
      AACLogger.info('🎉 All data services successfully initialized with single source of truth UID.');
      logServiceStatus();

    } catch (e, stacktrace) {
      AACLogger.error('❌❌❌ A critical error occurred during data services initialization: $e', stackTrace: stacktrace);
      _isInitialized = false;
      _currentUid = null;
      // We rethrow to make it clear that the app is in an invalid state.
      rethrow;
    }
  }

  /// Resets all services, typically on logout.
  Future<void> reset() async {
    AACLogger.info('🔄 Resetting all data services...');
    if (!_isInitialized) return;
    
    // Reset custom categories service state properly
    if (_customCategoriesService != null) {
      await _customCategoriesService!.resetServiceState();
      _customCategoriesService!.dispose();
    }
    
    // Dispose other services but DON'T clear their local data
    favoritesService?.dispose();
    
    // Reset service references (but Hive data remains intact)
    _userDataManager = null;
    _favoritesService = null;
    _phraseHistoryService = null;
    _settingsService = null;
    _customCategoriesService = null;
    _isInitialized = false;
    _currentUid = null;
    AACLogger.info('✅ All data services have been reset (Hive data preserved).');
  }

  /// Trigger a sync of all user data from Firebase to local storage
  /// This should be called after successful initialization to ensure
  /// the user's cloud data is available locally
  Future<void> syncUserDataFromCloud() async {
    if (!_isInitialized) {
      AACLogger.warning('Cannot sync data - services not initialized');
      return;
    }

    try {
      AACLogger.info('🔄 Starting sync of user data from Firebase to local storage...');

      // Sync favorites if service is available
      if (hasFavoritesService) {
        try {
          await favoritesService!.syncFromCloud();
          AACLogger.info('✅ Favorites synced from cloud');
        } catch (e) {
          AACLogger.warning('⚠️ Favorites sync failed: $e');
        }
      } else {
        AACLogger.warning('FavoritesService not available for sync');
      }

      // Sync phrase history if service is available
      if (hasPhraseHistoryService) {
        try {
          await phraseHistoryService!.syncFromCloud();
          AACLogger.info('✅ Phrase history synced from cloud');
        } catch (e) {
          AACLogger.warning('⚠️ Phrase history sync failed: $e');
        }
      } else {
        AACLogger.warning('PhraseHistoryService not available for sync');
      }

      // Sync custom categories if service is available
      if (hasCustomCategoriesService) {
        try {
          await customCategoriesService!.syncFromCloud();
          AACLogger.info('✅ Custom categories synced from cloud');
        } catch (e) {
          AACLogger.warning('⚠️ Custom categories sync failed: $e');
        }
      } else {
        AACLogger.warning('CustomCategoriesService not available for sync');
      }

      AACLogger.info('✅ User data sync completed (available services synced)');
    } catch (e) {
      AACLogger.error('❌ Error during sync process: $e');
      // Don't rethrow - sync failure shouldn't break the app
    }
  }

  void logServiceStatus() {
    AACLogger.info('================ Data Services Status ================');
    AACLogger.info('Initializer Status: ${_isInitialized ? "✅ INITIALIZED" : "❌ NOT INITIALIZED"}');
    AACLogger.info('Firebase UID: ${_currentUid ?? "N/A"}');
    if (_isInitialized) {
      AACLogger.info('  - UserDataManager: ${_userDataManager?.isInitialized == true ? "✅" : "❌"}');
      AACLogger.info('  - FavoritesService: ${_favoritesService?.isInitialized == true ? "✅" : "❌"}');
      AACLogger.info('  - PhraseHistoryService: ${_phraseHistoryService?.isInitialized == true ? "✅" : "❌"}');
      AACLogger.info('  - CustomCategoriesService: ${_customCategoriesService?.isInitialized == true ? "✅" : "❌"}');
      AACLogger.info('  - SettingsService: ${_settingsService?.isInitialized == true ? "✅" : "❌"}');
    }
    AACLogger.info('======================================================');
  }
}
