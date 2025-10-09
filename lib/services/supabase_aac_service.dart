import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/symbol.dart';
import '../models/user_profile.dart';
import '../models/communication_history.dart';
import '../models/app_settings.dart';
import '../utils/aac_logger.dart';

/// Comprehensive Supabase Service for AAC App
/// Handles all user data with local-first, cloud-sync architecture
class SupabaseAACService {
  static const String _tag = 'SupabaseAACService';
  static final SupabaseClient _supabase = Supabase.instance.client;
  
  // Current user session
  static String? get currentUserId => _supabase.auth.currentUser?.id;
  static User? get currentUser => _supabase.auth.currentUser;
  
  // ============================================================================
  // 1. USER PROFILE MANAGEMENT
  // ============================================================================
  
  /// Create a new user profile
  static Future<UserProfile> createProfile({
    required String profileName,
    required String displayName,
    required String role, // 'child', 'caregiver', 'therapist'
    String? ageGroup,
    String? communicationLevel,
    String preferredLanguage = 'en-US',
    Map<String, dynamic>? accessibilitySettings,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');
      
      final response = await _supabase
          .from('user_profiles')
          .insert({
            'supabase_uid': userId,
            'profile_name': profileName,
            'display_name': displayName,
            'role': role,
            'age_group': ageGroup,
            'communication_level': communicationLevel,
            'preferred_language': preferredLanguage,
            'accessibility_settings': accessibilitySettings ?? {},
          })
          .select()
          .single();
      
      AACLogger.info('Created profile: $profileName for user: $userId', tag: _tag);
      
      return UserProfile(
        id: response['id'],
        name: response['profile_name'],
        role: UserRole.values.firstWhere(
          (r) => r.toString().split('.').last == response['role'],
          orElse: () => UserRole.child,
        ),
        createdAt: DateTime.parse(response['created_at']),
        settings: ProfileSettings(),
      );
    } catch (e) {
      AACLogger.error('Error creating profile: $e', tag: _tag);
      rethrow;
    }
  }
  
  /// Get all profiles for current user
  static Future<List<UserProfile>> getUserProfiles() async {
    try {
      final userId = currentUserId;
      if (userId == null) return [];
      
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('supabase_uid', userId)
          .eq('is_active', true)
          .order('last_active_at', ascending: false);
      
      return response.map<UserProfile>((data) => UserProfile(
        id: data['id'],
        name: data['profile_name'],
        role: UserRole.values.firstWhere(
          (r) => r.toString().split('.').last == data['role'],
          orElse: () => UserRole.child,
        ),
        createdAt: DateTime.parse(data['created_at']),
        settings: ProfileSettings(),
      )).toList();
    } catch (e) {
      AACLogger.error('Error fetching profiles: $e', tag: _tag);
      return [];
    }
  }
  
  /// Update profile activity timestamp
  static Future<void> updateProfileActivity(String profileId) async {
    try {
      await _supabase
          .from('user_profiles')
          .update({'last_active_at': DateTime.now().toIso8601String()})
          .eq('id', profileId);
    } catch (e) {
      AACLogger.warning('Failed to update profile activity: $e', tag: _tag);
    }
  }
  
  // ============================================================================
  // 2. FAVORITES MANAGEMENT
  // ============================================================================
  
  /// Add symbol to favorites
  static Future<void> addToFavorites({
    required String profileId,
    required String symbolReference,
    required Map<String, dynamic> symbolData,
    String symbolType = 'global_default',
  }) async {
    try {
      await _supabase.from('user_favorites').upsert({
        'profile_id': profileId,
        'symbol_reference': symbolReference,
        'symbol_data': symbolData,
        'symbol_type': symbolType,
        'favorite_order': 0,
        'frequency_count': 1,
      });
      
      AACLogger.info('Added $symbolReference to favorites for profile $profileId', tag: _tag);
    } catch (e) {
      AACLogger.error('Error adding to favorites: $e', tag: _tag);
      rethrow;
    }
  }
  
  /// Remove symbol from favorites
  static Future<void> removeFromFavorites({
    required String profileId,
    required String symbolReference,
  }) async {
    try {
      await _supabase
          .from('user_favorites')
          .delete()
          .eq('profile_id', profileId)
          .eq('symbol_reference', symbolReference);
      
      AACLogger.info('Removed $symbolReference from favorites', tag: _tag);
    } catch (e) {
      AACLogger.error('Error removing from favorites: $e', tag: _tag);
      rethrow;
    }
  }
  
