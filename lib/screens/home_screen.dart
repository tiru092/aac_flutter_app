import 'dart:async';
import 'package:flutter/foundation.dart' as foundation hide Category;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/communication_grid.dart';
import '../widgets/quick_phrases_bar.dart';
import '../models/symbol.dart';
import '../utils/aac_helper.dart';
import '../utils/sample_data.dart';
import '../services/user_profile_service.dart';
import '../screens/enhanced_goals_screen.dart';
import '../screens/aac_learning_goals_screen.dart';
import '../screens/professional_therapeutic_goals_screen.dart';
import '../screens/professional_communication_coach_screen.dart';
import '../screens/favorites_screen.dart';
import '../services/favorites_service.dart';
import '../services/secure_encryption_service.dart';
import '../services/aac_analytics_service.dart';
import 'accessibility_settings_screen.dart';
import 'add_symbol_screen.dart';
import 'profile_screen.dart';
import 'subscription_screen.dart';
// REMOVED: 'practice_goals_screen.dart' - File deleted due to compilation errors
// import '../widgets/arasaac_asterisk_grid.dart'; // Temporarily disabled for performance testing

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Symbol> _selectedSymbols = [];
  List<Symbol> _allSymbols = [];
  List<Symbol> _filteredSymbols = []; // Add filtered symbols for search
  List<Category> _categories = [];
  List<Category> _customCategories = [];
  final List<String> _goals = [
    'Say "hello" to a friend',
    'Ask for a drink',
    'Express an emotion',
    'Practice saying my name'
  ];
  bool _isLoading = true;
  bool _showQuickPhrases = false;
  bool _showSpeechControls = false;
  String _currentCategory = 'All'; // Track current category
  String? _errorMessage; // Add error message state
  bool _servicesInitialized = false; // Track service initialization
  String _searchQuery = ''; // Add search query state
  final TextEditingController _searchController = TextEditingController(); // Add search controller
  
  // Favorites service for tracking user preferences
  final FavoritesService _favoritesService = FavoritesService();
  
  // Speech control values
  double _speechRate = 0.5;
  double _speechPitch = 1.2;
  double _speechVolume = 1.0;

  @override
  void initState() {
    super.initState();
    // Initialize filtered symbols
    _filteredSymbols = _allSymbols;
    // Load data synchronously for immediate responsiveness
    _initializeImmediately();
    // Load user data asynchronously
    _loadDataAsync();
  }

  void _initializeImmediately() {
    // Load sample data immediately - no async operations
    _allSymbols = SampleData.getSampleSymbols();
    _categories = SampleData.getSampleCategories();
    // Don't initialize _customCategories here - let it be loaded from user data
    _isLoading = false;
    _servicesInitialized = true; // Enable all UI interactions immediately
    
    // Load speech settings synchronously
    _speechRate = 0.5;
    _speechPitch = 1.2;
    _speechVolume = 1.0;
    
    // Initialize services much later, completely in background
    Timer(Duration(milliseconds: 100), () {
      _initializeServicesAsync();
    });
    
    // Initialize services even later
    Timer(Duration(seconds: 3), () {
      _initializeServicesVeryLate();
    });
  }

  void _initializeServicesVeryLate() async {
    // This runs much later when UI is fully settled
    try {
      // Initialize Firebase
      try {
        await Firebase.initializeApp().timeout(Duration(seconds: 5));
        debugPrint('Firebase initialized (background)');
      } catch (e) {
        debugPrint('Firebase skipped: $e');
      }
      
      // Initialize SharedPreferences  
      try {
        await SharedPreferences.getInstance();
        debugPrint('SharedPreferences initialized (background)');
      } catch (e) {
        debugPrint('SharedPreferences skipped: $e');
      }
      
      // Initialize encryption
      try {
        await SecureEncryptionService().initialize();
        debugPrint('Encryption initialized (background)');
      } catch (e) {
        debugPrint('Encryption skipped: $e');
      }
      
      // Initialize database  
      try {
        await AACHelper.initializeDatabase();
        debugPrint('Database initialized (background)');
      } catch (e) {
        debugPrint('Database skipped: $e');
      }
      
      // Initialize TTS
      try {
        await AACHelper.initializeTTS();
        debugPrint('TTS initialized (background)');
      } catch (e) {
        debugPrint('TTS skipped: $e');
      }
      
      // Initialize AAC Analytics Service
      try {
        await AACAnalyticsService().initialize();
        debugPrint('AAC Analytics Service initialized (background)');
      } catch (e) {
        debugPrint('AAC Analytics Service skipped: $e');
      }
      
      // Initialize Favorites Service
      try {
        await _favoritesService.initialize();
        debugPrint('Favorites Service initialized (background)');
      } catch (e) {
        debugPrint('Favorites Service skipped: $e');
      }
      
      debugPrint('All background services completed');
    } catch (e) {
      debugPrint('Background initialization error: $e');
    }
  }

  // Initialize all heavy services asynchronously after UI is shown
  Future<void> _initializeServicesAsync() async {
    // Use Future.microtask to ensure this runs after the build
    await Future.microtask(() async {
      try {
        debugPrint('HomeScreen: Starting async service initialization...');
        
        // Initialize Firebase (optional)
        try {
          await Future.any([
            Firebase.initializeApp(),
            Future.delayed(const Duration(seconds: 2))
          ]);
          debugPrint('HomeScreen: Firebase initialized successfully');
        } catch (e) {
          debugPrint('HomeScreen: Firebase initialization failed: $e');
        }
        
        // Initialize SharedPreferences
        try {
          await SharedPreferences.getInstance();
          debugPrint('HomeScreen: SharedPreferences initialized');
        } catch (e) {
          debugPrint('HomeScreen: SharedPreferences initialization failed: $e');
        }
        
        // Initialize SecureEncryptionService
        try {
          await SecureEncryptionService().initialize();
          debugPrint('HomeScreen: SecureEncryptionService initialized');
        } catch (e) {
          debugPrint('HomeScreen: SecureEncryptionService initialization failed: $e');
        }
        
        // Initialize database
        try {
          await AACHelper.initializeDatabase();
          debugPrint('HomeScreen: Database initialized');
        } catch (e) {
          debugPrint('HomeScreen: Database initialization failed: $e');
        }
        
        // Initialize TTS
        try {
          await AACHelper.initializeTTS();
          debugPrint('HomeScreen: TTS initialized');
        } catch (e) {
          debugPrint('HomeScreen: TTS initialization failed: $e');
        }
        
        // Mark services as initialized
        if (mounted) {
          setState(() {
            _servicesInitialized = true;
          });
          // Don't load data here - let user interaction trigger it
        }
        
        debugPrint('HomeScreen: All services initialized successfully');
      } catch (e) {
        debugPrint('HomeScreen: Error during service initialization: $e');
        if (mounted) {
          setState(() {
            _servicesInitialized = true; // Continue even with errors
          });
          // Don't load data automatically - let user interaction trigger it
        }
      }
    });
  }

  // Load minimal data to show UI quickly
  Future<void> _loadMinimalData() async {
    try {
      // Load sample data to show UI immediately
      final sampleSymbols = SampleData.getSampleSymbols();
      final sampleCategories = SampleData.getSampleCategories();
      
      if (mounted) {
        setState(() {
          _allSymbols = sampleSymbols;
          _categories = sampleCategories;
          // Don't override _customCategories here - let it be loaded from user data
          _isLoading = false;
        });
      }
      
      // Load speech settings
      _loadSpeechSettings();
    } catch (e) {
      debugPrint('Error loading minimal data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading data: $e';
        });
      }
    }
  }

  // Asynchronous data loading that won't block UI
  Future<void> _loadDataAsync() async {
    try {
      // First, quickly update UI with minimal loading state
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }
      
      // Use an isolate-like approach - yield control back to UI thread frequently
      await Future.delayed(Duration(milliseconds: 10)); // Let UI update
      
      // Load data in chunks to avoid blocking UI
      final defaultCategories = SampleData.getSampleCategories();
      await Future.delayed(Duration(milliseconds: 5)); // Yield to UI
      
      final defaultSymbols = SampleData.getSampleSymbols();
      await Future.delayed(Duration(milliseconds: 5)); // Yield to UI
      
      // Update UI with loaded data
      if (mounted) {
        setState(() {
          _categories = defaultCategories;
          // Don't override _customCategories here - let it be loaded from user data
          _allSymbols = defaultSymbols;
          _isLoading = false;
        });
      }
      
      // Load speech settings in background
      await Future.delayed(Duration(milliseconds: 10)); // Yield to UI
      _loadSpeechSettings();
      
      // Load database data in background without blocking UI
      _loadDatabaseDataInBackground();
      
    } catch (e) {
      debugPrint('Error in _loadDataAsync: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading data: Using sample data only';
          _isLoading = false;
          // Fallback to sample data
          _categories = SampleData.getSampleCategories();
          _allSymbols = SampleData.getSampleSymbols();
        });
      }
    }
  }

  // Load database data in background without blocking UI
  void _loadDatabaseDataInBackground() {
    Future.microtask(() async {
      try {
        // Add small delays between each operation to prevent UI blocking
        await Future.delayed(Duration(milliseconds: 100));
        
        // Load profile data
        final profile = await UserProfileService.getActiveProfile();
        await Future.delayed(Duration(milliseconds: 50));
        
        // Load categories and symbols from user profile
        final dbCategories = profile?.userCategories ?? [];
        final dbSymbols = profile?.userSymbols ?? [];
        await Future.delayed(Duration(milliseconds: 50));
        
        // Update UI with database data if available
        if (mounted && (dbCategories.isNotEmpty || dbSymbols.isNotEmpty)) {
          setState(() {
            // Combine default symbols with user's custom symbols (don't replace)
            if (dbSymbols.isNotEmpty) {
              // Get default symbols
              final defaultSymbols = SampleData.getSampleSymbols();
              // Filter out any user symbols that might duplicate defaults (by ID)
              final customSymbols = dbSymbols.where((userSymbol) => 
                !defaultSymbols.any((defaultSymbol) => defaultSymbol.id == userSymbol.id)
              ).toList();
              // Combine: defaults + custom symbols
              _allSymbols = [...defaultSymbols, ...customSymbols];
            }
          });
        }
        
        // Load custom categories separately
        await Future.delayed(Duration(milliseconds: 50));
        final customCategories = dbCategories.where((cat) => !cat.isDefault).toList();
        if (mounted && customCategories.isNotEmpty) {
          setState(() {
            _customCategories = customCategories;
          });
        }
        
      } catch (e) {
        debugPrint('Background database loading error: $e');
        // Don't update UI with error - just continue with sample data
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear any previous errors
    });
    
    try {
      // Load default sample data only - skip user data to avoid encryption issues
      final defaultCategories = SampleData.getSampleCategories();
      final defaultSymbols = SampleData.getSampleSymbols();
      
      // Use only sample data to avoid encryption errors
      setState(() {
        _categories = defaultCategories;
        // Don't override _customCategories here - let it be loaded from user data
        _allSymbols = defaultSymbols;
        _isLoading = false;
      });
      
      // Load speech settings with fallback defaults
      _loadSpeechSettings();
    } catch (e) {
      print('Error in _loadData: $e');
      setState(() {
        _errorMessage = 'Error loading data: Using sample data only';
        _isLoading = false;
        // Fallback to just sample data
        _categories = SampleData.getSampleCategories();
        _allSymbols = SampleData.getSampleSymbols();
        // Don't override _customCategories here - let it be loaded from user data
      });
    }
  }
  
  void _loadSpeechSettings() {
    try {
      // Load speech settings asynchronously without blocking UI
      Future.delayed(Duration.zero, () {
        if (mounted) {
          setState(() {
            _speechRate = AACHelper.speechRate;
            _speechPitch = AACHelper.speechPitch;
            _speechVolume = AACHelper.speechVolume;
          });
        }
      });
    } catch (e) {
      print('Error loading speech settings: $e');
      // Use default values if loading fails
      if (mounted) {
        setState(() {
          _speechRate = 0.5;
          _speechPitch = 1.2;
          _speechVolume = 1.0;
        });
      }
    }
  }
  
  // Refresh custom categories from user profile
  void _refreshCustomCategories() async {
    try {
      final profile = await UserProfileService.getActiveProfile();
      if (profile != null && mounted) {
        final customCategories = profile.userCategories.where((cat) => !cat.isDefault).toList();
        setState(() {
          _customCategories = customCategories;
        });
      }
    } catch (e) {
      debugPrint('Error refreshing custom categories: $e');
    }
  }
  
  List<Symbol> _getFilteredSymbols() {
    try {
      List<Symbol> baseSymbols;
      
      // First filter by category
      if (_currentCategory == 'All') {
        baseSymbols = _allSymbols;
      } else {
        baseSymbols = _allSymbols.where((symbol) => symbol.category == _currentCategory).toList();
      }
      
      // Then filter by search query
      if (_searchQuery.isEmpty) {
        return baseSymbols;
      } else {
        return baseSymbols.where((symbol) {
          return symbol.label.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 (symbol.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                 symbol.category.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();
      }
    } catch (e) {
      print('Error filtering symbols: $e');
      return _allSymbols; // Return all symbols if filtering fails
    }
  }
  
  void _changeCategory(String category) {
    try {
      setState(() {
        _currentCategory = category;
      });
    } catch (e) {
      print('Error changing category: $e');
      // Show error to user
      _showErrorDialog('Failed to change category');
    }
  }

  // CRITICAL: Symbol tap functionality - Add to sentence ONLY (no async operations)
  void _onSymbolTap(Symbol symbol) {
    try {
      // ONLY add symbol to sentence - no async operations that can block UI
      setState(() {
        _selectedSymbols.add(symbol);
      });
      
      // Try to speak in background, don't wait for it
      _trySpeak(symbol.label);
      
      // Record usage in favorites (non-blocking)
      _recordSymbolUsage(symbol);
    } catch (e) {
      print('Error in symbol tap: $e');
      // Even if setState fails, don't block UI
    }
  }

  // Record symbol usage in favorites (non-blocking background operation)
  void _recordSymbolUsage(Symbol symbol, {String action = 'tapped'}) {
    // Don't await this - let it run in background
    () async {
      try {
        await _favoritesService.recordUsage(symbol, action: action);
      } catch (e) {
        // Ignore errors - don't block UI
        print('Favorites recording failed (ignored): $e');
      }
    }();
  }

  // Non-blocking speak attempt
  void _trySpeak(String text) {
    // Don't await this - let it run in background
    () async {
      try {
        await AACHelper.speak(text);
      } catch (e) {
        // Ignore speech errors - don't block UI
        print('Speech failed (ignored): $e');
      }
    }();
  }

  void _speakSentence() {
    try {
      if (_selectedSymbols.isNotEmpty) {
        final sentence = _selectedSymbols.map((s) => s.label).join(' ');
        _trySpeak(sentence);
        
        // Record each symbol as spoken in a sentence (non-blocking)
        for (final symbol in _selectedSymbols) {
          _recordSymbolUsage(symbol, action: 'spoken');
        }
      }
    } catch (e) {
      print('Error in speak sentence: $e');
    }
  }

  void _clearSentence() {
    try {
      setState(() {
        _selectedSymbols.clear();
      });
    } catch (e) {
      print('Error clearing sentence: $e');
      _showErrorDialog('Failed to clear sentence');
    }
  }

  void _removeSymbolAt(int index) {
    try {
      if (index >= 0 && index < _selectedSymbols.length) {
        setState(() {
          _selectedSymbols.removeAt(index);
        });
      }
    } catch (e) {
      print('Error removing symbol: $e');
      _showErrorDialog('Failed to remove symbol');
    }
  }

  void _onQuickPhraseSpeak(String phrase) {
    try {
      _trySpeak(phrase);
    } catch (e) {
      print('Error in quick phrase speak: $e');
    }
  }
  
  // Handle symbol update from edit dialog
  void _onSymbolUpdate(Symbol updatedSymbol) {
    try {
      print('DEBUG: _onSymbolUpdate called with symbol ID: ${updatedSymbol.id}');
      print('DEBUG: Updated symbol label: ${updatedSymbol.label}');
      print('DEBUG: Updated symbol image path: ${updatedSymbol.imagePath}');
      
      setState(() {
        // Find and replace the symbol in _allSymbols
        final index = _allSymbols.indexWhere((s) => s.id == updatedSymbol.id);
        print('DEBUG: Found symbol at index: $index');
        if (index != -1) {
          print('DEBUG: Old symbol: ${_allSymbols[index].label} - ${_allSymbols[index].imagePath}');
          _allSymbols[index] = updatedSymbol;
          print('DEBUG: New symbol: ${_allSymbols[index].label} - ${_allSymbols[index].imagePath}');
        } else {
          print('DEBUG: Symbol not found in _allSymbols list!');
        }
      });
      
      // Show success message
      _trySpeak('Symbol updated successfully');
      print('DEBUG: Symbol update completed successfully');
    } catch (e) {
      print('Error updating symbol: $e');
      _showErrorDialog('Failed to update symbol');
    }
  }
  
  // Handle symbol deletion from edit dialog
  void _onSymbolDelete(Symbol deletedSymbol) {
    try {
      setState(() {
        // Remove the symbol from _allSymbols
        _allSymbols.removeWhere((s) => s.id == deletedSymbol.id);
      });
      
      // Show success message
      _trySpeak('Symbol deleted successfully');
    } catch (e) {
      print('Error deleting symbol: $e');
      _showErrorDialog('Failed to delete symbol');
    }
  }

  void _toggleQuickPhrases() {
    try {
      setState(() {
        _showQuickPhrases = !_showQuickPhrases;
      });
    } catch (e) {
      print('Error toggling quick phrases: $e');
      _showErrorDialog('Failed to toggle quick phrases');
    }
  }
  
  void _toggleSpeechControls() {
    try {
      setState(() {
        _showSpeechControls = !_showSpeechControls;
      });
    } catch (e) {
      print('Error toggling speech controls: $e');
      _showErrorDialog('Failed to toggle speech controls');
    }
  }

  void _showMenuOptions() {
    try {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: const Text(
            'Menu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          message: const Text('Access app features and settings'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _toggleQuickPhrases();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.chat_bubble_2_fill,
                    color: _showQuickPhrases ? Color(0xFF4ECDC4) : Colors.grey[600],
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    _showQuickPhrases ? 'Hide Quick Phrases' : 'Show Quick Phrases',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _toggleSpeechControls();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.waveform,
                    color: _showSpeechControls ? Color(0xFF4ECDC4) : Colors.grey[600],
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    _showSpeechControls ? 'Hide Speech Controls' : 'Show Speech Controls',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _openInteractiveFun();
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.person_2_alt,
                    color: Color(0xFF6C63FF),
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Communication Coach',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _openSettings();
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.settings,
                    color: Colors.grey,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.destructiveRed,
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      print('Error showing menu options: $e');
      _showErrorDialog('Failed to show menu options');
    }
  }

  void _showProfileSwitcher() async {
    try {
      // Get all available profiles
      final profiles = await UserProfileService.getAllProfiles();
      final currentProfile = await UserProfileService.getActiveProfile();
      
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: const Text('Settings'),
          message: const Text('Configure your AAC app settings'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.person_crop_circle_badge_plus,
                    color: Color(0xFF4ECDC4),
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Manage Profiles',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => const SubscriptionScreen(),
                  ),
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.sparkles,
                    color: Color(0xFFFFD700),
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Subscription',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Goals option removed as per requirements
            // CupertinoActionSheetAction(
            //   onPressed: () {
            //     Navigator.pop(context);
            //     Navigator.push(
            //       context,
            //       CupertinoPageRoute(
            //         builder: (context) => const EnhancedGoalsScreen(),
            //       ),
            //     );
            //   },
            //   child: const Row(
            //     mainAxisAlignment: MainAxisAlignment.center,
            //     children: [
            //       Icon(
            //         CupertinoIcons.flag,
            //         color: Color(0xFF4ECDC4),
            //         size: 24,
            //       ),
            //       SizedBox(width: 12),
            //       Text(
            //         'Goals & Progress',
            //         style: TextStyle(
            //           fontSize: 16,
            //           fontWeight: FontWeight.w600,
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => const AccessibilitySettingsScreen(),
                  ),
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.settings,
                    color: Color(0xFF6C63FF),
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Accessibility Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    } on AACException catch (e) {
      print('AAC Error showing profile switcher: $e');
      _showErrorDialog('Failed to show profile switcher: ${e.message}');
    } catch (e) {
      print('Unexpected error showing profile switcher: $e');
      _showErrorDialog('Failed to show profile switcher');
    }
  }

  // Show error dialog to user
  void _showErrorDialog(String message) {
    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  void _openSettings() {
    _showProfileSwitcher();
  }

  void _openGoalsScreen() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const FavoritesScreen(),
      ),
    );
  }

  void _openInteractiveFun() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const ProfessionalCommunicationCoachScreen(),
      ),
    );
  }

  // Helper methods for responsive design
  double _getResponsiveTextSize(BuildContext context, {required double baseSize, required double maxSize}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;
    
    if (isLandscape) {
      // In landscape, use smaller text to save vertical space
      return (screenWidth * 0.018).clamp(baseSize * 0.75, maxSize * 0.8);
    } else {
      // In portrait, use normal responsive sizing
      return (screenWidth * 0.035).clamp(baseSize, maxSize);
    }
  }

  double _getResponsiveIconSize(BuildContext context, {required double baseSize}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;
    
    if (isLandscape) {
      // In landscape, optimize for height and make buttons smaller
      return (screenHeight * 0.03).clamp(baseSize * 0.6, baseSize * 0.9);
    } else {
      // In portrait, optimize for width
      return (screenWidth * 0.06).clamp(baseSize, baseSize * 1.5);
    }
  }

  EdgeInsets _getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;
    
    if (isLandscape) {
      // Tighter padding in landscape to maximize usable space
      return EdgeInsets.symmetric(horizontal: screenWidth * 0.02, vertical: 4);
    } else {
      // More generous padding in portrait
      return EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: 8);
    }
  }

  BoxConstraints _getSentenceBarConstraints(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape = screenWidth > screenHeight;
    
    if (isLandscape) {
      // In landscape, keep sentence bar very compact - around 10% of height
      return BoxConstraints(
        maxHeight: screenHeight * 0.10, // Reduced from 15% to 10%
        minHeight: 45, // Reduced minimum height
      );
    } else {
      // In portrait, keep to 12% of height instead of 15%
      return BoxConstraints(
        maxHeight: screenHeight * 0.12, // Reduced from 15% to 12% 
        minHeight: 50,
      );
    }
  }
  
  // Helper method for responsive action bar height (speak/clear buttons) - made more compact
  double _getResponsiveActionBarHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape = screenWidth > screenHeight;
    
    // Much smaller action bar in landscape to save space
    if (isLandscape) {
      return screenHeight * 0.05; // Reduced from 6% to 5% of screen height in landscape
    } else {
      return screenHeight * 0.06; // Reduced from 7% to 6% of screen height in portrait  
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug: log screen metrics and state to help diagnose missing speak bar / extra buttons on device
    try {
      final w = MediaQuery.of(context).size.width;
      debugPrint('HomeScreen.build: width=$w, selectedSymbols=${_selectedSymbols.length}, servicesInitialized=$_servicesInitialized');
    } catch (e) {
      debugPrint('HomeScreen.build: could not read MediaQuery: $e');
    }

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7FAFC),
        body: Center(
          child: CupertinoActivityIndicator(
            radius: 20,
            color: Color(0xFF4299E1),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Soft pastel background instead of plain white
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            GestureDetector(
              onTap: () {
                // Close overlays when tapping outside
                if (_showQuickPhrases || _showSpeechControls) {
                  setState(() {
                    _showQuickPhrases = false;
                    _showSpeechControls = false;
                  });
                }
              },
              child: Column(
                children: [
                  // Top row: only show in portrait mode
                  if (!MediaQuery.of(context).orientation.isLandscape)
                    Padding(
                      padding: _getResponsivePadding(context),
                      child: LayoutBuilder(
                        builder: (context, topConstraints) {
                          final screenWidth = topConstraints.maxWidth;
                          final screenHeight = MediaQuery.of(context).size.height;
                          final isLandscape = screenWidth > screenHeight;
                          
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // + Symbol button (top left corner) - only in portrait
                              if (!isLandscape) ...[
                                Container(
                                  width: screenWidth * 0.08,
                                  height: screenWidth * 0.08,
                                  margin: EdgeInsets.only(right: screenWidth * 0.015),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF6C63FF).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: () async {
                                        try {
                                          // Navigate to Add Symbol screen with full functionality
                                          final Symbol? newSymbol = await Navigator.push(
                                            context,
                                            CupertinoPageRoute(
                                              builder: (context) => const AddSymbolScreen(),
                                            ),
                                          );
                                          
                                          // If user created a new symbol, add it to our symbols list
                                          if (newSymbol != null && mounted) {
                                            setState(() {
                                              _allSymbols.add(newSymbol);
                                              
                                              // Also refresh custom categories in case a new category was created
                                              _refreshCustomCategories();
                                            });
                                          }
                                        } catch (e) {
                                          _showErrorDialog('Error opening Add Symbol screen: $e');
                                        }
                                      },
                                      child: Icon(
                                        CupertinoIcons.add,
                                        color: Colors.white,
                                        size: screenWidth * 0.045,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.015),
                              ],
                              
                              // Right side controls (compact horizontal layout)
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // In portrait: show all buttons as before
                                    // Quick Phrases toggle
                                    _buildTopControlButton(
                                      icon: CupertinoIcons.chat_bubble_2_fill,
                                      isActive: _showQuickPhrases,
                                      onPressed: _toggleQuickPhrases,
                                      screenWidth: screenWidth,
                                      isLandscape: isLandscape,
                                    ),
                                    SizedBox(width: screenWidth * 0.008),
                                    
                                    // Speech Controls toggle
                                    _buildTopControlButton(
                                      icon: CupertinoIcons.waveform,
                                      isActive: _showSpeechControls,
                                      onPressed: _toggleSpeechControls,
                                      screenWidth: screenWidth,
                                      isLandscape: isLandscape,
                                    ),
                                    SizedBox(width: screenWidth * 0.008),
                                    
                                    // Search bar (compact)
                                    Flexible(
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: screenWidth * 0.30,
                                          minWidth: screenWidth * 0.15,
                                        ),
                                        child: _buildSearchBar(),
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.008),
                                    
                                    // Favorites & History button
                                    _buildTopControlButton(
                                      icon: CupertinoIcons.heart_fill,
                                      isActive: false,
                                      onPressed: _openGoalsScreen,
                                      screenWidth: screenWidth,
                                      isLandscape: isLandscape,
                                    ),
                                    SizedBox(width: screenWidth * 0.008),
                                    
                                    // Professional Communication Coach button
                                    _buildTopControlButton(
                                      icon: CupertinoIcons.person_2_alt,
                                      isActive: false,
                                      onPressed: _openInteractiveFun,
                                      screenWidth: screenWidth,
                                      isLandscape: isLandscape,
                                    ),
                                    SizedBox(width: screenWidth * 0.008),
                                    
                                    // Settings button
                                    _buildTopControlButton(
                                      icon: CupertinoIcons.settings,
                                      isActive: false,
                                      onPressed: _openSettings,
                                      screenWidth: screenWidth,
                                      isLandscape: isLandscape,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    
                  // Menu button for landscape mode - positioned absolutely in top right
                  if (MediaQuery.of(context).orientation.isLandscape)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _buildTopControlButton(
                        icon: CupertinoIcons.ellipsis_circle_fill,
                        isActive: false,
                        onPressed: _showMenuOptions,
                        screenWidth: MediaQuery.of(context).size.width,
                        isLandscape: true,
                      ),
                    ),            // Error message display
            if (_errorMessage != null)
              Container(
                padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.03), // 3% of screen width
                margin: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.04, // 4% of screen width
                  vertical: MediaQuery.of(context).size.height * 0.01, // 1% of screen height
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECEB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE53E3E)),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      color: Color(0xFFE53E3E),
                      size: MediaQuery.of(context).size.width * 0.05, // 5% of screen width
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.02), // 2% of screen width
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Color(0xFFE53E3E),
                          fontSize: MediaQuery.of(context).size.width * 0.035, // 3.5% of screen width
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: MediaQuery.of(context).size.width * 0.06, // 6% of screen width
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                        });
                      },
                      child: Icon(
                        CupertinoIcons.clear,
                        color: Color(0xFFE53E3E),
                        size: MediaQuery.of(context).size.width * 0.04, // 4% of screen width
                      ),
                    ),
                  ],
                ),
              ),

            // ARASAAC Asterisk Grid - Core Vocabulary (TEMPORARILY DISABLED FOR PERFORMANCE TESTING)
            // ArasaacAsteriskGrid(
            //   onSymbolTap: _onSymbolTap,
            // ),
            
            
            // Main content area - different layout for landscape vs portrait
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  final screenHeight = constraints.maxHeight;
                  final isLandscape = screenWidth > screenHeight;
                  
                  if (isLandscape) {
                    // Horizontal layout: categories on right side like reference image
                    return Row(
                      children: [
                        // Main content area (left side)
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              // Communication Grid
                              Expanded(
                                child: CommunicationGrid(
                                  symbols: _getFilteredSymbols(),
                                  categories: _categories,
                                  onSymbolTap: _onSymbolTap,
                                  onCategoryTap: (category) {},
                                  viewType: ViewType.symbols,
                                  selectedSymbols: _selectedSymbols,
                                  onSpeakSentence: _speakSentence,
                                  onClearSentence: _clearSentence,
                                  onRemoveSymbolAt: _removeSymbolAt,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Right sidebar with categories (like reference image) - reduced by 20%
                        Container(
                          width: screenWidth * 0.176, // Reduced from 0.22 to 0.176 (20% reduction)
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(-2, 0),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Categories header
                              Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.015, // Slightly reduced
                                  horizontal: screenWidth * 0.01, // Reduced padding
                                ),
                                child: AutoSizeText(
                                  'Categories',
                                  style: GoogleFonts.nunito(
                                    fontSize: 18, // Increased from 16 to 18
                                    fontWeight: FontWeight.w700, // Increased from w600 to w700
                                    color: Colors.grey.shade700,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                              
                              // Categories list
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.008), // Reduced padding
                                    child: Column(
                                      children: [
                                        _buildCategoryTab('All'),
                                        SizedBox(height: 6), // Reduced spacing
                                        
                                        // Custom categories
                                        if (_customCategories.isNotEmpty) ...[
                                          ..._customCategories.map((category) => Padding(
                                            padding: const EdgeInsets.only(bottom: 6), // Reduced spacing
                                            child: _buildCategoryTab(category.name, isCustom: true),
                                          )),
                                          
                                          // Divider
                                          Container(
                                            height: 1,
                                            margin: EdgeInsets.symmetric(vertical: 8), // Reduced margin
                                            color: Colors.grey.shade300,
                                          ),
                                        ],
                                        
                                        // Default categories (excluding custom categories)
                                        ..._categories.where((category) => 
                                          !_customCategories.any((customCat) => customCat.name == category.name)
                                        ).map((category) => Padding(
                                          padding: const EdgeInsets.only(bottom: 6), // Reduced spacing
                                          child: _buildCategoryTab(category.name),
                                        )),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              
                              // Add button and Search bar above favorites
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.008), // Match categories padding
                                child: Column(
                                  children: [
                                    // Add symbol button - match category tab size and style
                                    GestureDetector(
                                      onTap: () async {
                                        try {
                                          final Symbol? newSymbol = await Navigator.push(
                                            context,
                                            CupertinoPageRoute(
                                              builder: (context) => const AddSymbolScreen(),
                                            ),
                                          );
                                          if (newSymbol != null && mounted) {
                                            setState(() {
                                              _allSymbols.add(newSymbol);
                                              _refreshCustomCategories();
                                            });
                                          }
                                        } catch (e) {
                                          _showErrorDialog('Error opening Add Symbol screen: $e');
                                        }
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.02, // Match category tab horizontal padding
                                          vertical: screenHeight * 0.008, // Match category tab vertical padding
                                        ),
                                        margin: EdgeInsets.only(bottom: 6), // Match category spacing
                                        constraints: BoxConstraints(
                                          minHeight: 38, // Match category tab minimum height
                                          maxHeight: 48, // Match category tab maximum height
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(20), // Match category tab border radius
                                          boxShadow: [
                                            BoxShadow(
                                              color: Color(0xFF6C63FF).withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: Offset(0, 3),
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              CupertinoIcons.add,
                                              size: 16, // Match category icon size
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 4), // Match category icon spacing
                                            AutoSizeText(
                                              'Add Symbol',
                                              style: GoogleFonts.nunito(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700, // Match category text weight
                                                fontSize: 16, // Match category text size
                                                letterSpacing: 0.3, // Match category letter spacing
                                              ),
                                              maxLines: 1,
                                              minFontSize: 12, // Match category min font size
                                              maxFontSize: 20, // Match category max font size
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    
                                    // Search bar - match category tab size and style
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: screenWidth * 0.02, // Match category tab horizontal padding
                                        vertical: screenHeight * 0.008, // Match category tab vertical padding
                                      ),
                                      margin: EdgeInsets.only(bottom: 6), // Match category spacing
                                      constraints: BoxConstraints(
                                        minHeight: 38, // Match category tab minimum height
                                        maxHeight: 48, // Match category tab maximum height
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20), // Match category tab border radius
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 2,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            CupertinoIcons.search,
                                            size: 16, // Match category icon size
                                            color: Colors.grey.shade600,
                                          ),
                                          SizedBox(width: 4), // Match category icon spacing
                                          Expanded(
                                            child: CupertinoTextField(
                                              controller: _searchController,
                                              onChanged: _filterSymbols,
                                              style: GoogleFonts.nunito(
                                                fontSize: 16, // Match category text size
                                                fontWeight: FontWeight.w700, // Match category text weight
                                                color: Colors.grey.shade700,
                                                letterSpacing: 0.3, // Match category letter spacing
                                              ),
                                              placeholder: 'Search...',
                                              placeholderStyle: GoogleFonts.nunito(
                                                fontSize: 16, // Match category text size
                                                fontWeight: FontWeight.w700, // Match category text weight
                                                color: Colors.grey.shade400,
                                                letterSpacing: 0.3, // Match category letter spacing
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.transparent,
                                              ),
                                              suffix: _searchQuery.isNotEmpty
                                                  ? CupertinoButton(
                                                      padding: EdgeInsets.zero,
                                                      minSize: 16,
                                                      onPressed: () {
                                                        _searchController.clear();
                                                        _filterSymbols('');
                                                      },
                                                      child: Icon(
                                                        CupertinoIcons.clear_circled_solid,
                                                        color: Colors.grey.shade400,
                                                        size: 16, // Match category icon size
                                                      ),
                                                    )
                                                  : null,
                                              padding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Favorites button at bottom of sidebar
                              Container(
                                padding: EdgeInsets.all(screenWidth * 0.008),
                                child: GestureDetector(
                                  onTap: _openGoalsScreen,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: screenHeight * 0.012,
                                      horizontal: screenWidth * 0.01,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Color(0xFFFF6B6B), Color(0xFFE63946)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0xFFE63946).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          CupertinoIcons.heart_fill,
                                          color: Colors.white,
                                          size: screenWidth * 0.025,
                                        ),
                                        SizedBox(width: screenWidth * 0.008),
                                        Text(
                                          'Favorites',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: screenWidth * 0.022,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  } else {
                    // Portrait layout: traditional top categories + grid + bottom bar
                    return Column(
                      children: [
                        // Category Navigation Tabs - horizontal scroll for portrait - reduced by 20%
                        Container(
                          height: MediaQuery.of(context).size.height * 0.044, // Reduced from 0.055 to 0.044 (20% reduction)
                          constraints: BoxConstraints(
                            minHeight: 36, // Reduced from 45 to 36
                            maxHeight: 48, // Reduced from 60 to 48
                          ),
                          margin: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width * 0.012, // Reduced from 0.015
                            vertical: MediaQuery.of(context).size.height * 0.002, // Reduced from 0.003
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildCategoryTab('All'),
                                SizedBox(width: MediaQuery.of(context).size.width * 0.016), // Reduced from 0.02

                                // Custom categories
                                if (_customCategories.isNotEmpty) ...[
                                  ..._customCategories.map((category) => Padding(
                                    padding: EdgeInsets.only(right: MediaQuery.of(context).size.width * 0.016), // Reduced
                                    child: _buildCategoryTab(category.name, isCustom: true),
                                  )),

                                  // Divider
                                  Container(
                                    height: MediaQuery.of(context).size.height * 0.024, // Reduced from 0.03
                                    width: 1,
                                    margin: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.012), // Reduced
                                    color: Colors.grey.shade300,
                                  ),
                                ],

                                // Default categories (excluding custom categories)
                                ..._categories.where((category) => 
                                  !_customCategories.any((customCat) => customCat.name == category.name)
                                ).map((category) => Padding(
                                  padding: EdgeInsets.only(right: MediaQuery.of(context).size.width * 0.016), // Reduced
                                  child: _buildCategoryTab(category.name),
                                )),
                              ],
                            ),
                          ),
                        ),
                        
                        // Communication Grid
                        Expanded(
                          child: CommunicationGrid(
                            symbols: _getFilteredSymbols(),
                            categories: _categories,
                            onSymbolTap: _onSymbolTap,
                            onCategoryTap: (category) {},
                            viewType: ViewType.symbols,
                            onSymbolUpdate: _onSymbolUpdate,
                            onSymbolEdit: _onSymbolDelete,
                          ),
                        ),
                        
                        // Single Speak Bar at bottom with full functionality - only show when symbols are selected
                        if (_selectedSymbols.isNotEmpty) _buildSpeakBar(),
                      ],
                    );
                  }
                },
              ),
            ),
            
            // DEBUG: small floating debug button (only in debug mode)
            if (foundation.kDebugMode)
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: EdgeInsets.only(right: MediaQuery.of(context).size.width * 0.04, top: 8),
                  child: GestureDetector(
                    onTap: () {
                      debugPrint('DEBUG: selectedSymbols=${_selectedSymbols.length}, showQuickPhrases=$_showQuickPhrases, showSpeechControls=$_showSpeechControls');
                      _showErrorDialog('Debug: selectedSymbols=${_selectedSymbols.length}\nshowQuickPhrases=$_showQuickPhrases\nshowSpeechControls=$_showSpeechControls');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.bug_report,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Overlay widgets positioned on top
        // Quick Phrases Bar (positioned overlay)
        if (_showQuickPhrases)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {}, // Prevent tap from bubbling through to close overlay
              child: QuickPhrasesBar(
                onPhraseSpeak: _onQuickPhraseSpeak,
              ),
            ),
          ),
          
        // Speech Controls (positioned overlay)
        if (_showSpeechControls)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {}, // Prevent tap from bubbling through to close overlay
              child: _buildSpeechControls(),
            ),
          ),
      ],
    ),
  ),
    );
  }

  Widget _buildCategoryTab(String categoryName, {bool isCustom = false}) {
    final isSelected = _currentCategory == categoryName;
    final categoryColor = isCustom
        ? const Color(0xFF9F7AEA) // Purple for custom categories
        : AACHelper.getCategoryColor(categoryName);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;

    // Get category icon
    IconData categoryIcon = _getCategoryIcon(categoryName);

    return GestureDetector(
      onTap: () => _changeCategory(categoryName),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isLandscape ? screenWidth * 0.02 : screenWidth * 0.025, // Slightly reduced for compactness 
          vertical: isLandscape ? screenHeight * 0.008 : screenHeight * 0.01, // Increased for better touch area
        ),
        constraints: BoxConstraints(
          minHeight: isLandscape ? 38 : 42, // Increased minimum height
          maxHeight: isLandscape ? 48 : 52, // Increased maximum height
        ),
        decoration: BoxDecoration(
          color: isSelected ? categoryColor : Colors.white,
          borderRadius: BorderRadius.circular(isLandscape ? 20 : 16), // More rounded in landscape
          border: Border.all(
            color: isSelected ? categoryColor : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: categoryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                    spreadRadius: 1,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Category icon - only show in landscape view for pill-style tabs
            if (isLandscape) ...[
              Icon(
                categoryIcon,
                size: 16,
                color: isSelected ? Colors.white : categoryColor,
              ),
              SizedBox(width: 4),
            ],
            AutoSizeText(
              categoryName,
              style: GoogleFonts.nunito(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w700, // Increased from w600 to w700 for more professional look
                fontSize: isLandscape ? 16 : 18, // Increased from 13/14 to 16/18 for better readability
                letterSpacing: 0.3, // Slightly increased letter spacing
              ),
              maxLines: 1,
              minFontSize: 12, // Increased from 10
              maxFontSize: 20, // Increased from 16
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeakBar() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.02,
        vertical: MediaQuery.of(context).size.height * 0.008,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Symbol area: flexible and scrollable
          if (_selectedSymbols.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.02,
                vertical: MediaQuery.of(context).size.height * 0.008,
              ),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: MediaQuery.of(context).size.width * 0.006,
                  runSpacing: MediaQuery.of(context).size.height * 0.004,
                  children: _selectedSymbols.asMap().entries.map((entry) {
                    final categoryColor = AACHelper.getCategoryColor(entry.value.category);
                    return GestureDetector(
                      onTap: () => _removeSymbolAt(entry.key),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: categoryColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          entry.value.label,
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          
          // Action buttons
          Container(
            padding: EdgeInsets.fromLTRB(
              MediaQuery.of(context).size.width * 0.02,
              0,
              MediaQuery.of(context).size.width * 0.02,
              MediaQuery.of(context).size.height * 0.008,
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _speakSentence,
                    icon: Icon(CupertinoIcons.speaker_3, size: 20),
                    label: Text('Speak'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38A169),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (_selectedSymbols.isNotEmpty) ...[
                  SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                  IconButton(
                    onPressed: _clearSentence,
                    icon: Icon(CupertinoIcons.clear_thick),
                    color: const Color(0xFFE53E3E),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get category icons
  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'all':
        return CupertinoIcons.square_grid_2x2;
      case 'food & drinks':
      case 'food':
        return CupertinoIcons.bag_fill;
      case 'emotions':
        return CupertinoIcons.smiley;
      case 'actions':
        return CupertinoIcons.hand_raised;
      case 'family':
        return CupertinoIcons.person_2_fill;
      case 'basic needs':
        return CupertinoIcons.heart_fill;
      case 'vehicles':
        return CupertinoIcons.car;
      case 'animals':
        return CupertinoIcons.paw;
      case 'toys':
        return CupertinoIcons.gamecontroller;
      case 'colors':
        return CupertinoIcons.paintbrush;
      case 'numbers':
        return CupertinoIcons.number;
      case 'letters':
        return CupertinoIcons.textformat_abc;
      default:
        return CupertinoIcons.circle_fill;
    }
  }

  Widget _buildSpeechControls() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.016, // Reduced by 50% from 0.032
        vertical: isLandscape ? screenHeight * 0.002 : screenHeight * 0.004, // Reduced by 50% from 0.004/0.008
      ),
      padding: EdgeInsets.all(isLandscape ? screenWidth * 0.008 : screenWidth * 0.016), // Reduced by 50% from 0.016/0.032
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Speech Controls',
            style: TextStyle(
              fontSize: isLandscape ? screenWidth * 0.015 : screenWidth * 0.027, // Reduced by 50% from 0.03/0.054
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D3748),
            ),
          ),
          SizedBox(height: isLandscape ? screenHeight * 0.002 : screenHeight * 0.006), // Reduced by 50% from 0.004/0.012
          _buildSpeechControlSlider(
            label: 'Speed',
            icon: CupertinoIcons.speedometer,
            value: _speechRate,
            min: 0.1,
            max: 1.0,
            onChanged: (value) async {
              setState(() {
                _speechRate = value;
              });
              await AACHelper.setSpeechRate(value);
            },
          ),
          SizedBox(height: isLandscape ? screenHeight * 0.002 : screenHeight * 0.006), // Reduced by 50% from 0.004/0.012
          _buildSpeechControlSlider(
            label: 'Pitch',
            icon: CupertinoIcons.waveform,
            value: _speechPitch,
            min: 0.5,
            max: 2.0,
            onChanged: (value) async {
              setState(() {
                _speechPitch = value;
              });
              await AACHelper.setSpeechPitch(value);
            },
          ),
          SizedBox(height: isLandscape ? screenHeight * 0.002 : screenHeight * 0.006), // Reduced by 50% from 0.004/0.012
          _buildSpeechControlSlider(
            label: 'Volume',
            icon: CupertinoIcons.volume_up,
            value: _speechVolume,
            min: 0.0,
            max: 1.0,
            onChanged: (value) async {
              setState(() {
                _speechVolume = value;
              });
              await AACHelper.setSpeechVolume(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpeechControlSlider({
    required String label,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: MediaQuery.of(context).size.width * 0.03, // Reduced by 50% from 0.06
          color: const Color(0xFF4ECDC4),
        ),
        SizedBox(width: MediaQuery.of(context).size.width * 0.012), // Reduced by 50% from 0.024
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.024, // Reduced by 50% from 0.048
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D3748),
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFF4ECDC4),
                  thumbColor: const Color(0xFF4ECDC4),
                  trackHeight: MediaQuery.of(context).size.height * 0.0032, // Reduced by 50% from 0.0064
                  thumbShape: RoundSliderThumbShape(
                    enabledThumbRadius: MediaQuery.of(context).size.width * 0.01, // Reduced by 50% from 0.02
                  ),
                ),
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Search functionality methods
  void _filterSymbols(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredSymbols = _allSymbols;
      } else {
        _filteredSymbols = _allSymbols.where((symbol) {
          return symbol.label.toLowerCase().contains(query.toLowerCase()) ||
                 (symbol.description?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
                 symbol.category.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Widget _buildSearchBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final buttonSize = screenWidth * (isLandscape ? 0.06 : 0.08);
    
    return Container(
      height: buttonSize, // Match button height
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: CupertinoTextField(
        controller: _searchController,
        onChanged: _filterSymbols,
        style: const TextStyle(fontSize: 14),
        placeholder: 'Search symbols...',
        placeholderStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xFF999999),
        ),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(12), // Match button border radius
          border: Border.all(color: CupertinoColors.systemGrey4),
        ),
        prefix: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Icon(
            CupertinoIcons.search,
            color: const Color(0xFF999999),
            size: screenWidth * (isLandscape ? 0.025 : 0.035), // Responsive icon size
          ),
        ),
        suffix: _searchQuery.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 20,
                  onPressed: () {
                    _searchController.clear();
                    _filterSymbols('');
                  },
                  child: Icon(
                    CupertinoIcons.clear_circled_solid,
                    color: const Color(0xFF999999),
                    size: screenWidth * (isLandscape ? 0.025 : 0.035), // Responsive icon size
                  ),
                ),
              )
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  void _saveCustomCategories() async {
    // Save all custom categories to user profile and local database
    try {
      final profile = await UserProfileService.getActiveProfile();
      if (profile != null) {
        final updatedProfile = profile.copyWith(
          userCategories: [..._customCategories],
          lastActiveAt: DateTime.now(),
        );
        await UserProfileService.saveUserProfile(updatedProfile);
        
        // Also update local database
        await AACHelper.clearCustomCategories();
        for (final category in _customCategories) {
          await AACHelper.addCategory(category);
        }
      }
    } catch (e) {
      debugPrint('Error saving custom categories: $e');
    }
  }

  // Helper method to build top control buttons
  Widget _buildTopControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
    required double screenWidth,
    required bool isLandscape,
  }) {
    // Match the + button size
    final buttonSize = screenWidth * (isLandscape ? 0.06 : 0.08);
    final iconSize = screenWidth * (isLandscape ? 0.035 : 0.045);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: buttonSize,
      height: buttonSize,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF4ECDC4) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12), // Match + button border radius
            boxShadow: isActive ? [
              BoxShadow(
                color: const Color(0xFF4ECDC4).withOpacity(0.3),
                blurRadius: 8, // Match + button shadow
                offset: const Offset(0, 4), // Match + button shadow
              ),
            ] : [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.white : Colors.grey.shade600,
            size: iconSize, // Use same icon size as + button
          ),
        ),
      ),
    );
  }
}
