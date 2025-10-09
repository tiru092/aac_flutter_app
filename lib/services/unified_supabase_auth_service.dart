/// Unified Supabase Authentication Service
/// Replaces all Firebase Auth functionality with Supabase Auth
/// Maintains the same API interface for seamless migration

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../utils/aac_logger.dart';

class UnifiedSupabaseAuthService {
  static const String _tag = 'UnifiedSupabaseAuth';
  static SupabaseClient get _supabase => Supabase.instance.client;
  
  // ============================================================================
  // CURRENT USER ACCESS (Replaces FirebaseAuth.instance.currentUser)
  // ============================================================================
  
  /// Get current authenticated user (replaces FirebaseAuth.instance.currentUser)
  static User? get currentUser => _supabase.auth.currentUser;
  
  /// Get current user ID (replaces FirebaseAuth.instance.currentUser?.uid)
  static String? get currentUserId => _supabase.auth.currentUser?.id;
  
  /// Check if user is authenticated
  static bool get isAuthenticated => _supabase.auth.currentUser != null;
  
  /// Get user email
  static String? get currentUserEmail => _supabase.auth.currentUser?.email;
  
  /// Get user display name (from user metadata)
  static String? get currentUserDisplayName => 
      _supabase.auth.currentUser?.userMetadata?['display_name'] ?? 
      _supabase.auth.currentUser?.userMetadata?['full_name'];
  
  // ============================================================================
  // AUTHENTICATION METHODS
  // ============================================================================
  
