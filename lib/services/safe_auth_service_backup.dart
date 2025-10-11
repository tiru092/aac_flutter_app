import 'package:flutter/foundation.dart';
import 'unified_supabase_auth_service.dart';
import 'auth_service.dart';
import 'firebase_config_service.dart';

/// Safe wrapper around UnifiedSupabaseAuthService
class SafeAuthService {
  static bool _isInitialized = true; // Supabase is always available
  
  SafeAuthService();
  
  /// Check if auth is available (always true for Supabase)
  bool get isAvailable => _isInitialized;
  
  /// Get current user safely
  dynamic get currentUser {
    try {
      return UnifiedSupabaseAuthService.currentUser;
    } catch (e) {
      debugPrint('SafeAuthService: Error getting current user: $e');
      return null;
    }
  }
  
  /// Get auth state changes safely
  Stream get authStateChanges {
    try {
      return UnifiedSupabaseAuthService.instance.userChanges;
    } catch (e) {
      debugPrint('SafeAuthService: Error getting auth state changes: $e');
      return Stream.value(null);
    }
  }

  /// Sign up with email safely
  Future<dynamic> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await UnifiedSupabaseAuthService.instance.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('SafeAuthService: Error signing up: $e');
      return null;
    }
  }

  /// Sign in with email safely
  Future<dynamic> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await UnifiedSupabaseAuthService.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('SafeAuthService: Error signing in: $e');
      return null;
    }
  }

  /// Sign out safely
  Future<void> signOut() async {
    try {
      await UnifiedSupabaseAuthService.signOut();
    } catch (e) {
      debugPrint('SafeAuthService: Error signing out: $e');
    }
  }
  
  /// Get auth state changes safely
  Stream get authStateChanges {
    try {
      return UnifiedSupabaseAuthService.instance.userChanges;
    } catch (e) {
      debugPrint('SafeAuthService: Error getting auth state changes: $e');
      return Stream.value(null);
    }
  }
  
  /// Sign up with email safely
  Future<dynamic> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await UnifiedSupabaseAuthService.instance.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('SafeAuthService: Error signing up: $e');
      return null;
    }
  }
  
  /// Sign in with email safely
  Future<dynamic> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await UnifiedSupabaseAuthService.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('SafeAuthService: Error signing in: $e');
      return null;
    }
  }
  
  /// Sign out safely
  Future<void> signOut() async {
    if (_authService == null) return;
    
    try {
      await _authService!.signOut();
    } catch (e) {
      debugPrint('SafeAuthService: Error signing out: $e');
    }
  }
  
      // Check if email is verified for new accounts
      if (user.emailConfirmedAt == null && creationTime != null && DateTime.now().difference(creationTime).inDays > 1) {
        SecureLogger.warning('User account is unverified after 24 hours');
      }  /// Send verification email safely
  Future<void> sendVerificationEmail() async {
    try {
      await UnifiedSupabaseAuthService.sendVerificationEmail();
    } catch (e) {
      rethrow;
    }
  }
  
  /// Reset password safely
  Future<void> resetPassword(String email) async {
    try {
      await UnifiedSupabaseAuthService.sendPasswordResetEmail(email);
    } catch (e) {
      rethrow;
    }
  }
}