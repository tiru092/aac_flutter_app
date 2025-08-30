import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'firebase_config_service.dart';

/// Safe wrapper around AuthService that handles Firebase unavailability
class SafeAuthService {
  AuthService? _authService;
  
  SafeAuthService() {
    if (FirebaseConfigService.canUseFirebaseServices()) {
      _authService = AuthService();
    }
  }
  
  /// Check if Firebase auth is available
  bool get isAvailable => _authService != null;
  
  /// Get current user safely
  User? get currentUser {
    try {
      return _authService?.currentUser;
    } catch (e) {
      debugPrint('SafeAuthService: Error getting current user: $e');
      return null;
    }
  }
  
  /// Get auth state changes safely
  Stream<User?> get authStateChanges {
    try {
      if (_authService != null) {
        return _authService!.authStateChanges;
      }
      return Stream.value(null);
    } catch (e) {
      debugPrint('SafeAuthService: Error getting auth state changes: $e');
      return Stream.value(null);
    }
  }
  
  /// Sign up with email safely
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    if (_authService == null) {
      throw AuthException('Firebase authentication not available', 'firebase_unavailable');
    }
    
    try {
      return await _authService!.signUpWithEmail(
        email: email,
        password: password,
        name: name,
      );
    } catch (e) {
      rethrow;
    }
  }
  
  /// Sign in with email safely
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (_authService == null) {
      throw AuthException('Firebase authentication not available', 'firebase_unavailable');
    }
    
    try {
      return await _authService!.signInWithEmail(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
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
  
  /// Check email verification safely
  Future<bool> isEmailVerified() async {
    if (_authService == null) return true; // No verification needed if no Firebase
    
    try {
      return await _authService!.isEmailVerified();
    } catch (e) {
      debugPrint('SafeAuthService: Error checking email verification: $e');
      return true;
    }
  }
  
  /// Send verification email safely
  Future<void> sendVerificationEmail() async {
    if (_authService == null) {
      throw AuthException('Firebase authentication not available', 'firebase_unavailable');
    }
    
    try {
      await _authService!.sendVerificationEmail();
    } catch (e) {
      rethrow;
    }
  }
  
  /// Reset password safely
  Future<void> resetPassword(String email) async {
    if (_authService == null) {
      throw AuthException('Firebase authentication not available', 'firebase_unavailable');
    }
    
    try {
      await _authService!.resetPassword(email);
    } catch (e) {
      rethrow;
    }
  }
}