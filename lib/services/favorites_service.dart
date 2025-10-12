import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/symbol.dart';
import 'user_data_manager.dart';
import '../utils/aac_logger.dart';
import 'supabase_aac_service_compatible.dart';

/// Production-ready Favorites Service that is controlled by DataServicesInitializer.
/// It uses the Firebase UID provided by the initializer as the single source of truth.
class FavoritesService extends ChangeNotifier {
  late final UserDataManager _userDataManager;
  late final String _currentUid;
  bool _isInitialized = false;

  // Storage keys
  static const String _favoritesKey = 'favorites';
  static const String _historyKey = 'favorites_history';
  static const String _historyLastSyncKey = 'history_last_sync';

  // Data
  List<Symbol> _favoriteSymbols = [];
  List<HistoryItem> _usageHistory = [];

  // Duplicate prevention - track recent items
  final Set<String> _recentlyProcessed = <String>{};

  // Streams for real-time updates
  final StreamController<List<Symbol>> _favoritesController = StreamController<List<Symbol>>.broadcast();
  final StreamController<List<HistoryItem>> _historyController = StreamController<List<HistoryItem>>.broadcast();
  
  // Stream for individual symbol favorite status changes
  final StreamController<Symbol> _symbolChangedController = StreamController<Symbol>.broadcast();

  // Getters
  List<Symbol> get favoriteSymbols => List.unmodifiable(_favoriteSymbols);
  List<HistoryItem> get usageHistory => List.unmodifiable(_usageHistory);
  Stream<List<Symbol>> get favoritesStream => _favoritesController.stream;
  Stream<List<HistoryItem>> get historyStream => _historyController.stream;
  Stream<Symbol> get symbolChangedStream => _symbolChangedController.stream;
  bool get isInitialized => _isInitialized;

  /// Initialize the service with a Firebase UID and a UserDataManager instance.
  /// This must be called by DataServicesInitializer.
  Future<void> initializeWithUid(String uid, UserDataManager userDataManager) async {
    print('🔥 FavoritesService: initializeWithUid called - _isInitialized: $_isInitialized, uid: $uid');
    if (_isInitialized) {
      print('🔥 FavoritesService: Already initialized, checking current UID: $_currentUid vs new UID: $uid');
      if (_currentUid == uid) {
        print('🔥 FavoritesService: Same UID, skipping re-initialization');
        return;
      } else {
        print('🔥 FavoritesService: Different UID, forcing re-initialization');
        _isInitialized = false; // Force re-initialization with new UID
      }
    }

    try {
      print('🔥 FavoritesService: Starting initialization with UID: $uid');
      AACLogger.info('FavoritesService: Initializing with UID: $uid', tag: 'FavoritesService');
      _currentUid = uid;
      _userDataManager = userDataManager;

      print('🔥 FavoritesService: About to load favorites...');
      await _loadFavorites();
      print('🔥 FavoritesService: Favorites loaded, about to load history...');
      await _loadHistory();
      print('🔥 FavoritesService: History loaded, cleaning up old synced items...');
      await _cleanupOldSyncedItems();
      print('🔥 FavoritesService: Cleanup completed, setting initialized flag...');

      _isInitialized = true;
      print('🔥 FavoritesService: ✅ Initialization completed successfully for UID: $uid');
      AACLogger.info('FavoritesService: Initialized successfully for UID: $uid', tag: 'FavoritesService');
      
      // Force sync existing local data to Supabase (one-time migration)
      print('🔥 FavoritesService: Starting force sync of existing local data...');
      await forceSyncLocalDataToSupabase();
      print('🔥 FavoritesService: Force sync completed');
    } catch (e, stacktrace) {
      print('🔥 FavoritesService: ❌ Initialization failed: $e');
      AACLogger.error('FavoritesService: Initialization failed: $e', stackTrace: stacktrace, tag: 'FavoritesService');
      _favoriteSymbols = [];
      _usageHistory = [];
      _isInitialized = true; // Initialize to prevent crashes, but with empty data.
    }
  }

