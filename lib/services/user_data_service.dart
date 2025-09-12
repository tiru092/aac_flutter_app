import '../models/symbol.dart';
import '../services/local_data_manager.dart';
import '../services/user_profile_service.dart';
import '../services/user_data_manager.dart';
import '../services/data_services_initializer_robust.dart';
import '../services/cloud_sync_service.dart';

/// Service to easily add user data with automatic local storage and cloud sync
class UserDataService {
  static final UserDataService _instance = UserDataService._internal();
  factory UserDataService() => _instance;
  UserDataService._internal();

  final CloudSyncService _cloudSyncService = CloudSyncService();

  Future<bool> _ensureInitialized() async {
    final dataServices = DataServicesInitializer.instance;
    if (!dataServices.isInitialized) {
      print('UserDataService: Data services not initialized');
      return false;
    }
    return true;
  }

  /// Add a new symbol created by the user
  Future<bool> addUserSymbol(Symbol symbol) async {
    try {
      if (!await _ensureInitialized()) return false;
      final userDataManager = DataServicesInitializer.instance.userDataManager;
      final firebaseUid = userDataManager.currentUserId;
      
      // Add to local storage immediately using Firebase UID
      await LocalDataManager().addUserData(
        userId: firebaseUid, // Use Firebase UID consistently
        newSymbol: symbol,
      );
      
      // Sync to cloud
      await _cloudSyncService.syncOnDataChange(firebaseUid, symbol: symbol);
      
      return true;
      
    } catch (e) {
      print('UserDataService: Error adding user symbol: $e');
      return false;
    }
  }

  /// Add a new category created by the user
  Future<bool> addUserCategory(Category category) async {
    try {
      if (!await _ensureInitialized()) return false;
      final userDataManager = DataServicesInitializer.instance.userDataManager;
      final firebaseUid = userDataManager.currentUserId;

      // Add to local storage immediately using Firebase UID
      await LocalDataManager().addUserData(
        userId: firebaseUid, // Use Firebase UID consistently
        newCategory: category,
      );
      
      // Sync to cloud
      await _cloudSyncService.syncOnDataChange(firebaseUid, category: category);
      
      return true;
      
    } catch (e) {
      print('UserDataService: Error adding user category: $e');
      return false;
    }
  }

  /// Add a symbol to user's favorites
  Future<bool> addToFavorites(String symbolId) async {
    try {
      if (!await _ensureInitialized()) return false;
      final userDataManager = DataServicesInitializer.instance.userDataManager;
      final firebaseUid = userDataManager.currentUserId;
      
      // Add to local storage immediately using Firebase UID
      await LocalDataManager().addUserData(
        userId: firebaseUid, // Use Firebase UID consistently
        favoriteSymbolId: symbolId,
      );
      
      return true;
      
    } catch (e) {
      print('UserDataService: Error adding to favorites: $e');
      return false;
    }
  }

  /// Record communication history entry
  Future<bool> addCommunicationHistory({
    required List<String> symbolLabels,
    required String spokenText,
    DateTime? timestamp,
  }) async {
    try {
      if (!await _ensureInitialized()) return false;
      final userDataManager = DataServicesInitializer.instance.userDataManager;
      final firebaseUid = userDataManager.currentUserId;
      
      // Create history entry
      final historyEntry = {
        'symbolLabels': symbolLabels,
        'spokenText': spokenText,
        'timestamp': (timestamp ?? DateTime.now()).millisecondsSinceEpoch,
        'userId': firebaseUid, // Use Firebase UID consistently
        'userName': 'User', // Simplified for consistency
      };
      
      // Add to local storage immediately using Firebase UID
      await LocalDataManager().addUserData(
        userId: firebaseUid, // Use Firebase UID consistently
        historyEntry: historyEntry,
      );
      
      print('UserDataService: Communication history added successfully');
      return true;
      
    } catch (e) {
      print('UserDataService: Error adding communication history: $e');
      return false;
    }
  }

