import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/symbol.dart';
import '../models/user_profile.dart';
import '../models/communication_history.dart';
import '../models/app_settings.dart';
import '../models/history_entry.dart';
import '../utils/aac_logger.dart';
import 'firebase_path_registry.dart';

/// Centralized User Data Manager that is controlled by DataServicesInitializer.
/// It uses the Firebase UID provided by the initializer as the single source of truth
/// for all data operations, both online (Firebase) and offline (Hive).
class UserDataManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late final String _currentUserId;
  UserProfile? _currentUserProfile;
  bool _isInitialized = false;

  // Hive boxes for the current user
  late Box<Symbol> _userSymbolsBox;
  late Box<Category> _userCategoriesBox;
  late Box _userFavoritesBox; // Generic box to store favorites as JSON list
  late Box<HistoryEntry> _userHistoryBox;
  late Box<AppSettings> _userSettingsBox;
  late Box<CommunicationHistoryEntry> _userCommunicationHistoryBox;
  late Box _userPhraseHistoryBox; // Generic box for phrase history

  bool get isInitialized => _isInitialized;
  User? get currentUser => FirebaseAuth.instance.currentUser;
  bool get isAuthenticated => currentUser != null;

  /// Initialize the user data manager with a specific Firebase UID.
  /// This must be called by DataServicesInitializer.
  Future<void> initializeWithUid(String uid) async {
    if (_isInitialized) return;

    try {
      AACLogger.info('UserDataManager: Initializing with UID: $uid', tag: 'UserDataManager');
      _currentUserId = uid;

      // Register adapters if not already registered
      _registerHiveAdapters();

      // Open user-specific Hive boxes
      await _openUserBoxes(uid);

      // Load or create user profile
      try {
        await _loadOrCreateUserProfile(uid);
        AACLogger.info('UserDataManager: Profile loaded/created successfully', tag: 'UserDataManager');
      } catch (e) {
        AACLogger.error('UserDataManager: Profile creation failed: $e', tag: 'UserDataManager');
        rethrow;
      }

      _isInitialized = true;
      AACLogger.info('UserDataManager: Initialization complete for UID: $uid', tag: 'UserDataManager');
    } catch (e, stackTrace) { // Corrected parameter name
      AACLogger.error('UserDataManager: Initialization failed for UID $uid: $e', stackTrace: stackTrace, tag: 'UserDataManager');
      _isInitialized = false;
      rethrow;
    }
  }

  void _registerHiveAdapters() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(SymbolAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(CategoryAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(CommunicationHistoryEntryAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(HistoryEntryAdapter());
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(AppSettingsAdapter());
  }

  /// Open all Hive boxes for the user with UID-based naming
  Future<void> _openUserBoxes(String userId) async {
    try {
      // Create user-specific box names using Firebase UID
      final symbolsBoxName = 'symbols_$userId';
      final categoriesBoxName = 'categories_$userId';
      final favoritesBoxName = 'favorites_$userId';
      final historyBoxName = 'history_$userId';
      final settingsBoxName = 'settings_$userId';
      final communicationHistoryBoxName = 'comm_history_$userId';
      final phraseHistoryBoxName = 'phrase_history_$userId'; // New box name

      // Open boxes
      _userSymbolsBox = await Hive.openBox<Symbol>(symbolsBoxName);
      _userCategoriesBox = await Hive.openBox<Category>(categoriesBoxName);
      _userFavoritesBox = await Hive.openBox(favoritesBoxName); // Generic box for JSON storage
      _userHistoryBox = await Hive.openBox<HistoryEntry>(historyBoxName);
      _userSettingsBox = await Hive.openBox<AppSettings>(settingsBoxName);
      _userCommunicationHistoryBox = await Hive.openBox<CommunicationHistoryEntry>(communicationHistoryBoxName);
      _userPhraseHistoryBox = await Hive.openBox(phraseHistoryBoxName); // Open the new box

      AACLogger.info('UserDataManager: Opened all Hive boxes for user: $userId', tag: 'UserDataManager');
    } catch (e) {
      AACLogger.error('UserDataManager: Error opening user boxes: $e', tag: 'UserDataManager');
      rethrow;
    }
  }

  /// Close current user's Hive boxes
  Future<void> _closeCurrentUserBoxes() async {
    try {
      await _userSymbolsBox.close();
      await _userCategoriesBox.close();
      await _userFavoritesBox.close();
      await _userHistoryBox.close();
      await _userSettingsBox.close();
      await _userCommunicationHistoryBox.close();
      await _userPhraseHistoryBox.close(); // Close the new box
      AACLogger.info('UserDataManager: Closed all user boxes for UID: $_currentUserId', tag: 'UserDataManager');
    } catch (e) {
      AACLogger.error('UserDataManager: Error closing user boxes: $e', tag: 'UserDataManager');
    }
  }

  /// Load or create user profile
  Future<void> _loadOrCreateUserProfile(String userId) async {
    try {
      final userDocRef = _firestore.collection('users').doc(userId);
      final profileDoc = await userDocRef.get();

      if (profileDoc.exists) {
        final profileData = profileDoc.data();
        AACLogger.info('UserDataManager: Profile document exists, data: $profileData', tag: 'UserDataManager');
        
        if (profileData != null) {
          _currentUserProfile = UserProfile.fromJson(profileData as Map<String, dynamic>);
          AACLogger.info('UserDataManager: Loaded profile from Firestore for: $userId', tag: 'UserDataManager');
        } else {
          AACLogger.warning('UserDataManager: Profile document exists but data is null, creating new profile', tag: 'UserDataManager');
          // Fall through to create new profile
        }
      }
      
      if (_currentUserProfile == null) {
        // Create new profile if none was loaded
        final user = FirebaseAuth.instance.currentUser; // Still need this for initial creation
        
        // Safe name extraction with explicit null handling
        String userName = 'User';
        if (user?.displayName != null && user!.displayName!.isNotEmpty) {
          userName = user.displayName!;
        } else if (user?.email != null && user!.email!.isNotEmpty) {
          final emailParts = user.email!.split('@');
          if (emailParts.isNotEmpty && emailParts.first.isNotEmpty) {
            userName = emailParts.first;
          }
        }
        
        _currentUserProfile = UserProfile(
          id: userId, // Use Firebase UID as profile ID
          name: userName,
          role: UserRole.child,
          email: user?.email ?? '',
          createdAt: DateTime.now(),
          settings: ProfileSettings(),
        );
        
        await userDocRef.set(_currentUserProfile!.toJson());
        AACLogger.info('UserDataManager: Created new profile in Firestore for: $userId', tag: 'UserDataManager');
      }
    } catch (e) {
      AACLogger.error('UserDataManager: Error loading/creating profile: $e', tag: 'UserDataManager');
      rethrow;
    }
  }

  // GETTERS FOR CURRENT USER STATE

  /// Get current Firebase user ID (non-null, throws if not initialized)
  String get currentUserId {
    if (!_isInitialized) {
      throw Exception('UserDataManager not initialized - call initializeWithUid() first');
    }
    if (_currentUserId.isEmpty) {
      throw Exception('UserDataManager currentUserId is empty - initialization failed');
    }
    return _currentUserId;
  }

  /// Get current user profile
  Future<UserProfile?> getUserProfile() async {
    if (!_isInitialized) {
      AACLogger.warning('Cannot get user profile, UserDataManager not initialized.');
      return null;
    }
    if (_currentUserProfile != null) return _currentUserProfile;

    // If null, try to fetch again
    await _loadOrCreateUserProfile(_currentUserId);
    return _currentUserProfile;
  }

  // HIVE BOX ACCESSORS

  /// Get user symbols box
  Box<Symbol> get userSymbolsBox {
    if (!_isInitialized) throw Exception('UserDataManager not initialized');
    return _userSymbolsBox;
  }

  /// Get user categories box
  Box<Category> get userCategoriesBox {
    if (!_isInitialized) throw Exception('UserDataManager not initialized');
    return _userCategoriesBox;
  }

  /// Get user favorites box
  Box get userFavoritesBox {
    if (!_isInitialized) throw Exception('UserDataManager not initialized');
    return _userFavoritesBox;
  }

  /// Get user history box
  Box<HistoryEntry> get userHistoryBox {
    if (!_isInitialized) throw Exception('UserDataManager not initialized');
    return _userHistoryBox;
  }

  /// Get user settings box
  Box<AppSettings> get userSettingsBox {
    if (!_isInitialized) throw Exception('UserDataManager not initialized');
    return _userSettingsBox;
  }

  /// Get user communication history box
  Box<CommunicationHistoryEntry> get userCommunicationHistoryBox {
    if (!_isInitialized) throw Exception('UserDataManager not initialized');
    return _userCommunicationHistoryBox;
  }

  /// Get user phrase history box
  Box get userPhraseHistoryBox {
    if (!_isInitialized) throw Exception('UserDataManager not initialized');
    return _userPhraseHistoryBox;
  }

  /// Get user favorites box (for FavoritesService)
  Future<Box> getFavoritesBox() async {
    if (!_isInitialized) throw Exception('UserDataManager not initialized');
    final boxName = FirebasePathRegistry.hiveUserFavoritesBox(_currentUserId);
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    }
    return await Hive.openBox(boxName);
  }

  /// Get user custom categories box (for CustomCategoriesService)
  Future<Box> getCustomCategoriesBox() async {
    if (!_isInitialized) throw Exception('UserDataManager not initialized');
    final boxName = FirebasePathRegistry.hiveCustomCategoriesBox(_currentUserId);
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    }
    return await Hive.openBox(boxName);
  }

  /// Get user custom symbols box (for CustomSymbolsService)
  Future<Box> getCustomSymbolsBox() async {
    if (!_isInitialized) throw Exception('UserDataManager not initialized');
    final boxName = FirebasePathRegistry.hiveCustomSymbolsBox(_currentUserId);
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    }
    return await Hive.openBox(boxName);
  }

  // FIRESTORE ACCESSORS

  /// Get user's Firestore document reference
  DocumentReference get userDocument {
    if (!_isInitialized) throw Exception('UserDataManager not initialized');
    return _firestore.doc(FirebasePathRegistry.userDocument(_currentUserId));
  }

  /// Get user's symbols collection
  CollectionReference get userSymbolsCollection {
    return _firestore.collection(FirebasePathRegistry.userSymbols(_currentUserId));
  }

  /// Get user's favorites collection
  CollectionReference get userFavoritesCollection {
    return userDocument.collection('favorites');
  }

  /// Save the entire user profile to Firestore
  Future<void> saveUserProfile(UserProfile profile) async {
    if (!_isInitialized) {
      AACLogger.warning('Cannot save profile, UserDataManager not initialized.');
      return;
    }
    try {
      await userDocument.set(profile.toJson());
      _currentUserProfile = profile; // Update local cache
      AACLogger.info('Successfully saved user profile to Firestore for UID: $_currentUserId');
    } catch (e) {
      AACLogger.error('Error saving user profile: $e');
      rethrow;
    }
  }

  // GENERIC CLOUD DATA METHODS

  /// Get a generic data blob from the user's userData subcollection.
  Future<dynamic> getCloudData(String key) async {
    if (!_isInitialized) return null;
    try {
      final doc = await userDocument.get();
      if (doc.exists) {
        final userData = doc.data() as Map<String, dynamic>?;
        if (userData != null && userData.containsKey('userData')) {
          final userDataMap = userData['userData'] as Map<String, dynamic>?;
          if (userDataMap != null && userDataMap.containsKey(key)) {
            AACLogger.info('UserDataManager: Loaded $key from Firebase for UID: $_currentUserId', tag: 'UserDataManager');
            return userDataMap[key];
          }
        }
      }
      AACLogger.info('UserDataManager: No cloud data found for key $key, UID: $_currentUserId', tag: 'UserDataManager');
      return null;
    } catch (e) {
      AACLogger.error('UserDataManager: Error getting cloud data for key $key: $e', tag: 'UserDataManager');
      return null;
    }
  }

  /// Set a generic data blob in the user's userData subcollection.
  Future<void> setCloudData(String key, dynamic value) async {
    if (!_isInitialized) return;
    try {
      await userDocument.set({
        'userData': {
          key: value,
          '${key}_updatedAt': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));
      AACLogger.info('UserDataManager: Saved $key to Firebase for UID: $_currentUserId', tag: 'UserDataManager');
    } catch (e) {
      AACLogger.error('UserDataManager: Error setting cloud data for key $key: $e', tag: 'UserDataManager');
      rethrow;
    }
  }

  /// Dispose the user data manager and close Hive boxes.
  Future<void> dispose() async {
    if (!_isInitialized) return;
    await _closeCurrentUserBoxes();
    _isInitialized = false;
  }
}