  /// Load favorites from storage.
  Future<void> _loadFavorites() async {
    AACLogger.info('FavoritesService: Starting to load favorites...', tag: 'FavoritesService');
    try {
      // Try cloud first
      AACLogger.info('FavoritesService: Attempting to load from cloud...', tag: 'FavoritesService');
      final cloudFavorites = await _userDataManager.getCloudData(_favoritesKey);
      
      if (cloudFavorites != null && cloudFavorites is List) {
        AACLogger.info('FavoritesService: Found ${cloudFavorites.length} favorites in cloud', tag: 'FavoritesService');
        _favoriteSymbols = cloudFavorites.map((data) => Symbol.fromJson(Map<String, dynamic>.from(data))).toList();
        await _saveFavoritesToLocal();
        AACLogger.info('FavoritesService: Successfully loaded ${_favoriteSymbols.length} favorites from cloud.', tag: 'FavoritesService');
      } else {
        // Fallback to local storage
        AACLogger.info('FavoritesService: No cloud data found, trying local storage...', tag: 'FavoritesService');
        final localBox = await _userDataManager.getFavoritesBox();
        AACLogger.info('FavoritesService: Got local box, checking for key: $_favoritesKey', tag: 'FavoritesService');
        final localData = localBox.get(_favoritesKey);
        
        if (localData != null) {
          AACLogger.info('FavoritesService: Found local data of type: ${localData.runtimeType}', tag: 'FavoritesService');
          _favoriteSymbols = (localData as List<dynamic>).map((data) => Symbol.fromJson(Map<String, dynamic>.from(data))).toList();
          AACLogger.info('FavoritesService: Successfully loaded ${_favoriteSymbols.length} favorites from local Hive.', tag: 'FavoritesService');
        } else {
          AACLogger.info('FavoritesService: No local data found, starting with empty favorites list', tag: 'FavoritesService');
          _favoriteSymbols = [];
        }
      }
    } catch (e, stackTrace) {
      AACLogger.error('FavoritesService: Error loading favorites: $e', stackTrace: stackTrace, tag: 'FavoritesService');
      _favoriteSymbols = [];
    } finally {
      AACLogger.info('FavoritesService: Broadcasting ${_favoriteSymbols.length} favorites to stream', tag: 'FavoritesService');
      _favoritesController.add(_favoriteSymbols);
    }
  }

