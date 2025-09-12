import 'dart:async';
import 'package:flutter/foundation.dart';
import '../utils/aac_logger.dart';
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

class PhraseHistoryService extends ChangeNotifier {
  static const int _maxHistorySize = 50;
  static const String _historyKey = 'phrase_history';
  static const String _favoritesKey = 'phrase_favorites';

  late UserDataManager _userDataManager;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  List<PhraseHistoryItem> _history = [];
  List<PhraseHistoryItem> _favorites = [];

  List<PhraseHistoryItem> get history => List.unmodifiable(_history);
  List<PhraseHistoryItem> get favorites => List.unmodifiable(_favorites);

  final StreamController<List<PhraseHistoryItem>> _historyController = StreamController.broadcast();
  Stream<List<PhraseHistoryItem>> get historyStream => _historyController.stream;

  final StreamController<List<PhraseHistoryItem>> _favoritesController = StreamController.broadcast();
  Stream<List<PhraseHistoryItem>> get favoritesStream => _favoritesController.stream;

  Future<void> initializeWithUid(String uid, UserDataManager userDataManager) async {
    if (_isInitialized) {
      AACLogger.warning('PhraseHistoryService already initialized.', tag: 'PhraseHistoryService');
      return;
    }
    AACLogger.info('Initializing PhraseHistoryService with UID: $uid', tag: 'PhraseHistoryService');
    _userDataManager = userDataManager;

    await _loadHistory();
    await _loadFavorites();
    
    _isInitialized = true;
    notifyListeners();
    AACLogger.info('PhraseHistoryService initialized successfully.', tag: 'PhraseHistoryService');
  }

  Future<void> addPhraseToHistory(String phrase) async {
    if (!_isInitialized) {
      AACLogger.warning('Service not initialized, cannot add phrase.', tag: 'PhraseHistoryService');
      return;
    }
    if (phrase.trim().isEmpty) return;
    
    try {
      final historyItem = PhraseHistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: phrase,
        timestamp: DateTime.now(),
      );
      
      _history.removeWhere((h) => h.text == phrase);
      _history.insert(0, historyItem);
      
      if (_history.length > _maxHistorySize) {
        _history = _history.take(_maxHistorySize).toList();
      }
      
      await _saveHistory();
      notifyListeners();
    } catch (e) {
      AACLogger.error('Error adding phrase to history: $e', tag: 'PhraseHistoryService');
    }
  }

  Future<void> toggleFavorite(PhraseHistoryItem item) async {
    if (!_isInitialized) return;

    final bool isCurrentlyFavorite = _favorites.any((f) => f.id == item.id);
    
    if (isCurrentlyFavorite) {
      _favorites.removeWhere((f) => f.id == item.id);
    } else {
      _favorites.insert(0, item.copyWith(isFavorite: true));
    }

    // Update the item's state in the main history list as well
    final historyIndex = _history.indexWhere((h) => h.id == item.id);
    if (historyIndex != -1) {
      _history[historyIndex] = _history[historyIndex].copyWith(isFavorite: !isCurrentlyFavorite);
    }

    await _saveFavorites();
    await _saveHistory(); // Save history in case an item's favorite status changed
    notifyListeners();
  }

  Future<void> reorderFavorites(int oldIndex, int newIndex) async {
    if (!_isInitialized) return;
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _favorites.removeAt(oldIndex);
    _favorites.insert(newIndex, item);
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> removeFavorite(String id) async {
    if (!_isInitialized) return;
    _favorites.removeWhere((f) => f.id == id);
    
    final historyIndex = _history.indexWhere((h) => h.id == id);
    if (historyIndex != -1) {
      _history[historyIndex] = _history[historyIndex].copyWith(isFavorite: false);
    }
    
    await _saveFavorites();
    await _saveHistory();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    if (!_isInitialized) return;
    _history.clear();
    await _saveHistory();
    notifyListeners();
  }

  Future<void> _loadHistory() async {
    try {
      final historyData = await _userDataManager.getCloudData(_historyKey);
      if (historyData != null && historyData is List) {
        _history = historyData.map((data) => PhraseHistoryItem.fromJson(Map<String, dynamic>.from(data))).toList();
      } else {
        // Fallback to local if cloud is empty/invalid
        final box = _userDataManager.userPhraseHistoryBox;
        final localData = box.get(_historyKey);
        if (localData != null && localData is List) {
           _history = localData.map((data) => PhraseHistoryItem.fromJson(Map<String, dynamic>.from(data))).toList();
        }
      }
      _historyController.add(_history);
      notifyListeners();
    } catch (e) {
      AACLogger.error('Error loading phrase history: $e', tag: 'PhraseHistoryService');
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final favoritesData = await _userDataManager.getCloudData(_favoritesKey);
      if (favoritesData != null && favoritesData is List) {
        _favorites = favoritesData.map((data) => PhraseHistoryItem.fromJson(Map<String, dynamic>.from(data))).toList();
      } else {
        // Fallback to local
        final box = _userDataManager.userPhraseHistoryBox;
        final localData = box.get(_favoritesKey);
        if (localData != null && localData is List) {
          _favorites = localData.map((data) => PhraseHistoryItem.fromJson(Map<String, dynamic>.from(data))).toList();
        }
      }
      _favoritesController.add(_favorites);
      notifyListeners();
    } catch (e) {
      AACLogger.error('Error loading phrase favorites: $e', tag: 'PhraseHistoryService');
    }
  }

  Future<void> _saveHistory() async {
    _historyController.add(_history);
    await _saveHistoryToLocal();
    await _userDataManager.setCloudData(_historyKey, _history.map((h) => h.toJson()).toList());
  }

  Future<void> _saveHistoryToLocal() async {
    final box = _userDataManager.userPhraseHistoryBox;
    await box.put(_historyKey, _history.map((h) => h.toJson()).toList());
  }

  Future<void> _saveFavorites() async {
    _favoritesController.add(_favorites);
    await _saveFavoritesToLocal();
    await _userDataManager.setCloudData(_favoritesKey, _favorites.map((f) => f.toJson()).toList());
  }

  Future<void> _saveFavoritesToLocal() async {
    final box = _userDataManager.userPhraseHistoryBox;
    await box.put(_favoritesKey, _favorites.map((f) => f.toJson()).toList());
  }

  /// Sync from cloud to local (useful after login or when data changes elsewhere)
  Future<void> syncFromCloud() async {
    if (!_isInitialized) return;
    
    try {
      await _loadHistory();
      await _loadFavorites();
      AACLogger.info('PhraseHistoryService: Synced from cloud.', tag: 'PhraseHistoryService');
    } catch (e) {
      AACLogger.error('PhraseHistoryService: Error syncing from cloud: $e', tag: 'PhraseHistoryService');
    }
  }

  void disposeService() {
    _historyController.close();
    _favoritesController.close();
    _isInitialized = false;
    _history.clear();
    _favorites.clear();
    AACLogger.info('PhraseHistoryService disposed.', tag: 'PhraseHistoryService');
    super.dispose();
  }
}