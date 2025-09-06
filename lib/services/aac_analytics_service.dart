import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Professional AAC Analytics Service
/// Based on evidence-based practices from Avaz, Proloquo, and therapeutic research
class AACAnalyticsService {
  static const String _keySessionData = 'aac_session_data';
  static const String _keyGoalProgress = 'aac_goal_progress';
  static const String _keyLanguageStats = 'aac_language_stats';
  static const String _keyTherapeuticData = 'aac_therapeutic_data';

  // Session tracking
  static DateTime? _sessionStart;
  static int _totalTaps = 0;
  static int _totalWords = 0;
  static int _totalSentences = 0;
  static Map<String, int> _categoryUsage = {};
  static Map<String, int> _symbolFrequency = {};
  static List<String> _communicationAttempts = [];
  static Map<String, dynamic> _dailyGoals = {};

  /// Initialize service (for consistency with other services)
  Future<void> initialize() async {
    debugPrint('AACAnalyticsService: Initialized');
  }

  /// Initialize session tracking
  static void startSession() {
    _sessionStart = DateTime.now();
    _totalTaps = 0;
    _totalWords = 0;
    _totalSentences = 0;
    _categoryUsage.clear();
    _symbolFrequency.clear();
    _communicationAttempts.clear();
    print('AAC Analytics: Session started at ${_sessionStart}');
  }

  /// Track symbol usage with therapeutic context
  static void trackSymbolUsage(String symbolId, String category, String context) {
    _totalTaps++;
    _totalWords++;
    
    // Track category usage
    _categoryUsage[category] = (_categoryUsage[category] ?? 0) + 1;
    
    // Track symbol frequency
    _symbolFrequency[symbolId] = (_symbolFrequency[symbolId] ?? 0) + 1;
    
    // Record communication attempt with timestamp
    final attempt = {
      'timestamp': DateTime.now().toIso8601String(),
      'symbolId': symbolId,
      'category': category,
      'context': context,
      'sessionTime': _sessionStart != null 
          ? DateTime.now().difference(_sessionStart!).inSeconds 
          : 0,
    };
    
    _communicationAttempts.add(json.encode(attempt));
    
    if (kDebugMode) {
      print('AAC Analytics: Symbol "$symbolId" used in category "$category"');
    }
  }

  /// Track sentence completion
  static void trackSentenceCompletion(List<String> symbols, String context) {
    _totalSentences++;
    
    final sentence = {
      'timestamp': DateTime.now().toIso8601String(),
      'symbols': symbols,
      'wordCount': symbols.length,
      'context': context,
      'complexity': _calculateSentenceComplexity(symbols),
    };
    
    _communicationAttempts.add(json.encode(sentence));
    
    if (kDebugMode) {
      print('AAC Analytics: Sentence completed with ${symbols.length} words');
    }
  }

  /// Calculate sentence complexity for language development tracking
  static String _calculateSentenceComplexity(List<String> symbols) {
    if (symbols.length == 1) return 'Single Word';
    if (symbols.length == 2) return 'Two Word Combination';
    if (symbols.length <= 4) return 'Simple Sentence';
    if (symbols.length <= 7) return 'Complex Sentence';
    return 'Advanced Expression';
  }

  /// Track therapeutic goal progress
  static void trackGoalProgress(String goalId, String goalType, double progress) {
    _dailyGoals[goalId] = {
      'type': goalType,
      'progress': progress,
      'timestamp': DateTime.now().toIso8601String(),
      'achieved': progress >= 1.0,
    };
    
    if (kDebugMode) {
      print('AAC Analytics: Goal "$goalId" progress: ${(progress * 100).toInt()}%');
    }
  }

  /// Get session summary for therapeutic review
  static Map<String, dynamic> getSessionSummary() {
    final duration = _sessionStart != null 
        ? DateTime.now().difference(_sessionStart!).inMinutes 
        : 0;
    
    return {
      'sessionDuration': duration,
      'totalTaps': _totalTaps,
      'totalWords': _totalWords,
      'totalSentences': _totalSentences,
      'averageWordsPerMinute': duration > 0 ? (_totalWords / duration).toStringAsFixed(1) : '0',
      'categoryBreakdown': _categoryUsage,
      'topSymbols': _getTopSymbols(),
      'communicationComplexity': _getComplexityDistribution(),
      'goalProgress': _dailyGoals,
    };
  }