  /// Load history from storage with incremental sync support.
  Future<void> _loadHistory() async {
    print('🔥 FavoritesService._loadHistory: Starting incremental sync...');
    AACLogger.info('FavoritesService: Starting incremental history sync...', tag: 'FavoritesService');
    
    try {
      // First, load existing local data
      final localBox = await _userDataManager.getFavoritesBox();
      List<HistoryItem> existingHistory = [];
      DateTime? lastSyncTime;
      
      // Load existing local history
      final localData = localBox.get(_historyKey);
      if (localData != null && localData is List) {
        print('🔥 FavoritesService._loadHistory: Found ${localData.length} existing local items');
        for (int i = 0; i < localData.length; i++) {
          final item = localData[i];
          try {
            Map<String, dynamic> itemMap;
            if (item is Map<String, dynamic>) {
              itemMap = item;
            } else if (item is Map) {
              itemMap = Map<String, dynamic>.from(item);
            } else {
              continue; // Skip invalid items
            }
            existingHistory.add(HistoryItem.fromJson(itemMap));
          } catch (e) {
            print('🔥 FavoritesService._loadHistory: Error processing local item $i: $e');
            continue; // Skip invalid items
          }
        }
        AACLogger.info('FavoritesService: Loaded ${existingHistory.length} existing history items from local', tag: 'FavoritesService');
      }
      
      // Get last sync timestamp
      final lastSyncData = localBox.get(_historyLastSyncKey);
      if (lastSyncData is String) {
        try {
          lastSyncTime = DateTime.parse(lastSyncData);
          print('🔥 FavoritesService._loadHistory: Last sync time: ${lastSyncTime.toIso8601String()}');
        } catch (e) {
          print('🔥 FavoritesService._loadHistory: Invalid last sync time format, doing full sync');
          lastSyncTime = null;
        }
      }
      
      // Fetch only new items from cloud since last sync
      print('🔥 FavoritesService._loadHistory: Fetching new items from cloud...');
      final newCloudHistory = await _userDataManager.getCloudData(_historyKey, lastSyncTime: lastSyncTime);
      List<HistoryItem> newItems = [];
      
      if (newCloudHistory != null && newCloudHistory is List && newCloudHistory.isNotEmpty) {
        print('🔥 FavoritesService._loadHistory: Found ${newCloudHistory.length} NEW items in cloud');
        AACLogger.info('� INCREMENTAL SYNC: Found ${newCloudHistory.length} NEW history items from cloud', tag: 'FavoritesService');
        
        for (final data in newCloudHistory) {
          try {
            Map<String, dynamic> itemMap;
            if (data is Map<String, dynamic>) {
              itemMap = data;
            } else if (data is Map) {
              itemMap = Map<String, dynamic>.from(data);
            } else {
              continue; // Skip invalid items
            }
            newItems.add(HistoryItem.fromJson(itemMap));
          } catch (e) {
            print('🔥 FavoritesService._loadHistory: Error processing new cloud item: $e');
            continue; // Skip invalid items
          }
        }
        
        // Merge new items with existing (avoid duplicates by timestamp + symbol + action)
        final Set<String> existingKeys = existingHistory
            .map((item) => '${item.timestamp.millisecondsSinceEpoch}_${item.symbol.id ?? item.symbol.label}_${item.action}')
            .toSet();
            
        final List<HistoryItem> trulyNewItems = newItems.where((item) {
          final key = '${item.timestamp.millisecondsSinceEpoch}_${item.symbol.id ?? item.symbol.label}_${item.action}';
          return !existingKeys.contains(key);
        }).toList();
        
        if (trulyNewItems.isNotEmpty) {
          print('📤 INCREMENTAL SYNC: Added ${trulyNewItems.length} NEW history items (skipped ${newItems.length - trulyNewItems.length} existing)');
          AACLogger.info('📤 INCREMENTAL SYNC: Added ${trulyNewItems.length} NEW history items (skipped ${newItems.length - trulyNewItems.length} existing)', tag: 'FavoritesService');
          existingHistory.addAll(trulyNewItems);
        } else {
          print('✅ SYNC STATUS: All ${newItems.length} cloud items already exist locally');
          AACLogger.info('✅ SYNC STATUS: All ${newItems.length} cloud items already exist locally', tag: 'FavoritesService');
        }
        
        // Update last sync time to now
        await localBox.put(_historyLastSyncKey, DateTime.now().toIso8601String());
      } else {
        print('✅ SYNC STATUS: No new history items found in cloud');
        AACLogger.info('✅ SYNC STATUS: No new history items found since last sync', tag: 'FavoritesService');
      }
      
      // Set the final history list
      _usageHistory = existingHistory;
      
      // Keep history trimmed to reasonable size (100 items)
      if (_usageHistory.length > 100) {
        _usageHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _usageHistory = _usageHistory.sublist(0, 100);
      }
      
      // Save updated history to local
      await _saveHistoryToLocal();
      
      print('🔥 FavoritesService._loadHistory: ✅ Incremental sync completed with ${_usageHistory.length} total items');
      AACLogger.info('FavoritesService: ✅ Incremental sync completed with ${_usageHistory.length} total history items', tag: 'FavoritesService');
      
    } catch (e) {
      print('🔥 FavoritesService._loadHistory: ❌ Error: $e');
      AACLogger.error('FavoritesService: Error in incremental history sync: $e', tag: 'FavoritesService');
      _usageHistory = [];
    } finally {
      _usageHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      print('🔥 FavoritesService._loadHistory: Broadcasting ${_usageHistory.length} items to stream');
      AACLogger.info('FavoritesService: Broadcasting ${_usageHistory.length} history items to stream', tag: 'FavoritesService');
      _historyController.add(_usageHistory);
    }
  }
  
  /// Add symbol to favorites
  Future<void> addToFavorites(Symbol symbol) async {
    if (!_isInitialized) {
      AACLogger.warning('FavoritesService not initialized, cannot add to favorites.', tag: 'FavoritesService');
      return;
    }
    try {
      // Avoid duplicates
      if (!isFavorite(symbol)) {
        _favoriteSymbols.add(symbol);
        await _saveFavorites();
        
        // Sync to Supabase user_favorites table (non-blocking)
        _syncToSupabase(symbol.id ?? symbol.label, isAdd: true, symbol: symbol);
        
        // Notify only about this specific symbol change
        _symbolChangedController.add(symbol);
        AACLogger.info('Added ${symbol.label} to favorites.', tag: 'FavoritesService');
      }
    } catch (e) {
      AACLogger.error('Error adding to favorites: $e', tag: 'FavoritesService');
    }
  }

