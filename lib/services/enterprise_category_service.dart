import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/aac_logger.dart';

/// Enterprise Category Service - Manages categories with hierarchical structure
/// 
/// ENTERPRISE STRATEGY:
/// 1. user_custom_categories → Hierarchical custom categories
/// 2. global_default_categories → System categories
/// 3. learning_analytics → Usage patterns and optimization insights
/// 
/// PERFORMANCE FEATURES:
/// - Hierarchical relationships with parent/child
/// - Batch operations for performance
/// - Usage analytics and optimization
/// - RLS policy compliance
class EnterpriseCategoryService {
  static const String _tag = 'EnterpriseCategoryService';
  
  /// Get user's categories with hierarchical structure
  /// 
  /// ENTERPRISE OPTIMIZATIONS:
  /// - Hierarchical tree structure
  /// - Usage analytics integration  
  /// - Performance optimized queries
  /// - Symbol count aggregation
  static Future<List<Map<String, dynamic>>> getUserCategories(String userId) async {
    try {
      AACLogger.info('$_tag: 🔍 ENTERPRISE QUERY: Fetching hierarchical categories for user $userId', tag: _tag);
      
      // ENTERPRISE QUERY 1: Get all user categories with hierarchy
      final customCategories = await Supabase.instance.client
          .from('user_custom_categories')
          .select('''
            id,
            name,
            description,
            color_code,
            icon_path,
            parent_category_id,
            sort_order,
            is_shared,
            symbols_count,
            usage_frequency,
            tags,
            metadata,
            created_at,
            updated_at
          ''')
          .eq('profile_id', userId)
          .order('parent_category_id', ascending: true) // Parents first
          .order('sort_order', ascending: true)
          .order('usage_frequency', ascending: false); // Most used first
      
      // ENTERPRISE QUERY 2: Get symbol counts for each category
      final symbolCounts = await _getCategorySymbolCounts(userId, customCategories);
      
      // ENTERPRISE STRATEGY: Build hierarchical structure
      final categoryMap = <int, Map<String, dynamic>>{};
      final rootCategories = <Map<String, dynamic>>[];
      
      // First pass: Create category objects and map
      for (final category in customCategories) {
        final enrichedCategory = {
          ...category,
          'actual_symbols_count': symbolCounts[category['id']] ?? 0,
          'children': <Map<String, dynamic>>[],
          'level': 0, // Will be calculated
          'path': <String>[category['name']], // Full hierarchy path
        };
        
        categoryMap[category['id']] = enrichedCategory;
        
        if (category['parent_category_id'] == null) {
          rootCategories.add(enrichedCategory);
        }
      }
      
      // Second pass: Build hierarchy and calculate levels
      for (final category in customCategories) {
        if (category['parent_category_id'] != null) {
          final parentId = category['parent_category_id'] as int;
          final parent = categoryMap[parentId];
          final child = categoryMap[category['id']];
          
          if (parent != null && child != null) {
            parent['children'].add(child);
            child['level'] = (parent['level'] as int) + 1;
            child['path'] = [
              ...List<String>.from(parent['path']),
              category['name']
            ];
          }
        }
      }
      
      // ENTERPRISE OPTIMIZATION: Sort by usage and hierarchy
      _sortCategoriesHierarchically(rootCategories);
      
      AACLogger.info('$_tag: ✅ ENTERPRISE SUCCESS: Retrieved ${customCategories.length} categories (${rootCategories.length} root) with hierarchy', tag: _tag);
      
      // Track analytics for category query
      await _trackAnalytics(userId, 'category_query', {
        'total_categories': customCategories.length,
        'root_categories': rootCategories.length,
        'hierarchical_levels': _calculateMaxLevel(rootCategories),
        'query_type': 'hierarchical_categories_with_counts',
      });
      
      return rootCategories;
    } catch (e, stackTrace) {
      AACLogger.error('$_tag: ❌ ENTERPRISE ERROR: Failed to fetch categories: $e', stackTrace: stackTrace, tag: _tag);
      rethrow;
    }
  }
  
