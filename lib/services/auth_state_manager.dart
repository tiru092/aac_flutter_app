import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/unified_supabase_auth_service.dart';
import '../models/user_profile.dart';
import '../services/local_data_manager.dart';
import '../services/cloud_sync_service.dart';
import '../services/user_profile_service.dart';
import '../services/user_data_service.dart';
import '../services/secure_logger.dart';
import '../services/crash_reporting_service.dart';

/// Enterprise-level Authentication State Manager
/// 
/// Features:
/// - Single source of truth for auth state
/// - Automatic data initialization on login
/// - Comprehensive error handling and recovery
/// - Proper cleanup on logout
/// - Production-ready logging and monitoring
/// 
/// This service ensures that:
/// 1. Supabase user ID is always used as the single source of truth
/// 2. Local data is properly initialized after successful authentication
/// 3. Cloud sync is triggered appropriately
/// 4. All state changes are properly handled
class AuthStateManager {
  static AuthStateManager? _instance;
  static AuthStateManager get instance => _instance ??= AuthStateManager._internal();
  
  AuthStateManager._internal();
  
  // Services
  final LocalDataManager _localDataManager = LocalDataManager();
  final CloudSyncService _cloudSyncService = CloudSyncService();
  final UserDataService _userDataService = UserDataService();
  final CrashReportingService _crashReportingService = CrashReportingService();
  
  // State management
  StreamSubscription? _authStateSubscription;
  dynamic _currentUser;
  UserProfile? _currentUserProfile;
  bool _isInitialized = false;
  bool _isProcessingStateChange = false;
  
  // Status tracking
  AuthState _currentAuthState = AuthState.unknown;
  DataInitializationStatus _dataInitStatus = DataInitializationStatus.notStarted;
  SyncStatus _syncStatus = SyncStatus.idle;
  
  // Getters
  dynamic get currentUser => _currentUser;
  UserProfile? get currentUserProfile => _currentUserProfile;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _isInitialized;
  AuthState get authState => _currentAuthState;
  DataInitializationStatus get dataInitializationStatus => _dataInitStatus;
  SyncStatus get syncStatus => _syncStatus;
  
  /// Initialize the Auth State Manager
  /// Must be called once during app initialization
  Future<void> initialize() async {
    if (_isInitialized) {
      SecureLogger.warning('AuthStateManager already initialized');
      return;
    }
    
    try {
      SecureLogger.info('AuthStateManager: Initializing...');
      
      // Set initial state
      _currentUser = UnifiedSupabaseAuthService.currentUser;
      _updateAuthState();
      
      // Set up auth state listener
      _authStateSubscription = UnifiedSupabaseAuthService.userChanges.listen(
        _handleAuthStateChange,
        onError: (error) {
          SecureLogger.error('Auth state stream error', error);
          _crashReportingService.reportException(Exception(error.toString()), StackTrace.current);
        },
      );
      
      // If user is already authenticated, initialize their data
      if (_currentUser != null) {
        await _initializeUserData(_currentUser!);
      }
      
      _isInitialized = true;
      SecureLogger.info('✅ AuthStateManager initialized successfully');
      
    } catch (e, stackTrace) {
      SecureLogger.error('AuthStateManager initialization failed', e);
      _crashReportingService.reportException(Exception(e.toString()), stackTrace);
      
      // Set safe defaults to prevent app crash
      _isInitialized = true;
      _currentAuthState = AuthState.error;
    }
  }
  
  /// Handle authentication state changes
  Future<void> _handleAuthStateChange(dynamic user) async {
    // Prevent concurrent state processing
    if (_isProcessingStateChange) {
      SecureLogger.info('AuthStateManager: State change already in progress, skipping');
      return;
    }
    
    _isProcessingStateChange = true;
    
    try {
      final previousUser = _currentUser;
      _currentUser = user;
      
      SecureLogger.authEvent('Auth state changed', 
        userId: user?.id);
      
      if (user != null && (previousUser?.id != user.id)) {
        // User signed in or switched users
        await _handleUserSignIn(user, previousUser);
      } else if (user == null && previousUser != null) {
        // User signed out
        await _handleUserSignOut(previousUser);
      }
      
      _updateAuthState();
      
    } catch (e, stackTrace) {
      SecureLogger.error('Error handling auth state change', e);
      _crashReportingService.reportException(Exception(e.toString()), stackTrace);
      _currentAuthState = AuthState.error;
    } finally {
      _isProcessingStateChange = false;
    }
  }
  