  /// Remove symbol from favorites
  Future<void> removeFromFavorites(Symbol symbol) async {
    if (!_isInitialized) {
      AACLogger.warning('FavoritesService not initialized, cannot remove from favorites.', tag: 'FavoritesService');
      return;
    }
    try {
      final initialLength = _favoriteSymbols.length;
      _favoriteSymbols.removeWhere((fav) => 
        (fav.id != null && symbol.id != null && fav.id == symbol.id) ||
        ((fav.id == null || symbol.id == null) && fav.label == symbol.label)
      );
      final wasRemoved = _favoriteSymbols.length < initialLength;
      
      if (wasRemoved) {
        await _saveFavorites();
        
        // Sync removal from Supabase user_favorites table (non-blocking)
        _syncToSupabase(symbol.id ?? symbol.label, isAdd: false);
        
        // Notify only about this specific symbol change
        _symbolChangedController.add(symbol);
        AACLogger.info('Removed ${symbol.label} from favorites.', tag: 'FavoritesService');
      }
    } catch (e) {
      AACLogger.error('Error removing from favorites: $e', tag: 'FavoritesService');
    }
  }

  /// Check if a symbol is a favorite
  bool isFavorite(Symbol symbol) {
    if (!_isInitialized) return false;
    return _favoriteSymbols.any((fav) => 
      (fav.id != null && symbol.id != null && fav.id == symbol.id) ||
      ((fav.id == null || symbol.id == null) && fav.label == symbol.label)
    );
  }

  /// Add an item to the usage history with DIRECT real-time Supabase insertion
  Future<void> recordUsage(Symbol symbol, {required String action}) async {
    print('🔥 DIRECT INSERT: Called for ${symbol.label} with action: $action, initialized: $_isInitialized');
    AACLogger.info('🔥 DIRECT INSERT: recordUsage called - symbol: ${symbol.label}, action: $action', tag: 'FavoritesService');
    
    if (!_isInitialized) {
      print('🔥 DIRECT INSERT: ❌ Service not initialized!');
      AACLogger.warning('FavoritesService not initialized, cannot record usage.', tag: 'FavoritesService');
      return;
    }
    
    try {
      final now = DateTime.now();
      final historyItem = HistoryItem(symbol: symbol, timestamp: now, action: action);
      
      // DUPLICATE PREVENTION: Create unique key for recent processing (in-memory only)
      final itemKey = '${symbol.label}_${action}_${now.millisecondsSinceEpoch ~/ 1000}'; // Round to seconds
      
      if (_recentlyProcessed.contains(itemKey)) {
        print('🔥 DIRECT INSERT: ⚠️  Skipping duplicate item within same second: $itemKey');
        AACLogger.warning('FavoritesService: Skipping duplicate item within same second: $itemKey', tag: 'FavoritesService');
        return;
      }
      
      // Add to recent processing set (short-term duplicate prevention)
      _recentlyProcessed.add(itemKey);
      
      // Clean up old entries (keep only last 10 seconds for memory management)
      final cutoffTime = now.millisecondsSinceEpoch ~/ 1000 - 10;
      _recentlyProcessed.removeWhere((key) {
        final parts = key.split('_');
        if (parts.length >= 3) {
          final timestamp = int.tryParse(parts.last) ?? 0;
          return timestamp < cutoffTime;
        }
        return false;
      });
      
      // 1. Add to local memory IMMEDIATELY (for instant UI updates)
      _usageHistory.insert(0, historyItem);
      print('🔥 DIRECT INSERT: Added to local history, total count: ${_usageHistory.length}');
      
      // Keep history trimmed to 100 items
      if (_usageHistory.length > 100) {
        _usageHistory = _usageHistory.sublist(0, 100);
      }
      
      // 2. Update UI stream IMMEDIATELY (for real-time display)
      _historyController.add(_usageHistory);
      
      // 3. Save to local storage IMMEDIATELY (for persistence)
      await _saveHistoryToLocal();
      
      // 4. DIRECT INSERT to Supabase (no complex sync logic, no batching)
      await _insertDirectlyToSupabase(historyItem);
      
      print('🔥 DIRECT INSERT: ✅ Successfully completed all operations for ${symbol.label}');
      AACLogger.info('🔥 DIRECT INSERT: Successfully recorded usage of ${symbol.label} with action: $action', tag: 'FavoritesService');
      
    } catch (e) {
      print('🔥 DIRECT INSERT: ❌ Error: $e');
      AACLogger.error('🔥 DIRECT INSERT: Error recording usage: $e', tag: 'FavoritesService');
      // Don't rethrow - let the app continue working even if cloud sync fails
    }
  }

