import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../widgets/communication_grid.dart';
import '../widgets/sentence_bar.dart';
import '../widgets/quick_phrases_bar.dart';
import '../models/symbol.dart';
import '../models/user_profile.dart'; // Add missing import
import '../utils/aac_helper.dart';
import '../utils/sample_data.dart';
import '../services/user_profile_service.dart';
import 'accessibility_settings_screen.dart';
import 'add_symbol_screen.dart';
import 'profile_screen.dart';
import 'subscription_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Symbol> _selectedSymbols = [];
  List<Symbol> _allSymbols = [];
  List<Category> _categories = [];
  List<Category> _customCategories = [];
  bool _isLoading = true;
  bool _showQuickPhrases = false;
  bool _showSpeechControls = false;
  String _currentCategory = 'All'; // Track current category
  String? _errorMessage; // Add error message state
  
  // Speech control values
  double _speechRate = 0.5;
  double _speechPitch = 1.2;
  double _speechVolume = 1.0;

  @override
  void initState() {
    super.initState();
    _checkProfile();
  }

  Future<void> _checkProfile() async {
    try {
      // Check if there's an active profile, otherwise create one
      final activeProfile = await UserProfileService.getActiveProfile();
      
      if (activeProfile == null) {
        // Create a default profile for the user
        await UserProfileService.createProfile(
          name: 'Default User',
        );
      }
    } on AACException catch (e) {
      setState(() {
        _errorMessage = 'Profile error: ${e.message}';
      });
      print('AAC Error checking profile: $e');
    } catch (e) {
      setState(() {
        _errorMessage = 'Unexpected error while checking profile';
      });
      print('Unexpected error checking profile: $e');
    } finally {
      // Now load the data - always proceed even if profile check fails
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear any previous errors
    });
    
    try {
      // Load default sample data
      final defaultCategories = SampleData.getSampleCategories();
      final defaultSymbols = SampleData.getSampleSymbols();
      
      // Load user-specific data - with fallback to empty lists on failure
      List<Symbol> userSymbols = [];
      List<Category> userCategories = [];
      
      try {
        userSymbols = await UserProfileService.getUserSymbols();
        userCategories = await UserProfileService.getUserCategories(); 
      } on AACException catch (e) {
        print('AAC Error loading user data: $e');
        setState(() {
          _errorMessage = 'Error loading user data: ${e.message}';
        });
        // Continue with empty user data
      } catch (e) {
        print('Unexpected error loading user data: $e');
        setState(() {
          _errorMessage = 'Unexpected error loading user data';
        });
        // Continue with empty user data
      }
      
      setState(() {
        _categories = defaultCategories;
        _customCategories = userCategories;
        _allSymbols = [...defaultSymbols, ...userSymbols];
        _isLoading = false;
      });
      
      // Load speech settings
      _loadSpeechSettings();
    } on AACException catch (e) {
      print('AAC Error in _loadData: $e');
      setState(() {
        _errorMessage = 'Data loading error: ${e.message}';
        _isLoading = false;
        // Fallback to just sample data if something goes wrong
        _categories = SampleData.getSampleCategories();
        _allSymbols = SampleData.getSampleSymbols();
        _customCategories = [];
      });
    } catch (e) {
      print('Unexpected error in _loadData: $e');
      setState(() {
        _errorMessage = 'Unexpected error loading data';
        _isLoading = false;
        // Fallback to just sample data if something goes wrong
        _categories = SampleData.getSampleCategories();
        _allSymbols = SampleData.getSampleSymbols();
        _customCategories = [];
      });
    }
  }
  
  void _loadSpeechSettings() {
    try {
      setState(() {
        _speechRate = AACHelper.speechRate;
        _speechPitch = AACHelper.speechPitch;
        _speechVolume = AACHelper.speechVolume;
      });
    } catch (e) {
      print('Error loading speech settings: $e');
      // Use default values if loading fails
      setState(() {
        _speechRate = 0.5;
        _speechPitch = 1.2;
        _speechVolume = 1.0;
      });
    }
  }
  
  List<Symbol> _getFilteredSymbols() {
    try {
      if (_currentCategory == 'All') {
        return _allSymbols;
      }
      return _allSymbols.where((symbol) => symbol.category == _currentCategory).toList();
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

  // CRITICAL: Symbol tap functionality - Add to sentence AND speak
  void _onSymbolTap(Symbol symbol) async {
    try {
      // 1. Add symbol to sentence
      setState(() {
        _selectedSymbols.add(symbol);
      });
      
      // 2. Speak the symbol immediately
      await AACHelper.speak(symbol.label);
    } on AACException catch (e) {
      print('AAC Error speaking symbol: $e');
      _showErrorDialog('Failed to speak symbol: ${e.message}');
    } catch (e) {
      print('Unexpected error speaking symbol: $e');
      _showErrorDialog('Failed to speak symbol');
    }
  }

  void _speakSentence() async {
    try {
      if (_selectedSymbols.isNotEmpty) {
        final sentence = _selectedSymbols.map((s) => s.label).join(' ');
        await AACHelper.speak(sentence);
      }
    } on AACException catch (e) {
      print('AAC Error speaking sentence: $e');
      _showErrorDialog('Failed to speak sentence: ${e.message}');
    } catch (e) {
      print('Unexpected error speaking sentence: $e');
      _showErrorDialog('Failed to speak sentence');
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

  void _onQuickPhraseSpeak(String phrase) async {
    try {
      await AACHelper.speak(phrase);
    } on AACException catch (e) {
      print('AAC Error speaking phrase: $e');
      _showErrorDialog('Failed to speak phrase: ${e.message}');
    } catch (e) {
      print('Unexpected error speaking phrase: $e');
      _showErrorDialog('Failed to speak phrase');
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

  void _showProfileSwitcher() async {
    try {
      // Get all available profiles
      final profiles = await UserProfileService.getAllProfiles();
      final currentProfile = await UserProfileService.getActiveProfile();
      
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: const Text('Switch Profile'),
          message: const Text('Select a user profile or create a new one'),
          actions: [
            // Show existing profiles
            ...profiles.map((profile) => CupertinoActionSheetAction(
              onPressed: () async {
                try {
                  Navigator.pop(context);
                  if (profile.id != currentProfile?.id) {
                    await UserProfileService.setActiveProfile(profile);
                    // Reload data with the new profile
                    _loadData();
                  }
                } on AACException catch (e) {
                  print('AAC Error switching profile: $e');
                  _showErrorDialog('Failed to switch profile: ${e.message}');
                } catch (e) {
                  print('Unexpected error switching profile: $e');
                  _showErrorDialog('Failed to switch profile');
                }
              },
              isDefaultAction: profile.id == currentProfile?.id,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.person,
                    color: Color(0xFF4ECDC4),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    profile.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )),
            CupertinoActionSheetAction(
              onPressed: () async {
                try {
                  Navigator.pop(context);
                  // Create new profile
                  final newProfile = await UserProfileService.createProfile(
                    name: 'New Profile',
                  );
                  await UserProfileService.setActiveProfile(newProfile);
                  _loadData();
                  
                  // Show success message
                  if (mounted) {
                    showCupertinoDialog(
                      context: context,
                      builder: (context) => CupertinoAlertDialog(
                        title: const Text('Profile Created'),
                        content: const Text('New profile has been created successfully.'),
                        actions: [
                          CupertinoDialogAction(
                            child: const Text('OK'),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    );
                  }
                } on AACException catch (e) {
                  print('AAC Error creating profile: $e');
                  _showErrorDialog('Failed to create profile: ${e.message}');
                } catch (e) {
                  print('Unexpected error creating profile: $e');
                  _showErrorDialog('Failed to create profile');
                }
              },
              isDefaultAction: true,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.add,
                    color: Color(0xFF6C63FF),
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Create New Profile',
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

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: const Color(0xFFF7FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with buttons
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Quick Phrases toggle
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _toggleQuickPhrases,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _showQuickPhrases 
                            ? const Color(0xFF4ECDC4) 
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        CupertinoIcons.chat_bubble_2_fill,
                        color: _showQuickPhrases ? Colors.white : Colors.grey.shade600,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Speech Controls toggle
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _toggleSpeechControls,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _showSpeechControls 
                            ? const Color(0xFF6C63FF) 
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        CupertinoIcons.waveform,
                        color: _showSpeechControls ? Colors.white : Colors.grey.shade600,
                        size: 20,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'AAC Communicator',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ),
                  ),
                  // Settings button
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _openSettings,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        CupertinoIcons.settings,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Error message display
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECEB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE53E3E)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      color: Color(0xFFE53E3E),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFE53E3E),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 24,
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                        });
                      },
                      child: const Icon(
                        CupertinoIcons.clear,
                        color: Color(0xFFE53E3E),
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Sentence bar
            Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    child: _selectedSymbols.isEmpty
                        ? const Text(
                            'Tap symbols to communicate',
                            style: TextStyle(
                              color: Color(0xFF718096),
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          )
                        : Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: _selectedSymbols.asMap().entries.map((entry) {
                              final categoryColor = AACHelper.getCategoryColor(entry.value.category);
                              return GestureDetector(
                                onTap: () => _removeSymbolAt(entry.key),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: categoryColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    entry.value.label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                  
                  if (_selectedSymbols.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: CupertinoButton(
                              color: const Color(0xFF38A169),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              onPressed: _speakSentence,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(CupertinoIcons.speaker_2, color: Colors.white, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'Speak',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CupertinoButton(
                            color: const Color(0xFFE53E3E),
                            padding: const EdgeInsets.all(12),
                            onPressed: _clearSentence,
                            child: const Icon(CupertinoIcons.clear, color: Colors.white, size: 16),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            // Category Navigation Tabs
            Container(
              height: 60,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryTab('All'),
                    const SizedBox(width: 12),
                    
                    // Custom categories
                    if (_customCategories.isNotEmpty) ... [
                      ..._customCategories.map((category) => Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _buildCategoryTab(category.name, isCustom: true),
                      )),
                      
                      // Divider between custom and default categories
                      Container(
                        height: 30,
                        width: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: Colors.grey.shade300,
                      ),
                    ],
                    
                    // Default categories
                    ..._categories.map((category) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _buildCategoryTab(category.name),
                    )),
                  ],
                ),
              ),
            ),
            
            // Quick Phrases Bar (conditionally shown)
            if (_showQuickPhrases)
              QuickPhrasesBar(
                onPhraseSpeak: _onQuickPhraseSpeak,
              ),
              
            // Speech Controls (conditionally shown)
            if (_showSpeechControls)
              _buildSpeechControls(),
            
            // Communication Grid
            Expanded(
              child: CommunicationGrid(
                symbols: _getFilteredSymbols(), // Use filtered symbols
                categories: _categories,
                onSymbolTap: _onSymbolTap,
                onCategoryTap: (category) {}, // Empty function for now
                viewType: ViewType.symbols, // Show symbols view
              ),
            ),
            
            // CRITICAL: Add Symbol Bar - Fixed bottom bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: GestureDetector(
                  onTap: () async {
                    try {
                      // Navigate to Add Symbol screen
                      final newSymbol = await Navigator.push<Symbol>(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => const AddSymbolScreen(),
                        ),
                      );
                      
                      if (newSymbol != null) {
                        // Add the new symbol to the list
                        setState(() {
                          _allSymbols.add(newSymbol);
                          
                          // Check if this is a new custom category
                          final existingCategories = [
                            ..._categories.map((c) => c.name),
                            ..._customCategories.map((c) => c.name),
                          ];
                          
                          if (!existingCategories.contains(newSymbol.category)) {
                            // Create new custom category
                            final newCategory = Category(
                              name: newSymbol.category,
                              iconPath: 'custom',
                              colorCode: 0xFF9F7AEA, // Default purple
                            );
                            _customCategories.add(newCategory);
                            
                            // Save custom categories (in a real app)
                            _saveCustomCategories();
                          }
                        });
                        
                        // Show success message
                        if (mounted) {
                          showCupertinoDialog(
                            context: context,
                            builder: (context) => CupertinoAlertDialog(
                              title: const Text('Symbol Added'),
                              content: Text('"${newSymbol.label}" has been added to ${newSymbol.category} category.'),
                              actions: [
                                CupertinoDialogAction(
                                  child: const Text('Great!'),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    } on AACException catch (e) {
                      print('AAC Error adding symbol: $e');
                      _showErrorDialog('Failed to add symbol: ${e.message}');
                    } catch (e) {
                      print('Unexpected error adding symbol: $e');
                      _showErrorDialog('Failed to add symbol');
                    }
                  },
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF6C63FF),
                          Color(0xFF4ECDC4),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            CupertinoIcons.add_circled_solid,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Add New Symbol',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            CupertinoIcons.add_circled_solid,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
    
    return GestureDetector(
      onTap: () => _changeCategory(categoryName),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? categoryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? categoryColor : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: categoryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          categoryName,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSpeechControls() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
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
          const Text(
            'Speech Controls',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 12),
          _buildSpeechControlSlider(
            label: 'Speed',
            icon: CupertinoIcons.speedometer,
            value: _speechRate,
            min: 0.1,
            max: 1.0,
            onChanged: (value) {
              setState(() {
                _speechRate = value;
              });
              AACHelper.setSpeechRate(value);
            },
          ),
          const SizedBox(height: 12),
          _buildSpeechControlSlider(
            label: 'Pitch',
            icon: CupertinoIcons.waveform,
            value: _speechPitch,
            min: 0.5,
            max: 2.0,
            onChanged: (value) {
              setState(() {
                _speechPitch = value;
              });
              AACHelper.setSpeechPitch(value);
            },
          ),
          const SizedBox(height: 12),
          _buildSpeechControlSlider(
            label: 'Volume',
            icon: CupertinoIcons.volume_up,
            value: _speechVolume,
            min: 0.0,
            max: 1.0,
            onChanged: (value) {
              setState(() {
                _speechVolume = value;
              });
              AACHelper.setSpeechVolume(value);
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
        Icon(icon, size: 20, color: const Color(0xFF4ECDC4)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFF4ECDC4),
                  thumbColor: const Color(0xFF4ECDC4),
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
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

  void _saveCustomCategories() {
    // In a real implementation, you would save custom categories to persistent storage
    // For now, we'll just print a message
    print('Custom categories saved');
  }
}