import '../models/phrase_history.dart';
import 'user_data_manager.dart';

class HistoryManager {
  static HistoryManager? _instance;
  UserDataManager? _userDataManager;

  HistoryManager._();

  static HistoryManager get instance {
    _instance ??= HistoryManager._();
    return _instance!;
  }

  Future<void> initialize(UserDataManager userDataManager) async {
    _userDataManager = userDataManager;
  }

  Future<void> _ensureInitialized() async {
    if (_userDataManager == null) {
      throw Exception('HistoryManager not initialized. Call initialize() first.');
    }
  }

  Future<List<PhraseHistory>> getHistory() async {
    await _ensureInitialized();
    if (!_userDataManager!.isAuthenticated) {
      return [];
    }

    try {
      final historyBox = await _userDataManager!.getHistoryBox();
      final historyData = historyBox.get('phrases', defaultValue: <Map<String, dynamic>>[]);
      
      return historyData
          .map<PhraseHistory>((item) => PhraseHistory.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addToHistory(PhraseHistory phrase) async {
    await _ensureInitialized();
    if (!_userDataManager!.isAuthenticated) {
      return;
    }

    try {
      final historyBox = await _userDataManager!.getHistoryBox();
      final history = await getHistory();
      
      history.insert(0, phrase);
      
      // Keep only last 100 entries
      if (history.length > 100) {
        history.removeRange(100, history.length);
      }
      
      final historyData = history.map((h) => h.toJson()).toList();
      await historyBox.put('phrases', historyData);
      
      // Sync to cloud
      await _syncToCloud();
    } catch (e) {
      // Handle error silently for now
    }
  }

  Future<void> removeFromHistory(String phraseId) async {
    await _ensureInitialized();
    if (!_userDataManager!.isAuthenticated) {
      return;
    }

    try {
      final history = await getHistory();
      history.removeWhere((phrase) => phrase.id == phraseId);
      
      final historyBox = await _userDataManager!.getHistoryBox();
      final historyData = history.map((h) => h.toJson()).toList();
      await historyBox.put('phrases', historyData);
      
      // Sync to cloud
      await _syncToCloud();
    } catch (e) {
      // Handle error silently for now
    }
  }

  Future<void> clearHistory() async {
    await _ensureInitialized();
    if (!_userDataManager!.isAuthenticated) {
      return;
    }

    try {
      final historyBox = await _userDataManager!.getHistoryBox();
      await historyBox.put('phrases', <Map<String, dynamic>>[]);
      
      // Sync to cloud
      await _syncToCloud();
    } catch (e) {
      // Handle error silently for now
    }
  }

  Future<void> syncFromCloud() async {
    if (!_userDataManager!.isAuthenticated) {
      return;
    }

    try {
      final cloudHistory = await _userDataManager!.getCloudData('history');
      if (cloudHistory != null) {
        final historyBox = await _userDataManager!.getHistoryBox();
        await historyBox.put('phrases', cloudHistory);
      }
    } catch (e) {
      // Handle error silently for now
    }
  }

  /// Sync history to Firestore
  Future<void> _syncToCloud() async {
    try {
      final history = await getHistory();
      final historyData = history.map((h) => h.toJson()).toList();
      await _userDataManager!.setCloudData('history', historyData);
    } catch (e) {
      // Handle error silently for now
    }
  }
}