  /// Clears all favorite symbols.
  Future<void> clearFavorites() async {
    if (!_isInitialized) return;
    _favoriteSymbols.clear();
    await _saveFavorites();
    AACLogger.info('All favorites cleared.', tag: 'FavoritesService');
  }

  /// Clears the entire usage history.
  Future<void> clearHistory() async {
    if (!_isInitialized) return;
    _usageHistory.clear();
    await _saveHistory();
    AACLogger.info('Usage history cleared.', tag: 'FavoritesService');
  }

  /// Save favorites to both local and cloud storage.
  Future<void> _saveFavorites() async {
    // Broadcast updated favorites list for components that need the full list
    _favoritesController.add(_favoriteSymbols);
    await _saveFavoritesToLocal();
    await _userDataManager.setCloudData(_favoritesKey, _favoriteSymbols.map((s) => s.toJson()).toList());
  }

  Future<void> _saveFavoritesToLocal() async {
    try {
      final box = await _userDataManager.getFavoritesBox();
      final dataToSave = _favoriteSymbols.map((s) => s.toJson()).toList();
      await box.put(_favoritesKey, dataToSave);
      AACLogger.info('FavoritesService: Saved ${_favoriteSymbols.length} favorites to local storage (key: $_favoritesKey)', tag: 'FavoritesService');
    } catch (e) {
      AACLogger.error('FavoritesService: Error saving favorites to local storage: $e', tag: 'FavoritesService');
      rethrow;
    }
  }

  /// Save history to local storage only (cloud sync uses direct insertion now)
  Future<void> _saveHistory() async {
    _historyController.add(_usageHistory);
    await _saveHistoryToLocal();
    // 🔥 REMOVED: await _userDataManager.setCloudData(...) - History now uses direct insertion
  }

  /// Save only a new history item to local storage (cloud sync uses direct insertion now)
  Future<void> _saveNewHistoryItem(HistoryItem newItem) async {
    // Update UI stream with full history
    _historyController.add(_usageHistory);
    
    // Save all history to local storage
    await _saveHistoryToLocal();
    
    // Track for local duplicate prevention
    await _trackSyncedItem(newItem);
    
    // 🔥 REMOVED: Cloud sync logic - History now uses direct insertion via recordUsage()
    print('🔥 FavoritesService._saveNewHistoryItem: Saved locally (cloud sync via direct insertion)');
  }

  Future<void> _saveHistoryToLocal() async {
    try {
      final box = await _userDataManager.getFavoritesBox();
      final dataToSave = _usageHistory.map((h) => h.toJson()).toList();
      AACLogger.info('🔥 FavoritesService: About to save ${_usageHistory.length} history items with key: $_historyKey', tag: 'FavoritesService');
      AACLogger.info('🔥 FavoritesService: Box name: ${box.name}, Box path: ${box.path}', tag: 'FavoritesService');
      await box.put(_historyKey, dataToSave);
      AACLogger.info('🔥 FavoritesService: ✅ Successfully saved ${_usageHistory.length} history items to local storage', tag: 'FavoritesService');
      
      // Verify the save by immediately reading back
      final readBack = box.get(_historyKey);
      AACLogger.info('🔥 FavoritesService: Verification - Read back data type: ${readBack?.runtimeType}, length: ${readBack is List ? readBack.length : 'N/A'}', tag: 'FavoritesService');
    } catch (e) {
      AACLogger.error('🔥 FavoritesService: Error saving history to local storage: $e', tag: 'FavoritesService');
      rethrow;
    }
  }

