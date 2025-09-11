import '../utils/aac_logger.dart';
import 'user_data_manager.dart';
import 'favorites_service.dart';
import 'phrase_history_service.dart';

class DataServicesInitializer {
  bool _isInitialized = false;
  UserDataManager? _userDataManager;
  FavoritesService? _favoritesService;
  PhraseHistoryService? _phraseHistoryService;

  /// Initialize all data services with Firebase UID as single source of truth
  Future<void> initialize() async {
    if (_isInitialized) {
      AACLogger.info('Data services already initialized');
      return;
    }

    try {
      AACLogger.info('🔄 Starting data services initialization with Firebase UID...');

      // 1. Initialize UserDataManager first (single source of truth)
      _userDataManager = UserDataManager();
      await _userDataManager!.initialize();
      AACLogger.info('✅ UserDataManager initialized with Firebase UID support');

      // 2. Initialize FavoritesService with Firebase UID support
      _favoritesService = FavoritesService();
      await _favoritesService!.initialize();
      AACLogger.info('✅ FavoritesService initialized with Firebase UID isolation');

      // 3. Initialize PhraseHistoryService with Firebase UID support
      _phraseHistoryService = PhraseHistoryService();
      await _phraseHistoryService!.initialize();
      AACLogger.info('✅ PhraseHistoryService initialized with Firebase UID isolation');

      // 4. Initialize custom categories with Firebase UID support
      await _initializeCustomCategories();
      AACLogger.info('✅ Custom categories initialized with Firebase UID isolation');

      _isInitialized = true;
      AACLogger.info('🎉 All data services successfully initialized with Firebase UID single source of truth');
    } catch (e) {
      AACLogger.error('❌ Data services initialization failed: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  /// Initialize custom categories with Firebase UID support
  Future<void> _initializeCustomCategories() async {
    try {
      if (_userDataManager?.isAuthenticated != true) {
        AACLogger.warning('User not authenticated, skipping custom categories initialization');
        return;
      }

      // Get Firebase UID-based custom categories
      final customCategoriesData = await _userDataManager!.getCloudData('custom_categories');
      
      if (customCategoriesData != null) {
        AACLogger.info('Loaded ${customCategoriesData.length} custom categories from Firebase UID storage');
        
        // Save to local Hive storage with Firebase UID isolation
        final customCategoriesBox = await _userDataManager!.getCustomCategoriesBox();
        await customCategoriesBox.put('categories', customCategoriesData);
        
        AACLogger.info('Custom categories synced to local storage with Firebase UID');
      } else {
        AACLogger.info('No custom categories found for current Firebase UID');
      }

    } catch (e) {
      AACLogger.error('Error initializing custom categories with Firebase UID: $e');
      // Don't rethrow - custom categories failure shouldn't break app initialization
    }
  }

  /// Add custom category with Firebase UID isolation
  Future<void> addCustomCategory(Map<String, dynamic> categoryData) async {
    try {
      if (_userDataManager?.isAuthenticated != true) {
        throw Exception('User must be authenticated to add custom categories');
      }

      // Get current categories from Firebase UID storage
      List<dynamic> currentCategories = await _userDataManager!.getCloudData('custom_categories') ?? [];
      
      // Add new category
      currentCategories.add(categoryData);
      
      // Save back to Firebase UID storage
      await _userDataManager!.setCloudData('custom_categories', currentCategories);
      
      // Update local storage
      final customCategoriesBox = await _userDataManager!.getCustomCategoriesBox();
      await customCategoriesBox.put('categories', currentCategories);
      
      AACLogger.info('Custom category added with Firebase UID isolation');
      
    } catch (e) {
      AACLogger.error('Failed to add custom category with Firebase UID: $e');
      rethrow;
    }
  }

  /// Get custom categories for current Firebase UID
  Future<List<dynamic>> getCustomCategories() async {
    try {
      if (_userDataManager?.isAuthenticated != true) {
        return [];
      }

      // Try cloud data first
      final cloudData = await _userDataManager!.getCloudData('custom_categories');
      if (cloudData != null) {
        return cloudData;
      }

      // Fall back to local storage
      final customCategoriesBox = await _userDataManager!.getCustomCategoriesBox();
      return customCategoriesBox.get('categories', defaultValue: []);
      
    } catch (e) {
      AACLogger.error('Failed to get custom categories for Firebase UID: $e');
      return [];
    }
  }

  /// Delete custom category with Firebase UID isolation
  Future<void> deleteCustomCategory(String categoryId) async {
    try {
      if (_userDataManager?.isAuthenticated != true) {
        throw Exception('User must be authenticated to delete custom categories');
      }

      // Get current categories
      List<dynamic> currentCategories = await _userDataManager!.getCloudData('custom_categories') ?? [];
      
      // Remove category
      currentCategories.removeWhere((category) => category['id'] == categoryId);
      
      // Save back to Firebase UID storage
      await _userDataManager!.setCloudData('custom_categories', currentCategories);
      
      // Update local storage
      final customCategoriesBox = await _userDataManager!.getCustomCategoriesBox();
      await customCategoriesBox.put('categories', currentCategories);
      
      AACLogger.info('Custom category deleted with Firebase UID isolation');
      
    } catch (e) {
      AACLogger.error('Failed to delete custom category with Firebase UID: $e');
      rethrow;
    }
  }

  /// Log status of all services for debugging
  void logServiceStatus() {
    AACLogger.info('=== Data Services Status (Firebase UID Integration) ===');
    AACLogger.info('Initialized: $_isInitialized');
    if (_isInitialized) {
      AACLogger.info('UserDataManager: ${_userDataManager?.isAuthenticated == true ? "✅ Active with Firebase UID" : "⚠️ Not authenticated"}');
      AACLogger.info('FavoritesService: ${_favoritesService != null ? "✅ Active with Firebase UID isolation" : "❌ Not initialized"}');
      AACLogger.info('PhraseHistoryService: ${_phraseHistoryService != null ? "✅ Active with Firebase UID isolation" : "❌ Not initialized"}');
      AACLogger.info('Custom Categories: ✅ Firebase UID-based storage ready');
    }
    AACLogger.info('=== End Status ===');
  }
}
