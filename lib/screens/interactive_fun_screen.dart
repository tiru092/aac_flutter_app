import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../utils/aac_helper.dart';

class InteractiveFunScreen extends StatefulWidget {
  const InteractiveFunScreen({super.key});

  @override
  State<InteractiveFunScreen> createState() => _InteractiveFunScreenState();
}

class _InteractiveFunScreenState extends State<InteractiveFunScreen>
    with TickerProviderStateMixin {
  
  // Animation controllers for pop effects
  late AnimationController _popAnimationController;
  late Animation<double> _popAnimation;
  late AnimationController _burstController;
  late Animation<double> _burstAnimation;
  
  // Routine sequencer state
  List<Map<String, String>> _routineItems = [
    {'name': 'Wake up', 'emoji': '⏰', 'id': 'wake'},
    {'name': 'Brush teeth', 'emoji': '🦷', 'id': 'brush'},
    {'name': 'Breakfast', 'emoji': '🍳', 'id': 'breakfast'},
    {'name': 'Get dressed', 'emoji': '👕', 'id': 'dress'},
    {'name': 'School', 'emoji': '🏫', 'id': 'school'},
    {'name': 'Lunch', 'emoji': '🍽️', 'id': 'lunch'},
    {'name': 'Play time', 'emoji': '🎮', 'id': 'play'},
    {'name': 'Dinner', 'emoji': '🍝', 'id': 'dinner'},
    {'name': 'Bath time', 'emoji': '🛁', 'id': 'bath'},
    {'name': 'Bedtime', 'emoji': '🛏️', 'id': 'bed'},
  ];
  
  List<Map<String, String>> _droppedRoutine = [];
  bool _isPlayingRoutine = false;
  
  // Shape/Color sorter state
  Map<String, Map<String, String>> _shapeSorterItems = {
    'blue_circle': {'shape': '🔵', 'target': '🥤', 'name': 'blue cup'},
    'green_square': {'shape': '🟩', 'target': '🍽️', 'name': 'green plate'},
    'red_triangle': {'shape': '🔺', 'target': '🍎', 'name': 'red apple'},
    'yellow_star': {'shape': '⭐', 'target': '🧀', 'name': 'yellow cheese'},
  };
  
  Map<String, bool> _shapesMatched = {};
  
  // Gamification state
  int _completedTasks = 0;
  List<String> _earnedBadges = [];
  double _weekProgress = 0.0;
  
  // Social narratives
  List<Map<String, dynamic>> _socialStories = [
    {
      'title': 'Morning Routine',
      'emoji': '🌅',
      'pages': [
        {'text': 'When I wake up in the morning, I stretch and yawn.', 'image': '😴'},
        {'text': 'I get out of bed and say "Good morning!"', 'image': '🛏️'},
        {'text': 'I brush my teeth to keep them clean and healthy.', 'image': '🦷'},
        {'text': 'I eat breakfast to give me energy for the day.', 'image': '🍳'},
      ]
    },
    {
      'title': 'Making Friends',
      'emoji': '👋',
      'pages': [
        {'text': 'When I meet someone new, I can say "Hi!" and smile.', 'image': '😊'},
        {'text': 'I can ask "What\'s your name?" to learn about them.', 'image': '❓'},
        {'text': 'I can share my toys and play together.', 'image': '🧸'},
        {'text': 'Being kind makes everyone happy.', 'image': '💝'},
      ]
    },
    {
      'title': 'Going to the Store',
      'emoji': '🏪',
      'pages': [
        {'text': 'Before we go to the store, we make a list.', 'image': '📝'},
        {'text': 'At the store, I stay close to my grown-up.', 'image': '👨‍👩‍👧'},
        {'text': 'We find the items on our list one by one.', 'image': '🛒'},
        {'text': 'We pay at the checkout and say "Thank you!"', 'image': '💳'},
      ]
    },
  ];
  
  int _currentStoryIndex = 0;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _popAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _popAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _popAnimationController, curve: Curves.elasticOut)
    );
    
    _burstController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _burstAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _burstController, curve: Curves.easeOut)
    );
    
    // Initialize shape sorter state
    for (String key in _shapeSorterItems.keys) {
      _shapesMatched[key] = false;
    }
    
    // Initialize progress
    _weekProgress = _completedTasks / 10.0;
  }

  @override
  void dispose() {
    _popAnimationController.dispose();
    _burstController.dispose();
    super.dispose();
  }

  void _triggerPopAnimation(String text) async {
    await _popAnimationController.forward();
    AACHelper.speak(text);
    await _popAnimationController.reverse();
    
    _burstController.forward().then((_) {
      _burstController.reset();
    });
  }

  void _addToRoutine(Map<String, String> item) {
    if (_droppedRoutine.length < 6) { // Limit to 6 items for ASD-friendly complexity
      setState(() {
        _droppedRoutine.add(item);
      });
      _triggerPopAnimation('Added ${item['name']} to routine!');
    }
  }

  void _clearRoutine() {
    setState(() {
      _droppedRoutine.clear();
    });
    AACHelper.speak('Routine cleared!');
  }

  void _playRoutine() async {
    if (_droppedRoutine.isEmpty) return;
    
    setState(() {
      _isPlayingRoutine = true;
    });
    
    for (int i = 0; i < _droppedRoutine.length; i++) {
      final item = _droppedRoutine[i];
      AACHelper.speak('Step ${i + 1}: ${item['name']}');
      await Future.delayed(const Duration(seconds: 2));
    }
    
    setState(() {
      _isPlayingRoutine = false;
      _completedTasks++;
      _weekProgress = _completedTasks / 10.0;
    });
    
    _checkForBadges();
    AACHelper.speak('Great job completing your routine!');
  }

  void _checkForBadges() {
    if (_completedTasks >= 3 && !_earnedBadges.contains('Routine Master')) {
      setState(() {
        _earnedBadges.add('Routine Master');
      });
      _showBadgeEarned('Routine Master', '📅');
    }
    
    if (_shapesMatched.values.where((matched) => matched).length >= 2 && 
        !_earnedBadges.contains('Color Matcher')) {
      setState(() {
        _earnedBadges.add('Color Matcher');
      });
      _showBadgeEarned('Color Matcher', '🎨');
    }
  }

  void _showBadgeEarned(String badge, String emoji) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('🎉 Badge Earned!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(badge, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Awesome!'),
            onPressed: () {
              Navigator.pop(context);
              AACHelper.speak('You earned the $badge badge! Great job!');
            },
          ),
        ],
      ),
    );
  }

  void _matchShape(String shapeKey, String targetKey) {
    if (shapeKey == targetKey) {
      setState(() {
        _shapesMatched[shapeKey] = true;
      });
      _triggerPopAnimation('Great match! ${_shapeSorterItems[shapeKey]!['name']}');
      _checkForBadges();
    } else {
      AACHelper.speak('Try again! Look for the matching item.');
    }
  }

  Widget _buildPopButton({
    required String text,
    required String emoji,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ScaleTransition(
      scale: _popAnimation,
      child: GestureDetector(
        onTap: () {
          _triggerPopAnimation(text);
          onTap();
        },
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: color ?? Colors.blue.shade100,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 4),
              Text(
                text,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Colors.deepPurple,
        middle: Text(
          'Interactive Fun',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress and Badges Section
                _buildProgressSection(),
                const SizedBox(height: 24),
                
                // Pop & Burst Interactions
                _buildPopSection(),
                const SizedBox(height: 24),
                
                // Routine Sequencer
                _buildRoutineSection(),
                const SizedBox(height: 24),
                
                // Shape/Color Sorter
                _buildShapeSorterSection(),
                const SizedBox(height: 24),
                
                // Social Narratives
                _buildSocialNarrativeSection(),
                const SizedBox(height: 24),
                
                // Educational Videos placeholder
                _buildEducationalVideoSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade100, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.orange, size: 28),
              const SizedBox(width: 8),
              const Text(
                'Your Progress',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tasks completed this week: $_completedTasks/10'),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _weekProgress,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade400),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Badges
          if (_earnedBadges.isNotEmpty) ...[
            const Text('Your Badges:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _earnedBadges.map((badge) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge == 'Routine Master' ? '📅 $badge' : '🎨 $badge',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPopSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎉', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 8),
              const Text(
                'Pop & Play',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Tap the symbols to see them pop and hear their sounds!'),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildPopButton(
                text: 'Happy',
                emoji: '😊',
                onTap: () {},
                color: Colors.yellow.shade100,
              ),
              _buildPopButton(
                text: 'Cookie',
                emoji: '🍪',
                onTap: () {},
                color: Colors.brown.shade100,
              ),
              _buildPopButton(
                text: 'Music',
                emoji: '🎵',
                onTap: () {},
                color: Colors.purple.shade100,
              ),
              _buildPopButton(
                text: 'Heart',
                emoji: '❤️',
                onTap: () {},
                color: Colors.red.shade100,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📅', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 8),
              const Text(
                'Daily Routine Builder',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Drag activities into your daily routine!'),
          const SizedBox(height: 16),
          
          // Available routine items
          const Text('Available Activities:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _routineItems.length,
              itemBuilder: (context, index) {
                final item = _routineItems[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Draggable<Map<String, String>>(
                    data: item,
                    feedback: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(item['emoji']!, style: const TextStyle(fontSize: 24)),
                            Text(
                              item['name']!,
                              style: const TextStyle(fontSize: 8),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade300),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(item['emoji']!, style: const TextStyle(fontSize: 20)),
                          Text(
                            item['name']!,
                            style: const TextStyle(fontSize: 8),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          
          // Drop zone
          const Text('My Daily Routine:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DragTarget<Map<String, String>>(
            onAccept: _addToRoutine,
            builder: (context, candidateData, rejectedData) {
              return Container(
                width: double.infinity,
                height: 100,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: candidateData.isNotEmpty 
                      ? Colors.green.shade100 
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: candidateData.isNotEmpty 
                        ? Colors.green.shade400 
                        : Colors.grey.shade400,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _droppedRoutine.isEmpty
                    ? const Center(
                        child: Text(
                          'Drop routine items here!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _droppedRoutine.map((item) => Chip(
                          avatar: Text(item['emoji']!),
                          label: Text(item['name']!),
                          backgroundColor: Colors.blue.shade100,
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            setState(() {
                              _droppedRoutine.remove(item);
                            });
                          },
                        )).toList(),
                      ),
              );
            },
          ),
          const SizedBox(height: 16),
          
          // Control buttons
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  color: Colors.green,
                  onPressed: _droppedRoutine.isEmpty || _isPlayingRoutine ? null : _playRoutine,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isPlayingRoutine ? CupertinoIcons.hourglass : CupertinoIcons.play,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(_isPlayingRoutine ? 'Playing...' : 'Play Routine'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              CupertinoButton(
                color: Colors.red,
                onPressed: _droppedRoutine.isEmpty ? null : _clearRoutine,
                child: const Icon(CupertinoIcons.clear, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShapeSorterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔴', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 8),
              const Text(
                'Shape & Color Matcher',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Drag each shape to its matching item!'),
          const SizedBox(height: 16),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _shapeSorterItems.length,
            itemBuilder: (context, index) {
              final key = _shapeSorterItems.keys.elementAt(index);
              final item = _shapeSorterItems[key]!;
              final isMatched = _shapesMatched[key]!;
              
              return Row(
                children: [
                  // Draggable shape
                  Expanded(
                    child: isMatched 
                        ? Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.green.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text('✓', style: TextStyle(fontSize: 32, color: Colors.green.shade800)),
                            ),
                          )
                        : Draggable<String>(
                            data: key,
                            feedback: Material(
                              color: Colors.transparent,
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(item['shape']!, style: const TextStyle(fontSize: 32)),
                                ),
                              ),
                            ),
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.shade300),
                              ),
                              child: Center(
                                child: Text(item['shape']!, style: const TextStyle(fontSize: 32)),
                              ),
                            ),
                          ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Drop target
                  Expanded(
                    child: DragTarget<String>(
                      onAccept: (draggedKey) => _matchShape(draggedKey, key),
                      builder: (context, candidateData, rejectedData) {
                        return Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: candidateData.isNotEmpty 
                                ? Colors.yellow.shade100 
                                : (isMatched ? Colors.green.shade200 : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: candidateData.isNotEmpty 
                                  ? Colors.yellow.shade400 
                                  : (isMatched ? Colors.green.shade400 : Colors.grey.shade400),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(item['target']!, style: const TextStyle(fontSize: 32)),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSocialNarrativeSection() {
    final currentStory = _socialStories[_currentStoryIndex];
    final currentPage = currentStory['pages'][_currentPageIndex];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.pink.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.pink.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(currentStory['emoji'], style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 8),
              Text(
                'Social Story: ${currentStory['title']}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Story content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.pink.shade200),
            ),
            child: Column(
              children: [
                Text(
                  currentPage['image'],
                  style: const TextStyle(fontSize: 64),
                ),
                const SizedBox(height: 16),
                Text(
                  currentPage['text'],
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Navigation buttons
          Row(
            children: [
              // Previous page
              CupertinoButton(
                color: Colors.grey,
                onPressed: _currentPageIndex > 0 
                    ? () {
                        setState(() {
                          _currentPageIndex--;
                        });
                      }
                    : null,
                child: const Icon(CupertinoIcons.back, color: Colors.white),
              ),
              
              const SizedBox(width: 12),
              
              // Read page button
              Expanded(
                child: CupertinoButton(
                  color: Colors.pink,
                  onPressed: () {
                    AACHelper.speak(currentPage['text']);
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.speaker_2, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Read Page'),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Next page or story
              CupertinoButton(
                color: Colors.pink,
                onPressed: () {
                  if (_currentPageIndex < currentStory['pages'].length - 1) {
                    setState(() {
                      _currentPageIndex++;
                    });
                  } else {
                    // Move to next story or loop back
                    setState(() {
                      _currentStoryIndex = (_currentStoryIndex + 1) % _socialStories.length;
                      _currentPageIndex = 0;
                    });
                  }
                },
                child: Icon(
                  _currentPageIndex < currentStory['pages'].length - 1
                      ? CupertinoIcons.forward
                      : CupertinoIcons.refresh,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          
          // Progress indicator
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              currentStory['pages'].length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _currentPageIndex 
                      ? Colors.pink.shade400 
                      : Colors.grey.shade300,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationalVideoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📺', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 8),
              const Text(
                'Educational Videos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Coming soon: Interactive videos about emotions, routines, and social skills!'),
          const SizedBox(height: 16),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildVideoThumbnail('Emotions', '😊', 'Learn about feelings'),
              _buildVideoThumbnail('Daily Routine', '⏰', 'Morning activities'),
              _buildVideoThumbnail('Friendship', '👫', 'Making friends'),
              _buildVideoThumbnail('Safety', '🚦', 'Staying safe'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoThumbnail(String title, String emoji, String description) {
    return GestureDetector(
      onTap: () {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text('$emoji $title'),
            content: Text('$description\n\nVideo feature coming soon!'),
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purple.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Text(
              description,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