  /// Get user favorites with usage statistics
  static Future<List<Map<String, dynamic>>> getFavorites(String profileId) async {
    try {
      final response = await _supabase
          .from('user_favorites')
          .select()
          .eq('profile_id', profileId)
          .order('favorite_order')
          .order('frequency_count', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AACLogger.error('Error fetching favorites: $e', tag: _tag);
      return [];
    }
  }
  
  /// Reorder favorites
  static Future<void> reorderFavorites(String profileId, List<String> orderedSymbolRefs) async {
    try {
      final batch = <Future>[];
      
      for (int i = 0; i < orderedSymbolRefs.length; i++) {
        batch.add(
          _supabase
              .from('user_favorites')
              .update({'favorite_order': i})
              .eq('profile_id', profileId)
              .eq('symbol_reference', orderedSymbolRefs[i])
        );
      }
      
      await Future.wait(batch);
      AACLogger.info('Reordered ${orderedSymbolRefs.length} favorites', tag: _tag);
    } catch (e) {
      AACLogger.error('Error reordering favorites: $e', tag: _tag);
      rethrow;
    }
  }
  
  // ============================================================================
  // 3. USAGE HISTORY & ANALYTICS
  // ============================================================================
  
  /// Record symbol usage for analytics
  static Future<void> recordSymbolUsage({
    required String profileId,
    required String symbolReference,
    required String actionType,
    Map<String, dynamic>? symbolData,
    Map<String, dynamic>? contextData,
    int? durationMs,
  }) async {
    try {
      await _supabase.from('symbol_usage_history').insert({
        'profile_id': profileId,
        'symbol_reference': symbolReference,
        'symbol_data': symbolData,
        'action_type': actionType,
        'context_data': contextData ?? {},
        'usage_duration_ms': durationMs,
      });
    } catch (e) {
      // Don't throw on analytics errors - app should continue working
      AACLogger.warning('Failed to record usage: $e', tag: _tag);
    }
  }
  
  /// Get usage statistics for a profile
  static Future<Map<String, dynamic>> getUsageAnalytics(String profileId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now();
      
      final response = await _supabase
          .from('symbol_usage_history')
          .select('symbol_reference, action_type, timestamp')
          .eq('profile_id', profileId)
          .gte('timestamp', startDate.toIso8601String())
          .lte('timestamp', endDate.toIso8601String())
          .order('timestamp', ascending: false);
      
      // Process analytics data
      final analytics = <String, dynamic>{
        'total_actions': response.length,
        'most_used_symbols': <String, int>{},
        'action_breakdown': <String, int>{},
        'daily_usage': <String, int>{},
      };
      
      for (final record in response) {
        final symbol = record['symbol_reference'] as String;
        final action = record['action_type'] as String;
        final timestamp = DateTime.parse(record['timestamp']);
        final dateKey = '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
        
        // Count symbol usage
        analytics['most_used_symbols'][symbol] = 
            (analytics['most_used_symbols'][symbol] ?? 0) + 1;
        
        // Count action types
        analytics['action_breakdown'][action] = 
            (analytics['action_breakdown'][action] ?? 0) + 1;
        
        // Count daily usage
        analytics['daily_usage'][dateKey] = 
            (analytics['daily_usage'][dateKey] ?? 0) + 1;
      }
      
      return analytics;
    } catch (e) {
      AACLogger.error('Error fetching analytics: $e', tag: _tag);
      return {};
    }
  }
  
  // ============================================================================
  // 4. COMMUNICATION HISTORY
  // ============================================================================
  
  /// Save communication phrase
  static Future<void> saveCommunicationPhrase({
    required String profileId,
    required String phraseText,
    required List<Map<String, dynamic>> symbolsUsed,
    String? sessionId,
    Map<String, dynamic>? context,
    bool isFavorite = false,
    int? durationMs,
  }) async {
    try {
      await _supabase.from('communication_history').insert({
        'profile_id': profileId,
        'session_id': sessionId,
        'phrase_text': phraseText,
        'symbols_used': symbolsUsed,
        'context': context ?? {},
        'is_favorite': isFavorite,
        'duration_ms': durationMs,
      });
      
      AACLogger.info('Saved communication phrase for profile $profileId', tag: _tag);
    } catch (e) {
      AACLogger.error('Error saving communication phrase: $e', tag: _tag);
      rethrow;
    }
  }
  
