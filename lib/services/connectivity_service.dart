import 'dart:io';
import 'package:flutter/foundation.dart';

/// Simple connectivity checking service
class ConnectivityService {
  static const String _testHost = 'google.com';
  static const int _testPort = 80;
  static const Duration _timeout = Duration(seconds: 5);
  
  /// Check if device has internet connectivity
  static Future<bool> hasInternetConnection() async {
    try {
      debugPrint('ConnectivityService: Checking internet connectivity...');
      
      final result = await InternetAddress.lookup(_testHost).timeout(_timeout);
      
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        debugPrint('ConnectivityService: Internet connection available');
        return true;
      }
      
      debugPrint('ConnectivityService: No internet connection');
      return false;
    } catch (e) {
      debugPrint('ConnectivityService: Error checking connectivity: $e');
      return false;
    }
  }
  
  /// Check if Firebase services are reachable
  static Future<bool> canReachFirebase() async {
    try {
      debugPrint('ConnectivityService: Checking Firebase connectivity...');
      
      // Try to reach Firebase Auth endpoints
      final hosts = [
        'identitytoolkit.googleapis.com',
        'securetoken.googleapis.com',
        'firebase.googleapis.com'
      ];
      
      for (final host in hosts) {
        try {
          final result = await InternetAddress.lookup(host).timeout(_timeout);
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            debugPrint('ConnectivityService: Firebase services reachable via $host');
            return true;
          }
        } catch (e) {
          debugPrint('ConnectivityService: Cannot reach $host: $e');
          continue;
        }
      }
      
      debugPrint('ConnectivityService: Cannot reach Firebase services');
      return false;
    } catch (e) {
      debugPrint('ConnectivityService: Error checking Firebase connectivity: $e');
      return false;
    }
  }
  
  /// Get connection status message for users
  static Future<String> getConnectionStatusMessage() async {
    final hasInternet = await hasInternetConnection();
    
    if (!hasInternet) {
      return 'No internet connection available. Please check your network settings.';
    }
    
    final canReachFirebase = await ConnectivityService.canReachFirebase();
    if (!canReachFirebase) {
      return 'Cannot reach authentication services. Please try again in a moment.';
    }
    
    return 'Connection is working properly.';
  }
}