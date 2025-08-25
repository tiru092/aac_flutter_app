import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_profile.dart';

/// Custom exception for COPPA compliance-related errors
class COPPAComplianceException implements Exception {
  final String message;
  
  COPPAComplianceException(this.message);
  
  @override
  String toString() => 'COPPAComplianceException: $message';
}

/// Service to handle COPPA compliance for child user data protection
class COPPAComplianceService {
  static final COPPAComplianceService _instance = COPPAComplianceService._internal();
  factory COPPAComplianceService() => _instance;
  COPPAComplianceService._internal();

  static const String _consentKey = 'coppa_consent_status';
  static const String _consentDetailsKey = 'coppa_consent_details';
  static const String _childProfilesKey = 'coppa_child_profiles';
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  /// COPPA consent status enumeration
  enum ConsentStatus {
    notRequired, // For users 13 and older
    pending,     // Consent requested but not yet provided
    granted,     // Parental consent granted
    denied,      // Parental consent denied
    expired      // Consent expired and needs renewal
  }
  
  /// Check if COPPA consent is required for a user
  Future<bool> isConsentRequired(UserProfile profile) async {
    try {
      // COPPA applies to children under 13
      if (profile.role == UserRole.child) {
        // In a real implementation, you would check the child's actual age
        // For this example, we'll assume all child profiles require consent
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error checking COPPA consent requirement: $e');
      // Default to requiring consent for child profiles for safety
      return profile.role == UserRole.child;
    }
  }
  
  /// Get current consent status for a child profile
  Future<ConsentStatus> getConsentStatus(String profileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final consentDataJson = prefs.getString('$_consentKey_$profileId');
      
      if (consentDataJson == null) {
        return ConsentStatus.notRequired;
      }
      
      final consentData = jsonDecode(consentDataJson) as Map<String, dynamic>;
      final statusString = consentData['status'] as String;
      
      return ConsentStatus.values.firstWhere(
        (status) => status.toString() == 'ConsentStatus.$statusString',
        orElse: () => ConsentStatus.notRequired,
      );
    } catch (e) {
      print('Error getting COPPA consent status: $e');
      return ConsentStatus.notRequired;
    }
  }
  
