import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/symbol.dart';
import '../utils/aac_helper.dart';

class ArasaacAsteriskGrid extends StatelessWidget {
  final Function(Symbol) onSymbolTap;
  
  const ArasaacAsteriskGrid({super.key, required this.onSymbolTap});

  // ARASAAC core vocabulary words organized by frequency and function - OPTIMIZED
  // Reduced set for better performance, additional words loaded on demand
  static List<Symbol> get coreVocabulary => _coreVocabulary ??= _generateCoreVocabulary();
  static List<Symbol>? _coreVocabulary;
  
  static List<Symbol> _generateCoreVocabulary() => [
    // Essential core words only for better performance
    Symbol(
      label: 'I',
      imagePath: 'emoji:👆',
      category: 'Core Words',
      isDefault: true,
      description: 'First person pronoun',
    ),
    Symbol(
      label: 'You',
      imagePath: 'emoji:👤',
      category: 'Core Words',
      isDefault: true,
      description: 'Second person pronoun',
    ),
    Symbol(
      label: 'Want',
      imagePath: 'emoji:🙏',
      category: 'Core Words',
      isDefault: true,
      description: 'Express desire',
    ),
    Symbol(
      label: 'Like',
      imagePath: 'emoji:👍',
      category: 'Core Words',
      isDefault: true,
      description: 'Express preference',
    ),
    Symbol(
      label: 'More',
      imagePath: 'emoji:➕',
      category: 'Core Words',
      isDefault: true,
      description: 'Request additional',
    ),
    Symbol(
      label: 'Stop',
      imagePath: 'emoji:🛑',
      category: 'Core Words',
      isDefault: true,
      description: 'Request to cease',
    ),
    Symbol(
      label: 'Help',
      imagePath: 'emoji:🆘',
      category: 'Core Words',
      isDefault: true,
      description: 'Request assistance',
    ),
    Symbol(
      label: 'Yes',
      imagePath: 'emoji:✅',
      category: 'Core Words',
      isDefault: true,
      description: 'Affirmation',
    ),
    Symbol(
      label: 'No',
      imagePath: 'emoji:❌',
      category: 'Core Words',
      isDefault: true,
      description: 'Negation',
    ),
    Symbol(
      label: 'Please',
      imagePath: 'emoji:🙏',
      category: 'Core Words',
      isDefault: true,
      description: 'Politeness marker',
    ),
    Symbol(
      label: 'Thank You',
      imagePath: 'emoji:🙌',
      category: 'Core Words',
      isDefault: true,
      description: 'Expression of gratitude',
    ),
    Symbol(
      label: 'Hello',
      imagePath: 'emoji:👋',
      category: 'Core Words',
      isDefault: true,
      description: 'Greeting',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Responsive height based on screen size
    final screenHeight = MediaQuery.of(context).size.height;
    final gridHeight = screenHeight > 800 ? 140.0 : 120.0;

    return Container(
      height: gridHeight, // Responsive height for the asterisk grid
      margin: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.04, // 4% of screen width
        vertical: MediaQuery.of(context).size.height * 0.01, // 1% of screen height
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with ARASAAC branding
          Padding(
            padding: EdgeInsets.fromLTRB(
              MediaQuery.of(context).size.width * 0.04, // 4% of screen width
              MediaQuery.of(context).size.height * 0.015, // 1.5% of screen height
              MediaQuery.of(context).size.width * 0.04, // 4% of screen width
              MediaQuery.of(context).size.height * 0.01, // 1% of screen height
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.star_fill,
                  color: Color(0xFF4ECDC4),
                  size: MediaQuery.of(context).size.width * 0.05, // 5% of screen width
                ),
                SizedBox(width: MediaQuery.of(context).size.width * 0.02), // 2% of screen width
                Text(
                  'Core Vocabulary',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.04 * AACHelper.getTextSizeMultiplier(), // 4% of screen width
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const Spacer(),
                Icon(
                  CupertinoIcons.asterisk_circle,
                  color: Color(0xFF6C63FF),
                  size: MediaQuery.of(context).size.width * 0.045, // 4.5% of screen width
                ),
              ],
            ),
          ),
          
          // Horizontal scrollable grid
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.03), // 3% of screen width
              itemCount: coreVocabulary.length,
              itemBuilder: (context, index) {
                final symbol = coreVocabulary[index];
                return _buildCoreWordTile(context, symbol);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoreWordTile(BuildContext context, Symbol symbol) {
    final categoryColor = AACHelper.getCategoryColor(symbol.category);
    
    return Container(
      width: MediaQuery.of(context).size.width * 0.2, // 20% of screen width
      constraints: BoxConstraints(
        minWidth: 70,
        maxWidth: 100,
      ),
      margin: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.01), // 1% of screen width
      child: GestureDetector(
        onTap: () => onSymbolTap(symbol),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Symbol image/icon
            Container(
              width: MediaQuery.of(context).size.width * 0.125, // 12.5% of screen width
              height: MediaQuery.of(context).size.width * 0.125, // 12.5% of screen width
              constraints: BoxConstraints(
                minWidth: 40,
                minHeight: 40,
                maxWidth: 60,
                maxHeight: 60,
              ),
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: categoryColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  _getWordEmoji(symbol.label),
                  style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.06), // 6% of screen width
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.008), // 0.8% of screen height
            
            // Word label
            Text(
              symbol.label,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.03 * AACHelper.getTextSizeMultiplier(), // 3% of screen width
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D3748),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getWordEmoji(String word) {
    switch (word.toLowerCase()) {
      case 'i':
      case 'you':
        return '👤';
      case 'want':
      case 'like':
        return '❤️';
      case 'more':
        return '➕';
      case 'stop':
        return '🛑';
      case 'go':
        return '➡️';
      case 'help':
        return '🆘';
      case 'yes':
        return '✅';
      case 'no':
        return '❌';
      case 'please':
      case 'thank you':
        return '🙏';
      case 'hello':
        return '👋';
      case 'goodbye':
        return '👋';
      case 'eat':
        return '🍽️';
      case 'drink':
        return '🥤';
      case 'play':
        return '🎮';
      case 'sleep':
        return '😴';
      case 'bathroom':
        return '🚽';
      case 'happy':
        return '😊';
      case 'sad':
        return '😢';
      case 'big':
        return '🔍';
      case 'small':
        return '🔎';
      case 'hot':
        return '🔥';
      case 'cold':
        return '❄️';
      default:
        return '💬';
    }
  }
}
