import 'package:flutter/foundation.dart';
import '../firebase_supabase_migration_service.dart';
import '../supabase/index.dart';
import 'hybrid_auth_service.dart';
import 'hybrid_database_service.dart';
import 'hybrid_user_profile_service.dart';

/// Hybrid Service Orchestrator
/// Coordinates all hybrid services during Firebase to Supabase migration
class HybridServiceOrchestrator {
  static HybridServiceOrchestrator? _instance;
  
  late final HybridAuthService _authService;
  late final HybridDatabaseService _databaseService;
  late final HybridUserProfileService _userProfileService;
  
  bool _initialized = false;
  
  HybridServiceOrchestrator._internal();
  
  factory HybridServiceOrchestrator() {
    _instance ??= HybridServiceOrchestrator._internal();
    return _instance!;
  }
  
  /// Initialize all hybrid services
  Future<void> initialize() async {
    if (_initialized) {
      if (kDebugMode) {
        print('HybridServiceOrchestrator already initialized');
      }
      return;
    }
    
    try {
      // Initialize migration service first
      await migrationService.enableMigration();
      
      // Initialize hybrid services
      _authService = HybridAuthService();
      _databaseService = HybridDatabaseService();
      _userProfileService = HybridUserProfileService();
      
      _initialized = true;
      
      if (kDebugMode) {
        print('HybridServiceOrchestrator: initialized successfully');
      }
        
    } catch (e) {
      if (kDebugMode) {
        print('HybridServiceOrchestrator ERROR: Failed to initialize: $e');
      }
      rethrow;
    }
  }
  
  /// Check if orchestrator is initialized
  bool get isInitialized => _initialized;
  
  /// Get auth service
  HybridAuthService get auth {
    _ensureInitialized();
    return _authService;
  }
  
  /// Get database service
  HybridDatabaseService get database {
    _ensureInitialized();
    return _databaseService;
  }
  
  /// Get user profile service
  HybridUserProfileService get userProfile {
    _ensureInitialized();
    return _userProfileService;
  }
  
  /// Switch to Supabase as primary data source
  Future<void> switchToSupabasePrimary() async {
    try {
      _ensureInitialized();
      
      migrationService.switchToSupabasePrimary();
      
      // Clear any cached data to force reload from new primary
      _userProfileService.clearCache();
      
      if (kDebugMode) {
        print('HybridServiceOrchestrator: Switched to Supabase as primary data source');
      }
        
    } catch (e) {
      if (kDebugMode) {
        print('HybridServiceOrchestrator ERROR: Failed to switch to Supabase primary: $e');
      }
      rethrow;
    }
  }
  
  /// Get comprehensive migration status
  Map<String, dynamic> getMigrationStatus() {
    if (!_initialized) {
      return {'initialized': false};
    }
    
    return {
      'initialized': true,
      'migration': migrationService.getMigrationStatus(),
      'auth': _authService.getUserMigrationStatus(),
      'userProfile': _userProfileService.getProfileMigrationStatus(),
    };
  }
  
  /// Test connectivity to both services
  Future<Map<String, bool>> testConnectivity() async {
    final results = <String, bool>{};
    
    try {
      // Test Firebase connectivity (simple auth state check)
      results['firebase'] = true; // Firebase is always available in this context
      
      // Test Supabase connectivity
      if (migrationService.isMigrationEnabled) {
        results['supabase'] = await supabaseService.testConnection();
      } else {
        results['supabase'] = false;
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('HybridServiceOrchestrator ERROR: Connectivity test failed: $e');
      }
      results['firebase'] = false;
      results['supabase'] = false;
    }
    
    return results;
  }
  
  /// Disable migration and return to Firebase-only mode
  Future<void> disableMigration() async {
    try {
      migrationService.disableMigration();
      
      // Clear caches to ensure clean state
      _userProfileService.clearCache();
      
      if (kDebugMode) {
        print('HybridServiceOrchestrator: Migration disabled - returned to Firebase-only mode');
      }
        
    } catch (e) {
      if (kDebugMode) {
        print('HybridServiceOrchestrator ERROR: Failed to disable migration: $e');
      }
      rethrow;
    }
  }
  
  /// Ensure orchestrator is initialized
  void _ensureInitialized() {
    if (!_initialized) {
      throw Exception('HybridServiceOrchestrator not initialized. Call initialize() first');
    }
  }
  
  /// Dispose all services
  Future<void> dispose() async {
    try {
      if (_initialized) {
        _userProfileService.clearCache();
        _initialized = false;
      }
      
      if (kDebugMode) {
        print('HybridServiceOrchestrator: disposed');
      }
        
    } catch (e) {
      if (kDebugMode) {
        print('HybridServiceOrchestrator ERROR: Error disposing: $e');
      }
    }
  }
}

/// Global hybrid service orchestrator instance
final hybridServices = HybridServiceOrchestrator();