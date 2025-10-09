import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:flutter/foundation.dart';
import '../firebase_supabase_migration_service.dart';
import '../supabase/index.dart';

/// Hybrid Authentication Service
/// Manages authentication across Firebase and Supabase during migration
class HybridAuthService {
  static HybridAuthService? _instance;
  
  // Firebase service (existing)
  final firebase.FirebaseAuth _firebaseAuth;
  
  HybridAuthService._internal({firebase.FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? firebase.FirebaseAuth.instance;
  
  factory HybridAuthService() {
    _instance ??= HybridAuthService._internal();
    return _instance!;
  }
  
  /// Get current user from primary service
  dynamic get currentUser {
    if (!migrationService.isMigrationEnabled) {
      return _firebaseAuth.currentUser;
    }
    
    if (migrationService.isSupabasePrimary) {
      return supabaseService.auth.currentUser;
    } else {
      return _firebaseAuth.currentUser;
    }
  }
  
  /// Get current user ID from primary service
  String? get currentUserId {
    final user = currentUser;
    if (user == null) return null;
    
    if (!migrationService.isMigrationEnabled) {
      return (user as firebase.User).uid;
    }
    
    if (migrationService.isSupabasePrimary) {
      return (user as supabase.User).id;
    } else {
      return (user as firebase.User).uid;
    }
  }
  
  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;
  
  /// Sign up with email and password
  Future<Map<String, dynamic>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final results = <String, dynamic>{};
      
      // Always sign up to Firebase first (existing system)
      final firebaseResult = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name if provided
      if (displayName != null) {
        await firebaseResult.user?.updateDisplayName(displayName);
      }
      
      results['firebase'] = {
        'success': true,
        'user': firebaseResult.user,
        'uid': firebaseResult.user?.uid,
      };
      
      // Sign up to Supabase if migration is enabled
      if (migrationService.isMigrationEnabled) {
        try {
          final supabaseMetadata = <String, dynamic>{
            'display_name': displayName,
            'firebase_uid': firebaseResult.user?.uid,
            ...?metadata,
          };
          
          final supabaseResult = await supabaseService.auth.signUp(
            email: email,
            password: password,
            metadata: supabaseMetadata,
          );
          
          results['supabase'] = {
            'success': true,
            'user': supabaseResult.user,
            'uid': supabaseResult.user?.id,
          };
          
          if (kDebugMode) {
            print('HybridAuthService: User signed up to both Firebase and Supabase');
          }
        } catch (supabaseError) {
          // Log Supabase error but don't fail the entire operation
          if (kDebugMode) {
            print('HybridAuthService WARNING: Supabase signup failed: $supabaseError');
          }
          results['supabase'] = {
            'success': false,
            'error': supabaseError.toString(),
          };
        }
      }
      
      return results;
    } catch (e) {
      if (kDebugMode) {
        print('HybridAuthService ERROR: Hybrid signup failed: $e');
      }
      rethrow;
    }
  }
  
  /// Sign in with email and password
  Future<Map<String, dynamic>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final results = <String, dynamic>{};
      
      if (!migrationService.isMigrationEnabled || migrationService.isFirebasePrimary) {
        // Firebase primary - sign in to Firebase first
        final firebaseResult = await _firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        results['firebase'] = {
          'success': true,
          'user': firebaseResult.user,
          'uid': firebaseResult.user?.uid,
        };
        
        // Also sign in to Supabase if migration is enabled
        if (migrationService.isMigrationEnabled) {
          try {
            final supabaseResult = await supabaseService.auth.signInWithPassword(
              email: email,
              password: password,
            );
            
            results['supabase'] = {
              'success': true,
              'user': supabaseResult.user,
              'uid': supabaseResult.user?.id,
            };
          } catch (supabaseError) {
            if (kDebugMode) {
              print('HybridAuthService WARNING: Supabase signin failed: $supabaseError');
            }
            results['supabase'] = {
              'success': false,
              'error': supabaseError.toString(),
            };
          }
        }
      } else {
        // Supabase primary - sign in to Supabase first
        final supabaseResult = await supabaseService.auth.signInWithPassword(
          email: email,
          password: password,
        );
        
        results['supabase'] = {
          'success': true,
          'user': supabaseResult.user,
          'uid': supabaseResult.user?.id,
        };
        
        // Also maintain Firebase session for compatibility
        try {
          final firebaseResult = await _firebaseAuth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          
          results['firebase'] = {
            'success': true,
            'user': firebaseResult.user,
            'uid': firebaseResult.user?.uid,
          };
        } catch (firebaseError) {
          if (kDebugMode) {
            print('HybridAuthService WARNING: Firebase signin failed: $firebaseError');
          }
          results['firebase'] = {
            'success': false,
            'error': firebaseError.toString(),
          };
        }
      }
      
      if (kDebugMode) {
        print('HybridAuthService: User signed in successfully');
      }
      return results;
    } catch (e) {
      if (kDebugMode) {
        print('HybridAuthService ERROR: Hybrid signin failed: $e');
      }
      rethrow;
    }
  }
  
  /// Sign out from both services
  Future<void> signOut() async {
    try {
      final futures = <Future>[];
      
      // Sign out from Firebase
      futures.add(_firebaseAuth.signOut());
      
      // Sign out from Supabase if migration is enabled
      if (migrationService.isMigrationEnabled) {
        futures.add(supabaseService.auth.signOut());
      }
      
      await Future.wait(futures);
      
      if (kDebugMode) {
        print('HybridAuthService: User signed out from all services');
      }
    } catch (e) {
      if (kDebugMode) {
        print('HybridAuthService ERROR: Hybrid signout failed: $e');
      }
      rethrow;
    }
  }
  
  /// Reset password
  Future<void> resetPassword({required String email}) async {
    try {
      final futures = <Future>[];
      
      // Reset password in Firebase
      futures.add(_firebaseAuth.sendPasswordResetEmail(email: email));
      
      // Reset password in Supabase if migration is enabled
      if (migrationService.isMigrationEnabled) {
        futures.add(supabaseService.auth.resetPassword(email: email));
      }
      
      await Future.wait(futures);
      
      if (kDebugMode) {
        print('HybridAuthService: Password reset sent to: $email');
      }
    } catch (e) {
      if (kDebugMode) {
        print('HybridAuthService ERROR: Hybrid password reset failed: $e');
      }
      rethrow;
    }
  }
  
  /// Get auth state changes stream
  Stream<Map<String, dynamic>> get authStateChanges {
    if (!migrationService.isMigrationEnabled) {
      return _firebaseAuth.authStateChanges().map((user) => {
        'firebase': user,
        'supabase': null,
        'primary': 'firebase',
      });
    }
    
    // For now, just return Firebase auth state - can be enhanced later
    return _firebaseAuth.authStateChanges().map((user) => {
      'firebase': user,
      'supabase': migrationService.isMigrationEnabled ? supabaseService.auth.currentUser : null,
      'primary': migrationService.isSupabasePrimary ? 'supabase' : 'firebase',
    });
  }
  
  /// Get migration status for current user
  Map<String, dynamic> getUserMigrationStatus() {
    return {
      'firebaseAuthenticated': _firebaseAuth.currentUser != null,
      'supabaseAuthenticated': migrationService.isMigrationEnabled && 
                              supabaseService.auth.isAuthenticated,
      'migrationEnabled': migrationService.isMigrationEnabled,
      'primaryService': migrationService.isSupabasePrimary ? 'supabase' : 'firebase',
    };
  }
}