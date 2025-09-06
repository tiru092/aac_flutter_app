import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/symbol.dart';
import '../models/communication_history.dart';
import '../models/user_profile.dart';
import '../services/symbol_database_service.dart';
import '../services/user_profile_service.dart';

/// Enterprise-grade data caching service for optimal offline experience
/// Pre-caches frequently used data and manages intelligent cache policies
class DataCacheService {
  static final DataCacheService _instance = DataCacheService._internal();
  static DataCacheService get instance => _instance;
  
  DataCacheService._internal();

  // Cache storage keys
  static const String _communicationItemsKey = 'cached_communication_items';
  static const String _categoriesKey = 'cached_categories';
  static const String _userProfilesKey = 'cached_user_profiles';
  static const String _frequentlyUsedKey = 'frequently_used_items';
  static const String _recentlyUsedKey = 'recently_used_items';
  static const String _cacheMetadataKey = 'cache_metadata';
  static const String _usageStatisticsKey = 'usage_statistics';
  static const String _preferencesKey = 'cache_preferences';

  // Cache configuration
  static const int maxCacheSize = 50 * 1024 * 1024; // 50MB
  static const int maxRecentItems = 100;
  static const int maxFrequentItems = 50;
  static const Duration cacheValidityPeriod = Duration(hours: 24);
  static const Duration backgroundUpdateInterval = Duration(minutes: 30);

  // Services
  SharedPreferences? _prefs;
  final SymbolDatabaseService _symbolService = SymbolDatabaseService();
  final UserProfileService _userService = UserProfileService();
  
  // Cache state
  final Map<String, dynamic> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, int> _accessCounts = {};
  final Set<String> _priorityItems = {};
  
  // Streams for real-time updates
  final StreamController<CacheStatus> _statusController = StreamController<CacheStatus>.broadcast();
  final StreamController<Map<String, dynamic>> _cacheUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  
  // Background processing
  Timer? _backgroundUpdateTimer;
  Timer? _cacheCleanupTimer;
  bool _isInitialized = false;
  bool _backgroundProcessingEnabled = true;

  // Getters
  Stream<CacheStatus> get statusStream => _statusController.stream;
  Stream<Map<String, dynamic>> get cacheUpdateStream => _cacheUpdateController.stream;
  bool get isInitialized => _isInitialized;

  /// Initialize the cache service
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Load cache preferences
      await _loadCachePreferences();
      
      // Load existing cache metadata
      await _loadCacheMetadata();
      
      // Pre-load critical data into memory
      await _loadCriticalDataToMemory();
      
      // Start background processes
      if (_backgroundProcessingEnabled) {
        _startBackgroundProcesses();
      }
      
      _isInitialized = true;
      _emitStatus(CacheStatus.ready);
      
