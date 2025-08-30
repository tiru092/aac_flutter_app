import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

/// Service for fetching ARASAAC pictograms
/// API Documentation: https://arasaac.org/developers/api
class ArasaacService {
  static const String _baseUrl = 'https://api.arasaac.org/api';
  static const String _cdnUrl = 'https://static.arasaac.org/pictograms';
  
  // Cache for pictogram URLs to improve performance
  static final Map<String, String> _urlCache = {};
  static final Map<String, Uint8List> _imageCache = {};

  /// Search pictograms by keyword
  /// Returns a list of pictogram IDs that match the search term
  static Future<List<int>> searchPictograms(String keyword, {String locale = 'en'}) async {
    try {
      final url = Uri.parse('$_baseUrl/pictograms/$locale/search/$keyword');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map<int>((item) => item['_id'] as int).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error searching ARASAAC pictograms: $e');
      return [];
    }
  }

  /// Get pictogram URL for a specific ID
  /// Returns the direct URL to the pictogram image
  static String getPictogramUrl(int pictogramId, {bool color = true, int size = 300}) {
    final cacheKey = '${pictogramId}_${color}_$size';
    if (_urlCache.containsKey(cacheKey)) {
      return _urlCache[cacheKey]!;
    }
    
    final url = '$_cdnUrl/$pictogramId/$pictogramId\_$size.png';
    _urlCache[cacheKey] = url;
    return url;
  }

  /// Get pictogram image data
  /// Returns the actual image bytes for caching
  static Future<Uint8List?> getPictogramImage(int pictogramId, {bool color = true, int size = 300}) async {
    final cacheKey = '${pictogramId}_${color}_$size';
    if (_imageCache.containsKey(cacheKey)) {
      return _imageCache[cacheKey];
    }

    try {
      final url = getPictogramUrl(pictogramId, color: color, size: size);
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final imageData = response.bodyBytes;
        _imageCache[cacheKey] = imageData;
        return imageData;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching ARASAAC pictogram image: $e');
      return null;
    }
  }

  /// Get the best pictogram for a goal category
  /// Returns a pictogram ID that best represents the category
  static Future<int?> getPictogramForGoalCategory(String category) async {
    final searchTerms = {
      'communication': ['speak', 'talk', 'mouth', 'speech'],
      'social': ['friends', 'people', 'share', 'together'],
      'dailyLiving': ['home', 'daily', 'routine', 'life'],
      'learning': ['book', 'learn', 'study', 'school'],
      'emotional': ['feelings', 'emotion', 'happy', 'heart'],
      'routine': ['calendar', 'schedule', 'time', 'daily'],
    };

    final terms = searchTerms[category.toLowerCase()] ?? ['goal'];
    
    for (final term in terms) {
      final results = await searchPictograms(term);
      if (results.isNotEmpty) {
        return results.first;
      }
    }
    return null;
  }

  /// Get pictogram for specific goal titles
  /// Maps common goal phrases to appropriate pictograms
  static Future<int?> getPictogramForGoalTitle(String title) async {
    final keywords = _extractKeywords(title.toLowerCase());
    
    for (final keyword in keywords) {
      final results = await searchPictograms(keyword);
      if (results.isNotEmpty) {
        return results.first;
      }
    }
    return null;
  }

  /// Extract meaningful keywords from goal titles
  static List<String> _extractKeywords(String title) {
    final keywordMap = {
      'please': ['please'],
      'thank': ['thank'],
      'feel': ['feelings', 'emotion'],
      'happy': ['happy'],
      'sad': ['sad'],
      'help': ['help'],
      'share': ['share'],
      'friend': ['friends'],
      'words': ['speak', 'talk'],
      'communicate': ['speak'],
      'routine': ['routine'],
      'daily': ['daily'],
      'practice': ['practice'],
      'learn': ['learn'],
    };

    final keywords = <String>[];
    for (final entry in keywordMap.entries) {
      if (title.contains(entry.key)) {
        keywords.addAll(entry.value);
      }
    }
    
    // If no specific keywords found, try basic search terms
    if (keywords.isEmpty) {
      final words = title.split(' ');
      keywords.addAll(words.where((word) => word.length > 3));
    }
    
    return keywords;
  }

  /// Default goal pictograms - pre-selected quality pictograms for common goals
  static Map<String, int> get defaultGoalPictograms => {
    'communication': 2419, // Speech bubble
    'social': 2425,        // Friends/people
    'dailyLiving': 11975,  // House/home
    'learning': 2427,      // Book
    'emotional': 2424,     // Heart/feelings
    'routine': 2426,       // Calendar
    'speak': 2419,         // Mouth/speaking
    'help': 2420,          // Help gesture
    'share': 2421,         // Sharing
    'practice': 2422,      // Practice/exercise
    'goal': 2423,          // Target/goal
  };

  /// Get attribution text for ARASAAC usage
  static String get attributionText => 
      'Pictograms from ARASAAC (arasaac.org) - Creative Commons License';

  /// Clear cache to free memory
  static void clearCache() {
    _urlCache.clear();
    _imageCache.clear();
  }
}