  /// DIRECT INSERT to Supabase - bypasses all sync complexity
  Future<void> _insertDirectlyToSupabase(HistoryItem historyItem) async {
    try {
      print('🔥 DIRECT SUPABASE: Starting direct insert for ${historyItem.symbol.label}');
      
      // Use the static methods from SupabaseAACService directly
      // Note: communication_type must be 'phrase', 'word', or 'sentence' per DB constraint
      await SupabaseAACService.saveCommunication(
        messageText: historyItem.symbol.label,
        symbolsUsed: [historyItem.symbol.id ?? historyItem.symbol.label],
        communicationType: 'word', // ✅ Use 'word' instead of 'symbol_tap' (DB constraint compliant)
        contextInfo: {
          'action': historyItem.action,
          'category': historyItem.symbol.category,
          'is_custom': historyItem.symbol.isDefault != true,
          'image_path': historyItem.symbol.imagePath,
          'direct_insert': true, // Mark as direct insert to distinguish from batch sync
          'insertion_timestamp': DateTime.now().toIso8601String(),
          'used_at': historyItem.timestamp.toIso8601String(),
          'symbol_tap': true, // Store the fact that this was a symbol tap in context
        },
      );
      
      print('🔥 DIRECT SUPABASE: ✅ Successfully inserted ${historyItem.symbol.label} to Supabase');
      AACLogger.info('🔥 DIRECT SUPABASE: Successfully inserted ${historyItem.symbol.label} directly to Supabase', tag: 'FavoritesService');
      
    } catch (e) {
      print('🔥 DIRECT SUPABASE: ❌ Error inserting to Supabase: $e');
      AACLogger.error('🔥 DIRECT SUPABASE: Error inserting to Supabase: $e', tag: 'FavoritesService');
      // Don't rethrow - let local operations continue even if cloud sync fails
    }
  }

  /// Sync from cloud to local (useful after login or when data changes elsewhere)
  /// NOTE: Only syncs favorites, NOT history (history uses direct insertion now)
  Future<void> syncFromCloud() async {
    if (!_isInitialized) return;
    
    try {
      await _loadFavorites();
      // 🔥 REMOVED: await _loadHistory(); - History now uses direct insertion, no need to sync on login
      AACLogger.info('FavoritesService: Synced favorites from cloud (history uses direct insertion).', tag: 'FavoritesService');
    } catch (e) {
      AACLogger.error('FavoritesService: Error syncing favorites from cloud: $e', tag: 'FavoritesService');
    }
  }

  /// Sync favorites to Supabase user_favorites table (non-blocking background operation)
  void _syncToSupabase(String symbolId, {required bool isAdd, Symbol? symbol}) {
    // Run in background without blocking local operations
    Future.microtask(() async {
      try {
        if (isAdd && symbol != null) {
          await SupabaseAACService.addToFavorites(
            symbolId,
            symbolLabel: symbol.label,
            symbolData: symbol.toJson(),
            isCustom: symbol.isDefault != true,
          );
          AACLogger.info('FavoritesService: Synced favorite add to user_favorites: $symbolId', tag: 'FavoritesService');
        } else {
          await SupabaseAACService.removeFromFavorites(symbolId);
          AACLogger.info('FavoritesService: Synced favorite removal from user_favorites: $symbolId', tag: 'FavoritesService');
        }
      } catch (e) {
        AACLogger.warning('FavoritesService: user_favorites sync failed for $symbolId: $e', tag: 'FavoritesService');
        // Don't rethrow - local operation should continue working
      }
    });
  }

