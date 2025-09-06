import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/symbol.dart';
import '../models/user_profile.dart';
import '../models/communication_history.dart';
import '../services/connectivity_service.dart';
import '../services/data_cache_service.dart';

/// Enterprise-grade offline-first features manager
/// Provides comprehensive offline functionality that works seamlessly without internet
class OfflineFeaturesService {
  static final OfflineFeaturesService _instance = OfflineFeaturesService._internal();
  static OfflineFeaturesService get instance => _instance;
  
  OfflineFeaturesService._internal();

  // Storage keys
  static const String _offlineAnalyticsKey = 'offline_analytics_data';
  static const String _offlineBackupsKey = 'offline_backups_metadata';
  static const String _offlineSettingsKey = 'offline_settings_backup';
  static const String _speechPatternsKey = 'offline_speech_patterns';
  static const String _usageInsightsKey = 'offline_usage_insights';
  static const String _personalizedContentKey = 'offline_personalized_content';
  static const String _offlineActivitiesKey = 'offline_activities_data';
  static const String _achievementsKey = 'offline_achievements';

  // Services
  SharedPreferences? _prefs;
  final ConnectivityService _connectivityService = ConnectivityService.instance;
  final DataCacheService _cacheService = DataCacheService.instance;
  
  // State management
  bool _isInitialized = false;
  final Map<String, dynamic> _offlineData = {};
  final StreamController<OfflineFeatureUpdate> _updateController = StreamController<OfflineFeatureUpdate>.broadcast();
  
  // Analytics and insights
  final Map<String, int> _usageCounters = {};
  final Map<String, List<DateTime>> _usageTimestamps = {};
  final Map<String, dynamic> _speechPatterns = {};
  final List<Map<String, dynamic>> _offlineActivities = [];

  // Getters
  Stream<OfflineFeatureUpdate> get updateStream => _updateController.stream;
  bool get isInitialized => _isInitialized;
  Map<String, dynamic> get offlineData => Map.unmodifiable(_offlineData);

  /// Initialize offline features service
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Load existing offline data
      await _loadOfflineData();
      
      // Initialize analytics tracking
      await _initializeAnalytics();
      
      // Setup personalized content
      await _initializePersonalizedContent();
      
      // Initialize offline activities
      await _initializeOfflineActivities();
      
