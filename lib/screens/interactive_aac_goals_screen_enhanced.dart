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
  
  // Enhanced Goal categories with evidence-based ASD engagement activities
  final List<Map<String, dynamic>> _interactiveGoals = [
    {
      'title': 'Request Items',
      'emoji': '🤲',
      'color': Colors.green,
      'description': 'Learn to ask for things you want',
      'type': 'request',
      'engagement_strategies': ['visual_choice_boards', 'structured_routines', 'sensory_motivation'],
      'symbols': [
        // Core vocabulary (most important for communication)
        {'text': 'I want', 'image': '🙋‍♂️', 'category': 'core', 'priority': 'high'},
        {'text': 'more', 'image': '➕', 'category': 'core', 'priority': 'high'},
        {'text': 'help', 'image': '🆘', 'category': 'core', 'priority': 'high'},
        {'text': 'please', 'image': '🙏', 'category': 'social', 'priority': 'high'},
        
        // Preferred items (high motivation for ASD kids)
        {'text': 'cookie', 'image': '🍪', 'category': 'food', 'priority': 'high'},
        {'text': 'juice', 'image': '🧃', 'category': 'drinks', 'priority': 'high'},
        {'text': 'crackers', 'image': '🍘', 'category': 'food', 'priority': 'medium'},
        {'text': 'milk', 'image': '🥛', 'category': 'drinks', 'priority': 'medium'},
        
        // Sensory-preferred items
        {'text': 'fidget toy', 'image': '🟡', 'category': 'sensory', 'priority': 'high'},
        {'text': 'music', 'image': '🎵', 'category': 'sensory', 'priority': 'high'},
        {'text': 'bubbles', 'image': '🫧', 'category': 'sensory', 'priority': 'medium'},
        {'text': 'swing', 'image': '🪆', 'category': 'sensory', 'priority': 'medium'},
        
        // Interactive toys
        {'text': 'tablet', 'image': '📱', 'category': 'tech', 'priority': 'high'},
        {'text': 'book', 'image': '📚', 'category': 'items', 'priority': 'medium'},
        {'text': 'puzzle', 'image': '🧩', 'category': 'toys', 'priority': 'medium'},
        {'text': 'blocks', 'image': '🧱', 'category': 'toys', 'priority': 'medium'},
      ]
    },
    {
      'title': 'Greetings & Social',
      'emoji': '👋',
      'color': Colors.blue,
      'description': 'Connect with others through greetings',
      'type': 'greetings',
      'engagement_strategies': ['social_scripts', 'routine_based', 'peer_modeling'],
      'symbols': [
        // Essential greetings
        {'text': 'Hi', 'image': '👋', 'category': 'greeting', 'priority': 'high'},
        {'text': 'Hello', 'image': '😊', 'category': 'greeting', 'priority': 'high'},
        {'text': 'Bye', 'image': '👋', 'category': 'farewell', 'priority': 'high'},
        
        // Time-based greetings (visual schedule support)
        {'text': 'Good morning', 'image': '🌅', 'category': 'greeting', 'priority': 'medium'},
        {'text': 'Good afternoon', 'image': '☀️', 'category': 'greeting', 'priority': 'medium'},
        {'text': 'Good night', 'image': '🌙', 'category': 'farewell', 'priority': 'medium'},
        
        // Social politeness
        {'text': 'Thank you', 'image': '🙏', 'category': 'polite', 'priority': 'high'},
        {'text': 'You\'re welcome', 'image': '🤝', 'category': 'polite', 'priority': 'medium'},
        {'text': 'Excuse me', 'image': '🙋‍♂️', 'category': 'polite', 'priority': 'medium'},
        
        // Social interaction
        {'text': 'My turn', 'image': '☝️', 'category': 'turn_taking', 'priority': 'high'},
        {'text': 'Your turn', 'image': '👉', 'category': 'turn_taking', 'priority': 'high'},
        {'text': 'Let\'s play', 'image': '🎮', 'category': 'play', 'priority': 'medium'},
        {'text': 'Come here', 'image': '🤝', 'category': 'invitation', 'priority': 'medium'},
      ]
    },
    {
      'title': 'Comments & Sharing',
      'emoji': '💭',
      'color': Colors.orange,
      'description': 'Share observations and experiences',
      'type': 'comments',
      'engagement_strategies': ['joint_attention', 'shared_interests', 'commenting_routines'],
      'symbols': [
        // Attention-getting (essential for ASD)
        {'text': 'Look!', 'image': '👀', 'category': 'attention', 'priority': 'high'},
        {'text': 'See!', 'image': '👁️', 'category': 'attention', 'priority': 'high'},
        {'text': 'Watch me!', 'image': '📺', 'category': 'attention', 'priority': 'high'},
        
        // Positive comments (motivation building)
        {'text': 'I like it', 'image': '👍', 'category': 'comment', 'priority': 'high'},
        {'text': 'That\'s cool!', 'image': '😎', 'category': 'comment', 'priority': 'high'},
        {'text': 'Wow!', 'image': '😮', 'category': 'exclamation', 'priority': 'medium'},
        {'text': 'Amazing!', 'image': '🤩', 'category': 'comment', 'priority': 'medium'},
        
        // Descriptive comments
        {'text': 'It\'s big', 'image': '📏', 'category': 'describe', 'priority': 'medium'},
        {'text': 'It\'s small', 'image': '🔬', 'category': 'describe', 'priority': 'medium'},
        {'text': 'It\'s fast', 'image': '💨', 'category': 'describe', 'priority': 'medium'},
        {'text': 'It\'s loud', 'image': '🔊', 'category': 'describe', 'priority': 'medium'},
        {'text': 'It\'s soft', 'image': '🪶', 'category': 'describe', 'priority': 'medium'},
        
        // Experience sharing
        {'text': 'I did it!', 'image': '🏆', 'category': 'achievement', 'priority': 'high'},
        {'text': 'I made it!', 'image': '🔨', 'category': 'achievement', 'priority': 'medium'},
        {'text': 'It works!', 'image': '✅', 'category': 'success', 'priority': 'medium'},
      ]
    },
    {
      'title': 'Questions & Learning',
      'emoji': '❓',
      'color': Colors.purple,
      'description': 'Ask questions to understand the world',
      'type': 'questions',
      'engagement_strategies': ['structured_questioning', 'visual_prompts', 'scaffolded_inquiry'],
      'symbols': [
        // WH question starters (critical for language development)
        {'text': 'What', 'image': '❓', 'category': 'question', 'priority': 'high'},
        {'text': 'Where', 'image': '📍', 'category': 'question', 'priority': 'high'},
        {'text': 'Who', 'image': '👤', 'category': 'question', 'priority': 'high'},
        {'text': 'When', 'image': '⏰', 'category': 'question', 'priority': 'medium'},
        {'text': 'Why', 'image': '🤔', 'category': 'question', 'priority': 'medium'},
        {'text': 'How', 'image': '⚙️', 'category': 'question', 'priority': 'medium'},
        
        // Question completers
        {'text': 'is that?', 'image': '👉', 'category': 'follow-up', 'priority': 'high'},
        {'text': 'are you?', 'image': '🫵', 'category': 'follow-up', 'priority': 'medium'},
        {'text': 'is it?', 'image': '💭', 'category': 'follow-up', 'priority': 'high'},
        {'text': 'does it go?', 'image': '🚗', 'category': 'follow-up', 'priority': 'medium'},
        
        // Information seeking
        {'text': 'Can I?', 'image': '🙋‍♂️', 'category': 'permission', 'priority': 'high'},
        {'text': 'May I?', 'image': '🙏', 'category': 'permission', 'priority': 'medium'},
        {'text': 'Do you have?', 'image': '🤲', 'category': 'inquiry', 'priority': 'medium'},
        {'text': 'Is it time?', 'image': '⏰', 'category': 'schedule', 'priority': 'high'},
        
        // Learning questions
        {'text': 'How do you?', 'image': '🧭', 'category': 'learning', 'priority': 'medium'},
        {'text': 'Show me', 'image': '👁️', 'category': 'learning', 'priority': 'high'},
      ]
    },
    {
      'title': 'Protest & Boundaries',
      'emoji': '✋',
      'color': Colors.red,
      'description': 'Express when you don\'t want something',
      'type': 'protest',
      'engagement_strategies': ['choice_making', 'self_advocacy', 'communication_alternatives'],
      'symbols': [
        // Essential protest vocabulary (prevents challenging behaviors)
        {'text': 'No', 'image': '❌', 'category': 'reject', 'priority': 'high'},
        {'text': 'Stop', 'image': '🛑', 'category': 'protest', 'priority': 'high'},
        {'text': 'All done', 'image': '✋', 'category': 'finished', 'priority': 'high'},
        
        // Self-advocacy
        {'text': 'I don\'t want', 'image': '🙅‍♂️', 'category': 'reject', 'priority': 'high'},
        {'text': 'I don\'t like', 'image': '👎', 'category': 'reject', 'priority': 'high'},
        {'text': 'Not now', 'image': '⏰', 'category': 'delay', 'priority': 'medium'},
        {'text': 'Later', 'image': '⏳', 'category': 'delay', 'priority': 'medium'},
        
        // Problem-solving
        {'text': 'Help me', 'image': '🆘', 'category': 'request', 'priority': 'high'},
        {'text': 'I can\'t', 'image': '🚫', 'category': 'difficulty', 'priority': 'medium'},
        {'text': 'Too hard', 'image': '💪', 'category': 'difficulty', 'priority': 'medium'},
        {'text': 'Break please', 'image': '⏸️', 'category': 'pause', 'priority': 'high'},
        
        // Choice alternatives
        {'text': 'Different', 'image': '🔄', 'category': 'choice', 'priority': 'medium'},
        {'text': 'Something else', 'image': '➡️', 'category': 'choice', 'priority': 'medium'},
        {'text': 'My choice', 'image': '☝️', 'category': 'autonomy', 'priority': 'medium'},
        
        // Sensory needs
        {'text': 'Too loud', 'image': '🔊', 'category': 'sensory', 'priority': 'high'},
        {'text': 'Too bright', 'image': '🔆', 'category': 'sensory', 'priority': 'high'},
      ]
    },
    {
      'title': 'Emotions & Feelings',
      'emoji': '😊',
      'color': Colors.pink,
      'description': 'Express how you feel inside',
      'type': 'emotions',
      'engagement_strategies': ['emotion_regulation', 'visual_emotion_scales', 'feeling_thermometer'],
      'symbols': [
        // Emotion starter
        {'text': 'I feel', 'image': '💭', 'category': 'core', 'priority': 'high'},
        
        // Basic emotions (essential for emotional regulation)
        {'text': 'happy', 'image': '😊', 'category': 'emotion', 'priority': 'high'},
        {'text': 'sad', 'image': '😢', 'category': 'emotion', 'priority': 'high'},
        {'text': 'angry', 'image': '😠', 'category': 'emotion', 'priority': 'high'},
        {'text': 'scared', 'image': '😨', 'category': 'emotion', 'priority': 'high'},
        
        // Complex emotions (for advanced users)
        {'text': 'excited', 'image': '🤩', 'category': 'emotion', 'priority': 'medium'},
        {'text': 'frustrated', 'image': '😤', 'category': 'emotion', 'priority': 'high'},
        {'text': 'worried', 'image': '😟', 'category': 'emotion', 'priority': 'medium'},
        {'text': 'confused', 'image': '😕', 'category': 'emotion', 'priority': 'medium'},
        {'text': 'proud', 'image': '😌', 'category': 'emotion', 'priority': 'medium'},
        
        // Physical feelings (important for ASD sensory awareness)
        {'text': 'tired', 'image': '😴', 'category': 'physical', 'priority': 'high'},
        {'text': 'hungry', 'image': '🍽️', 'category': 'physical', 'priority': 'high'},
        {'text': 'thirsty', 'image': '💧', 'category': 'physical', 'priority': 'high'},
        {'text': 'sick', 'image': '🤒', 'category': 'physical', 'priority': 'medium'},
        {'text': 'hot', 'image': '🥵', 'category': 'physical', 'priority': 'medium'},
        {'text': 'cold', 'image': '🥶', 'category': 'physical', 'priority': 'medium'},
        
        // Sensory descriptions
        {'text': 'overwhelmed', 'image': '🌀', 'category': 'sensory', 'priority': 'high'},
        {'text': 'calm', 'image': '😌', 'category': 'regulation', 'priority': 'high'},
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
    
    // Enhanced feedback for ASD users
    AACHelper.speak(text);
    
    // Provide visual feedback
    _showSuccessAnimation(text);
  }

  void _showSuccessAnimation(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Added: "$text" 🎉 Keep building your message!'),
            ),
          ],
        ),
        backgroundColor: _interactiveGoals[_selectedGoalIndex]['color'],
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
        middle: const Text(
          'Interactive AAC Goals',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.book, color: Colors.white),
              onPressed: () => _showPracticeInfo(),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.game_controller, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const StoryModeScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
      child: Column(
        children: [
          // Message Builder Section
          _buildMessageBuilder(),
          
          // Goal Tabs
          _buildGoalTabs(),
          
          // Interactive Activity
          Expanded(
            child: _buildInteractiveActivity(),
          ),
        ],
      ),
    );
  }

  void _showPracticeInfo() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('📖 Practice Mode'),
        content: const Text(
          'Practice Mode helps build real-world communication skills!\n\n'
          '🎯 Guided scenarios\n'
          '📅 Daily routines\n'
          '⭐ Priority symbols (★★★ = most important)\n'
          '🎉 Celebration feedback\n\n'
          'Look for red stars on high-priority symbols!',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Got it!'),
            onPressed: () => Navigator.pop(context),
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
            offset: const Offset(0, 4),
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
        
        final tabWidth = isLandscape ? screenWidth * 0.15 : screenWidth * 0.25;
        final tabHeight = isLandscape ? 70.0 : 85.0;
        
        return Container(
          height: tabHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _interactiveGoals.length,
            itemBuilder: (context, index) {
              final goal = _interactiveGoals[index];
              final isSelected = index == _selectedGoalIndex;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGoalIndex = index;
                  });
                },
                child: Container(
                  width: tabWidth,
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? goal['color'] : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: goal['color'],
                      width: 2,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: goal['color'].withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ] : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        goal['emoji'],
                        style: TextStyle(
                          fontSize: isLandscape ? 20 : 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        goal['title'],
                        style: TextStyle(
                          fontSize: isLandscape ? 10 : 12,
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
    
    // Sort symbols by priority - high priority first for ASD engagement
    symbols.sort((a, b) {
      final priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
      final aPriority = priorityOrder[a['priority']] ?? 3;
      final bPriority = priorityOrder[b['priority']] ?? 3;
      return aPriority.compareTo(bPriority);
    });

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Activity Instructions with ASD-friendly design
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: currentGoal['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: currentGoal['color'].withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: currentGoal['color'],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        currentGoal['emoji'],
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
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
                          Text(
                            currentGoal['description'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Engagement strategies indicator
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getActivityInstructions(currentGoal['type']),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                
                // Priority legend for caregivers
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildPriorityIndicator('High Priority', Colors.red, '★★★'),
                    const SizedBox(width: 12),
                    _buildPriorityIndicator('Medium Priority', Colors.orange, '★★'),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Symbol Grid with priority grouping
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isLandscape = constraints.maxWidth > constraints.maxHeight;
                final crossAxisCount = isLandscape ? 4 : 3;
                final aspectRatio = isLandscape ? 1.2 : 1.1;
                
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: aspectRatio,
                    crossAxisSpacing: constraints.maxWidth * 0.02,
                    mainAxisSpacing: constraints.maxWidth * 0.02,
                  ),
                  itemCount: symbols.length,
                  itemBuilder: (context, index) =>
                      _buildEnhancedSymbolCard(symbols[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSymbolCard(Map<String, dynamic> symbol) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        final cardWidth = constraints.maxWidth;
        final cardHeight = constraints.maxHeight;
        
        // Calculate responsive sizes with ASD-friendly scaling
        final emojiSize = isLandscape ? cardWidth * 0.35 : cardWidth * 0.4;
        final fontSize = isLandscape ? cardWidth * 0.08 : cardWidth * 0.09;
        
        // Priority-based styling for better visual hierarchy
        final priority = symbol['priority'] ?? 'medium';
        Color borderColor;
        Color priorityColor;
        switch (priority) {
          case 'high':
            borderColor = Colors.red.withOpacity(0.4);
            priorityColor = Colors.red;
            break;
          case 'medium':
            borderColor = Colors.orange.withOpacity(0.4);
            priorityColor = Colors.orange;
            break;
          default:
            borderColor = Colors.grey.withOpacity(0.3);
            priorityColor = Colors.grey;
        }

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
                    color: priorityColor.withOpacity(0.15),
                    blurRadius: priority == 'high' ? 12 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: borderColor,
                  width: priority == 'high' ? 3 : 2,
                ),
              ),
              child: Stack(
                children: [
                  // Priority indicator in corner
                  if (priority == 'high')
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  
                  // Main content
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Large emoji/icon with enhanced size for ASD
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: priority == 'high' 
                              ? priorityColor.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          symbol['image'],
                          style: TextStyle(
                            fontSize: emojiSize.clamp(28, 52),
                          ),
                        ),
                      ),
                      SizedBox(height: cardHeight * 0.08),
                      
                      // Text label with better contrast
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: cardWidth * 0.08),
                        child: Text(
                          symbol['text'],
                          style: TextStyle(
                            fontSize: fontSize.clamp(11, 15),
                            fontWeight: priority == 'high' ? FontWeight.w800 : FontWeight.bold,
                            color: priority == 'high' ? Colors.black : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriorityIndicator(String label, Color color, String stars) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          stars,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getActivityInstructions(String type) {
    switch (type) {
      case 'request':
        return '🎯 Start with "I want" + item + "please". Essential for getting your needs met! Look for high priority symbols with ★★★ stars.';
      case 'greetings':
        return '👋 Use greetings to connect with others. Practice when arriving, meeting friends, or at bedtime. High priority symbols help build social connections.';
      case 'comments':
        return '💭 Share what you notice! Comment on toys, activities, or things around you. Start with attention-getters like "Look!" Great for building social connections.';
      case 'questions':
        return '❓ Ask questions to learn more! Start with WH-words (What, Where, Who). High priority symbols are most important for daily communication.';
      case 'protest':
        return '✋ It\'s okay to say no! Use these when overwhelmed or need a break. High priority symbols prevent challenging behaviors and build self-advocacy.';
      case 'emotions':
        return '😊 Tell others how you feel inside. Start with "I feel..." Very important for emotional regulation. High priority emotions are most commonly needed.';
      default:
        return '📱 Tap symbols to build your message! ★★★ = most important symbols to learn first.';
    }
  }
}
