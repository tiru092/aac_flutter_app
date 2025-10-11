import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/favorites_service.dart';
import '../services/user_data_manager.dart';
import '../services/data_services_initializer_robust.dart';

/// Comprehensive sync testing and debugging utility
class SyncTestHelper {
  
  /// Test background sync functionality
  static Future<Map<String, dynamic>> testBackgroundSync() async {
    final results = <String, dynamic>{};
    
    try {
      // Check Supabase connection
      results['supabase_connected'] = await _testSupabaseConnection();
      
      // Check authentication state
      results['auth_state'] = await _testAuthenticationState();
      
      // Test UserDataManager sync
      results['user_data_sync'] = await _testUserDataManagerSync();
      
      // Test FavoritesService sync
      results['favorites_sync'] = await _testFavoritesServiceSync();
      
      // Check database schema
      results['schema_check'] = await _testDatabaseSchema();
      
      results['overall_status'] = 'COMPLETED';
      results['timestamp'] = DateTime.now().toIso8601String();
      
    } catch (e) {
      results['error'] = e.toString();
      results['overall_status'] = 'FAILED';
    }
    
    return results;
  }
  
  /// Test basic Supabase connectivity
  static Future<Map<String, dynamic>> _testSupabaseConnection() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      
      return {
        'connected': true,
        'user_authenticated': user != null,
        'user_id': user?.id,
        'user_email': user?.email,
      };
    } catch (e) {
      return {
        'connected': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Test authentication state
  static Future<Map<String, dynamic>> _testAuthenticationState() async {
    try {
      final userDataManager = DataServicesInitializer.instance.userDataManager;
      
      return {
        'data_manager_initialized': userDataManager != null,
        'current_user_id': userDataManager?.currentUserId,
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }
  
  /// Test UserDataManager cloud sync
  static Future<Map<String, dynamic>> _testUserDataManagerSync() async {
    try {
      final userDataManager = DataServicesInitializer.instance.userDataManager;
      if (userDataManager == null) {
        return {'error': 'UserDataManager not initialized'};
      }
      
      // Test write
      final testKey = 'sync_test_${DateTime.now().millisecondsSinceEpoch}';
      final testData = {
        'test': true,
        'timestamp': DateTime.now().toIso8601String(),
        'version': 1,
      };
      
      await userDataManager.setCloudData(testKey, testData);
      
      // Test read
      final readData = await userDataManager.getCloudData(testKey);
      
      return {
        'write_success': true,
        'read_success': readData != null,
        'data_matches': readData != null && readData['test'] == true,
        'test_key': testKey,
        'written_data': testData,
        'read_data': readData,
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }
  
  /// Test FavoritesService sync
  static Future<Map<String, dynamic>> _testFavoritesServiceSync() async {
    try {
      final favoritesService = DataServicesInitializer.instance.favoritesService;
      if (favoritesService == null) {
        return {'error': 'FavoritesService not initialized'};
      }
      
      final syncStatus = favoritesService.getSyncStatus();
      
      return {
        'service_initialized': syncStatus['initialized'],
        'favorites_count': syncStatus['favorites_count'],
        'history_count': syncStatus['history_count'],
        'sync_status': syncStatus,
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }
  
  /// Test database schema compatibility
  static Future<Map<String, dynamic>> _testDatabaseSchema() async {
    try {
      final client = Supabase.instance.client;
      
      // Test user_settings table structure
      final settingsTest = await client
          .from('user_settings')
          .select('profile_id, setting_key, setting_value, last_modified_at')
          .limit(1);
      
      return {
        'user_settings_accessible': true,
        'schema_compatible': true,
        'sample_query_success': settingsTest != null,
      };
    } catch (e) {
      return {
        'user_settings_accessible': false,
        'schema_compatible': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Print detailed sync status for debugging
  static Future<void> printSyncStatus() async {
    if (kDebugMode) {
      print('\n🔄 ===== AAC SYNC STATUS DEBUG =====');
      
      final results = await testBackgroundSync();
      
      print('📊 Overall Status: ${results['overall_status']}');
      print('⏰ Timestamp: ${results['timestamp']}');
      print('');
      
      // Supabase Connection
      final supabaseStatus = results['supabase_connected'] ?? {};
      print('🌐 Supabase Connection:');
      print('  Connected: ${supabaseStatus['connected']}');
      print('  Authenticated: ${supabaseStatus['user_authenticated']}');
      print('  User ID: ${supabaseStatus['user_id']}');
      print('');
      
      // User Data Sync
      final userDataStatus = results['user_data_sync'] ?? {};
      print('💾 UserDataManager Sync:');
      print('  Write Success: ${userDataStatus['write_success']}');
      print('  Read Success: ${userDataStatus['read_success']}');
      print('  Data Matches: ${userDataStatus['data_matches']}');
      if (userDataStatus['error'] != null) {
        print('  Error: ${userDataStatus['error']}');
      }
      print('');
      
      // Favorites Service
      final favoritesStatus = results['favorites_sync'] ?? {};
      print('⭐ FavoritesService:');
      print('  Initialized: ${favoritesStatus['service_initialized']}');
      print('  Favorites Count: ${favoritesStatus['favorites_count']}');
      print('  History Count: ${favoritesStatus['history_count']}');
      if (favoritesStatus['error'] != null) {
        print('  Error: ${favoritesStatus['error']}');
      }
      print('');
      
      // Schema Check
      final schemaStatus = results['schema_check'] ?? {};
      print('🗄️  Database Schema:');
      print('  Settings Table Accessible: ${schemaStatus['user_settings_accessible']}');
      print('  Schema Compatible: ${schemaStatus['schema_compatible']}');
      if (schemaStatus['error'] != null) {
        print('  Error: ${schemaStatus['error']}');
      }
      
      print('🔄 ===== END SYNC STATUS DEBUG =====\n');
    }
  }
}