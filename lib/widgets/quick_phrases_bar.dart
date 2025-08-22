import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/aac_helper.dart';
import 'dart:convert';

class QuickPhrase {
  final String id;
  final String label;
  final String speechText;
  final Color color;
  final IconData icon;

  QuickPhrase({
    required this.id,
    required this.label,
    required this.speechText,
    required this.color,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'speechText': speechText,
    'color': color.value,
    'icon': icon.codePoint,
  };

  factory QuickPhrase.fromJson(Map<String, dynamic> json) => QuickPhrase(
    id: json['id'],
    label: json['label'],
    speechText: json['speechText'],
    color: Color(json['color']),
    icon: IconData(json['icon'], fontFamily: 'CupertinoIcons'),
  );
}

class QuickPhrasesBar extends StatefulWidget {
  final Function(String) onPhraseSpeak;

  const QuickPhrasesBar({
    super.key,
    required this.onPhraseSpeak,
  });

  @override
  State<QuickPhrasesBar> createState() => _QuickPhrasesBarState();
}

class _QuickPhrasesBarState extends State<QuickPhrasesBar>
    with TickerProviderStateMixin {
  List<QuickPhrase> _phrases = [];
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    _loadPhrases();
    _slideController.forward();
  }

  Future<void> _loadPhrases() async {
    final prefs = await SharedPreferences.getInstance();
    final phrasesJson = prefs.getString('quick_phrases');
    
    if (phrasesJson != null) {
      final List<dynamic> phrasesList = jsonDecode(phrasesJson);
      setState(() {
        _phrases = phrasesList.map((json) => QuickPhrase.fromJson(json)).toList();
      });
    } else {
      // Load default phrases for special children
      _loadDefaultPhrases();
    }
  }

  void _loadDefaultPhrases() {
    setState(() {
      _phrases = [
        QuickPhrase(
          id: 'hello',
          label: 'Hello',
          speechText: 'Hello',
          color: const Color(0xFF6C63FF),
          icon: CupertinoIcons.hand_raised_fill,
        ),
        QuickPhrase(
          id: 'please',
          label: 'Please',
          speechText: 'Please',
          color: const Color(0xFF4ECDC4),
          icon: CupertinoIcons.heart_fill,
        ),
        QuickPhrase(
          id: 'thank_you',
          label: 'Thank You',
          speechText: 'Thank you',
          color: const Color(0xFFFFE66D),
          icon: CupertinoIcons.star_fill,
        ),
        QuickPhrase(
          id: 'help',
          label: 'Help Me',
          speechText: 'Help me please',
          color: const Color(0xFFFF6B6B),
          icon: CupertinoIcons.hand_raised_slash_fill,
        ),
        QuickPhrase(
          id: 'stop',
          label: 'Stop',
          speechText: 'Stop',
          color: const Color(0xFFFF9F43),
          icon: CupertinoIcons.stop_fill,
        ),
        QuickPhrase(
          id: 'more',
          label: 'More',
          speechText: 'More please',
          color: const Color(0xFF51CF66),
          icon: CupertinoIcons.plus_circle_fill,
        ),
      ];
    });
    _savePhrases();
  }

  Future<void> _savePhrases() async {
    final prefs = await SharedPreferences.getInstance();
    final phrasesJson = jsonEncode(_phrases.map((p) => p.toJson()).toList());
    await prefs.setString('quick_phrases', phrasesJson);
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              const Color(0xFFF8F9FA),
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
            _buildHeader(),
            _buildPhrasesGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
            CupertinoIcons.bolt_fill,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Quick Phrases',
            style: TextStyle(
              fontSize: 16 * AACHelper.getTextSizeMultiplier(),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _showAddPhraseDialog,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                CupertinoIcons.add,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhrasesGrid() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: _phrases.isEmpty
          ? _buildEmptyState()
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _phrases.map((phrase) => _buildPhraseButton(phrase)).toList(),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 80,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.add_circled,
              size: 32,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              'Add quick phrases',
              style: TextStyle(
                fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhraseButton(QuickPhrase phrase) {
    return Semantics(
      label: 'Quick phrase: ${phrase.label}, long press to edit',
      button: true,
      child: GestureDetector(
        onTap: () async {
          await AACHelper.accessibleHapticFeedback();
          await AACHelper.speak(phrase.speechText);
          widget.onPhraseSpeak(phrase.speechText);
        },
        onLongPress: () => _showEditPhraseDialog(phrase),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                phrase.color,
                phrase.color.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: phrase.color.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                phrase.icon,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                phrase.label,
                style: TextStyle(
                  fontSize: 13 * AACHelper.getTextSizeMultiplier(),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddPhraseDialog() {
    _showPhraseDialog(null);
  }

  void _showEditPhraseDialog(QuickPhrase phrase) {
    _showPhraseDialog(phrase);
  }

  void _showPhraseDialog(QuickPhrase? existingPhrase) {
    final labelController = TextEditingController(text: existingPhrase?.label ?? '');
    final speechController = TextEditingController(text: existingPhrase?.speechText ?? '');
    Color selectedColor = existingPhrase?.color ?? const Color(0xFF6C63FF);
    IconData selectedIcon = existingPhrase?.icon ?? CupertinoIcons.star_fill;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => CupertinoPopupSurface(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  existingPhrase == null ? '➕ Add Quick Phrase' : '✏️ Edit Phrase',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                CupertinoTextField(
                  controller: labelController,
                  placeholder: 'Button label',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                CupertinoTextField(
                  controller: speechController,
                  placeholder: 'What to speak',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (existingPhrase != null)
                      CupertinoButton(
                        color: const Color(0xFFFF6B6B),
                        onPressed: () {
                          _deletePhrase(existingPhrase);
                          Navigator.pop(context);
                        },
                        child: const Text('Delete'),
                      ),
                    CupertinoButton(
                      color: const Color(0xFF51CF66),
                      onPressed: () {
                        if (labelController.text.isNotEmpty && speechController.text.isNotEmpty) {
                          final phrase = QuickPhrase(
                            id: existingPhrase?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                            label: labelController.text,
                            speechText: speechController.text,
                            color: selectedColor,
                            icon: selectedIcon,
                          );
                          
                          if (existingPhrase == null) {
                            _addPhrase(phrase);
                          } else {
                            _updatePhrase(phrase);
                          }
                          Navigator.pop(context);
                        }
                      },
                      child: Text(existingPhrase == null ? 'Add' : 'Save'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CupertinoButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addPhrase(QuickPhrase phrase) {
    setState(() {
      _phrases.add(phrase);
    });
    _savePhrases();
  }

  void _updatePhrase(QuickPhrase updatedPhrase) {
    setState(() {
      final index = _phrases.indexWhere((p) => p.id == updatedPhrase.id);
      if (index != -1) {
        _phrases[index] = updatedPhrase;
      }
    });
    _savePhrases();
  }

  void _deletePhrase(QuickPhrase phrase) {
    setState(() {
      _phrases.removeWhere((p) => p.id == phrase.id);
    });
    _savePhrases();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }
}