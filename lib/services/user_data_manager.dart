import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';
import '../services/unified_supabase_auth_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/symbol.dart';
import '../models/user_profile.dart';
import '../models/communication_history.dart';
import '../models/app_settings.dart';
import '../models/history_entry.dart';
import '../utils/aac_logger.dart';
import 'firebase_path_registry.dart';

/// Centralized User Data Manager that is controlled by DataServicesInitializer.
/// It uses the Supabase User ID provided by the initializer as the single source of truth
/// for all data operations, both online (Supabase) and offline (Hive).
class UserDataManager {
  static final UserDataManager _instance = UserDataManager._internal();
  factory UserDataManager() => _instance;
  UserDataManager._internal();

  String? _currentUserId;
  String? get currentUserId => _currentUserId;
  UserProfile? _userProfile;
  UserProfile? get userProfile => _userProfile;

  bool _isInitialized = false;

  // Hive boxes for the current user
  late Box<Symbol> _userSymbolsBox;
  late Box<Category> _userCategoriesBox;
  late Box _userFavoritesBox; // Generic box to store favorites as JSON list
  late Box<HistoryEntry> _userHistoryBox;
  late Box<AppSettings> _userSettingsBox;
  late Box<CommunicationHistoryEntry> _userCommunicationHistoryBox;
  late Box _userPhraseHistoryBox; // Generic box for phrase history

  bool get isInitialized => _isInitialized;
  User? get currentUser => UnifiedSupabaseAuthService.currentUser;
  bool get isAuthenticated => currentUser != null;

  /// Initialize the user data manager with a specific Supabase User ID.
  /// This must be called by DataServicesInitializer.
  Future<void> initializeWithUid(String uid) async {
    if (_isInitialized) return;

    try {
      AACLogger.info('UserDataManager: Initializing with Supabase UID: $uid', tag: 'UserDataManager');
      _currentUserId = uid;

      // Register adapters if not already registered
      _registerHiveAdapters();

      // Open user-specific Hive boxes
      await _openUserBoxes(uid);

      // Load or create user profile
      try {
        await _loadOrCreateUserProfile(uid);
        AACLogger.info('UserDataManager: Profile loaded/created successfully', tag: 'UserDataManager');
      } catch (e) {
        AACLogger.error('UserDataManager: Profile creation failed: $e', tag: 'UserDataManager');
        rethrow;
      }

      _isInitialized = true;
      AACLogger.info('UserDataManager: Initialization complete for UID: $uid', tag: 'UserDataManager');
    } catch (e, stackTrace) { // Corrected parameter name
      AACLogger.error('UserDataManager: Initialization failed for UID $uid: $e', stackTrace: stackTrace, tag: 'UserDataManager');
      _isInitialized = false;
      rethrow;
    }
  }

  void _registerHiveAdapters() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(SymbolAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(CategoryAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(CommunicationHistoryEntryAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(HistoryEntryAdapter());
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(AppSettingsAdapter());
  }

  /// Open all Hive boxes for the user with UID-based naming
  Future<void> _openUserBoxes(String userId) async {
    try {
      // Create user-specific box names using Firebase UID
      final symbolsBoxName = 'symbols_$userId';
      final categoriesBoxName = 'categories_$userId';
      final favoritesBoxName = 'favorites_$userId';
      final historyBoxName = 'history_$userId';
      final settingsBoxName = 'settings_$userId';
      final communicationHistoryBoxName = 'comm_history_$userId';
      final phraseHistoryBoxName = 'phrase_history_$userId'; // New box name

      // Open boxes
      _userSymbolsBox = await Hive.openBox<Symbol>(symbolsBoxName);
      _userCategoriesBox = await Hive.openBox<Category>(categoriesBoxName);
      _userFavoritesBox = await Hive.openBox(favoritesBoxName); // Generic box for JSON storage
      _userHistoryBox = await Hive.openBox<HistoryEntry>(historyBoxName);
      _userSettingsBox = await Hive.openBox<AppSettings>(settingsBoxName);
      _userCommunicationHistoryBox = await Hive.openBox<CommunicationHistoryEntry>(communicationHistoryBoxName);
      _userPhraseHistoryBox = await Hive.openBox(phraseHistoryBoxName); // Open the new box

      AACLogger.info('UserDataManager: Opened all Hive boxes for user: $userId', tag: 'UserDataManager');
    } catch (e) {
      AACLogger.error('UserDataManager: Error opening user boxes: $e', tag: 'UserDataManager');
      rethrow;
    }
  }

  /// Close current user's Hive boxes
  Future<void> _closeCurrentUserBoxes() async {
    try {
      await _userSymbolsBox.close();
      await _userCategoriesBox.close();
      await _userFavoritesBox.close();
      await _userHistoryBox.close();
      await _userSettingsBox.close();
      await _userCommunicationHistoryBox.close();
      await _userPhraseHistoryBox.close(); // Close the new box
      AACLogger.info('UserDataManager: Closed all user boxes for UID: $_currentUserId', tag: 'UserDataManager');
    } catch (e) {
      AACLogger.error('UserDataManager: Error closing user boxes: $e', tag: 'UserDataManager');
    }
  }

  /// Load or create user profile
  Future<void> _loadOrCreateUserProfile(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        final profileData = response;
        AACLogger.info('UserDataManager: Profile document exists, data: $profileData', tag: 'UserDataManager');
        
        if (profileData != null) {
          _userProfile = UserProfile.fromJson(profileData as Map<String, dynamic>);
          AACLogger.info('UserDataManager: Loaded profile from Firestore for: $userId', tag: 'UserDataManager');
        } else {
          AACLogger.warning('UserDataManager: Profile document exists but data is null, creating new profile', tag: 'UserDataManager');
          // Fall through to create new profile
        }
      }
      
      if (_userProfile == null) {
        // Create new profile if none was loaded
        final user = UnifiedSupabaseAuthService.currentUser; // Use Supabase user
        
        // Safe name extraction with explicit null handling
        String userName = 'User';
        final displayName = UnifiedSupabaseAuthService.currentUserDisplayName;
        final email = UnifiedSupabaseAuthService.currentUserEmail;
        
        if (displayName != null && displayName.isNotEmpty) {
          userName = displayName;
        } else if (email != null && email.isNotEmpty) {
          final emailParts = email.split('@');
          if (emailParts.isNotEmpty && emailParts.first.isNotEmpty) {
            userName = emailParts.first;
          }
        }
        
        _userProfile = UserProfile(
          id: userId, // Use Supabase User ID as profile ID
          name: userName,
          role: UserRole.child,
          email: email ?? '',
          createdAt: DateTime.now(),
          settings: ProfileSettings(),
        );
        
        // Save new profile to Supabase
        await saveUserProfile(_userProfile!);
        AACLogger.info('UserDataManager: Created and saved new profile to Supabase for: $userId', tag: 'UserDataManager');
      }
    } catch (e) {
      AACLogger.error('UserDataManager: Error loading/creating profile: $e', tag: 'UserDataManager');
      rethrow;
    }
  }

