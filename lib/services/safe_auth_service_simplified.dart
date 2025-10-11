import 'dart:async';
import 'unified_supabase_auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SafeAuthService {
  static final SafeAuthService _instance = SafeAuthService._internal();
  factory SafeAuthService() => _instance;
  SafeAuthService._internal();

  final bool _isInitialized = false;
  final UnifiedSupabaseAuthService _authService = UnifiedSupabaseAuthService();

  // Current user getter
  User? get currentUser {
    try {
      return _authService.currentUser;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // User state changes stream
  Stream<User?> get userChanges {
    try {
      return _authService.userChanges;
    } catch (e) {
      print('Error accessing user changes stream: $e');
      return Stream.value(null);
    }
  }

  // Sign up with email and password
  Future<Map<String, dynamic>> signUpWithEmail(String email, String password) async {
    try {
      return await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error in sign up: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Sign in with email and password
  Future<Map<String, dynamic>> signInWithEmail(String email, String password) async {
    try {
      return await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error in sign in: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      print('Error in sign out: $e');
    }
  }

  // Reset password
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
      return {'success': true};
    } catch (e) {
      print('Error in reset password: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}