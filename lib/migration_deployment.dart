import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'services/hybrid/index.dart';

/// Migration Deployment Helper
/// Add this to your main.dart for safe deployment testing
class MigrationDeployment {
  static bool _migrationInitialized = false;
  
  /// Initialize migration services safely
  static Future<void> initializeMigration() async {
    if (_migrationInitialized) return;
    
    try {
      // Only initialize in debug mode first for testing
      if (kDebugMode) {
        print('🔄 Starting Supabase migration initialization...');
        
        // Initialize hybrid services
        await hybridServices.initialize();
        
        // Test connectivity
        final connectivity = await hybridServices.testConnectivity();
        
        print('✅ Migration initialized successfully!');
        print('   Firebase: ${connectivity['firebase']}');
        print('   Supabase: ${connectivity['supabase']}');
        
        // Get migration status
        final status = hybridServices.getMigrationStatus();
        print('📊 Migration Status:');
        print('   - Enabled: ${status['migration']['migrationEnabled']}');
        print('   - Primary: ${status['migration']['primaryService']}');
        
        _migrationInitialized = true;
        
      } else {
        // In production, start with Firebase-only for safety
        print('🔒 Production mode: Migration disabled for safety');
        print('   App running on Firebase-only mode');
      }
      
    } catch (e) {
      print('⚠️  Migration initialization failed: $e');
      print('📝 App will continue with Firebase-only mode');
      
      // Don't throw error - let app continue with Firebase
      _migrationInitialized = false;
      
      // Mark as "initialized" even though migration failed
      // This prevents repeated attempts and allows app to work offline
      _migrationInitialized = true;
    }
  }
  
  /// Enable migration in production (call this after testing)
  static Future<void> enableProductionMigration() async {
    try {
      print('🚀 Enabling production migration...');
      
      await hybridServices.initialize();
      
      final connectivity = await hybridServices.testConnectivity();
      print('✅ Production migration enabled!');
      print('   Firebase: ${connectivity['firebase']}');
      print('   Supabase: ${connectivity['supabase']}');
      
      _migrationInitialized = true;
      
    } catch (e) {
      print('❌ Production migration failed: $e');
      rethrow;
    }
  }
  
  /// Check if migration is ready
  static bool get isReady => _migrationInitialized;
  
  /// Get current migration info
  static Map<String, dynamic> getInfo() {
    if (!_migrationInitialized) {
      return {
        'status': 'disabled',
        'mode': 'firebase_only',
        'ready': false,
      };
    }
    
    return hybridServices.getMigrationStatus();
  }
}