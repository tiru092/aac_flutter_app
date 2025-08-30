import 'package:flutter/foundation.dart';
import '../services/firebase_config_service.dart';
import '../services/connectivity_service.dart';
import '../services/auth_wrapper_service.dart';

/// Comprehensive authentication diagnostics utility
class AuthDiagnostics {
  /// Run complete authentication system diagnostics
  static Future<AuthDiagnosticResult> runCompleteDiagnostics() async {
    debugPrint('AuthDiagnostics: Starting complete authentication diagnostics...');
    
    final results = <String, bool>{};
    final messages = <String>[];
    final recommendations = <String>[];
    
    try {
      // 1. Check internet connectivity
      debugPrint('AuthDiagnostics: Checking internet connectivity...');
      final hasInternet = await ConnectivityService.hasInternetConnection();
      results['Internet Connection'] = hasInternet;
      
      if (hasInternet) {
        messages.add('✅ Internet connection is working');
      } else {
        messages.add('❌ No internet connection detected');
        recommendations.add('Check your WiFi or cellular data connection');
      }
      
      // 2. Check Firebase connectivity
      debugPrint('AuthDiagnostics: Checking Firebase connectivity...');
      final canReachFirebase = await ConnectivityService.canReachFirebase();
      results['Firebase Services'] = canReachFirebase;
      
      if (canReachFirebase) {
        messages.add('✅ Firebase services are reachable');
      } else {
        messages.add('❌ Cannot reach Firebase authentication services');
        recommendations.add('Try again in a few moments - Firebase services may be temporarily unavailable');
      }
      
      // 3. Check Firebase configuration
      debugPrint('AuthDiagnostics: Checking Firebase configuration...');
      final firebaseConfigured = FirebaseConfigService.canUseFirebaseServices();
      results['Firebase Configuration'] = firebaseConfigured;
      
      if (firebaseConfigured) {
        messages.add('✅ Firebase is properly configured');
      } else {
        messages.add('❌ Firebase configuration issue detected');
        recommendations.add('Restart the app - Firebase may not have initialized properly');
      }
      
      // 4. Check AuthWrapper service status
      debugPrint('AuthDiagnostics: Checking AuthWrapper service...');
      try {
        final authWrapper = AuthWrapperService();
        final isInitialized = authWrapper.isInitialized;
        results['Authentication Service'] = isInitialized;
        
        if (isInitialized) {
          messages.add('✅ Authentication service is ready');
        } else {
          messages.add('❌ Authentication service not initialized');
          recommendations.add('Restart the app to reinitialize authentication services');
        }
      } catch (e) {
        results['Authentication Service'] = false;
        messages.add('❌ Authentication service error: ${e.toString()}');
        recommendations.add('Restart the app to fix authentication service issues');
      }
      
      // 5. Overall system status
      final allSystemsWorking = results.values.every((status) => status == true);
      results['Overall Status'] = allSystemsWorking;
      
      if (allSystemsWorking) {
        messages.add('🎉 All authentication systems are working properly!');
        messages.add('You should be able to sign in without issues.');
      } else {
        messages.add('⚠️  Some authentication systems have issues');
        messages.add('Please follow the recommendations below to resolve them.');
      }
      
    } catch (e) {
      debugPrint('AuthDiagnostics: Error during diagnostics: $e');
      messages.add('❌ Diagnostic error: ${e.toString()}');
      recommendations.add('Restart the app and try again');
    }
    
    debugPrint('AuthDiagnostics: Diagnostics complete. Overall status: ${results['Overall Status']}');
    
    return AuthDiagnosticResult(
      success: results['Overall Status'] ?? false,
      results: results,
      messages: messages,
      recommendations: recommendations,
    );
  }
  
  /// Quick connectivity check for immediate feedback
  static Future<bool> quickConnectivityCheck() async {
    try {
      final hasInternet = await ConnectivityService.hasInternetConnection();
      final firebaseConfigured = FirebaseConfigService.canUseFirebaseServices();
      
      return hasInternet && firebaseConfigured;
    } catch (e) {
      debugPrint('AuthDiagnostics: Quick check failed: $e');
      return false;
    }
  }
  
  /// Get a simple status message for users
  static Future<String> getSimpleStatusMessage() async {
    final isReady = await quickConnectivityCheck();
    
    if (isReady) {
      return 'Authentication system is ready ✅';
    } else {
      return 'Authentication system needs attention ⚠️';
    }
  }
}

/// Result of authentication diagnostics
class AuthDiagnosticResult {
  final bool success;
  final Map<String, bool> results;
  final List<String> messages;
  final List<String> recommendations;
  
  AuthDiagnosticResult({
    required this.success,
    required this.results,
    required this.messages,
    required this.recommendations,
  });
  
  /// Get a formatted report as a string
  String getFormattedReport() {
    final buffer = StringBuffer();
    
    buffer.writeln('Authentication System Diagnostic Report');
    buffer.writeln('=' * 50);
    buffer.writeln();
    
    // Status summary
    buffer.writeln('SYSTEM STATUS:');
    for (final entry in results.entries) {
      final status = entry.value ? '✅' : '❌';
      buffer.writeln('$status ${entry.key}');
    }
    buffer.writeln();
    
    // Detailed messages
    buffer.writeln('DETAILED RESULTS:');
    for (final message in messages) {
      buffer.writeln(message);
    }
    buffer.writeln();
    
    // Recommendations
    if (recommendations.isNotEmpty) {
      buffer.writeln('RECOMMENDATIONS:');
      for (int i = 0; i < recommendations.length; i++) {
        buffer.writeln('${i + 1}. ${recommendations[i]}');
      }
    }
    
    return buffer.toString();
  }
}