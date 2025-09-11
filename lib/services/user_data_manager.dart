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

/// Centralized User Data Manager that ensures Firebase UID is the single source of truth
/// for all data operations, both online (Firebase) and offline (Hive).
/// 
/// Key Features:
/// - Uses Firebase UID consistently across all data operations
/// - Manages user-specific Hive boxes with UID-based naming
/// - Handles online/offline synchronization
/// - Provides a unified interface for all user data
class UserDataManager {
  static final UserDataManager _instance = UserDataManager._internal();
  factory UserDataManager() => _instance;
  UserDataManager._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current user state
  String? _currentUserId;
  UserProfile? _currentUserProfile;
  
  // Hive boxes for current user
  Box<Symbol>? _userSymbolsBox;
  Box<Category>? _userCategoriesBox;
  Box<String>? _userFavoritesBox;
  Box<HistoryEntry>? _userHistoryBox;
  Box<AppSettings>? _userSettingsBox;
  Box<CommunicationHistoryEntry>? _userCommunicationHistoryBox;

  /// Initialize the user data manager
  Future<void> initialize() async {
    try {
      AACLogger.info('UserDataManager: Initializing...', tag: 'UserDataManager');
      
      // Initialize Hive if not already done
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(SymbolAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(CategoryAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(CommunicationHistoryEntryAdapter());
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(HistoryEntryAdapter());
      }
      if (!Hive.isAdapterRegistered(10)) {
        Hive.registerAdapter(AppSettingsAdapter());
      }
      
      // Set up auth state listener
      _auth.authStateChanges().listen(_onAuthStateChanged);
      
      // Initialize for current user if signed in
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _initializeForUser(currentUser.uid);
      }
      
      AACLogger.info('UserDataManager: Initialization complete', tag: 'UserDataManager');
    } catch (e) {
      AACLogger.error('UserDataManager: Initialization failed: $e', tag: 'UserDataManager');
      rethrow;
    }
  }

  /// Handle authentication state changes
  Future<void> _onAuthStateChanged(User? user) async {
    if (user?.uid != _currentUserId) {
      await _switchUser(user?.uid);
    }
  }

  /// Switch to a different user or sign out
  Future<void> _switchUser(String? newUserId) async {
    try {
      AACLogger.info('UserDataManager: Switching user from $_currentUserId to $newUserId', tag: 'UserDataManager');
      
      // Close current user's boxes
      await _closeCurrentUserBoxes();
      
      // Clear current state
      _currentUserId = null;
      _currentUserProfile = null;
      
      // Initialize for new user if provided
      if (newUserId != null) {
        await _initializeForUser(newUserId);
      }
      
      AACLogger.info('UserDataManager: User switch complete', tag: 'UserDataManager');
    } catch (e) {
      AACLogger.error('UserDataManager: Error switching user: $e', tag: 'UserDataManager');
    }
  }