  /// Update an existing symbol for the user
  Future<bool> updateUserSymbol(Symbol symbol) async {
    try {
      if (!await _ensureInitialized()) return false;
      final userDataManager = DataServicesInitializer.instance.userDataManager;
      final firebaseUid = userDataManager.currentUserId;

      await LocalDataManager().updateUserData(
        userId: firebaseUid,
        updatedSymbol: symbol,
      );

      await _cloudSyncService.syncOnDataChange(firebaseUid, symbol: symbol);
      
      return true;
      
    } catch (e) {
      print('UserDataService: Error updating user symbol: $e');
      return false;
    }
  }

  /// Update an existing category for the user
  Future<bool> updateUserCategory(Category category) async {
    try {
      if (!await _ensureInitialized()) return false;
      final userDataManager = DataServicesInitializer.instance.userDataManager;
      final firebaseUid = userDataManager.currentUserId;

      await LocalDataManager().updateUserData(
        userId: firebaseUid,
        updatedCategory: category,
      );

      await _cloudSyncService.syncOnDataChange(firebaseUid, category: category);
      
      return true;
      
    } catch (e) {
      print('UserDataService: Error updating user category: $e');
      return false;
    }
  }

  /// Delete a symbol for the user
  Future<bool> deleteUserSymbol(String symbolId) async {
    try {
      if (!await _ensureInitialized()) return false;
      final userDataManager = DataServicesInitializer.instance.userDataManager;
      final firebaseUid = userDataManager.currentUserId;

      await LocalDataManager().deleteUserData(
        userId: firebaseUid,
        symbolId: symbolId,
      );

      await _cloudSyncService.syncOnDataChange(firebaseUid, deletedSymbolId: symbolId);
      
      return true;
      
    } catch (e) {
      print('UserDataService: Error deleting user symbol: $e');
      return false;
    }
  }

  /// Delete a category for the user
  Future<bool> deleteUserCategory(String categoryId) async {
    try {
      if (!await _ensureInitialized()) return false;
      final userDataManager = DataServicesInitializer.instance.userDataManager;
      final firebaseUid = userDataManager.currentUserId;

      await LocalDataManager().deleteUserData(
        userId: firebaseUid,
        categoryId: categoryId,
      );

      await _cloudSyncService.syncOnDataChange(firebaseUid, deletedCategoryId: categoryId);
      
      return true;
      
    } catch (e) {
      print('UserDataService: Error deleting user category: $e');
      return false;
    }
  }

  /// Get user data summary (for display purposes)
  Future<Map<String, int>> getUserDataSummary() async {
    try {
      if (!await _ensureInitialized()) return {
        'symbols': 0,
        'categories': 0,
        'favorites': 0,
        'history': 0,
      };
      final userDataManager = DataServicesInitializer.instance.userDataManager;
      final firebaseUid = userDataManager.currentUserId;
      
      // Get summary from local data manager using Firebase UID
      return await LocalDataManager().getUserDataSummary(firebaseUid);
      
    } catch (e) {
      print('UserDataService: Error getting user data summary: $e');
      return {
        'symbols': 0,
        'categories': 0,
        'favorites': 0,
        'history': 0,
      };
    }
  }

  /// Clear user data on logout
  Future<void> clearUserDataOnLogout() async {
    try {
      print('UserDataService: Clearing user data on logout');
      
      // Use Firebase UID directly as single source of truth
      final userDataManager = DataServicesInitializer.instance.userDataManager;
      if (userDataManager.isAuthenticated) {
        final firebaseUid = userDataManager.currentUserId;
        await LocalDataManager().clearUserData(firebaseUid);
        print('UserDataService: User data cleared for UID: $firebaseUid');
      } else {
        print('UserDataService: No authenticated user for clearing data');
      }
      
      print('UserDataService: User data cleared on logout');
      
    } catch (e) {
      print('UserDataService: Error clearing user data on logout: $e');
    }
  }

  /// Trigger cloud sync on user login
  Future<void> onUserLogin() async {
    try {
      if (!await _ensureInitialized()) return;
      await _cloudSyncService.syncAllData();
    } catch (e) {
      print('UserDataService: Error during login sync: $e');
    }
  }
}
