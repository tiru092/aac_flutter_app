import 'dart:async';
import '../models/symbol.dart'; // Category is defined in symbol.dart
import '../utils/aac_logger.dart';
import 'user_data_manager.dart';

/// Service for managing custom categories with local-first Hive storage
/// Simplified architecture: Hive first (fast), no complex sync logic
/// Ensures custom categories persist across app restarts and sessions
class CustomCategoriesService {
  static const String _customCategoriesKey = 'custom_categories';
  
  UserDataManager? _userDataManager;
  String? _currentUid;
  bool _isInitialized = false;
  
  List<Category> _customCategories = [];
  final StreamController<List<Category>> _categoriesController = StreamController<List<Category>>.broadcast();

  /// Stream of custom categories updates
  Stream<List<Category>> get categoriesStream => _categoriesController.stream;
  
  /// Current list of custom categories
  List<Category> get customCategories => List.unmodifiable(_customCategories);
  
  bool get isInitialized => _isInitialized;

  /// Initialize with Firebase UID and UserDataManager
  Future<void> initializeWithUid(String uid, UserDataManager userDataManager) async {
    if (_isInitialized && _currentUid == uid) {
      AACLogger.info('CustomCategoriesService: Already initialized for UID: $_currentUid', tag: 'CustomCategoriesService');
      return;
    }

    try {
      AACLogger.info('CustomCategoriesService: Initializing with UID: $uid', tag: 'CustomCategoriesService');

      // Reset any previous state
      _customCategories.clear();
      _currentUid = uid;
      _userDataManager = userDataManager;

      // Load categories from local storage
      await _loadCustomCategories();

      _isInitialized = true;
      AACLogger.info('CustomCategoriesService: ✅ Initialized successfully for UID: $uid with ${_customCategories.length} categories', tag: 'CustomCategoriesService');
    } catch (e, stacktrace) {
      AACLogger.error('CustomCategoriesService: Initialization failed: $e', stackTrace: stacktrace, tag: 'CustomCategoriesService');
      _customCategories = [];
      _categoriesController.add(_customCategories);
      _isInitialized = true; // Initialize to prevent crashes, but with empty data.
    }
  }

  /// Load custom categories from local Hive storage
  Future<void> _loadCustomCategories() async {
    AACLogger.info('CustomCategoriesService: Loading categories from local storage for UID: $_currentUid', tag: 'CustomCategoriesService');

    try {
      // Load from local Hive storage
      final localBox = await _userDataManager!.getCustomCategoriesBox();
      final localData = localBox.get(_customCategoriesKey);

      if (localData != null && localData is List && localData.isNotEmpty) {
        try {
          _customCategories = localData.map((data) => Category.fromJson(Map<String, dynamic>.from(data))).toList();
          AACLogger.info('CustomCategoriesService: Found ${_customCategories.length} categories in local storage', tag: 'CustomCategoriesService');
        } catch (parseError) {
          AACLogger.error('CustomCategoriesService: Error parsing local data: $parseError - Clearing corrupted data', tag: 'CustomCategoriesService');
          // Clear corrupted data
          await localBox.delete(_customCategoriesKey);
          _customCategories = [];
        }
      } else {
        AACLogger.info('CustomCategoriesService: No local data found, starting fresh', tag: 'CustomCategoriesService');
        _customCategories = [];
      }

      // Update UI with loaded data
      _categoriesController.add(_customCategories);
      AACLogger.info('CustomCategoriesService: ✅ Data loading completed - ${_customCategories.length} categories available', tag: 'CustomCategoriesService');

    } catch (e, stackTrace) {
      AACLogger.error('CustomCategoriesService: Error loading categories: $e', stackTrace: stackTrace, tag: 'CustomCategoriesService');
      _customCategories = []; // Fallback to empty list
      _categoriesController.add(_customCategories);
    }
  }



  /// Add a new custom category with local-first storage
  Future<void> addCustomCategory(Category category) async {
    if (!_isInitialized) {
      AACLogger.warning('CustomCategoriesService not initialized, cannot add category.', tag: 'CustomCategoriesService');
      return;
    }

    try {
      // Avoid duplicates
      if (!_customCategories.any((c) => c.id == category.id)) {
        // Add to local storage and update UI
        _customCategories.add(category);
        await _saveToLocal();
        _categoriesController.add(_customCategories);
        AACLogger.info('CustomCategoriesService: ✅ Added category ${category.name} to local storage', tag: 'CustomCategoriesService');
      }
    } catch (e) {
      AACLogger.error('CustomCategoriesService: Error adding category: $e', tag: 'CustomCategoriesService');
    }
  }

  /// Remove a custom category
  Future<void> removeCustomCategory(String categoryId) async {
    if (!_isInitialized) {
      AACLogger.warning('CustomCategoriesService not initialized, cannot remove category.', tag: 'CustomCategoriesService');
      return;
    }

    try {
      // Remove from local storage and update UI
      _customCategories.removeWhere((c) => c.id == categoryId);
      await _saveToLocal();
      _categoriesController.add(_customCategories);
      AACLogger.info('CustomCategoriesService: ✅ Removed category $categoryId', tag: 'CustomCategoriesService');
    } catch (e) {
      AACLogger.error('CustomCategoriesService: Error removing category: $e', tag: 'CustomCategoriesService');
    }
  }

  /// Clear all custom categories
  Future<void> clearCustomCategories() async {
    if (!_isInitialized) return;

    _customCategories.clear();
    await _saveToLocal();
    _categoriesController.add(_customCategories);
    AACLogger.info('CustomCategoriesService: All custom categories cleared.', tag: 'CustomCategoriesService');
  }

  /// Save to local Hive storage
  Future<void> _saveToLocal() async {
    try {
      final box = await _userDataManager!.getCustomCategoriesBox();
      final dataToSave = _customCategories.map((c) => c.toJson()).toList();
      await box.put(_customCategoriesKey, dataToSave);
      AACLogger.info('CustomCategoriesService: Saved ${_customCategories.length} categories to local storage (key: $_customCategoriesKey)', tag: 'CustomCategoriesService');
    } catch (e) {
      AACLogger.error('CustomCategoriesService: Error saving to local storage: $e', tag: 'CustomCategoriesService');
    }
  }



  /// Dispose the service
  void dispose() {
    _categoriesController.close();
    _isInitialized = false;
    _currentUid = null;
    _userDataManager = null;
    _customCategories.clear();
    AACLogger.info('CustomCategoriesService: Service disposed and state cleared', tag: 'CustomCategoriesService');
  }

  /// Reset service state (useful for sign-out/sign-in cycles)
  Future<void> resetServiceState() async {
    try {
      AACLogger.info('CustomCategoriesService: Resetting service state...', tag: 'CustomCategoriesService');
      _isInitialized = false;
      _currentUid = null;
      _userDataManager = null;
      _customCategories.clear();
      
      // Clear the stream with empty data
      if (!_categoriesController.isClosed) {
        _categoriesController.add([]);
      }
      
      AACLogger.info('CustomCategoriesService: ✅ Service state reset completed', tag: 'CustomCategoriesService');
    } catch (e) {
      AACLogger.error('CustomCategoriesService: Error resetting service state: $e', tag: 'CustomCategoriesService');
    }
  }
}