  /// Load favorites from Supabase and merge with local (bidirectional sync)
  Future<void> syncFromSupabase() async {
    if (!_isInitialized) return;
    
    try {
      print('📥 BIDIRECTIONAL SYNC: Loading favorites from enhanced user_favorites table');
      final supabaseFavorites = await SupabaseAACService.getUserFavorites();
      AACLogger.info('FavoritesService: 📥 MERGE: Loaded ${supabaseFavorites.length} favorites from user_favorites table', tag: 'FavoritesService');
      
      if (supabaseFavorites.isNotEmpty) {
        final localSymbolIds = _favoriteSymbols.map((s) => s.id).toSet();
        int addedCount = 0;
        
        // Add Supabase favorites that aren't in local storage
        for (final favData in supabaseFavorites) {
          final symbolId = favData['symbol_id'] as String;
          
          if (!localSymbolIds.contains(symbolId)) {
            try {
              // Reconstruct Symbol from enhanced schema data
              Map<String, dynamic> symbolData;
              
              if (favData['symbol_data'] != null) {
                // Use complete symbol data from JSONB column
                symbolData = Map<String, dynamic>.from(favData['symbol_data']);
              } else {
                // Fallback: construct from individual columns
                symbolData = {
                  'id': favData['symbol_id'],
                  'label': favData['symbol_label'] ?? favData['symbol_id'],
                  'isDefault': !favData['is_custom'],
                };
              }
              
              // Create Symbol object and add to local favorites
              final symbol = Symbol.fromJson(symbolData);
              _favoriteSymbols.add(symbol);
              addedCount++;
              
              print('✅ MERGE: Added Supabase favorite "${symbol.label}" to local storage');
              
            } catch (e) {
              AACLogger.warning('FavoritesService: Failed to process Supabase favorite $symbolId: $e', tag: 'FavoritesService');
            }
          }
        }
        
        if (addedCount > 0) {
          // Save merged favorites to local storage
          await _saveFavorites();
          _favoritesController.add(List.from(_favoriteSymbols));
          
          print('🔄 MERGE SUCCESS: Added $addedCount favorites from Supabase to local storage');
          AACLogger.info('FavoritesService: 🔄 MERGE COMPLETE: Added $addedCount new favorites from Supabase', tag: 'FavoritesService');
        } else {
          print('✅ SYNC STATUS: Local and Supabase favorites are in sync');
        }
      }
      
    } catch (e) {
      AACLogger.warning('FavoritesService: ❌ BIDIRECTIONAL SYNC: Failed to load from Supabase: $e', tag: 'FavoritesService');
      print('❌ MERGE ERROR: Failed to sync from Supabase: $e');
    }
  }

  /// Force sync existing local data to Supabase (one-time migration)
  Future<void> forceSyncLocalDataToSupabase() async {
    if (!_isInitialized) {
      AACLogger.warning('FavoritesService: Cannot sync - service not initialized', tag: 'FavoritesService');
      return;
    }

    try {
      AACLogger.info('🔄 FavoritesService: Starting forced sync of existing local data to Supabase', tag: 'FavoritesService');
      
      // Force sync favorites if we have any
      if (_favoriteSymbols.isNotEmpty) {
        AACLogger.info('🔄 Syncing ${_favoriteSymbols.length} favorites to Supabase', tag: 'FavoritesService');
        await _userDataManager.setCloudData(_favoritesKey, _favoriteSymbols.map((s) => s.toJson()).toList());
        AACLogger.info('✅ Favorites synced to Supabase', tag: 'FavoritesService');
      } else {
        AACLogger.info('ℹ️  No favorites to sync', tag: 'FavoritesService');
      }
      
      // 🔥 REMOVED: History sync - History now uses direct insertion via recordUsage()
      if (_usageHistory.isNotEmpty) {
        AACLogger.info('ℹ️  History sync skipped (${_usageHistory.length} items) - using direct insertion', tag: 'FavoritesService');
      } else {
        AACLogger.info('ℹ️  No history to sync', tag: 'FavoritesService');
      }
      
      AACLogger.info('🎉 FavoritesService: Forced sync completed successfully!', tag: 'FavoritesService');
      
    } catch (e, stackTrace) {
      AACLogger.error('❌ FavoritesService: Forced sync failed: $e', stackTrace: stackTrace, tag: 'FavoritesService');
    }
  }

