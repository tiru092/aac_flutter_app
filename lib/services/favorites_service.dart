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

  // Data
  List<Symbol> _favoriteSymbols = [];
  List<HistoryItem> _usageHistory = [];

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
      print('🔥 FavoritesService: History loaded, setting initialized flag...');

      _isInitialized = true;
      print('🔥 FavoritesService: ✅ Initialization completed successfully for UID: $uid');
      AACLogger.info('FavoritesService: Initialized successfully for UID: $uid', tag: 'FavoritesService');
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

  /// Load history from storage.
  Future<void> _loadHistory() async {
    print('🔥 FavoritesService._loadHistory: Starting...');
    AACLogger.info('FavoritesService: Starting to load history...', tag: 'FavoritesService');
    try {
      // Try cloud first
      print('🔥 FavoritesService._loadHistory: Checking cloud data...');
      AACLogger.info('FavoritesService: Attempting to load history from cloud...', tag: 'FavoritesService');
      final cloudHistory = await _userDataManager.getCloudData(_historyKey);
      if (cloudHistory != null && cloudHistory is List) {
        print('🔥 FavoritesService._loadHistory: Found ${cloudHistory.length} items in cloud');
        AACLogger.info('FavoritesService: Found ${cloudHistory.length} history items in cloud', tag: 'FavoritesService');
        _usageHistory = cloudHistory.map((data) {
          // Handle various data formats safely
          Map<String, dynamic> itemMap;
          if (data is Map<String, dynamic>) {
            itemMap = data;
          } else if (data is Map) {
            itemMap = Map<String, dynamic>.from(data);
          } else {
            throw Exception('Invalid history item format: ${data.runtimeType}');
          }
          return HistoryItem.fromJson(itemMap);
        }).toList();
        await _saveHistoryToLocal();
        AACLogger.info('FavoritesService: Successfully loaded ${_usageHistory.length} history items from cloud.', tag: 'FavoritesService');
      } else {
        // Fallback to local storage
        print('🔥 FavoritesService._loadHistory: No cloud data, checking local storage...');
        AACLogger.info('🔥 FavoritesService: No cloud history data found, trying local storage...', tag: 'FavoritesService');
        final localBox = await _userDataManager.getFavoritesBox();
        print('🔥 FavoritesService._loadHistory: Got box - name: ${localBox.name}');
        AACLogger.info('🔥 FavoritesService: Got local box for history - name: ${localBox.name}, path: ${localBox.path}', tag: 'FavoritesService');
        AACLogger.info('🔥 FavoritesService: Box keys: ${localBox.keys.toList()}', tag: 'FavoritesService');
        print('🔥 FavoritesService._loadHistory: Box keys: ${localBox.keys.toList()}');
        AACLogger.info('🔥 FavoritesService: Looking for key: $_historyKey', tag: 'FavoritesService');
        final localData = localBox.get(_historyKey);
        if (localData != null) {
          print('🔥 FavoritesService._loadHistory: Found local data, length: ${localData is List ? localData.length : 'N/A'}');
          print('🔥 FavoritesService._loadHistory: Local data type: ${localData.runtimeType}');
          AACLogger.info('🔥 FavoritesService: Found local history data of type: ${localData.runtimeType}, length: ${localData is List ? localData.length : 'N/A'}', tag: 'FavoritesService');
          
          if (localData is List) {
            print('🔥 FavoritesService._loadHistory: Processing ${localData.length} items...');
            List<HistoryItem> historyItems = [];
            for (int i = 0; i < localData.length; i++) {
              final item = localData[i];
              print('🔥 FavoritesService._loadHistory: Item $i type: ${item.runtimeType}');
              try {
                Map<String, dynamic> itemMap;
                if (item is Map<String, dynamic>) {
                  itemMap = item;
                  print('🔥 FavoritesService._loadHistory: Item $i is already Map<String, dynamic>');
                } else if (item is Map) {
                  itemMap = Map<String, dynamic>.from(item);
                  print('🔥 FavoritesService._loadHistory: Item $i converted from Map to Map<String, dynamic>');
                } else {
                  print('🔥 FavoritesService._loadHistory: Item $i invalid format: ${item.runtimeType}, value: $item');
                  throw Exception('Invalid history item format: ${item.runtimeType}');
                }
                final historyItem = HistoryItem.fromJson(itemMap);
                historyItems.add(historyItem);
                print('🔥 FavoritesService._loadHistory: Item $i processed successfully');
              } catch (e) {
                print('🔥 FavoritesService._loadHistory: Error processing item $i: $e');
                continue; // Skip invalid items
              }
            }
            _usageHistory = historyItems;
          } else {
            print('🔥 FavoritesService._loadHistory: Local data is not a List: ${localData.runtimeType}');
            _usageHistory = [];
          }
          print('🔥 FavoritesService._loadHistory: ✅ Loaded ${_usageHistory.length} history items from local');
          AACLogger.info('🔥 FavoritesService: ✅ Successfully loaded ${_usageHistory.length} history items from local Hive', tag: 'FavoritesService');
        } else {
          print('🔥 FavoritesService._loadHistory: ❌ No local data found for key: $_historyKey');
          AACLogger.info('🔥 FavoritesService: ❌ No local history data found for key: $_historyKey', tag: 'FavoritesService');
          _usageHistory = [];
        }
      }
    } catch (e) {
      print('🔥 FavoritesService._loadHistory: ❌ Error: $e');
      AACLogger.error('FavoritesService: Error loading history: $e', tag: 'FavoritesService');
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
        
        // Sync to Supabase (non-blocking)
        _syncToSupabase(symbol.id ?? symbol.label, isAdd: true);
        
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
        
        // Sync removal to Supabase (non-blocking)
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

  /// Add an item to the usage history, now with a required action.
  Future<void> recordUsage(Symbol symbol, {required String action}) async {
    print('🔥 FavoritesService.recordUsage: Called for ${symbol.label} with action: $action, initialized: $_isInitialized');
    AACLogger.info('🔥 FavoritesService.recordUsage called - initialized: $_isInitialized, symbol: ${symbol.label}, action: $action', tag: 'FavoritesService');
    if (!_isInitialized) {
      print('🔥 FavoritesService.recordUsage: ❌ Service not initialized!');
      AACLogger.warning('FavoritesService not initialized, cannot record usage.', tag: 'FavoritesService');
      return;
    }
    try {
      final historyItem = HistoryItem(symbol: symbol, timestamp: DateTime.now(), action: action);
      _usageHistory.insert(0, historyItem);
      print('🔥 FavoritesService.recordUsage: Added item, total count: ${_usageHistory.length}');
      AACLogger.info('🔥 FavoritesService: Added history item, total count: ${_usageHistory.length}', tag: 'FavoritesService');
      
      // Keep history trimmed to 50 items
      if (_usageHistory.length > 50) {
        _usageHistory = _usageHistory.sublist(0, 50);
      }
      print('🔥 FavoritesService.recordUsage: About to save history...');
      await _saveHistory();
      print('🔥 FavoritesService.recordUsage: ✅ Successfully saved history');
      AACLogger.info('🔥 FavoritesService: Successfully recorded and saved usage of ${symbol.label} with action: $action', tag: 'FavoritesService');
    } catch (e) {
      print('🔥 FavoritesService.recordUsage: ❌ Error: $e');
      AACLogger.error('🔥 FavoritesService: Error recording usage: $e', tag: 'FavoritesService');
      rethrow;
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

  /// Save history to both local and cloud storage.
  Future<void> _saveHistory() async {
    _historyController.add(_usageHistory);
    await _saveHistoryToLocal();
    await _userDataManager.setCloudData(_historyKey, _usageHistory.map((h) => h.toJson()).toList());
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

  /// Sync from cloud to local (useful after login or when data changes elsewhere)
  Future<void> syncFromCloud() async {
    if (!_isInitialized) return;
    
    try {
      await _loadFavorites();
      await _loadHistory();
      AACLogger.info('FavoritesService: Synced from cloud.', tag: 'FavoritesService');
    } catch (e) {
      AACLogger.error('FavoritesService: Error syncing from cloud: $e', tag: 'FavoritesService');
    }
  }

  /// Sync favorites to Supabase (non-blocking background operation)
  void _syncToSupabase(String symbolId, {required bool isAdd}) {
    // Run in background without blocking local operations
    Future.microtask(() async {
      try {
        if (isAdd) {
          await SupabaseAACService.addToFavorites(symbolId);
          AACLogger.info('FavoritesService: Synced favorite add to Supabase: $symbolId', tag: 'FavoritesService');
        } else {
          await SupabaseAACService.removeFromFavorites(symbolId);
          AACLogger.info('FavoritesService: Synced favorite removal to Supabase: $symbolId', tag: 'FavoritesService');
        }
      } catch (e) {
        AACLogger.warning('FavoritesService: Supabase sync failed for $symbolId: $e', tag: 'FavoritesService');
        // Don't rethrow - local operation should continue working
      }
    });
  }

  /// Load favorites from Supabase and merge with local (call during initialization)
  Future<void> syncFromSupabase() async {
    if (!_isInitialized) return;
    
    try {
      final supabaseFavorites = await SupabaseAACService.getUserFavorites();
      AACLogger.info('FavoritesService: Loaded ${supabaseFavorites.length} favorites from Supabase', tag: 'FavoritesService');
      
      // TODO: Merge logic can be implemented here based on timestamps
      // For now, local storage remains the source of truth
    } catch (e) {
      AACLogger.warning('FavoritesService: Failed to load from Supabase: $e', tag: 'FavoritesService');
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
