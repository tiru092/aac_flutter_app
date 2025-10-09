import 'package:supabase_flutter/supabase_flutter.dart';
import 'unified_supabase_auth_service.dart';

/// Wrapper class to maintain backward compatibility with Firebase AuthService API
/// All methods delegate to UnifiedSupabaseAuthService
class UserCredential {
  final User user;
  
  UserCredential({required this.user});
}

class AuthException implements Exception {
  final String code;
  final String message;
  
  AuthException(this.code, this.message);
  
  @override
  String toString() => 'AuthException: $message (code: $code)';
}

class AuthService {
  // Static validation methods
  static String? validateSignUpInputs({
    required String email,
    required String password,
    required String name,
  }) {
    if (email.isEmpty) return 'Email is required';
    if (password.isEmpty) return 'Password is required';
    if (name.isEmpty) return 'Name is required';
    
    final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegExp.hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    
    if (password.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    
    return null;
  }

  static String? validateLinkProfileInput({required String profileId}) {
    if (profileId.isEmpty) return 'Profile ID is required';
    return null;
  }

  // Getter for current user
  User? get currentUser => UnifiedSupabaseAuthService.currentUser;

  // Auth state stream
  Stream<AuthState> get authStateChanges => UnifiedSupabaseAuthService.authStateChanges;

  // Sign up with email and password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await UnifiedSupabaseAuthService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: name,
      );
      
      return UserCredential(user: response.user!);
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException('signup-failed', e.toString());
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await UnifiedSupabaseAuthService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      return UserCredential(user: response.user!);
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException('signin-failed', e.toString());
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await UnifiedSupabaseAuthService.signOut();
    } catch (e) {
      throw AuthException('signout-failed', e.toString());
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await UnifiedSupabaseAuthService.sendPasswordResetEmail(email: email);
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException('reset-failed', e.toString());
    }
  }

  // Send verification email
  Future<void> sendVerificationEmail() async {
    try {
      await UnifiedSupabaseAuthService.sendVerificationEmail();
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException('verification-failed', e.toString());
    }
  }

  // Check if email is verified
  Future<bool> isEmailVerified() async {
    try {
      return UnifiedSupabaseAuthService.isEmailVerified;
    } catch (e) {
      throw AuthException('verification-check-failed', e.toString());
    }
  }

  // Update user profile
  Future<void> updateUserProfile({String? displayName}) async {
    try {
      if (displayName != null) {
        await UnifiedSupabaseAuthService.updateDisplayName(displayName: displayName);
      }
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException('profile-update-failed', e.toString());
    }
  }

  // Delete user account - Not implemented yet in Supabase migration
  Future<void> deleteUserAccount() async {
    throw AuthException('delete-not-implemented', 'Account deletion not yet implemented in Supabase migration');
  }
}