  /// Handle user sign-in
  Future<void> _handleUserSignIn(dynamic user, dynamic previousUser) async {
    try {
      SecureLogger.authEvent('Processing user sign-in', userId: user.uid);
      
      // If switching users, clean up previous user data
      if (previousUser != null && previousUser.uid != user.uid) {
        await _cleanupPreviousUserData(previousUser);
      }
      
      // Initialize data for new user
      await _initializeUserData(user);
      
      SecureLogger.authEvent('User sign-in processing completed', userId: user.uid);
      
    } catch (e, stackTrace) {
      SecureLogger.error('Error handling user sign-in', e);
      _crashReportingService.reportException(Exception(e.toString()), stackTrace);
      throw AuthStateException('Failed to initialize user data: $e');
    }
  }
  
  /// Handle user sign-out
  Future<void> _handleUserSignOut(User previousUser) async {
    try {
      SecureLogger.authEvent('Processing user sign-out', userId: previousUser.id);
      
      // Clean up user data
      await _cleanupPreviousUserData(previousUser);
      
      // Reset state
      _currentUserProfile = null;
      _dataInitStatus = DataInitializationStatus.notStarted;
      _syncStatus = SyncStatus.idle;
      
      SecureLogger.authEvent('User sign-out processing completed', userId: previousUser.id);
      
    } catch (e, stackTrace) {
      SecureLogger.error('Error handling user sign-out', e);
      _crashReportingService.reportException(Exception(e.toString()), stackTrace);
      // Don't throw here - sign-out should succeed even if cleanup fails
    }
  }
  
  /// Initialize user data after authentication
  Future<void> _initializeUserData(User user) async {
    try {
      _dataInitStatus = DataInitializationStatus.inProgress;
      SecureLogger.info('Initializing data for user: ${user.id}');
      
      // Create or load user profile
      UserProfile userProfile = await _getOrCreateUserProfile(user);
      _currentUserProfile = userProfile;
      
      // Initialize local data storage with Firebase UID as single source of truth
      await _localDataManager.initializeAfterLogin(userProfile);
      
      _dataInitStatus = DataInitializationStatus.completed;
      SecureLogger.info('✅ Local data initialized for user: ${user.id}');
      
      // Trigger cloud sync in background
      _triggerCloudSync(user.id);
      
    } catch (e, stackTrace) {
      _dataInitStatus = DataInitializationStatus.failed;
      SecureLogger.error('Failed to initialize user data', e);
      _crashReportingService.reportException(Exception(e.toString()), stackTrace);
      
      // Don't throw - allow user to continue with limited functionality
      SecureLogger.warning('User can continue with limited functionality');
    }
  }
  
  /// Get or create user profile
  Future<UserProfile> _getOrCreateUserProfile(User user) async {
    try {
      // Try to load existing profile by checking active profile first
      UserProfile? existingProfile = await UserProfileService.getActiveProfile();
      
      // If active profile exists and matches current user, use it
      if (existingProfile != null && existingProfile.id == user.id) {
        SecureLogger.info('Loaded existing active user profile');
        return existingProfile;
      }
      
      // Create new profile with Firebase UID as ID
      final newProfile = await UserProfileService.createProfile(
        name: user.userMetadata?['display_name'] ?? user.email?.split('@').first ?? 'User',
        email: user.email,
        id: user.id, // Use Supabase UID as profile ID
      );
      
      SecureLogger.info('Created new user profile');
      return newProfile;
      
    } catch (e, stackTrace) {
      SecureLogger.error('Error getting/creating user profile', e);
      _crashReportingService.reportException(Exception(e.toString()), stackTrace);
      
      // Create emergency profile to prevent app crash
      return UserProfile(
        id: user.id,
        name: user.userMetadata?['display_name'] ?? 'User',
        email: user.email ?? '',
        role: UserRole.child,
        createdAt: DateTime.now(),
        settings: ProfileSettings(),
        userSymbols: [],
        userCategories: [],
      );
    }
  }
  
