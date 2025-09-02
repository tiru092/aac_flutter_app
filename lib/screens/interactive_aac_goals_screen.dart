import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../utils/aac_helper.dart';
import '../screens/story_mode_screen.dart';

class InteractiveAACGoalsScreen extends StatefulWidget {
  const InteractiveAACGoalsScreen({super.key});

  @override
  State<InteractiveAACGoalsScreen> createState() => _InteractiveAACGoalsScreenState();
}

class _InteractiveAACGoalsScreenState extends State<InteractiveAACGoalsScreen>
    with TickerProviderStateMixin {
  
  int _selectedGoalIndex = 0;
  List<String> _messageBuilder = [];
  late AnimationController _animationController;
  late Animation<double> _bounceAnimation;
  
  // Goal categories with interactive activities
  final List<Map<String, dynamic>> _interactiveGoals = [
    {
      'title': 'Request Items',
      'emoji': '🤲',
      'color': Colors.green,
      'description': 'Learn to ask for things you want',
      'type': 'request',
      'symbols': [
        {'text': 'I want', 'image': '🙋‍♂️', 'category': 'core'},
        {'text': 'cookie', 'image': '🍪', 'category': 'food'},
        {'text': 'toy', 'image': '🧸', 'category': 'toys'},
        {'text': 'juice', 'image': '🧃', 'category': 'drinks'},
        {'text': 'book', 'image': '📚', 'category': 'items'},
        {'text': 'please', 'image': '🙏', 'category': 'social'},
      ]
    },
    {
      'title': 'Greetings',
      'emoji': '👋',
      'color': Colors.blue,
      'description': 'Say hello and goodbye',
      'type': 'greetings',
      'symbols': [
        {'text': 'Hi', 'image': '👋', 'category': 'greeting'},
        {'text': 'Hello', 'image': '😊', 'category': 'greeting'},
        {'text': 'Good morning', 'image': '🌅', 'category': 'greeting'},
        {'text': 'Bye bye', 'image': '👋', 'category': 'farewell'},
        {'text': 'See you later', 'image': '👋', 'category': 'farewell'},
        {'text': 'Good night', 'image': '🌙', 'category': 'farewell'},
      ]
    },
    {
      'title': 'Comments',
      'emoji': '💭',
      'color': Colors.orange,
      'description': 'Share your thoughts and feelings',
      'type': 'comments',
      'symbols': [
        {'text': 'That\'s fun!', 'image': '😄', 'category': 'comment'},
        {'text': 'I like it', 'image': '👍', 'category': 'comment'},
        {'text': 'Wow!', 'image': '😮', 'category': 'exclamation'},
        {'text': 'Look at me!', 'image': '👀', 'category': 'attention'},
        {'text': 'Cool!', 'image': '😎', 'category': 'comment'},
        {'text': 'Amazing!', 'image': '🤩', 'category': 'comment'},
      ]
    },
    {
      'title': 'Questions',
      'emoji': '❓',
      'color': Colors.purple,
      'description': 'Ask questions to learn more',
      'type': 'questions',
      'symbols': [
        {'text': 'What', 'image': '❓', 'category': 'question'},
        {'text': 'Where', 'image': '📍', 'category': 'question'},
        {'text': 'Who', 'image': '👤', 'category': 'question'},
        {'text': 'is that?', 'image': '👉', 'category': 'follow-up'},
        {'text': 'are you?', 'image': '🤔', 'category': 'follow-up'},
        {'text': 'is it?', 'image': '💭', 'category': 'follow-up'},
      ]
    },
    {
      'title': 'Protest/Reject',
      'emoji': '✋',
      'color': Colors.red,
      'description': 'Say no when you don\'t want something',
      'type': 'protest',
      'symbols': [
        {'text': 'No', 'image': '❌', 'category': 'reject'},
        {'text': 'Stop', 'image': '🛑', 'category': 'protest'},
        {'text': 'I don\'t want', 'image': '🙅‍♂️', 'category': 'reject'},
        {'text': 'All done', 'image': '✋', 'category': 'finished'},
        {'text': 'Help', 'image': '🆘', 'category': 'request'},
        {'text': 'Different', 'image': '🔄', 'category': 'choice'},
      ]
    },
    {
      'title': 'Emotions',
      'emoji': '😊',
      'color': Colors.pink,
      'description': 'Tell others how you feel',
      'type': 'emotions',
      'symbols': [
        {'text': 'I feel', 'image': '💭', 'category': 'core'},
        {'text': 'happy', 'image': '😊', 'category': 'emotion'},
        {'text': 'sad', 'image': '😢', 'category': 'emotion'},
        {'text': 'angry', 'image': '😠', 'category': 'emotion'},
        {'text': 'excited', 'image': '🤩', 'category': 'emotion'},
        {'text': 'tired', 'image': '😴', 'category': 'emotion'},
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _addToMessage(String text, String emoji) {
    setState(() {
      _messageBuilder.add('$emoji $text');
    });
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    
    // Play sound for feedback
    AACHelper.speak(text);
  }

  void _speakMessage() {
    if (_messageBuilder.isNotEmpty) {
      final message = _messageBuilder.join(' ');
      AACHelper.speak(message);
      
      // Visual feedback
      _showMessageAnimation();
    }
  }

  void _clearMessage() {
    setState(() {
      _messageBuilder.clear();
    });
  }

  void _showMessageAnimation() {
    // Implementation for message animation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.volume_up, color: Colors.white),
            const SizedBox(width: 8),
            Text('Speaking: ${_messageBuilder.join(' ')}'),
          ],
        ),
        backgroundColor: _interactiveGoals[_selectedGoalIndex]['color'],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: _interactiveGoals[_selectedGoalIndex]['color'],
        middle: Text(
          'Interactive AAC Goals',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.book_solid, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => const StoryModeScreen(),
            ),
          ),
        ),
      ),
      child: Column(
        children: [
          // Message Builder Bar
          _buildMessageBuilder(),
          
          // Goal Tabs
          _buildGoalTabs(),
          
          // Interactive Activity Area
          Expanded(
            child: _buildInteractiveActivity(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBuilder() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          const Text(
            'My Message:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          
          // Message Display
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _messageBuilder.isEmpty
                ? const Text(
                    'Tap symbols to build your message...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _messageBuilder.map((item) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _interactiveGoals[_selectedGoalIndex]['color']
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item,
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    }).toList(),
                  ),
          ),
          
          const SizedBox(height: 12),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  color: _interactiveGoals[_selectedGoalIndex]['color'],
                  onPressed: _messageBuilder.isEmpty ? null : _speakMessage,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.speaker_2, size: 20),
                      SizedBox(width: 8),
                      Text('Speak', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              CupertinoButton(
                color: Colors.grey,
                onPressed: _messageBuilder.isEmpty ? null : _clearMessage,
                child: const Icon(CupertinoIcons.clear, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalTabs() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        final screenWidth = constraints.maxWidth;
        
        // Calculate dynamic tab width based on screen size
        final tabWidth = isLandscape ? screenWidth * 0.15 : screenWidth * 0.25;
        final tabHeight = isLandscape ? 70.0 : 85.0;
        
        return Container(
          height: tabHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
            itemCount: _interactiveGoals.length,
            itemBuilder: (context, index) {
              final goal = _interactiveGoals[index];
              final isSelected = index == _selectedGoalIndex;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGoalIndex = index;
                    _messageBuilder.clear(); // Clear message when switching goals
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.only(right: screenWidth * 0.02),
                  width: tabWidth,
                  decoration: BoxDecoration(
                    color: isSelected ? goal['color'] : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: goal['color'],
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: goal['color'].withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        goal['emoji'],
                        style: TextStyle(
                          fontSize: isLandscape ? 16 : 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        goal['title'],
                        style: TextStyle(
                          fontSize: isLandscape ? 11 : 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : goal['color'],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInteractiveActivity() {
    final currentGoal = _interactiveGoals[_selectedGoalIndex];
    final symbols = List<Map<String, dynamic>>.from(currentGoal['symbols']);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Activity Instructions
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: currentGoal['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: currentGoal['color'].withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentGoal['title'],
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: currentGoal['color'],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getActivityInstructions(currentGoal['type']),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Symbol Grid
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isLandscape = constraints.maxWidth > constraints.maxHeight;
                final screenWidth = constraints.maxWidth;
                
                // Dynamic column calculation for better space utilization
                int crossAxisCount;
                if (isLandscape) {
                  // In landscape: Always show exactly 3 columns
                  crossAxisCount = 3;
                } else {
                  // In portrait: 2 columns for larger layout size
                  crossAxisCount = 2;
                }

                // Adjust spacing and padding based on screen size
                final spacing = isLandscape ? screenWidth * 0.02 : screenWidth * 0.04;

                return GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    // Adjust aspect ratio for consistent sizing
                    childAspectRatio: isLandscape ? 1.2 : 1.1,
                  ),
                  itemCount: symbols.length,
                  itemBuilder: (context, index) {
                    final symbol = symbols[index];
                    return _buildSymbolCard(symbol);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymbolCard(Map<String, dynamic> symbol) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        final cardWidth = constraints.maxWidth;
        final cardHeight = constraints.maxHeight;
        
        // Calculate responsive sizes
        final emojiSize = isLandscape ? cardWidth * 0.35 : cardWidth * 0.4;
        final fontSize = isLandscape ? cardWidth * 0.08 : cardWidth * 0.09;
        
        return ScaleTransition(
          scale: _bounceAnimation,
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _addToMessage(symbol['text'], symbol['image']),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: _interactiveGoals[_selectedGoalIndex]['color'].withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Large emoji/icon - responsive size
                  Text(
                    symbol['image'],
                    style: TextStyle(fontSize: emojiSize.clamp(24, 48)),
                  ),
                  SizedBox(height: cardHeight * 0.08),
                  
                  // Text label - responsive size
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: cardWidth * 0.1),
                    child: Text(
                      symbol['text'],
                      style: TextStyle(
                        fontSize: fontSize.clamp(10, 14),
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

  String _getActivityInstructions(String type) {
    switch (type) {
      case 'request':
        return 'Tap symbols to ask for things you want. Start with "I want" then choose what you need!';
      case 'greetings':
        return 'Practice saying hello and goodbye. Choose the right greeting for different times of day!';
      case 'comments':
        return 'Share your thoughts! Tap symbols to tell others what you think about activities.';
      case 'questions':
        return 'Ask questions to learn more. Start with a question word, then add more details!';
      case 'protest':
        return 'It\'s okay to say no! Use these symbols when you don\'t want something or need help.';
      case 'emotions':
        return 'Tell others how you feel. Start with "I feel" then choose your emotion!';
      default:
        return 'Tap symbols to build your message, then press Speak!';
    }
  }
}
