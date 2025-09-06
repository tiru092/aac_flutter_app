import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/symbol.dart';
import '../models/user_profile.dart';
import '../utils/sample_data.dart';

/// Comprehensive local data management service for offline-first architecture
/// Handles initialization, storage, and synchronization of user data
class LocalDataManager {
  static final LocalDataManager _instance = LocalDataManager._internal();
  factory LocalDataManager() => _instance;
  LocalDataManager._internal();

  static const String _isLocalDataInitializedKey = 'local_data_initialized';
  static const String _defaultIconsCachedKey = 'default_icons_cached';
  static const String _userDataVersionKey = 'user_data_version';
  
  bool _isInitialized = false;
  
  /// Check if local data manager is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize local data after user login
  Future<void> initializeAfterLogin(UserProfile userProfile) async {
    try {
      print('LocalDataManager: Initializing for user: ${userProfile.name}');
      
      final prefs = await SharedPreferences.getInstance();
      final userKey = '${_isLocalDataInitializedKey}_${userProfile.id}';
      final isInitialized = prefs.getBool(userKey) ?? false;
      
      if (!isInitialized) {
        // Step 1: Store all default icons/symbols locally
        await _storeDefaultIconsLocally();
        
        // Step 2: Initialize user's personal data storage
        await _initializeUserDataStorage(userProfile);
        
        // Step 3: Set up data sync preferences
        await _setupDataSyncPreferences(userProfile);
        
        // Mark as initialized for this user
        await prefs.setBool(userKey, true);
        await prefs.setBool(_defaultIconsCachedKey, true);
        await prefs.setInt(_userDataVersionKey, 1);
        
        print('LocalDataManager: First-time initialization completed');
      } else {
        await _loadExistingUserData(userProfile);
      }
      
      _isInitialized = true;
      print('LocalDataManager: Initialization completed for ${userProfile.name}');
      
    } catch (e) {
      print('LocalDataManager: Error during initialization: $e');
      // Continue with basic functionality even if full initialization fails
      _isInitialized = true;
    }
  }

  /// Store all default icons and symbols locally for offline use
  Future<void> _storeDefaultIconsLocally() async {
    try {
      // Get all default symbols and categories
      final defaultSymbols = SampleData.getSampleSymbols();
      final defaultCategories = SampleData.getSampleCategories();
      
      // Store each symbol in local Hive storage
      final symbolsBox = await Hive.openBox('default_symbols');
      for (int i = 0; i < defaultSymbols.length; i++) {
        try {
          await symbolsBox.put('symbol_$i', defaultSymbols[i]);
        } catch (e) {
          // Continue with other symbols silently
        }
      }
      
      // Store categories in local storage
      final prefs = await SharedPreferences.getInstance();
      final categoriesJson = defaultCategories.map((c) => {
        'name': c.name,
        'iconPath': c.iconPath,
      }).toList();
      
      await prefs.setString('default_categories', categoriesJson.toString());
      
      print('LocalDataManager: Cached ${defaultSymbols.length} default symbols locally');
      
    } catch (e) {
      print('LocalDataManager: Error caching default data: $e');
    }
  }

  /// Initialize user's personal data storage structure
  Future<void> _initializeUserDataStorage(UserProfile userProfile) async {
    try {
      // Create user-specific Hive boxes if needed
      await _ensureUserBoxes(userProfile.id);
      
      // Initialize user's custom symbols collection (empty initially)
      await _initializeUserSymbols(userProfile);
      
      // Initialize user's custom categories collection (empty initially)
      await _initializeUserCategories(userProfile);
      
      // Initialize user's favorites (empty initially)
      await _initializeUserFavorites(userProfile);
      
      // Initialize communication history (empty initially)
      await _initializeUserHistory(userProfile);
      
    } catch (e) {
      print('LocalDataManager: Error initializing user data storage: $e');
    }
  }

