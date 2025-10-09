import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/symbol.dart' as models; // Use alias to avoid conflicts
import 'supabase/supabase_config.dart';
import 'supabase_aac_service_compatible.dart';

/// Hybrid Icon Service - Local-First with Supabase Sync
/// This service implements the local-first approach where:
/// 1. Icons are always available locally (assets/symbols/)
/// 2. Supabase provides backup/sync functionality
/// 3. App works offline with local assets
/// 4. Syncs with Supabase when available
class HybridIconService {
  static const String _tag = 'HybridIconService';
  
  /// Local default symbols - always available offline
  static final List<models.Symbol> _localDefaultSymbols = [
    // Food & Drinks - Most essential symbols first
    models.Symbol(
      id: 'local_apple',
      label: 'Apple',
      imagePath: 'assets/symbols/Apple.png',
      category: 'Food & Drinks',
      description: 'Red apple fruit for eating',
      isDefault: true,
    ),
    models.Symbol(
      id: 'local_water',
      label: 'Water', 
      imagePath: 'assets/symbols/Water.png',
      category: 'Food & Drinks',
      description: 'Glass of water to drink',
      isDefault: true,
    ),
    models.Symbol(
      id: 'local_milk',
      label: 'Milk', 
      imagePath: 'assets/symbols/milk.png',
      category: 'Food & Drinks',
      description: 'Glass of milk to drink',
      isDefault: true,
    ),
    models.Symbol(
      id: 'local_bread',
      label: 'Bread', 
      imagePath: 'assets/symbols/bread.png',
      category: 'Food & Drinks',
      description: 'Slice of bread to eat',
      isDefault: true,
    ),
    models.Symbol(
      id: 'local_banana',
      label: 'Banana', 
      imagePath: 'assets/symbols/banana.png',
      category: 'Food & Drinks',
      description: 'Yellow banana fruit',
      isDefault: true,
    ),
    models.Symbol(
      id: 'local_orange',
      label: 'Orange', 
      imagePath: 'assets/symbols/orange.png',
      category: 'Food & Drinks',
      description: 'Orange citrus fruit',
      isDefault: true,
    ),

    // Vehicles
    models.Symbol(
      id: 'local_car',
      label: 'Car',
      imagePath: 'assets/symbols/Car.png', 
      category: 'Vehicles',
      description: 'Family car for transportation',
      isDefault: true,
    ),
    models.Symbol(
      id: 'local_bus',
      label: 'Bus',
      imagePath: 'assets/symbols/bus.png', 
      category: 'Vehicles',
      description: 'Public bus transportation',
      isDefault: true,
    ),
    models.Symbol(
      id: 'local_train',
      label: 'Train',
      imagePath: 'assets/symbols/train.png', 
      category: 'Vehicles',
      description: 'Train for long distance',
      isDefault: true,
    ),
    models.Symbol(
      id: 'local_airplane',
      label: 'Airplane',
      imagePath: 'assets/symbols/airplane.png', 
      category: 'Vehicles',
      description: 'Airplane for flying',
      isDefault: true,
    ),

    // Emotions
    models.Symbol(
      id: 'local_happy',
      label: 'Happy',
      imagePath: 'assets/symbols/happy.png', 
      category: 'Emotions',
      description: 'Feeling happy and joyful',
      isDefault: true,
    ),
    models.Symbol(
      id: 'local_sad',
      label: 'Sad',
      imagePath: 'assets/symbols/sad.png', 
      category: 'Emotions',
      description: 'Feeling sad or upset',
      isDefault: true,
    ),
    models.Symbol(
      id: 'local_angry',
      label: 'Angry',
      imagePath: 'assets/symbols/angry.png', 
      category: 'Emotions',
      description: 'Feeling angry or mad',
      isDefault: true,
    ),
    models.Symbol(
      id: 'local_excited',
      label: 'Excited',
      imagePath: 'assets/symbols/excited.png', 
      category: 'Emotions',
      description: 'Feeling excited and energetic',
      isDefault: true,
    ),

    // Actions
    models.Symbol(
      id: 'local_eat',
      label: 'Eat',
      imagePath: 'assets/symbols/eat.png', 
      category: 'Actions',
      description: 'Eating food',
      isDefault: true,
    ),
    models.Symbol(
      id: 'local_drink',
      label: 'Drink',
      imagePath: 'assets/symbols/drink.png', 
      category: 'Actions',
      description: 'Drinking liquid',
      isDefault: true,
    ),
    models.Symbol(
      id: 'local_sleep',
      label: 'Sleep',
      imagePath: 'assets/symbols/sleep.png', 
      category: 'Actions',
      description: 'Going to sleep or rest',
      isDefault: true,
    ),
    models.Symbol(
      id: 'local_play',
      label: 'Play',
      imagePath: 'assets/symbols/play.png', 
      category: 'Actions',
      description: 'Playing games or having fun',
      isDefault: true,
    ),

    // Family
    models.Symbol(
      id: 'local_mom',
      label: 'Mom',
      imagePath: 'assets/symbols/mom.png', 
      category: 'Family',
      description: 'Mother or mom',
      isDefault: true,
    ),
    models.Symbol(
      id: 'local_dad',
      label: 'Dad',
      imagePath: 'assets/symbols/dad.png', 
      category: 'Family',
      description: 'Father or dad',
      isDefault: true,
    ),
    models.Symbol(
      id: 'local_family',
      label: 'Family',
      imagePath: 'assets/symbols/family.png', 
      category: 'Family',
      description: 'Family members together',
      isDefault: true,
    ),

    // Basic Needs
    models.Symbol(
      id: 'local_home',
      label: 'Home',
      imagePath: 'assets/symbols/home.png', 
      category: 'Basic Needs',
      description: 'House or home',
      isDefault: true,
    ),
    models.Symbol(
      id: 'local_toilet',
      label: 'Toilet',
      imagePath: 'assets/symbols/toilet.png', 
      category: 'Basic Needs',
      description: 'Bathroom or toilet',
      isDefault: true,
    ),
    models.Symbol(
      id: 'local_help',
      label: 'Help',
      imagePath: 'assets/symbols/help.png', 
      category: 'Basic Needs',
      description: 'Need help or assistance',
      isDefault: true,
    ),
  ];