  /// Get top used symbols for vocabulary analysis
  static List<Map<String, dynamic>> _getTopSymbols() {
    final sorted = _symbolFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(10).map((entry) => {
      'symbol': entry.key,
      'count': entry.value,
    }).toList();
  }

  /// Analyze communication complexity distribution
  static Map<String, int> _getComplexityDistribution() {
    final distribution = <String, int>{};
    
    for (final attemptJson in _communicationAttempts) {
      try {
        final attempt = json.decode(attemptJson);
        if (attempt['complexity'] != null) {
          final complexity = attempt['complexity'] as String;
          distribution[complexity] = (distribution[complexity] ?? 0) + 1;
        }
      } catch (e) {
        // Skip invalid entries
      }
    }
    
    return distribution;
  }

  /// Save session data for long-term analytics
  static Future<void> saveSessionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionData = getSessionSummary();
      
      // Get existing data
      final existingDataJson = prefs.getString(_keySessionData) ?? '[]';
      final existingData = json.decode(existingDataJson) as List;
      
      // Add current session
      sessionData['date'] = DateTime.now().toIso8601String();
      existingData.add(sessionData);
      
      // Keep only last 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final filteredData = existingData.where((session) {
        final sessionDate = DateTime.parse(session['date']);
        return sessionDate.isAfter(thirtyDaysAgo);
      }).toList();
      
      // Save updated data
      await prefs.setString(_keySessionData, json.encode(filteredData));
      
      if (kDebugMode) {
        print('AAC Analytics: Session data saved. Total sessions: ${filteredData.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AAC Analytics: Error saving session data: $e');
      }
    }
  }

  /// Get weekly progress report
  static Future<Map<String, dynamic>> getWeeklyReport() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionDataJson = prefs.getString(_keySessionData) ?? '[]';
      final sessionData = json.decode(sessionDataJson) as List;
      
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final weekSessions = sessionData.where((session) {
        final sessionDate = DateTime.parse(session['date']);
        return sessionDate.isAfter(weekAgo);
      }).toList();
      
      if (weekSessions.isEmpty) {
        return {
          'totalSessions': 0,
          'totalCommunicationTime': 0,
          'averageSessionLength': 0,
          'totalWords': 0,
          'totalSentences': 0,
          'mostUsedCategories': <String, int>{},
          'progressTrend': 'No data',
          'recommendations': ['Start using AAC daily for better progress tracking'],
        };
      }
      
      // Calculate aggregated statistics
      int totalMinutes = 0;
      int totalWords = 0;
      int totalSentences = 0;
      Map<String, int> categoryTotals = {};
      
      for (final session in weekSessions) {
        totalMinutes += session['sessionDuration'] as int;
        totalWords += session['totalWords'] as int;
        totalSentences += session['totalSentences'] as int;
        
        final categories = session['categoryBreakdown'] as Map<String, dynamic>;
        for (final entry in categories.entries) {
          categoryTotals[entry.key] = (categoryTotals[entry.key] ?? 0) + (entry.value as int);
        }
      }
      
      return {
        'totalSessions': weekSessions.length,
        'totalCommunicationTime': totalMinutes,
        'averageSessionLength': (totalMinutes / weekSessions.length).round(),
        'totalWords': totalWords,
        'totalSentences': totalSentences,
        'averageWordsPerSession': (totalWords / weekSessions.length).round(),
        'mostUsedCategories': categoryTotals,
        'progressTrend': _calculateProgressTrend(weekSessions),
        'recommendations': _generateRecommendations(weekSessions, categoryTotals),
      };
    } catch (e) {
      if (kDebugMode) {
        print('AAC Analytics: Error generating weekly report: $e');
      }
      return {'error': 'Unable to generate report'};
    }
  }

  /// Calculate progress trend
  static String _calculateProgressTrend(List<dynamic> sessions) {
    if (sessions.length < 2) return 'Insufficient data';
    
    final firstHalf = sessions.take(sessions.length ~/ 2);
    final secondHalf = sessions.skip(sessions.length ~/ 2);
    
    final firstHalfAvg = firstHalf.fold<double>(0, (sum, session) => 
        sum + (session['totalWords'] as int)) / firstHalf.length;
    final secondHalfAvg = secondHalf.fold<double>(0, (sum, session) => 
        sum + (session['totalWords'] as int)) / secondHalf.length;
    
    if (secondHalfAvg > firstHalfAvg * 1.1) return 'Improving';
    if (secondHalfAvg < firstHalfAvg * 0.9) return 'Declining';
    return 'Stable';
  }

  /// Generate therapeutic recommendations
  static List<String> _generateRecommendations(List<dynamic> sessions, Map<String, int> categories) {
    final recommendations = <String>[];
    
    // Session frequency
    if (sessions.length < 5) {
      recommendations.add('Try to use AAC daily for better language development');
    }
    
    // Session length
    final avgDuration = sessions.fold<double>(0, (sum, session) => 
        sum + (session['sessionDuration'] as int)) / sessions.length;
    if (avgDuration < 10) {
      recommendations.add('Aim for longer communication sessions (10+ minutes)');
    }
    
    // Category diversity
    if (categories.length < 3) {
      recommendations.add('Explore more vocabulary categories for diverse communication');
    }
    
    // Sentence complexity
    final totalSentences = sessions.fold<int>(0, (sum, session) => 
        sum + (session['totalSentences'] as int));
    final totalWords = sessions.fold<int>(0, (sum, session) => 
        sum + (session['totalWords'] as int));
    
    if (totalSentences > 0 && (totalWords / totalSentences) < 2) {
      recommendations.add('Practice combining words into longer sentences');
    }
    
    // If no issues found
    if (recommendations.isEmpty) {
      recommendations.add('Great progress! Continue regular AAC practice');
    }
    
    return recommendations;
  }

  /// Get language development milestones
  static Map<String, dynamic> getLanguageMilestones() {
    return {
      'currentLevel': _assessCurrentLevel(),
      'nextMilestone': _getNextMilestone(),
      'milestones': [
        {
          'level': 'Emerging Communicator',
          'description': 'Using single symbols to communicate basic needs',
          'goals': ['10+ different symbols used', '5+ communication attempts per session'],
        },
        {
          'level': 'Context-Dependent Communicator', 
          'description': 'Combining 2-3 symbols in familiar contexts',
          'goals': ['20+ different symbols used', '3+ two-word combinations per session'],
        },
        {
          'level': 'Independent Communicator',
          'description': 'Creating sentences across multiple contexts',
          'goals': ['50+ different symbols used', '5+ sentences per session'],
        },
        {
          'level': 'Generative Communicator',
          'description': 'Flexible language use across all communication functions',
          'goals': ['100+ symbols used', 'Complex sentences with grammar'],
        },
      ],
    };
  }

  /// Assess current communication level
  static String _assessCurrentLevel() {
    if (_symbolFrequency.length >= 100) return 'Generative Communicator';
    if (_symbolFrequency.length >= 50) return 'Independent Communicator';
    if (_symbolFrequency.length >= 20) return 'Context-Dependent Communicator';
    return 'Emerging Communicator';
  }

  /// Get next milestone
  static Map<String, dynamic> _getNextMilestone() {
    final currentLevel = _assessCurrentLevel();
    switch (currentLevel) {
      case 'Emerging Communicator':
        return {
          'target': 'Context-Dependent Communicator',
          'requirements': 'Use 20+ different symbols and create 2-word combinations',
          'progress': (_symbolFrequency.length / 20).clamp(0.0, 1.0),
        };
      case 'Context-Dependent Communicator':
        return {
          'target': 'Independent Communicator', 
          'requirements': 'Use 50+ different symbols and create sentences',
          'progress': (_symbolFrequency.length / 50).clamp(0.0, 1.0),
        };
      case 'Independent Communicator':
        return {
          'target': 'Generative Communicator',
          'requirements': 'Use 100+ symbols with complex grammar',
          'progress': (_symbolFrequency.length / 100).clamp(0.0, 1.0),
        };
      default:
        return {
          'target': 'Continued Growth',
          'requirements': 'Maintain and expand language skills',
          'progress': 1.0,
        };
    }
  }

  /// End session and save data
  static Future<void> endSession() async {
    if (_sessionStart != null) {
      await saveSessionData();
      if (kDebugMode) {
        print('AAC Analytics: Session ended. Duration: ${DateTime.now().difference(_sessionStart!).inMinutes} minutes');
      }
    }
  }
}
