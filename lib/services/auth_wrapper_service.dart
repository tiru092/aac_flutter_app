import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../services/cloud_sync_service.dart';

/// Comprehensive authentication wrapper that handles:
/// - Firebase authentication
/// - Local user profile management
/// - Multi-user support
/// - Offline functionality
/// - Data synchronization
class AuthWrapperService {
  static final AuthWrapperService _instance = AuthWrapperService._internal();
  factory AuthWrapperService() => _instance;
  AuthWrapperService._internal();

  final AuthService _authService = AuthService();
  final CloudSyncService _cloudSyncService = CloudSyncService();
  
  // Local storage keys
  static const String _isFirstLaunchKey = 'is_first_launch';
  static const String _hasLocalProfilesKey = 'has_local_profiles';
  static const String _lastSignedInUserKey = 'last_signed_in_user';
  static const String _offlineModeKey = 'offline_mode_enabled';
  static const String _hasVerifiedEmailKey = 'has_verified_email_ever';
  
  // Current state
  User? _currentFirebaseUser;
  UserProfile? _currentProfile;
  bool _isOfflineMode = false;
  bool _isInitialized = false;

  // Getters
  User? get currentFirebaseUser => _currentFirebaseUser;
  UserProfile? get currentProfile => _currentProfile;
  bool get isSignedIn => _currentFirebaseUser != null;
  bool get hasLocalProfile => _currentProfile != null;
  bool get isOfflineMode => _isOfflineMode;
  bool get isInitialized => _isInitialized;

  /// Initialize the authentication wrapper
  Future<void> initialize() async {
    try {
      debugPrint('AuthWrapperService: Initializing...');
      
      // Check if this is the first launch
      final prefs = await SharedPreferences.getInstance();
      final isFirstLaunch = prefs.getBool(_isFirstLaunchKey) ?? true;
      _isOfflineMode = prefs.getBool(_offlineModeKey) ?? false;
      
      debugPrint('AuthWrapperService: First launch: $isFirstLaunch, Offline mode: $_isOfflineMode');
      
      // Get current Firebase user
      _currentFirebaseUser = _authService.currentUser;
      
      if (_currentFirebaseUser != null) {
        debugPrint('AuthWrapperService: Found Firebase user: ${_currentFirebaseUser!.email}');
        
        // Try to load or create profile for signed-in user
        await _handleSignedInUser();
      } else {
        debugPrint('AuthWrapperService: No Firebase user found');
        
        // Check for local profiles
        await _handleLocalProfiles(isFirstLaunch);
      }
      
      // Mark as initialized
      _isInitialized = true;
      debugPrint('AuthWrapperService: Initialization complete');
      
    } catch (e) {
      debugPrint('AuthWrapperService: Error during initialization: $e');
      // Continue with offline mode
      _isOfflineMode = true;
      _isInitialized = true;
      await _handleLocalProfiles(true);
    }
  }

  /// Handle signed-in Firebase user
  Future<void> _handleSignedInUser() async {
    try {
      final user = _currentFirebaseUser!;
      
      // Try to load existing profile for this user
      UserProfile? profile = await _loadProfileForUser(user.uid);
      
      if (profile == null) {
        // Create new profile for this user
        profile = await UserProfileService.createProfile(
          name: user.displayName ?? user.email?.split('@').first ?? 'User',
          email: user.email,
        );
        
        // Link profile with Firebase user
        await _linkProfileWithUser(profile, user.uid);
        debugPrint('AuthWrapperService: Created new profile for user: ${profile.name}');
      } else {
        debugPrint('AuthWrapperService: Loaded existing profile: ${profile.name}');
      }
      
      // Set as active profile
      await UserProfileService.setActiveProfile(profile);
      _currentProfile = profile;
      
      // Sync with cloud if available
      if (!_isOfflineMode) {
        await _syncUserData();
      }
      
    } catch (e) {
      debugPrint('AuthWrapperService: Error handling signed-in user: $e');
      // Fall back to local profile management
      await _handleLocalProfiles(false);
    }
  }

  /// Handle local profiles when no Firebase user
  Future<void> _handleLocalProfiles(bool isFirstLaunch) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if we have any local profiles
      final profiles = await UserProfileService.getAllProfiles();
      
      // Clean up duplicate "Default User" profiles
      await _cleanupDuplicateProfiles(profiles);
      
      // Get updated profiles list after cleanup
      final cleanedProfiles = await UserProfileService.getAllProfiles();
      
