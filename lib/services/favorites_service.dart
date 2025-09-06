import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/symbol.dart';

/// Production-ready Favorites Service
/// Manages favorite symbols and history of played images/sounds
/// Designed for ASD users to easily access frequently used items
class FavoritesService extends ChangeNotifier {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  // Storage keys
  static const String _favoritesKey = 'user_favorites';
  static const String _historyKey = 'usage_history';
  
  // Data
  List<Symbol> _favoriteSymbols = [];
  List<HistoryItem> _usageHistory = [];
  SharedPreferences? _prefs;
  bool _isInitialized = false;
  
  // Streams for real-time updates
  final StreamController<List<Symbol>> _favoritesController = 
      StreamController<List<Symbol>>.broadcast();
  final StreamController<List<HistoryItem>> _historyController = 
      StreamController<List<HistoryItem>>.broadcast();
  
  // Getters
  List<Symbol> get favoriteSymbols => List.unmodifiable(_favoriteSymbols);
  List<HistoryItem> get usageHistory => List.unmodifiable(_usageHistory);
  Stream<List<Symbol>> get favoritesStream => _favoritesController.stream;
  Stream<List<HistoryItem>> get historyStream => _historyController.stream;
  bool get isInitialized => _isInitialized;
  
  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Try to load data with aggressive error handling
      try {
        await _loadFavorites();
      } catch (e) {
        debugPrint('FavoritesService: Error loading favorites, clearing data: $e');
        await _clearAllData();
      }
      
      try {
        await _loadHistory();
      } catch (e) {
        debugPrint('FavoritesService: Error loading history, clearing data: $e');
        await _clearHistoryData();
      }
      
