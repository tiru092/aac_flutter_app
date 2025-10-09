import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

/// Supabase Authentication Service
/// Runs parallel to Firebase Auth during migration
class SupabaseAuthService {
  static SupabaseAuthService? _instance;
  late final SupabaseClient _client;
  
  SupabaseAuthService._internal() {
    _client = SupabaseConfig.client;
  }
  
  factory SupabaseAuthService() {
    _instance ??= SupabaseAuthService._internal();
    return _instance!;
  }
  
  /// Get current user
  User? get currentUser => _client.auth.currentUser;
  
  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;
  
  /// Get current user ID
  String? get currentUserId => currentUser?.id;
  
  /// Get auth state stream
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
  
  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: metadata,
      );
      
      if (kDebugMode) {
        print('Supabase sign up successful: ${response.user?.id}');
      }
      
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Supabase sign up error: $e');
      }
      rethrow;
    }
  }
  
  /// Sign in with email and password
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (kDebugMode) {
        print('Supabase sign in successful: ${response.user?.id}');
      }
      
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Supabase sign in error: $e');
      }
      rethrow;
    }
  }
  
  /// Sign out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      
      if (kDebugMode) {
        print('Supabase sign out successful');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Supabase sign out error: $e');
      }
      rethrow;
    }
  }
  
  /// Reset password
  Future<void> resetPassword({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      
      if (kDebugMode) {
        print('Supabase password reset sent to: $email');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Supabase password reset error: $e');
      }
      rethrow;
    }
  }
  
  /// Update user metadata
  Future<UserResponse> updateUser({
    Map<String, dynamic>? data,
    String? email,
    String? password,
  }) async {
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(
          email: email,
          password: password,
          data: data,
        ),
      );
      
      if (kDebugMode) {
        print('Supabase user update successful');
      }
      
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Supabase user update error: $e');
      }
      rethrow;
    }
  }
  
  /// Delete user account
  Future<void> deleteUser() async {
    try {
      // Note: This requires admin privileges or RPC function
      // For now, we'll implement account deletion via RPC
      await _client.rpc('delete_user_account');
      
      if (kDebugMode) {
        print('Supabase user account deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Supabase user deletion error: $e');
      }
      rethrow;
    }
  }
  
  /// Get user session
  Session? get currentSession => _client.auth.currentSession;
  
  /// Refresh session
  Future<AuthResponse> refreshSession() async {
    try {
      final response = await _client.auth.refreshSession();
      
      if (kDebugMode) {
        print('Supabase session refreshed');
      }
      
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Supabase session refresh error: $e');
      }
      rethrow;
    }
  }
}