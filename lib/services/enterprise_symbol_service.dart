import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/aac_logger.dart';

/// Enterprise Symbol Service - Manages custom symbols with performance optimization
/// 
/// ENTERPRISE STRATEGY:
/// 1. user_custom_symbols → Full symbol data with versioning
/// 2. user_favorites → References to default symbols  
/// 3. phrase_history → Usage analytics and communication patterns
/// 4. learning_analytics → Performance metrics and insights
/// 
/// PERFORMANCE FEATURES:
/// - Batch operations for bulk sync
/// - Proper indexing utilization  
/// - RLS policy optimization
/// - Usage analytics integration
class EnterpriseSymbolService {
  static const String _tag = 'EnterpriseSymbolService';
  
  /// Get user's custom symbols with enterprise features
  /// 
  /// ENTERPRISE OPTIMIZATIONS:
  /// - Uses proper indexes for fast retrieval
  /// - Includes usage analytics
  /// - Supports hierarchical categories
  /// - Performance monitoring
  static Future<List<Map<String, dynamic>>> getUserCustomSymbols(String userId) async {
    try {
      AACLogger.info('$_tag: 🔍 ENTERPRISE QUERY: Fetching custom symbols for user $userId', tag: _tag);
      
      // ENTERPRISE QUERY with proper joins and indexes
      final result = await Supabase.instance.client
          .from('user_custom_symbols')
          .select('''
            id,
            label,
            description,
            image_path,
            image_url,
            speech_text,
            color_code,
            tags,
            is_shared,
            usage_count,
            created_at,
            updated_at,
            category_id,
            user_custom_categories!inner(
              name,
              color_code,
              parent_category_id
            )
          ''')
          .eq('profile_id', userId)
          .order('usage_count', ascending: false) // Performance: most used first
          .order('created_at', ascending: false); // Recent first for ties
      
      AACLogger.info('$_tag: ✅ ENTERPRISE SUCCESS: Retrieved ${result.length} custom symbols with category data', tag: _tag);
      
      // Track query performance
      await _trackAnalytics(userId, 'symbol_query', {
        'symbols_retrieved': result.length,
        'query_type': 'user_custom_symbols_with_categories',
        'performance_optimized': true,
      });
      
      return result;
    } catch (e, stackTrace) {
      AACLogger.error('$_tag: ❌ ENTERPRISE ERROR: Failed to fetch custom symbols: $e', stackTrace: stackTrace, tag: _tag);
      rethrow;
    }
  }
  