  /// Request parental consent for a child profile
  Future<void> requestParentalConsent(String profileId, String parentEmail) async {
    try {
      // In a real implementation, you would:
      // 1. Send an email to the parent with a consent form
      // 2. Generate a unique consent token
      // 3. Store the consent request details
      
      final consentDetails = {
        'profileId': profileId,
        'parentEmail': parentEmail,
        'requestedAt': DateTime.now().toIso8601String(),
        'status': ConsentStatus.pending.toString().split('.').last,
      };
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_consentDetailsKey_$profileId',
        jsonEncode(consentDetails),
      );
      
      // Update status to pending
      await _updateConsentStatus(profileId, ConsentStatus.pending);
      
      print('Parental consent requested for profile: $profileId');
    } catch (e) {
      print('Error requesting parental consent: $e');
      rethrow;
    }
  }
  
  /// Grant parental consent for a child profile
  Future<void> grantParentalConsent(String profileId, ConsentDetails details) async {
    try {
      // Store consent details securely
      final consentJson = jsonEncode(details.toJson());
      await _secureStorage.write(
        key: '$_consentDetailsKey_$profileId',
        value: consentJson,
      );
      
      // Update status to granted
      await _updateConsentStatus(profileId, ConsentStatus.granted);
      
      // Record consent timestamp for expiration tracking
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'consent_granted_at_$profileId',
        DateTime.now().toIso8601String(),
      );
      
      print('Parental consent granted for profile: $profileId');
    } catch (e) {
      print('Error granting parental consent: $e');
      rethrow;
    }
  }
  
  /// Deny parental consent for a child profile
  Future<void> denyParentalConsent(String profileId) async {
    try {
      await _updateConsentStatus(profileId, ConsentStatus.denied);
      print('Parental consent denied for profile: $profileId');
    } catch (e) {
      print('Error denying parental consent: $e');
      rethrow;
    }
  }
  
  /// Revoke parental consent for a child profile
  Future<void> revokeParentalConsent(String profileId) async {
    try {
      await _updateConsentStatus(profileId, ConsentStatus.notRequired);
      
      // Clear consent details
      await _secureStorage.delete(key: '$_consentDetailsKey_$profileId');
      
      print('Parental consent revoked for profile: $profileId');
    } catch (e) {
      print('Error revoking parental consent: $e');
      rethrow;
    }
  }
  
  /// Check if consent has expired (COPPA requires periodic re-consent)
  Future<bool> isConsentExpired(String profileId) async {
    try {
      final status = await getConsentStatus(profileId);
      
      // If consent is not granted, it's not expired
      if (status != ConsentStatus.granted) {
        return false;
      }
      
      // Check when consent was granted
      final prefs = await SharedPreferences.getInstance();
      final grantedAtString = prefs.getString('consent_granted_at_$profileId');
      
      if (grantedAtString == null) {
        return false; // No record of when granted, assume not expired
      }
      
      final grantedAt = DateTime.parse(grantedAtString);
      final now = DateTime.now();
      
      // COPPA doesn't specify an expiration period, but many services use 1-2 years
      // For this example, we'll use 1 year
      final expirationPeriod = Duration(days: 365);
      final expirationDate = grantedAt.add(expirationPeriod);
      
      return now.isAfter(expirationDate);
    } catch (e) {
      print('Error checking consent expiration: $e');
      return false; // Default to not expired for safety
    }
  }
  
  /// Get consent details for a child profile
  Future<ConsentDetails?> getConsentDetails(String profileId) async {
    try {
      final consentJson = await _secureStorage.read(
        key: '$_consentDetailsKey_$profileId',
      );
      
      if (consentJson == null) {
        return null;
      }
      
      final consentData = jsonDecode(consentJson) as Map<String, dynamic>;
      return ConsentDetails.fromJson(consentData);
    } catch (e) {
      print('Error getting consent details: $e');
      return null;
    }
  }
  
  /// Add a child profile to COPPA tracking
  Future<void> addChildProfile(String profileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingProfilesJson = prefs.getString(_childProfilesKey);
      
      final profiles = existingProfilesJson != null
          ? List<String>.from(jsonDecode(existingProfilesJson))
          : <String>[];
      
      if (!profiles.contains(profileId)) {
        profiles.add(profileId);
        
        await prefs.setString(
          _childProfilesKey,
          jsonEncode(profiles),
        );
      }
    } catch (e) {
      print('Error adding child profile: $e');
      rethrow;
    }
  }
  
  /// Remove a child profile from COPPA tracking
  Future<void> removeChildProfile(String profileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingProfilesJson = prefs.getString(_childProfilesKey);
      
      if (existingProfilesJson != null) {
        final profiles = List<String>.from(jsonDecode(existingProfilesJson));
        profiles.remove(profileId);
        
        await prefs.setString(
          _childProfilesKey,
          jsonEncode(profiles),
        );
      }
      
      // Also remove consent data
      await _secureStorage.delete(key: '$_consentDetailsKey_$profileId');
      await prefs.remove('$_consentKey_$profileId');
      await prefs.remove('consent_granted_at_$profileId');
    } catch (e) {
      print('Error removing child profile: $e');
      rethrow;
    }
  }
  
  /// Get all child profiles under COPPA protection
  Future<List<String>> getChildProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profilesJson = prefs.getString(_childProfilesKey);
      
      if (profilesJson == null) {
        return [];
      }
      
      return List<String>.from(jsonDecode(profilesJson));
    } catch (e) {
      print('Error getting child profiles: $e');
      return [];
    }
  }
  
  /// Check if data collection is allowed for a profile
  Future<bool> isDataCollectionAllowed(String profileId) async {
    try {
      final status = await getConsentStatus(profileId);
      
      // Data collection is allowed if:
      // 1. Consent is not required (user is 13 or older)
      // 2. Consent has been granted
      // 3. Consent is pending (limited data collection for consent process)
      
      return status == ConsentStatus.notRequired || 
             status == ConsentStatus.granted || 
             status == ConsentStatus.pending;
    } catch (e) {
      print('Error checking data collection permission: $e');
      // Default to not allowing data collection for safety
      return false;
    }
  }
  
  /// Log data access for audit purposes
  Future<void> logDataAccess(String profileId, String dataType, String purpose) async {
    try {
      // In a real implementation, you would log this to a secure audit trail
      print('Data access logged - Profile: $profileId, Type: $dataType, Purpose: $purpose');
    } catch (e) {
      print('Error logging data access: $e');
    }
  }
  
  /// Generate a consent verification report
  Future<ConsentReport> generateConsentReport(String profileId) async {
    try {
      final status = await getConsentStatus(profileId);
      final details = await getConsentDetails(profileId);
      final isExpired = await isConsentExpired(profileId);
      
      return ConsentReport(
        profileId: profileId,
        status: status,
        details: details,
        isExpired: isExpired,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      print('Error generating consent report: $e');
      rethrow;
    }
  }
  
  // Private methods
  
  Future<void> _updateConsentStatus(String profileId, ConsentStatus status) async {
    try {
      final consentData = {
        'profileId': profileId,
        'status': status.toString().split('.').last,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_consentKey_$profileId',
        jsonEncode(consentData),
      );
    } catch (e) {
      print('Error updating consent status: $e');
      rethrow;
    }
  }
}

// Data classes

class ConsentDetails {
  final String parentName;
  final String parentEmail;
  final String relationshipToChild;
  final DateTime consentGivenAt;
  final String consentToken;
  final String signature;
  final List<String> permissionsGranted;
  
  ConsentDetails({
    required this.parentName,
    required this.parentEmail,
    required this.relationshipToChild,
    required this.consentGivenAt,
    required this.consentToken,
    required this.signature,
    required this.permissionsGranted,
  });
  
  Map<String, dynamic> toJson() => {
        'parentName': parentName,
        'parentEmail': parentEmail,
        'relationshipToChild': relationshipToChild,
        'consentGivenAt': consentGivenAt.toIso8601String(),
        'consentToken': consentToken,
        'signature': signature,
        'permissionsGranted': permissionsGranted,
      };
  
  factory ConsentDetails.fromJson(Map<String, dynamic> json) => ConsentDetails(
        parentName: json['parentName'],
        parentEmail: json['parentEmail'],
        relationshipToChild: json['relationshipToChild'],
        consentGivenAt: DateTime.parse(json['consentGivenAt']),
        consentToken: json['consentToken'],
        signature: json['signature'],
        permissionsGranted: List<String>.from(json['permissionsGranted']),
      );
}

class ConsentReport {
  final String profileId;
  final COPPAComplianceService.ConsentStatus status;
  final ConsentDetails? details;
  final bool isExpired;
  final DateTime generatedAt;
  
  ConsentReport({
    required this.profileId,
    required this.status,
    this.details,
    required this.isExpired,
    required this.generatedAt,
  });
  
  @override
  String toString() => '''
ConsentReport(
  profileId: $profileId,
  status: $status,
  isExpired: $isExpired,
  generatedAt: $generatedAt
)''';
}