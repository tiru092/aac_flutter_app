import 'package:flutter/foundation.dart';
import 'supabase/index.dart';

/// Migration Service for Firebase to Supabase transition
/// Handles parallel operation and gradual data migration
class FirebaseSupabaseMigrationService {
  static FirebaseSupabaseMigrationService? _instance;
  
  bool _migrationEnabled = false;
  bool _supabasePrimary = false; // When true, Supabase becomes primary data source
  
  FirebaseSupabaseMigrationService._internal();
  
  factory FirebaseSupabaseMigrationService() {
    _instance ??= FirebaseSupabaseMigrationService._internal();
    return _instance!;
  }
  
  /// Enable parallel operation mode
  Future<void> enableMigration() async {
    try {
      // Initialize Supabase services
      await supabaseService.initialize();
      
      // Test Supabase connection
      final connected = await supabaseService.testConnection();
      if (!connected) {
        throw Exception('Cannot connect to Supabase');
      }
      
      _migrationEnabled = true;
      
      if (kDebugMode) {
        print('Migration mode enabled - parallel Firebase/Supabase operation');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error enabling migration: $e');
      }
      rethrow;
    }
  }
  
  /// Switch to Supabase as primary data source
  void switchToSupabasePrimary() {
    if (!_migrationEnabled) {
      throw Exception('Migration not enabled. Call enableMigration() first');
    }
    
    _supabasePrimary = true;
    
    if (kDebugMode) {
      print('Switched to Supabase as primary data source');
    }
  }
  
  /// Check if migration is enabled
  bool get isMigrationEnabled => _migrationEnabled;
  
  /// Check if Supabase is primary data source
  bool get isSupabasePrimary => _supabasePrimary;
  
  /// Check if Firebase is still primary
  bool get isFirebasePrimary => _migrationEnabled && !_supabasePrimary;
  
  /// Get migration status
  Map<String, dynamic> getMigrationStatus() {
    return {
      'migrationEnabled': _migrationEnabled,
      'supabasePrimary': _supabasePrimary,
      'firebasePrimary': _migrationEnabled && !_supabasePrimary,
      'supabaseConnected': supabaseService.isInitialized,
      'environment': supabaseService.isInitialized ? supabaseService.environment : null,
    };
  }
  
  /// Disable migration (back to Firebase only)
  void disableMigration() {
    _migrationEnabled = false;
    _supabasePrimary = false;
    
    if (kDebugMode) {
      print('Migration disabled - Firebase only mode');
    }
  }
}

/// Global migration service instance
final migrationService = FirebaseSupabaseMigrationService();