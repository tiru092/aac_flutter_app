import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/communication_grid.dart';
import '../widgets/sentence_bar.dart';
import '../widgets/quick_phrases_bar.dart';
import '../widgets/phrase_history_sheet.dart';
import '../widgets/edit_tile_dialog.dart';
import '../services/phrase_history_service.dart';
import '../services/symbol_database_service.dart';
import '../services/profile_service.dart';
import '../services/language_service.dart';
import '../models/symbol.dart';
import '../models/user_profile.dart';
import '../screens/profile_selection_screen.dart';
import '../utils/aac_helper.dart';
import '../utils/sample_data.dart';
import 'accessibility_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _buttonAnimationController;
  late AnimationController _headerAnimationController;
  late Animation<double> _buttonAnimation;
  late Animation<double> _headerAnimation;
  List<Category> _categories = [];
  List<Symbol> _allSymbols = [];
  List<Symbol> _selectedSymbols = [];
  bool _isLoading = true;
  bool _showQuickPhrases = false; // Professional AAC apps hide this by default
  final PhraseHistoryService _historyService = PhraseHistoryService();
  final SymbolDatabaseService _databaseService = SymbolDatabaseService();
  final ProfileService _profileService = ProfileService();
  final LanguageService _languageService = LanguageService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
    _initializeAccessibility();
  }

  Future<void> _initializeAccessibility() async {
    // Initialize enhanced TTS with accessibility features
    await AACHelper.initializeAccessibleTTS();
    
    // Initialize phrase history service
    await _historyService.initialize();
    
    // Initialize symbol database service
    await _databaseService.initialize();
    
    // Initialize profile service
    await _profileService.initialize();
    
    // Initialize language service
    await _languageService.initialize();
    
    // Announce app ready to screen readers
    Future.delayed(const Duration(milliseconds: 1000), () {
      AACHelper.announceToScreenReader('AAC Communication app is ready. Navigate through categories and symbols to communicate.');
    });
  }

  void _initializeAnimations() {
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _buttonAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    
    _headerAnimationController.forward();
  }

  Future<void> _loadData() async {
    try {
      // Load data from database service
      setState(() {
        _categories = _databaseService.categories;
        _allSymbols = _databaseService.symbols;
        _isLoading = false;
      });
    } catch (e) {
      // On error, fallback to sample data
      setState(() {
        _categories = SampleData.getSampleCategories();
        _allSymbols = SampleData.getSampleSymbols();
        _isLoading = false;
      });
    }
  }

  // Sentence Management Methods
  void _addSymbolToSentence(Symbol symbol) {
    setState(() {
      _selectedSymbols.add(symbol);
    });
    AACHelper.accessibleHapticFeedback();
  }

  void _removeSymbolAt(int index) {
    if (index >= 0 && index < _selectedSymbols.length) {
      setState(() {
        _selectedSymbols.removeAt(index);
      });
      AACHelper.accessibleHapticFeedback();
    }
  }

  void _clearSentence() {
    setState(() {
      _selectedSymbols.clear();
    });
    AACHelper.accessibleHapticFeedback();
  }

  void _undoLastSymbol() {
    if (_selectedSymbols.isNotEmpty) {
      setState(() {
        _selectedSymbols.removeLast();
      });
      AACHelper.accessibleHapticFeedback();
    }
  }

  void _speakSentence() async {
    if (_selectedSymbols.isNotEmpty) {
      // Following memory specification: simplified speech output
      final sentence = _selectedSymbols.map((s) => s.label).join(' ');
      await AACHelper.speak(sentence);
      await AACHelper.accessibleHapticFeedback();
      
      // Add to phrase history
      await _historyService.addToHistory(sentence);
    }
  }

  void _onQuickPhraseSpeak(String phraseText) async {
    // Quick phrases are spoken immediately and added to history
    await _historyService.addToHistory(phraseText);
  }

  void _showPhraseHistory() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => const PhraseHistorySheet(),
    );
  }

  void _showProfileSelection() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => ProfileSelectionScreen(
        onProfileSelected: (profile) {
          setState(() {
            // UI will update automatically based on new current profile
          });
        },
      ),
    );
  }

  void _onSymbolEdit(Symbol symbol) async {
    // Handle symbol deletion
    if (symbol.id != null) {
      await _databaseService.deleteSymbol(symbol.id!);
      setState(() {
        _allSymbols = _databaseService.symbols;
      });
    }
  }

  void _onSymbolUpdate(Symbol updatedSymbol) async {
    // Handle symbol update or creation
    if (updatedSymbol.id == null || updatedSymbol.id!.isEmpty) {
      // New symbol
      await _databaseService.addSymbol(updatedSymbol);
    } else {
      // Update existing symbol
      await _databaseService.updateSymbol(updatedSymbol);
    }
    
    setState(() {
      _allSymbols = _databaseService.symbols;
    });
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text(
          'Oops! 😕',
          style: TextStyle(fontSize: 20),
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text(
              'OK',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // PROFESSIONAL TOP BAR - Minimal like real AAC apps
  Widget _buildProfessionalTopBar() {
    return Container(
      height: 60,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // App title - minimal
            Row(
              children: [
                Text(
                  'AAC Communicator',
                  style: TextStyle(
                    fontSize: 18 * AACHelper.getTextSizeMultiplier(),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
            
            const Spacer(),
            
            // Essential actions only - like professional AAC apps
            Row(
              children: [
                // Quick Phrases toggle
                _buildTopBarButton(
                  icon: CupertinoIcons.chat_bubble_2,
                  onPressed: () {
                    setState(() {
                      _showQuickPhrases = !_showQuickPhrases;
                    });
                  },
                ),
                const SizedBox(width: 12),
                // Settings
                _buildTopBarButton(
                  icon: CupertinoIcons.gear,
                  onPressed: () => Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const AccessibilitySettingsScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Category chip for horizontal scrolling
  Widget _buildCategoryChip(String name, bool isSelected, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4299E1) : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected ? const Color(0xFF4299E1) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            name,
            style: TextStyle(
              fontSize: 14 * AACHelper.getTextSizeMultiplier(),
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF4A5568),
            ),
          ),
        ),
      ),
    );
  }

  // Big symbol tile - professional AAC style
  Widget _buildBigSymbolTile(Symbol symbol) {
    final categoryColor = AACHelper.getCategoryColor(symbol.category);
    
    return GestureDetector(
      onTap: () {
        _addSymbolToSentence(symbol);
        AACHelper.speak(symbol.label);
        AACHelper.accessibleHapticFeedback();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: categoryColor,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: categoryColor.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Image area - large
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: symbol.imagePath.startsWith('assets/')
                      ? Image.asset(
                          symbol.imagePath,
                          fit: BoxFit.contain,
                        )
                      : Image.file(
                          File(symbol.imagePath),
                          fit: BoxFit.contain,
                        ),
                ),
              ),
            ),
            // Label area - with category color
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: categoryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(13),
                  bottomRight: Radius.circular(13),
                ),
              ),
              child: Text(
                symbol.label,
                style: TextStyle(
                  fontSize: 16 * AACHelper.getTextSizeMultiplier(),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add symbol tile
  Widget _buildAddSymbolTile() {
    return GestureDetector(
      onTap: _onAddButtonPressed,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF4299E1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                CupertinoIcons.add,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add Symbol',
              style: TextStyle(
                fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4A5568),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Empty state when no symbols
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              CupertinoIcons.chat_bubble_2,
              size: 40,
              color: Color(0xFF4A5568),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No symbols yet!',
            style: TextStyle(
              fontSize: 24 * AACHelper.getTextSizeMultiplier(),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first symbol',
            style: TextStyle(
              fontSize: 16 * AACHelper.getTextSizeMultiplier(),
              color: const Color(0xFF718096),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Create default symbols if none exist
  List<Symbol> _createDefaultSymbols() {
    return [
      Symbol(
        label: 'Hello',
        imagePath: 'assets/symbols/hello.png',
        category: 'Social',
        isDefault: true,
      ),
      Symbol(
        label: 'Please',
        imagePath: 'assets/symbols/please.png',
        category: 'Social',
        isDefault: true,
      ),
      Symbol(
        label: 'Thank You',
        imagePath: 'assets/symbols/thank_you.png',
        category: 'Social',
        isDefault: true,
      ),
    ];
  }

  // Get default images - ARASAAC style symbols
  List<Map<String, String>> _getDefaultImages() {
    return [
      // Social/Greetings
      {'path': 'assets/symbols/hello.png', 'label': 'Hello', 'category': 'Social'},
      {'path': 'assets/symbols/please.png', 'label': 'Please', 'category': 'Social'},
      {'path': 'assets/symbols/thank_you.png', 'label': 'Thank You', 'category': 'Social'},
      {'path': 'assets/symbols/goodbye.png', 'label': 'Goodbye', 'category': 'Social'},
      {'path': 'assets/symbols/help.png', 'label': 'Help Me', 'category': 'Social'},
      {'path': 'assets/symbols/stop.png', 'label': 'Stop', 'category': 'Social'},
      
      // Food & Drinks
      {'path': 'assets/symbols/apple.png', 'label': 'Apple', 'category': 'Food'},
      {'path': 'assets/symbols/water.png', 'label': 'Water', 'category': 'Food'},
      {'path': 'assets/symbols/milk.png', 'label': 'Milk', 'category': 'Food'},
      {'path': 'assets/symbols/bread.png', 'label': 'Bread', 'category': 'Food'},
      {'path': 'assets/symbols/banana.png', 'label': 'Banana', 'category': 'Food'},
      {'path': 'assets/symbols/cookie.png', 'label': 'Cookie', 'category': 'Food'},
      
      // Actions
      {'path': 'assets/symbols/eat.png', 'label': 'Eat', 'category': 'Actions'},
      {'path': 'assets/symbols/drink.png', 'label': 'Drink', 'category': 'Actions'},
      {'path': 'assets/symbols/play.png', 'label': 'Play', 'category': 'Actions'},
      {'path': 'assets/symbols/sleep.png', 'label': 'Sleep', 'category': 'Actions'},
      {'path': 'assets/symbols/go.png', 'label': 'Go', 'category': 'Actions'},
      {'path': 'assets/symbols/come.png', 'label': 'Come', 'category': 'Actions'},
      
      // People
      {'path': 'assets/symbols/mom.png', 'label': 'Mom', 'category': 'People'},
      {'path': 'assets/symbols/dad.png', 'label': 'Dad', 'category': 'People'},
      {'path': 'assets/symbols/me.png', 'label': 'Me', 'category': 'People'},
      {'path': 'assets/symbols/you.png', 'label': 'You', 'category': 'People'},
      
      // Emotions
      {'path': 'assets/symbols/happy.png', 'label': 'Happy', 'category': 'Describing'},
      {'path': 'assets/symbols/sad.png', 'label': 'Sad', 'category': 'Describing'},
      {'path': 'assets/symbols/angry.png', 'label': 'Angry', 'category': 'Describing'},
      {'path': 'assets/symbols/tired.png', 'label': 'Tired', 'category': 'Describing'},
      
      // Basic Needs
      {'path': 'assets/symbols/toilet.png', 'label': 'Toilet', 'category': 'Misc'},
      {'path': 'assets/symbols/home.png', 'label': 'Home', 'category': 'Misc'},
      {'path': 'assets/symbols/school.png', 'label': 'School', 'category': 'Misc'},
      {'path': 'assets/symbols/car.png', 'label': 'Car', 'category': 'Misc'},
    ];
  }

  // Create symbol from default image
  void _createSymbolFromDefaultImage(Map<String, String> imageData) {
    final symbol = Symbol(
      label: imageData['label']!,
      imagePath: imageData['path']!,
      category: imageData['category']!,
      isDefault: false,
      description: 'Default symbol: ${imageData['label']}',
    );
    
    _onSymbolUpdate(symbol);
    
    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${imageData['label']}" to your symbols'),
        backgroundColor: const Color(0xFF38A169),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Open camera for taking photos
  void _openCamera() async {
    try {
      // Show placeholder for now - would integrate with image_picker plugin
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('📷 Camera'),
          content: const Text(
            'Camera functionality will open here.\n\n'
            'This would integrate with the image_picker plugin to capture photos '
            'and create custom symbols.',
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorDialog('Camera not available: $e');
    }
  }

  // Open gallery for selecting photos
  void _openGallery() async {
    try {
      // Show placeholder for now - would integrate with image_picker plugin
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('🖼️ Gallery'),
          content: const Text(
            'Gallery selection will open here.\n\n'
            'This would integrate with the image_picker plugin to select '
            'existing photos and create custom symbols.',
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorDialog('Gallery not available: $e');
    }
  }

  // Professional top bar button
  Widget _buildTopBarButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF4A5568),
          size: 20,
        ),
      ),
    );
  }

  // COMPACT SENTENCE BAR - Always visible but minimal
  Widget _buildCompactSentenceBar() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Sentence display - compact
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            child: _selectedSymbols.isEmpty
                ? Text(
                    'Tap symbols to communicate',
                    style: TextStyle(
                      color: const Color(0xFF718096),
                      fontSize: 16 * AACHelper.getTextSizeMultiplier(),
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
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
          
          // Action buttons - compact row
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(CupertinoIcons.speaker_2, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Speak',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16 * AACHelper.getTextSizeMultiplier(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    color: const Color(0xFFED8936),
                    padding: const EdgeInsets.all(12),
                    onPressed: _undoLastSymbol,
                    child: const Icon(CupertinoIcons.back, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 6),
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
    );
  }

  // MAIN COMMUNICATION AREA - Big tiles like professional AAC apps
  Widget _buildMainCommunicationArea() {
    return Column(
      children: [
        // Quick phrases (hidden by default, like professional apps)
        if (_showQuickPhrases) 
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: QuickPhrasesBar(onPhraseSpeak: _onQuickPhraseSpeak),
          ),
        
        if (_showQuickPhrases) const SizedBox(height: 12),
        
        // Main symbol/category grid - BIG TILES
        Expanded(
          child: _buildBigTileGrid(),
        ),
      ],
    );
  }

  // BIG TILE GRID - Professional AAC style
  Widget _buildBigTileGrid() {
    // Always show symbols by default with option to browse categories
    final displaySymbols = _allSymbols.isNotEmpty ? _allSymbols : _createDefaultSymbols();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          // Category navigation if needed
          if (_categories.isNotEmpty)
            Container(
              height: 50,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildCategoryChip('All', _selectedIndex == 0, () {
                      setState(() => _selectedIndex = 0);
                    });
                  }
                  final category = _categories[index - 1];
                  return _buildCategoryChip(
                    category.name,
                    _selectedIndex == index,
                    () => setState(() => _selectedIndex = index),
                  );
                },
              ),
            ),
          
          // Big symbol tiles
          Expanded(
            child: _allSymbols.isEmpty 
                ? _buildEmptyState()
                : GridView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // Professional AAC apps use 3 columns
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: displaySymbols.length + 1, // +1 for add button
                    itemBuilder: (context, index) {
                      if (index >= displaySymbols.length) {
                        return _buildAddSymbolTile();
                      }
                      return _buildBigSymbolTile(displaySymbols[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }



  // Add button handler
  void _onAddButtonPressed() async {
    await AACHelper.accessibleHapticFeedback();
    await AACHelper.speakWithAccessibility('Add new symbol or category');
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Add New'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showAddSymbolDialog();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.add_circled, color: CupertinoColors.activeBlue),
                SizedBox(width: 8),
                Text('Add Symbol'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showAddCategoryDialog();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.folder_badge_plus, color: CupertinoColors.activeBlue),
                SizedBox(width: 8),
                Text('Add Category'),
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

  void _showAddSymbolDialog() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _buildImageSelectionDialog(),
    );
  }

  // COMPREHENSIVE IMAGE SELECTION DIALOG with tabs
  Widget _buildImageSelectionDialog() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'Add New Symbol',
                    style: TextStyle(
                      fontSize: 24 * AACHelper.getTextSizeMultiplier(),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAFC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        CupertinoIcons.xmark,
                        color: Color(0xFF4A5568),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: TabBar(
                indicator: BoxDecoration(
                  color: const Color(0xFF4299E1),
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF4A5568),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.square_grid_2x2, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Default',
                          style: TextStyle(
                            fontSize: 12 * AACHelper.getTextSizeMultiplier(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.camera, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Camera',
                          style: TextStyle(
                            fontSize: 12 * AACHelper.getTextSizeMultiplier(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.photo, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Gallery',
                          style: TextStyle(
                            fontSize: 12 * AACHelper.getTextSizeMultiplier(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Tab Content
            Expanded(
              child: TabBarView(
                children: [
                  _buildDefaultImagesTab(),
                  _buildCameraTab(),
                  _buildGalleryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // DEFAULT IMAGES TAB - with ARASAAC style symbols
  Widget _buildDefaultImagesTab() {
    final defaultImages = _getDefaultImages();
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose from built-in symbols',
            style: TextStyle(
              fontSize: 16 * AACHelper.getTextSizeMultiplier(),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4A5568),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: defaultImages.length,
              itemBuilder: (context, index) {
                final imageData = defaultImages[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _createSymbolFromDefaultImage(imageData);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AACHelper.getCategoryColor(imageData['category'] ?? 'Misc'),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Image.asset(
                              imageData['path'] ?? '',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: AACHelper.getCategoryColor(imageData['category'] ?? 'Misc'),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                          ),
                          child: Text(
                            imageData['label'] ?? '',
                            style: TextStyle(
                              fontSize: 10 * AACHelper.getTextSizeMultiplier(),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // CAMERA TAB
  Widget _buildCameraTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF4299E1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              CupertinoIcons.camera_fill,
              size: 60,
              color: Color(0xFF4299E1),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Take a Photo',
            style: TextStyle(
              fontSize: 24 * AACHelper.getTextSizeMultiplier(),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Take a new photo to create a custom symbol',
            style: TextStyle(
              fontSize: 16 * AACHelper.getTextSizeMultiplier(),
              color: const Color(0xFF718096),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: const Color(0xFF4299E1),
              onPressed: () {
                Navigator.pop(context);
                _openCamera();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.camera, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Open Camera',
                    style: TextStyle(
                      fontSize: 18 * AACHelper.getTextSizeMultiplier(),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // GALLERY TAB
  Widget _buildGalleryTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF38A169).withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              CupertinoIcons.photo_fill,
              size: 60,
              color: Color(0xFF38A169),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Choose from Gallery',
            style: TextStyle(
              fontSize: 24 * AACHelper.getTextSizeMultiplier(),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select an existing photo from your device',
            style: TextStyle(
              fontSize: 16 * AACHelper.getTextSizeMultiplier(),
              color: const Color(0xFF718096),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: const Color(0xFF38A169),
              onPressed: () {
                Navigator.pop(context);
                _openGallery();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.photo, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Open Gallery',
                    style: TextStyle(
                      fontSize: 18 * AACHelper.getTextSizeMultiplier(),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    // For now, show a simple alert - category creation functionality would need a separate dialog
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Add Category'),
        content: const Text('Category creation feature coming soon!'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }





  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CupertinoActivityIndicator(
                  radius: 20,
                  color: AACHelper.childFriendlyColors[0],
                ),
                const SizedBox(height: 20),
                Text(
                  'Loading AAC Communication...',
                  style: TextStyle(
                    fontSize: 18 * AACHelper.getTextSizeMultiplier(),
                    color: AACHelper.childFriendlyColors[0],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: Column(
            children: [
              // MINIMAL TOP BAR - Clean and professional
              _buildProfessionalTopBar(),
              
              // COMPACT SENTENCE BAR - Always visible but minimal
              _buildCompactSentenceBar(),
              
              // MAIN COMMUNICATION AREA - Big tiles front and center
              Expanded(
                child: _buildMainCommunicationArea(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }
}