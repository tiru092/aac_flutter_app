import 'user_data_manager.dart';

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

  // UserDataManager for Firebase UID single source of truth
  final UserDataManager _userDataManager = UserDataManager();

  List<PhraseHistoryItem> _history = [];
  List<PhraseHistoryItem> _favorites = [];

  List<PhraseHistoryItem> get history => List.unmodifiable(_history);
  List<PhraseHistoryItem> get favorites => List.unmodifiable(_favorites);

  Future<void> initialize() async {
    await _userDataManager.initialize();
    await _loadHistory();
    await _loadFavorites();
  }

  Future<void> addPhraseToHistory(String phrase) async {
    if (phrase.trim().isEmpty) return;
    
    try {
      final historyItem = PhraseHistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: phrase,
        timestamp: DateTime.now(),
        isFavorite: false,
      );
      
      // Remove if already exists to avoid duplicates
      _history.removeWhere((h) => h.text == phrase);
      
      // Add to beginning of list
      _history.insert(0, historyItem);
      
      // Keep only last 20 phrases
      if (_history.length > _maxHistorySize) {
        _history = _history.take(_maxHistorySize).toList();
      }
      
      await _saveHistory();
    } catch (e) {
      print('Error adding phrase to history: $e');
    }
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
    if (!_userDataManager.isAuthenticated) return;
    
    try {
      final historyBox = await _userDataManager.getHistoryBox();
      final historyData = historyBox.get(_historyKey);
      
      if (historyData != null) {
        _history = (historyData as List<dynamic>)
            .map((json) => PhraseHistoryItem.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }
    } catch (e) {
      print('Error loading history: $e');
      _history = [];
    }
  }

  Future<void> _loadFavorites() async {
    if (!_userDataManager.isAuthenticated) return;
    
    try {
      final historyBox = await _userDataManager.getHistoryBox();
      final favoritesData = historyBox.get(_favoritesKey);
      
      if (favoritesData != null) {
        _favorites = (favoritesData as List<dynamic>)
            .map((json) => PhraseHistoryItem.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }
    } catch (e) {
      print('Error loading favorites: $e');
      _favorites = [];
    }
  }

  Future<void> _saveHistory() async {
    if (!_userDataManager.isAuthenticated) return;
    
    try {
      final historyBox = await _userDataManager.getHistoryBox();
      final historyData = _history.map((h) => h.toJson()).toList();
      await historyBox.put(_historyKey, historyData);
      
      // Also sync to cloud
      await _userDataManager.setCloudData('phrase_history', historyData);
    } catch (e) {
      print('Error saving history: $e');
    }
  }

  Future<void> _saveFavorites() async {
    if (!_userDataManager.isAuthenticated) return;
    
    try {
      final historyBox = await _userDataManager.getHistoryBox();
      final favoritesData = _favorites.map((f) => f.toJson()).toList();
      await historyBox.put(_favoritesKey, favoritesData);
      
      // Also sync to cloud
      await _userDataManager.setCloudData('phrase_favorites', favoritesData);
    } catch (e) {
      print('Error saving favorites: $e');
    }
  }
}