  /// Track synced items persistently to prevent duplicates after app restart
  Future<void> _trackSyncedItem(HistoryItem item) async {
    try {
      final box = await _userDataManager.getFavoritesBox();
      final syncedItemsKey = 'synced_history_items';
      
      // Get existing synced items
      final existingSynced = box.get(syncedItemsKey, defaultValue: <String>[]);
      final syncedItems = List<String>.from(existingSynced);
      
      // Create unique key for the item (timestamp + symbol + action)
      final itemKey = '${item.timestamp.millisecondsSinceEpoch}_${item.symbol.id ?? item.symbol.label}_${item.action}';
      
      // Add to synced items if not already present
      if (!syncedItems.contains(itemKey)) {
        syncedItems.add(itemKey);
        
        // Keep only recent items (last 1000) to prevent unlimited growth
        if (syncedItems.length > 1000) {
          syncedItems.removeRange(0, syncedItems.length - 1000);
        }
        
        await box.put(syncedItemsKey, syncedItems);
        print('🔥 FavoritesService._trackSyncedItem: Tracked synced item: $itemKey');
      }
    } catch (e) {
      AACLogger.warning('FavoritesService: Failed to track synced item: $e', tag: 'FavoritesService');
    }
  }

  /// Check if item is already synced to prevent duplicates
  Future<bool> _isItemAlreadySynced(HistoryItem item) async {
    try {
      final box = await _userDataManager.getFavoritesBox();
      final syncedItemsKey = 'synced_history_items';
      
      // Get existing synced items
      final existingSynced = box.get(syncedItemsKey, defaultValue: <String>[]);
      final syncedItems = List<String>.from(existingSynced);
      
      // Create unique key for the item (timestamp + symbol + action)
      final itemKey = '${item.timestamp.millisecondsSinceEpoch}_${item.symbol.id ?? item.symbol.label}_${item.action}';
      
      final isAlreadySynced = syncedItems.contains(itemKey);
      if (isAlreadySynced) {
        print('🔥 FavoritesService._isItemAlreadySynced: Item already synced: $itemKey');
      }
      
      return isAlreadySynced;
    } catch (e) {
      AACLogger.warning('FavoritesService: Failed to check if item synced: $e', tag: 'FavoritesService');
      return false; // If we can't check, assume not synced to be safe
    }
  }

  /// Clean up old synced items to prevent unlimited growth
  Future<void> _cleanupOldSyncedItems() async {
    try {
      final box = await _userDataManager.getFavoritesBox();
      final syncedItemsKey = 'synced_history_items';
      
      // Get existing synced items
      final existingSynced = box.get(syncedItemsKey, defaultValue: <String>[]);
      final syncedItems = List<String>.from(existingSynced);
      
      final int maxItems = 1000; // Keep only last 1000 synced items
      if (syncedItems.length > maxItems) {
        // Keep only the most recent items (assuming they're added chronologically)
        final recentItems = syncedItems.sublist(syncedItems.length - maxItems);
        await box.put(syncedItemsKey, recentItems);
        
        final removedCount = syncedItems.length - recentItems.length;
        print('🧹 FavoritesService._cleanupOldSyncedItems: Cleaned up $removedCount old synced item records');
        AACLogger.info('FavoritesService: Cleaned up $removedCount old synced item records', tag: 'FavoritesService');
      } else {
        print('🧹 FavoritesService._cleanupOldSyncedItems: No cleanup needed (${syncedItems.length}/$maxItems items)');
      }
    } catch (e) {
      AACLogger.warning('FavoritesService: Failed to cleanup old synced items: $e', tag: 'FavoritesService');
    }
  }

  /// Dispose the service and close streams.
  void dispose() {
    _favoritesController.close();
    _historyController.close();
    _symbolChangedController.close();
    _isInitialized = false;
    AACLogger.info('FavoritesService disposed.', tag: 'FavoritesService');
    super.dispose();
  }
}

class HistoryItem {
  final Symbol symbol;
  final DateTime timestamp;
  final String action;
  
  HistoryItem({
    required this.symbol,
    required this.timestamp,
    required this.action,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'action': action,
    };
  }
  
  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    // Handle nested dynamic maps by converting them safely
    var symbolData = json['symbol'];
    Map<String, dynamic> symbolMap;
    if (symbolData is Map<String, dynamic>) {
      symbolMap = symbolData;
    } else if (symbolData is Map) {
      symbolMap = Map<String, dynamic>.from(symbolData);
    } else {
      throw Exception('Invalid symbol data format in HistoryItem: ${symbolData.runtimeType}');
    }
    
    return HistoryItem(
      symbol: Symbol.fromJson(symbolMap),
      timestamp: DateTime.parse(json['timestamp']),
      action: json['action'] ?? 'played',
    );
  }
}
