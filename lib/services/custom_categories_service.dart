import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/symbol.dart'; // Category is defined in symbol.dart
import '../utils/aac_logger.dart';
import 'user_data_manager.dart';
import 'shared_resource_service.dart';
import 'user_profile_service.dart';

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

  /// Load custom categories from storage - prioritize Hive first, then sync with Firebase
  Future<void> _loadCustomCategories() async {
    bool dataLoadedFromHive = false;
    
    try {
      // STEP 1: Load from local Hive storage first (faster, works offline)
      AACLogger.info('CustomCategoriesService: Loading categories from local Hive storage first...', tag: 'CustomCategoriesService');
      final localBox = await _userDataManager!.getCustomCategoriesBox();
      final localData = localBox.get(_customCategoriesKey);
      
      if (localData != null && localData is List && localData.isNotEmpty) {
        _customCategories = localData.map((data) => Category.fromJson(Map<String, dynamic>.from(data))).toList();
        dataLoadedFromHive = true;
        AACLogger.info('CustomCategoriesService: Loaded ${_customCategories.length} categories from local Hive storage.', tag: 'CustomCategoriesService');
      } else {
        AACLogger.info('CustomCategoriesService: No local data found, will try Firebase...', tag: 'CustomCategoriesService');
      }
      
      // STEP 2: Sync with Firebase in background (for new device or updates)
      try {
        AACLogger.info('CustomCategoriesService: Syncing with Firebase...', tag: 'CustomCategoriesService');
        final firebaseCategories = await SharedResourceService.getUserCustomCategories(_currentUid!);
        
        if (firebaseCategories.isNotEmpty) {
          if (!dataLoadedFromHive) {
            // No local data, use Firebase data
            _customCategories = firebaseCategories;
            await _saveToLocal(); // Cache Firebase data locally
            AACLogger.info('CustomCategoriesService: Loaded ${_customCategories.length} categories from Firebase (new device).', tag: 'CustomCategoriesService');
          } else {
            // We have local data, check if Firebase has newer data
            if (firebaseCategories.length != _customCategories.length) {
              AACLogger.info('CustomCategoriesService: Firebase has different data, merging...', tag: 'CustomCategoriesService');
              // Simple merge: add any Firebase categories not in local storage
              for (final fbCategory in firebaseCategories) {
                if (!_customCategories.any((local) => local.id == fbCategory.id)) {
                  _customCategories.add(fbCategory);
                  AACLogger.info('CustomCategoriesService: Added category from Firebase: ${fbCategory.name}', tag: 'CustomCategoriesService');
                }
              }
              await _saveToLocal(); // Save merged data
            }
          }
        } else if (!dataLoadedFromHive) {
          // No data anywhere, start with empty list
          _customCategories = [];
          AACLogger.info('CustomCategoriesService: No data found in Hive or Firebase, starting fresh.', tag: 'CustomCategoriesService');
        }
      } catch (firebaseError) {
        AACLogger.warning('CustomCategoriesService: Firebase sync failed, using local data only: $firebaseError', tag: 'CustomCategoriesService');
        if (!dataLoadedFromHive) {
          _customCategories = [];
        }
      }
      
    } catch (e) {
      AACLogger.error('CustomCategoriesService: Error during category loading: $e', tag: 'CustomCategoriesService');
      _customCategories = [];
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
        // STEP 1: Add to local storage immediately for instant UI update
        _customCategories.add(category);
        await _saveToLocal();
        _categoriesController.add(_customCategories);
        AACLogger.info('CustomCategoriesService: Added category ${category.name} to local storage', tag: 'CustomCategoriesService');
        
        // STEP 2: Save to Firebase in background
        try {
          final createdCategory = await SharedResourceService.addUserCustomCategory(_currentUid!, category);
          if (createdCategory != null) {
            // Update local category with any server-side changes (like updated timestamps)
            final index = _customCategories.indexWhere((c) => c.id == category.id);
            if (index != -1) {
              _customCategories[index] = createdCategory;
              await _saveToLocal();
            }
            AACLogger.info('CustomCategoriesService: Successfully synced category ${createdCategory.name} to Firebase', tag: 'CustomCategoriesService');
          }
        } catch (firebaseError) {
          AACLogger.warning('CustomCategoriesService: Failed to sync category to Firebase, keeping local copy: $firebaseError', tag: 'CustomCategoriesService');
          // Category is still saved locally, so user can use it
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
      // STEP 1: Remove from local storage immediately for instant UI update
      _customCategories.removeWhere((c) => c.id == categoryId);
      await _saveToLocal();
      _categoriesController.add(_customCategories);
      AACLogger.info('CustomCategoriesService: Removed category $categoryId from local storage', tag: 'CustomCategoriesService');
      
      // STEP 2: Remove from Firebase in background
      try {
        await SharedResourceService.deleteUserCustomCategory(_currentUid!, categoryId);
        AACLogger.info('CustomCategoriesService: Successfully removed category $categoryId from Firebase', tag: 'CustomCategoriesService');
      } catch (firebaseError) {
        AACLogger.warning('CustomCategoriesService: Failed to remove category from Firebase: $firebaseError', tag: 'CustomCategoriesService');
        // Category is still removed locally, which is what user sees
      }
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
