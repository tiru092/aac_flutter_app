import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import 'coppa_compliance_service.dart';

/// Custom exception for analytics-related errors
class AnalyticsException implements Exception {
  final String message;
  
  AnalyticsException(this.message);
  
  @override
  String toString() => 'AnalyticsException: $message';
}

/// Service to handle analytics collection with explicit user consent
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  static const String _consentKey = 'analytics_consent';
  static const String _consentTimestampKey = 'analytics_consent_timestamp';
  static const String _analyticsDataKey = 'analytics_data';
  static const String _lastUploadKey = 'analytics_last_upload';
  
  // Configuration
  static const Duration _uploadInterval = Duration(hours: 24);
  static const int _maxStoredEvents = 1000;
  
  // Analytics collection state
  bool _isEnabled = false;
  bool _isInitialized = false;
  final List<AnalyticsEvent> _pendingEvents = [];
  
  /// Initialize the analytics service
  Future<void> initialize() async {
    try {
      if (_isInitialized) return;
      
      // Check for existing consent
      await _loadConsentStatus();
      
      // Load pending events
      await _loadPendingEvents();
      
      // Start periodic upload if enabled
      if (_isEnabled) {
        _startPeriodicUpload();
      }
      
      _isInitialized = true;
      print('Analytics service initialized. Enabled: $_isEnabled');
    } catch (e) {
      print('Error initializing analytics service: $e');
    }
  }
  
  /// Request user consent for analytics collection
  Future<ConsentResult> requestConsent(UserProfile profile) async {
    try {
      // Check if consent is required based on user type
      final isChild = profile.role == UserRole.child;
      
      // For children, check COPPA compliance
      if (isChild) {
        final coppaService = COPPAComplianceService();
        final consentRequired = await coppaService.isConsentRequired(profile);
        
        if (consentRequired) {
          // For children under COPPA, analytics consent must come from parent
          return ConsentResult(
            status: AnalyticsConsentStatus.parentalConsentRequired,
            message: 'Parental consent required for analytics collection for children',
          );
        }
      }
      
      // For adults or children with parental consent, request direct consent
      return ConsentResult(
        status: AnalyticsConsentStatus.pending,
        message: 'User consent required for analytics collection',
      );
    } catch (e) {
      print('Error requesting analytics consent: $e');
      return ConsentResult(
        status: AnalyticsConsentStatus.error,
        message: 'Error requesting consent: $e',
      );
    }
  }
  
  /// Grant analytics consent
  Future<void> grantConsent(String userId, ConsentDetails details) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Store consent details
      final consentData = {
        'userId': userId,
        'granted': true,
        'timestamp': DateTime.now().toIso8601String(),
        'details': details.toJson(),
      };
      
      await prefs.setString(_consentKey, jsonEncode(consentData));
      await prefs.setString(_consentTimestampKey, DateTime.now().toIso8601String());
      
      _isEnabled = true;
      
      // Start periodic upload
      _startPeriodicUpload();
      
      print('Analytics consent granted for user: $userId');
    } catch (e) {
      print('Error granting analytics consent: $e');
      rethrow;
    }
  }
  
  /// Deny analytics consent
  Future<void> denyConsent(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Store denial
      final consentData = {
        'userId': userId,
        'granted': false,
        'timestamp': DateTime.now().toIso8601String(),
        'details': null,
      };
      
      await prefs.setString(_consentKey, jsonEncode(consentData));
      await prefs.setString(_consentTimestampKey, DateTime.now().toIso8601String());
      
      _isEnabled = false;
      
      // Clear pending events
      _pendingEvents.clear();
      await _savePendingEvents();
      
      print('Analytics consent denied for user: $userId');
    } catch (e) {
      print('Error denying analytics consent: $e');
      rethrow;
    }
  }
  
  /// Revoke analytics consent
  Future<void> revokeConsent(String userId) async {
    try {
      await denyConsent(userId);
      print('Analytics consent revoked for user: $userId');
    } catch (e) {
      print('Error revoking analytics consent: $e');
      rethrow;
    }
  }
  
  /// Check if analytics consent has been granted
  Future<bool> isConsentGranted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final consentDataJson = prefs.getString(_consentKey);
      
      if (consentDataJson == null) {
        return false;
      }
      
      final consentData = jsonDecode(consentDataJson) as Map<String, dynamic>;
      return consentData['granted'] == true;
    } catch (e) {
      print('Error checking analytics consent status: $e');
      return false;
    }
  }
  
  /// Get consent details
  Future<ConsentDetails?> getConsentDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final consentDataJson = prefs.getString(_consentKey);
      
      if (consentDataJson == null) {
        return null;
      }
      
      final consentData = jsonDecode(consentDataJson) as Map<String, dynamic>;
      final detailsData = consentData['details'] as Map<String, dynamic>?;
      
      if (detailsData == null) {
        return null;
      }
      
      return ConsentDetails.fromJson(detailsData);
    } catch (e) {
      print('Error getting analytics consent details: $e');
      return null;
    }
  }
  
  /// Log an analytics event
  Future<void> logEvent(AnalyticsEvent event) async {
    try {
      // Check if analytics is enabled
      if (!_isEnabled) {
        return;
      }
      
      // Add timestamp if not provided
      if (event.timestamp == null) {
        event = event.copyWith(timestamp: DateTime.now());
      }
      
      // Add to pending events
      _pendingEvents.add(event);
      
      // Trim events if exceeding limit
      if (_pendingEvents.length > _maxStoredEvents) {
        _pendingEvents.removeRange(0, _pendingEvents.length - _maxStoredEvents);
      }
      
      // Save pending events
      await _savePendingEvents();
      
      // Upload immediately if high priority
      if (event.priority == EventPriority.high) {
        await _uploadEvents();
      }
    } catch (e) {
      print('Error logging analytics event: $e');
    }
  }
  
  /// Log app launch event
  Future<void> logAppLaunch(String userId, String platform) async {
    try {
      final event = AnalyticsEvent(
        name: 'app_launch',
        userId: userId,
        properties: {
          'platform': platform,
          'timestamp': DateTime.now().toIso8601String(),
        },
        priority: EventPriority.normal,
      );
      
      await logEvent(event);
    } catch (e) {
      print('Error logging app launch event: $e');
    }
  }
  
  /// Log feature usage event
  Future<void> logFeatureUsage(String userId, String featureName, Map<String, dynamic>? properties) async {
    try {
      final event = AnalyticsEvent(
        name: 'feature_usage',
        userId: userId,
        properties: {
          'feature': featureName,
          'timestamp': DateTime.now().toIso8601String(),
          ...?properties,
        },
        priority: EventPriority.normal,
      );
      
      await logEvent(event);
    } catch (e) {
      print('Error logging feature usage event: $e');
    }
  }
  
  /// Log error event
  Future<void> logError(String userId, String errorType, String errorMessage, {Map<String, dynamic>? properties}) async {
    try {
      final event = AnalyticsEvent(
        name: 'error',
        userId: userId,
        properties: {
          'error_type': errorType,
          'error_message': errorMessage,
          'timestamp': DateTime.now().toIso8601String(),
          ...?properties,
        },
        priority: EventPriority.high,
      );
      
      await logEvent(event);
    } catch (e) {
      print('Error logging error event: $e');
    }
  }
  
  /// Log user interaction event
  Future<void> logUserInteraction(String userId, String interactionType, Map<String, dynamic>? properties) async {
    try {
      final event = AnalyticsEvent(
        name: 'user_interaction',
        userId: userId,
        properties: {
          'interaction_type': interactionType,
          'timestamp': DateTime.now().toIso8601String(),
          ...?properties,
        },
        priority: EventPriority.normal,
      );
      
      await logEvent(event);
    } catch (e) {
      print('Error logging user interaction event: $e');
    }
  }
  
  /// Manually trigger event upload
  Future<void> uploadEvents() async {
    try {
      if (!_isEnabled) {
        return;
      }
      
      await _uploadEvents();
    } catch (e) {
      print('Error uploading analytics events: $e');
    }
  }
  
  /// Get analytics report
  Future<AnalyticsReport> generateReport() async {
    try {
      final consentGranted = await isConsentGranted();
      final consentDetails = await getConsentDetails();
      
      return AnalyticsReport(
        isEnabled: _isEnabled,
        consentGranted: consentGranted,
        consentDetails: consentDetails,
        pendingEventsCount: _pendingEvents.length,
        lastUpload: await _getLastUploadTime(),
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      print('Error generating analytics report: $e');
      rethrow;
    }
  }
  
  /// Clear all stored analytics data
  Future<void> clearData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear stored data
      await prefs.remove(_consentKey);
      await prefs.remove(_consentTimestampKey);
      await prefs.remove(_analyticsDataKey);
      await prefs.remove(_lastUploadKey);
      
      // Clear pending events
      _pendingEvents.clear();
      
      print('Analytics data cleared');
    } catch (e) {
      print('Error clearing analytics data: $e');
      rethrow;
    }
  }
  
  // Private methods
  
  Future<void> _loadConsentStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final consentDataJson = prefs.getString(_consentKey);
      
      if (consentDataJson != null) {
        final consentData = jsonDecode(consentDataJson) as Map<String, dynamic>;
        _isEnabled = consentData['granted'] == true;
      }
    } catch (e) {
      print('Error loading analytics consent status: $e');
    }
  }
  
  Future<void> _loadPendingEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsDataJson = prefs.getString(_analyticsDataKey);
      
      if (eventsDataJson != null) {
        final eventsData = jsonDecode(eventsDataJson) as List;
        _pendingEvents.clear();
        
        for (final eventData in eventsData) {
          _pendingEvents.add(AnalyticsEvent.fromJson(Map<String, dynamic>.from(eventData)));
        }
      }
    } catch (e) {
      print('Error loading pending analytics events: $e');
    }
  }
  
  Future<void> _savePendingEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final eventsData = _pendingEvents.map((event) => event.toJson()).toList();
      await prefs.setString(_analyticsDataKey, jsonEncode(eventsData));
    } catch (e) {
      print('Error saving pending analytics events: $e');
    }
  }
  
  Future<void> _uploadEvents() async {
    try {
      if (_pendingEvents.isEmpty) {
        return;
      }
      
      // In a real implementation, you would send events to an analytics service
      // For this example, we'll just log them and clear the pending events
      
      print('Uploading ${_pendingEvents.length} analytics events:');
      for (final event in _pendingEvents) {
        // Anonymize data before upload
        final anonymizedEvent = _anonymizeEvent(event);
        print('  - ${anonymizedEvent.name}: ${anonymizedEvent.properties}');
      }
      
      // Clear pending events after "upload"
      _pendingEvents.clear();
      await _savePendingEvents();
      
      // Record upload time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastUploadKey, DateTime.now().toIso8601String());
      
      print('Analytics events uploaded successfully');
    } catch (e) {
      print('Error uploading analytics events: $e');
    }
  }
  
  AnalyticsEvent _anonymizeEvent(AnalyticsEvent event) {
    try {
      // Remove or obfuscate personally identifiable information
      final anonymizedProperties = Map<String, dynamic>.from(event.properties ?? {});
      
      // Remove sensitive fields
      anonymizedProperties.removeWhere((key, value) {
        final lowerKey = key.toLowerCase();
        return lowerKey.contains('email') || 
               lowerKey.contains('phone') || 
               lowerKey.contains('name') ||
               lowerKey.contains('address');
      });
      
      return event.copyWith(properties: anonymizedProperties);
    } catch (e) {
      print('Error anonymizing event: $e');
      return event;
    }
  }
  
  Future<DateTime?> _getLastUploadTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUploadString = prefs.getString(_lastUploadKey);
      
      if (lastUploadString != null) {
        return DateTime.parse(lastUploadString);
      }
      
      return null;
    } catch (e) {
      print('Error getting last upload time: $e');
      return null;
    }
  }
  
  Timer? _uploadTimer;
  
  void _startPeriodicUpload() {
    try {
      // Cancel any existing timer
      _uploadTimer?.cancel();
      
      // Periodically upload events
      _uploadTimer = Timer.periodic(_uploadInterval, (timer) async {
        if (_isEnabled) {
          await _uploadEvents();
        }
      });
    } catch (e) {
      print('Error starting periodic analytics upload: $e');
    }
  }
}

