import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

/// Service to handle Firebase configuration and initialization
class FirebaseConfigService {
  static bool _isInitialized = false;
  static bool _isAvailable = false;
  
  /// Check if Firebase is available and properly configured
  static bool get isAvailable => _isAvailable;
  
  /// Check if Firebase has been initialized
  static bool get isInitialized => _isInitialized;
  
  /// Initialize Firebase with proper error handling
  static Future<bool> initialize() async {
    try {
      debugPrint('FirebaseConfigService: Attempting to initialize Firebase...');
      
      // Check if Firebase is already initialized
      if (Firebase.apps.isNotEmpty) {
        debugPrint('FirebaseConfigService: Firebase already initialized');
        _isInitialized = true;
        _isAvailable = true;
        return true;
      }
      
      // Try to initialize Firebase
      await Firebase.initializeApp();
      
      _isInitialized = true;
      _isAvailable = true;
      
      debugPrint('FirebaseConfigService: Firebase initialized successfully');
      return true;
      
    } on FirebaseException catch (e) {
      debugPrint('FirebaseConfigService: Firebase initialization failed with FirebaseException: ${e.message}');
      debugPrint('FirebaseConfigService: Error code: ${e.code}');
      
      _isInitialized = false;
      _isAvailable = false;
      
      // Handle specific Firebase errors
      switch (e.code) {
        case 'no-app':
          debugPrint('FirebaseConfigService: No Firebase app configured. App will run in offline mode.');
          break;
        case 'duplicate-app':
          debugPrint('FirebaseConfigService: Firebase app already exists. Continuing...');
          _isInitialized = true;
          _isAvailable = true;
          return true;
        default:
          debugPrint('FirebaseConfigService: Unknown Firebase error: ${e.code}');
      }
      
      return false;
      
    } catch (e) {
      debugPrint('FirebaseConfigService: Firebase initialization failed with general error: $e');
      
      // Check if it's a configuration issue
      if (e.toString().contains('google-services.json') || 
          e.toString().contains('GoogleService-Info.plist') ||
          e.toString().contains('No Firebase App')) {
        debugPrint('FirebaseConfigService: Firebase configuration files missing. App will run in offline mode.');
      }
      
      _isInitialized = false;
      _isAvailable = false;
      return false;
    }
  }
  
  /// Get the default Firebase app if available
  static FirebaseApp? getDefaultApp() {
    try {
      if (_isAvailable && Firebase.apps.isNotEmpty) {
        return Firebase.app();
      }
      return null;
    } catch (e) {
      debugPrint('FirebaseConfigService: Error getting default app: $e');
      return null;
    }
  }
  
  /// Check if Firebase services are ready to use
  static bool canUseFirebaseServices() {
    return _isInitialized && _isAvailable && Firebase.apps.isNotEmpty;
  }
  
  /// Get Firebase initialization status message
  static String getStatusMessage() {
    if (_isInitialized && _isAvailable) {
      return 'Firebase is initialized and ready';
    } else if (_isInitialized && !_isAvailable) {
      return 'Firebase initialized but services unavailable';
    } else {
      return 'Firebase not configured - running in offline mode';
    }
  }
}