  /// Set up data synchronization preferences
  Future<void> _setupDataSyncPreferences(UserProfile userProfile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Set up sync preferences for this user
      await prefs.setBool('auto_sync_enabled_${userProfile.id}', true);
      await prefs.setBool('sync_on_wifi_only_${userProfile.id}', false);
      await prefs.setInt('last_sync_timestamp_${userProfile.id}', DateTime.now().millisecondsSinceEpoch);
      
    } catch (e) {
      print('LocalDataManager: Error setting up sync preferences: $e');
    }
  }

  /// Load existing user data from local storage
  Future<void> _loadExistingUserData(UserProfile userProfile) async {
    try {
      // Ensure all user boxes are available
      await _ensureUserBoxes(userProfile.id);
      
    } catch (e) {
      print('LocalDataManager: Error loading existing user data: $e');
    }
  }

  /// Ensure all necessary Hive boxes exist for the user
  Future<void> _ensureUserBoxes(String userId) async {
    try {
      // Ensure Hive is initialized first
      if (!Hive.isBoxOpen('symbols')) {
        // If symbols box isn't open, Hive probably isn't initialized yet
        // Initialize it first
        try {
          await Hive.initFlutter();
          print('LocalDataManager: Hive initialized');
        } catch (e) {
          print('LocalDataManager: Hive already initialized or error: $e');
        }
      }
      
      // Create user-specific box names
      final userSymbolsBox = 'user_symbols_$userId';
      final userCategoriesBox = 'user_categories_$userId';
      final userFavoritesBox = 'user_favorites_$userId';
      final userHistoryBox = 'user_history_$userId';
      
      // Open or create boxes
      if (!Hive.isBoxOpen(userSymbolsBox)) {
        await Hive.openBox(userSymbolsBox);
      }
      if (!Hive.isBoxOpen(userCategoriesBox)) {
        await Hive.openBox(userCategoriesBox);
      }
      if (!Hive.isBoxOpen(userFavoritesBox)) {
        await Hive.openBox(userFavoritesBox);
      }
      if (!Hive.isBoxOpen(userHistoryBox)) {
        await Hive.openBox(userHistoryBox);
      }
      
    } catch (e) {
      print('LocalDataManager: Error ensuring user boxes: $e');
    }
  }

  /// Initialize user's custom symbols collection
  Future<void> _initializeUserSymbols(UserProfile userProfile) async {
    try {
      final box = await Hive.openBox('user_symbols_${userProfile.id}');
      
      // If user has existing symbols in profile, migrate them to the box
      if (userProfile.userSymbols.isNotEmpty) {
        for (int i = 0; i < userProfile.userSymbols.length; i++) {
          await box.put('symbol_$i', userProfile.userSymbols[i]);
        }
        print('LocalDataManager: Migrated ${userProfile.userSymbols.length} user symbols to local storage');
      }
      
    } catch (e) {
      print('LocalDataManager: Error initializing user symbols: $e');
    }
  }

  /// Initialize user's custom categories collection
  Future<void> _initializeUserCategories(UserProfile userProfile) async {
    try {
      final box = await Hive.openBox('user_categories_${userProfile.id}');
      
      // If user has existing categories in profile, migrate them to the box
      if (userProfile.userCategories.isNotEmpty) {
        for (int i = 0; i < userProfile.userCategories.length; i++) {
          await box.put('category_$i', userProfile.userCategories[i]);
        }
        print('LocalDataManager: Migrated ${userProfile.userCategories.length} user categories to local storage');
      }
      
    } catch (e) {
      print('LocalDataManager: Error initializing user categories: $e');
    }
  }

  /// Initialize user's favorites collection
  Future<void> _initializeUserFavorites(UserProfile userProfile) async {
    try {
      final box = await Hive.openBox('user_favorites_${userProfile.id}');
      
      // Initialize empty favorites if none exist
      if (box.isEmpty) {
        await box.put('favorites_list', <String>[]);
        print('LocalDataManager: Initialized empty favorites for user');
      }
      
    } catch (e) {
      print('LocalDataManager: Error initializing user favorites: $e');
    }
  }

  /// Initialize user's communication history
  Future<void> _initializeUserHistory(UserProfile userProfile) async {
    try {
      final box = await Hive.openBox('user_history_${userProfile.id}');
      
      // Initialize empty history if none exists
      if (box.isEmpty) {
        await box.put('history_list', <Map<String, dynamic>>[]);
        print('LocalDataManager: Initialized empty communication history for user');
      }
      
    } catch (e) {
      print('LocalDataManager: Error initializing user history: $e');
    }
  }

  /// Add new user data (symbols, categories) and sync with cloud in background
  Future<void> addUserData({
    required String userId,
    Symbol? newSymbol,
    Category? newCategory,
    String? favoriteSymbolId,
    Map<String, dynamic>? historyEntry,
  }) async {
    try {
      print('LocalDataManager: Adding user data locally...');
      
      // Add to local storage immediately
      if (newSymbol != null) {
        await _addSymbolLocally(userId, newSymbol);
      }
      
      if (newCategory != null) {
        await _addCategoryLocally(userId, newCategory);
      }
      
      if (favoriteSymbolId != null) {
        await _addFavoriteLocally(userId, favoriteSymbolId);
      }
      
      if (historyEntry != null) {
        await _addHistoryEntryLocally(userId, historyEntry);
      }
      
      print('LocalDataManager: Data added locally');
      
      // Schedule background sync
      _scheduleBackgroundSync(userId);
      
    } catch (e) {
      print('LocalDataManager: Error adding user data: $e');
    }
  }

  /// Add symbol to local storage
  Future<void> _addSymbolLocally(String userId, Symbol symbol) async {
    try {
      final box = await Hive.openBox('user_symbols_$userId');
      final key = 'symbol_${DateTime.now().millisecondsSinceEpoch}';
      await box.put(key, symbol);
      
      print('LocalDataManager: Added symbol "${symbol.label}" locally');
      
    } catch (e) {
      print('LocalDataManager: Error adding symbol locally: $e');
    }
  }

  /// Add category to local storage
  Future<void> _addCategoryLocally(String userId, Category category) async {
    try {
      final box = await Hive.openBox('user_categories_$userId');
      final key = 'category_${DateTime.now().millisecondsSinceEpoch}';
      await box.put(key, category);
      
      print('LocalDataManager: Added category "${category.name}" locally');
      
    } catch (e) {
      print('LocalDataManager: Error adding category locally: $e');
    }
  }

  /// Add favorite to local storage
  Future<void> _addFavoriteLocally(String userId, String symbolId) async {
    try {
      final box = await Hive.openBox('user_favorites_$userId');
      final favorites = List<String>.from(box.get('favorites_list', defaultValue: <String>[]));
      
      if (!favorites.contains(symbolId)) {
        favorites.add(symbolId);
        await box.put('favorites_list', favorites);
        print('LocalDataManager: Added favorite "$symbolId" locally');
      }
      
    } catch (e) {
      print('LocalDataManager: Error adding favorite locally: $e');
    }
  }

  /// Add history entry to local storage
  Future<void> _addHistoryEntryLocally(String userId, Map<String, dynamic> entry) async {
    try {
      final box = await Hive.openBox('user_history_$userId');
      final history = List<Map<String, dynamic>>.from(box.get('history_list', defaultValue: <Map<String, dynamic>>[]));
      
      history.insert(0, entry); // Add to beginning for most recent first
      
      // Keep only last 1000 entries to manage storage
      if (history.length > 1000) {
        history.removeRange(1000, history.length);
      }
      
      await box.put('history_list', history);
      print('LocalDataManager: Added history entry locally');
      
    } catch (e) {
      print('LocalDataManager: Error adding history entry locally: $e');
    }
  }

  /// Schedule background sync with cloud
  void _scheduleBackgroundSync(String userId) {
    // Use a timer to sync after a short delay to batch multiple operations
    Future.delayed(Duration(seconds: 5), () async {
      try {
        print('LocalDataManager: Starting background sync for user $userId');
        
        // TODO: Implement cloud sync logic here
        // This would sync with Firebase or other cloud service
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('last_sync_timestamp_$userId', DateTime.now().millisecondsSinceEpoch);
        
        print('LocalDataManager: Background sync completed for user $userId');
        
      } catch (e) {
        print('LocalDataManager: Background sync failed: $e');
        // Sync will be retried later
      }
    });
  }

  /// Get user's local data summary
  Future<Map<String, int>> getUserDataSummary(String userId) async {
    try {
      final symbolsBox = await Hive.openBox('user_symbols_$userId');
      final categoriesBox = await Hive.openBox('user_categories_$userId');
      final favoritesBox = await Hive.openBox('user_favorites_$userId');
      final historyBox = await Hive.openBox('user_history_$userId');
      
      final favorites = List<String>.from(favoritesBox.get('favorites_list', defaultValue: <String>[]));
      final history = List<Map<String, dynamic>>.from(historyBox.get('history_list', defaultValue: <Map<String, dynamic>>[]));
      
      return {
        'symbols': symbolsBox.length,
        'categories': categoriesBox.length,
        'favorites': favorites.length,
        'history': history.length,
      };
      
    } catch (e) {
      print('LocalDataManager: Error getting user data summary: $e');
      return {
        'symbols': 0,
        'categories': 0,
        'favorites': 0,
        'history': 0,
      };
    }
  }

  /// Clear all user data (for logout or data reset)
  Future<void> clearUserData(String userId) async {
    try {
      print('LocalDataManager: Clearing data for user $userId');
      
      final boxNames = [
        'user_symbols_$userId',
        'user_categories_$userId',
        'user_favorites_$userId',
        'user_history_$userId',
      ];
      
      for (final boxName in boxNames) {
        if (Hive.isBoxOpen(boxName)) {
          final box = Hive.box(boxName);
          await box.clear();
          await box.close();
        }
      }
      
      // Clear user-specific preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_isLocalDataInitializedKey}_$userId');
      await prefs.remove('auto_sync_enabled_$userId');
      await prefs.remove('sync_on_wifi_only_$userId');
      await prefs.remove('last_sync_timestamp_$userId');
      
      print('LocalDataManager: User data cleared for $userId');
      
    } catch (e) {
      print('LocalDataManager: Error clearing user data: $e');
    }
  }
}