  /// Local default categories - always available offline
  static final List<models.Category> _localDefaultCategories = [
    models.Category(
      id: 'local_food',
      name: 'Food & Drinks',
      iconPath: 'assets/icons/food.png',
      colorCode: 0xFFFF6B6B,
      isDefault: true,
    ),
    models.Category(
      id: 'local_vehicles',
      name: 'Vehicles',
      iconPath: 'assets/icons/vehicles.png', 
      colorCode: 0xFF4ECDC4,
      isDefault: true,
    ),
    models.Category(
      id: 'local_emotions',
      name: 'Emotions',
      iconPath: 'assets/icons/emotions.png',
      colorCode: 0xFFFFE66D,
      isDefault: true,
    ),
    models.Category(
      id: 'local_actions',
      name: 'Actions',
      iconPath: 'assets/icons/actions.png',
      colorCode: 0xFF6C63FF,
      isDefault: true,
    ),
    models.Category(
      id: 'local_family',
      name: 'Family',
      iconPath: 'assets/icons/family.png',
      colorCode: 0xFFFF9F43,
      isDefault: true,
    ),
    models.Category(
      id: 'local_needs', 
      name: 'Basic Needs',
      iconPath: 'assets/icons/needs.png',
      colorCode: 0xFF51CF66,
      isDefault: true,
    ),
  ];

  /// Get all symbols using local-first approach
  static Future<List<models.Symbol>> getAllSymbols() async {
    try {
      // Always start with local symbols (offline-first)
      final List<models.Symbol> allSymbols = List.from(_localDefaultSymbols);
      
      // Try to enhance with Supabase data if available
      if (SupabaseConfig.isInitialized) {
        try {
          final supabaseSymbols = await _getSymbolsFromSupabase();
          
          // Merge: keep local symbols, add Supabase symbols that don't exist locally
          final localLabels = _localDefaultSymbols.map((s) => s.label).toSet();
          final newSupabaseSymbols = supabaseSymbols.where((s) => !localLabels.contains(s.label)).toList();
          
          allSymbols.addAll(newSupabaseSymbols);
          
          if (kDebugMode) {
            print('[$_tag] Loaded ${_localDefaultSymbols.length} local + ${newSupabaseSymbols.length} Supabase symbols');
          }
        } catch (e) {
          if (kDebugMode) {
            print('[$_tag] Supabase unavailable, using local symbols only: $e');
          }
        }
      }
      
      return allSymbols;
    } catch (e) {
      if (kDebugMode) {
        print('[$_tag] Error loading symbols, fallback to local only: $e');
      }
      return _localDefaultSymbols;
    }
  }