  /// Sign up with email and password
  static Future<AuthResponse> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      AACLogger.info('$_tag: Starting sign up for $email');
      
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'display_name': displayName} : null,
      );
      
      if (response.user != null) {
        AACLogger.info('$_tag: Sign up successful for ${response.user!.email}');
        
        // Create user profile in our user_profiles table
        await _createUserProfile(response.user!);
      }
      
      return response;
    } catch (e) {
      AACLogger.error('$_tag: Sign up failed: $e');
      rethrow;
    }
  }
  
  /// Sign in with email and password
  static Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      AACLogger.info('$_tag: Starting sign in for $email');
      
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        AACLogger.info('$_tag: Sign in successful for ${response.user!.email}');
        
        // Ensure user profile exists in our database
        await _ensureUserProfile(response.user!);
      }
      
      return response;
    } catch (e) {
      AACLogger.error('$_tag: Sign in failed: $e');
      rethrow;
    }
  }
  
  /// Sign out current user
  static Future<void> signOut() async {
    try {
      final userEmail = currentUserEmail;
      await _supabase.auth.signOut();
      AACLogger.info('$_tag: Sign out successful for $userEmail');
    } catch (e) {
      AACLogger.error('$_tag: Sign out failed: $e');
      rethrow;
    }
  }
  
  /// Send password reset email
  static Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      AACLogger.info('$_tag: Password reset email sent to $email');
    } catch (e) {
      AACLogger.error('$_tag: Password reset failed: $e');
      rethrow;
    }
  }
  
  /// Update user password
  static Future<UserResponse> updatePassword({required String newPassword}) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      AACLogger.info('$_tag: Password updated successfully');
      return response;
    } catch (e) {
      AACLogger.error('$_tag: Password update failed: $e');
      rethrow;
    }
  }
  
  /// Update user email
  static Future<UserResponse> updateEmail({required String newEmail}) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(email: newEmail),
      );
      AACLogger.info('$_tag: Email update initiated for $newEmail');
      return response;
    } catch (e) {
      AACLogger.error('$_tag: Email update failed: $e');
      rethrow;
    }
  }
  
  /// Update user display name
  static Future<UserResponse> updateDisplayName({required String displayName}) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(data: {'display_name': displayName}),
      );
      
      // Also update in user_profiles table
      if (currentUserId != null) {
        await _supabase.from('user_profiles').upsert({
          'id': currentUserId!,
          'name': displayName,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
      
      AACLogger.info('$_tag: Display name updated to: $displayName');
      return response;
    } catch (e) {
      AACLogger.error('$_tag: Display name update failed: $e');
      rethrow;
    }
  }
  
  /// Send email verification
  static Future<void> sendEmailVerification() async {
    try {
      if (currentUser?.emailConfirmedAt == null) {
        await _supabase.auth.resend(
          type: OtpType.signup,
          email: currentUser!.email!,
        );
        AACLogger.info('$_tag: Email verification sent');
      }
    } catch (e) {
      AACLogger.error('$_tag: Email verification failed: $e');
      rethrow;
    }
  }
  
  /// Send verification email (alias for backward compatibility)
  static Future<void> sendVerificationEmail() => sendEmailVerification();
  
  /// Check if email is verified
  static bool get isEmailVerified => currentUser?.emailConfirmedAt != null;
  
  // ============================================================================
  // AUTH STATE CHANGES (Replaces FirebaseAuth.instance.authStateChanges())
  // ============================================================================
  
  /// Listen to auth state changes
  static Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  
  /// Listen to user changes (simplified interface)
  static Stream<User?> get userChanges => 
      _supabase.auth.onAuthStateChange.map((data) => data.session?.user);
  
  // ============================================================================
  // USER PROFILE MANAGEMENT
  // ============================================================================
  
  /// Create user profile in our database after signup
  static Future<void> _createUserProfile(User user) async {
    try {
      final profileData = {
        'id': user.id,
        'name': user.userMetadata?['display_name'] ?? 
                user.userMetadata?['full_name'] ?? 
                'AAC User',
        'email': user.email ?? '',
        'role': 'communicator',
        'avatar_url': user.userMetadata?['avatar_url'],
        'settings': <String, dynamic>{},
        'app_settings': <String, dynamic>{},
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'last_active_at': DateTime.now().toIso8601String(),
        'is_active': true,
      };
      
      await _supabase.from('user_profiles').upsert(profileData);
      AACLogger.info('$_tag: User profile created for ${user.email}');
    } catch (e) {
      AACLogger.warning('$_tag: Failed to create user profile: $e');
      // Don't rethrow - auth should succeed even if profile creation fails
    }
  }
  
  /// Ensure user profile exists (called on sign in)
  static Future<void> _ensureUserProfile(User user) async {
    try {
      // Check if profile exists
      final existingProfile = await _supabase
          .from('user_profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();
      
      if (existingProfile == null) {
        // Create profile if it doesn't exist
        await _createUserProfile(user);
      } else {
        // Update last active time
        await _supabase.from('user_profiles').update({
          'last_active_at': DateTime.now().toIso8601String(),
        }).eq('id', user.id);
      }
    } catch (e) {
      AACLogger.warning('$_tag: Failed to ensure user profile: $e');
    }
  }
  
  // ============================================================================
  // MIGRATION HELPERS
  // ============================================================================
  
  /// Initialize service (called during app startup)
  static Future<void> initialize() async {
    try {
      // Supabase client is already initialized via SupabaseConfig
      AACLogger.info('$_tag: Supabase Auth Service initialized');
      
      // If user is already signed in, ensure profile exists
      final user = currentUser;
      if (user != null) {
        await _ensureUserProfile(user);
      }
    } catch (e) {
      AACLogger.error('$_tag: Initialization failed: $e');
    }
  }
  
  /// Get user info formatted for compatibility with existing code
  static Map<String, dynamic>? getUserInfo() {
    final user = currentUser;
    if (user == null) return null;
    
    return {
      'uid': user.id,  // For Firebase compatibility
      'id': user.id,
      'email': user.email,
      'displayName': currentUserDisplayName,
      'emailVerified': isEmailVerified,
      'createdAt': user.createdAt,
      'lastSignInAt': user.lastSignInAt,
      'metadata': user.userMetadata,
    };
  }
  
  /// Migration method: Create Supabase user from Firebase UID (if needed)
  static Future<bool> createSupabaseUserFromFirebaseData({
    required String firebaseUid,
    required String email,
    String? displayName,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // This would be used if migrating existing Firebase users
      // For now, we'll just log that migration capability exists
      AACLogger.info('$_tag: Migration capability available for Firebase UID: $firebaseUid');
      return true;
    } catch (e) {
      AACLogger.error('$_tag: Migration failed for Firebase UID $firebaseUid: $e');
      return false;
    }
  }
  
  // ============================================================================
  // ERROR HANDLING HELPERS
  // ============================================================================
  
  /// Convert Supabase auth exceptions to user-friendly messages
  static String getErrorMessage(dynamic exception) {
    if (exception is AuthException) {
      switch (exception.message.toLowerCase()) {
        case 'invalid login credentials':
        case 'invalid credentials':
          return 'Invalid email or password. Please try again.';
        case 'email not confirmed':
          return 'Please verify your email address before signing in.';
        case 'too many requests':
          return 'Too many attempts. Please try again later.';
        case 'user not found':
          return 'No account found with this email address.';
        case 'weak password':
          return 'Password should be at least 6 characters long.';
        case 'email already registered':
        case 'user already exists':
          return 'An account with this email already exists.';
        default:
          return exception.message;
      }
    }
    
    return exception.toString();
  }
}