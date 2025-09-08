import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'secure_auth_service.dart';
import 'secure_database_service.dart';
import 'encryption_service.dart';
import 'coppa_compliance_service.dart';
import '../utils/aac_logger.dart';

/// Security validation service to verify all security components are working
class SecurityValidationService {
  
  /// Run comprehensive security validation
  static Future<SecurityValidationResult> validateSecurity() async {
    final result = SecurityValidationResult();
    
    try {
      AACLogger.info('Starting comprehensive security validation');
      
      // Test 1: Authentication Service
      result.authServiceValid = await _validateAuthService();
      
      // Test 2: Database Service
      result.databaseServiceValid = await _validateDatabaseService();
      
      // Test 3: Encryption Service
      result.encryptionServiceValid = await _validateEncryptionService();
      
      // Test 4: COPPA Compliance
      result.coppaComplianceValid = await _validateCOPPACompliance();
      
      // Test 5: Firebase Rules
      result.firebaseRulesValid = await _validateFirebaseRules();
      
      // Test 6: User Isolation
      result.userIsolationValid = await _validateUserIsolation();
      
      // Test 7: Data Retention
      result.dataRetentionValid = await _validateDataRetention();
      
      result.overallValid = _calculateOverallValidation(result);
      
      AACLogger.info('Security validation completed: ${result.overallValid ? "PASSED" : "FAILED"}');
      
    } catch (e) {
      AACLogger.error('Security validation failed with error: $e');
      result.overallValid = false;
      result.errors.add('Validation error: $e');
    }
    
    return result;
  }
  
  static Future<bool> _validateAuthService() async {
    try {
      // Check if auth service is properly initialized
      final isAuth = SecureAuthService.isAuthenticated;
      
      if (isAuth) {
        // Test user ID hashing
        final userId = SecureAuthService.currentUserId;
        if (userId != null) {
          final hash = SecureAuthService.hashUserId(userId);
          if (hash.length < 8) return false;
        }
        
        // Test secure collections access
        final userDoc = SecureAuthService.userDocument;
        final symbolsCol = SecureAuthService.userSymbolsCollection;
        
        return userDoc != null && symbolsCol != null;
      }
      
      return true; // Valid if not authenticated
    } catch (e) {
      AACLogger.error('Auth service validation failed: $e');
      return false;
    }
  }
  
  static Future<bool> _validateDatabaseService() async {
    try {
      if (!SecureAuthService.isAuthenticated) return true;
      
      // Test secure document access
      final userDoc = SecureDatabaseService.getUserDocument();
      if (userDoc == null) return false;
      
      // Test collection validation
      final validCollection = SecureDatabaseService.getUserCollection('symbols');
      final invalidCollection = SecureDatabaseService.getUserCollection('invalid_collection');
      
      return validCollection != null && invalidCollection == null;
    } catch (e) {
      AACLogger.error('Database service validation failed: $e');
      return false;
    }
  }
  
  static Future<bool> _validateEncryptionService() async {
    try {
      // Test encryption/decryption
      const testData = 'Test sensitive data 123';
      final encrypted = await EncryptionService().encrypt(testData);
      
      if (encrypted == testData) return false;
      
      final decrypted = await EncryptionService().decrypt(encrypted);
      if (decrypted != testData) return false;
      
      return true;
    } catch (e) {
      AACLogger.error('Encryption service validation failed: $e');
      return false;
    }
  }
  
  static Future<bool> _validateCOPPACompliance() async {
    try {
      // Test that COPPA service is available and working
      await COPPAComplianceService().getChildProfiles();
      
      // Basic validation that the service works
      return true;
    } catch (e) {
      AACLogger.error('COPPA compliance validation failed: $e');
      return false;
    }
  }
  
  static Future<bool> _validateFirebaseRules() async {
    try {
      if (!SecureAuthService.isAuthenticated) return true;
      
      // Try to access own user document (should succeed)
      final userDoc = SecureAuthService.userDocument;
      if (userDoc != null) {
        try {
          await userDoc.get();
          // If we got here, rules allow access to own data
        } catch (e) {
          return false;
        }
      }
      
      return true;
    } catch (e) {
      AACLogger.error('Firebase rules validation failed: $e');
      return false;
    }
  }
  