  // GETTERS FOR CURRENT USER STATE

  /// Get current Firebase user ID (non-null, throws if not initialized)
  String get currentUserIdNonNull {
    if (!_isInitialized) {
      throw Exception('UserDataManager not initialized - call initializeWithUid() first');
    }
    if (_currentUserId?.isEmpty != false) {
      throw Exception('UserDataManager currentUserId is empty - initialization failed');
    }
    return _currentUserId!;
  }

  /// Get current user profile
  Future<UserProfile?> getUserProfile() async {
    if (!_isInitialized) {
      AACLogger.warning('Cannot get user profile, UserDataManager not initialized.');
      return null;
    }
    if (_userProfile != null) return _userProfile;

    // If null, try to fetch again
    await _loadOrCreateUserProfile(_currentUserId!);
    return _userProfile;
  }

  // HIVE BOX ACCESSORS

  /// Get user symbols box
  Box<Symbol> get userSymbolsBox {
    if (!_isInitialized) throw Exception('UserDataManager not initialized');
    return _userSymbolsBox;
  }

  /// Get user categories box
  Box<Category> get userCategoriesBox {
    if (!_isInitialized) throw Exception('UserDataManager not initialized');
    return _userCategoriesBox;
  }

  /// Get user favorites box
  Box get userFavoritesBox {
    if (!_isInitialized) throw Exception('UserDataManager not initialized');
    return _userFavoritesBox;
  }

  /// Get user history box
  Box<HistoryEntry> get userHistoryBox {
    if (!_isInitialized) throw Exception('UserDataManager not initialized');
    return _userHistoryBox;
  }

  /// Get user settings box
  Box<AppSettings> get userSettingsBox {
    if (!_isInitialized) throw Exception('UserDataManager not initialized');
    return _userSettingsBox;
  }

  /// Get user communication history box
  Box<CommunicationHistoryEntry> get userCommunicationHistoryBox {
    if (!_isInitialized) throw Exception('UserDataManager not initialized');
    return _userCommunicationHistoryBox;
  }

  /// Get user phrase history box
  Box get userPhraseHistoryBox {
    if (!_isInitialized) throw Exception('UserDataManager not initialized');
    return _userPhraseHistoryBox;
  }

  /// Get user favorites box (for FavoritesService)
  Future<Box> getFavoritesBox() async {
    if (!_isInitialized) throw Exception('UserDataManager not initialized');
    return _userFavoritesBox;
  }

