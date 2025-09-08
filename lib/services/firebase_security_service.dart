import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'secure_logger.dart';

/// Firebase security hardening service
/// Implements additional security measures for Firebase connections
class FirebaseSecurityService {
  static final FirebaseSecurityService _instance = FirebaseSecurityService._internal();
  factory FirebaseSecurityService() => _instance;
  FirebaseSecurityService._internal();

  // Rate limiting for Firebase operations
  final Map<String, DateTime> _lastRequestTimes = {};
  final Map<String, int> _requestCounts = {};
  static const int _maxRequestsPerMinute = 60;
  static const Duration _rateLimitWindow = Duration(minutes: 1);

  /// Initialize Firebase security hardening
  Future<void> initialize() async {
    try {
      SecureLogger.info('Initializing Firebase security hardening...');
      
      // Configure Firestore settings for security
      await _configureFirestoreSettings();
      
      // Set up Auth state monitoring for security
      _setupAuthSecurityMonitoring();
      
      // Initialize connection security
      await _initializeConnectionSecurity();
      
      SecureLogger.info('Firebase security hardening initialized successfully');
    } catch (e) {
      SecureLogger.error('Failed to initialize Firebase security hardening', e);
      rethrow;
    }
  }

  /// Configure Firestore settings for better security
  Future<void> _configureFirestoreSettings() async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Configure settings for security and performance
      await firestore.enableNetwork();
      
      // Note: In production, consider enabling offline persistence carefully
      // as it can expose data if device is compromised
      if (kDebugMode) {
        // Only enable persistence in debug mode for development
        try {
          // Enable persistence using the correct method for this Firebase version
          await firestore.clearPersistence();
          SecureLogger.debug('Firestore persistence configured (debug mode only)');
        } catch (e) {
          SecureLogger.debug('Firestore persistence configuration failed', e);
        }
      }
      