  /// Get all categories using local-first approach  
  static Future<List<models.Category>> getAllCategories() async {
    try {
      // Always start with local categories (offline-first)
      final List<models.Category> allCategories = List.from(_localDefaultCategories);
      
      // Try to enhance with Supabase data if available
      if (SupabaseConfig.isInitialized) {
        try {
          final supabaseCategories = await _getCategoriesFromSupabase();
          
          // Merge: keep local categories, add Supabase categories that don't exist locally
          final localNames = _localDefaultCategories.map((c) => c.name).toSet();
          final newSupabaseCategories = supabaseCategories.where((c) => !localNames.contains(c.name)).toList();
          
          allCategories.addAll(newSupabaseCategories);
          
          if (kDebugMode) {
            print('[$_tag] Loaded ${_localDefaultCategories.length} local + ${newSupabaseCategories.length} Supabase categories');
          }
        } catch (e) {
          if (kDebugMode) {
            print('[$_tag] Supabase unavailable, using local categories only: $e');
          }
        }
      }
      
      return allCategories;
    } catch (e) {
      if (kDebugMode) {
        print('[$_tag] Error loading categories, fallback to local only: $e');
      }
      return _localDefaultCategories;
    }
  }

  /// Get symbols for a specific category (local-first)
  static Future<List<models.Symbol>> getSymbolsByCategory(String categoryName) async {
    final allSymbols = await getAllSymbols();
    return allSymbols.where((symbol) => symbol.category == categoryName).toList();
  }

  /// Sync local symbols to Supabase (for backup/cross-device sync)
  static Future<void> syncToSupabase() async {
    if (!SupabaseConfig.isInitialized) {
      if (kDebugMode) {
        print('[$_tag] Supabase not initialized, skipping sync');
      }
      return;
    }

    try {
      final client = SupabaseConfig.client;
      
      // Sync categories first
      for (final category in _localDefaultCategories) {
        await client
            .from('global_default_categories')
            .upsert({
              'name': category.name,
              'color_code': category.colorCode,
              'sort_order': _localDefaultCategories.indexOf(category),
            })
            .match({'name': category.name});
      }
      
      // Sync symbols
      for (final symbol in _localDefaultSymbols) {
        await client
            .from('global_default_symbols')
            .upsert({
              'category_name': symbol.category,
              'label': symbol.label,
              'image_path': symbol.imagePath,
              'speech_text': symbol.label,
              'description': symbol.description,
            })
            .match({'label': symbol.label, 'category_name': symbol.category});
      }
      
      if (kDebugMode) {
        print('[$_tag] Successfully synced local defaults to Supabase');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[$_tag] Failed to sync to Supabase: $e');
      }
      // Don't throw - local-first means app continues working
    }
  }

  /// Get symbols from Supabase (private helper)
  static Future<List<models.Symbol>> _getSymbolsFromSupabase() async {
    final client = SupabaseConfig.client;
    
    final response = await client
        .from('global_default_symbols')
        .select();
        
    return (response as List<dynamic>).map((data) => models.Symbol(
      id: data['id'].toString(),
      label: data['label'] ?? '',
      imagePath: data['image_path'] ?? '',
      category: data['category_name'] ?? '',
      description: data['description'] ?? '',
      isDefault: true,
    )).toList();
  }

  /// Get categories from Supabase (private helper)
  static Future<List<models.Category>> _getCategoriesFromSupabase() async {
    final client = SupabaseConfig.client;
    
    final response = await client
        .from('global_default_categories')
        .select()
        .order('sort_order');
        
    return (response as List<dynamic>).map((data) => models.Category(
      id: data['id'].toString(),
      name: data['name'] ?? '',
      iconPath: data['icon_path'] ?? 'assets/icons/default.png',
      colorCode: data['color_code'] ?? 0xFF6C63FF,
      isDefault: true,
    )).toList();
  }

  /// Check if icon file exists locally (for asset validation)
  static bool hasLocalIcon(String imagePath) {
    return imagePath.startsWith('assets/symbols/') && 
           ['Apple.png', 'Water.png', 'Car.png'].any((file) => imagePath.contains(file));
  }

  /// Get fallback icon path if original not available
  static String getFallbackIconPath(String originalPath) {
    if (hasLocalIcon(originalPath)) {
      return originalPath;
    }
    // Fallback to first available local icon
    return 'assets/symbols/Apple.png';
  }