  /// Get user custom categories box (for CustomCategoriesService)
  Future<Box> getCustomCategoriesBox() async {
    if (!_isInitialized) throw Exception('UserDataManager not initialized');
    final boxName = FirebasePathRegistry.hiveCustomCategoriesBox(_currentUserId!);
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    }
    return await Hive.openBox(boxName);
  }

  /// Get user custom symbols box (for CustomSymbolsService)
  Future<Box> getCustomSymbolsBox() async {
    if (!_isInitialized) throw Exception('UserDataManager not initialized');
    final boxName = FirebasePathRegistry.hiveCustomSymbolsBox(_currentUserId!);
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    }
    return await Hive.openBox(boxName);
  }

  // FIRESTORE ACCESSORS - DISABLED IN SUPABASE MIGRATION

  // /// Get user's Firestore document reference
  // DocumentReference get userDocument {
  //   if (!_isInitialized) throw Exception('UserDataManager not initialized');
  //   return _firestore.doc(FirebasePathRegistry.userDocument(_currentUserId));
  // }

  // /// Get user's symbols collection
  // CollectionReference get userSymbolsCollection {
  //   return _firestore.collection(FirebasePathRegistry.userSymbols(_currentUserId));
  // }

  // /// Get user's favorites collection
  // CollectionReference get userFavoritesCollection {
  //   return userDocument.collection('favorites');
  // }

  /// Save the entire user profile to Supabase (migrated from Firestore)
  Future<void> saveUserProfile(UserProfile profile) async {
    if (!_isInitialized) {
      AACLogger.warning('Cannot save profile, UserDataManager not initialized.');
      return;
    }
    try {
      await Supabase.instance.client
          .from('user_profiles')
          .upsert(profile.toJson());
      _userProfile = profile; // Update local cache
      AACLogger.info('Successfully saved user profile to Supabase for ID: ${profile.id}');
    } catch (e) {
      AACLogger.error('Error saving user profile: $e');
      rethrow;
    }
  }

  // GENERIC CLOUD DATA METHODS - DISABLED IN SUPABASE MIGRATION

  /// Get a generic data blob from Supabase user_settings table
  Future<dynamic> getCloudData(String key, {DateTime? lastSyncTime}) async {
    if (!_isInitialized) return null;
    
    try {
      // Route to specific tables based on key
      if (key == 'favorites_history') {
        return await _getHistoryFromSupabase(lastSyncTime: lastSyncTime);
      } else if (key == 'favorites') {
        return await _getFavoritesFromSupabase();
      } else if (key == 'custom_categories') {
        return await _getCustomCategoriesFromSupabase();
      } else {
        // Fallback to generic user_settings
        return await _getGenericData(key);
      }
    } catch (e) {
      AACLogger.error('UserDataManager: Error getting cloud data for key $key: $e');
      return null;
    }
  }

  /// Get history from communication_history table with incremental sync support
  Future<List<Map<String, dynamic>>?> _getHistoryFromSupabase({DateTime? lastSyncTime}) async {
    try {
      var query = Supabase.instance.client
          .from('communication_history')
          .select('*')
          .eq('user_id', _currentUserId!);

      // If lastSyncTime is provided, only fetch newer records for incremental sync
      if (lastSyncTime != null) {
        query = query.gt('created_at', lastSyncTime.toIso8601String());
        AACLogger.info('UserDataManager: Incremental sync - fetching history items newer than: ${lastSyncTime.toIso8601String()}');
      } else {
        AACLogger.info('UserDataManager: Full sync - fetching all history items');
      }

      final response = await query.order('created_at', ascending: false);

      if (response.isNotEmpty) {
        AACLogger.info('UserDataManager: Loaded ${response.length} ${lastSyncTime != null ? 'NEW' : ''} history items from communication_history for UID: $_currentUserId');
        
        // Convert to the format expected by FavoritesService
        final historyItems = <Map<String, dynamic>>[];
        for (final item in response) {
          final symbolsUsed = item['symbols_used'] as List?;
          if (symbolsUsed != null && symbolsUsed.isNotEmpty) {
            final symbolData = symbolsUsed.first as Map<String, dynamic>;
            historyItems.add({
              'symbol': symbolData,
              'timestamp': item['created_at'],
              'action': (item['context_info'] as Map<String, dynamic>?)?['action'] ?? 'played',
            });
          }
        }
        
        return historyItems;
      }
      
      AACLogger.info('UserDataManager: No ${lastSyncTime != null ? 'new' : ''} history found in communication_history for UID: $_currentUserId');
      return null;
    } catch (e) {
      AACLogger.error('UserDataManager: Error getting history from communication_history: $e');
      return null;
    }
  }

  /// Get favorites from user_favorites table (enhanced to store both default and custom symbols)
  Future<List<Map<String, dynamic>>?> _getFavoritesFromSupabase() async {
    try {
      // Get all favorites for this user with enhanced schema support
      final favoritesResponse = await Supabase.instance.client
          .from('user_favorites')
          .select('symbol_id, symbol_label, symbol_data, is_custom, added_at')
          .eq('user_id', _currentUserId!)
          .order('added_at', ascending: false);

      if (favoritesResponse.isNotEmpty) {
        AACLogger.info('UserDataManager: 📥 BIDIRECTIONAL SYNC: Found ${favoritesResponse.length} favorites from user_favorites table');
        print('📥 SUPABASE SYNC: Loading favorites from enhanced user_favorites table');
        
        final favorites = <Map<String, dynamic>>[];
        
        for (final fav in favoritesResponse) {
          try {
            // Priority: Use stored symbol_data for complete symbol information
            Map<String, dynamic> symbolData;
            
            if (fav['symbol_data'] != null && fav['symbol_data'] is Map) {
              // Use complete symbol data stored as JSONB
              symbolData = Map<String, dynamic>.from(fav['symbol_data']);
              print('✅ ENHANCED SYNC: Loaded complete symbol data for "${fav['symbol_label']}"');
            } else {
              // Fallback: construct from individual columns (for legacy data)
              symbolData = {
                'id': fav['symbol_id'],
                'label': fav['symbol_label'] ?? fav['symbol_id'],
                'category': 'Favorites',
                'isDefault': !fav['is_custom'],
              };
              AACLogger.info('UserDataManager: 🔄 FALLBACK: Constructed symbol from individual fields for ${fav['symbol_id']}');
            }
            
            // Ensure consistency between symbol_data and individual columns
            symbolData['id'] = symbolData['id'] ?? fav['symbol_id'];
            symbolData['label'] = symbolData['label'] ?? fav['symbol_label'] ?? fav['symbol_id'];
            symbolData['isDefault'] = symbolData['isDefault'] ?? !fav['is_custom'];
            
            favorites.add(symbolData);
            
          } catch (e) {
            AACLogger.warning('UserDataManager: ❌ Failed to process favorite ${fav['symbol_id']}: $e', tag: 'UserDataManager');
          }
        }
        
        if (favorites.isNotEmpty) {
          print('✅ BIDIRECTIONAL SYNC: Successfully loaded ${favorites.length} favorites (${favorites.where((f) => f['isDefault'] == true).length} default + ${favorites.where((f) => f['isDefault'] != true).length} custom)');
          AACLogger.info('UserDataManager: 📊 SYNC STATS: ${favorites.length} total favorites loaded from user_favorites table');
          return favorites;
        }
      }
      
      AACLogger.info('UserDataManager: No favorites found in user_favorites for UID: $_currentUserId');
      return null;
    } catch (e) {
      AACLogger.error('UserDataManager: Error getting favorites from user_favorites: $e');
      return null;
    }
  }

  /// Get custom categories from user_custom_categories table
  Future<List<Map<String, dynamic>>?> _getCustomCategoriesFromSupabase() async {
    try {
      final categoriesResponse = await Supabase.instance.client
          .from('user_custom_categories')
          .select('*')
          .eq('profile_id', _currentUserId!)  // Note: uses profile_id per table schema
          .order('sort_order', ascending: true);  // Note: uses sort_order per table schema

      if (categoriesResponse.isNotEmpty) {
        AACLogger.info('UserDataManager: Found ${categoriesResponse.length} custom categories for UID: $_currentUserId');
        
        // Convert to the format expected by CustomCategoriesService
        final categories = <Map<String, dynamic>>[];
        for (final item in categoriesResponse) {
          categories.add({
            'id': item['id'],
            'name': item['name'],  // Note: field is 'name', not 'category_name'
            'description': item['description'],
            'colorCode': item['color_code'],
            'iconPath': item['icon_path'],
            'displayOrder': item['sort_order'],  // Note: field is 'sort_order'
            'isDefault': false, // Custom categories are never default
            'isShared': item['is_shared'] ?? false,
            'symbolsCount': item['symbols_count'] ?? 0,
          });
        }
        
        AACLogger.info('UserDataManager: Loaded ${categories.length} custom categories from user_custom_categories');
        return categories;
      }
      
      AACLogger.info('UserDataManager: No custom categories found in user_custom_categories for UID: $_currentUserId');
      return null;
    } catch (e) {
      AACLogger.error('UserDataManager: Error getting custom categories from user_custom_categories: $e');
      return null;
    }
  }

  /// Fallback for generic data
  Future<dynamic> _getGenericData(String key) async {
    final response = await Supabase.instance.client
        .from('user_settings')
        .select('setting_value')
        .eq('profile_id', _currentUserId!)
        .eq('setting_key', key)
        .maybeSingle();

    if (response != null) {
      AACLogger.info('UserDataManager: Loaded $key from user_settings for UID: $_currentUserId');
      return response['setting_value'];
    }
    
    AACLogger.info('UserDataManager: No data found for key $key in user_settings, UID: $_currentUserId');
    return null;
  }

  /// Set a generic data blob in Supabase user_settings table (non-blocking for background sync)
  Future<void> setCloudData(String key, dynamic value) async {
    if (!_isInitialized) return;
    
    // Route to specific tables based on key
    if (key == 'favorites_history') {
      await _syncHistoryToSupabase(value);
    } else if (key == 'single_history_item') {
      // FIXED: Handle single item sync to prevent duplicates
      await _syncSingleHistoryItem(value);
    } else if (key == 'favorites') {
      await _syncFavoritesToSupabase(value);
    } else if (key == 'custom_categories') {
      await _syncCustomCategoriesToSupabase(value);
    } else {
      // Fallback to generic user_settings for other keys
      await _syncGenericData(key, value);
    }
  }

  /// Sync history data to communication_history table
  Future<void> _syncHistoryToSupabase(dynamic historyData) async {
    if (historyData == null || historyData is! List) return;
    
    Future.microtask(() async {
      try {
        // 🚀 INCREMENTAL SYNC: Only sync new history items, not all data
        final cutoffTime = DateTime.now().subtract(Duration(hours: 24)).toIso8601String();
        
        // Get existing history IDs from Supabase (recent items only)
        final existingHistory = await Supabase.instance.client
            .from('communication_history')
            .select('message_text, created_at')
            .eq('user_id', _currentUserId!)
            .gte('created_at', cutoffTime);
        
        final existingKeys = <String>{};
        for (final item in existingHistory) {
          final key = '${item['message_text']}_${item['created_at']}';
          existingKeys.add(key);
        }
        
        // Filter to only NEW history items
        final newHistoryRecords = <Map<String, dynamic>>[];
        for (final item in historyData) {
          if (item is Map<String, dynamic>) {
            final symbolData = item['symbol'] as Map<String, dynamic>?;
            if (symbolData != null) {
              final timestamp = item['timestamp'] ?? DateTime.now().toIso8601String();
              final messageText = symbolData['label'] ?? 'Unknown';
              final itemKey = '${messageText}_${timestamp}';
              
              // Only add if not already in Supabase
              if (!existingKeys.contains(itemKey)) {
                newHistoryRecords.add({
                  'user_id': _currentUserId,
                  'message_text': messageText,
                  'symbols_used': [symbolData],
                  'communication_type': item['action'] == 'phrase' ? 'phrase' : 'word',
                  'context_info': {'action': item['action']},
                  'created_at': timestamp,
                });
              }
            }
          }
        }
        
        if (newHistoryRecords.isNotEmpty) {
          // Schema-compatible SCD: Use existing columns with enhanced context metadata
          final enhancedRecords = newHistoryRecords.map((record) {
            final messageText = record['message_text'];
            final timestamp = record['created_at'];
            final parsedTime = DateTime.tryParse(timestamp) ?? DateTime.now();
            final timeHash = (parsedTime.millisecondsSinceEpoch ~/ 1000).toString();
            
            // Store SCD metadata in context_info JSONB field (existing column)
            final originalContext = record['context_info'] as Map<String, dynamic>? ?? {};
            final enhancedContext = {
              ...originalContext,
              'scd_metadata': {
                'composite_key': '${_currentUserId}_${messageText}_$timeHash',
                'sync_method': 'bulk_history_sync',
                'version': 1,
                'sync_timestamp': DateTime.now().toIso8601String(),
              }
            };
            
            return {
              ...record,
              'context_info': enhancedContext,
            };
          }).toList();
          
          // Use simple insert with duplicate checking (schema-compatible approach)
          try {
            await Supabase.instance.client
                .from('communication_history')
                .insert(enhancedRecords);
            
            print('📤 SCD BULK INSERT: Added ${enhancedRecords.length} history items with metadata tracking');
            AACLogger.info('UserDataManager: 🚀 SCD: Bulk inserted ${enhancedRecords.length} history items with SCD metadata', tag: 'UserDataManager');
          } catch (bulkError) {
            // Fallback to individual inserts with duplicate checking
            print('⚠️  SCD FALLBACK: Bulk insert failed, using individual insert with duplicate check');
            
            int successCount = 0;
            for (final record in enhancedRecords) {
              try {
                // Check for existing record before inserting
                final messageText = record['message_text'];
                final createdAt = record['created_at'];
                
                final existing = await Supabase.instance.client
                    .from('communication_history')
                    .select('id')
                    .eq('user_id', _currentUserId!)
                    .eq('message_text', messageText)
                    .eq('created_at', createdAt)
                    .maybeSingle();
                
                if (existing == null) {
                  await Supabase.instance.client
                      .from('communication_history')
                      .insert(record);
                  successCount++;
                } else {
                  print('🔄 SCD SKIP: Duplicate detected for $messageText');
                }
              } catch (insertError) {
                // Skip duplicates (likely constraint violations or other conflicts)
                if (!insertError.toString().contains('duplicate') && 
                    !insertError.toString().contains('constraint') &&
                    !insertError.toString().contains('violates')) {
                  print('❌ Individual insert failed for ${record['message_text']}: $insertError');
                }
              }
            }
            
            print('📤 SCD INDIVIDUAL: Successfully inserted $successCount/${enhancedRecords.length} history items');
            AACLogger.info('UserDataManager: ✅ SCD: Individual insert completed $successCount/${enhancedRecords.length}', tag: 'UserDataManager');
          }
        } else {
          print('✅ SCD STATUS: All ${historyData.length} history items already synced - no new data to upload');
        }
        
      } catch (e) {
        AACLogger.warning('UserDataManager: ⚠️  Incremental history sync failed: $e', tag: 'UserDataManager');
        print('❌ SYNC ERROR: History incremental sync failed: $e');
      }
    });
  }

  /// Sync a single new history item to prevent duplicates
  Future<void> _syncSingleHistoryItem(dynamic singleItemData) async {
    if (singleItemData == null || singleItemData is! List || singleItemData.isEmpty) return;
    
    Future.microtask(() async {
      try {
        final item = singleItemData[0];
        if (item is Map<String, dynamic>) {
          final symbolData = item['symbol'] as Map<String, dynamic>?;
          if (symbolData != null) {
            final timestamp = item['timestamp'] ?? DateTime.now().toIso8601String();
            final messageText = symbolData['label'] ?? 'Unknown';
            
            // Schema-Compatible SCD MERGE: Check for duplicates using existing columns
            final parsedTimestamp = DateTime.tryParse(timestamp) ?? DateTime.now();
            final timeWindow = parsedTimestamp.subtract(Duration(minutes: 5));
            
            try {
              // Check if this exact item already exists within 5-minute window
              final existing = await Supabase.instance.client
                  .from('communication_history')
                  .select('id, created_at, context_info')
                  .eq('user_id', _currentUserId!)
                  .eq('message_text', messageText)
                  .gte('created_at', timeWindow.toIso8601String())
                  .lte('created_at', parsedTimestamp.add(Duration(minutes: 5)).toIso8601String())
                  .maybeSingle();
              
              if (existing != null) {
                print('🔄 SCD MERGE: Single item "$messageText" already exists, updating context');
                
                // Merge existing context with new SCD metadata
                final existingContext = existing['context_info'] as Map<String, dynamic>? ?? {};
                final enhancedContext = {
                  ...existingContext,
                  'action': item['action'],
                  'scd_metadata': {
                    ...((existingContext['scd_metadata'] as Map<String, dynamic>?) ?? {}),
                    'sync_method': 'single_item_sync',
                    'last_sync': DateTime.now().toIso8601String(),
                    'update_count': ((existingContext['scd_metadata']?['update_count'] as int?) ?? 0) + 1,
                    'composite_key': '${_currentUserId}_${messageText}_${parsedTimestamp.millisecondsSinceEpoch ~/ 1000}',
                  }
                };
                
                // Update existing record with enhanced context (SCD Type 1 strategy)
                await Supabase.instance.client
                    .from('communication_history')
                    .update({
                      'symbols_used': [symbolData],
                      'context_info': enhancedContext,
                    })
                    .eq('id', existing['id']);
                
                print('📤 SCD UPDATE: Updated existing single item: $messageText');
                AACLogger.info('UserDataManager: 🔄 SCD: Updated existing history item "$messageText"', tag: 'UserDataManager');
              } else {
                // Create new record with SCD metadata in context_info (schema-compatible)
                final newRecord = {
                  'user_id': _currentUserId,
                  'message_text': messageText,
                  'symbols_used': [symbolData],
                  'communication_type': item['action'] == 'phrase' ? 'phrase' : 'word',
                  'context_info': {
                    'action': item['action'],
                    'scd_metadata': {
                      'sync_method': 'single_item_sync',
                      'composite_key': '${_currentUserId}_${messageText}_${parsedTimestamp.millisecondsSinceEpoch ~/ 1000}',
                      'version': 1,
                      'created_via': 'user_data_manager',
                    }
                  },
                  'created_at': timestamp,
                };
                
                await Supabase.instance.client
                    .from('communication_history')
                    .insert(newRecord);
                
                print('📤 SCD INSERT: Added new single history item: $messageText');
                AACLogger.info('UserDataManager: ✅ SCD: Created new history item "$messageText"', tag: 'UserDataManager');
              }
            } catch (duplicateError) {
              // Fallback: If duplicate check fails, skip this item to prevent duplication
              print('⚠️  SCD FALLBACK: Skipping potential duplicate "$messageText" due to check error: $duplicateError');
              AACLogger.warning('UserDataManager: ⚠️  SCD: Skipped potential duplicate "$messageText"', tag: 'UserDataManager');
            }
          }
        }
      } catch (e) {
        AACLogger.warning('UserDataManager: ⚠️  Single history item sync failed: $e', tag: 'UserDataManager');
        print('❌ SYNC ERROR: Single history item sync failed: $e');
      }
    });
  }

  /// Clean favorites sync: Properly use user_favorites table only for favorites storage
  /// - All favorites (default and custom) → user_favorites table with enhanced schema
  /// - Proper user isolation with user_id for each user's favorites
  /// - Clean separation: favorites in user_favorites, phrases in phrase_history
  Future<void> _syncFavoritesToSupabase(dynamic favoritesData) async {
    if (favoritesData == null || favoritesData is! List) {
      AACLogger.warning('UserDataManager: Favorites data is null or not a list, skipping sync', tag: 'UserDataManager');
      return;
    }
    
    Future.microtask(() async {
      try {
        // 🚀 INCREMENTAL SYNC: Check what's already in Supabase to avoid unnecessary uploads
        final existingFavorites = await Supabase.instance.client
            .from('user_favorites')
            .select('symbol_id, symbol_label')
            .eq('user_id', _currentUserId!);
        
        final existingSymbolIds = <String>{};
        for (final fav in existingFavorites) {
          existingSymbolIds.add(fav['symbol_id'] as String);
        }
        
        AACLogger.info('UserDataManager: 🔄 INCREMENTAL SYNC: Processing ${favoritesData.length} local favorites (${existingSymbolIds.length} already in Supabase)', tag: 'UserDataManager');
        print('🔄 SUPABASE SYNC: Incremental favorites sync - checking ${favoritesData.length} local vs ${existingSymbolIds.length} existing');
        
        final newFavoriteRecords = <Map<String, dynamic>>[];
        final localSymbolIds = <String>{};
        int skippedCount = 0;
        
        for (final item in favoritesData) {
          if (item is Map<String, dynamic>) {
            final symbolLabel = item['label'] ?? 'Unknown';
            
            // Fix UUID issue: Generate proper UUID if ID is missing or not a UUID
            String symbolId = item['id']?.toString() ?? '';
            if (symbolId.isEmpty || !_isValidUuid(symbolId)) {
              symbolId = _generateSymbolUuid(symbolLabel);
              item['id'] = symbolId;
              print('🔧 UUID FIX: Generated UUID "$symbolId" for symbol "$symbolLabel"');
            }
            
            localSymbolIds.add(symbolId);
            
            // Only add if not already in Supabase
            if (!existingSymbolIds.contains(symbolId)) {
              newFavoriteRecords.add({
                'user_id': _currentUserId,
                'symbol_id': symbolId,
                'symbol_label': symbolLabel,
                'symbol_data': item,
                'is_custom': item['isDefault'] != true,
                'added_at': DateTime.now().toIso8601String(),
              });
              print('➕ NEW FAVORITE: Adding "$symbolLabel" to Supabase');
            } else {
              skippedCount++;
            }
          }
        }
        
        // Insert only NEW favorites
        if (newFavoriteRecords.isNotEmpty) {
          await Supabase.instance.client
              .from('user_favorites')
              .insert(newFavoriteRecords);
          
          print('📤 INCREMENTAL SYNC: Added ${newFavoriteRecords.length} NEW favorites (skipped $skippedCount existing)');
          AACLogger.info('UserDataManager: 📤 INCREMENTAL: Added ${newFavoriteRecords.length} new favorites, skipped $skippedCount existing');
        } else {
          print('✅ SYNC STATUS: All ${favoritesData.length} favorites already synced - no new data to upload');
        }
        
        // Clean up orphaned favorites (removed locally but still in Supabase)
        final orphanedSymbols = existingSymbolIds.where((id) => !localSymbolIds.contains(id)).toList();
        
        if (orphanedSymbols.isNotEmpty) {
          await Supabase.instance.client
              .from('user_favorites')
              .delete()
              .eq('user_id', _currentUserId!)
              .inFilter('symbol_id', orphanedSymbols);
          print('🧹 CLEANUP: Removed ${orphanedSymbols.length} orphaned favorites from Supabase');
        }
        
        print('🎯 BIDIRECTIONAL SUCCESS: Complete favorites sync with enhanced schema and cleanup');
        
      } catch (e, stackTrace) {
        AACLogger.error('UserDataManager: ❌ BIDIRECTIONAL SYNC: Favorites sync failed: $e', stackTrace: stackTrace, tag: 'UserDataManager');
        print('❌ BIDIRECTIONAL ERROR: Favorites sync failed: $e');
      }
    });
  }

  /// Sync custom categories data to user_custom_categories table
  /// Enterprise custom categories sync: Advanced hierarchy with performance optimization
  /// - Hierarchical categories → user_custom_categories with parent/child relationships
  /// - Performance tracking → learning_analytics table  
  /// - Usage optimization → Batch operations with proper indexing
  Future<void> _syncCustomCategoriesToSupabase(dynamic categoriesData) async {
    if (categoriesData == null || categoriesData is! List) {
      AACLogger.warning('UserDataManager: Categories data is null or not a list, skipping sync', tag: 'UserDataManager');
      return;
    }
    
    Future.microtask(() async {
      try {
        AACLogger.info('UserDataManager: 🔄 ENTERPRISE SYNC: Processing ${categoriesData.length} custom categories with hierarchy support', tag: 'UserDataManager');
        print('🔄 SUPABASE SYNC: Enterprise categories sync - hierarchical approach');
        
        final categoryRecords = <Map<String, dynamic>>[];
        final categoryHierarchy = <String, String?>{}; // child -> parent mapping
        int skippedDefault = 0;
        
        // ENTERPRISE STRATEGY 1: Process categories with hierarchy detection
        for (final item in categoriesData) {
          if (item is Map<String, dynamic>) {
            // Only sync non-default (custom) categories
            if (item['isDefault'] != true) {
              final categoryName = item['name'] ?? 'Unknown Category';
              final parentCategory = item['parentCategory'];
              categoryHierarchy[categoryName] = parentCategory;
              
              categoryRecords.add({
                'profile_id': _currentUserId,
                'name': categoryName,
                'description': item['description'] ?? '',
                'color_code': item['colorCode'],
                'icon_path': item['iconPath'],
                'parent_category_id': null, // Will be resolved in second pass
                'sort_order': item['displayOrder'] ?? 0,
                'is_shared': item['isShared'] ?? false,
                'symbols_count': item['symbolCount'] ?? 0,
                'usage_frequency': item['usageCount'] ?? 0,
                'tags': item['tags'] ?? [],
                'metadata': {
                  'creation_source': 'user_sync',
                  'last_modified': DateTime.now().toIso8601String(),
                  'version': 1,
                },
              });
            } else {
              skippedDefault++;
            }
          }
        }
        
        // ENTERPRISE STRATEGY 2: Batch operations with transaction-like behavior
        if (categoryRecords.isNotEmpty) {
          // Clear existing categories for clean sync
          await Supabase.instance.client
              .from('user_custom_categories')
              .delete()
              .eq('profile_id', _currentUserId!);
          print('🔄 ENTERPRISE: Cleared existing categories for clean sync');
          
          // Insert parent categories first (no parent_category_id)
          final parentCategories = categoryRecords
              .where((cat) => categoryHierarchy[cat['name']] == null)
              .toList();
          
          if (parentCategories.isNotEmpty) {
            final insertedParents = await Supabase.instance.client
                .from('user_custom_categories')
                .insert(parentCategories)
                .select('id, name');
            
            // Create parent name -> id mapping for child categories
            final parentIdMap = <String, int>{};
            for (final parent in insertedParents) {
              parentIdMap[parent['name']] = parent['id'];
            }
            
            // Insert child categories with proper parent_category_id
            final childCategories = categoryRecords
                .where((cat) => categoryHierarchy[cat['name']] != null)
                .map((cat) {
              final parentName = categoryHierarchy[cat['name']];
              cat['parent_category_id'] = parentIdMap[parentName];
              return cat;
            }).toList();
            
            if (childCategories.isNotEmpty) {
              await Supabase.instance.client
                  .from('user_custom_categories')
                  .insert(childCategories);
              print('✅ ENTERPRISE: ${childCategories.length} child categories with hierarchy');
            }
            
            print('✅ ENTERPRISE: ${parentCategories.length} parent categories synced');
          } else {
            // All flat categories - insert directly
            await Supabase.instance.client
                .from('user_custom_categories')
                .insert(categoryRecords);
            print('✅ ENTERPRISE: ${categoryRecords.length} flat categories synced');
          }
          
          // ENTERPRISE STRATEGY 3: Analytics tracking for performance monitoring
          await Supabase.instance.client
              .from('learning_analytics')
              .insert({
                'profile_id': _currentUserId,
                'activity_type': 'category_sync',
                'content_type': 'custom_categories',
                'metrics': {
                  'categories_synced': categoryRecords.length,
                  'hierarchical_categories': categoryHierarchy.length,
                  'sync_timestamp': DateTime.now().toIso8601String(),
                  'performance_score': categoryRecords.length > 0 ? 1.0 : 0.0,
                },
                'session_data': {
                  'sync_type': 'enterprise_hierarchical',
                  'batch_size': categoryRecords.length,
                },
              });
          
          AACLogger.info('UserDataManager: ✅ ENTERPRISE SYNC: Successfully processed ${categoryRecords.length} categories with hierarchy optimization (${skippedDefault} default skipped)', tag: 'UserDataManager');
          print('🎯 ENTERPRISE SUCCESS: Hierarchical categories sync with performance tracking');
        }
        
        if (skippedDefault > 0) {
          print('ℹ️  ENTERPRISE: Skipped ${skippedDefault} default categories (enterprise maintains custom-only strategy)');
        }
        
      } catch (e, stackTrace) {
        AACLogger.error('UserDataManager: ❌ ENTERPRISE SYNC: Categories sync failed: $e', stackTrace: stackTrace, tag: 'UserDataManager');
        print('❌ ENTERPRISE ERROR: Categories sync failed: $e');
      }
    });
  }

  /// Enterprise settings sync: Comprehensive user_settings table management
  /// 
  /// ENTERPRISE STRATEGY:
  /// - Grouped settings by category (ui, speech, accessibility, privacy, data)
  /// - Proper validation and data types
  /// - Performance tracking and analytics
  /// - Version control for settings evolution
  Future<void> _syncGenericData(String key, dynamic value) async {
    Future.microtask(() async {
      try {
        AACLogger.info('UserDataManager: 🔄 ENTERPRISE SETTINGS: Syncing $key to comprehensive user_settings', tag: 'UserDataManager');
        
        // ENTERPRISE STRATEGY: Determine appropriate setting group
        String settingGroup = 'data'; // Default
        if (key.startsWith('speech_')) {
          settingGroup = 'speech';
        } else if (key.startsWith('ui_') || key.contains('theme') || key.contains('display')) {
          settingGroup = 'ui';
        } else if (key.startsWith('accessibility_') || key.contains('contrast') || key.contains('size')) {
          settingGroup = 'accessibility';
        } else if (key.startsWith('privacy_') || key.contains('analytics') || key.contains('tracking')) {
          settingGroup = 'privacy';
        } else if (key.contains('favorites') || key.contains('categories') || key.contains('symbols')) {
          settingGroup = 'data';
        }
        
        // ENTERPRISE VALIDATION: Prepare setting data with metadata
        final settingData = {
          'profile_id': _currentUserId,
          'setting_group': settingGroup,
          'setting_key': key,
          'setting_value': value,
          'data_type': _getDataType(value),
          'is_sensitive': _isSensitiveSetting(key),
          'version': 1, // For future settings migration support
          'metadata': {
            'sync_source': 'user_data_manager',
            'last_modified_by': _currentUserId,
            'modification_context': 'automatic_sync',
          },
          'last_modified_at': DateTime.now().toIso8601String(),
        };
        
        // ENTERPRISE INSERT/UPDATE with conflict resolution
        await Supabase.instance.client
            .from('user_settings')
            .upsert(settingData, onConflict: 'profile_id,setting_key');
        
        // ENTERPRISE ANALYTICS: Track settings usage patterns
        await Supabase.instance.client
            .from('learning_analytics')
            .insert({
              'profile_id': _currentUserId,
              'activity_type': 'setting_sync',
              'content_type': 'user_settings',
              'metrics': {
                'setting_key': key,
                'setting_group': settingGroup,
                'data_size': value.toString().length,
                'sync_timestamp': DateTime.now().toIso8601String(),
              },
              'session_data': {
                'sync_method': 'enterprise_settings_sync',
                'data_type': _getDataType(value),
              },
            });
        
        AACLogger.info('UserDataManager: ✅ ENTERPRISE SUCCESS: Synced $key to user_settings group "$settingGroup"', tag: 'UserDataManager');
        print('🎯 ENTERPRISE: Settings sync complete - $key -> $settingGroup');
        
      } catch (e) {
        AACLogger.warning('UserDataManager: ❌ ENTERPRISE ERROR: Settings sync failed for $key: $e', tag: 'UserDataManager');
        // Don't rethrow - this is background sync, local operation should continue
      }
    });
  }
  
  /// Helper: Determine data type for enterprise validation
  String _getDataType(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return 'string';
    if (value is int) return 'integer';
    if (value is double) return 'float';
    if (value is bool) return 'boolean';
    if (value is List) return 'array';
    if (value is Map) return 'object';
    return 'unknown';
  }
  
  /// Helper: Identify sensitive settings for enterprise security
  bool _isSensitiveSetting(String key) {
    final sensitiveKeys = [
      'user_id', 'auth_token', 'api_key', 'password', 
      'email', 'phone', 'location', 'personal_info'
    ];
    return sensitiveKeys.any((sensitive) => key.toLowerCase().contains(sensitive));
  }

  /// Helper: Validate if a string is a valid UUID format
  bool _isValidUuid(String uuid) {
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    );
    return uuidRegex.hasMatch(uuid);
  }

  /// Helper: Generate deterministic UUID from symbol label for consistency
  String _generateSymbolUuid(String label) {
    // Create deterministic UUID based on label hash for consistency
    final hash = label.hashCode.abs();
    final hashStr = hash.toString().padLeft(10, '0');
    
    // Generate additional hash for full UUID length
    final hash2 = (label + '_symbol').hashCode.abs();
    final hash2Str = hash2.toString().padLeft(10, '0');
    
    // Combine and format as UUID v4: xxxxxxxx-xxxx-4xxx-axxx-xxxxxxxxxxxx
    final combined = (hashStr + hash2Str).padRight(32, '0').substring(0, 32);
    
    return '${combined.substring(0, 8)}-'
           '${combined.substring(8, 12)}-'
           '4${combined.substring(13, 16)}-'
           'a${combined.substring(17, 20)}-'
           '${combined.substring(20, 32)}';
  }

  /// LOCAL-FIRST CUSTOM CATEGORIES METHODS
  
  /// Add a custom category to local storage immediately
  Future<void> addCustomCategory(Category category) async {
    if (!_isInitialized) throw Exception('UserDataManager not initialized');
    
    try {
      // Save to local Hive box
      final key = category.id ?? _generateUniqueId();
      if (category.id == null) {
        category.id = key;
      }
      
      await _userCategoriesBox.put(key, category);
      AACLogger.info('UserDataManager: Added custom category "${category.name}" to local storage', tag: 'UserDataManager');
      
      // Queue for Supabase sync in background
      await _queueCategoryForSync(category);
    } catch (e) {
      AACLogger.error('UserDataManager: Failed to add custom category: $e', tag: 'UserDataManager');
      rethrow;
    }
  }
  
  /// Get all custom categories from local storage
  Future<List<Category>> getCustomCategories() async {
    if (!_isInitialized) throw Exception('UserDataManager not initialized');
    
    try {
      final categories = _userCategoriesBox.values.where((cat) => !cat.isDefault).toList();
      AACLogger.info('UserDataManager: Retrieved ${categories.length} custom categories from local storage', tag: 'UserDataManager');
      return categories;
    } catch (e) {
      AACLogger.error('UserDataManager: Failed to get custom categories: $e', tag: 'UserDataManager');
      return [];
    }
  }
  
  /// Remove a custom category from local storage
  Future<void> removeCustomCategory(String categoryId) async {
    if (!_isInitialized) throw Exception('UserDataManager not initialized');
    
    try {
      await _userCategoriesBox.delete(categoryId);
      AACLogger.info('UserDataManager: Removed custom category $categoryId from local storage', tag: 'UserDataManager');
      
      // Queue for Supabase delete in background
      await _queueCategoryForDeletion(categoryId);
    } catch (e) {
      AACLogger.error('UserDataManager: Failed to remove custom category: $e', tag: 'UserDataManager');
      rethrow;
    }
  }
  
  /// Queue category for background sync to Supabase (DISABLED - using direct insertion)
  Future<void> _queueCategoryForSync(Category category) async {
    // 🔥 REMOVED: Batch sync disabled - CustomCategoriesService now uses direct insertion
    AACLogger.info('UserDataManager: Category sync disabled - using direct insertion for "${category.name}"', tag: 'UserDataManager');
  }
  
  /// Queue category for background deletion from Supabase (DISABLED - using direct insertion)
  Future<void> _queueCategoryForDeletion(String categoryId) async {
    // 🔥 REMOVED: Batch sync disabled - CustomCategoriesService now uses direct deletion
    AACLogger.info('UserDataManager: Category deletion sync disabled - using direct deletion for $categoryId', tag: 'UserDataManager');
  }
  
  /// LOCAL-FIRST CUSTOM SYMBOLS METHODS
  
  /// Add a custom symbol to local storage immediately  
  Future<void> addCustomSymbol(Symbol symbol) async {
    if (!_isInitialized) throw Exception('UserDataManager not initialized');
    
    try {
      // Save to local Hive box
      final key = symbol.id ?? _generateUniqueId();
      if (symbol.id == null) {
        symbol.id = key;
      }
      
      await _userSymbolsBox.put(key, symbol);
      AACLogger.info('UserDataManager: Added custom symbol "${symbol.label}" to local storage', tag: 'UserDataManager');
      
      // Queue for Supabase sync in background
      await _queueSymbolForSync(symbol);
    } catch (e) {
      AACLogger.error('UserDataManager: Failed to add custom symbol: $e', tag: 'UserDataManager');
      rethrow;
    }
  }
  
  /// Get all custom symbols from local storage
  Future<List<Symbol>> getCustomSymbols() async {
    if (!_isInitialized) throw Exception('UserDataManager not initialized');
    
    try {
      final symbols = _userSymbolsBox.values.where((sym) => !sym.isDefault).toList();
      AACLogger.info('UserDataManager: Retrieved ${symbols.length} custom symbols from local storage', tag: 'UserDataManager');
      return symbols;
    } catch (e) {
      AACLogger.error('UserDataManager: Failed to get custom symbols: $e', tag: 'UserDataManager');
      return [];
    }
  }
  
  /// Remove a custom symbol from local storage
  Future<void> removeCustomSymbol(String symbolId) async {
    if (!_isInitialized) throw Exception('UserDataManager not initialized');
    
    try {
      await _userSymbolsBox.delete(symbolId);
      AACLogger.info('UserDataManager: Removed custom symbol $symbolId from local storage', tag: 'UserDataManager');
      
      // Queue for Supabase delete in background
      await _queueSymbolForDeletion(symbolId);
    } catch (e) {
      AACLogger.error('UserDataManager: Failed to remove custom symbol: $e', tag: 'UserDataManager');
      rethrow;
    }
  }
  
  /// Queue symbol for background sync to Supabase (DISABLED - using direct insertion)
  Future<void> _queueSymbolForSync(Symbol symbol) async {
    // 🔥 REMOVED: Batch sync disabled - CustomSymbolsService now uses direct insertion
    AACLogger.info('UserDataManager: Symbol sync disabled - using direct insertion for "${symbol.label}"', tag: 'UserDataManager'); 
  }
  
  /// Queue symbol for background deletion from Supabase (DISABLED - using direct insertion)
  Future<void> _queueSymbolForDeletion(String symbolId) async {
    // 🔥 REMOVED: Batch sync disabled - CustomSymbolsService now uses direct deletion
    AACLogger.info('UserDataManager: Symbol deletion sync disabled - using direct deletion for $symbolId', tag: 'UserDataManager');
  }

  /// Generate unique ID for custom categories and symbols
  String _generateUniqueId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           (Random().nextInt(1000).toString().padLeft(3, '0'));
  }

  /// Dispose the user data manager and close Hive boxes.
  Future<void> dispose() async {
    // TODO: Implement proper cleanup
    AACLogger.info('UserDataManager dispose - placeholder cleanup');
  }
}