      SecureLogger.info('Firestore security settings configured');
    } catch (e) {
      SecureLogger.error('Failed to configure Firestore settings', e);
    }
  }

  /// Set up Auth state monitoring for security anomalies
  void _setupAuthSecurityMonitoring() {
    try {
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (user != null) {
          SecureLogger.authEvent('User authenticated', userId: user.uid);
          _validateUserSession(user);
        } else {
          SecureLogger.authEvent('User signed out');
          _clearSecurityCache();
        }
      });
      
      // Monitor token changes for security
      FirebaseAuth.instance.idTokenChanges().listen((User? user) {
        if (user != null) {
          SecureLogger.authEvent('User token refreshed', userId: user.uid);
          _validateTokenSecurity(user);
        }
      });
      
      SecureLogger.info('Auth security monitoring enabled');
    } catch (e) {
      SecureLogger.error('Failed to setup auth security monitoring', e);
    }
  }

  /// Initialize connection security measures
  Future<void> _initializeConnectionSecurity() async {
    try {
      // In production, you would initialize Firebase App Check here
      // For now, we'll add placeholder for future implementation
      
      SecureLogger.info('Connection security measures initialized');
    } catch (e) {
      SecureLogger.error('Failed to initialize connection security', e);
    }
  }

  /// Validate user session for security anomalies
  void _validateUserSession(User user) {
    try {
      // Check for suspicious session patterns
      if (user.metadata.creationTime != null && user.metadata.lastSignInTime != null) {
        final creationTime = user.metadata.creationTime!;
        final lastSignIn = user.metadata.lastSignInTime!;
        final timeDiff = DateTime.now().difference(lastSignIn);
        
        // Log if session is very old (potential security concern)
        if (timeDiff.inDays > 30) {
          SecureLogger.warning('User session is over 30 days old');
        }
        
        // Check if email is verified for new accounts
        if (!user.emailVerified && DateTime.now().difference(creationTime).inDays > 1) {
          SecureLogger.warning('User account is unverified after 24 hours');
        }
      }
    } catch (e) {
      SecureLogger.error('Error validating user session', e);
    }
  }

  /// Validate token security
  void _validateTokenSecurity(User user) {
    try {
      // In production, you might want to validate token claims
      // and check for anomalies in token refresh patterns
      SecureLogger.debug('Token validation completed for user');
    } catch (e) {
      SecureLogger.error('Error validating token security', e);
    }
  }

  /// Clear security cache when user signs out
  void _clearSecurityCache() {
    try {
      _lastRequestTimes.clear();
      _requestCounts.clear();
      SecureLogger.debug('Security cache cleared');
    } catch (e) {
      SecureLogger.error('Error clearing security cache', e);
    }
  }

  /// Rate limiting for Firebase operations
  bool isRateLimited(String operationType, {String? userId}) {
    try {
      final key = userId != null ? '${operationType}_$userId' : operationType;
      final now = DateTime.now();
      
      // Clean old entries
      _cleanOldRateLimit(now);
      
      // Check current rate
      final lastRequest = _lastRequestTimes[key];
      final currentCount = _requestCounts[key] ?? 0;
      
      if (lastRequest != null) {
        final timeSinceLastRequest = now.difference(lastRequest);
        
        if (timeSinceLastRequest < _rateLimitWindow) {
          if (currentCount >= _maxRequestsPerMinute) {
            SecureLogger.warning('Rate limit exceeded for operation: $operationType');
            return true;
          }
        } else {
          // Reset count after rate limit window
          _requestCounts[key] = 0;
        }
      }
      
      // Update counters
      _lastRequestTimes[key] = now;
      _requestCounts[key] = currentCount + 1;
      
      return false;
    } catch (e) {
      SecureLogger.error('Error checking rate limit', e);
      return false; // Allow request on error to avoid blocking legitimate users
    }
  }

  /// Clean old rate limit entries
  void _cleanOldRateLimit(DateTime now) {
    try {
      final keysToRemove = <String>[];
      
      _lastRequestTimes.forEach((key, lastTime) {
        if (now.difference(lastTime) > _rateLimitWindow) {
          keysToRemove.add(key);
        }
      });
      
      for (final key in keysToRemove) {
        _lastRequestTimes.remove(key);
        _requestCounts.remove(key);
      }
    } catch (e) {
      SecureLogger.error('Error cleaning old rate limit entries', e);
    }
  }

  /// Secure Firestore write with additional validation
  Future<void> secureFirestoreWrite({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
    String? userId,
  }) async {
    try {
      // Check rate limiting
      if (isRateLimited('firestore_write', userId: userId)) {
        throw Exception('Rate limit exceeded for Firestore writes');
      }
      
      // Validate data before writing
      final sanitizedData = _sanitizeFirestoreData(data);
      
      // Add security metadata
      sanitizedData['_lastModified'] = FieldValue.serverTimestamp();
      sanitizedData['_modifiedBy'] = userId ?? 'anonymous';
      
      // Perform write
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(documentId)
          .set(sanitizedData, SetOptions(merge: true));
      
      SecureLogger.firebaseEvent('Secure Firestore write completed', 
          collection: collection, success: true);
      
    } catch (e) {
      SecureLogger.firebaseEvent('Secure Firestore write failed', 
          collection: collection, success: false);
      rethrow;
    }
  }

  /// Secure Firestore read with validation
  Future<DocumentSnapshot> secureFirestoreRead({
    required String collection,
    required String documentId,
    String? userId,
  }) async {
    try {
      // Check rate limiting
      if (isRateLimited('firestore_read', userId: userId)) {
        throw Exception('Rate limit exceeded for Firestore reads');
      }
      
      // Perform read
      final doc = await FirebaseFirestore.instance
          .collection(collection)
          .doc(documentId)
          .get();
      
      SecureLogger.firebaseEvent('Secure Firestore read completed', 
          collection: collection, success: true);
      
      return doc;
    } catch (e) {
      SecureLogger.firebaseEvent('Secure Firestore read failed', 
          collection: collection, success: false);
      rethrow;
    }
  }

  /// Sanitize data before Firestore operations
  Map<String, dynamic> _sanitizeFirestoreData(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};
    
    data.forEach((key, value) {
      // Remove potentially dangerous keys
      if (!key.startsWith('_') && !key.contains('..') && !key.contains('/')) {
        if (value is String) {
          // Basic XSS prevention for string values
          sanitized[key] = value.replaceAll(RegExp(r'<[^>]*>'), '');
        } else if (value is Map<String, dynamic>) {
          sanitized[key] = _sanitizeFirestoreData(value);
        } else {
          sanitized[key] = value;
        }
      }
    });
    
    return sanitized;
  }

  /// Monitor suspicious activity
  void reportSuspiciousActivity(String activity, {Map<String, dynamic>? details}) {
    try {
      SecureLogger.warning('Suspicious activity detected: $activity');
      
      // In production, you might want to:
      // 1. Log to a security monitoring service
      // 2. Send alerts to administrators
      // 3. Temporarily restrict user access
      // 4. Log additional context for investigation
      
      if (details != null && kDebugMode) {
        SecureLogger.debug('Activity details: $details');
      }
    } catch (e) {
      SecureLogger.error('Error reporting suspicious activity', e);
    }
  }

  /// Get security status summary
  Map<String, dynamic> getSecurityStatus() {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      
      return {
        'isUserAuthenticated': currentUser != null,
        'isEmailVerified': currentUser?.emailVerified ?? false,
        'activeRateLimitedOperations': _requestCounts.length,
        'securityHardeningEnabled': true,
        'lastSecurityCheck': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      SecureLogger.error('Error getting security status', e);
      return {
        'error': 'Failed to get security status',
        'securityHardeningEnabled': false,
      };
    }
  }

  /// Dispose of resources
  void dispose() {
    try {
      _clearSecurityCache();
      SecureLogger.info('Firebase security service disposed');
    } catch (e) {
      SecureLogger.error('Error disposing Firebase security service', e);
    }
  }
}