  /// Initialize the service with comprehensive Supabase features
  static Future<void> initialize() async {
    if (kDebugMode) {
      print('[$_tag] Initializing Hybrid Icon Service with Supabase integration...');
    }
    
    // Pre-load local symbols and categories
    await getAllSymbols();
    await getAllCategories();
    
    // Initialize Supabase features if user is authenticated
    await _initializeSupabaseFeatures();
    
    // Attempt background sync to Supabase if available
    Future.microtask(() => syncToSupabase());
    
    if (kDebugMode) {
      print('[$_tag] Hybrid Icon Service initialized successfully');
      print('[$_tag] Local-first architecture: ${_localDefaultSymbols.length} symbols, ${_localDefaultCategories.length} categories');
    }
  }
  
  /// Initialize comprehensive Supabase features
  static Future<void> _initializeSupabaseFeatures() async {
    try {
      if (!SupabaseConfig.isInitialized) {
        print('[$_tag] Supabase not initialized, skipping advanced features');
        return;
      }
      
      final currentUser = SupabaseAACService.currentUser;
      if (currentUser == null) {
        print('[$_tag] No authenticated user, skipping user-specific features');
        return;
      }
      
      // Ensure user profile exists
      await SupabaseAACService.upsertUserProfile(
        name: currentUser.userMetadata?['full_name'] ?? 'AAC User',
        email: currentUser.email,
      );
      
      // Get sync status
      final syncStatus = await SupabaseAACService.getSyncStatus();
      print('[$_tag] Supabase sync status: $syncStatus');
      
      // Setup real-time subscriptions for dynamic updates
      _setupRealTimeSubscriptions();
      
      print('[$_tag] Comprehensive Supabase features initialized');
    } catch (e) {
      print('[$_tag] Failed to initialize Supabase features: $e');
    }
  }
  
  /// Setup real-time subscriptions for favorites and communication
  static void _setupRealTimeSubscriptions() {
    try {
      // Subscribe to favorites updates
      SupabaseAACService.subscribeToFavorites().listen((favorites) {
        print('[$_tag] Received ${favorites.length} favorites updates');
        // Could trigger UI refresh or cache updates here
      });
      
      // Subscribe to communication history updates
      SupabaseAACService.subscribeToCommunicationHistory().listen((history) {
        print('[$_tag] Received communication history updates');
        // Could update recent phrases or analytics
      });
      
      print('[$_tag] Real-time subscriptions active');
    } catch (e) {
      print('[$_tag] Failed to setup real-time subscriptions: $e');
    }
  }

  // ============================================================================
  // SUPABASE INTEGRATION METHODS
  // ============================================================================

  /// Add symbol to Supabase favorites
  static Future<void> addToFavorites(String symbolLabel) async {
    try {
      if (!SupabaseConfig.isInitialized || SupabaseAACService.currentUser == null) {
        print('[$_tag] Cannot add to favorites: Supabase not available');
        return;
      }

      // Find symbol ID from local symbols
      final symbol = _localDefaultSymbols.firstWhere(
        (s) => s.label == symbolLabel,
        orElse: () => models.Symbol(
          id: 'unknown',
          label: symbolLabel,
          imagePath: 'assets/symbols/Apple.png',
          category: 'unknown',
        ),
      );

      if (symbol.id != null && symbol.id != 'unknown') {
        await SupabaseAACService.addToFavorites(symbol.id!);
        print('[$_tag] Added $symbolLabel to favorites');
      }
    } catch (e) {
      print('[$_tag] Failed to add to favorites: $e');
    }
  }