      _isInitialized = true;
      debugPrint('FavoritesService: Initialized successfully');
    } catch (e) {
      debugPrint('FavoritesService: Initialization error: $e');
      // Initialize with empty data if everything fails
      _favoriteSymbols = [];
      _usageHistory = [];
      _isInitialized = true;
    }
  }
  
  /// Load favorites from storage
  Future<void> _loadFavorites() async {
    try {
      final favoritesJson = _prefs?.getString(_favoritesKey);
      if (favoritesJson != null) {
        final List<dynamic> favoritesData = jsonDecode(favoritesJson);
        _favoriteSymbols = favoritesData
            .map((data) => Symbol.fromJson(data))
            .toList();
      }
      _favoritesController.add(_favoriteSymbols);
    } catch (e) {
      debugPrint('Error loading favorites: $e');
      _favoriteSymbols = [];
    }
  }
  
  /// Load history from storage
  Future<void> _loadHistory() async {
    try {
      final historyJson = _prefs?.getString(_historyKey);
      if (historyJson != null) {
        // Check if the data is too large before parsing
        if (historyJson.length > 1000000) { // 1MB limit
          debugPrint('History data too large, clearing it');
          await _clearHistoryData();
          return;
        }
        
        final List<dynamic> historyData = jsonDecode(historyJson);
        
        // Limit to maximum 50 items for better performance
        final limitedData = historyData.take(50).toList();
        
        _usageHistory = limitedData
            .map((data) => HistoryItem.fromJson(data))
            .toList();
        
        // Sort by timestamp (most recent first)
        _usageHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
      _historyController.add(_usageHistory);
    } catch (e) {
      debugPrint('Error loading history: $e');
      _usageHistory = [];
      await _clearHistoryData();
    }
  }
  
  /// Add symbol to favorites
  Future<void> addToFavorites(Symbol symbol) async {
    if (!_isInitialized) {
      debugPrint('FavoritesService not initialized, cannot add to favorites');
      return;
    }
    
    try {
      debugPrint('AddToFavorites: Attempting to add symbol ${symbol.label} (ID: ${symbol.id})');
      
      // Check if already in favorites (handle null ids)
      bool isAlreadyFavorite = false;
      if (symbol.id != null) {
        isAlreadyFavorite = _favoriteSymbols.any((fav) => fav.id == symbol.id);
        debugPrint('AddToFavorites: Checking by ID - Already favorite: $isAlreadyFavorite');
      } else {
        // Fallback for symbols without IDs: match by label and category
        isAlreadyFavorite = _favoriteSymbols.any((fav) => 
          fav.label == symbol.label && fav.category == symbol.category);
        debugPrint('AddToFavorites: Checking by label+category (NO ID) - Already favorite: $isAlreadyFavorite');
        debugPrint('WARNING: Adding symbol without ID to favorites: ${symbol.label}');
      }
      
      if (isAlreadyFavorite) {
        debugPrint('AddToFavorites: Symbol ${symbol.label} is already in favorites, skipping');
        return; // Already in favorites
      }
      
      _favoriteSymbols.add(symbol);
      debugPrint('AddToFavorites: Successfully added ${symbol.label} to favorites list');
      
      await _saveFavorites();
      _favoritesController.add(_favoriteSymbols);
      notifyListeners();
      
      debugPrint('Added to favorites: ${symbol.label}');
    } catch (e) {
      debugPrint('Error adding to favorites: $e');
    }
  }
  
  /// Remove symbol from favorites
  Future<void> removeFromFavorites(Symbol symbol) async {
    if (!_isInitialized) {
      debugPrint('FavoritesService: Not initialized, cannot remove');
      return;
    }
    
    try {
      debugPrint('Attempting to remove symbol: ${symbol.label}, ID: ${symbol.id}');
      debugPrint('Current favorites count: ${_favoriteSymbols.length}');
      
      if (symbol.id != null) {
        final initialCount = _favoriteSymbols.length;
        _favoriteSymbols.removeWhere((fav) => fav.id == symbol.id);
        final newCount = _favoriteSymbols.length;
        
        debugPrint('Removed ${initialCount - newCount} items. New count: $newCount');
        
        await _saveFavorites();
        _favoritesController.add(_favoriteSymbols);
        notifyListeners();
        
        debugPrint('Successfully removed from favorites: ${symbol.label}');
      } else {
        // Fallback: try to match by label and category if ID is null
        debugPrint('Symbol ID is null, trying to match by label and category');
        final initialCount = _favoriteSymbols.length;
        _favoriteSymbols.removeWhere((fav) => 
          fav.label == symbol.label && fav.category == symbol.category);
        final newCount = _favoriteSymbols.length;
        
        debugPrint('Removed ${initialCount - newCount} items by label/category match. New count: $newCount');
        
        if (newCount < initialCount) {
          await _saveFavorites();
          _favoritesController.add(_favoriteSymbols);
          notifyListeners();
          debugPrint('Successfully removed from favorites: ${symbol.label}');
        }
      }
    } catch (e) {
      debugPrint('Error removing from favorites: $e');
    }
  }
  
  /// Check if symbol is in favorites
  bool isFavorite(Symbol symbol) {
    if (!_isInitialized) {
      debugPrint('FavoritesService not initialized, returning false for isFavorite check');
      return false;
    }
    
    if (symbol.id != null) {
      final result = _favoriteSymbols.any((fav) => fav.id == symbol.id);
      debugPrint('isFavorite: Checking symbol ${symbol.label} (ID: ${symbol.id}) - Result: $result');
      return result;
    } else {
      // Fallback for symbols without IDs: match by label and category
      final result = _favoriteSymbols.any((fav) => 
        fav.label == symbol.label && fav.category == symbol.category);
      debugPrint('isFavorite: Checking symbol ${symbol.label} (NO ID, using label+category) - Result: $result');
      
      // Log warning for symbols without IDs
      if (result) {
        debugPrint('WARNING: Symbol ${symbol.label} matched as favorite using fallback method (no ID). This could cause false positives.');
      }
      
      return result;
    }
  }
  
  /// Record symbol usage in history
  Future<void> recordUsage(Symbol symbol, {String? action}) async {
    if (!_isInitialized) return;
    
    try {
      final historyItem = HistoryItem(
        symbol: symbol,
        timestamp: DateTime.now(),
        action: action ?? 'played',
      );
      
      // Add to beginning of list (most recent first)
      _usageHistory.insert(0, historyItem);
      
      // Keep only last 50 items to prevent data bloat
      if (_usageHistory.length > 50) {
        _usageHistory = _usageHistory.take(50).toList();
      }
      
      await _saveHistory();
      _historyController.add(_usageHistory);
      notifyListeners();
      
      debugPrint('Recorded usage: ${symbol.label} - $action');
    } catch (e) {
      debugPrint('Error recording usage: $e');
    }
  }
  
  /// Get recent history items
  List<HistoryItem> getRecentHistory({int limit = 20}) {
    return _usageHistory.take(limit).toList();
  }
  
  /// Clear all favorites
  Future<void> clearFavorites() async {
    if (!_isInitialized) return;
    
    try {
      _favoriteSymbols.clear();
      await _saveFavorites();
      _favoritesController.add(_favoriteSymbols);
      notifyListeners();
      
      debugPrint('Cleared all favorites');
    } catch (e) {
      debugPrint('Error clearing favorites: $e');
    }
  }
  
  /// Clear all history
  Future<void> clearHistory() async {
    if (!_isInitialized) return;
    
    try {
      _usageHistory.clear();
      await _saveHistory();
      _historyController.add(_usageHistory);
      notifyListeners();
      
      debugPrint('Cleared all history');
    } catch (e) {
      debugPrint('Error clearing history: $e');
    }
  }
  
  /// Save favorites to storage
  Future<void> _saveFavorites() async {
    try {
      final favoritesJson = jsonEncode(
        _favoriteSymbols.map((symbol) => symbol.toJson()).toList(),
      );
      await _prefs?.setString(_favoritesKey, favoritesJson);
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }
  
  /// Save history to storage
  Future<void> _saveHistory() async {
    try {
      final historyJson = jsonEncode(
        _usageHistory.map((item) => item.toJson()).toList(),
      );
      await _prefs?.setString(_historyKey, historyJson);
    } catch (e) {
      debugPrint('Error saving history: $e');
    }
  }
  
  /// Clear all data (internal helper)
  Future<void> _clearAllData() async {
    try {
      await _prefs?.remove(_favoritesKey);
      await _prefs?.remove(_historyKey);
      _favoriteSymbols = [];
      _usageHistory = [];
      _favoritesController.add(_favoriteSymbols);
      _historyController.add(_usageHistory);
    } catch (e) {
      debugPrint('Error clearing all data: $e');
    }
  }
  
  /// Clear history data (internal helper)
  Future<void> _clearHistoryData() async {
    try {
      await _prefs?.remove(_historyKey);
      _usageHistory = [];
      _historyController.add(_usageHistory);
    } catch (e) {
      debugPrint('Error clearing history data: $e');
    }
  }

  @override
  void dispose() {
    _favoritesController.close();
    _historyController.close();
    super.dispose();
  }
}

/// History item model
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