      debugPrint('DataCacheService: Initialized successfully');
    } catch (e) {
      debugPrint('DataCacheService: Initialization failed - $e');
      _emitStatus(CacheStatus.error);
      rethrow;
    }
  }

  /// Pre-cache frequently used communication items
  Future<void> preCacheFrequentlyUsed() async {
    if (!_isInitialized) return;
    
    try {
      _emitStatus(CacheStatus.updating);
      
      // Get frequently used items based on usage statistics
      final frequentItems = await _getFrequentlyUsedItems();
      final recentItems = await _getRecentlyUsedItems();
      
      // Combine and prioritize items
      final itemsToCache = <String, dynamic>{};
      
      // Add frequent items with high priority
      for (final item in frequentItems) {
        itemsToCache[item['id']] = {
          'data': item,
          'priority': 'high',
          'lastAccessed': DateTime.now().millisecondsSinceEpoch,
          'accessCount': _accessCounts[item['id']] ?? 0,
        };
      }
      
      // Add recent items with medium priority
      for (final item in recentItems) {
        if (!itemsToCache.containsKey(item['id'])) {
          itemsToCache[item['id']] = {
            'data': item,
            'priority': 'medium',
            'lastAccessed': DateTime.now().millisecondsSinceEpoch,
            'accessCount': _accessCounts[item['id']] ?? 0,
          };
        }
      }
      
      // Cache symbols from SymbolDatabaseService
      final symbols = _symbolService.symbols;
      for (final symbol in symbols) {
        if (!itemsToCache.containsKey(symbol.id)) {
          itemsToCache[symbol.id ?? symbol.label] = {
            'data': {
              'id': symbol.id ?? symbol.label,
              'label': symbol.label,
              'imagePath': symbol.imagePath,
              'category': symbol.category,
              'description': symbol.description,
              'speechText': symbol.speechText,
              'colorCode': symbol.colorCode,
            },
            'priority': 'medium',
            'lastAccessed': DateTime.now().millisecondsSinceEpoch,
            'accessCount': _accessCounts[symbol.id ?? symbol.label] ?? 0,
          };
        }
      }
      
      // Cache communication items
      await _cacheData(_communicationItemsKey, itemsToCache);
      
      // Pre-load into memory cache for instant access
      _memoryCache[_communicationItemsKey] = itemsToCache;
      _cacheTimestamps[_communicationItemsKey] = DateTime.now();
      
      debugPrint('DataCacheService: Pre-cached ${itemsToCache.length} communication items');
      _emitStatus(CacheStatus.ready);
      
    } catch (e) {
      debugPrint('DataCacheService: Pre-caching failed - $e');
      _emitStatus(CacheStatus.error);
    }
  }

  /// Cache categories and organizational data
  Future<void> preCacheCategories() async {
    if (!_isInitialized) return;
    
    try {
      // Get all categories from service
      final categories = _symbolService.categories;
      
      final categoryData = <String, dynamic>{};
      for (final category in categories) {
        categoryData[category.id ?? category.name] = {
          'data': {
            'id': category.id ?? category.name,
            'name': category.name,
            'iconPath': category.iconPath,
            'colorCode': category.colorCode,
            'dateCreated': category.dateCreated.toIso8601String(),
            'isDefault': category.isDefault,
          },
          'priority': 'high', // Categories are always high priority
          'lastAccessed': DateTime.now().millisecondsSinceEpoch,
        };
      }
      
      await _cacheData(_categoriesKey, categoryData);
      _memoryCache[_categoriesKey] = categoryData;
      _cacheTimestamps[_categoriesKey] = DateTime.now();
      
      debugPrint('DataCacheService: Pre-cached ${categories.length} categories');
      
    } catch (e) {
      debugPrint('DataCacheService: Category pre-caching failed - $e');
    }
  }

  /// Cache user profiles and settings
  Future<void> preCacheUserProfiles() async {
    if (!_isInitialized) return;
    
    try {
      // Get current user profiles
      final profiles = await UserProfileService.getAllProfiles();
      
      final profileData = <String, dynamic>{};
      for (final profile in profiles) {
        profileData[profile.id] = {
          'data': {
            'id': profile.id,
            'name': profile.name,
            'role': profile.role.toString(),
            'createdAt': profile.createdAt.toIso8601String(),
            // Add other profile data as needed
          },
          'priority': 'high',
          'lastAccessed': DateTime.now().millisecondsSinceEpoch,
        };
      }
      
      await _cacheData(_userProfilesKey, profileData);
      _memoryCache[_userProfilesKey] = profileData;
      _cacheTimestamps[_userProfilesKey] = DateTime.now();
      
      debugPrint('DataCacheService: Pre-cached ${profiles.length} user profiles');
      
    } catch (e) {
      debugPrint('DataCacheService: User profile pre-caching failed - $e');
    }
  }

  /// Get cached communication items
  Future<List<Map<String, dynamic>>> getCachedCommunicationItems({bool memoryOnly = false}) async {
    try {
      Map<String, dynamic>? cachedData;
      
      // Try memory cache first for instant access
      if (_memoryCache.containsKey(_communicationItemsKey)) {
        cachedData = _memoryCache[_communicationItemsKey];
      } else if (!memoryOnly) {
        // Fall back to persistent storage
        cachedData = await _getCachedData(_communicationItemsKey);
        if (cachedData != null) {
          _memoryCache[_communicationItemsKey] = cachedData;
        }
      }
      
      if (cachedData == null) return [];
      
      // Convert cached data to Map objects (simplified version)
      final items = <Map<String, dynamic>>[];
      for (final entry in cachedData.values) {
        try {
          final itemData = entry['data'] as Map<String, dynamic>;
          items.add(itemData);
        } catch (e) {
          debugPrint('DataCacheService: Failed to parse cached item - $e');
        }
      }
      
      // Update access statistics
      await _updateAccessStatistics(_communicationItemsKey);
      
      return items;
      
    } catch (e) {
      debugPrint('DataCacheService: Failed to get cached communication items - $e');
      return [];
    }
  }

  /// Get cached categories
  Future<List<Map<String, dynamic>>> getCachedCategories({bool memoryOnly = false}) async {
    try {
      Map<String, dynamic>? cachedData;
      
      if (_memoryCache.containsKey(_categoriesKey)) {
        cachedData = _memoryCache[_categoriesKey];
      } else if (!memoryOnly) {
        cachedData = await _getCachedData(_categoriesKey);
        if (cachedData != null) {
          _memoryCache[_categoriesKey] = cachedData;
        }
      }
      
      if (cachedData == null) return [];
      
      final categories = <Map<String, dynamic>>[];
      for (final entry in cachedData.values) {
        try {
          final categoryData = entry['data'] as Map<String, dynamic>;
          categories.add(categoryData);
        } catch (e) {
          debugPrint('DataCacheService: Failed to parse cached category - $e');
        }
      }
      
      await _updateAccessStatistics(_categoriesKey);
      return categories;
      
    } catch (e) {
      debugPrint('DataCacheService: Failed to get cached categories - $e');
      return [];
    }
  }

  /// Get cached user profiles
  Future<List<Map<String, dynamic>>> getCachedUserProfiles({bool memoryOnly = false}) async {
    try {
      Map<String, dynamic>? cachedData;
      
      if (_memoryCache.containsKey(_userProfilesKey)) {
        cachedData = _memoryCache[_userProfilesKey];
      } else if (!memoryOnly) {
        cachedData = await _getCachedData(_userProfilesKey);
        if (cachedData != null) {
          _memoryCache[_userProfilesKey] = cachedData;
        }
      }
      
      if (cachedData == null) return [];
      
      final profiles = <Map<String, dynamic>>[];
      for (final entry in cachedData.values) {
        try {
          final profileData = entry['data'] as Map<String, dynamic>;
          profiles.add(profileData);
        } catch (e) {
          debugPrint('DataCacheService: Failed to parse cached profile - $e');
        }
      }
      
      await _updateAccessStatistics(_userProfilesKey);
      return profiles;
      
    } catch (e) {
      debugPrint('DataCacheService: Failed to get cached user profiles - $e');
      return [];
    }
  }

  /// Record usage of a communication item for intelligent caching
  Future<void> recordItemUsage(String itemId) async {
    if (!_isInitialized) return;
    
    try {
      // Update access count
      _accessCounts[itemId] = (_accessCounts[itemId] ?? 0) + 1;
      
      // Update recently used items
      final recentItems = await _getRecentlyUsedItems();
      recentItems.removeWhere((item) => item['id'] == itemId);
      recentItems.insert(0, {
        'id': itemId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'count': _accessCounts[itemId],
      });
      
      // Keep only the most recent items
      if (recentItems.length > maxRecentItems) {
        recentItems.removeRange(maxRecentItems, recentItems.length);
      }
      
      await _prefs?.setString(_recentlyUsedKey, jsonEncode(recentItems));
      
      // Update frequently used items if usage count warrants it
      if (_accessCounts[itemId]! >= 3) {
        await _updateFrequentlyUsedItems(itemId);
      }
      
      // Save usage statistics
      await _saveUsageStatistics();
      
      _cacheUpdateController.add({'itemUsed': itemId});
      
    } catch (e) {
      debugPrint('DataCacheService: Failed to record item usage - $e');
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    try {
      _memoryCache.clear();
      _cacheTimestamps.clear();
      _accessCounts.clear();
      _priorityItems.clear();
      
      await _prefs?.remove(_communicationItemsKey);
      await _prefs?.remove(_categoriesKey);
      await _prefs?.remove(_userProfilesKey);
      await _prefs?.remove(_cacheMetadataKey);
      
      debugPrint('DataCacheService: Cache cleared successfully');
      _emitStatus(CacheStatus.ready);
      
    } catch (e) {
      debugPrint('DataCacheService: Failed to clear cache - $e');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStatistics() async {
    try {
      final cacheSize = await _calculateCacheSize();
      final itemCount = _memoryCache.length;
      final hitRate = await _calculateCacheHitRate();
      
      return {
        'cacheSize': cacheSize,
        'cacheSizeFormatted': _formatBytes(cacheSize),
        'itemCount': itemCount,
        'hitRate': hitRate,
        'memoryItemCount': _memoryCache.length,
        'accessCounts': Map<String, int>.from(_accessCounts),
        'totalAccesses': _accessCounts.values.fold(0, (sum, count) => sum + count),
        'backgroundProcessingEnabled': _backgroundProcessingEnabled,
        'lastUpdate': _cacheTimestamps.values.isNotEmpty 
            ? _cacheTimestamps.values.reduce((a, b) => a.isAfter(b) ? a : b).toIso8601String()
            : null,
      };
    } catch (e) {
      debugPrint('DataCacheService: Failed to get cache statistics - $e');
      return {};
    }
  }

  /// Configure cache preferences
  Future<void> setCachePreferences({
    bool? backgroundProcessingEnabled,
    bool? aggressiveCaching,
    int? maxCacheItems,
  }) async {
    try {
      final prefs = {
        'backgroundProcessingEnabled': backgroundProcessingEnabled ?? _backgroundProcessingEnabled,
        'aggressiveCaching': aggressiveCaching ?? false,
        'maxCacheItems': maxCacheItems ?? 1000,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      };
      
      await _prefs?.setString(_preferencesKey, jsonEncode(prefs));
      
      if (backgroundProcessingEnabled != null) {
        _backgroundProcessingEnabled = backgroundProcessingEnabled;
        if (backgroundProcessingEnabled && _backgroundUpdateTimer == null) {
          _startBackgroundProcesses();
        } else if (!backgroundProcessingEnabled) {
          _stopBackgroundProcesses();
        }
      }
      
      debugPrint('DataCacheService: Cache preferences updated');
      
    } catch (e) {
      debugPrint('DataCacheService: Failed to set cache preferences - $e');
    }
  }

  // Private helper methods
  
  Future<void> _loadCachePreferences() async {
    try {
      final prefsString = _prefs?.getString(_preferencesKey);
      if (prefsString != null) {
        final prefs = jsonDecode(prefsString);
        _backgroundProcessingEnabled = prefs['backgroundProcessingEnabled'] ?? true;
      }
    } catch (e) {
      debugPrint('DataCacheService: Failed to load cache preferences - $e');
    }
  }
  
  Future<void> _loadCacheMetadata() async {
    try {
      final metadataString = _prefs?.getString(_cacheMetadataKey);
      if (metadataString != null) {
        final metadata = jsonDecode(metadataString);
        
        // Load timestamps
        final timestamps = metadata['timestamps'] as Map<String, dynamic>?;
        if (timestamps != null) {
          timestamps.forEach((key, value) {
            _cacheTimestamps[key] = DateTime.fromMillisecondsSinceEpoch(value);
          });
        }
        
        // Load access counts
        final accessCounts = metadata['accessCounts'] as Map<String, dynamic>?;
        if (accessCounts != null) {
          accessCounts.forEach((key, value) {
            _accessCounts[key] = value;
          });
        }
      }
    } catch (e) {
      debugPrint('DataCacheService: Failed to load cache metadata - $e');
    }
  }
  
  Future<void> _loadCriticalDataToMemory() async {
    // Load categories (always needed)
    await preCacheCategories();
    
    // Load frequently used items
    await preCacheFrequentlyUsed();
    
    // Load user profiles
    await preCacheUserProfiles();
  }
  
  void _startBackgroundProcesses() {
    // Background update timer
    _backgroundUpdateTimer = Timer.periodic(backgroundUpdateInterval, (timer) {
      _performBackgroundUpdate();
    });
    
    // Cache cleanup timer (daily)
    _cacheCleanupTimer = Timer.periodic(const Duration(hours: 24), (timer) {
      _performCacheCleanup();
    });
  }
  
  void _stopBackgroundProcesses() {
    _backgroundUpdateTimer?.cancel();
    _backgroundUpdateTimer = null;
    
    _cacheCleanupTimer?.cancel();
    _cacheCleanupTimer = null;
  }
  
  Future<void> _performBackgroundUpdate() async {
    try {
      debugPrint('DataCacheService: Performing background update');
      
      // Re-cache frequently used items
      await preCacheFrequentlyUsed();
      
      // Update cache metadata
      await _saveCacheMetadata();
      
    } catch (e) {
      debugPrint('DataCacheService: Background update failed - $e');
    }
  }
  
  Future<void> _performCacheCleanup() async {
    try {
      debugPrint('DataCacheService: Performing cache cleanup');
      
      // Remove expired cache entries
      final now = DateTime.now();
      final keysToRemove = <String>[];
      
      _cacheTimestamps.forEach((key, timestamp) {
        if (now.difference(timestamp) > cacheValidityPeriod) {
          keysToRemove.add(key);
        }
      });
      
      for (final key in keysToRemove) {
        _memoryCache.remove(key);
        _cacheTimestamps.remove(key);
        await _prefs?.remove(key);
      }
      
      debugPrint('DataCacheService: Cleaned up ${keysToRemove.length} expired entries');
      
    } catch (e) {
      debugPrint('DataCacheService: Cache cleanup failed - $e');
    }
  }
  
  Future<List<Map<String, dynamic>>> _getFrequentlyUsedItems() async {
    try {
      final frequentString = _prefs?.getString(_frequentlyUsedKey);
      if (frequentString != null) {
        final items = jsonDecode(frequentString) as List;
        return items.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('DataCacheService: Failed to get frequently used items - $e');
    }
    return [];
  }
  
  Future<List<Map<String, dynamic>>> _getRecentlyUsedItems() async {
    try {
      final recentString = _prefs?.getString(_recentlyUsedKey);
      if (recentString != null) {
        final items = jsonDecode(recentString) as List;
        return items.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('DataCacheService: Failed to get recently used items - $e');
    }
    return [];
  }
  
  Future<void> _updateFrequentlyUsedItems(String itemId) async {
    try {
      final frequentItems = await _getFrequentlyUsedItems();
      
      // Update or add item
      final existingIndex = frequentItems.indexWhere((item) => item['id'] == itemId);
      if (existingIndex != -1) {
        frequentItems[existingIndex]['count'] = _accessCounts[itemId];
        frequentItems[existingIndex]['lastUsed'] = DateTime.now().millisecondsSinceEpoch;
      } else {
        frequentItems.add({
          'id': itemId,
          'count': _accessCounts[itemId],
          'lastUsed': DateTime.now().millisecondsSinceEpoch,
        });
      }
      
      // Sort by usage count
      frequentItems.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
      
      // Keep only top items
      if (frequentItems.length > maxFrequentItems) {
        frequentItems.removeRange(maxFrequentItems, frequentItems.length);
      }
      
      await _prefs?.setString(_frequentlyUsedKey, jsonEncode(frequentItems));
      
    } catch (e) {
      debugPrint('DataCacheService: Failed to update frequently used items - $e');
    }
  }
  
  Future<void> _cacheData(String key, Map<String, dynamic> data) async {
    try {
      final jsonString = jsonEncode(data);
      await _prefs?.setString(key, jsonString);
      _cacheTimestamps[key] = DateTime.now();
    } catch (e) {
      debugPrint('DataCacheService: Failed to cache data for key $key - $e');
    }
  }
  
  Future<Map<String, dynamic>?> _getCachedData(String key) async {
    try {
      final jsonString = _prefs?.getString(key);
      if (jsonString != null) {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('DataCacheService: Failed to get cached data for key $key - $e');
    }
    return null;
  }
  
  Future<void> _updateAccessStatistics(String key) async {
    _accessCounts[key] = (_accessCounts[key] ?? 0) + 1;
    await _saveCacheMetadata();
  }
  
  Future<void> _saveCacheMetadata() async {
    try {
      final metadata = {
        'timestamps': _cacheTimestamps.map((key, value) => 
            MapEntry(key, value.millisecondsSinceEpoch)),
        'accessCounts': _accessCounts,
        'lastSaved': DateTime.now().millisecondsSinceEpoch,
      };
      
      await _prefs?.setString(_cacheMetadataKey, jsonEncode(metadata));
    } catch (e) {
      debugPrint('DataCacheService: Failed to save cache metadata - $e');
    }
  }
  
  Future<void> _saveUsageStatistics() async {
    try {
      final stats = {
        'accessCounts': _accessCounts,
        'totalAccesses': _accessCounts.values.fold(0, (sum, count) => sum + count),
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      };
      
      await _prefs?.setString(_usageStatisticsKey, jsonEncode(stats));
    } catch (e) {
      debugPrint('DataCacheService: Failed to save usage statistics - $e');
    }
  }
  
  Future<int> _calculateCacheSize() async {
    int totalSize = 0;
    try {
      final keys = [_communicationItemsKey, _categoriesKey, _userProfilesKey];
      for (final key in keys) {
        final data = _prefs?.getString(key);
        if (data != null) {
          totalSize += data.length;
        }
      }
    } catch (e) {
      debugPrint('DataCacheService: Failed to calculate cache size - $e');
    }
    return totalSize;
  }
  
  Future<double> _calculateCacheHitRate() async {
    try {
      final totalAccesses = _accessCounts.values.fold(0, (sum, count) => sum + count);
      final cacheHits = _memoryCache.length * 10; // Estimated
      return totalAccesses > 0 ? (cacheHits / totalAccesses).clamp(0.0, 1.0) : 0.0;
    } catch (e) {
      debugPrint('DataCacheService: Failed to calculate cache hit rate - $e');
      return 0.0;
    }
  }
  
  String _formatBytes(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    int index = 0;
    double size = bytes.toDouble();
    
    while (size >= 1024 && index < suffixes.length - 1) {
      size /= 1024;
      index++;
    }
    
    return '${size.toStringAsFixed(1)} ${suffixes[index]}';
  }
  
  void _emitStatus(CacheStatus status) {
    _statusController.add(status);
  }

  /// Dispose resources
  void dispose() {
    _stopBackgroundProcesses();
    _statusController.close();
    _cacheUpdateController.close();
  }
}

/// Cache status enumeration
enum CacheStatus {
  initializing,
  ready,
  updating,
  error,
}

/// Cache status information
class CacheStatusInfo {
  final CacheStatus status;
  final String? message;
  final DateTime timestamp;

  CacheStatusInfo({
    required this.status,
    this.message,
    required this.timestamp,
  });
}
