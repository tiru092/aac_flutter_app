import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

/// Custom exception for crash reporting-related errors
class CrashReportingException implements Exception {
  final String message;
  
  CrashReportingException(this.message);
  
  @override
  String toString() => 'CrashReportingException: $message';
}

/// Service to handle crash reporting and error tracking
class CrashReportingService {
  static final CrashReportingService _instance = CrashReportingService._internal();
  factory CrashReportingService() => _instance;
  CrashReportingService._internal();

  bool _isInitialized = false;
  final AuthService _authService = AuthService();
  final List<ErrorInfo> _errorHistory = [];

  /// Initialize crash reporting service
  Future<void> initialize() async {
    try {
      if (_isInitialized) return;
      
      // Initialize Firebase Crashlytics
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
      
      // Set user identifier if user is logged in
      _setUserIdentifier();
      
      // Listen for auth state changes to update user identifier
      _authService.authStateChanges.listen((user) {
        _setUserIdentifier();
      });
      
      // Set up custom keys
      await _setCustomKeys();
      
      _isInitialized = true;
      print('Crash reporting service initialized');
    } catch (e) {
      print('Error initializing crash reporting service: $e');
    }
  }

  /// Set user identifier for crash reports
  void _setUserIdentifier() {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        FirebaseCrashlytics.instance.setUserIdentifier(user.uid);
        FirebaseCrashlytics.instance.setCustomKey('user_email', user.email ?? 'unknown');
      }
    } catch (e) {
      print('Error setting user identifier for crash reporting: $e');
    }
  }

  /// Set custom keys for crash reports
  Future<void> _setCustomKeys() async {
    try {
      // App version
      FirebaseCrashlytics.instance.setCustomKey('platform', Platform.operatingSystem);
      FirebaseCrashlytics.instance.setCustomKey('platform_version', Platform.operatingSystemVersion);
      
      // Add more custom keys as needed
      if (kDebugMode) {
        FirebaseCrashlytics.instance.setCustomKey('debug_mode', true);
      }
    } catch (e) {
      print('Error setting custom keys for crash reporting: $e');
    }
  }

  /// Report a non-fatal exception with additional context
  Future<void> reportException(Exception exception, [StackTrace? stackTrace, Map<String, dynamic>? additionalInfo]) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      // Add to error history
      _errorHistory.add(ErrorInfo(
        timestamp: DateTime.now(),
        exception: exception,
        stackTrace: stackTrace,
        additionalInfo: additionalInfo,
      ));
      
      // Keep only the last 100 errors
      if (_errorHistory.length > 100) {
        _errorHistory.removeAt(0);
      }
      
      // Log to console in debug mode
      if (kDebugMode) {
        developer.log(
          'Non-fatal exception: $exception',
          name: 'CrashReporting',
          error: exception,
          stackTrace: stackTrace,
        );
      }
      
      // Add additional context to crash report
      if (additionalInfo != null) {
        for (final entry in additionalInfo.entries) {
          await FirebaseCrashlytics.instance.setCustomKey(entry.key, entry.value.toString());
        }
      }
      
      // Report to Firebase Crashlytics
      await FirebaseCrashlytics.instance.recordError(
        exception,
        stackTrace,
        fatal: false,
      );
    } catch (e) {
      print('Error reporting exception: $e');
    }
  }

  /// Report a fatal exception
  Future<void> reportFatalException(Exception exception, [StackTrace? stackTrace, Map<String, dynamic>? additionalInfo]) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      // Add to error history
      _errorHistory.add(ErrorInfo(
        timestamp: DateTime.now(),
        exception: exception,
        stackTrace: stackTrace,
        additionalInfo: additionalInfo,
        isFatal: true,
      ));
      
      // Log to console in debug mode
      if (kDebugMode) {
        developer.log(
          'Fatal exception: $exception',
          name: 'CrashReporting',
          error: exception,
          stackTrace: stackTrace,
        );
      }
      
      // Add additional context to crash report
      if (additionalInfo != null) {
        for (final entry in additionalInfo.entries) {
          await FirebaseCrashlytics.instance.setCustomKey(entry.key, entry.value.toString());
        }
      }
      
      // Report to Firebase Crashlytics
      await FirebaseCrashlytics.instance.recordError(
        exception,
        stackTrace,
        fatal: true,
      );
    } catch (e) {
      print('Error reporting fatal exception: $e');
    }
  }

  /// Log a custom message with severity level
  Future<void> logMessage(String message, {LogLevel level = LogLevel.info, Map<String, dynamic>? additionalInfo}) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      // Log to console in debug mode
      if (kDebugMode) {
        developer.log(message, name: 'CrashReporting', level: level.index);
      }
      
      // Add additional context
      if (additionalInfo != null) {
        for (final entry in additionalInfo.entries) {
          await FirebaseCrashlytics.instance.setCustomKey(entry.key, entry.value.toString());
        }
      }
      
      // Add severity prefix to message
      final prefixedMessage = '[${level.name.toUpperCase()}] $message';
      
      // Log to Firebase Crashlytics
      await FirebaseCrashlytics.instance.log(prefixedMessage);
    } catch (e) {
      print('Error logging message: $e');
    }
  }

  /// Set a custom key-value pair for crash reports
  Future<void> setCustomKey(String key, dynamic value) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      await FirebaseCrashlytics.instance.setCustomKey(key, value);
    } catch (e) {
      print('Error setting custom key: $e');
    }
  }

  /// Set user attributes for crash reports
  Future<void> setUserAttributes(Map<String, dynamic> attributes) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      for (final entry in attributes.entries) {
        await FirebaseCrashlytics.instance.setCustomKey(entry.key, entry.value);
      }
    } catch (e) {
      print('Error setting user attributes: $e');
    }
  }

  /// Test crash reporting by forcing a crash
  /// Only use this for testing purposes
  Future<void> testCrash() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      // Only allow test crash in debug mode
      if (kDebugMode) {
        await logMessage('Testing crash reporting functionality');
        // The crash method doesn't return a Future, so we don't await it
        FirebaseCrashlytics.instance.crash();
      }
    } catch (e) {
      print('Error testing crash: $e');
    }
  }

  /// Check if crash reporting is available
  bool get isAvailable {
    try {
      return _isInitialized && !kDebugMode;
    } catch (e) {
      return false;
    }
  }

  /// Get recent error history
  List<ErrorInfo> get errorHistory => List.unmodifiable(_errorHistory);
  
  /// Clear error history
  void clearErrorHistory() {
    _errorHistory.clear();
  }
  
  /// Report a handled error with context
  Future<void> reportHandledError(String operation, Object error, [StackTrace? stackTrace]) async {
    try {
      final additionalInfo = {
        'operation': operation,
        'handled': true,
      };
      
      await reportException(
        CrashReportingException('Handled error in $operation: $error'),
        stackTrace,
        additionalInfo,
      );
    } catch (e) {
      print('Error reporting handled error: $e');
    }
  }

  /// Report an error with optional stack trace and reason
  Future<void> reportError(Object error, [StackTrace? stackTrace, String? reason]) async {
    try {
      final additionalInfo = <String, dynamic>{};
      if (reason != null) {
        additionalInfo['reason'] = reason;
      }
      
      Exception exception;
      if (error is Exception) {
        exception = error;
      } else {
        exception = Exception(error.toString());
      }
      
      await reportException(exception, stackTrace, additionalInfo);
    } catch (e) {
      print('Error reporting error: $e');
    }
  }
}

/// Log level enumeration
enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
  fatal,
}

/// Error information structure
class ErrorInfo {
  final DateTime timestamp;
  final Exception exception;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? additionalInfo;
  final bool isFatal;
  
  ErrorInfo({
    required this.timestamp,
    required this.exception,
    this.stackTrace,
    this.additionalInfo,
    this.isFatal = false,
  });
}