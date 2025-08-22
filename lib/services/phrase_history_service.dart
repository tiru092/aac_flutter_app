import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PhraseHistoryItem {
  final String id;
  final String text;
  final DateTime timestamp;
  final bool isFavorite;

  PhraseHistoryItem({
    required this.id,
    required this.text,
    required this.timestamp,
    this.isFavorite = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
    'isFavorite': isFavorite,
  };

  factory PhraseHistoryItem.fromJson(Map<String, dynamic> json) => PhraseHistoryItem(
    id: json['id'],
    text: json['text'],
    timestamp: DateTime.parse(json['timestamp']),
    isFavorite: json['isFavorite'] ?? false,
  );

  PhraseHistoryItem copyWith({
    String? id,
    String? text,
    DateTime? timestamp,
    bool? isFavorite,
  }) => PhraseHistoryItem(
    id: id ?? this.id,
    text: text ?? this.text,
    timestamp: timestamp ?? this.timestamp,
    isFavorite: isFavorite ?? this.isFavorite,
  );
}

class PhraseHistoryService {
  static const int _maxHistorySize = 20;
  static const String _historyKey = 'phrase_history';
  static const String _favoritesKey = 'phrase_favorites';

  static final PhraseHistoryService _instance = PhraseHistoryService._internal();
  factory PhraseHistoryService() => _instance;
  PhraseHistoryService._internal();

  List<PhraseHistoryItem> _history = [];
  List<PhraseHistoryItem> _favorites = [];

  List<PhraseHistoryItem> get history => List.unmodifiable(_history);
  List<PhraseHistoryItem> get favorites => List.unmodifiable(_favorites);

  Future<void> initialize() async {
    await _loadHistory();
    await _loadFavorites();
  }

  Future<void> addToHistory(String text) async {
    if (text.trim().isEmpty) return;

    // Check if this phrase already exists in recent history (last 3 items)
    final recentTexts = _history.take(3).map((h) => h.text.toLowerCase()).toList();
    if (recentTexts.contains(text.toLowerCase())) {
      return; // Don't add duplicates of recent phrases
    }

    final item = PhraseHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      timestamp: DateTime.now(),
    );

    _history.insert(0, item); // Add to beginning (most recent)

    // Maintain ring buffer size
    if (_history.length > _maxHistorySize) {
      _history = _history.take(_maxHistorySize).toList();
    }

    await _saveHistory();
  }

  Future<void> toggleFavorite(PhraseHistoryItem item) async {
    if (item.isFavorite) {
      // Remove from favorites
      _favorites.removeWhere((f) => f.id == item.id);
      
      // Update in history if exists
      final historyIndex = _history.indexWhere((h) => h.text == item.text);
      if (historyIndex != -1) {
        _history[historyIndex] = _history[historyIndex].copyWith(isFavorite: false);
      }
    } else {
      // Add to favorites
      final favoriteItem = item.copyWith(isFavorite: true);
      _favorites.insert(0, favoriteItem); // Add to beginning
      
      // Update in history if exists
      final historyIndex = _history.indexWhere((h) => h.text == item.text);
      if (historyIndex != -1) {
        _history[historyIndex] = _history[historyIndex].copyWith(isFavorite: true);
      }
    }

    await _saveFavorites();
    await _saveHistory();
  }

  Future<void> reorderFavorites(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _favorites.removeAt(oldIndex);
    _favorites.insert(newIndex, item);
    await _saveFavorites();
  }

  Future<void> removeFavorite(String id) async {
    _favorites.removeWhere((f) => f.id == id);
    
    // Update in history if exists
    final historyIndex = _history.indexWhere((h) => h.id == id);
    if (historyIndex != -1) {
      _history[historyIndex] = _history[historyIndex].copyWith(isFavorite: false);
    }
    
    await _saveFavorites();
    await _saveHistory();
  }

  Future<void> clearHistory() async {
    _history.clear();
    await _saveHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);
      
      if (historyJson != null) {
        final List<dynamic> historyList = jsonDecode(historyJson);
        _history = historyList
            .map((json) => PhraseHistoryItem.fromJson(json))
            .toList();
      }
    } catch (e) {
      print('Error loading history: $e');
      _history = [];
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_favoritesKey);
      
      if (favoritesJson != null) {
        final List<dynamic> favoritesList = jsonDecode(favoritesJson);
        _favorites = favoritesList
            .map((json) => PhraseHistoryItem.fromJson(json))
            .toList();
      }
    } catch (e) {
      print('Error loading favorites: $e');
      _favorites = [];
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = jsonEncode(_history.map((h) => h.toJson()).toList());
      await prefs.setString(_historyKey, historyJson);
    } catch (e) {
      print('Error saving history: $e');
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = jsonEncode(_favorites.map((f) => f.toJson()).toList());
      await prefs.setString(_favoritesKey, favoritesJson);
    } catch (e) {
      print('Error saving favorites: $e');
    }
  }
}