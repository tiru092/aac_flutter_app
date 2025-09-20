import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    if (_isInitialized && _currentUid == uid) {
      AACLogger.info('CustomCategoriesService: Already initialized for UID: $_currentUid', tag: 'CustomCategoriesService');
      return;
    }

    // CRITICAL FIX: Validate UID matches current Firebase user
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid != uid) {
      throw Exception('CustomCategoriesService: UID mismatch! Expected: ${currentUser?.uid}, Got: $uid');
    }

    try {
      AACLogger.info('CustomCategoriesService: Initializing with UID: $uid', tag: 'CustomCategoriesService');
      
      // Reset any previous state
      _customCategories.clear();
      _currentUid = uid;
      _userDataManager = userDataManager;

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

  /// Load custom categories from storage - prioritize Hive first, then sync with Firebase
  Future<void> _loadCustomCategories() async {
    List<Category> hiveCategories = [];
    List<Category> firebaseCategories = [];
    bool hiveDataExists = false;
    
    try {
      // STEP 1: Always load from local Hive storage first (faster, works offline)
      AACLogger.info('CustomCategoriesService: Loading categories from local Hive storage...', tag: 'CustomCategoriesService');
      final localBox = await _userDataManager!.getCustomCategoriesBox();
      final localData = localBox.get(_customCategoriesKey);
      
      if (localData != null && localData is List && localData.isNotEmpty) {
        try {
          hiveCategories = localData.map((data) => Category.fromJson(Map<String, dynamic>.from(data))).toList();
          hiveDataExists = true;
          AACLogger.info('CustomCategoriesService: Found ${hiveCategories.length} categories in local Hive storage.', tag: 'CustomCategoriesService');
        } catch (parseError) {
          AACLogger.error('CustomCategoriesService: Error parsing Hive data (corrupted?): $parseError - Clearing corrupted data', tag: 'CustomCategoriesService');
          // Clear corrupted data
          await localBox.delete(_customCategoriesKey);
          hiveCategories = [];
          hiveDataExists = false;
        }
      } else {
        AACLogger.info('CustomCategoriesService: No local data found in Hive.', tag: 'CustomCategoriesService');
      }
      
      // STEP 2: Try to load from Firebase (for validation/sync)
      try {
        AACLogger.info('CustomCategoriesService: Loading from Firebase for sync validation...', tag: 'CustomCategoriesService');
        firebaseCategories = await SharedResourceService.getUserCustomCategories(_currentUid!);
        AACLogger.info('CustomCategoriesService: Found ${firebaseCategories.length} categories in Firebase.', tag: 'CustomCategoriesService');
      } catch (firebaseError) {
        AACLogger.warning('CustomCategoriesService: Firebase load failed: $firebaseError', tag: 'CustomCategoriesService');
        // Continue with Hive data only
      }
      
      // STEP 3: Determine final data source with clear priority
      if (hiveDataExists && hiveCategories.isNotEmpty) {
        // PRIORITY: Use Hive data (local data has highest priority)
        _customCategories = hiveCategories;
        AACLogger.info('CustomCategoriesService: ✅ Using Hive data (${_customCategories.length} categories) - Local data takes priority', tag: 'CustomCategoriesService');
        
        // Background sync: if Firebase has data, check for any new items
        if (firebaseCategories.isNotEmpty) {
          // Run background sync asynchronously to not block UI
          _performBackgroundSync(firebaseCategories);
        }
      } else if (firebaseCategories.isNotEmpty) {
        // FALLBACK: Use Firebase data if no local data exists
        _customCategories = firebaseCategories;
        await _saveToLocal(); // Cache Firebase data locally
        AACLogger.info('CustomCategoriesService: ✅ Using Firebase data (${_customCategories.length} categories) - No local data, downloading from cloud', tag: 'CustomCategoriesService');
      } else {
        // FALLBACK: No data anywhere, start fresh
        _customCategories = [];
        AACLogger.info('CustomCategoriesService: ✅ Starting fresh - No data found in Hive or Firebase', tag: 'CustomCategoriesService');
      }
      
      // STEP 4: Update UI with loaded data
      _categoriesController.add(_customCategories);
      AACLogger.info('CustomCategoriesService: ✅ Data loading completed - ${_customCategories.length} categories available', tag: 'CustomCategoriesService');
      
    } catch (e, stackTrace) {
      AACLogger.error('CustomCategoriesService: Error loading categories: $e', stackTrace: stackTrace, tag: 'CustomCategoriesService');
      _customCategories = []; // Fallback to empty list
      _categoriesController.add(_customCategories);
    }
  }

  /// Perform background sync to merge any new Firebase data with local Hive data
  /// IMPROVED: Better conflict resolution for timestamp-based updates
  Future<void> _performBackgroundSync(List<Category> firebaseCategories) async {
    try {
      bool hasChanges = false;
      
      // Check if Firebase has any categories not in local storage
      for (final fbCategory in firebaseCategories) {
        final localCategory = _customCategories.firstWhere((local) => local.id == fbCategory.id, 
          orElse: () => Category(name: '', iconPath: '', colorCode: 0));
        
        if (localCategory.name.isEmpty) {
          // New category from Firebase - add it
          _customCategories.add(fbCategory);
          hasChanges = true;
          AACLogger.info('CustomCategoriesService: Background sync - Added new category from Firebase: ${fbCategory.name}', tag: 'CustomCategoriesService');
        } else {
          // IMPROVED: Handle conflicts based on timestamps if available
          final fbDate = fbCategory.dateCreated ?? DateTime.fromMillisecondsSinceEpoch(0);
          final localDate = localCategory.dateCreated ?? DateTime.fromMillisecondsSinceEpoch(0);
          
          if (fbDate.isAfter(localDate)) {
            // Firebase version is newer - update local
            final index = _customCategories.indexWhere((local) => local.id == fbCategory.id);
            if (index != -1) {
              _customCategories[index] = fbCategory;
              hasChanges = true;
              AACLogger.info('CustomCategoriesService: Background sync - Updated category from Firebase (newer): ${fbCategory.name}', tag: 'CustomCategoriesService');
            }
          }
        }
      }
      
      // Check if local storage has categories not in Firebase (sync them up)
      final localOnlyCategories = _customCategories.where((local) => 
        !firebaseCategories.any((fb) => fb.id == local.id)).toList();
      
      if (localOnlyCategories.isNotEmpty) {
        AACLogger.info('CustomCategoriesService: Found ${localOnlyCategories.length} local-only categories (will sync to Firebase)', tag: 'CustomCategoriesService');
        // IMPROVED: Sync local-only categories to Firebase to prevent data loss
        for (final localCategory in localOnlyCategories) {
          try {
            await SharedResourceService.addUserCustomCategory(_currentUid!, localCategory);
            AACLogger.info('CustomCategoriesService: Synced local category to Firebase: ${localCategory.name}', tag: 'CustomCategoriesService');
          } catch (e) {
            AACLogger.warning('CustomCategoriesService: Failed to sync local category to Firebase: ${localCategory.name}, error: $e', tag: 'CustomCategoriesService');
          }
        }
      }
      
      if (hasChanges) {
        await _saveToLocal(); // Save merged data
        _categoriesController.add(_customCategories); // Update UI
        AACLogger.info('CustomCategoriesService: Background sync completed with conflict resolution', tag: 'CustomCategoriesService');
      } else {
        AACLogger.info('CustomCategoriesService: Background sync - no changes needed', tag: 'CustomCategoriesService');
      }
    } catch (e) {
      AACLogger.error('CustomCategoriesService: Background sync failed: $e', tag: 'CustomCategoriesService');
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