  /// Create custom category with enterprise features
  /// 
  /// ENTERPRISE STRATEGY:
  /// - Hierarchical validation
  /// - Duplicate prevention
  /// - Analytics tracking
  /// - Performance optimization
  static Future<Map<String, dynamic>> createCustomCategory({
    required String userId,
    required String name,
    String? description,
    String? colorCode,
    String? iconPath,
    int? parentCategoryId,
    int sortOrder = 0,
    bool isShared = false,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      AACLogger.info('$_tag: 🔄 ENTERPRISE CREATE: Adding category "$name" for user $userId', tag: _tag);
      
      // ENTERPRISE VALIDATION 1: Check for duplicates within same parent
      final duplicateCheck = await Supabase.instance.client
          .from('user_custom_categories')
          .select('id')
          .eq('profile_id', userId)
          .eq('name', name);
      
      if (parentCategoryId != null) {
        duplicateCheck.eq('parent_category_id', parentCategoryId);
      } else {
        duplicateCheck.is_('parent_category_id', null);
      }
      
      final existing = await duplicateCheck.maybeSingle();
      if (existing != null) {
        throw Exception('Category "$name" already exists in this location');
      }
      
      // ENTERPRISE VALIDATION 2: Validate parent exists
      if (parentCategoryId != null) {
        final parentExists = await Supabase.instance.client
            .from('user_custom_categories')
            .select('id')
            .eq('id', parentCategoryId)
            .eq('profile_id', userId)
            .maybeSingle();
        
        if (parentExists == null) {
          throw Exception('Parent category not found or not accessible');
        }
      }
      
      // ENTERPRISE STRATEGY: Prepare category data
      final categoryData = {
        'profile_id': userId,
        'name': name,
        'description': description ?? '',
        'color_code': colorCode,
        'icon_path': iconPath,
        'parent_category_id': parentCategoryId,
        'sort_order': sortOrder,
        'is_shared': isShared,
        'symbols_count': 0, // Initialize to 0
        'usage_frequency': 0,
        'tags': tags ?? <String>[],
        'metadata': {
          'creation_source': 'enterprise_service',
          'created_by': userId,
          'version': 1,
          ...?metadata,
        },
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      // ENTERPRISE INSERT with full return data
      final result = await Supabase.instance.client
          .from('user_custom_categories')
          .insert(categoryData)
          .select('''
            *,
            user_custom_categories!parent_category_id(name, color_code)
          ''')
          .single();
      
      // ENTERPRISE ANALYTICS: Track category creation
      await _trackAnalytics(userId, 'category_creation', {
        'category_name': name,
        'has_parent': parentCategoryId != null,
        'parent_id': parentCategoryId,
        'is_shared': isShared,
        'has_custom_icon': iconPath != null,
        'tag_count': (tags?.length ?? 0),
      });
      
      AACLogger.info('$_tag: ✅ ENTERPRISE SUCCESS: Created category "$name" with ID ${result['id']}', tag: _tag);
      return result;
      
    } catch (e, stackTrace) {
      AACLogger.error('$_tag: ❌ ENTERPRISE ERROR: Failed to create category "$name": $e', stackTrace: stackTrace, tag: _tag);
      rethrow;
    }
  }
  
  /// Update category usage frequency (enterprise analytics)
  static Future<void> trackCategoryUsage({
    required String userId,
    required int categoryId,
    String? context,
  }) async {
    try {
      // ENTERPRISE STRATEGY: Increment usage frequency
      await Supabase.instance.client
          .from('user_custom_categories')
          .update({
            'usage_frequency': Supabase.instance.client.rpc('increment_category_usage', params: {'category_id': categoryId}),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', categoryId)
          .eq('profile_id', userId);
      
      // ENTERPRISE ANALYTICS: Learning analytics
      await _trackAnalytics(userId, 'category_usage', {
        'category_id': categoryId,
        'context': context,
        'usage_timestamp': DateTime.now().toIso8601String(),
      });
      
      AACLogger.info('$_tag: ✅ ENTERPRISE ANALYTICS: Tracked usage for category $categoryId', tag: _tag);
      
    } catch (e, stackTrace) {
      AACLogger.error('$_tag: ❌ ENTERPRISE ERROR: Failed to track category usage: $e', stackTrace: stackTrace, tag: _tag);
      // Don't rethrow - analytics failure shouldn't break user experience
    }
  }
  
  /// Get category performance insights
  static Future<Map<String, dynamic>> getCategoryInsights(String userId) async {
    try {
      AACLogger.info('$_tag: 🔍 ENTERPRISE ANALYTICS: Generating category insights for user $userId', tag: _tag);
      
      // ENTERPRISE QUERY: Category analytics
      final categoryStats = await Supabase.instance.client
          .from('user_custom_categories')
          .select('id, name, usage_frequency, symbols_count, created_at')
          .eq('profile_id', userId);
      
      // ENTERPRISE ANALYTICS: Calculate insights
      final totalCategories = categoryStats.length;
      final totalUsage = categoryStats.fold<int>(0, (sum, cat) => sum + (cat['usage_frequency'] ?? 0));
      final avgUsage = totalCategories > 0 ? totalUsage / totalCategories : 0;
      
      final mostUsed = categoryStats.isEmpty ? null : 
          categoryStats.reduce((a, b) => (a['usage_frequency'] ?? 0) > (b['usage_frequency'] ?? 0) ? a : b);
      
      final insights = {
        'total_categories': totalCategories,
        'total_usage': totalUsage,
        'average_usage': avgUsage,
        'most_used_category': mostUsed,
        'categories_with_symbols': categoryStats.where((c) => (c['symbols_count'] ?? 0) > 0).length,
        'empty_categories': categoryStats.where((c) => (c['symbols_count'] ?? 0) == 0).length,
        'generated_at': DateTime.now().toIso8601String(),
      };
      
      // Track insights generation
      await _trackAnalytics(userId, 'category_insights', insights);
      
      AACLogger.info('$_tag: ✅ ENTERPRISE INSIGHTS: Generated performance analytics', tag: _tag);
      return insights;
      
    } catch (e, stackTrace) {
      AACLogger.error('$_tag: ❌ ENTERPRISE ERROR: Failed to generate insights: $e', stackTrace: stackTrace, tag: _tag);
      rethrow;
    }
  }
  
  /// Private helper: Get symbol counts for categories
  static Future<Map<int, int>> _getCategorySymbolCounts(String userId, List<Map<String, dynamic>> categories) async {
    final counts = <int, int>{};
    
    for (final category in categories) {
      try {
        final symbolCount = await Supabase.instance.client
            .from('user_custom_symbols')
            .select('id', count: CountOption.exact)
            .eq('profile_id', userId)
            .eq('category_id', category['id']);
        
        counts[category['id']] = symbolCount.count ?? 0;
      } catch (e) {
        AACLogger.warning('$_tag: Failed to get symbol count for category ${category['id']}: $e', tag: _tag);
        counts[category['id']] = 0;
      }
    }
    
    return counts;
  }
  
  /// Private helper: Sort categories hierarchically by usage
  static void _sortCategoriesHierarchically(List<Map<String, dynamic>> categories) {
    categories.sort((a, b) {
      final aUsage = a['usage_frequency'] ?? 0;
      final bUsage = b['usage_frequency'] ?? 0;
      if (aUsage != bUsage) return bUsage.compareTo(aUsage); // Higher usage first
      
      final aOrder = a['sort_order'] ?? 0;
      final bOrder = b['sort_order'] ?? 0;
      return aOrder.compareTo(bOrder); // Sort order for ties
    });
    
    // Recursively sort children
    for (final category in categories) {
      final children = List<Map<String, dynamic>>.from(category['children']);
      if (children.isNotEmpty) {
        _sortCategoriesHierarchically(children);
      }
    }
  }
  
  /// Private helper: Calculate maximum hierarchy level
  static int _calculateMaxLevel(List<Map<String, dynamic>> categories) {
    int maxLevel = 0;
    
    void calculateLevel(List<Map<String, dynamic>> cats, int currentLevel) {
      maxLevel = currentLevel > maxLevel ? currentLevel : maxLevel;
      for (final cat in cats) {
        final children = List<Map<String, dynamic>>.from(cat['children']);
        if (children.isNotEmpty) {
          calculateLevel(children, currentLevel + 1);
        }
      }
    }
    
    calculateLevel(categories, 0);
    return maxLevel;
  }
  
  /// Private helper for analytics tracking
  static Future<void> _trackAnalytics(String userId, String activityType, Map<String, dynamic> metrics) async {
    try {
      await Supabase.instance.client
          .from('learning_analytics')
          .insert({
            'profile_id': userId,
            'activity_type': activityType,
            'content_type': 'enterprise_categories',
            'metrics': metrics,
            'session_data': {
              'service': 'EnterpriseCategoryService',
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