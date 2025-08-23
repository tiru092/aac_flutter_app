import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../widgets/communication_grid.dart';
import '../widgets/sentence_bar.dart';
import '../widgets/quick_phrases_bar.dart';
import '../models/symbol.dart';
import '../utils/aac_helper.dart';
import '../utils/sample_data.dart';
import 'accessibility_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Symbol> _selectedSymbols = [];
  List<Symbol> _allSymbols = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  bool _showQuickPhrases = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Load sample data
    setState(() {
      _categories = SampleData.getSampleCategories();
      _allSymbols = SampleData.getSampleSymbols();
      _isLoading = false;
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

  void _openSettings() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const AccessibilitySettingsScreen(),
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
            
            // Quick Phrases Bar (conditionally shown)
            if (_showQuickPhrases)
              QuickPhrasesBar(
                onPhraseSpeak: _onQuickPhraseSpeak,
              ),
            
            // Communication Grid
            Expanded(
              child: CommunicationGrid(
                symbols: _allSymbols,
                categories: _categories,
                onSymbolTap: _onSymbolTap, // THIS IS THE KEY - symbols will speak!
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
                  onTap: () {
                    // Add symbol functionality
                    showCupertinoDialog(
                      context: context,
                      builder: (context) => CupertinoAlertDialog(
                        title: const Text('Add Symbol'),
                        content: const Text('Add symbol functionality here!'),
                        actions: [
                          CupertinoDialogAction(
                            child: const Text('OK'),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    );
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


}