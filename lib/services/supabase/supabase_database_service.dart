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
  
  /// Add communication history entry
  Future<void> addCommunicationHistory(Map<String, dynamic> historyData) async {
    try {
      final data = {
        'user_id': _currentUserId,
        ...historyData,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      await _client
          .from('communication_history')
          .insert(data);
      
      if (kDebugMode) {
        print('Communication history added successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding communication history: $e');
      }
      rethrow;
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