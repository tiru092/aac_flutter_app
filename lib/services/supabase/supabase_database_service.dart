import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

/// Supabase Database Service
/// Handles database operations for Supabase during migration
class SupabaseDatabaseService {
  static SupabaseDatabaseService? _instance;
  late final SupabaseClient _client;
  
  SupabaseDatabaseService._internal() {
    _client = SupabaseConfig.client;
  }
  
  factory SupabaseDatabaseService() {
    _instance ??= SupabaseDatabaseService._internal();
    return _instance!;
  }
  
  /// Get current user ID (required for RLS)
  String get _currentUserId {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return userId;
  }
  
  // User Profiles Operations
  
  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .eq('id', _currentUserId)
          .maybeSingle();
      
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user profile: $e');
      }
      rethrow;
    }
  }
  
  /// Create or update user profile
  Future<void> upsertUserProfile(Map<String, dynamic> profileData) async {
    try {
      final data = {
        'id': _currentUserId,
        ...profileData,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      await _client
          .from('user_profiles')
          .upsert(data);
      
      if (kDebugMode) {
        print('User profile upserted successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error upserting user profile: $e');
      }
      rethrow;
    }
  }
  
  // Categories Operations
  
  /// Get categories for user
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _client
          .from('categories')
          .select()
          .eq('user_id', _currentUserId)
          .order('name');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting categories: $e');
      }
      rethrow;
    }
  }
  
  /// Create category
  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> categoryData) async {
    try {
      final data = {
        'user_id': _currentUserId,
        ...categoryData,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      final response = await _client
          .from('categories')
          .insert(data)
          .select()
          .single();
      
      if (kDebugMode) {
        print('Category created successfully: ${response['id']}');
      }
      
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating category: $e');
      }
      rethrow;
    }
  }
  
  /// Update category
  Future<void> updateCategory(String categoryId, Map<String, dynamic> updates) async {
    try {
      final data = {
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      await _client
          .from('categories')
          .update(data)
          .eq('id', categoryId)
          .eq('user_id', _currentUserId);
      
      if (kDebugMode) {
        print('Category updated successfully: $categoryId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating category: $e');
      }
      rethrow;
    }
  }
  
  /// Delete category
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _client
          .from('categories')
          .delete()
          .eq('id', categoryId)
          .eq('user_id', _currentUserId);
      
      if (kDebugMode) {
        print('Category deleted successfully: $categoryId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting category: $e');
      }
      rethrow;
    }
  }
  
  // Symbols Operations
  
  /// Get symbols for category
  Future<List<Map<String, dynamic>>> getSymbolsForCategory(String categoryId) async {
    try {
      final response = await _client
          .from('symbols')
          .select()
          .eq('category_id', categoryId)
          .order('name');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting symbols for category: $e');
      }
      rethrow;
    }
  }
  
  /// Create symbol
  Future<Map<String, dynamic>> createSymbol(Map<String, dynamic> symbolData) async {
    try {
      final data = {
        'user_id': _currentUserId,
        ...symbolData,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      final response = await _client
          .from('symbols')
          .insert(data)
          .select()
          .single();
      
      if (kDebugMode) {
        print('Symbol created successfully: ${response['id']}');
      }
      
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating symbol: $e');
      }
      rethrow;
    }
  }
  
  // Communication History Operations
  
  /// Get communication history
  Future<List<Map<String, dynamic>>> getCommunicationHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('communication_history')
          .select()
          .eq('user_id', _currentUserId)
          .order('created_at', ascending: false)
          .limit(limit)
          .range(offset, offset + limit - 1);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting communication history: $e');
      }
      rethrow;
    }
  }
  
  /// Add communication history entry with schema-compatible SCD merge logic
  Future<void> addCommunicationHistory(Map<String, dynamic> historyData) async {
    try {
      final now = DateTime.now();
      final messageText = historyData['message_text'] ?? 'Unknown';
      
      // Schema-compatible SCD: Store metadata in existing context_info JSONB column
      final originalContext = historyData['context_info'] as Map<String, dynamic>? ?? {};
      final timeHash = (now.millisecondsSinceEpoch ~/ 1000).toString();
      
      final enhancedContext = {
        ...originalContext,
        'scd_metadata': {
          'composite_key': '${_currentUserId}_${messageText}_$timeHash',
          'sync_method': 'supabase_database_service',
          'version': 1,
          'created_timestamp': now.toIso8601String(),
        }
      };
      
      final data = {
        'user_id': _currentUserId,
        ...historyData,
        'context_info': enhancedContext,
        'created_at': historyData['created_at'] ?? now.toIso8601String(),
      };
      
      // SCD Strategy: Check for duplicates within 5-minute window using existing columns
      final existing = await _client
          .from('communication_history')
          .select('id, created_at, context_info')
          .eq('user_id', _currentUserId!)
          .eq('message_text', messageText)
          .gte('created_at', now.subtract(Duration(minutes: 5)).toIso8601String())
          .maybeSingle();
      
      if (existing != null) {
        // SCD Type 1: Update existing record by merging context
        final existingContext = existing['context_info'] as Map<String, dynamic>? ?? {};
        final mergedContext = {
          ...existingContext,
          ...enhancedContext,
          'scd_metadata': {
            ...((existingContext['scd_metadata'] as Map<String, dynamic>?) ?? {}),
            ...enhancedContext['scd_metadata'],
            'update_count': ((existingContext['scd_metadata']?['update_count'] as int?) ?? 0) + 1,
            'last_updated': now.toIso8601String(),
          }
        };
        
        await _client
            .from('communication_history')
            .update({
              ...historyData,
              'context_info': mergedContext,
            })
            .eq('id', existing['id']);
        
        if (kDebugMode) {
          print('🔄 SCD: Communication history updated (merged duplicate): ${existing['id']}');
        }
      } else {
        // Insert new record
        await _client
            .from('communication_history')
            .insert(data);
        
        if (kDebugMode) {
          print('✅ SCD: Communication history added successfully (new entry)');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ SCD Error adding communication history: $e');
      }
      
      // Fallback: Try simple insert without SCD logic
      try {
        if (kDebugMode) {
          print('🔄 SCD FALLBACK: Attempting simple insert...');
        }
        
        final fallbackData = {
          'user_id': _currentUserId,
          ...historyData,
          'created_at': historyData['created_at'] ?? DateTime.now().toIso8601String(),
        };
        
        await _client
            .from('communication_history')
            .insert(fallbackData);
        
        if (kDebugMode) {
          print('✅ SCD FALLBACK: Simple insert successful');
        }
      } catch (fallbackError) {
        if (kDebugMode) {
          print('❌ SCD FALLBACK FAILED: $fallbackError');
        }
        rethrow;
      }
    }
  }
  
  // Favorites Operations
  
  /// Get user favorites
  Future<List<Map<String, dynamic>>> getUserFavorites() async {
    try {
      final response = await _client
          .from('user_favorites')
          .select('*, symbols(*)')
          .eq('user_id', _currentUserId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user favorites: $e');
      }
      rethrow;
    }
  }
  
  /// Add to favorites
  Future<void> addToFavorites(String symbolId) async {
    try {
      final data = {
        'user_id': _currentUserId,
        'symbol_id': symbolId,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      await _client
          .from('user_favorites')
          .insert(data);
      
      if (kDebugMode) {
        print('Symbol added to favorites: $symbolId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding to favorites: $e');
      }
      rethrow;
    }
  }
  
  /// Remove from favorites
  Future<void> removeFromFavorites(String symbolId) async {
    try {
      await _client
          .from('user_favorites')
          .delete()
          .eq('user_id', _currentUserId)
          .eq('symbol_id', symbolId);
      
      if (kDebugMode) {
        print('Symbol removed from favorites: $symbolId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error removing from favorites: $e');
      }
      rethrow;
    }
  }
  
  // Subscription Operations
  
  /// Get user subscription
  Future<Map<String, dynamic>?> getUserSubscription() async {
    try {
      final response = await _client
          .from('subscriptions')
          .select()
          .eq('user_id', _currentUserId)
          .eq('status', 'active')
          .maybeSingle();
      
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user subscription: $e');
      }
      rethrow;
    }
  }
  
  /// Create or update subscription
  Future<void> upsertSubscription(Map<String, dynamic> subscriptionData) async {
    try {
      final data = {
        'user_id': _currentUserId,
        ...subscriptionData,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      await _client
          .from('subscriptions')
          .upsert(data);
      
      if (kDebugMode) {
        print('Subscription upserted successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error upserting subscription: $e');
      }
      rethrow;
    }
  }
}