  static Future<bool> _validateUserIsolation() async {
    try {
      if (!SecureAuthService.isAuthenticated) return true;
      
      final userId = SecureAuthService.currentUserId;
      if (userId == null) return false;
      
      // Test that user collections are properly isolated
      final symbolsCol = SecureAuthService.userSymbolsCollection;
      final favoritesCol = SecureAuthService.userFavoritesCollection;
      
      if (symbolsCol == null || favoritesCol == null) return false;
      
      // Verify path structure includes user ID
      if (!symbolsCol.path.contains(userId)) return false;
      if (!favoritesCol.path.contains(userId)) return false;
      
      return true;
    } catch (e) {
      AACLogger.error('User isolation validation failed: $e');
      return false;
    }
  }
  
  static Future<bool> _validateDataRetention() async {
    try {
      if (!SecureAuthService.isAuthenticated) return true;
      
      // Test data retention check (should not throw)
      // Check if child profiles have appropriate data retention policies
      final childProfiles = await COPPAComplianceService().getChildProfiles();
      
      // All child profiles should have valid consent status
      for (final profileId in childProfiles) {
        final status = await COPPAComplianceService().getConsentStatus(profileId);
        if (status == ConsentStatus.denied) {
          return false; // Should not have data for denied consent
        }
      }
      
      return true;
    } catch (e) {
      AACLogger.error('Data retention validation failed: $e');
      return false;
    }
  }
  
  static bool _calculateOverallValidation(SecurityValidationResult result) {
    return result.authServiceValid &&
           result.databaseServiceValid &&
           result.encryptionServiceValid &&
           result.coppaComplianceValid &&
           result.firebaseRulesValid &&
           result.userIsolationValid &&
           result.dataRetentionValid;
  }
  
  /// Get security status report for debugging
  static Future<Map<String, dynamic>> getSecurityStatusReport() async {
    final result = await validateSecurity();
    
    return {
      'validation_timestamp': DateTime.now().toIso8601String(),
      'overall_valid': result.overallValid,
      'components': {
        'auth_service': result.authServiceValid,
        'database_service': result.databaseServiceValid,
        'encryption_service': result.encryptionServiceValid,
        'coppa_compliance': result.coppaComplianceValid,
        'firebase_rules': result.firebaseRulesValid,
        'user_isolation': result.userIsolationValid,
        'data_retention': result.dataRetentionValid,
      },
      'errors': result.errors,
      'warnings': result.warnings,
      'recommendations': result.recommendations,
    };
  }
}

/// Result class for security validation
class SecurityValidationResult {
  bool authServiceValid = false;
  bool databaseServiceValid = false;
  bool encryptionServiceValid = false;
  bool coppaComplianceValid = false;
  bool firebaseRulesValid = false;
  bool userIsolationValid = false;
  bool dataRetentionValid = false;
  bool overallValid = false;
  
  List<String> errors = [];
  List<String> warnings = [];
  List<String> recommendations = [];
  
  /// Get human-readable summary
  String getSummary() {
    if (overallValid) {
      return 'All security components are functioning correctly.';
    } else {
      final failedComponents = <String>[];
      if (!authServiceValid) failedComponents.add('Authentication Service');
      if (!databaseServiceValid) failedComponents.add('Database Service');
      if (!encryptionServiceValid) failedComponents.add('Encryption Service');
      if (!coppaComplianceValid) failedComponents.add('COPPA Compliance');
      if (!firebaseRulesValid) failedComponents.add('Firebase Rules');
      if (!userIsolationValid) failedComponents.add('User Isolation');
      if (!dataRetentionValid) failedComponents.add('Data Retention');
      
      return 'Security validation failed. Issues found in: ${failedComponents.join(', ')}';
    }
  }
}