  /// Save communication phrase to history
  static Future<void> saveCommunicationPhrase(String phrase, List<String> symbolLabels) async {
    try {
      if (!SupabaseConfig.isInitialized || SupabaseAACService.currentUser == null) {
        print('[$_tag] Cannot save phrase: Supabase not available');
        return;
      }

      // Get symbol IDs for the labels
      final symbolIds = symbolLabels
          .map((label) {
            final symbol = _localDefaultSymbols.firstWhere(
              (s) => s.label == label,
              orElse: () => models.Symbol(
                id: 'unknown',
                label: label,
                imagePath: 'assets/symbols/Apple.png',
                category: 'unknown',
              ),
            );
            return symbol.id;
          })
          .where((id) => id != null && id != 'unknown')
          .cast<String>()
          .toList();

      await SupabaseAACService.saveCommunication(
        messageText: phrase,
        symbolsUsed: symbolIds,
        communicationType: 'phrase',
        contextInfo: {
          'symbol_labels': symbolLabels,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // Also save to phrase history
      await SupabaseAACService.savePhrase(text: phrase);

      print('[$_tag] Saved communication phrase: $phrase');
    } catch (e) {
      print('[$_tag] Failed to save communication: $e');
    }
  }

  /// Get user's favorite symbols from Supabase
  static Future<List<models.Symbol>> getFavoriteSymbols() async {
    try {
      if (!SupabaseConfig.isInitialized || SupabaseAACService.currentUser == null) {
        print('[$_tag] Cannot get favorites: Supabase not available');
        return [];
      }

      final favorites = await SupabaseAACService.getUserFavorites();
      final favoriteSymbols = <models.Symbol>[];

      for (final favorite in favorites) {
        // Try to find matching local symbol
        final localSymbol = _localDefaultSymbols.firstWhere(
          (s) => s.id == favorite['symbol_id'],
          orElse: () => models.Symbol(
            id: favorite['symbol_id'] ?? 'unknown',
            label: favorite['symbols']?['label'] ?? 'Unknown',
            imagePath: favorite['symbols']?['image_path'] ?? 'assets/symbols/Apple.png',
            category: favorite['symbols']?['category_name'] ?? 'Unknown',
            description: favorite['symbols']?['description'],
            speechText: favorite['symbols']?['speech_text'],
          ),
        );

        favoriteSymbols.add(localSymbol);
      }

      print('[$_tag] Retrieved ${favoriteSymbols.length} favorite symbols');
      return favoriteSymbols;
    } catch (e) {
      print('[$_tag] Failed to get favorites: $e');
      return [];
    }
  }

  /// Get recent communication phrases
  static Future<List<String>> getRecentPhrases({int limit = 10}) async {
    try {
      if (!SupabaseConfig.isInitialized || SupabaseAACService.currentUser == null) {
        print('[$_tag] Cannot get recent phrases: Supabase not available');
        return [];
      }

      final phraseHistory = await SupabaseAACService.getPhraseHistory();
      final recentPhrases = phraseHistory
          .take(limit)
          .map((phrase) => phrase['text'].toString())
          .toList();

      print('[$_tag] Retrieved ${recentPhrases.length} recent phrases');
      return recentPhrases;
    } catch (e) {
      print('[$_tag] Failed to get recent phrases: $e');
      return [];
    }
  }

  /// Create custom symbol in Supabase
  static Future<models.Symbol?> createCustomSymbol({
    required String label,
    required String imagePath,
    required String category,
    String? description,
    String? speechText,
  }) async {
    try {
      if (!SupabaseConfig.isInitialized || SupabaseAACService.currentUser == null) {
        print('[$_tag] Cannot create custom symbol: Supabase not available');
        return null;
      }

      final customSymbol = await SupabaseAACService.createCustomSymbol(
        label: label,
        imagePath: imagePath,
        description: description,
        speechText: speechText,
      );

      final symbol = models.Symbol(
        id: customSymbol['id'],
        label: customSymbol['label'],
        imagePath: customSymbol['image_path'] ?? imagePath,
        category: category,
        description: customSymbol['description'],
        speechText: customSymbol['speech_text'],
        isDefault: false,
      );

      print('[$_tag] Created custom symbol: $label');
      return symbol;
    } catch (e) {
      print('[$_tag] Failed to create custom symbol: $e');
      return null;
    }
  }

  /// Get sync status and analytics
  static Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      if (!SupabaseConfig.isInitialized || SupabaseAACService.currentUser == null) {
        return {
          'status': 'offline',
          'local_symbols': _localDefaultSymbols.length,
          'local_categories': _localDefaultCategories.length,
        };
      }

      final syncStatus = await SupabaseAACService.getSyncStatus();
      syncStatus['local_symbols'] = _localDefaultSymbols.length;
      syncStatus['local_categories'] = _localDefaultCategories.length;
      syncStatus['status'] = 'online';

      return syncStatus;
    } catch (e) {
      print('[$_tag] Failed to get sync status: $e');
      return {
        'status': 'error',
        'error': e.toString(),
        'local_symbols': _localDefaultSymbols.length,
        'local_categories': _localDefaultCategories.length,
      };
    }
  }
}