import '../models/symbol.dart';
import '../services/local_data_manager.dart';
import '../services/user_profile_service.dart';

/// Service to easily add user data with automatic local storage and cloud sync
class UserDataService {
  static final UserDataService _instance = UserDataService._internal();
  factory UserDataService() => _instance;
  UserDataService._internal();

  /// Add a new symbol created by the user
  Future<bool> addUserSymbol(Symbol symbol) async {
    try {
      // Get current user
      final currentProfile = await UserProfileService.getActiveProfile();
      if (currentProfile == null) {
        print('UserDataService: No active profile found');
        return false;
      }
      
      // Add to local storage immediately
      await LocalDataManager().addUserData(
        userId: currentProfile.id,
        newSymbol: symbol,
      );
      
      return true;
      
    } catch (e) {
      print('UserDataService: Error adding user symbol: $e');
      return false;
    }
  }

  /// Add a new category created by the user
  Future<bool> addUserCategory(Category category) async {
    try {
      // Get current user
      final currentProfile = await UserProfileService.getActiveProfile();
      if (currentProfile == null) {
        print('UserDataService: No active profile found');
        return false;
      }
      
      // Add to local storage immediately
      await LocalDataManager().addUserData(
        userId: currentProfile.id,
        newCategory: category,
      );
      
      return true;
      
    } catch (e) {
      print('UserDataService: Error adding user category: $e');
      return false;
    }
  }

  /// Add a symbol to user's favorites
  Future<bool> addToFavorites(String symbolId) async {
    try {
      // Get current user
      final currentProfile = await UserProfileService.getActiveProfile();
      if (currentProfile == null) {
        print('UserDataService: No active profile found');
        return false;
      }
      
      // Add to local storage immediately
      await LocalDataManager().addUserData(
        userId: currentProfile.id,
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
      // Get current user
      final currentProfile = await UserProfileService.getActiveProfile();
      if (currentProfile == null) {
        print('UserDataService: No active profile found');
        return false;
      }
      
      // Create history entry
      final historyEntry = {
        'symbolLabels': symbolLabels,
        'spokenText': spokenText,
        'timestamp': (timestamp ?? DateTime.now()).millisecondsSinceEpoch,
        'userId': currentProfile.id,
        'userName': currentProfile.name,
      };
      
      // Add to local storage immediately
      await LocalDataManager().addUserData(
        userId: currentProfile.id,
        historyEntry: historyEntry,
      );
      
      print('UserDataService: Communication history added successfully');
      return true;
      
    } catch (e) {
      print('UserDataService: Error adding communication history: $e');
      return false;
    }
  }

  /// Get user data summary (for display purposes)
  Future<Map<String, int>> getUserDataSummary() async {
    try {
      // Get current user
      final currentProfile = await UserProfileService.getActiveProfile();
      if (currentProfile == null) {
        print('UserDataService: No active profile found');
        return {
          'symbols': 0,
          'categories': 0,
          'favorites': 0,
          'history': 0,
        };
      }
      
      // Get summary from local data manager
      return await LocalDataManager().getUserDataSummary(currentProfile.id);
      
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
      
      // Get current user
      final currentProfile = await UserProfileService.getActiveProfile();
      if (currentProfile != null) {
        await LocalDataManager().clearUserData(currentProfile.id);
      }
      
      print('UserDataService: User data cleared on logout');
      
    } catch (e) {
      print('UserDataService: Error clearing user data on logout: $e');
    }
  }
}
