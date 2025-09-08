import 'package:flutter/foundation.dart';

/// Secure logging service that prevents sensitive data exposure in production
class SecureLogger {
  static final SecureLogger _instance = SecureLogger._internal();
  factory SecureLogger() => _instance;
  SecureLogger._internal();

  /// Log debug information (only in debug mode)
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('[DEBUG] $message');
      if (error != null) {
        print('[DEBUG] Error: $error');
      }
      if (stackTrace != null && kDebugMode) {
        print('[DEBUG] Stack trace: $stackTrace');
      }
    }
  }

  /// Log informational messages (only in debug mode)
  static void info(String message) {
    if (kDebugMode) {
      print('[INFO] $message');
    }
  }

  /// Log warnings (only in debug mode)
  static void warning(String message, [Object? error]) {
    if (kDebugMode) {
      print('[WARNING] $message');
      if (error != null) {
        print('[WARNING] Error: $error');
      }
    }
  }

  /// Log errors (only in debug mode, with sanitized messages for production)
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('[ERROR] $message');
      if (error != null) {
        print('[ERROR] Error details: $error');
      }
      if (stackTrace != null) {
        print('[ERROR] Stack trace: $stackTrace');
      }
    } else {
      // In production, we might want to log to a crash reporting service
      // For now, we'll just silently handle errors without exposing sensitive data
      // TODO: Integrate with Firebase Crashlytics for production error reporting
    }
  }

  /// Log authentication related events (sanitized for security)
  static void authEvent(String event, {String? userId}) {
    if (kDebugMode) {
      final sanitizedUserId = userId != null ? 'User: ${userId.substring(0, 4)}***' : 'No user';
      print('[AUTH] $event - $sanitizedUserId');
    }
  }

  /// Log Firebase operations (sanitized)
  static void firebaseEvent(String event, {String? collection, bool success = true}) {
    if (kDebugMode) {
      final status = success ? 'SUCCESS' : 'FAILED';
      final collectionInfo = collection != null ? ' (Collection: $collection)' : '';
      print('[FIREBASE] $event - $status$collectionInfo');
    }
  }

  /// Log encryption/decryption operations (without exposing data)
  static void encryptionEvent(String operation, {bool success = true, String? errorCode}) {
    if (kDebugMode) {
      final status = success ? 'SUCCESS' : 'FAILED';
      final errorInfo = errorCode != null ? ' (Error: $errorCode)' : '';
      print('[ENCRYPTION] $operation - $status$errorInfo');
    }
  }

  /// Log user data operations (sanitized)
  static void dataEvent(String operation, {String? dataType, bool success = true}) {
    if (kDebugMode) {
      final status = success ? 'SUCCESS' : 'FAILED';
      final typeInfo = dataType != null ? ' (Type: $dataType)' : '';
      print('[DATA] $operation - $status$typeInfo');
    }
  }

  /// Sanitize sensitive data for logging
  static String sanitizeData(String data) {
    if (data.length <= 4) {
      return '***';
    }
    return '${data.substring(0, 2)}***${data.substring(data.length - 2)}';
  }

  /// Check if we should log sensitive information
  static bool get shouldLogSensitiveData => kDebugMode;

  /// Log app lifecycle events
  static void lifecycleEvent(String event, {String? details}) {
    if (kDebugMode) {
      final detailsInfo = details != null ? ' - $details' : '';
      print('[LIFECYCLE] $event$detailsInfo');
    }
  }
}
