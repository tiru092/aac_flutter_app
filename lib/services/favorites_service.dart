import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/symbol.dart';
import 'user_data_manager.dart';
import '../utils/aac_logger.dart';

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
    if (_isInitialized) return;

    try {
      AACLogger.info('FavoritesService: Initializing with UID: $uid', tag: 'FavoritesService');
      _currentUid = uid;
      _userDataManager = userDataManager;

      await _loadFavorites();
      await _loadHistory();

      _isInitialized = true;
      AACLogger.info('FavoritesService: Initialized successfully for UID: $uid', tag: 'FavoritesService');
    } catch (e, stacktrace) {
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
    try {
      final cloudHistory = await _userDataManager.getCloudData(_historyKey);
      if (cloudHistory != null && cloudHistory is List) {
        _usageHistory = cloudHistory.map((data) => HistoryItem.fromJson(Map<String, dynamic>.from(data))).toList();
        await _saveHistoryToLocal();
        AACLogger.info('FavoritesService: Loaded ${_usageHistory.length} history items from cloud.', tag: 'FavoritesService');
      } else {
        final localBox = await _userDataManager.getFavoritesBox();
        final localData = localBox.get(_historyKey);
        if (localData != null) {
          _usageHistory = (localData as List<dynamic>).map((data) => HistoryItem.fromJson(Map<String, dynamic>.from(data))).toList();
          AACLogger.info('FavoritesService: Loaded ${_usageHistory.length} history items from local Hive.', tag: 'FavoritesService');
        }
      }
    } catch (e) {
      AACLogger.error('FavoritesService: Error loading history: $e', tag: 'FavoritesService');
      _usageHistory = [];
    } finally {
      _usageHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));
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
    if (!_isInitialized) {
      AACLogger.warning('FavoritesService not initialized, cannot record usage.', tag: 'FavoritesService');
      return;
    }
    try {
      final historyItem = HistoryItem(symbol: symbol, timestamp: DateTime.now(), action: action);
      _usageHistory.insert(0, historyItem);
      // Keep history trimmed to 50 items
      if (_usageHistory.length > 50) {
        _usageHistory = _usageHistory.sublist(0, 50);
      }
      await _saveHistory();
      AACLogger.info('Recorded usage of ${symbol.label} with action: $action.', tag: 'FavoritesService');
    } catch (e) {
      AACLogger.error('Error recording usage: $e', tag: 'FavoritesService');
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
    final box = await _userDataManager.getFavoritesBox();
    await box.put(_historyKey, _usageHistory.map((h) => h.toJson()).toList());
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
    return HistoryItem(
      symbol: Symbol.fromJson(json['symbol']),
      timestamp: DateTime.parse(json['timestamp']),
      action: json['action'] ?? 'played',
    );
  }
}
