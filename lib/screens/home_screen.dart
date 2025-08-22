import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/communication_grid.dart';
import '../widgets/sentence_bar.dart';
import '../models/symbol.dart';
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
      final categories = AACHelper.getAllCategories();
      final symbols = AACHelper.getAllSymbols();
      
      // If no data exists, load sample data
      if (categories.isEmpty || symbols.isEmpty) {
        setState(() {
          _categories = SampleData.getSampleCategories();
          _allSymbols = SampleData.getSampleSymbols();
          _isLoading = false;
        });
      } else {
        setState(() {
          _categories = categories;
          _allSymbols = symbols;
          _isLoading = false;
        });
      }
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
    }
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

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _headerAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _headerAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AACHelper.childFriendlyColors[0],
                  AACHelper.childFriendlyColors[1],
                  AACHelper.childFriendlyColors[2],
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '👋 Hello!',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Let\'s communicate! 💬',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        _buildSettingsButton(),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            CupertinoIcons.hand_thumbsup_fill,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Tap symbols to speak!',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.95),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.all(16),
        onPressed: () async {
          await AACHelper.provideFeedback(
            text: 'Opening settings',
            soundEffect: SoundEffect.buttonTap,
            tone: EmotionalTone.friendly,
          );
          
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => const AccessibilitySettingsScreen(),
            ),
          );
        },
        child: const Icon(
          CupertinoIcons.gear_alt_fill,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: CupertinoSegmentedControl<int>(
          groupValue: _selectedIndex,
          selectedColor: AACHelper.childFriendlyColors[3],
          unselectedColor: Colors.transparent,
          borderColor: Colors.transparent,
          pressedColor: AACHelper.childFriendlyColors[3].withOpacity(0.3),
          onValueChanged: (value) {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedIndex = value;
            });
          },
          children: {
            0: _buildSegmentItem('🏠 Categories', _selectedIndex == 0),
            1: _buildSegmentItem('📚 All Symbols', _selectedIndex == 1),
          },
        ),
      ),
    );
  }

  Widget _buildSegmentItem(String text, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _buttonAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _buttonAnimation.value,
          child: GestureDetector(
            onTap: _onAddButtonPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AACHelper.childFriendlyColors[5],
                    AACHelper.childFriendlyColors[7],
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AACHelper.childFriendlyColors[5].withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.add_circled_solid,
                    color: Colors.white,
                    size: 32,
                  ),
                  SizedBox(width: 12),
                  Text(
                    '✨ Add New',
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
        );
      },
    );
  }

  void _onAddButtonPressed() {
    HapticFeedback.mediumImpact();
    _buttonAnimationController.forward().then((_) {
      _buttonAnimationController.reverse();
    });
    
    _showAddSymbolDialog();
  }

  void _showAddSymbolDialog() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text(
          '✨ Add New Symbol',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        message: const Text(
          'Choose how to add a new symbol',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to camera
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.camera_fill,
                  color: CupertinoColors.systemBlue,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  '📷 Take Photo',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to gallery
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.photo_fill,
                  color: CupertinoColors.systemGreen,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  '🖼️ Choose from Gallery',
                  style: TextStyle(fontSize: 18),
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
              fontSize: 18,
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
      return CupertinoPageScaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const CupertinoActivityIndicator(
                      radius: 20,
                      color: CupertinoColors.systemBlue,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '🚀 Loading your symbols...',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      child: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              // Add SentenceBar here
              SentenceBar(
                selectedSymbols: _selectedSymbols,
                onAddSymbol: _addSymbolToSentence,
                onRemoveAt: _removeSymbolAt,
                onClear: _clearSentence,
                onUndo: _undoLastSymbol,
                onSpeak: _speakSentence,
              ),
              _buildSegmentedControl(),
              Expanded(
                child: CommunicationGrid(
                  viewType: _selectedIndex == 0 ? ViewType.categories : ViewType.symbols,
                  categories: _categories,
                  symbols: _allSymbols,
                  onSymbolTap: (symbol) async {
                    HapticFeedback.mediumImpact();
                    // Add symbol to sentence instead of just speaking
                    _addSymbolToSentence(symbol);
                    await AACHelper.speak(symbol.label);
                  },
                  onCategoryTap: (category) {
                    HapticFeedback.lightImpact();
                    // Navigate to category symbols
                  },
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 24,
            right: 24,
            child: _buildFloatingActionButton(),
          ),
        ],
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