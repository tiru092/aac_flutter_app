import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Supabase service configuration and initialization
/// This service runs parallel to Firebase during migration
class SupabaseConfig {
  static SupabaseClient? _client;
  static bool _initialized = false;
  
  // Environment detection
  static const String _env = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );
  
  // Development configuration
  static const String _devUrl = 'https://qvxatrnbufqzyagdlepa.supabase.co';
  static const String _devAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF2eGF0cm5idWZxenlhZ2RsZXBhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk4MDEyMDQsImV4cCI6MjA3NTM3NzIwNH0.CqID6t3H6Kidmj2IlXNU1uWRexD80_FxmFtZC_uquBI';
  
  // Production configuration (same for now during migration)
  static const String _prodUrl = 'https://qvxatrnbufqzyagdlepa.supabase.co';
  static const String _prodAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF2eGF0cm5idWZxenlhZ2RsZXBhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk4MDEyMDQsImV4cCI6MjA3NTM3NzIwNH0.CqID6t3H6Kidmj2IlXNU1uWRexD80_FxmFtZC_uquBI';
  
  /// Get the current Supabase client
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call SupabaseConfig.initialize() first');
    }
    return _client!;
  }
  
  /// Check if Supabase is initialized
  static bool get isInitialized => _initialized;
  
  /// Initialize Supabase
  static Future<void> initialize() async {
    if (_initialized) {
      if (kDebugMode) {
        print('Supabase already initialized');
      }
      return;
    }
    
    try {
      const url = _env == 'production' ? _prodUrl : _devUrl;
      const anonKey = _env == 'production' ? _prodAnonKey : _devAnonKey;
      
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: kDebugMode,
      );
      
      _client = Supabase.instance.client;
      _initialized = true;
      
      if (kDebugMode) {
        print('Supabase initialized successfully');
        print('Environment: $_env');
        print('URL: $url');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Supabase: $e');
      }
      rethrow;
    }
  }
  
  /// Check network connectivity
  static Future<bool> isNetworkConnected() async {
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
  
  /// Test Supabase connection
  static Future<bool> testConnection() async {
    try {
      if (!_initialized) {
        await initialize();
      }
      
      if (!(await isNetworkConnected())) {
        return false;
      }
      
      // Test with a simple query
      await _client!.from('user_profiles').select('count').count();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Supabase connection test failed: $e');
      }
      return false;
    }
  }
  
  /// Get current environment
  static String get environment => _env;
  
  /// Get current URL
  static String get currentUrl => _env == 'production' ? _prodUrl : _devUrl;
  
  /// Dispose resources
  static Future<void> dispose() async {
    _client = null;
    _initialized = false;
  }
}

/// Extension for easier access to Supabase client
extension SupabaseExtension on SupabaseClient {
  /// Get user ID from current session
  String? get currentUserId => auth.currentUser?.id;
  
  /// Check if user is authenticated
  bool get isAuthenticated => auth.currentUser != null;
}