      if (cleanedProfiles.isEmpty) {
        // No profiles exist - create default profile only once
        debugPrint('AuthWrapperService: No profiles found - creating default profile');
        
        final defaultProfile = await UserProfileService.createProfile(
          name: 'Default User',
        );
        
        _currentProfile = defaultProfile;
        await prefs.setBool(_isFirstLaunchKey, false);
        await prefs.setBool(_hasLocalProfilesKey, true);
        
        debugPrint('AuthWrapperService: Created default profile: ${defaultProfile.name}');
        
      } else {
        // Load the most recently active profile
        _currentProfile = await UserProfileService.getActiveProfile();
        
        if (_currentProfile == null) {
          // Set first profile as active if none is set
          _currentProfile = cleanedProfiles.first;
          await UserProfileService.setActiveProfile(_currentProfile!);
        }
        
        debugPrint('AuthWrapperService: Loaded local profile: ${_currentProfile!.name}');
        
        // Mark as not first launch since we have profiles
        await prefs.setBool(_isFirstLaunchKey, false);
        await prefs.setBool(_hasLocalProfilesKey, true);
      }
      
    } catch (e) {
      debugPrint('AuthWrapperService: Error handling local profiles: $e');
      
      // Create emergency fallback profile
      _currentProfile = UserProfile(
        id: 'emergency_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Emergency User',
        role: UserRole.child,
        createdAt: DateTime.now(),
        settings: ProfileSettings(),
        userSymbols: [],
        userCategories: [],
      );
    }
  }

  /// Clean up duplicate "Default User" profiles
  Future<void> _cleanupDuplicateProfiles(List<UserProfile> profiles) async {
    try {
      // Find all "Default User" profiles
      final defaultUsers = profiles.where((p) => p.name == 'Default User').toList();
      
      if (defaultUsers.length > 1) {
        debugPrint('AuthWrapperService: Found ${defaultUsers.length} duplicate Default User profiles');
        
        // Keep the first one (oldest) and delete the rest
        for (int i = 1; i < defaultUsers.length; i++) {
          await UserProfileService.deleteProfile(defaultUsers[i].id);
          debugPrint('AuthWrapperService: Deleted duplicate profile: ${defaultUsers[i].id}');
        }
        
        debugPrint('AuthWrapperService: Cleanup complete - kept 1 Default User profile');
      }
    } catch (e) {
      debugPrint('AuthWrapperService: Error cleaning up duplicate profiles: $e');
    }
  }

  /// Sign up with email and password
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      debugPrint('AuthWrapperService: Signing up user: $email');
      
      // Create Firebase account
      final userCredential = await _authService.signUpWithEmail(
        email: email,
        password: password,
        name: name,
      );
      
      _currentFirebaseUser = userCredential.user;
      
      // Create user profile
      final profile = await UserProfileService.createProfile(
        name: name,
        email: email,
      );
      
      // Link profile with Firebase user
      if (_currentFirebaseUser != null) {
        await _linkProfileWithUser(profile, _currentFirebaseUser!.uid);
      }
      
      _currentProfile = profile;
      
      // Save sign-in state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSignedInUserKey, email);
      
      debugPrint('AuthWrapperService: Sign up successful');
      
      return AuthResult.success(
        user: _currentFirebaseUser,
        profile: _currentProfile,
        message: 'Account created successfully. Please verify your email.',
      );
      
    } on AuthException catch (e) {
      debugPrint('AuthWrapperService: Sign up failed: ${e.message}');
      return AuthResult.failure(e.message);
    } catch (e) {
      debugPrint('AuthWrapperService: Unexpected sign up error: $e');
      return AuthResult.failure('Failed to create account. Please try again.');
    }
  }

  /// Sign in with email and password
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('AuthWrapperService: Signing in user: $email');
      
      // Sign in with Firebase
      final userCredential = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      
      _currentFirebaseUser = userCredential.user;
      
      // Check and store verification status if user is already verified
      if (_currentFirebaseUser != null && _currentFirebaseUser!.emailVerified) {
        await _storeVerificationStatus(true);
        debugPrint('AuthWrapperService: User is already verified, status stored');
      }
      
      // Load or create user profile
      await _handleSignedInUser();
      
      // Save sign-in state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSignedInUserKey, email);
      _isOfflineMode = false;
      await prefs.setBool(_offlineModeKey, false);
      
      debugPrint('AuthWrapperService: Sign in successful');
      
      return AuthResult.success(
        user: _currentFirebaseUser,
        profile: _currentProfile,
        message: 'Signed in successfully.',
      );
      
    } on AuthException catch (e) {
      debugPrint('AuthWrapperService: Sign in failed: ${e.message}');
      return AuthResult.failure(e.message);
    } catch (e) {
      debugPrint('AuthWrapperService: Unexpected sign in error: $e');
      return AuthResult.failure('Failed to sign in. Please try again.');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      debugPrint('AuthWrapperService: Signing out');
      
      // Sign out from Firebase
      await _authService.signOut();
      _currentFirebaseUser = null;
      
      // Keep local profile active for offline use
      // _currentProfile remains available
      
      // Clear sign-in state
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastSignedInUserKey);
      
      debugPrint('AuthWrapperService: Sign out successful');
      
    } catch (e) {
      debugPrint('AuthWrapperService: Error during sign out: $e');
    }
  }

  /// Switch to offline mode
  Future<void> enableOfflineMode() async {
    try {
      debugPrint('AuthWrapperService: Enabling offline mode');
      
      // Check if user has ever verified their email before allowing offline access
      final hasVerified = await hasEverVerifiedEmail();
      if (!hasVerified) {
        debugPrint('AuthWrapperService: Cannot enable offline mode - user has never verified email');
        throw Exception('Email verification required before offline access');
      }
      
      _isOfflineMode = true;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_offlineModeKey, true);
      
      // Ensure we have a local profile
      if (_currentProfile == null) {
        await _handleLocalProfiles(false);
      }
      
      debugPrint('AuthWrapperService: Offline mode enabled');
      
    } catch (e) {
      debugPrint('AuthWrapperService: Error enabling offline mode: $e');
      rethrow;
    }
  }

  /// Switch to online mode and sync
  Future<AuthResult> enableOnlineMode() async {
    try {
      debugPrint('AuthWrapperService: Enabling online mode');
      
      _isOfflineMode = false;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_offlineModeKey, false);
      
      // Try to restore previous sign-in
      final lastSignedInUser = prefs.getString(_lastSignedInUserKey);
      
      if (lastSignedInUser != null && _currentFirebaseUser == null) {
        return AuthResult.failure(
          'Please sign in to sync your data online.',
        );
      }
      
      // Sync data if signed in
      if (_currentFirebaseUser != null) {
        await _syncUserData();
      }
      
      debugPrint('AuthWrapperService: Online mode enabled');
      
      return AuthResult.success(
        user: _currentFirebaseUser,
        profile: _currentProfile,
        message: 'Online mode enabled.',
      );
      
    } catch (e) {
      debugPrint('AuthWrapperService: Error enabling online mode: $e');
      return AuthResult.failure('Failed to enable online mode.');
    }
  }

  /// Create a new local profile
  Future<UserProfile> createLocalProfile({
    required String name,
    String? email,
    String? phoneNumber,
  }) async {
    try {
      debugPrint('AuthWrapperService: Creating local profile: $name');
      
      final profile = await UserProfileService.createProfile(
        name: name,
        email: email,
        phoneNumber: phoneNumber,
      );
      
      // If this is the first profile, set it as current
      if (_currentProfile == null) {
        _currentProfile = profile;
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasLocalProfilesKey, true);
      
      debugPrint('AuthWrapperService: Local profile created: ${profile.name}');
      
      return profile;
      
    } catch (e) {
      debugPrint('AuthWrapperService: Error creating local profile: $e');
      rethrow;
    }
  }

  /// Switch between local profiles
  Future<void> switchProfile(UserProfile profile) async {
    try {
      debugPrint('AuthWrapperService: Switching to profile: ${profile.name}');
      
      await UserProfileService.setActiveProfile(profile);
      _currentProfile = profile;
      
      // Sync if online and signed in
      if (!_isOfflineMode && _currentFirebaseUser != null) {
        await _syncUserData();
      }
      
      debugPrint('AuthWrapperService: Profile switched successfully');
      
    } catch (e) {
      debugPrint('AuthWrapperService: Error switching profile: $e');
      rethrow;
    }
  }

  /// Get all available profiles
  Future<List<UserProfile>> getAllProfiles() async {
    try {
      return await UserProfileService.getAllProfiles();
    } catch (e) {
      debugPrint('AuthWrapperService: Error getting profiles: $e');
      return [];
    }
  }

  /// Link a profile with Firebase user
  Future<void> _linkProfileWithUser(UserProfile profile, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_${profile.id}_user', userId);
      await prefs.setString('user_${userId}_profile', profile.id);
      
      debugPrint('AuthWrapperService: Linked profile ${profile.id} with user $userId');
      
    } catch (e) {
      debugPrint('AuthWrapperService: Error linking profile with user: $e');
    }
  }

  /// Load profile for Firebase user
  Future<UserProfile?> _loadProfileForUser(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileId = prefs.getString('user_${userId}_profile');
      
      if (profileId != null) {
        final profiles = await UserProfileService.getAllProfiles();
        return profiles.firstWhere(
          (profile) => profile.id == profileId,
          orElse: () => throw Exception('Profile not found'),
        );
      }
      
      return null;
      
    } catch (e) {
      debugPrint('AuthWrapperService: Error loading profile for user: $e');
      return null;
    }
  }

  /// Sync user data with cloud
  Future<void> _syncUserData() async {
    try {
      if (_isOfflineMode || _currentFirebaseUser == null) return;
      
      debugPrint('AuthWrapperService: Syncing user data...');
      
      // Sync profiles
      await UserProfileService.syncAllProfilesToCloud();
      
      debugPrint('AuthWrapperService: Data sync completed');
      
    } catch (e) {
      debugPrint('AuthWrapperService: Error syncing data: $e');
      // Don't throw - sync failures shouldn't break the app
    }
  }

  /// Check if email verification is required
  Future<bool> isEmailVerificationRequired() async {
    if (_currentFirebaseUser == null) return false;
    
    try {
      // Always reload user first to get the latest verification status
      await _currentFirebaseUser!.reload();
      final updatedUser = FirebaseAuth.instance.currentUser;
      
      if (updatedUser == null) {
        // User was signed out during reload - they need to sign in again
        _currentFirebaseUser = null;
        return false;
      }
      
      // Update our reference
      _currentFirebaseUser = updatedUser;
      
      // Check if email is verified
      final isVerified = updatedUser.emailVerified;
      
      debugPrint('AuthWrapperService: Email verification check - isVerified: $isVerified');
      
      // If user is verified, store this status permanently
      if (isVerified) {
        await _storeVerificationStatus(true);
      }
      
      // Only require verification if email is definitely not verified
      // Be more lenient to avoid verification loops
      return !isVerified;
      
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthWrapperService: Firebase auth error during verification check: ${e.code} - ${e.message}');
      
      if (e.code == 'user-not-found' || e.code == 'user-token-expired') {
        // User session is invalid - sign them out and require re-authentication
        _currentFirebaseUser = null;
        await _authService.signOut();
        return false;
      }
      
      // For other Firebase auth errors, assume verified to avoid blocking users
      return false;
    } catch (e) {
      debugPrint('AuthWrapperService: Error checking email verification (assuming verified): $e');
      // If there's an error checking, assume verified to avoid blocking users
      return false;
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    try {
      await _authService.sendVerificationEmail();
    } catch (e) {
      debugPrint('AuthWrapperService: Error sending email verification: $e');
      rethrow;
    }
  }

  /// Store email verification status
  Future<void> _storeVerificationStatus(bool isVerified) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasVerifiedEmailKey, isVerified);
      debugPrint('AuthWrapperService: Stored verification status: $isVerified');
    } catch (e) {
      debugPrint('AuthWrapperService: Error storing verification status: $e');
    }
  }

  /// Check if user has ever verified their email
  Future<bool> hasEverVerifiedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasVerified = prefs.getBool(_hasVerifiedEmailKey) ?? false;
      debugPrint('AuthWrapperService: Has ever verified email: $hasVerified');
      return hasVerified;
    } catch (e) {
      debugPrint('AuthWrapperService: Error checking verification history: $e');
      return false;
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
    } catch (e) {
      debugPrint('AuthWrapperService: Error resetting password: $e');
      rethrow;
    }
  }
}

/// Result class for authentication operations
class AuthResult {
  final bool isSuccess;
  final String message;
  final User? user;
  final UserProfile? profile;

  AuthResult._({
    required this.isSuccess,
    required this.message,
    this.user,
    this.profile,
  });

  factory AuthResult.success({
    required String message,
    User? user,
    UserProfile? profile,
  }) => AuthResult._(
    isSuccess: true,
    message: message,
    user: user,
    profile: profile,
  );

  factory AuthResult.failure(String message) => AuthResult._(
    isSuccess: false,
    message: message,
  );
}