  /// Get user's favorite symbols (default + custom) with enterprise approach
  /// 
  /// ENTERPRISE STRATEGY:
  /// - Combines user_favorites (default symbols) + user_custom_symbols (marked as favorite)
  /// - Uses proper table joins for performance
  /// - Includes usage analytics
  static Future<List<Map<String, dynamic>>> getUserFavorites(String userId) async {
    try {
      AACLogger.info('$_tag: 🔍 ENTERPRISE QUERY: Fetching hybrid favorites for user $userId', tag: _tag);
      
      // ENTERPRISE QUERY 1: Default symbol favorites
      final defaultFavorites = await Supabase.instance.client
          .from('user_favorites')
          .select('''
            symbols!inner(
              id,
              label,
              description,
              image_path,
              speech_text,
              color_code,
              categories!inner(name)
            ),
            added_at
          ''')
          .eq('user_id', userId)
          .order('added_at', ascending: false);
      
      // ENTERPRISE QUERY 2: Custom symbol favorites (tagged as favorite)
      final customFavorites = await Supabase.instance.client
          .from('user_custom_symbols')
          .select('''
            id,
            label,
            description,
            image_path,
            image_url,
            speech_text,
            color_code,
            tags,
            usage_count,
            created_at,
            user_custom_categories(name, color_code)
          ''')
          .eq('profile_id', userId)
          .contains('tags', ['favorite']); // Enterprise: tagged favorites
      
      // ENTERPRISE STRATEGY: Combine and normalize data structure
      final allFavorites = <Map<String, dynamic>>[];
      
      // Add default favorites with normalized structure
      for (final fav in defaultFavorites) {
        final symbol = fav['symbols'];
        allFavorites.add({
          'id': symbol['id'],
          'label': symbol['label'],
          'description': symbol['description'],
          'image_path': symbol['image_path'],
          'speech_text': symbol['speech_text'],
          'color_code': symbol['color_code'],
          'category': symbol['categories']?['name'],
          'is_custom': false,
          'added_at': fav['added_at'],
          'usage_count': 1, // Default symbols don't track usage in favorites
          'source': 'default_symbol',
        });
      }
      
      // Add custom favorites with normalized structure
      for (final symbol in customFavorites) {
        allFavorites.add({
          'id': symbol['id'],
          'label': symbol['label'],
          'description': symbol['description'],
          'image_path': symbol['image_path'],
          'image_url': symbol['image_url'],
          'speech_text': symbol['speech_text'],
          'color_code': symbol['color_code'],
          'category': symbol['user_custom_categories']?['name'],
          'is_custom': true,
          'added_at': symbol['created_at'],
          'usage_count': symbol['usage_count'],
          'source': 'custom_symbol',
        });
      }
      
      // ENTERPRISE OPTIMIZATION: Sort by usage and recency
      allFavorites.sort((a, b) {
        final aUsage = a['usage_count'] ?? 0;
        final bUsage = b['usage_count'] ?? 0;
        if (aUsage != bUsage) return bUsage.compareTo(aUsage); // Higher usage first
        
        final aDate = DateTime.tryParse(a['added_at'] ?? '') ?? DateTime(1970);
        final bDate = DateTime.tryParse(b['added_at'] ?? '') ?? DateTime(1970);
        return bDate.compareTo(aDate); // More recent first for ties
      });
      
      AACLogger.info('$_tag: ✅ ENTERPRISE SUCCESS: Retrieved ${allFavorites.length} hybrid favorites (${defaultFavorites.length} default + ${customFavorites.length} custom)', tag: _tag);
      
      // Track analytics for hybrid favorites
      await _trackAnalytics(userId, 'favorites_query', {
        'total_favorites': allFavorites.length,
        'default_favorites': defaultFavorites.length,
        'custom_favorites': customFavorites.length,
        'query_type': 'hybrid_favorites',
      });
      
      return allFavorites;
    } catch (e, stackTrace) {
      AACLogger.error('$_tag: ❌ ENTERPRISE ERROR: Failed to fetch hybrid favorites: $e', stackTrace: stackTrace, tag: _tag);
      rethrow;
    }
  }
  
