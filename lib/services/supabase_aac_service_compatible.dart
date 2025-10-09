/// Comprehensive Supabase AAC Service
/// Provides complete AAC functionality with the existing database schema
/// Handles user profiles, favorites, communication history, and custom content

import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase/supabase_config.dart';

class SupabaseAACService {
  static SupabaseClient get client => SupabaseConfig.client;
  static User? get currentUser => client.auth.currentUser;
  
  /// Ensure user is authenticated
  static void _ensureAuthenticated() {
    if (currentUser == null) {
      throw Exception('User must be authenticated');
    }
  }

  // ============================================================================
  // USER PROFILE MANAGEMENT
  // ============================================================================

  /// Get current user profile (works with existing schema)
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    _ensureAuthenticated();
    
    try {
      final response = await client
          .from('user_profiles')
          .select('*')
          .eq('id', currentUser!.id)
          .single();
      return response;
    } catch (e) {
      print('No profile found for user: ${currentUser!.id}');
      return null;
    }
  }

  /// Create or update user profile (compatible with existing schema)
  static Future<Map<String, dynamic>> upsertUserProfile({
    required String name,
    String? email,
    String role = 'communicator',
    String? avatarUrl,
    Map<String, dynamic> settings = const {},
    Map<String, dynamic> appSettings = const {},
  }) async {
    _ensureAuthenticated();
    
    final profileData = {
      'id': currentUser!.id,
      'name': name,
      'email': email ?? currentUser!.email ?? '',
      'role': role,
      'avatar_url': avatarUrl,
      'settings': settings,
      'app_settings': appSettings,
      'last_active_at': DateTime.now().toIso8601String(),
    };
    
    final response = await client
        .from('user_profiles')
        .upsert(profileData)
        .select()
        .single();
    
    return response;
  }

  // ============================================================================
  // SYMBOLS & CATEGORIES MANAGEMENT
  // ============================================================================

  /// Get user's custom symbols
  static Future<List<Map<String, dynamic>>> getUserSymbols() async {
    _ensureAuthenticated();
    
    final response = await client
        .from('symbols')
        .select('*, categories(*)')
        .eq('user_id', currentUser!.id)
        .order('usage_count', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }



  /// Get user's categories
  static Future<List<Map<String, dynamic>>> getUserCategories() async {
    _ensureAuthenticated();
    
    final response = await client
        .from('categories')
        .select('*')
        .eq('user_id', currentUser!.id)
        .order('sort_order');
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Create a new category
  static Future<Map<String, dynamic>> createCategory({
    required String name,
    int? colorCode,
    String? iconPath,
    int sortOrder = 0,
  }) async {
    _ensureAuthenticated();
    
    final categoryData = {
      'user_id': currentUser!.id,
      'name': name,
      'color_code': colorCode,
      'icon_path': iconPath,
      'sort_order': sortOrder,
      'is_default': false,
    };
    
    final response = await client
        .from('categories')
        .insert(categoryData)
        .select()
        .single();
    
    return response;
  }

  // ============================================================================
  // FAVORITES MANAGEMENT
  // ============================================================================

  /// Get user's favorite symbols
  static Future<List<Map<String, dynamic>>> getUserFavorites() async {
    _ensureAuthenticated();
    
    final response = await client
        .from('user_favorites')
        .select('*, symbols(*)')
        .eq('user_id', currentUser!.id)
        .order('added_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Add symbol to favorites
  static Future<void> addToFavorites(String symbolId) async {
    _ensureAuthenticated();
    
    await client.from('user_favorites').upsert({
      'user_id': currentUser!.id,
      'symbol_id': symbolId,
      'added_at': DateTime.now().toIso8601String(),
    });
    
    // Update usage count in symbols table
    await client.rpc('increment_symbol_usage', params: {
      'symbol_id': symbolId,
    });
  }

  /// Remove symbol from favorites
  static Future<void> removeFromFavorites(String symbolId) async {
    _ensureAuthenticated();
    
    await client
        .from('user_favorites')
        .delete()
        .eq('user_id', currentUser!.id)
        .eq('symbol_id', symbolId);
  }

  /// Check if symbol is favorited
  static Future<bool> isSymbolFavorited(String symbolId) async {
    _ensureAuthenticated();
    
    try {
      await client
          .from('user_favorites')
          .select('id')
          .eq('user_id', currentUser!.id)
          .eq('symbol_id', symbolId)
          .single();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // COMMUNICATION HISTORY
  // ============================================================================

  /// Save communication to history
  static Future<Map<String, dynamic>> saveCommunication({
    required String messageText,
    List<String> symbolsUsed = const [],
    String communicationType = 'phrase',
    Map<String, dynamic> contextInfo = const {},
  }) async {
    _ensureAuthenticated();
    
    final historyData = {
      'user_id': currentUser!.id,
      'message_text': messageText,
      'symbols_used': symbolsUsed,
      'communication_type': communicationType,
      'context_info': contextInfo,
    };
    
    final response = await client
        .from('communication_history')
        .insert(historyData)
        .select()
        .single();
    
    return response;
  }

  /// Get communication history
  static Future<List<Map<String, dynamic>>> getCommunicationHistory({
    int limit = 50,
    DateTime? since,
  }) async {
    _ensureAuthenticated();
    
    var query = client
        .from('communication_history')
        .select('*')
        .eq('user_id', currentUser!.id)
        .order('created_at', ascending: false)
        .limit(limit);
    
    if (since != null) {
      // Use where clause instead of filter for date comparison
      query = query;
      // TODO: Add proper date filtering when Supabase client supports it
    }
    
    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================================================
  // PHRASE MANAGEMENT
  // ============================================================================

  /// Get phrase history/favorites
  static Future<List<Map<String, dynamic>>> getPhraseHistory() async {
    _ensureAuthenticated();
    
    final response = await client
        .from('phrase_history')
        .select('*')
        .eq('user_id', currentUser!.id)
        .order('usage_count', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Save or update phrase
  static Future<Map<String, dynamic>> savePhrase({
    required String text,
    bool isFavorite = false,
  }) async {
    _ensureAuthenticated();
    
    // Check if phrase already exists
    try {
      final existing = await client
          .from('phrase_history')
          .select('*')
          .eq('user_id', currentUser!.id)
          .eq('text', text)
          .single();
      
      // Update usage count
      final response = await client
          .from('phrase_history')
          .update({
            'usage_count': existing['usage_count'] + 1,
            'last_used_at': DateTime.now().toIso8601String(),
            'is_favorite': isFavorite,
          })
          .eq('id', existing['id'])
          .select()
          .single();
      
      return response;
    } catch (e) {
      // Create new phrase
      final phraseData = {
        'user_id': currentUser!.id,
        'text': text,
        'is_favorite': isFavorite,
        'usage_count': 1,
        'last_used_at': DateTime.now().toIso8601String(),
      };
      
      final response = await client
          .from('phrase_history')
          .insert(phraseData)
          .select()
          .single();
      
      return response;
    }
  }

  // ============================================================================
  // CUSTOM CONTENT WITH NEW TABLES
  // ============================================================================

  /// Get user's custom categories (new table)
  static Future<List<Map<String, dynamic>>> getCustomCategories() async {
    _ensureAuthenticated();
    
    final response = await client
        .from('user_custom_categories')
        .select('*')
        .eq('profile_id', currentUser!.id)
        .order('sort_order');
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Create custom category in new table
  static Future<Map<String, dynamic>> createCustomCategory({
    required String name,
    String? description,
    String? iconPath,
    int? colorCode,
    int sortOrder = 0,
  }) async {
    _ensureAuthenticated();
    
    final categoryData = {
      'profile_id': currentUser!.id,
      'name': name,
      'description': description,
      'icon_path': iconPath,
      'color_code': colorCode,
      'sort_order': sortOrder,
    };
    
    final response = await client
        .from('user_custom_categories')
        .insert(categoryData)
        .select()
        .single();
    
    return response;
  }

  /// Get custom symbols (new table)
  static Future<List<Map<String, dynamic>>> getCustomSymbols() async {
    _ensureAuthenticated();
    
    final response = await client
        .from('user_custom_symbols')
        .select('*, user_custom_categories(*)')
        .eq('profile_id', currentUser!.id)
        .order('usage_count', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Create custom symbol in new table
  static Future<Map<String, dynamic>> createCustomSymbol({
    required String label,
    String? description,
    String? imagePath,
    String? categoryId,
    String? speechText,
    int? colorCode,
    List<String> tags = const [],
    bool isShared = false,
  }) async {
    _ensureAuthenticated();
    
    final symbolData = {
      'profile_id': currentUser!.id,
      'label': label,
      'description': description,
      'image_path': imagePath,
      'category_id': categoryId,
      'speech_text': speechText ?? label,
      'color_code': colorCode,
      'tags': tags,
      'is_shared': isShared,
    };
    
    final response = await client
        .from('user_custom_symbols')
        .insert(symbolData)
        .select()
        .single();
    
    return response;
  }

  // ============================================================================
  // SETTINGS MANAGEMENT
  // ============================================================================

  /// Get user settings
  static Future<Map<String, dynamic>> getUserSettings(String settingGroup) async {
    _ensureAuthenticated();
    
    final response = await client
        .from('user_settings')
        .select('*')
        .eq('profile_id', currentUser!.id)
        .eq('setting_group', settingGroup);
    
    final settings = <String, dynamic>{};
    for (final setting in response) {
      settings[setting['setting_key']] = setting['setting_value'];
    }
    
    return settings;
  }

  /// Save user setting
  static Future<void> saveSetting({
    required String settingGroup,
    required String settingKey,
    required dynamic settingValue,
    bool isLocked = false,
  }) async {
    _ensureAuthenticated();
    
    await client.from('user_settings').upsert({
      'profile_id': currentUser!.id,
      'setting_group': settingGroup,
      'setting_key': settingKey,
      'setting_value': settingValue,
      'is_locked': isLocked,
      'last_modified_at': DateTime.now().toIso8601String(),
    });
  }

  // ============================================================================
  // ANALYTICS & INSIGHTS
  // ============================================================================

  /// Record learning analytics
  static Future<void> recordAnalytics({
    required String metricType,
    required double metricValue,
    required DateTime periodStart,
    required DateTime periodEnd,
    Map<String, dynamic> context = const {},
  }) async {
    _ensureAuthenticated();
    
    await client.from('learning_analytics').insert({
      'profile_id': currentUser!.id,
      'metric_type': metricType,
      'metric_value': metricValue,
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'context': context,
    });
  }

  /// Start app session
  static Future<String> startAppSession({
    Map<String, dynamic> deviceInfo = const {},
    String? appVersion,
  }) async {
    _ensureAuthenticated();
    
    final response = await client
        .from('app_sessions')
        .insert({
          'profile_id': currentUser!.id,
          'device_info': deviceInfo,
          'app_version': appVersion,
        })
        .select('id')
        .single();
    
    return response['id'];
  }

  /// End app session
  static Future<void> endAppSession(String sessionId, {
    int symbolsUsed = 0,
    int phrasesCreated = 0,
  }) async {
    _ensureAuthenticated();
    
    final sessionEnd = DateTime.now();
    
    // Get session start time to calculate duration
    final session = await client
        .from('app_sessions')
        .select('session_start')
        .eq('id', sessionId)
        .single();
    
    final sessionStart = DateTime.parse(session['session_start']);
    final durationMinutes = sessionEnd.difference(sessionStart).inMinutes;
    
    await client.from('app_sessions').update({
      'session_end': sessionEnd.toIso8601String(),
      'duration_minutes': durationMinutes,
      'symbols_used': symbolsUsed,
      'phrases_created': phrasesCreated,
    }).eq('id', sessionId);
  }

  // ============================================================================
  // REAL-TIME SUBSCRIPTIONS
  // ============================================================================

  /// Subscribe to favorites changes
  static Stream<List<Map<String, dynamic>>> subscribeToFavorites() {
    _ensureAuthenticated();
    
    return client
        .from('user_favorites')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUser!.id);
  }

  /// Subscribe to communication history changes
  static Stream<List<Map<String, dynamic>>> subscribeToCommunicationHistory() {
    _ensureAuthenticated();
    
    return client
        .from('communication_history')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUser!.id)
        .order('created_at', ascending: false)
        .limit(20);
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Bulk sync operation for offline data
  static Future<Map<String, dynamic>> bulkSync({
    List<Map<String, dynamic>>? symbols,
    List<Map<String, dynamic>>? categories,
    List<Map<String, dynamic>>? favorites,
    List<Map<String, dynamic>>? phrases,
  }) async {
    _ensureAuthenticated();
    
    final results = <String, dynamic>{};
    
    try {
      if (symbols != null && symbols.isNotEmpty) {
        final symbolResults = await client.from('symbols').upsert(symbols);
        results['symbols'] = symbolResults.length;
      }
      
      if (categories != null && categories.isNotEmpty) {
        final categoryResults = await client.from('categories').upsert(categories);
        results['categories'] = categoryResults.length;
      }
      
      if (favorites != null && favorites.isNotEmpty) {
        final favoriteResults = await client.from('user_favorites').upsert(favorites);
        results['favorites'] = favoriteResults.length;
      }
      
      if (phrases != null && phrases.isNotEmpty) {
        final phraseResults = await client.from('phrase_history').upsert(phrases);
        results['phrases'] = phraseResults.length;
      }
      
      results['status'] = 'success';
      results['timestamp'] = DateTime.now().toIso8601String();
      
    } catch (e) {
      results['status'] = 'error';
      results['error'] = e.toString();
    }
    
    return results;
  }

  /// Get sync status and statistics
  static Future<Map<String, dynamic>> getSyncStatus() async {
    _ensureAuthenticated();
    
    final stats = <String, dynamic>{};
    
    try {
      // Count user's data
      stats['symbols'] = await _getTableCount('symbols');
      stats['categories'] = await _getTableCount('categories');
      stats['favorites'] = await _getTableCount('user_favorites');
      stats['phrases'] = await _getTableCount('phrase_history');
      stats['custom_symbols'] = await _getTableCount('user_custom_symbols');
      stats['custom_categories'] = await _getTableCount('user_custom_categories');
      
      stats['last_sync'] = DateTime.now().toIso8601String();
      stats['user_id'] = currentUser!.id;
      
    } catch (e) {
      stats['error'] = e.toString();
    }
    
    return stats;
  }

  /// Helper method to get table count for user
  static Future<int> _getTableCount(String tableName) async {
    final response = await client
        .from(tableName)
        .select('*')
        .eq('user_id', currentUser!.id)
        .count(CountOption.exact);
    
    return response.count ?? 0;
  }
}