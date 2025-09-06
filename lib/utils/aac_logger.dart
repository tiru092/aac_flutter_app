import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Logger utility for AAC Flutter App
/// Replaces print() statements with proper logging that works in both debug and release modes
class AACLogger {
  static const String _appTag = 'AAC_APP';
  
  /// Log information messages
  static void info(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log('INFO', message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  /// Log debug messages (only in debug mode)
  static void debug(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      _log('DEBUG', message, tag: tag, error: error, stackTrace: stackTrace);
    }
  }
  
  /// Log warning messages
  static void warning(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log('WARNING', message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  /// Log error messages
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log('ERROR', message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  /// Log voice-related operations
  static void voice(String message, {Object? error, StackTrace? stackTrace}) {
    _log('VOICE', message, tag: 'Voice', error: error, stackTrace: stackTrace);
  }
  
  /// Log authentication-related operations
  static void auth(String message, {Object? error, StackTrace? stackTrace}) {
    _log('AUTH', message, tag: 'Auth', error: error, stackTrace: stackTrace);
  }
  
  /// Log Firebase-related operations
  static void firebase(String message, {Object? error, StackTrace? stackTrace}) {
    _log('FIREBASE', message, tag: 'Firebase', error: error, stackTrace: stackTrace);
  }
  
  /// Log UI-related operations
  static void ui(String message, {Object? error, StackTrace? stackTrace}) {
    _log('UI', message, tag: 'UI', error: error, stackTrace: stackTrace);
  }
  
  /// Log performance-related operations
  static void performance(String message, {Object? error, StackTrace? stackTrace}) {
    _log('PERFORMANCE', message, tag: 'Performance', error: error, stackTrace: stackTrace);
  }
  
  /// Internal logging method
  static void _log(String level, String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final timestamp = DateTime.now().toIso8601String();
    final logTag = tag != null ? '$_appTag:$tag' : _appTag;
    final logMessage = '[$timestamp] [$level] [$logTag] $message';
    
    if (kDebugMode) {
      // In debug mode, use developer.log for better debugging
      developer.log(
        message,
        time: DateTime.now(),
        level: _getLevelValue(level),
        name: logTag,
        error: error,
        stackTrace: stackTrace,
      );
    } else {
      // In release mode, use a more conservative approach
      if (level == 'ERROR' || level == 'WARNING') {
        developer.log(
          logMessage,
          time: DateTime.now(),
          level: _getLevelValue(level),
          name: logTag,
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }
  
  /// Convert log level to numeric value
  static int _getLevelValue(String level) {
    switch (level) {
      case 'DEBUG':
        return 500;
      case 'INFO':
        return 800;
      case 'WARNING':
        return 900;
      case 'ERROR':
        return 1000;
      default:
        return 800;
    }
  }
  
  /// Log method call for debugging
  static void methodCall(String className, String methodName, {Map<String, dynamic>? params}) {
    if (kDebugMode) {
      final paramsStr = params != null ? ' params: $params' : '';
      debug('$className.$methodName()$paramsStr', tag: 'MethodCall');
    }
  }
  
  /// Log user interaction for analytics
  static void userAction(String action, {Map<String, dynamic>? details}) {
    final detailsStr = details != null ? ' details: $details' : '';
    info('User action: $action$detailsStr', tag: 'UserAction');
  }
}
