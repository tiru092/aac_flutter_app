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
      await _loadFavorites();
      await _loadHistory();
      _isInitialized = true;
      debugPrint('FavoritesService: Initialized successfully');
    } catch (e) {
      debugPrint('FavoritesService: Initialization error: $e');
      rethrow;
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
        final List<dynamic> historyData = jsonDecode(historyJson);
        _usageHistory = historyData
            .map((data) => HistoryItem.fromJson(data))
            .toList();
        
        // Sort by timestamp (most recent first)
        _usageHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
        // Keep only last 100 items for performance
        if (_usageHistory.length > 100) {
          _usageHistory = _usageHistory.take(100).toList();
          await _saveHistory(); // Save the trimmed list
        }
      }
      _historyController.add(_usageHistory);
    } catch (e) {
      debugPrint('Error loading history: $e');
      _usageHistory = [];
    }
  }
  
  /// Add symbol to favorites
  Future<void> addToFavorites(Symbol symbol) async {
    if (!_isInitialized) return;
    
    try {
      // Check if already in favorites (handle null ids)
      if (symbol.id != null && _favoriteSymbols.any((fav) => fav.id == symbol.id)) {
        return; // Already in favorites
      }
      
      _favoriteSymbols.add(symbol);
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
    if (!_isInitialized) return;
    
    try {
      if (symbol.id != null) {
        _favoriteSymbols.removeWhere((fav) => fav.id == symbol.id);
        await _saveFavorites();
        _favoritesController.add(_favoriteSymbols);
        notifyListeners();
        
        debugPrint('Removed from favorites: ${symbol.label}');
      }
    } catch (e) {
      debugPrint('Error removing from favorites: $e');
    }
  }
  
  /// Check if symbol is in favorites
  bool isFavorite(Symbol symbol) {
    if (symbol.id == null) return false;
    return _favoriteSymbols.any((fav) => fav.id == symbol.id);
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
      
      // Keep only last 100 items
      if (_usageHistory.length > 100) {
        _usageHistory = _usageHistory.take(100).toList();
      }
      
      await _saveHistory();
      _historyController.add(_usageHistory);
      notifyListeners();
      
      debugPrint('Recorded usage: ${symbol.label} - $action');
    } catch (e) {
      debugPrint('Error recording usage: $e');
    }
  }
  
  /// Get most frequently used symbols
  List<Symbol> getMostUsedSymbols({int limit = 10}) {
    final symbolCounts = <String, int>{};
    final symbolMap = <String, Symbol>{};
    
    for (final item in _usageHistory) {
      final symbolId = item.symbol.id;
      if (symbolId != null) {
        symbolCounts[symbolId] = (symbolCounts[symbolId] ?? 0) + 1;
        symbolMap[symbolId] = item.symbol;
      }
    }
    
    final sortedEntries = symbolCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEntries
        .take(limit)
        .map((entry) => symbolMap[entry.key]!)
        .toList();
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
