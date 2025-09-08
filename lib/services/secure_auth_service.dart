import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import '../utils/aac_logger.dart';

/// Secure Authentication Service with user isolation and session management
/// This service ensures that user data is completely isolated and secure
class SecureAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static Timer? _sessionTimer;
  static const Duration _sessionTimeout = Duration(hours: 24);
  static const String _lastActivityKey = 'last_activity';
  
  /// Get current authenticated user ID
  static String? get currentUserId {
    final user = _auth.currentUser;
    return user?.uid;
  }
  
  /// Check if user is authenticated
  static bool get isAuthenticated {
    return _auth.currentUser != null;
  }
  
  /// Get current user object
  static User? get currentUser {
    return _auth.currentUser;
  }
  
  /// CRITICAL: Get user's secure document reference
  static DocumentReference? get userDocument {
    final userId = currentUserId;
    if (userId == null) return null;
    return _firestore.collection('users').doc(userId);
  }
  
  /// CRITICAL: Get user's symbols collection with complete isolation
  static CollectionReference? get userSymbolsCollection {
    final userId = currentUserId;
    if (userId == null) return null;
    return _firestore.collection('users').doc(userId).collection('symbols');
  }
  
  /// CRITICAL: Get user's favorites collection with complete isolation
  static CollectionReference? get userFavoritesCollection {
    final userId = currentUserId;
    if (userId == null) return null;
    return _firestore.collection('users').doc(userId).collection('favorites');
  }
  
  /// CRITICAL: Get user's history collection with complete isolation
  static CollectionReference? get userHistoryCollection {
    final userId = currentUserId;
    if (userId == null) return null;
    return _firestore.collection('users').doc(userId).collection('history');
  }
  
  /// Initialize secure session management
  static Future<void> initializeSecureSession() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _updateLastActivity();
        await _enforceSessionTimeout();
        _startSessionTimer();
        AACLogger.info('Secure session initialized for user: ${hashUserId(user.uid)}');
      }
    } catch (e) {
      AACLogger.error('Failed to initialize secure session: $e');
    }
  }
  
  /// Update last activity timestamp
  static Future<void> _updateLastActivity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastActivityKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      AACLogger.warning('Failed to update last activity: $e');
    }
  }
  
  /// CRITICAL: Enforce session timeout for security
  static Future<void> _enforceSessionTimeout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastActivity = prefs.getInt(_lastActivityKey);
      
      if (lastActivity != null) {
        final lastActivityTime = DateTime.fromMillisecondsSinceEpoch(lastActivity);
        final timeSince = DateTime.now().difference(lastActivityTime);
        
        if (timeSince > _sessionTimeout) {
          AACLogger.warning('Session timeout detected, signing out user');
          await secureSignOut();
        }
      }
    } catch (e) {
      AACLogger.error('Failed to enforce session timeout: $e');
    }
  }
  
  /// Start session monitoring timer
  static void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      _enforceSessionTimeout();
    });
  }
  
  /// CRITICAL: Secure sign out with complete data cleanup
  static Future<void> secureSignOut() async {
    try {
      AACLogger.info('Initiating secure sign out');
      
      // Cancel session timer
      _sessionTimer?.cancel();
      
      // Clear sensitive local data
      await _clearSensitiveLocalData();
      
      // Sign out from Firebase
      await _auth.signOut();
      
      AACLogger.info('Secure sign out completed');
    } catch (e) {
      AACLogger.error('Error during secure sign out: $e');
      // Ensure sign out even if cleanup fails
      try {
        await _auth.signOut();
      } catch (signOutError) {
        AACLogger.error('Failed to sign out from Firebase: $signOutError');
      }
    }
  }
  
  /// Clear sensitive local data on sign out
  static Future<void> _clearSensitiveLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear activity tracking
      await prefs.remove(_lastActivityKey);
      
      // Clear any cached user data
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('user_') || 
            key.startsWith('cached_') || 
            key.startsWith('profile_')) {
          await prefs.remove(key);
        }
      }
      
      AACLogger.info('Sensitive local data cleared');
    } catch (e) {
      AACLogger.warning('Failed to clear some local data: $e');
    }
  }
  
  /// CRITICAL: Hash user ID for logging/analytics (privacy protection)
  static String hashUserId(String userId) {
    final bytes = utf8.encode(userId + 'aac_app_security_salt_2024');
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 8); // Use first 8 characters
  }
  
  /// Validate user email domain (prevent fake/spam accounts)
  static bool isValidEmailDomain(String email) {
    final validDomains = [
      'gmail.com', 'yahoo.com', 'outlook.com', 'hotmail.com',
      'icloud.com', 'protonmail.com', 'aol.com'
    ];
    
    final domain = email.split('@').last.toLowerCase();
    return validDomains.contains(domain);
  }
  
  /// Update user activity (call this on user interactions)
  static Future<void> updateUserActivity() async {
    if (isAuthenticated) {
      await _updateLastActivity();
    }
  }
  
  /// Get authentication state stream
  static Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }
  
  /// Clean up resources
  static void dispose() {
    _sessionTimer?.cancel();
  }
}
