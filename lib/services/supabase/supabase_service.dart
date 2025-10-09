import 'package:flutter/foundation.dart';
import 'supabase_config.dart';
import 'supabase_auth_service.dart';
import 'supabase_database_service.dart';

/// Main Supabase Service Orchestrator
/// Coordinates all Supabase services during migration
class SupabaseService {
  static SupabaseService? _instance;
  
  // Service instances
  late final SupabaseAuthService _authService;
  late final SupabaseDatabaseService _databaseService;
  
  bool _initialized = false;
  
  SupabaseService._internal();
  
  factory SupabaseService() {
    _instance ??= SupabaseService._internal();
    return _instance!;
  }
  
  /// Initialize all Supabase services
  Future<void> initialize() async {
    if (_initialized) {
      if (kDebugMode) {
        print('SupabaseService already initialized');
      }
      return;
    }
    
    try {
      // Initialize Supabase configuration
      await SupabaseConfig.initialize();
      
      // Initialize service instances
      _authService = SupabaseAuthService();
      _databaseService = SupabaseDatabaseService();
      
      _initialized = true;
      
      if (kDebugMode) {
        print('SupabaseService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing SupabaseService: $e');
      }
      rethrow;
    }
  }
  
  /// Check if service is initialized
  bool get isInitialized => _initialized;
  
  /// Get auth service
  SupabaseAuthService get auth {
    _ensureInitialized();
    return _authService;
  }
  
  /// Get database service
  SupabaseDatabaseService get database {
    _ensureInitialized();
    return _databaseService;
  }
  
  /// Test Supabase connection
  Future<bool> testConnection() async {
    try {
      _ensureInitialized();
      return await SupabaseConfig.testConnection();
    } catch (e) {
      if (kDebugMode) {
        print('Supabase connection test failed: $e');
      }
      return false;
    }
  }
  
  /// Get current environment
  String get environment => SupabaseConfig.environment;
  
  /// Get current URL
  String get currentUrl => SupabaseConfig.currentUrl;
  
  /// Check if user is authenticated
  bool get isAuthenticated => _initialized && _authService.isAuthenticated;
  
  /// Get current user ID
  String? get currentUserId => _initialized ? _authService.currentUserId : null;
  
  /// Ensure service is initialized
  void _ensureInitialized() {
    if (!_initialized) {
      throw Exception('SupabaseService not initialized. Call initialize() first');
    }
  }
  
  /// Dispose all services
  Future<void> dispose() async {
    try {
      await SupabaseConfig.dispose();
      _initialized = false;
      
      if (kDebugMode) {
        print('SupabaseService disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error disposing SupabaseService: $e');
      }
    }
  }
}

/// Global instance for easy access
final supabaseService = SupabaseService();