// Data classes

enum AnalyticsConsentStatus {
  pending,
  granted,
  denied,
  parentalConsentRequired,
  error,
}

class ConsentResult {
  final AnalyticsConsentStatus status;
  final String message;
  
  ConsentResult({
    required this.status,
    required this.message,
  });
}

class ConsentDetails {
  final String consentId;
  final DateTime consentedAt;
  final List<String> allowedEventTypes;
  final bool allowDataSharing;
  final String consentVersion;
  
  ConsentDetails({
    required this.consentId,
    required this.consentedAt,
    required this.allowedEventTypes,
    required this.allowDataSharing,
    required this.consentVersion,
  });
  
  Map<String, dynamic> toJson() => {
        'consentId': consentId,
        'consentedAt': consentedAt.toIso8601String(),
        'allowedEventTypes': allowedEventTypes,
        'allowDataSharing': allowDataSharing,
        'consentVersion': consentVersion,
      };
  
  factory ConsentDetails.fromJson(Map<String, dynamic> json) => ConsentDetails(
        consentId: json['consentId'],
        consentedAt: DateTime.parse(json['consentedAt']),
        allowedEventTypes: List<String>.from(json['allowedEventTypes']),
        allowDataSharing: json['allowDataSharing'],
        consentVersion: json['consentVersion'],
      );
}

