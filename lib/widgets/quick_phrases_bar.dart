import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/aac_helper.dart';
import '../services/aac_localizations.dart';
import '../services/locale_notifier.dart';
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
    icon: _getIconFromCode(json['icon']),
  );
  
  static IconData _getIconFromCode(int codePoint) {
    // Map common icon codes to constant icons for release builds
    switch (codePoint) {
      case 0xf37d: return CupertinoIcons.hand_raised_fill;
      case 0xf443: return CupertinoIcons.heart_fill;
      case 0xf4b6: return CupertinoIcons.star_fill;
      case 0xf37e: return CupertinoIcons.hand_raised_slash_fill;
      case 0xf4aa: return CupertinoIcons.stop_fill;
      case 0xf489: return CupertinoIcons.plus_circle_fill;
      default: return CupertinoIcons.star_fill; // Fallback icon
    }
  }
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
    final localizations = AACLocalizations.of(context);
    setState(() {
      _phrases = [
        QuickPhrase(
          id: 'hello',
          label: localizations?.translate('hello') ?? 'Hello',
          speechText: localizations?.translate('hello') ?? 'Hello',
          color: const Color(0xFF6C63FF),
          icon: CupertinoIcons.hand_raised_fill,
        ),
        QuickPhrase(
          id: 'please',
          label: localizations?.translate('please') ?? 'Please',
          speechText: localizations?.translate('please') ?? 'Please',
          color: const Color(0xFF4ECDC4),
          icon: CupertinoIcons.heart_fill,
        ),
        QuickPhrase(
          id: 'thank_you',
          label: localizations?.translate('thank_you') ?? 'Thank You',
          speechText: localizations?.translate('thank_you') ?? 'Thank you',
          color: const Color(0xFFFFE66D),
          icon: CupertinoIcons.star_fill,
        ),
        QuickPhrase(
          id: 'help',
          label: localizations?.translate('help_me') ?? 'Help Me',
          speechText: localizations?.translate('help_me_please') ?? 'Help me please',
          color: const Color(0xFFFF6B6B),
          icon: CupertinoIcons.hand_raised_slash_fill,
        ),
        QuickPhrase(
          id: 'stop',
          label: localizations?.translate('stop') ?? 'Stop',
          speechText: localizations?.translate('stop') ?? 'Stop',
          color: const Color(0xFFFF9F43),
          icon: CupertinoIcons.stop_fill,
        ),
        QuickPhrase(
          id: 'more',
          label: localizations?.translate('more') ?? 'More',
          speechText: localizations?.translate('more_please') ?? 'More please',
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
    return AnimatedBuilder(
      animation: LocaleNotifier.instance,
      builder: (context, child) => SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.016, // Reduced by 50% from 0.032
            vertical: MediaQuery.of(context).size.height * 0.004, // Reduced by 50% from 0.008
          ),
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
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.016, // Reduced by 50% from 0.032
        vertical: MediaQuery.of(context).size.height * 0.006, // Reduced by 50% from 0.012
      ),
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
          Icon(
            CupertinoIcons.bolt_fill,
            color: Colors.white,
            size: MediaQuery.of(context).size.width * 0.03, // Reduced by 50% from 0.06
          ),
          SizedBox(width: MediaQuery.of(context).size.width * 0.008), // Reduced by 50% from 0.016
          Text(
            'Quick Phrases',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.024 * AACHelper.getTextSizeMultiplier(), // Reduced by 50% from 0.048
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _showAddPhraseDialog,
            child: Container(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.006), // Reduced by 50% from 0.012
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                CupertinoIcons.add,
                color: Colors.white,
                size: MediaQuery.of(context).size.width * 0.024, // Reduced by 50% from 0.048
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhrasesGrid() {
    return Container(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.012), // Reduced by 50% from 0.024
      child: _phrases.isEmpty
          ? _buildEmptyState()
          : Wrap(
              spacing: MediaQuery.of(context).size.width * 0.008, // Reduced by 50% from 0.016
              runSpacing: MediaQuery.of(context).size.height * 0.004, // Reduced by 50% from 0.008
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: _phrases.map((phrase) => _buildPhraseButton(phrase)).toList(),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.04, // Reduced by 50% from 0.08
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Use minimum space
          children: [
            Flexible(
              child: Icon(
                CupertinoIcons.add_circled,
                size: MediaQuery.of(context).size.width * 0.048, // Reduced by 50% from 0.096
                color: Colors.white70,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.002), // Further reduced for tight space
            Flexible(
              child: Text(
                'Add quick phrases',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.019 * AACHelper.getTextSizeMultiplier(), // Slightly smaller for tight space
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
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
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.012, // Reduced by 50% from 0.024
            vertical: MediaQuery.of(context).size.height * 0.004, // Reduced by 50% from 0.008
          ),
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
                size: MediaQuery.of(context).size.width * 0.024, // Reduced by 50% from 0.048
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.006), // Reduced by 50% from 0.012
              Text(
                phrase.label,
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.0195 * AACHelper.getTextSizeMultiplier(), // Reduced by 50% from 0.039
                  fontWeight: FontWeight.w700,
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