  /// Trigger cloud synchronization
  void _triggerCloudSync(String userId) {
    // Run sync in background without blocking UI
    Future.microtask(() async {
      try {
        _syncStatus = SyncStatus.syncing;
        SecureLogger.info('Starting cloud sync for user: $userId');
        
        await _cloudSyncService.syncAllData();
        
        _syncStatus = SyncStatus.completed;
        SecureLogger.info('✅ Cloud sync completed for user: $userId');
        
      } catch (e, stackTrace) {
        _syncStatus = SyncStatus.failed;
        SecureLogger.warning('Cloud sync failed (user can continue offline)', e);
        _crashReportingService.reportException(Exception(e.toString()), stackTrace);
      }
    });
  }
  
  /// Clean up previous user data
  Future<void> _cleanupPreviousUserData(User previousUser) async {
    try {
      SecureLogger.info('Cleaning up data for previous user: ${previousUser.id}');
      
      // Clear user data from local storage
      await _userDataService.clearUserDataOnLogout();
      
      SecureLogger.info('✅ Previous user data cleaned up');
      
    } catch (e, stackTrace) {
      SecureLogger.warning('Error cleaning up previous user data', e);
      _crashReportingService.reportException(Exception(e.toString()), stackTrace);
    }
  }
  
  /// Update authentication state
  void _updateAuthState() {
    final previousState = _currentAuthState;
    
    if (_currentUser == null) {
      _currentAuthState = AuthState.signedOut;
    } else if (_currentUser!.emailConfirmedAt != null) {
      _currentAuthState = AuthState.signedInVerified;
    } else {
      _currentAuthState = AuthState.signedInUnverified;
    }
    
    if (previousState != _currentAuthState) {
      SecureLogger.authEvent('Auth state updated', 
        userId: _currentUser?.id);
    }
  }
  
  /// Manually trigger data sync (for testing or manual refresh)
  Future<void> triggerManualSync() async {
    if (_currentUser == null) {
      throw const AuthStateException('No authenticated user for manual sync');
    }
    
    try {
      SecureLogger.info('Manual sync triggered');
      _triggerCloudSync(_currentUser!.id);
    } catch (e) {
      throw AuthStateException('Manual sync failed: $e');
    }
  }
  
  /// Get current authentication status summary
  AuthStatusSummary getAuthStatusSummary() {
    return AuthStatusSummary(
      isAuthenticated: isAuthenticated,
      userId: _currentUser?.id,
      email: _currentUser?.email,
      isEmailVerified: _currentUser?.emailConfirmedAt != null,
      authState: _currentAuthState,
      dataInitStatus: _dataInitStatus,
      syncStatus: _syncStatus,
      profileName: _currentUserProfile?.name,
    );
  }
  
  /// Dispose resources
  void dispose() {
    SecureLogger.info('AuthStateManager: Disposing resources');
    _authStateSubscription?.cancel();
    _isInitialized = false;
  }
}

/// Authentication states
enum AuthState {
  unknown,
  signedOut,
  signedInUnverified,
  signedInVerified,
  error,
}

/// Data initialization status
enum DataInitializationStatus {
  notStarted,
  inProgress,
  completed,
  failed,
}

/// Sync status
enum SyncStatus {
  idle,
  syncing,
  completed,
  failed,
}

/// Authentication status summary
class AuthStatusSummary {
  final bool isAuthenticated;
  final String? userId;
  final String? email;
  final bool isEmailVerified;
  final AuthState authState;
  final DataInitializationStatus dataInitStatus;
  final SyncStatus syncStatus;
  final String? profileName;
  
  const AuthStatusSummary({
    required this.isAuthenticated,
    this.userId,
    this.email,
    required this.isEmailVerified,
    required this.authState,
    required this.dataInitStatus,
    required this.syncStatus,
    this.profileName,
  });
  
  @override
  String toString() {
    return 'AuthStatusSummary(authenticated: $isAuthenticated, '
        'verified: $isEmailVerified, state: $authState, '
        'dataInit: $dataInitStatus, sync: $syncStatus)';
  }
}

/// Custom exception for auth state management
class AuthStateException implements Exception {
  final String message;
  const AuthStateException(this.message);
  
  @override
  String toString() => 'AuthStateException: $message';
}