enum EventPriority {
  low,
  normal,
  high,
}

class AnalyticsEvent {
  final String name;
  final String userId;
  final Map<String, dynamic>? properties;
  final DateTime? timestamp;
  final EventPriority priority;
  
  AnalyticsEvent({
    required this.name,
    required this.userId,
    this.properties,
    this.timestamp,
    this.priority = EventPriority.normal,
  });
  
  AnalyticsEvent copyWith({
    String? name,
    String? userId,
    Map<String, dynamic>? properties,
    DateTime? timestamp,
    EventPriority? priority,
  }) =>
      AnalyticsEvent(
        name: name ?? this.name,
        userId: userId ?? this.userId,
        properties: properties ?? this.properties,
        timestamp: timestamp ?? this.timestamp,
        priority: priority ?? this.priority,
      );
  
  Map<String, dynamic> toJson() => {
        'name': name,
        'userId': userId,
        'properties': properties,
        'timestamp': timestamp?.toIso8601String(),
        'priority': priority.toString().split('.').last,
      };
  
  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) => AnalyticsEvent(
        name: json['name'],
        userId: json['userId'],
        properties: json['properties'] as Map<String, dynamic>?,
        timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
        priority: EventPriority.values.firstWhere(
          (p) => p.toString() == 'EventPriority.${json['priority']}',
          orElse: () => EventPriority.normal,
        ),
      );
}

class AnalyticsReport {
  final bool isEnabled;
  final bool consentGranted;
  final ConsentDetails? consentDetails;
  final int pendingEventsCount;
  final DateTime? lastUpload;
  final DateTime generatedAt;
  
  AnalyticsReport({
    required this.isEnabled,
    required this.consentGranted,
    this.consentDetails,
    required this.pendingEventsCount,
    this.lastUpload,
    required this.generatedAt,
  });
  
  @override
  String toString() => '''
AnalyticsReport(
  isEnabled: $isEnabled,
  consentGranted: $consentGranted,
  pendingEvents: $pendingEventsCount,
  lastUpload: $lastUpload,
  generatedAt: $generatedAt
)''';
}