  /// Get communication history
  static Future<List<Map<String, dynamic>>> getCommunicationHistory(
    String profileId, {
    int limit = 50,
    DateTime? startDate,
    bool favoritesOnly = false,
  }) async {
    try {
      var query = _supabase
          .from('communication_history')
          .select()
          .eq('profile_id', profileId);
      
      if (favoritesOnly) {
        query = query.eq('is_favorite', true);
      }
      
      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      
      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AACLogger.error('Error fetching communication history: $e', tag: _tag);
      return [];
    }
  }
  
  /// Toggle phrase favorite status
  static Future<void> togglePhraseFavorite(String phraseId, bool isFavorite) async {
    try {
      await _supabase
          .from('communication_history')
          .update({'is_favorite': isFavorite})
          .eq('id', phraseId);
    } catch (e) {
      AACLogger.error('Error toggling phrase favorite: $e', tag: _tag);
      rethrow;
    }
  }
  
  // ============================================================================
  // 5. CUSTOM USER CONTENT
  // ============================================================================
  
  /// Create custom symbol
  static Future<String> createCustomSymbol({
    required String profileId,
    required String label,
    required String description,
    String? imagePath,
    String? categoryId,
    String? speechText,
    int? colorCode,
    List<String>? tags,
  }) async {
    try {
      final response = await _supabase
          .from('user_custom_symbols')
          .insert({
            'profile_id': profileId,
            'label': label,
            'description': description,
            'image_path': imagePath,
            'category_id': categoryId,
            'speech_text': speechText ?? label,
            'color_code': colorCode,
            'tags': tags ?? [],
          })
          .select()
          .single();
      
      final symbolId = response['id'];
      AACLogger.info('Created custom symbol: $label for profile $profileId', tag: _tag);
      return symbolId;
    } catch (e) {
      AACLogger.error('Error creating custom symbol: $e', tag: _tag);
      rethrow;
    }
  }
  