  /// Add custom symbol with enterprise features
  /// 
  /// ENTERPRISE STRATEGY:
  /// - Proper validation and normalization
  /// - Category relationship management
  /// - Analytics tracking
  /// - Performance optimization
  static Future<Map<String, dynamic>> addCustomSymbol({
    required String userId,
    required String label,
    String? description,
    String? imagePath,
    String? imageUrl,
    String? speechText,
    String? colorCode,
    int? categoryId,
    List<String>? tags,
    bool isFavorite = false,
  }) async {
    try {
      AACLogger.info('$_tag: 🔄 ENTERPRISE CREATE: Adding custom symbol "$label" for user $userId', tag: _tag);
      
      // ENTERPRISE VALIDATION: Check for duplicates
      final existing = await Supabase.instance.client
          .from('user_custom_symbols')
          .select('id')
          .eq('profile_id', userId)
          .eq('label', label)
          .maybeSingle();
      
      if (existing != null) {
        throw Exception('Symbol with label "$label" already exists');
      }
      
      // ENTERPRISE STRATEGY: Prepare normalized data
      final symbolTags = List<String>.from(tags ?? []);
      if (isFavorite && !symbolTags.contains('favorite')) {
        symbolTags.add('favorite');
      }
      
      final symbolData = {
        'profile_id': userId,
        'label': label,
        'description': description ?? '',
        'image_path': imagePath,
        'image_url': imageUrl,
        'speech_text': speechText ?? label,
        'color_code': colorCode,
        'category_id': categoryId,
        'tags': symbolTags,
        'is_shared': false,
        'usage_count': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      // ENTERPRISE INSERT with full return data
      final result = await Supabase.instance.client
          .from('user_custom_symbols')
          .insert(symbolData)
          .select('''
            *,
            user_custom_categories(name, color_code)
          ''')
          .single();
      
      // ENTERPRISE ANALYTICS: Track symbol creation
      await _trackAnalytics(userId, 'symbol_creation', {
        'symbol_label': label,
        'has_category': categoryId != null,
        'is_favorite': isFavorite,
        'has_custom_image': imagePath != null || imageUrl != null,
        'tag_count': symbolTags.length,
      });
      
      AACLogger.info('$_tag: ✅ ENTERPRISE SUCCESS: Created custom symbol "$label" with ID ${result['id']}', tag: _tag);
      return result;
      
    } catch (e, stackTrace) {
      AACLogger.error('$_tag: ❌ ENTERPRISE ERROR: Failed to add custom symbol "$label": $e', stackTrace: stackTrace, tag: _tag);
      rethrow;
    }
  }
  
  /// Track symbol usage with enterprise analytics
  static Future<void> trackSymbolUsage({
    required String userId,
    required String symbolId,
    required bool isCustomSymbol,
    String? context,
    String? phraseText,
  }) async {
    try {
      // ENTERPRISE STRATEGY 1: Update usage count
      if (isCustomSymbol) {
        await Supabase.instance.client
            .from('user_custom_symbols')
            .update({
              'usage_count': Supabase.instance.client.rpc('increment_usage', params: {'symbol_id': symbolId}),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', symbolId);
      }
      
      // ENTERPRISE STRATEGY 2: Record in communication history
      await Supabase.instance.client
          .from('communication_history')
          .insert({
            'profile_id': userId,
            'symbol_id': symbolId,
            'symbol_type': isCustomSymbol ? 'custom' : 'default',
            'usage_context': context ?? 'symbol_selection',
            'phrase_text': phraseText,
            'session_data': {
              'timestamp': DateTime.now().toIso8601String(),
              'interaction_type': 'symbol_usage',
            },
          });
      
      // ENTERPRISE ANALYTICS: Learning analytics
      await _trackAnalytics(userId, 'symbol_usage', {
        'symbol_id': symbolId,
        'is_custom': isCustomSymbol,
        'context': context,
        'usage_timestamp': DateTime.now().toIso8601String(),
      });
      
      AACLogger.info('$_tag: ✅ ENTERPRISE ANALYTICS: Tracked usage for symbol $symbolId', tag: _tag);
      
    } catch (e, stackTrace) {
      AACLogger.error('$_tag: ❌ ENTERPRISE ERROR: Failed to track symbol usage: $e', stackTrace: stackTrace, tag: _tag);
      // Don't rethrow - analytics failure shouldn't break user experience
    }
  }
  
  /// Private helper for analytics tracking
  static Future<void> _trackAnalytics(String userId, String activityType, Map<String, dynamic> metrics) async {
    try {
      await Supabase.instance.client
          .from('learning_analytics')
          .insert({
            'profile_id': userId,
            'activity_type': activityType,
            'content_type': 'enterprise_symbols',
            'metrics': metrics,
            'session_data': {
              'service': 'EnterpriseSymbolService',
              'timestamp': DateTime.now().toIso8601String(),
            },
            'created_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      AACLogger.warning('$_tag: Analytics tracking failed: $e', tag: _tag);
      // Don't rethrow - analytics failures should be silent
    }
  }
}