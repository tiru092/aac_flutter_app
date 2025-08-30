import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../models/enhanced_goal.dart';
import '../models/goal.dart';
import '../services/arasaac_service.dart';
import '../utils/aac_helper.dart';

class GoalPracticeScreen extends StatefulWidget {
  final EnhancedGoal goal;

  const GoalPracticeScreen({
    super.key,
    required this.goal,
  });

  @override
  State<GoalPracticeScreen> createState() => _GoalPracticeScreenState();
}

class _GoalPracticeScreenState extends State<GoalPracticeScreen>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late AnimationController _progressController;
  late Animation<double> _celebrationAnimation;

  int _currentSessionProgress = 0;
  int _sessionTarget = 3; // Default session target
  bool _sessionCompleted = false;
  List<Map<String, dynamic>> _practiceItems = [];
  int _currentItemIndex = 0;
  String _feedback = '';
  bool _showingFeedback = false;
  String? _selectedEmotion;
  Set<int> _completedActivities = {};

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializePracticeSession();
  }

  void _setupAnimations() {
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _celebrationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _initializePracticeSession() {
    switch (widget.goal.category) {
      case GoalCategory.communication:
        _initializeCommunicationPractice();
        break;
      case GoalCategory.emotional:
        _initializeEmotionalPractice();
        break;
      case GoalCategory.social:
        _initializeSocialPractice();
        break;
      case GoalCategory.learning:
        _initializeLearningPractice();
        break;
      case GoalCategory.dailyLiving:
        _initializeDailyLivingPractice();
        break;
      case GoalCategory.routine:
        _initializeRoutinePractice();
        break;
    }
  }

  void _initializeCommunicationPractice() {
    if (widget.goal.title.toLowerCase().contains('please') ||
        widget.goal.title.toLowerCase().contains('thank')) {
      _practiceItems = [
        {
          'scenario': 'You want a snack from the kitchen',
          'correctPhrase': 'Please may I have a snack?',
          'symbols': ['please', 'snack', 'I', 'want'],
          'arasaacIds': [2588, 7082, 7574, 2419], // Real ARASAAC IDs
          'hint': 'Remember to say please when asking for something',
          'difficulty': 1,
        },
        {
          'scenario': 'Your friend shares their toy with you',
          'correctPhrase': 'Thank you for sharing!',
          'symbols': ['thank', 'you', 'sharing', 'friend'],
          'arasaacIds': [2589, 7575, 2421, 2425],
          'hint': 'Show gratitude when someone is kind to you',
          'difficulty': 1,
        },
        {
          'scenario': 'You need help opening a bottle',
          'correctPhrase': 'Please can you help me?',
          'symbols': ['please', 'help', 'me', 'you'],
          'arasaacIds': [2588, 2420, 7576, 7575],
          'hint': 'Use polite words when asking for assistance',
          'difficulty': 2,
        },
        {
          'scenario': 'Teacher explains something difficult',
          'correctPhrase': 'Thank you for explaining',
          'symbols': ['thank', 'you', 'explain', 'teacher'],
          'arasaacIds': [2589, 7575, 8901, 3090],
          'hint': 'Thank people who help you learn',
          'difficulty': 2,
        },
        {
          'scenario': 'You want to join a group activity',
          'correctPhrase': 'Please may I join you?',
          'symbols': ['please', 'join', 'I', 'activity'],
          'arasaacIds': [2588, 8902, 7574, 2422],
          'hint': 'Ask permission before joining others',
          'difficulty': 3,
        },
      ];
    } else if (widget.goal.title.toLowerCase().contains('greeting')) {
      _practiceItems = [
        {
          'scenario': 'Meeting your teacher in the morning',
          'correctPhrase': 'Good morning!',
          'symbols': ['good', 'morning', 'hello', 'teacher'],
          'arasaacIds': [2590, 2591, 2592, 3090],
          'hint': 'Greet people when you see them',
          'difficulty': 1,
        },
        {
          'scenario': 'Leaving school at the end of the day',
          'correctPhrase': 'Goodbye, see you tomorrow!',
          'symbols': ['goodbye', 'see', 'you', 'tomorrow'],
          'arasaacIds': [2593, 7577, 7575, 2594],
          'hint': 'Say goodbye when leaving',
          'difficulty': 1,
        },
        {
          'scenario': 'Meeting a new child at the playground',
          'correctPhrase': 'Hi, my name is...',
          'symbols': ['hello', 'my', 'name', 'friend'],
          'arasaacIds': [2592, 7578, 7579, 2425],
          'hint': 'Introduce yourself to new people',
          'difficulty': 2,
        },
      ];
    }
    _sessionTarget = _practiceItems.length;
  }

  void _initializeEmotionalPractice() {
    _practiceItems = [
      {
        'scenario': 'Your favorite toy breaks accidentally',
        'emotion': 'sad',
        'correctPhrase': 'I feel sad because my toy broke',
        'symbols': ['I', 'feel', 'sad', 'toy', 'broken'],
        'arasaacIds': [7574, 2424, 2432, 2423, 8903],
        'color': Colors.blue,
        'hint': 'It\'s okay to feel sad when something breaks',
        'copingStrategy': 'Take deep breaths and ask for help to fix it',
        'difficulty': 1,
      },
      {
        'scenario': 'You receive a surprise gift from family',
        'emotion': 'happy',
        'correctPhrase': 'I feel very happy and excited!',
        'symbols': ['I', 'feel', 'happy', 'excited', 'gift'],
        'arasaacIds': [7574, 2424, 2431, 2434, 8904],
        'color': Colors.yellow,
        'hint': 'Express joy when good things happen',
        'copingStrategy': 'Share your happiness with others',
        'difficulty': 1,
      },
      {
        'scenario': 'There\'s a loud thunderstorm outside',
        'emotion': 'scared',
        'correctPhrase': 'I feel scared of the thunder',
        'symbols': ['I', 'feel', 'scared', 'thunder', 'loud'],
        'arasaacIds': [7574, 2424, 2433, 8905, 8906],
        'color': Colors.purple,
        'hint': 'It\'s normal to feel scared of loud noises',
        'copingStrategy': 'Stay with someone you trust and use calm breathing',
        'difficulty': 2,
      },
      {
        'scenario': 'Someone takes your turn without asking',
        'emotion': 'angry',
        'correctPhrase': 'I feel angry when you don\'t wait',
        'symbols': ['I', 'feel', 'angry', 'wait', 'turn'],
        'arasaacIds': [7574, 2424, 8907, 8908, 8909],
        'color': Colors.red,
        'hint': 'Express anger with words, not actions',
        'copingStrategy': 'Use calm voice and ask for fairness',
        'difficulty': 3,
      },
      {
        'scenario': 'You have to speak in front of the class',
        'emotion': 'nervous',
        'correctPhrase': 'I feel nervous about speaking',
        'symbols': ['I', 'feel', 'nervous', 'speak', 'class'],
        'arasaacIds': [7574, 2424, 8910, 2592, 8911],
        'color': Colors.orange,
        'hint': 'Nervousness is normal before new experiences',
        'copingStrategy': 'Practice what you want to say and breathe slowly',
        'difficulty': 3,
      },
    ];
    _sessionTarget = 4; // Practice 4 out of 5 emotions per session
  }

  void _initializeSocialPractice() {
    if (widget.goal.title.toLowerCase().contains('help')) {
      _practiceItems = [
        {
          'scenario': 'You can\'t reach something on a high shelf',
          'correctPhrase': 'Excuse me, I need help please',
          'symbols': ['excuse', 'me', 'need', 'help', 'please'],
          'arasaacIds': [8912, 7576, 2435, 2420, 2588],
          'action': 'Ask for help',
          'socialSkill': 'Polite request',
          'difficulty': 1,
        },
        {
          'scenario': 'Your homework is too difficult to understand',
          'correctPhrase': 'Can you help me understand this?',
          'symbols': ['can', 'you', 'help', 'understand', 'homework'],
          'arasaacIds': [8913, 7575, 2420, 8914, 8915],
          'action': 'Ask for help',
          'socialSkill': 'Academic assistance',
          'difficulty': 2,
        },
        {
          'scenario': 'You see someone struggling with heavy bags',
          'correctPhrase': 'Would you like me to help?',
          'symbols': ['would', 'you', 'like', 'help', 'carry'],
          'arasaacIds': [8916, 7575, 8917, 2420, 8918],
          'action': 'Offer help',
          'socialSkill': 'Helping others',
          'difficulty': 2,
        },
        {
          'scenario': 'Your friend looks upset and confused',
          'correctPhrase': 'Are you okay? Can I help?',
          'symbols': ['are', 'you', 'okay', 'help', 'friend'],
          'arasaacIds': [8919, 7575, 8920, 2420, 2425],
          'action': 'Offer emotional support',
          'socialSkill': 'Empathy and care',
          'difficulty': 3,
        },
      ];
    } else if (widget.goal.title.toLowerCase().contains('share')) {
      _practiceItems = [
        {
          'scenario': 'You have extra crayons and your friend needs one',
          'correctPhrase': 'You can use my crayons',
          'symbols': ['you', 'can', 'use', 'my', 'crayons'],
          'arasaacIds': [7575, 8913, 8921, 7578, 8922],
          'action': 'Share materials',
          'socialSkill': 'Generosity',
          'difficulty': 1,
        },
        {
          'scenario': 'Your lunch has your favorite snack and extra',
          'correctPhrase': 'Would you like to share my snack?',
          'symbols': ['would', 'you', 'like', 'share', 'snack'],
          'arasaacIds': [8916, 7575, 8917, 2421, 7082],
          'action': 'Share food',
          'socialSkill': 'Kindness',
          'difficulty': 2,
        },
        {
          'scenario': 'You\'re playing a fun game and others want to join',
          'correctPhrase': 'Come and play with us!',
          'symbols': ['come', 'play', 'with', 'us', 'join'],
          'arasaacIds': [8923, 2422, 8924, 8925, 8902],
          'action': 'Share activities',
          'socialSkill': 'Inclusion',
          'difficulty': 2,
        },
      ];
    }
    _sessionTarget = _practiceItems.length;
  }

  void _initializeLearningPractice() {
    // Comprehensive vocabulary with proper ARASAAC IDs
    final vocabularyByCategory = {
      'food': [
        {'word': 'Apple', 'arasaacId': 7000, 'description': 'A red or green fruit'},
        {'word': 'Bread', 'arasaacId': 7001, 'description': 'Food made from flour'},
        {'word': 'Milk', 'arasaacId': 7002, 'description': 'White drink from cows'},
        {'word': 'Banana', 'arasaacId': 7003, 'description': 'Yellow curved fruit'},
        {'word': 'Water', 'arasaacId': 7004, 'description': 'Clear liquid we drink'},
      ],
      'emotions': [
        {'word': 'Happy', 'arasaacId': 2431, 'description': 'Feeling good and joyful'},
        {'word': 'Sad', 'arasaacId': 2432, 'description': 'Feeling down or upset'},
        {'word': 'Angry', 'arasaacId': 8907, 'description': 'Feeling mad or frustrated'},
        {'word': 'Excited', 'arasaacId': 2434, 'description': 'Feeling very happy and energetic'},
        {'word': 'Calm', 'arasaacId': 8926, 'description': 'Feeling peaceful and relaxed'},
      ],
      'actions': [
        {'word': 'Walk', 'arasaacId': 7005, 'description': 'Move by putting one foot in front of the other'},
        {'word': 'Run', 'arasaacId': 7006, 'description': 'Move quickly on your feet'},
        {'word': 'Jump', 'arasaacId': 7007, 'description': 'Push off the ground with your feet'},
        {'word': 'Dance', 'arasaacId': 7008, 'description': 'Move your body to music'},
        {'word': 'Read', 'arasaacId': 7009, 'description': 'Look at words and understand them'},
      ],
      'people': [
        {'word': 'Mother', 'arasaacId': 7010, 'description': 'Female parent'},
        {'word': 'Father', 'arasaacId': 7011, 'description': 'Male parent'},
        {'word': 'Teacher', 'arasaacId': 3090, 'description': 'Person who helps you learn'},
        {'word': 'Friend', 'arasaacId': 2425, 'description': 'Someone you like and play with'},
        {'word': 'Doctor', 'arasaacId': 7012, 'description': 'Person who helps when you\'re sick'},
      ],
      'objects': [
        {'word': 'Book', 'arasaacId': 2427, 'description': 'Object with pages to read'},
        {'word': 'Ball', 'arasaacId': 7013, 'description': 'Round object to play with'},
        {'word': 'Car', 'arasaacId': 7014, 'description': 'Vehicle that drives on roads'},
        {'word': 'House', 'arasaacId': 11975, 'description': 'Building where people live'},
        {'word': 'Phone', 'arasaacId': 7015, 'description': 'Device to talk to people far away'},
      ],
    };

    // Select words from different categories for balanced learning
    final selectedWords = <Map<String, dynamic>>[];
    vocabularyByCategory.forEach((category, words) {
      selectedWords.add({
        ...words[0], // Take first word from each category
        'category': category,
        'practiced': false,
        'attempts': 0,
        'mastered': false,
      });
    });

    _practiceItems = selectedWords;
    _sessionTarget = selectedWords.length;
  }

  void _initializeDailyLivingPractice() {
    _practiceItems = [
      {
        'mealTime': 'Breakfast',
        'scenario': 'What would you like for breakfast?',
        'options': [
          {'name': 'Cereal', 'arasaacId': 7020, 'phrase': 'I would like cereal please'},
          {'name': 'Toast', 'arasaacId': 7021, 'phrase': 'I want toast with butter please'},
          {'name': 'Eggs', 'arasaacId': 7022, 'phrase': 'Can I have eggs please'},
          {'name': 'Fruit', 'arasaacId': 7023, 'phrase': 'I would like some fruit please'},
        ],
        'context': 'Morning meal communication',
        'difficulty': 1,
      },
      {
        'mealTime': 'Lunch',
        'scenario': 'What do you want for lunch today?',
        'options': [
          {'name': 'Sandwich', 'arasaacId': 7024, 'phrase': 'I want a sandwich please'},
          {'name': 'Soup', 'arasaacId': 7025, 'phrase': 'Can I have soup please'},
          {'name': 'Salad', 'arasaacId': 7026, 'phrase': 'I would like a salad please'},
          {'name': 'Pizza', 'arasaacId': 7027, 'phrase': 'I want pizza please'},
        ],
        'context': 'Midday meal communication',
        'difficulty': 2,
      },
      {
        'mealTime': 'Dinner',
        'scenario': 'What would you prefer for dinner?',
        'options': [
          {'name': 'Pasta', 'arasaacId': 7028, 'phrase': 'I would like pasta for dinner'},
          {'name': 'Chicken', 'arasaacId': 7029, 'phrase': 'Can I have chicken please'},
          {'name': 'Rice', 'arasaacId': 7030, 'phrase': 'I want rice with vegetables'},
          {'name': 'Fish', 'arasaacId': 7031, 'phrase': 'I would like fish please'},
        ],
        'context': 'Evening meal communication',
        'difficulty': 2,
      },
      {
        'mealTime': 'Snack Time',
        'scenario': 'You\'re hungry between meals',
        'options': [
          {'name': 'Apple', 'arasaacId': 7000, 'phrase': 'May I have an apple please'},
          {'name': 'Crackers', 'arasaacId': 7032, 'phrase': 'Can I have some crackers'},
          {'name': 'Yogurt', 'arasaacId': 7033, 'phrase': 'I would like yogurt please'},
          {'name': 'Cookies', 'arasaacId': 7034, 'phrase': 'May I have one cookie please'},
        ],
        'context': 'Requesting snacks appropriately',
        'difficulty': 1,
      },
    ];
    _sessionTarget = 4; // Practice all meal times
  }

  void _initializeRoutinePractice() {
    _practiceItems = [
      {
        'routineName': 'Morning Routine',
        'time': 'Morning',
        'activities': [
          {
            'name': 'Wake up',
            'arasaacId': 7040,
            'phrase': 'I woke up',
            'order': 1,
            'importance': 'Start the day'
          },
          {
            'name': 'Brush teeth',
            'arasaacId': 7041,
            'phrase': 'I am brushing my teeth',
            'order': 2,
            'importance': 'Personal hygiene'
          },
          {
            'name': 'Get dressed',
            'arasaacId': 7042,
            'phrase': 'I am getting dressed',
            'order': 3,
            'importance': 'Preparing for the day'
          },
          {
            'name': 'Eat breakfast',
            'arasaacId': 7043,
            'phrase': 'I am eating breakfast',
            'order': 4,
            'importance': 'Morning nutrition'
          },
          {
            'name': 'Go to school',
            'arasaacId': 7044,
            'phrase': 'I am going to school',
            'order': 5,
            'importance': 'Daily education'
          },
        ],
        'difficulty': 1,
      },
      {
        'routineName': 'Evening Routine',
        'time': 'Evening',
        'activities': [
          {
            'name': 'Come home',
            'arasaacId': 7045,
            'phrase': 'I came home',
            'order': 1,
            'importance': 'Returning home'
          },
          {
            'name': 'Do homework',
            'arasaacId': 7046,
            'phrase': 'I am doing homework',
            'order': 2,
            'importance': 'Learning responsibility'
          },
          {
            'name': 'Eat dinner',
            'arasaacId': 7047,
            'phrase': 'I am eating dinner',
            'order': 3,
            'importance': 'Evening nutrition'
          },
          {
            'name': 'Take a bath',
            'arasaacId': 7048,
            'phrase': 'I am taking a bath',
            'order': 4,
            'importance': 'Evening hygiene'
          },
          {
            'name': 'Go to bed',
            'arasaacId': 7049,
            'phrase': 'I am going to bed',
            'order': 5,
            'importance': 'Rest and sleep'
          },
        ],
        'difficulty': 2,
      },
    ];
    _sessionTarget = 2; // Practice both routines
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Practice: ${widget.goal.title}',
          style: const TextStyle(fontSize: 16),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context, _currentSessionProgress),
        ),
        trailing: _buildProgressIndicator(),
      ),
      child: SafeArea(
        child: _sessionCompleted 
            ? _buildSessionCompleteView()
            : _buildPracticeView(),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$_currentSessionProgress/$_sessionTarget',
        style: const TextStyle(
          color: CupertinoColors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPracticeView() {
    if (_practiceItems.isEmpty) {
      return const Center(
        child: Text('No practice items available'),
      );
    }

    switch (widget.goal.category) {
      case GoalCategory.communication:
        return _buildCommunicationPractice();
      case GoalCategory.emotional:
        return _buildEmotionalPractice();
      case GoalCategory.social:
        return _buildSocialPractice();
      case GoalCategory.learning:
        return _buildLearningPractice();
      case GoalCategory.dailyLiving:
        return _buildDailyLivingPractice();
      case GoalCategory.routine:
        return _buildRoutinePractice();
    }
  }

  Widget _buildCommunicationPractice() {
    if (_currentItemIndex >= _practiceItems.length) return Container();
    
    final item = _practiceItems[_currentItemIndex];
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildDifficultyIndicator(item['difficulty'] as int),
          const SizedBox(height: 10),
          _buildScenarioCard(item['scenario'] as String),
          const SizedBox(height: 20),
          _buildHintCard(item['hint'] as String),
          const SizedBox(height: 30),
          _buildSymbolsGrid(
            item['symbols'] as List<String>,
            item['arasaacIds'] as List<int>,
          ),
          const SizedBox(height: 20),
          _buildCorrectPhraseDisplay(item['correctPhrase'] as String),
          const SizedBox(height: 30),
          _buildPracticeButtons(),
          if (_showingFeedback) _buildFeedbackCard(),
        ],
      ),
    );
  }

  Widget _buildEmotionalPractice() {
    if (_currentItemIndex >= _practiceItems.length) return Container();
    
    final item = _practiceItems[_currentItemIndex];
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildDifficultyIndicator(item['difficulty'] as int),
          const SizedBox(height: 10),
          _buildScenarioCard(item['scenario'] as String),
          const SizedBox(height: 20),
          _buildHintCard(item['hint'] as String),
          const SizedBox(height: 30),
          _buildEmotionOptions(item),
          const SizedBox(height: 20),
          _buildSelectedEmotionDisplay(item),
          const SizedBox(height: 20),
          _buildCopingStrategyCard(item['copingStrategy'] as String),
          if (_showingFeedback) _buildFeedbackCard(),
        ],
      ),
    );
  }

  Widget _buildSocialPractice() {
    if (_currentItemIndex >= _practiceItems.length) return Container();
    
    final item = _practiceItems[_currentItemIndex];
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildDifficultyIndicator(item['difficulty'] as int),
          const SizedBox(height: 10),
          _buildScenarioCard(item['scenario'] as String),
          const SizedBox(height: 20),
          _buildSocialSkillCard(item['socialSkill'] as String),
          const SizedBox(height: 20),
          _buildActionPrompt(item['action'] as String),
          const SizedBox(height: 30),
          _buildSymbolsGrid(
            item['symbols'] as List<String>,
            item['arasaacIds'] as List<int>,
          ),
          const SizedBox(height: 20),
          _buildCorrectPhraseDisplay(item['correctPhrase'] as String),
          const SizedBox(height: 30),
          _buildPracticeButtons(),
          if (_showingFeedback) _buildFeedbackCard(),
        ],
      ),
    );
  }

  Widget _buildLearningPractice() {
    if (_currentItemIndex >= _practiceItems.length) return Container();
    
    final item = _practiceItems[_currentItemIndex];
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Learn New Word #${_currentItemIndex + 1} of ${_practiceItems.length}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.systemBlue,
            ),
          ),
          const SizedBox(height: 40),
          _buildEnhancedVocabularyCard(item),
          const SizedBox(height: 30),
          _buildVocabularyProgressTracker(item),
          const SizedBox(height: 40),
          _buildEnhancedVocabularyActions(item),
          if (_showingFeedback) _buildFeedbackCard(),
        ],
      ),
    );
  }

  Widget _buildDailyLivingPractice() {
    if (_currentItemIndex >= _practiceItems.length) return Container();
    
    final item = _practiceItems[_currentItemIndex];
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildDifficultyIndicator(item['difficulty'] as int),
          const SizedBox(height: 10),
          _buildMealTimeHeader(item['mealTime'] as String),
          const SizedBox(height: 20),
          _buildScenarioCard(item['scenario'] as String),
          const SizedBox(height: 20),
          _buildContextCard(item['context'] as String),
          const SizedBox(height: 30),
          _buildEnhancedMealOptions(item['options'] as List<Map<String, dynamic>>),
          if (_showingFeedback) _buildFeedbackCard(),
        ],
      ),
    );
  }

  Widget _buildRoutinePractice() {
    if (_currentItemIndex >= _practiceItems.length) return Container();
    
    final item = _practiceItems[_currentItemIndex];
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildDifficultyIndicator(item['difficulty'] as int),
          const SizedBox(height: 10),
          Text(
            item['routineName'] as String,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.systemPurple,
            ),
          ),
          const SizedBox(height: 30),
          _buildEnhancedRoutineActivities(item['activities'] as List<Map<String, dynamic>>),
          const SizedBox(height: 30),
          _buildRoutineCompleteButton(),
          if (_showingFeedback) _buildFeedbackCard(),
        ],
      ),
    );
  }

  Widget _buildDifficultyIndicator(int difficulty) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: difficulty == 1 
            ? CupertinoColors.systemGreen.withOpacity(0.2)
            : difficulty == 2 
            ? CupertinoColors.systemOrange.withOpacity(0.2)
            : CupertinoColors.systemRed.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: difficulty == 1 
              ? CupertinoColors.systemGreen
              : difficulty == 2 
              ? CupertinoColors.systemOrange
              : CupertinoColors.systemRed,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < 3; i++)
            Icon(
              CupertinoIcons.circle_fill,
              size: 8,
              color: i < difficulty 
                  ? (difficulty == 1 
                      ? CupertinoColors.systemGreen
                      : difficulty == 2 
                      ? CupertinoColors.systemOrange
                      : CupertinoColors.systemRed)
                  : CupertinoColors.systemGrey3,
            ),
          const SizedBox(width: 8),
          Text(
            difficulty == 1 ? 'Easy' : difficulty == 2 ? 'Medium' : 'Hard',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: difficulty == 1 
                  ? CupertinoColors.systemGreen
                  : difficulty == 2 
                  ? CupertinoColors.systemOrange
                  : CupertinoColors.systemRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHintCard(String hint) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemYellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.systemYellow),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.lightbulb,
            color: CupertinoColors.systemYellow,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hint,
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: CupertinoColors.label,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorrectPhraseDisplay(String correctPhrase) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.systemGreen),
      ),
      child: Column(
        children: [
          const Text(
            'Target Phrase:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            correctPhrase,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.label,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCopingStrategyCard(String copingStrategy) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemIndigo.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.systemIndigo),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.heart,
                color: CupertinoColors.systemIndigo,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Coping Strategy:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.systemIndigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            copingStrategy,
            style: const TextStyle(
              fontSize: 14,
              color: CupertinoColors.label,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialSkillCard(String socialSkill) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemTeal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.systemTeal),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.person_2,
                color: CupertinoColors.systemTeal,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Social Skill Focus:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.systemTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            socialSkill,
            style: const TextStyle(
              fontSize: 14,
              color: CupertinoColors.label,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedVocabularyCard(Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              item['category'] as String,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemBlue,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                ArasaacService.getPictogramUrl(item['arasaacId'] as int),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    CupertinoIcons.photo,
                    size: 40,
                    color: CupertinoColors.systemGrey,
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const CupertinoActivityIndicator();
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            item['word'] as String,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item['description'] as String,
            style: const TextStyle(
              fontSize: 16,
              color: CupertinoColors.secondaryLabel,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVocabularyProgressTracker(Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildProgressStep('See', true),
          _buildProgressStep('Hear', _showingFeedback),
          _buildProgressStep('Say', false),
          _buildProgressStep('Use', false),
        ],
      ),
    );
  }

  Widget _buildProgressStep(String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive 
                ? CupertinoColors.systemBlue 
                : CupertinoColors.systemGrey4,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isActive 
                ? CupertinoIcons.check_mark 
                : CupertinoIcons.circle,
            color: CupertinoColors.white,
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isActive 
                ? CupertinoColors.systemBlue 
                : CupertinoColors.systemGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedVocabularyActions(Map<String, dynamic> item) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CupertinoButton.filled(
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.speaker_2, size: 20),
                    SizedBox(width: 8),
                    Text('Listen'),
                  ],
                ),
                onPressed: () {
                  _playSound(item['word'] as String);
                  setState(() {
                    _showingFeedback = true;
                  });
                  Timer(const Duration(seconds: 2), () {
                    setState(() {
                      _showingFeedback = false;
                    });
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CupertinoButton(
                color: CupertinoColors.systemGreen,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.mic, size: 20),
                    SizedBox(width: 8),
                    Text('Practice'),
                  ],
                ),
                onPressed: () {
                  _showPracticeDialog(item['word'] as String);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CupertinoButton(
          child: const Text('Next Word'),
          onPressed: _nextItem,
        ),
      ],
    );
  }

  Widget _buildContextCard(String context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.systemPurple),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.info_circle,
                color: CupertinoColors.systemPurple,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Context:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.systemPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context,
            style: const TextStyle(
              fontSize: 14,
              color: CupertinoColors.label,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedMealOptions(List<Map<String, dynamic>> options) {
    return Column(
      children: [
        const Text(
          'Choose your meal option:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.label,
          ),
        ),
        const SizedBox(height: 16),
        ...options.map((option) => _buildMealOptionCard(option)).toList(),
      ],
    );
  }

  Widget _buildMealOptionCard(Map<String, dynamic> option) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _selectMealOption(option),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CupertinoColors.systemGrey4),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    ArasaacService.getPictogramUrl(option['arasaacId'] as int),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        CupertinoIcons.square_favorites,
                        size: 30,
                        color: CupertinoColors.systemGrey,
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const CupertinoActivityIndicator();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option['name'] as String,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label,
                      ),
                    ),
                    Text(
                      option['phrase'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                CupertinoIcons.forward,
                color: CupertinoColors.systemGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedRoutineActivities(List<Map<String, dynamic>> activities) {
    return Column(
      children: activities.asMap().entries.map((entry) {
        final index = entry.key;
        final activity = entry.value;
        return _buildEnhancedRoutineActivityCard(activity, index);
      }).toList(),
    );
  }

  Widget _buildEnhancedRoutineActivityCard(Map<String, dynamic> activity, int index) {
    final isCompleted = _completedActivities.contains(index);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _toggleActivity(index, activity),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isCompleted 
                ? CupertinoColors.systemGreen.withOpacity(0.1)
                : CupertinoColors.systemBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCompleted 
                  ? CupertinoColors.systemGreen 
                  : CupertinoColors.systemGrey4,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    ArasaacService.getPictogramUrl(activity['arasaacId'] as int),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        CupertinoIcons.calendar,
                        size: 30,
                        color: CupertinoColors.systemGrey,
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const CupertinoActivityIndicator();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['name'] as String,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isCompleted 
                            ? CupertinoColors.systemGreen 
                            : CupertinoColors.label,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activity['importance'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isCompleted 
                    ? CupertinoIcons.check_mark_circled_solid
                    : CupertinoIcons.circle,
                color: isCompleted 
                    ? CupertinoColors.systemGreen 
                    : CupertinoColors.systemGrey,
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScenarioCard(String scenario) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: CupertinoColors.systemBlue.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            CupertinoIcons.chat_bubble_text,
            size: 40,
            color: CupertinoColors.systemBlue,
          ),
          const SizedBox(height: 10),
          Text(
            scenario,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSymbolsGrid(List<String> symbols, List<int> arasaacIds) {
    return Wrap(
      spacing: 15,
      runSpacing: 15,
      children: List.generate(symbols.length, (index) {
        return _buildSymbolTile(
          symbols[index],
          arasaacIds.length > index ? arasaacIds[index] : null,
        );
      }),
    );
  }

  Widget _buildSymbolTile(String symbol, int? arasaacId) {
    return GestureDetector(
      onTap: () => _handleSymbolTap(symbol),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: CupertinoColors.systemGrey4,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (arasaacId != null)
              CachedNetworkImage(
                imageUrl: ArasaacService.getPictogramUrl(arasaacId),
                width: 50,
                height: 50,
                placeholder: (context, url) => const CupertinoActivityIndicator(),
                errorWidget: (context, url, error) => const Icon(
                  CupertinoIcons.photo,
                  size: 50,
                  color: CupertinoColors.systemGrey,
                ),
              )
            else
              const Icon(
                CupertinoIcons.chat_bubble,
                size: 50,
                color: CupertinoColors.systemBlue,
              ),
            const SizedBox(height: 5),
            Text(
              symbol,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPracticeButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CupertinoButton.filled(
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.speaker_2, size: 18),
              SizedBox(width: 8),
              Text('Say It'),
            ],
          ),
          onPressed: _handleSayIt,
        ),
        CupertinoButton.filled(
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.checkmark_circle, size: 18),
              SizedBox(width: 8),
              Text('Done'),
            ],
          ),
          onPressed: _handlePracticeDone,
        ),
      ],
    );
  }

  Widget _buildEmotionOptions(Map<String, dynamic> item) {
    final emotions = ['happy', 'sad', 'excited', 'scared', 'angry'];
    final colors = [
      Colors.yellow,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];

    return Wrap(
      spacing: 15,
      runSpacing: 15,
      children: List.generate(emotions.length, (index) {
        final isCorrect = emotions[index] == item['emotion'];
        return GestureDetector(
          onTap: () => _handleEmotionSelection(emotions[index], isCorrect),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colors[index].withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCorrect 
                    ? CupertinoColors.systemGreen 
                    : Colors.transparent,
                width: 3,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _getEmotionEmoji(emotions[index]),
                  style: const TextStyle(fontSize: 30),
                ),
                Text(
                  emotions[index],
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSelectedEmotionDisplay(Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Correct answer: I feel ${item['emotion']}!',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _getEmotionEmoji(item['emotion']),
            style: const TextStyle(fontSize: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPrompt(String action) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: CupertinoColors.systemYellow.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.hand_raised,
            color: CupertinoColors.systemYellow,
          ),
          const SizedBox(width: 10),
          Text(
            'Practice: $action',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVocabularyCard(Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: CupertinoColors.systemBlue,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          if (item['arasaacId'] != null)
            CachedNetworkImage(
              imageUrl: ArasaacService.getPictogramUrl(item['arasaacId']),
              width: 120,
              height: 120,
              placeholder: (context, url) => const CupertinoActivityIndicator(),
              errorWidget: (context, url, error) => const Icon(
                CupertinoIcons.photo,
                size: 120,
                color: CupertinoColors.systemGrey,
              ),
            ),
          const SizedBox(height: 20),
          Text(
            item['word'] as String,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.systemBlue,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Category: ${item['category']}',
            style: const TextStyle(
              fontSize: 16,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVocabularyActions() {
    return Column(
      children: [
        CupertinoButton.filled(
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.speaker_3, size: 20),
              SizedBox(width: 8),
              Text('Listen & Repeat'),
            ],
          ),
          onPressed: _handleListenAndRepeat,
        ),
        const SizedBox(height: 15),
        CupertinoButton(
          child: const Text('I Know This Word!'),
          onPressed: _handleVocabularyDone,
        ),
      ],
    );
  }

  Widget _buildMealTimeHeader(String mealTime) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: CupertinoColors.systemOrange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.time,
            color: CupertinoColors.systemOrange,
            size: 24,
          ),
          const SizedBox(width: 10),
          Text(
            '$mealTime Time',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.systemOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealOptions(List<String> options, List<int> arasaacIds) {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: List.generate(options.length, (index) {
        return GestureDetector(
          onTap: () => _handleMealSelection(options[index]),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: CupertinoColors.systemOrange,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.systemGrey.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (arasaacIds.length > index)
                  CachedNetworkImage(
                    imageUrl: ArasaacService.getPictogramUrl(arasaacIds[index]),
                    width: 60,
                    height: 60,
                    placeholder: (context, url) => const CupertinoActivityIndicator(radius: 15),
                    errorWidget: (context, url, error) => const Icon(
                      CupertinoIcons.square_favorites_alt,
                      size: 60,
                      color: CupertinoColors.systemOrange,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  options[index],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildRoutineActivities(List<String> activities, List<int> arasaacIds) {
    return Column(
      children: List.generate(activities.length, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: CupertinoColors.systemPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CupertinoColors.systemPurple.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              if (arasaacIds.length > index)
                CachedNetworkImage(
                  imageUrl: ArasaacService.getPictogramUrl(arasaacIds[index]),
                  width: 50,
                  height: 50,
                  placeholder: (context, url) => const CupertinoActivityIndicator(radius: 12),
                  errorWidget: (context, url, error) => const Icon(
                    CupertinoIcons.clock,
                    size: 50,
                    color: CupertinoColors.systemPurple,
                  ),
                ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  activities[index],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.checkmark_circle),
                onPressed: () => _handleActivityDone(activities[index]),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildRoutineCompleteButton() {
    return CupertinoButton.filled(
      child: const Text('Complete Routine'),
      onPressed: _handleRoutineComplete,
    );
  }

  Widget _buildFeedbackCard() {
    return AnimatedBuilder(
      animation: _celebrationAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _celebrationAnimation.value,
          child: Container(
            margin: const EdgeInsets.only(top: 20),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CupertinoColors.systemGreen,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.star_fill,
                  color: CupertinoColors.systemYellow,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  _feedback,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.systemGreen,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSessionCompleteView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _celebrationAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.8 + (_celebrationAnimation.value * 0.4),
                  child: const Text(
                    '🎉',
                    style: TextStyle(fontSize: 100),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            const Text(
              'Awesome Job!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: CupertinoColors.systemGreen,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'You completed the practice session!\nYou practiced $_currentSessionProgress/${_sessionTarget} activities.',
              style: const TextStyle(
                fontSize: 18,
                color: CupertinoColors.systemGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            CupertinoButton.filled(
              child: const Text('Continue to Goals'),
              onPressed: () => Navigator.pop(context, _currentSessionProgress),
            ),
          ],
        ),
      ),
    );
  }

  // Event Handlers
  void _handleSymbolTap(String symbol) async {
    await AACHelper.speak(symbol);
  }

  void _handleSayIt() async {
    if (_currentItemIndex < _practiceItems.length) {
      final item = _practiceItems[_currentItemIndex];
      await AACHelper.speak(item['correctPhrase'] as String);
    }
  }

  void _handlePracticeDone() {
    _showFeedback('Great job! Keep practicing!');
    _advanceToNext();
  }

  void _handleEmotionSelection(String emotion, bool isCorrect) async {
    await AACHelper.speak('I feel $emotion');
    
    if (isCorrect) {
      _showFeedback('Perfect! You identified the emotion correctly!');
      _advanceToNext();
    } else {
      _showFeedback('Try again! Think about how you would feel.');
    }
  }

  void _handleListenAndRepeat() async {
    if (_currentItemIndex < _practiceItems.length) {
      final item = _practiceItems[_currentItemIndex];
      await AACHelper.speak(item['word'] as String);
    }
  }

  void _handleVocabularyDone() {
    _showFeedback('New word learned! Well done!');
    _advanceToNext();
  }

  void _handleMealSelection(String meal) async {
    await AACHelper.speak('I want $meal please');
    _showFeedback('Great communication! You asked politely.');
    _advanceToNext();
  }

  void _handleActivityDone(String activity) async {
    await AACHelper.speak('I did $activity');
    _showFeedback('Activity completed!');
  }

  void _handleRoutineComplete() {
    _showFeedback('Routine completed! You\'re doing great!');
    _advanceToNext();
  }

  void _showFeedback(String message) {
    setState(() {
      _feedback = message;
      _showingFeedback = true;
    });

    _celebrationController.forward();

    // Hide feedback after 2 seconds
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showingFeedback = false;
        });
        _celebrationController.reset();
      }
    });
  }

  void _advanceToNext() {
    setState(() {
      _currentSessionProgress++;
      _currentItemIndex++;
    });

    _progressController.forward().then((_) {
      _progressController.reset();
    });

    // Check if session is complete
    if (_currentSessionProgress >= _sessionTarget) {
      Timer(const Duration(seconds: 1), () {
        setState(() {
          _sessionCompleted = true;
        });
        _celebrationController.forward();
      });
    }
  }

  void _selectMealOption(Map<String, dynamic> option) {
    _playSound(option['phrase'] as String);
    setState(() {
      _showingFeedback = true;
    });
    
    Timer(const Duration(seconds: 2), () {
      setState(() {
        _showingFeedback = false;
      });
      _nextItem();
    });
  }

  void _toggleActivity(int index, Map<String, dynamic> activity) {
    setState(() {
      if (_completedActivities.contains(index)) {
        _completedActivities.remove(index);
      } else {
        _completedActivities.add(index);
      }
    });
    
    _playSound(activity['name'] as String);
  }

  void _playSound(String text) {
    AACHelper.speak(text);
  }

  void _nextItem() {
    if (_currentItemIndex < _practiceItems.length - 1) {
      setState(() {
        _currentItemIndex++;
        _showingFeedback = false;
        _selectedEmotion = null;
      });
    } else {
      _completeSession();
    }
  }

  void _completeSession() {
    setState(() {
      _sessionCompleted = true;
    });
    _celebrationController.forward();
  }

  void _showPracticeDialog(String word) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Practice Time!'),
          content: Text('Try saying "$word" out loud!'),
          actions: [
            CupertinoDialogAction(
              child: const Text('Done'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String _getEmotionEmoji(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'sad':
        return '😢';
      case 'excited':
        return '🤩';
      case 'scared':
        return '😨';
      case 'angry':
        return '😠';
      default:
        return '😊';
    }
  }
}