  /// Get user's custom symbols
  static Future<List<Map<String, dynamic>>> getCustomSymbols(String profileId) async {
    try {
      final response = await _supabase
          .from('user_custom_symbols')
          .select()
          .eq('profile_id', profileId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AACLogger.error('Error fetching custom symbols: $e', tag: _tag);
      return [];
    }
  }
  
  /// Create custom category
  static Future<String> createCustomCategory({
    required String profileId,
    required String name,
    String? description,
    String? iconPath,
    int? colorCode,
    int sortOrder = 0,
    String? parentCategoryId,
  }) async {
    try {
      final response = await _supabase
          .from('user_custom_categories')
          .insert({
            'profile_id': profileId,
            'name': name,
            'description': description,
            'icon_path': iconPath,
            'color_code': colorCode,
            'sort_order': sortOrder,
            'parent_category_id': parentCategoryId,
          })
          .select()
          .single();
      
      final categoryId = response['id'];
      AACLogger.info('Created custom category: $name for profile $profileId', tag: _tag);
      return categoryId;
    } catch (e) {
      AACLogger.error('Error creating custom category: $e', tag: _tag);
      rethrow;
    }
  }
  
  /// Get user's custom categories
  static Future<List<Map<String, dynamic>>> getCustomCategories(String profileId) async {
    try {
      final response = await _supabase
          .from('user_custom_categories')
          .select()
          .eq('profile_id', profileId)
          .order('sort_order')
          .order('name');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AACLogger.error('Error fetching custom categories: $e', tag: _tag);
      return [];
    }
  }
  
  // ============================================================================
  // 6. USER SETTINGS MANAGEMENT
  // ============================================================================
  
  /// Save user setting
  static Future<void> saveSetting({
    required String profileId,
    required String settingGroup,
    required String settingKey,
    required dynamic settingValue,
    bool isLocked = false,
  }) async {
    try {
      await _supabase.from('user_settings').upsert({
        'profile_id': profileId,
        'setting_group': settingGroup,
        'setting_key': settingKey,
        'setting_value': settingValue,
        'is_locked': isLocked,
      });
    } catch (e) {
      AACLogger.error('Error saving setting: $e', tag: _tag);
      rethrow;
    }
  }
  
  /// Get user settings
  static Future<Map<String, dynamic>> getUserSettings(String profileId, {String? settingGroup}) async {
    try {
      var query = _supabase
          .from('user_settings')
          .select()
          .eq('profile_id', profileId);
      
      if (settingGroup != null) {
        query = query.eq('setting_group', settingGroup);
      }
      
      final response = await query;
      
      final settings = <String, dynamic>{};
      for (final setting in response) {
        final group = setting['setting_group'];
        final key = setting['setting_key'];
        final value = setting['setting_value'];
        
        if (!settings.containsKey(group)) {
          settings[group] = <String, dynamic>{};
        }
        settings[group][key] = value;
      }
      
      return settings;
    } catch (e) {
      AACLogger.error('Error fetching settings: $e', tag: _tag);
      return {};
    }
  }
  
  // ============================================================================
  // 7. PROFILE VERSIONING & BACKUP
  // ============================================================================
  
  /// Create profile backup version
  static Future<void> createProfileVersion({
    required String profileId,
    required Map<String, dynamic> profileData,
    String? changeDescription,
  }) async {
    try {
      // Get current version number
      final lastVersion = await _supabase
          .from('user_profile_versions')
          .select('version_number')
          .eq('profile_id', profileId)
          .order('version_number', ascending: false)
          .limit(1);
      
      final nextVersion = lastVersion.isEmpty ? 1 : (lastVersion.first['version_number'] + 1);
      
      await _supabase.from('user_profile_versions').insert({
        'profile_id': profileId,
        'version_number': nextVersion,
        'profile_data': profileData,
        'change_description': changeDescription,
        'created_by': currentUserId,
      });
      
      AACLogger.info('Created profile version $nextVersion for $profileId', tag: _tag);
    } catch (e) {
      AACLogger.error('Error creating profile version: $e', tag: _tag);
      rethrow;
    }
  }
  
  /// Get profile versions
  static Future<List<Map<String, dynamic>>> getProfileVersions(String profileId) async {
    try {
      final response = await _supabase
          .from('user_profile_versions')
          .select()
          .eq('profile_id', profileId)
          .order('version_number', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AACLogger.error('Error fetching profile versions: $e', tag: _tag);
      return [];
    }
  }
  
  // ============================================================================
  // 8. REAL-TIME SUBSCRIPTIONS
  // ============================================================================
  
  /// Subscribe to profile changes
  static Stream<List<Map<String, dynamic>>> subscribeToProfileChanges() {
    final userId = currentUserId;
    if (userId == null) return Stream.empty();
    
    return _supabase
        .from('user_profiles')
        .stream(primaryKey: ['id'])
        .eq('supabase_uid', userId);
  }
  
  /// Subscribe to favorites changes for a profile
  static Stream<List<Map<String, dynamic>>> subscribeToFavorites(String profileId) {
    return _supabase
        .from('user_favorites')
        .stream(primaryKey: ['id'])
        .eq('profile_id', profileId)
        .order('favorite_order');
  }
  
  /// Subscribe to communication history for a profile
  static Stream<List<Map<String, dynamic>>> subscribeToCommunicationHistory(String profileId) {
    return _supabase
        .from('communication_history')
        .stream(primaryKey: ['id'])
        .eq('profile_id', profileId)
        .order('created_at', ascending: false)
        .limit(50);
  }
  
  // ============================================================================
  // 9. BULK OPERATIONS & SYNC
  // ============================================================================
  
  /// Sync all user data (for initial login or data recovery)
  static Future<Map<String, dynamic>> syncAllUserData(String profileId) async {
    try {
      final results = await Future.wait([
        getFavorites(profileId),
        getCommunicationHistory(profileId),
        getCustomSymbols(profileId),
        getCustomCategories(profileId),
        getUserSettings(profileId),
        getUsageAnalytics(profileId),
      ]);
      
      return {
        'favorites': results[0],
        'communication_history': results[1],
        'custom_symbols': results[2],
        'custom_categories': results[3],
        'settings': results[4],
        'analytics': results[5],
        'synced_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      AACLogger.error('Error syncing user data: $e', tag: _tag);
      return {};
    }
  }
  
  /// Clear all data for a profile (for profile deletion)
  static Future<void> clearProfileData(String profileId) async {
    try {
      await Future.wait([
        _supabase.from('user_favorites').delete().eq('profile_id', profileId),
        _supabase.from('symbol_usage_history').delete().eq('profile_id', profileId),
        _supabase.from('communication_history').delete().eq('profile_id', profileId),
        _supabase.from('user_custom_symbols').delete().eq('profile_id', profileId),
        _supabase.from('user_custom_categories').delete().eq('profile_id', profileId),
        _supabase.from('user_settings').delete().eq('profile_id', profileId),
        _supabase.from('user_profiles').delete().eq('id', profileId),
      ]);
      
      AACLogger.info('Cleared all data for profile $profileId', tag: _tag);
    } catch (e) {
      AACLogger.error('Error clearing profile data: $e', tag: _tag);
      rethrow;
    }
  }
}