  /// Initialize data management for a specific user
  Future<void> _initializeForUser(String userId) async {
    try {
      AACLogger.info('UserDataManager: Initializing for user: $userId', tag: 'UserDataManager');
      
      _currentUserId = userId;
      
      // Open user-specific Hive boxes
      await _openUserBoxes(userId);
      
      // Load or create user profile
      await _loadOrCreateUserProfile(userId);
      
      AACLogger.info('UserDataManager: User initialization complete for: $userId', tag: 'UserDataManager');
    } catch (e) {
      AACLogger.error('UserDataManager: Error initializing user $userId: $e', tag: 'UserDataManager');
      rethrow;
    }
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

      // Open boxes
      _userSymbolsBox = await Hive.openBox<Symbol>(symbolsBoxName);
      _userCategoriesBox = await Hive.openBox<Category>(categoriesBoxName);
      _userFavoritesBox = await Hive.openBox<String>(favoritesBoxName);
      _userHistoryBox = await Hive.openBox<HistoryEntry>(historyBoxName);
      _userSettingsBox = await Hive.openBox<AppSettings>(settingsBoxName);
      _userCommunicationHistoryBox = await Hive.openBox<CommunicationHistoryEntry>(communicationHistoryBoxName);

      AACLogger.info('UserDataManager: Opened all Hive boxes for user: $userId', tag: 'UserDataManager');
    } catch (e) {
      AACLogger.error('UserDataManager: Error opening user boxes: $e', tag: 'UserDataManager');
      rethrow;
    }
  }

  /// Close current user's Hive boxes
  Future<void> _closeCurrentUserBoxes() async {
    try {
      await _userSymbolsBox?.close();
      await _userCategoriesBox?.close();
      await _userFavoritesBox?.close();
      await _userHistoryBox?.close();
      await _userSettingsBox?.close();
      await _userCommunicationHistoryBox?.close();

      _userSymbolsBox = null;
      _userCategoriesBox = null;
      _userFavoritesBox = null;
      _userHistoryBox = null;
      _userSettingsBox = null;
      _userCommunicationHistoryBox = null;

      AACLogger.info('UserDataManager: Closed all user boxes', tag: 'UserDataManager');
    } catch (e) {
      AACLogger.error('UserDataManager: Error closing user boxes: $e', tag: 'UserDataManager');
    }
  }

  /// Load or create user profile
  Future<void> _loadOrCreateUserProfile(String userId) async {
    try {
      // Try to load from Firestore first
      DocumentSnapshot profileDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (profileDoc.exists) {
        _currentUserProfile = UserProfile.fromJson(
          profileDoc.data() as Map<String, dynamic>
        );
        AACLogger.info('UserDataManager: Loaded profile from Firestore for: $userId', tag: 'UserDataManager');
      } else {
        // Create default profile if not found
        final user = _auth.currentUser;
        _currentUserProfile = UserProfile(
          id: userId, // Use Firebase UID as profile ID
          name: user?.displayName ?? user?.email?.split('@').first ?? 'User',
          role: UserRole.child,
          email: user?.email,
          createdAt: DateTime.now(),
          settings: ProfileSettings(),
        );
        
        // Save to Firestore
        await _firestore
            .collection('users')
            .doc(userId)
            .set(_currentUserProfile!.toJson());
            
        AACLogger.info('UserDataManager: Created new profile for: $userId', tag: 'UserDataManager');
      }

      // Store profile ID in SharedPreferences for offline access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_id', userId);
      
    } catch (e) {
      AACLogger.error('UserDataManager: Error loading/creating profile: $e', tag: 'UserDataManager');
      rethrow;
    }
  }

  // GETTERS FOR CURRENT USER STATE

  /// Get current Firebase user ID
  String? get currentUserId => _currentUserId;

  /// Get current user profile
  UserProfile? get currentUserProfile => _currentUserProfile;

  /// Check if user is authenticated
  bool get isAuthenticated => _currentUserId != null;

  /// Get Firebase user
  User? get firebaseUser => _auth.currentUser;

  // HIVE BOX ACCESSORS (with null safety)

  /// Get user symbols box
  Box<Symbol>? get userSymbolsBox => _userSymbolsBox;

  /// Get user categories box
  Box<Category>? get userCategoriesBox => _userCategoriesBox;

  /// Get user favorites box
  Box<String>? get userFavoritesBox => _userFavoritesBox;

  /// Get user history box
  Box<HistoryEntry>? get userHistoryBox => _userHistoryBox;

  /// Get user settings box
  Box<AppSettings>? get userSettingsBox => _userSettingsBox;

  /// Get user communication history box
  Box<CommunicationHistoryEntry>? get userCommunicationHistoryBox => _userCommunicationHistoryBox;

  // FIRESTORE ACCESSORS (with null safety)

  /// Get user's Firestore document reference
  DocumentReference? get userDocument {
    if (_currentUserId == null) return null;
    return _firestore.collection('users').doc(_currentUserId);
  }

  /// Get user's symbols collection
  CollectionReference? get userSymbolsCollection {
    final doc = userDocument;
    if (doc == null) return null;
    return doc.collection('symbols');
  }

  /// Get user's favorites collection
  CollectionReference? get userFavoritesCollection {
    final doc = userDocument;
    if (doc == null) return null;
    return doc.collection('favorites');
  }

  /// Get user's history collection
  CollectionReference? get userHistoryCollection {
    final doc = userDocument;
    if (doc == null) return null;
    return doc.collection('history');
  }

  /// Get user's communication history collection
  CollectionReference? get userCommunicationHistoryCollection {
    final doc = userDocument;
    if (doc == null) return null;
    return doc.collection('communication_history');
  }

  // DATA OPERATIONS

  /// Save user profile
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      if (_currentUserId == null) {
        throw Exception('No user signed in');
      }

      // Ensure profile ID matches Firebase UID
      final updatedProfile = profile.copyWith(id: _currentUserId);
      _currentUserProfile = updatedProfile;

      // Save to Firestore
      await userDocument?.set(updatedProfile.toJson());
      
      AACLogger.info('UserDataManager: Saved user profile', tag: 'UserDataManager');
    } catch (e) {
      AACLogger.error('UserDataManager: Error saving user profile: $e', tag: 'UserDataManager');
      rethrow;
    }
  }

  /// Sync local data to Firestore
  Future<void> syncToFirestore() async {
    try {
      if (_currentUserId == null || !isOnline()) return;

      AACLogger.info('UserDataManager: Starting sync to Firestore', tag: 'UserDataManager');

      // Sync symbols
      await _syncSymbolsToFirestore();
      
      // Sync favorites
      await _syncFavoritesToFirestore();
      
      // Sync history
      await _syncHistoryToFirestore();
      
      AACLogger.info('UserDataManager: Sync to Firestore complete', tag: 'UserDataManager');
    } catch (e) {
      AACLogger.error('UserDataManager: Error syncing to Firestore: $e', tag: 'UserDataManager');
    }
  }

  /// Sync symbols to Firestore
  Future<void> _syncSymbolsToFirestore() async {
    final symbolsBox = _userSymbolsBox;
    final symbolsCollection = userSymbolsCollection;
    
    if (symbolsBox == null || symbolsCollection == null) return;

    for (int i = 0; i < symbolsBox.length; i++) {
      final symbol = symbolsBox.getAt(i);
      if (symbol != null) {
        await symbolsCollection.doc(symbol.id).set(symbol.toJson());
      }
    }
  }

  /// Sync favorites to Firestore
  Future<void> _syncFavoritesToFirestore() async {
    final favoritesBox = _userFavoritesBox;
    final favoritesCollection = userFavoritesCollection;
    
    if (favoritesBox == null || favoritesCollection == null) return;

    for (int i = 0; i < favoritesBox.length; i++) {
      final favoriteId = favoritesBox.getAt(i);
      if (favoriteId != null) {
        await favoritesCollection.doc(favoriteId).set({
          'symbolId': favoriteId,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  /// Sync history to Firestore
  Future<void> _syncHistoryToFirestore() async {
    final historyBox = _userHistoryBox;
    final historyCollection = userHistoryCollection;
    
    if (historyBox == null || historyCollection == null) return;

    for (int i = 0; i < historyBox.length; i++) {
      final historyEntry = historyBox.getAt(i);
      if (historyEntry != null) {
        await historyCollection.doc(historyEntry.id).set(historyEntry.toFirestore());
      }
    }
  }

  /// Check if device is online (simplified check)
  bool isOnline() {
    // This is a simplified check. In a real app, you'd use connectivity_plus package
    return true; // Assume online for now
  }

  /// Get user-specific favorites box
  Future<Box> getFavoritesBox() async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    final boxName = 'user_${currentUserId}_favorites';
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    }
    return await Hive.openBox(boxName);
  }

  /// Get user-specific history box  
  Future<Box> getHistoryBox() async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    final boxName = 'user_${currentUserId}_history';
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    }
    return await Hive.openBox(boxName);
  }

  /// Get user-specific custom categories box
  Future<Box> getCustomCategoriesBox() async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    final boxName = 'user_${currentUserId}_custom_categories';
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    }
    return await Hive.openBox(boxName);
  }

  /// Set data in cloud Firestore
  Future<void> setCloudData(String key, dynamic data) async {
    if (!isAuthenticated) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('userData')
          .doc(key)
          .set({
            'data': data,
            'timestamp': FieldValue.serverTimestamp(),
          });
      
      AACLogger.info('UserDataManager: Synced $key to cloud for user: $currentUserId', tag: 'UserDataManager');
    } catch (e) {
      AACLogger.error('UserDataManager: Failed to sync $key to cloud: $e', tag: 'UserDataManager');
    }
  }

  /// Get data from cloud Firestore
  Future<dynamic> getCloudData(String key) async {
    if (!isAuthenticated) return null;
    
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('userData')
          .doc(key)
          .get();
      
      if (doc.exists) {
        final data = doc.data();
        return data?['data'];
      }
      return null;
    } catch (e) {
      AACLogger.error('UserDataManager: Failed to get $key from cloud: $e', tag: 'UserDataManager');
      return null;
    }
  }

  /// Clean up resources
  Future<void> dispose() async {
    await _closeCurrentUserBoxes();
    _currentUserId = null;
    _currentUserProfile = null;
  }
}
