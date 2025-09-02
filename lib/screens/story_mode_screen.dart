import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../utils/aac_helper.dart';

class StoryModeScreen extends StatefulWidget {
  const StoryModeScreen({super.key});

  @override
  State<StoryModeScreen> createState() => _StoryModeScreenState();
}

class _StoryModeScreenState extends State<StoryModeScreen>
    with TickerProviderStateMixin {
  
  List<Map<String, String>> _storySymbols = [];
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  
  final List<Map<String, String>> _availableSymbols = [
    // Characters
    {'text': 'I', 'emoji': '👤', 'category': 'people'},
    {'text': 'Mom', 'emoji': '👩', 'category': 'people'},
    {'text': 'Dad', 'emoji': '👨', 'category': 'people'},
    {'text': 'friend', 'emoji': '👫', 'category': 'people'},
    {'text': 'dog', 'emoji': '🐕', 'category': 'animals'},
    {'text': 'cat', 'emoji': '🐱', 'category': 'animals'},
    
    // Actions
    {'text': 'go', 'emoji': '🚶‍♂️', 'category': 'actions'},
    {'text': 'play', 'emoji': '🎮', 'category': 'actions'},
    {'text': 'eat', 'emoji': '🍽️', 'category': 'actions'},
    {'text': 'sleep', 'emoji': '😴', 'category': 'actions'},
    {'text': 'run', 'emoji': '🏃‍♂️', 'category': 'actions'},
    {'text': 'jump', 'emoji': '🤸‍♂️', 'category': 'actions'},
    
    // Places
    {'text': 'park', 'emoji': '🏞️', 'category': 'places'},
    {'text': 'home', 'emoji': '🏠', 'category': 'places'},
    {'text': 'school', 'emoji': '🏫', 'category': 'places'},
    {'text': 'store', 'emoji': '🏪', 'category': 'places'},
    
    // Objects
    {'text': 'ball', 'emoji': '⚽', 'category': 'objects'},
    {'text': 'book', 'emoji': '📚', 'category': 'objects'},
    {'text': 'toy', 'emoji': '🧸', 'category': 'objects'},
    {'text': 'food', 'emoji': '🍎', 'category': 'objects'},
    
    // Time/Sequence
    {'text': 'first', 'emoji': '1️⃣', 'category': 'sequence'},
    {'text': 'then', 'emoji': '2️⃣', 'category': 'sequence'},
    {'text': 'last', 'emoji': '3️⃣', 'category': 'sequence'},
    {'text': 'today', 'emoji': '📅', 'category': 'time'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _addSymbolToStory(Map<String, String> symbol) {
    setState(() {
      _storySymbols.add(symbol);
    });
    
    // Speak the word when added
    AACHelper.speak(symbol['text']!);
    
    // Visual feedback
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }

  void _removeSymbolFromStory(int index) {
    setState(() {
      _storySymbols.removeAt(index);
    });
  }

  void _playStory() {
    if (_storySymbols.isNotEmpty) {
      final storyText = _storySymbols.map((symbol) => symbol['text']).join(' ');
      AACHelper.speak(storyText);
      
      _showStoryAnimation();
    }
  }

  void _clearStory() {
    setState(() {
      _storySymbols.clear();
    });
  }

  void _showStoryAnimation() {
    showDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('🎭 Playing Your Story!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Icon(CupertinoIcons.speaker_2_fill, size: 30, color: Colors.blue),
                const Icon(CupertinoIcons.heart_fill, size: 30, color: Colors.red),
                const Icon(CupertinoIcons.star_fill, size: 30, color: Colors.orange),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _storySymbols.map((s) => '${s['emoji']} ${s['text']}').join(' '),
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Great Job!'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.purple,
        middle: const Text(
          '📚 Story Mode',
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
      ),
      child: Column(
        children: [
          // Story Builder Area
          _buildStoryBuilder(),
          
          // Symbol Categories
          Expanded(
            child: _buildSymbolCategories(),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryBuilder() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -1),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    '📖 My Story',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  if (_storySymbols.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_storySymbols.length} words',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Story Display
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 100),
              padding: const EdgeInsets.all(16),
              child: _storySymbols.isEmpty
                  ? Center(
                      child: Column(
                        children: [
                          Icon(
                            CupertinoIcons.book,
                            size: 40,
                            color: Colors.grey.withOpacity(0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap symbols below to create your story!',
                            style: TextStyle(
                              color: Colors.grey.withOpacity(0.7),
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _storySymbols.asMap().entries.map((entry) {
                        final index = entry.key;
                        final symbol = entry.value;
                        
                        return GestureDetector(
                          onTap: () => _removeSymbolFromStory(index),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.purple.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  symbol['emoji']!,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  symbol['text']!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.purple,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  CupertinoIcons.xmark_circle_fill,
                                  size: 16,
                                  color: Colors.purple.withOpacity(0.6),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
            
            // Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      color: _storySymbols.isEmpty 
                          ? Colors.grey.withOpacity(0.5)
                          : Colors.purple,
                      onPressed: _storySymbols.isEmpty ? null : _playStory,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.play_circle_fill, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'PLAY STORY',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CupertinoButton(
                    color: Colors.red.withOpacity(0.8),
                    onPressed: _storySymbols.isEmpty ? null : _clearStory,
                    child: const Icon(CupertinoIcons.clear_circled_solid, size: 24),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymbolCategories() {
    final categories = ['people', 'actions', 'places', 'objects', 'sequence'];
    final categoryColors = {
      'people': Colors.blue,
      'actions': Colors.green,
      'places': Colors.orange,
      'objects': Colors.red,
      'sequence': Colors.purple,
    };
    
    return DefaultTabController(
      length: categories.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            labelColor: Colors.purple,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.purple,
            tabs: categories.map((category) {
              return Tab(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: categoryColors[category]!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          Expanded(
            child: TabBarView(
              children: categories.map((category) {
                final categorySymbols = _availableSymbols
                    .where((symbol) => symbol['category'] == category)
                    .toList();
                
                return LayoutBuilder(
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
                    final basePadding = isLandscape ? screenWidth * 0.03 : screenWidth * 0.04;
                    final spacing = isLandscape ? screenWidth * 0.02 : screenWidth * 0.04;

                    return GridView.builder(
                      padding: EdgeInsets.all(basePadding),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        // Adjust aspect ratio for consistent sizing
                        childAspectRatio: isLandscape ? 1.2 : 1.1,
                      ),
                      itemCount: categorySymbols.length,
                      itemBuilder: (context, index) {
                        final symbol = categorySymbols[index];
                        return _buildSymbolCard(symbol, categoryColors[category]!);
                      },
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymbolCard(Map<String, String> symbol, Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        final cardWidth = constraints.maxWidth;
        final cardHeight = constraints.maxHeight;
        
        // Calculate responsive sizes
        final emojiSize = isLandscape ? cardWidth * 0.35 : cardWidth * 0.4;
        final fontSize = isLandscape ? cardWidth * 0.08 : cardWidth * 0.09;
        
        return CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _addSymbolToStory(symbol),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Large symbol/emoji - responsive size
                Text(
                  symbol['emoji']!,
                  style: TextStyle(fontSize: emojiSize.clamp(24, 48)),
                ),
                SizedBox(height: cardHeight * 0.08),
                
                // Text label - responsive size
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: cardWidth * 0.1),
                  child: Text(
                    symbol['text']!,
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
        );
      },
    );
  }
}
