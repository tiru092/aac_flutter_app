import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../widgets/communication_grid.dart';
import '../widgets/sentence_bar.dart';
import '../widgets/quick_phrases_bar.dart';
import '../models/symbol.dart';
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
    } catch (e) {
      print('Error checking profile: $e');
    } finally {
      // Now load the data - always proceed even if profile check fails
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
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
      } catch (e) {
        print('Error loading user data: $e');
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
    } catch (e) {
      print('Error in _loadData: $e');
      setState(() {
        // Fallback to just sample data if something goes wrong
        _categories = SampleData.getSampleCategories();
        _allSymbols = SampleData.getSampleSymbols();
        _customCategories = [];
        _isLoading = false;
      });
    }
  }
  
  void _loadSpeechSettings() {
    setState(() {
      _speechRate = AACHelper.speechRate;
      _speechPitch = AACHelper.speechPitch;
      _speechVolume = AACHelper.speechVolume;
    });
  }
  
  List<Symbol> _getFilteredSymbols() {
    if (_currentCategory == 'All') {
      return _allSymbols;
    }
    return _allSymbols.where((symbol) => symbol.category == _currentCategory).toList();
  }
  
  void _changeCategory(String category) {
    setState(() {
      _currentCategory = category;
    });
  }

  // CRITICAL: Symbol tap functionality - Add to sentence AND speak
  void _onSymbolTap(Symbol symbol) async {
    // 1. Add symbol to sentence
    setState(() {
      _selectedSymbols.add(symbol);
    });
    
    // 2. Speak the symbol immediately
    await AACHelper.speak(symbol.label);
  }

  void _speakSentence() async {
    if (_selectedSymbols.isNotEmpty) {
      final sentence = _selectedSymbols.map((s) => s.label).join(' ');
      await AACHelper.speak(sentence);
    }
  }

  void _clearSentence() {
    setState(() {
      _selectedSymbols.clear();
    });
  }

  void _removeSymbolAt(int index) {
    if (index >= 0 && index < _selectedSymbols.length) {
      setState(() {
        _selectedSymbols.removeAt(index);
      });
    }
  }

  void _onQuickPhraseSpeak(String phrase) async {
    await AACHelper.speak(phrase);
  }

  void _toggleQuickPhrases() {
    setState(() {
      _showQuickPhrases = !_showQuickPhrases;
    });
  }
  
  void _toggleSpeechControls() {
    setState(() {
      _showSpeechControls = !_showSpeechControls;
    });
  }

  void _showProfileSwitcher() async {
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
              Navigator.pop(context);
              if (profile.id != currentProfile?.id) {
                await UserProfileService.setActiveProfile(profile);
                // Reload data with the new profile
                _loadData();
              }
            },
            isDefaultAction: profile.id == currentProfile?.id,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.person_fill,
                  color: Color(0xFF4ECDC4),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  profile.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (profile.id == currentProfile?.id) ...[  
                  const SizedBox(width: 8),
                  const Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: Color(0xFF38A169),
                    size: 16,
                  ),
                ],
              ],
            ),
          )),
          
          // Create new profile option
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showCreateProfileDialog();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.person_badge_plus_fill,
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
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
  
  void _showCreateProfileDialog() {
    final nameController = TextEditingController();
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Create New Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: nameController,
              placeholder: 'Enter user name',
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context);
                
                // Create new profile
                await UserProfileService.createProfile(name: name);
                
                // Reload data with the new profile
                _loadData();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
  
  void _openSettings() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text(
          'Menu',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        message: const Text('Choose an option'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showProfileSwitcher();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.person_2_fill,
                  color: Color(0xFF38A169),
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Switch Profile',
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
                  CupertinoIcons.person_circle,
                  color: Color(0xFF4ECDC4),
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Profile',
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
                  CupertinoIcons.star_fill,
                  color: Color(0xFFFFD700),
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Premium Plans',
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
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Add Symbol',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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

  Widget _buildSpeechControls() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6C63FF).withOpacity(0.1),
            const Color(0xFF4ECDC4).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6C63FF).withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6C63FF).withOpacity(0.8),
                  const Color(0xFF4ECDC4).withOpacity(0.8),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.waveform,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  '🎚️ Speech Controls',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () async {
                    await AACHelper.speak('Testing voice settings');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.speaker_2_fill,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSliderControl(
                  title: 'Speech Speed',
                  icon: CupertinoIcons.speedometer,
                  value: _speechRate,
                  min: 0.1,
                  max: 1.0,
                  onChanged: (value) async {
                    setState(() => _speechRate = value);
                    await AACHelper.setSpeechRate(value);
                  },
                ),
                const SizedBox(height: 16),
                _buildSliderControl(
                  title: 'Voice Pitch',
                  icon: CupertinoIcons.waveform,
                  value: _speechPitch,
                  min: 0.5,
                  max: 2.0,
                  onChanged: (value) async {
                    setState(() => _speechPitch = value);
                    await AACHelper.setSpeechPitch(value);
                  },
                ),
                const SizedBox(height: 16),
                _buildSliderControl(
                  title: 'Volume',
                  icon: CupertinoIcons.volume_up,
                  value: _speechVolume,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (value) async {
                    setState(() => _speechVolume = value);
                    await AACHelper.setSpeechVolume(value);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderControl({
    required String title,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF6C63FF),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 4),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFF6C63FF),
                  thumbColor: const Color(0xFF6C63FF),
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
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
        Container(
          width: 48,
          alignment: Alignment.centerRight,
          child: Text(
            '${(value * 100).round()}%',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
      ],
    );
  }

  void _saveCustomCategories() async {
    // Save custom categories to the user's profile
    for (final category in _customCategories) {
      await UserProfileService.addCategoryToActiveProfile(category);
    }
  }

  Widget _buildCategoryTab(String categoryName, {bool isCustom = false}) {
    final isSelected = _currentCategory == categoryName;
    final categoryColor = categoryName == 'All' 
        ? const Color(0xFF4ECDC4)
        : isCustom
            ? _findCustomCategoryColor(categoryName)
            : AACHelper.getCategoryColor(categoryName);
    
    return GestureDetector(
      onTap: () => _changeCategory(categoryName),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? categoryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: categoryColor,
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: categoryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isCustom ? '🎨' : _getCategoryEmoji(categoryName),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 6),
            Text(
              categoryName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : categoryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _findCustomCategoryColor(String categoryName) {
    final customCategory = _customCategories.firstWhere(
      (cat) => cat.name == categoryName,
      orElse: () => Category(
        name: categoryName,
        iconPath: 'custom',
        colorCode: 0xFF9F7AEA, // Default purple
      ),
    );
    return Color(customCategory.colorCode);
  }
  
  String _getCategoryEmoji(String categoryName) {
    switch (categoryName) {
      case 'All':
        return '🌐';
      case 'Food & Drinks':
        return '🍎';
      case 'Vehicles':
        return '🚗';
      case 'Emotions':
        return '😊';
      case 'Actions':
        return '🏃';
      case 'Family':
        return '👨‍👩‍👧‍👦';
      case 'Basic Needs':
        return '🙏';
      default:
        return '📝';
    }
  }

}