      _isInitialized = true;
      debugPrint('OfflineFeaturesService: Initialized successfully');
      
    } catch (e) {
      debugPrint('OfflineFeaturesService: Initialization failed - $e');
      rethrow;
    }
  }

  /// Advanced offline analytics and usage tracking
  Future<void> trackCommunicationUsage(String itemId, String category, String content) async {
    if (!_isInitialized) return;

    try {
      final timestamp = DateTime.now();
      
      // Update usage counters
      _usageCounters[itemId] = (_usageCounters[itemId] ?? 0) + 1;
      
      // Track timestamps for pattern analysis
      _usageTimestamps[itemId] = (_usageTimestamps[itemId] ?? [])..add(timestamp);
      
      // Analyze speech patterns
      await _analyzeSpeechPattern(content, category, timestamp);
      
      // Generate insights
      await _generateUsageInsights();
      
      // Record offline activity
      await _recordOfflineActivity({
        'type': 'communication',
        'itemId': itemId,
        'category': category,
        'content': content,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'sessionId': _getCurrentSessionId(),
      });
      
      // Save data periodically
      await _saveOfflineAnalytics();
      
      _updateController.add(OfflineFeatureUpdate(
        type: OfflineFeatureType.analytics,
        data: {'itemId': itemId, 'usage': _usageCounters[itemId]},
      ));
      
    } catch (e) {
      debugPrint('OfflineFeaturesService: Failed to track usage - $e');
    }
  }

  /// Generate personalized communication recommendations
  Future<List<Map<String, dynamic>>> getPersonalizedRecommendations() async {
    if (!_isInitialized) return [];

    try {
      final recommendations = <Map<String, dynamic>>[];
      
      // Get most frequently used items
      final frequentItems = _usageCounters.entries
          .where((entry) => entry.value >= 3)
          .toList()..sort((a, b) => b.value.compareTo(a.value));
      
      for (final entry in frequentItems.take(10)) {
        recommendations.add({
          'itemId': entry.key,
          'score': entry.value,
          'reason': 'Frequently used',
          'priority': 'high',
        });
      }
      
      // Get items used at similar times of day
      final currentHour = DateTime.now().hour;
      final timeBasedItems = _getItemsUsedAtTime(currentHour);
      
      for (final item in timeBasedItems.take(5)) {
        if (!recommendations.any((r) => r['itemId'] == item['itemId'])) {
          recommendations.add({
            'itemId': item['itemId'],
            'score': item['frequency'],
            'reason': 'Often used at this time',
            'priority': 'medium',
          });
        }
      }
      
      // Get items from similar communication patterns
      final patternBasedItems = await _getPatternBasedRecommendations();
      
      for (final item in patternBasedItems.take(3)) {
        if (!recommendations.any((r) => r['itemId'] == item['itemId'])) {
          recommendations.add({
            'itemId': item['itemId'],
            'score': item['score'],
            'reason': 'Similar to your communication style',
            'priority': 'low',
          });
        }
      }
      
      return recommendations;
      
    } catch (e) {
      debugPrint('OfflineFeaturesService: Failed to generate recommendations - $e');
      return [];
    }
  }

  /// Create comprehensive offline backup
  Future<Map<String, dynamic>> createOfflineBackup() async {
    if (!_isInitialized) return {};

    try {
      final backup = <String, dynamic>{
        'metadata': {
          'version': '1.0',
          'created': DateTime.now().toIso8601String(),
          'deviceInfo': await _getDeviceInfo(),
          'appVersion': '1.1.0',
        },
        'userData': {
          'usageCounters': _usageCounters,
          'usageTimestamps': _usageTimestamps.map((key, value) => 
              MapEntry(key, value.map((dt) => dt.millisecondsSinceEpoch).toList())),
          'speechPatterns': _speechPatterns,
          'personalizedContent': _offlineData[_personalizedContentKey] ?? {},
          'achievements': _offlineData[_achievementsKey] ?? [],
        },
        'analytics': {
          'offlineActivities': _offlineActivities,
          'usageInsights': _offlineData[_usageInsightsKey] ?? {},
        },
        'settings': await _exportSettings(),
        'cache': await _cacheService.getCacheStatistics(),
      };
      
      // Save backup metadata
      final backupMetadata = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'created': DateTime.now().toIso8601String(),
        'size': jsonEncode(backup).length,
        'type': 'full_offline_backup',
      };
      
      final existingBackups = await _getOfflineBackups();
      existingBackups.add(backupMetadata);
      
      // Keep only the 5 most recent backups
      existingBackups.sort((a, b) => b['created'].compareTo(a['created']));
      if (existingBackups.length > 5) {
        existingBackups.removeRange(5, existingBackups.length);
      }
      
      await _prefs?.setString(_offlineBackupsKey, jsonEncode(existingBackups));
      
      debugPrint('OfflineFeaturesService: Created offline backup with ${backup.length} sections');
      return backup;
      
    } catch (e) {
      debugPrint('OfflineFeaturesService: Failed to create offline backup - $e');
      return {};
    }
  }

  /// Restore from offline backup
  Future<bool> restoreFromOfflineBackup(Map<String, dynamic> backup) async {
    if (!_isInitialized) return false;

    try {
      // Validate backup format
      if (!backup.containsKey('metadata') || !backup.containsKey('userData')) {
        throw Exception('Invalid backup format');
      }
      
      // Restore user data
      final userData = backup['userData'] as Map<String, dynamic>;
      
      if (userData.containsKey('usageCounters')) {
        _usageCounters.clear();
        _usageCounters.addAll(Map<String, int>.from(userData['usageCounters']));
      }
      
      if (userData.containsKey('usageTimestamps')) {
        _usageTimestamps.clear();
        final timestamps = userData['usageTimestamps'] as Map<String, dynamic>;
        timestamps.forEach((key, value) {
          _usageTimestamps[key] = (value as List).map((timestamp) => 
              DateTime.fromMillisecondsSinceEpoch(timestamp)).toList();
        });
      }
      
      if (userData.containsKey('speechPatterns')) {
        _speechPatterns.clear();
        _speechPatterns.addAll(userData['speechPatterns']);
      }
      
      // Restore analytics data
      if (backup.containsKey('analytics')) {
        final analytics = backup['analytics'] as Map<String, dynamic>;
        
        if (analytics.containsKey('offlineActivities')) {
          _offlineActivities.clear();
          _offlineActivities.addAll(List<Map<String, dynamic>>.from(analytics['offlineActivities']));
        }
        
        if (analytics.containsKey('usageInsights')) {
          _offlineData[_usageInsightsKey] = analytics['usageInsights'];
        }
      }
      
      // Save restored data
      await _saveOfflineAnalytics();
      await _saveOfflineData();
      
      _updateController.add(OfflineFeatureUpdate(
        type: OfflineFeatureType.backup,
        data: {'restored': true},
      ));
      
      debugPrint('OfflineFeaturesService: Successfully restored offline backup');
      return true;
      
    } catch (e) {
      debugPrint('OfflineFeaturesService: Failed to restore offline backup - $e');
      return false;
    }
  }

  /// Generate detailed usage insights
  Future<Map<String, dynamic>> generateUsageInsights() async {
    if (!_isInitialized) return {};

    try {
      final insights = <String, dynamic>{};
      final now = DateTime.now();
      
      // Calculate total usage
      final totalUsage = _usageCounters.values.fold(0, (sum, count) => sum + count);
      insights['totalCommunications'] = totalUsage;
      
      // Find most used items
      final sortedUsage = _usageCounters.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
      
      insights['mostUsedItems'] = sortedUsage.take(10).map((entry) => {
        'itemId': entry.key,
        'count': entry.value,
      }).toList();
      
      // Calculate usage patterns by time of day
      final hourlyUsage = <int, int>{};
      for (final timestamps in _usageTimestamps.values) {
        for (final timestamp in timestamps) {
          final hour = timestamp.hour;
          hourlyUsage[hour] = (hourlyUsage[hour] ?? 0) + 1;
        }
      }
      
      insights['hourlyPatterns'] = hourlyUsage;
      insights['peakUsageHour'] = hourlyUsage.entries
          .reduce((a, b) => a.value > b.value ? a : b).key;
      
      // Calculate daily usage trends
      final dailyUsage = <String, int>{};
      final last7Days = List.generate(7, (index) => 
          now.subtract(Duration(days: index)));
      
      for (final day in last7Days) {
        final dayKey = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        int dayCount = 0;
        
        for (final timestamps in _usageTimestamps.values) {
          dayCount += timestamps.where((timestamp) => 
              timestamp.year == day.year &&
              timestamp.month == day.month &&
              timestamp.day == day.day).length;
        }
        
        dailyUsage[dayKey] = dayCount;
      }
      
      insights['dailyUsage'] = dailyUsage;
      insights['averageDailyUsage'] = dailyUsage.values.isNotEmpty
          ? dailyUsage.values.reduce((a, b) => a + b) / dailyUsage.length
          : 0;
      
      // Communication velocity (items per minute in active sessions)
      insights['communicationVelocity'] = _calculateCommunicationVelocity();
      
      // Category preferences
      insights['categoryPreferences'] = await _analyzeCategoryPreferences();
      
      // Progress metrics
      insights['progressMetrics'] = {
        'itemsExplored': _usageCounters.keys.length,
        'consistencyScore': _calculateConsistencyScore(),
        'diversityScore': _calculateDiversityScore(),
      };
      
      // Save insights
      _offlineData[_usageInsightsKey] = insights;
      await _saveOfflineData();
      
      return insights;
      
    } catch (e) {
      debugPrint('OfflineFeaturesService: Failed to generate insights - $e');
      return {};
    }
  }

  /// Get offline achievements and milestones
  Future<List<Map<String, dynamic>>> getOfflineAchievements() async {
    if (!_isInitialized) return [];

    try {
      final achievements = <Map<String, dynamic>>[];
      final totalUsage = _usageCounters.values.fold(0, (sum, count) => sum + count);
      
      // Communication milestones
      final milestones = [10, 50, 100, 500, 1000, 5000];
      for (final milestone in milestones) {
        if (totalUsage >= milestone) {
          achievements.add({
            'id': 'communications_$milestone',
            'title': '$milestone Communications',
            'description': 'Used AAC communication $milestone times',
            'icon': 'chat_bubble',
            'unlocked': true,
            'unlockedAt': _findFirstUsageDate(),
            'category': 'communication',
          });
        }
      }
      
      // Consistency achievements
      final consecutiveDays = _calculateConsecutiveDays();
      if (consecutiveDays >= 7) {
        achievements.add({
          'id': 'consistent_week',
          'title': 'Consistent Communicator',
          'description': 'Used AAC for 7 consecutive days',
          'icon': 'calendar',
          'unlocked': true,
          'unlockedAt': DateTime.now().subtract(Duration(days: consecutiveDays - 7)),
          'category': 'consistency',
        });
      }
      
      // Exploration achievements
      final uniqueItems = _usageCounters.keys.length;
      if (uniqueItems >= 50) {
        achievements.add({
          'id': 'explorer',
          'title': 'Communication Explorer',
          'description': 'Explored $uniqueItems different communication items',
          'icon': 'explore',
          'unlocked': true,
          'unlockedAt': _findFirstUsageDate(),
          'category': 'exploration',
        });
      }
      
      // Save achievements
      _offlineData[_achievementsKey] = achievements;
      await _saveOfflineData();
      
      return achievements;
      
    } catch (e) {
      debugPrint('OfflineFeaturesService: Failed to get achievements - $e');
      return [];
    }
  }

  /// Export offline features statistics
  Future<Map<String, dynamic>> exportOfflineStatistics() async {
    try {
      final insights = await generateUsageInsights();
      final achievements = await getOfflineAchievements();
      final recommendations = await getPersonalizedRecommendations();
      
      return {
        'exportDate': DateTime.now().toIso8601String(),
        'insights': insights,
        'achievements': achievements,
        'recommendations': recommendations,
        'speechPatterns': _speechPatterns,
        'activityLog': _offlineActivities.take(100).toList(), // Last 100 activities
        'metadata': {
          'totalItems': _usageCounters.keys.length,
          'totalUsage': _usageCounters.values.fold(0, (sum, count) => sum + count),
          'dataPoints': _usageTimestamps.values.fold(0, (sum, list) => sum + list.length),
        },
      };
    } catch (e) {
      debugPrint('OfflineFeaturesService: Failed to export statistics - $e');
      return {};
    }
  }

  // Private helper methods
  
  Future<void> _loadOfflineData() async {
    try {
      // Load analytics data
      final analyticsString = _prefs?.getString(_offlineAnalyticsKey);
      if (analyticsString != null) {
        final analytics = jsonDecode(analyticsString);
        
        if (analytics['usageCounters'] != null) {
          _usageCounters.addAll(Map<String, int>.from(analytics['usageCounters']));
        }
        
        if (analytics['speechPatterns'] != null) {
          _speechPatterns.addAll(analytics['speechPatterns']);
        }
        
        if (analytics['usageTimestamps'] != null) {
          final timestamps = analytics['usageTimestamps'] as Map<String, dynamic>;
          timestamps.forEach((key, value) {
            _usageTimestamps[key] = (value as List).map((timestamp) => 
                DateTime.fromMillisecondsSinceEpoch(timestamp)).toList();
          });
        }
      }
      
      // Load other offline data sections
      final offlineDataKeys = [
        _usageInsightsKey,
        _personalizedContentKey,
        _achievementsKey,
      ];
      
      for (final key in offlineDataKeys) {
        final dataString = _prefs?.getString(key);
        if (dataString != null) {
          _offlineData[key] = jsonDecode(dataString);
        }
      }
      
      // Load offline activities
      final activitiesString = _prefs?.getString(_offlineActivitiesKey);
      if (activitiesString != null) {
        final activities = jsonDecode(activitiesString) as List;
        _offlineActivities.addAll(activities.cast<Map<String, dynamic>>());
      }
      
    } catch (e) {
      debugPrint('OfflineFeaturesService: Failed to load offline data - $e');
    }
  }
  
  Future<void> _initializeAnalytics() async {
    // Initialize empty analytics if none exist
    if (_usageCounters.isEmpty) {
      await _saveOfflineAnalytics();
    }
  }
  
  Future<void> _initializePersonalizedContent() async {
    if (!_offlineData.containsKey(_personalizedContentKey)) {
      _offlineData[_personalizedContentKey] = {
        'preferences': {},
        'customizations': {},
        'recommendations': [],
      };
      await _saveOfflineData();
    }
  }
  
  Future<void> _initializeOfflineActivities() async {
    if (_offlineActivities.isEmpty) {
      await _recordOfflineActivity({
        'type': 'system',
        'action': 'offline_features_initialized',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }
  
  Future<void> _analyzeSpeechPattern(String content, String category, DateTime timestamp) async {
    try {
      final words = content.toLowerCase().split(RegExp(r'\W+'));
      final hour = timestamp.hour;
      
      // Track word frequency by category
      _speechPatterns[category] = _speechPatterns[category] ?? {};
      for (final word in words) {
        if (word.isNotEmpty) {
          _speechPatterns[category][word] = (_speechPatterns[category][word] ?? 0) + 1;
        }
      }
      
      // Track time-based patterns
      _speechPatterns['timePatterns'] = _speechPatterns['timePatterns'] ?? {};
      _speechPatterns['timePatterns'][hour.toString()] = 
          (_speechPatterns['timePatterns'][hour.toString()] ?? 0) + 1;
      
    } catch (e) {
      debugPrint('OfflineFeaturesService: Failed to analyze speech pattern - $e');
    }
  }
  
  Future<void> _generateUsageInsights() async {
    // Generate insights periodically (every 10 communications)
    final totalUsage = _usageCounters.values.fold(0, (sum, count) => sum + count);
    if (totalUsage % 10 == 0) {
      await generateUsageInsights();
    }
  }
  
  Future<void> _recordOfflineActivity(Map<String, dynamic> activity) async {
    _offlineActivities.add(activity);
    
    // Keep only recent activities (last 1000)
    if (_offlineActivities.length > 1000) {
      _offlineActivities.removeRange(0, _offlineActivities.length - 1000);
    }
    
    // Save periodically
    if (_offlineActivities.length % 50 == 0) {
      await _prefs?.setString(_offlineActivitiesKey, jsonEncode(_offlineActivities));
    }
  }
  
  String _getCurrentSessionId() {
    // Simple session ID based on app launch time
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
  
  List<Map<String, dynamic>> _getItemsUsedAtTime(int hour) {
    final timeBasedItems = <String, int>{};
    
    _usageTimestamps.forEach((itemId, timestamps) {
      final hourCount = timestamps.where((t) => t.hour == hour).length;
      if (hourCount > 0) {
        timeBasedItems[itemId] = hourCount;
      }
    });
    
    return timeBasedItems.entries.map((entry) => {
      'itemId': entry.key,
      'frequency': entry.value,
    }).toList()..sort((a, b) => (b['frequency'] as int).compareTo(a['frequency'] as int));
  }
  
  Future<List<Map<String, dynamic>>> _getPatternBasedRecommendations() async {
    // Simple pattern-based recommendations
    final recommendations = <Map<String, dynamic>>[];
    
    // Find items frequently used together
    // This is a simplified version - in practice, you'd use more sophisticated algorithms
    
    return recommendations;
  }
  
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    return {
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
    };
  }
  
  Future<List<Map<String, dynamic>>> _getOfflineBackups() async {
    try {
      final backupsString = _prefs?.getString(_offlineBackupsKey);
      if (backupsString != null) {
        final backups = jsonDecode(backupsString) as List;
        return backups.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('OfflineFeaturesService: Failed to get offline backups - $e');
    }
    return [];
  }
  
  Future<Map<String, dynamic>> _exportSettings() async {
    // Export current app settings
    return {
      'accessibility': {
        'highContrast': false, // Would get from AACHelper
        'largeText': false,
        'voiceFeedback': true,
      },
      'preferences': {},
    };
  }
  
  double _calculateCommunicationVelocity() {
    if (_usageTimestamps.isEmpty) return 0.0;
    
    double totalVelocity = 0.0;
    int sessions = 0;
    
    // Calculate velocity for each item's usage sessions
    _usageTimestamps.forEach((itemId, timestamps) {
      if (timestamps.length >= 2) {
        final sortedTimestamps = timestamps..sort();
        for (int i = 1; i < sortedTimestamps.length; i++) {
          final duration = sortedTimestamps[i].difference(sortedTimestamps[i-1]);
          if (duration.inMinutes > 0 && duration.inMinutes <= 60) { // Valid session
            totalVelocity += 1 / duration.inMinutes;
            sessions++;
          }
        }
      }
    });
    
    return sessions > 0 ? totalVelocity / sessions : 0.0;
  }
  
  Future<Map<String, dynamic>> _analyzeCategoryPreferences() async {
    final categoryUsage = <String, int>{};
    
    // This would analyze category usage from actual data
    // For now, return placeholder data
    
    return categoryUsage;
  }
  
  double _calculateConsistencyScore() {
    if (_usageTimestamps.isEmpty) return 0.0;
    
    final allTimestamps = _usageTimestamps.values
        .expand((list) => list)
        .toList()..sort();
    
    if (allTimestamps.length < 2) return 0.0;
    
    // Calculate consistency based on usage distribution
    final totalDays = allTimestamps.last.difference(allTimestamps.first).inDays + 1;
    final usageDays = allTimestamps.map((t) => 
        DateTime(t.year, t.month, t.day)).toSet().length;
    
    return usageDays / totalDays;
  }
  
  double _calculateDiversityScore() {
    if (_usageCounters.isEmpty) return 0.0;
    
    final totalUsage = _usageCounters.values.fold(0, (sum, count) => sum + count);
    final uniqueItems = _usageCounters.keys.length;
    
    // Higher score for more even distribution across items
    final averageUsage = totalUsage / uniqueItems;
    final variance = _usageCounters.values
        .map((count) => (count - averageUsage) * (count - averageUsage))
        .fold(0.0, (sum, sq) => sum + sq) / uniqueItems;
    
    return 1.0 / (1.0 + variance / (averageUsage * averageUsage));
  }
  
  DateTime? _findFirstUsageDate() {
    if (_usageTimestamps.isEmpty) return null;
    
    final allTimestamps = _usageTimestamps.values
        .expand((list) => list)
        .toList();
    
    if (allTimestamps.isEmpty) return null;
    
    return allTimestamps.reduce((a, b) => a.isBefore(b) ? a : b);
  }
  
  int _calculateConsecutiveDays() {
    if (_usageTimestamps.isEmpty) return 0;
    
    final allTimestamps = _usageTimestamps.values
        .expand((list) => list)
        .toList()..sort();
    
    if (allTimestamps.isEmpty) return 0;
    
    final usageDays = allTimestamps.map((t) => 
        DateTime(t.year, t.month, t.day)).toSet().toList()..sort();
    
    int consecutive = 1;
    int maxConsecutive = 1;
    
    for (int i = 1; i < usageDays.length; i++) {
      final daysDiff = usageDays[i].difference(usageDays[i-1]).inDays;
      if (daysDiff == 1) {
        consecutive++;
        maxConsecutive = maxConsecutive > consecutive ? maxConsecutive : consecutive;
      } else {
        consecutive = 1;
      }
    }
    
    return maxConsecutive;
  }
  
  Future<void> _saveOfflineAnalytics() async {
    try {
      final analytics = {
        'usageCounters': _usageCounters,
        'speechPatterns': _speechPatterns,
        'usageTimestamps': _usageTimestamps.map((key, value) => 
            MapEntry(key, value.map((dt) => dt.millisecondsSinceEpoch).toList())),
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      };
      
      await _prefs?.setString(_offlineAnalyticsKey, jsonEncode(analytics));
    } catch (e) {
      debugPrint('OfflineFeaturesService: Failed to save offline analytics - $e');
    }
  }
  
  Future<void> _saveOfflineData() async {
    try {
      for (final entry in _offlineData.entries) {
        await _prefs?.setString(entry.key, jsonEncode(entry.value));
      }
    } catch (e) {
      debugPrint('OfflineFeaturesService: Failed to save offline data - $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _updateController.close();
  }
}

/// Offline feature update types
enum OfflineFeatureType {
  analytics,
  backup,
  insights,
  achievements,
  recommendations,
}

/// Offline feature update notification
class OfflineFeatureUpdate {
  final OfflineFeatureType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  OfflineFeatureUpdate({
    required this.type,
    required this.data,
  }) : timestamp = DateTime.now();
}
