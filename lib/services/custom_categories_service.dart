import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/symbol.dart'; // Category is defined in symbol.dart
import '../utils/aac_logger.dart';
import 'user_data_manager.dart';
import 'shared_resource_service.dart';

/// Service for managing custom categories with Firebase UID isolation
/// Uses the correct Firebase structure: user_custom_symbols/{uid}/custom_categories
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
    if (_isInitialized) return;

    try {
      AACLogger.info('CustomCategoriesService: Initializing with UID: $uid', tag: 'CustomCategoriesService');
      _currentUid = uid;
      _userDataManager = userDataManager;

      await _loadCustomCategories();

      _isInitialized = true;
      AACLogger.info('CustomCategoriesService: Initialized successfully for UID: $uid', tag: 'CustomCategoriesService');
    } catch (e, stacktrace) {
      AACLogger.error('CustomCategoriesService: Initialization failed: $e', stackTrace: stacktrace, tag: 'CustomCategoriesService');
      _customCategories = [];
      _isInitialized = true; // Initialize to prevent crashes, but with empty data.
    }
  }

  /// Load custom categories from storage
  Future<void> _loadCustomCategories() async {
    try {
      // Load directly from SharedResourceService which uses the correct Firebase structure
      AACLogger.info('CustomCategoriesService: Loading categories from user_custom_symbols/{uid}/custom_categories', tag: 'CustomCategoriesService');
      _customCategories = await SharedResourceService.getUserCustomCategories(_currentUid!);
      
      // Save to local storage for offline access
      await _saveToLocal();
      AACLogger.info('CustomCategoriesService: Loaded ${_customCategories.length} categories from Firebase and cached locally.', tag: 'CustomCategoriesService');
      
    } catch (e) {
      AACLogger.error('CustomCategoriesService: Error loading from Firebase, trying local storage: $e', tag: 'CustomCategoriesService');
      
      // Fallback to local storage if Firebase fails
      try {
        final localBox = await _userDataManager!.getCustomCategoriesBox();
        final localData = localBox.get(_customCategoriesKey);
        if (localData != null && localData is List) {
          _customCategories = localData.map((data) => Category.fromJson(Map<String, dynamic>.from(data))).toList();
          AACLogger.info('CustomCategoriesService: Loaded ${_customCategories.length} categories from local Hive fallback.', tag: 'CustomCategoriesService');
        }
      } catch (localError) {
        AACLogger.error('CustomCategoriesService: Failed to load from local storage: $localError', tag: 'CustomCategoriesService');
        _customCategories = [];
      }
    } finally {
      _categoriesController.add(_customCategories);
    }
  }

  /// Add a new custom category
  Future<void> addCustomCategory(Category category) async {
    if (!_isInitialized) {
      AACLogger.warning('CustomCategoriesService not initialized, cannot add category.', tag: 'CustomCategoriesService');
      return;
    }
    
    try {
      // Avoid duplicates
      if (!_customCategories.any((c) => c.id == category.id)) {
        // Use SharedResourceService to add to correct Firebase structure
        final createdCategory = await SharedResourceService.addUserCustomCategory(_currentUid!, category);
        
        if (createdCategory != null) {
          _customCategories.add(createdCategory);
          await _saveCustomCategories();
          AACLogger.info('CustomCategoriesService: Added category ${createdCategory.name} with ID: ${createdCategory.id}', tag: 'CustomCategoriesService');
        } else {
          AACLogger.error('CustomCategoriesService: Failed to create category ${category.name}', tag: 'CustomCategoriesService');
        }
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
      // Remove from Firebase first
      await SharedResourceService.deleteUserCustomCategory(_currentUid!, categoryId);
      
      // Remove from local list
      _customCategories.removeWhere((c) => c.id == categoryId);
      await _saveCustomCategories();
      AACLogger.info('CustomCategoriesService: Removed category $categoryId', tag: 'CustomCategoriesService');
    } catch (e) {
      AACLogger.error('CustomCategoriesService: Error removing category: $e', tag: 'CustomCategoriesService');
    }
  }

  /// Update a custom category
  Future<void> updateCustomCategory(Category updatedCategory) async {
    if (!_isInitialized) {
      AACLogger.warning('CustomCategoriesService not initialized, cannot update category.', tag: 'CustomCategoriesService');
      return;
    }
    
    try {
      final index = _customCategories.indexWhere((c) => c.id == updatedCategory.id);
      if (index != -1) {
        // Update in Firebase first
        final firebaseUpdatedCategory = await SharedResourceService.updateUserCustomCategory(_currentUid!, updatedCategory);
        
        if (firebaseUpdatedCategory != null) {
          _customCategories[index] = firebaseUpdatedCategory;
          await _saveCustomCategories();
          AACLogger.info('CustomCategoriesService: Updated category ${updatedCategory.name}', tag: 'CustomCategoriesService');
        } else {
          AACLogger.error('CustomCategoriesService: Failed to update category ${updatedCategory.name} in Firebase', tag: 'CustomCategoriesService');
        }
      }
    } catch (e) {
      AACLogger.error('CustomCategoriesService: Error updating category: $e', tag: 'CustomCategoriesService');
    }
  }

  /// Clear all custom categories
  Future<void> clearCustomCategories() async {
    if (!_isInitialized) return;
    
    _customCategories.clear();
    await _saveCustomCategories();
    AACLogger.info('CustomCategoriesService: All custom categories cleared.', tag: 'CustomCategoriesService');
  }

  /// Save custom categories to both local and cloud storage
  Future<void> _saveCustomCategories() async {
    _categoriesController.add(_customCategories);
    await _saveToLocal();
    // Note: Firebase saving is handled by SharedResourceService in add/update/delete methods
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

  /// Sync from cloud to local (useful after changes made elsewhere)
  Future<void> syncFromCloud() async {
    if (!_isInitialized) return;
    
    try {
      await _loadCustomCategories();
      AACLogger.info('CustomCategoriesService: Synced from cloud.', tag: 'CustomCategoriesService');
    } catch (e) {
      AACLogger.error('CustomCategoriesService: Error syncing from cloud: $e', tag: 'CustomCategoriesService');
    }
  }

  /// Dispose the service
  void dispose() {
    _categoriesController.close();
    _isInitialized = false;
  }
}
