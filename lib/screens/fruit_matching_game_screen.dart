import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/aac_helper.dart';

/// Data class for game fruits
class GameFruit {
  final String name;
  final Color color;
  final String emoji;
  final Widget fruit;

  const GameFruit(this.name, this.color, this.emoji, this.fruit);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameFruit && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}

/// Fruit Matching Game Screen with drag and drop functionality
class FruitMatchingGameScreen extends StatefulWidget {
  const FruitMatchingGameScreen({super.key});

  @override
  State<FruitMatchingGameScreen> createState() => _FruitMatchingGameScreenState();
}

class _FruitMatchingGameScreenState extends State<FruitMatchingGameScreen>
    with TickerProviderStateMixin {
  
  // Game configuration
  static const int totalRounds = 10;
  int currentRound = 1;
  int score = 0;
  
  // Current game state
  late GameFruit currentFruit;
  late List<GameFruit> targetFruits;
  int correctTargetIndex = 0;
  
  // Animation controllers
  late AnimationController _successAnimationController;
  late AnimationController _shakeAnimationController;
  late AnimationController _progressAnimationController;
  late AnimationController _celebrationAnimationController;
  late Animation<double> _successAnimation;
  late Animation<double> _shakeAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _celebrationAnimation;
  late Animation<double> _explosionAnimation;
  
  // Game feedback state
  bool isShowingFeedback = false;
  String feedbackMessage = '';
  bool wasCorrect = false;
  bool showCelebration = false;
  
  // Game fruits with names for accessibility - 10 unique fruits with proper visual representations
  final List<GameFruit> gameFruits = [
    GameFruit('Apple', const Color(0xFFFF6B6B), '🍎', _buildAppleFruit()),
    GameFruit('Banana', const Color(0xFFFFE66D), '🍌', _buildBananaFruit()),
    GameFruit('Orange', const Color(0xFFFF8A95), '🍊', _buildOrangeFruit()),
    GameFruit('Grapes', const Color(0xFFB983FF), '🍇', _buildGrapesFruit()),
    GameFruit('Strawberry', const Color(0xFFF38BA8), '🍓', _buildStrawberryFruit()),
    GameFruit('Pineapple', const Color(0xFFFFE66D), '🍍', _buildPineappleFruit()),
    GameFruit('Watermelon', const Color(0xFF20C997), '🍉', _buildWatermelonFruit()),
    GameFruit('Mango', const Color(0xFFFF8A95), '🥭', _buildMangoFruit()),
    GameFruit('Cherry', const Color(0xFFFF6B6B), '🍒', _buildCherryFruit()),
    GameFruit('Lemon', const Color(0xFFFFE66D), '🍋', _buildLemonFruit()),
  ];

  static Widget _buildAppleFruit() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFE53E3E)],
          center: Alignment.topLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x40FF6B6B),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '🍎',
          style: TextStyle(fontSize: 50),
        ),
      ),
    );
  }

  static Widget _buildBananaFruit() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE66D), Color(0xFFECC94B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40FFE66D),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '🍌',
          style: TextStyle(fontSize: 50),
        ),
      ),
    );
  }

  static Widget _buildOrangeFruit() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Color(0xFFFF8A95), Color(0xFFED8936)],
          center: Alignment.topLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x40FF8A95),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '🍊',
          style: TextStyle(fontSize: 50),
        ),
      ),
    );
  }

  static Widget _buildGrapesFruit() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFB983FF), Color(0xFF805AD5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40B983FF),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '🍇',
          style: TextStyle(fontSize: 50),
        ),
      ),
    );
  }

  static Widget _buildStrawberryFruit() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        gradient: const LinearGradient(
          colors: [Color(0xFFF38BA8), Color(0xFFE53E3E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40F38BA8),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '🍓',
          style: TextStyle(fontSize: 50),
        ),
      ),
    );
  }

  static Widget _buildPineappleFruit() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE66D), Color(0xFFD69E2E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40FFE66D),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '🍍',
          style: TextStyle(fontSize: 50),
        ),
      ),
    );
  }

  static Widget _buildWatermelonFruit() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Color(0xFF20C997), Color(0xFF38A169)],
          center: Alignment.topLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x4020C997),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '🍉',
          style: TextStyle(fontSize: 50),
        ),
      ),
    );
  }

  static Widget _buildMangoFruit() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8A95), Color(0xFFED8936)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40FF8A95),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '🥭',
          style: TextStyle(fontSize: 50),
        ),
      ),
    );
  }

  static Widget _buildCherryFruit() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFDC143C)],
          center: Alignment.topLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x40FF6B6B),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '🍒',
          style: TextStyle(fontSize: 50),
        ),
      ),
    );
  }

  static Widget _buildLemonFruit() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE66D), Color(0xFFECC94B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40FFE66D),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '🍋',
          style: TextStyle(fontSize: 50),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startNewRound();
  }

  void _initializeAnimations() {
    _successAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _successAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successAnimationController,
      curve: Curves.elasticOut,
    ));

    _shakeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeAnimationController,
      curve: Curves.easeInOut,
    ));

    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: currentRound / totalRounds,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOut,
    ));

    // Celebration explosion animation controller
    _celebrationAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _celebrationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _celebrationAnimationController,
      curve: Curves.easeOut,
    ));
    _explosionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _celebrationAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _successAnimationController.dispose();
    _shakeAnimationController.dispose();
    _progressAnimationController.dispose();
    _celebrationAnimationController.dispose();
    super.dispose();
  }

  void _startNewRound() {
    setState(() {
      // Select random fruit for this round
      currentFruit = gameFruits[math.Random().nextInt(gameFruits.length)];
      
      // Create target fruits list (one correct, two wrong)
      targetFruits = [];
      correctTargetIndex = math.Random().nextInt(3);
      
      // Add the correct fruit at the correct index
      for (int i = 0; i < 3; i++) {
        if (i == correctTargetIndex) {
          targetFruits.add(currentFruit);
        } else {
          // Add different fruits
          GameFruit differentFruit;
          do {
            differentFruit = gameFruits[math.Random().nextInt(gameFruits.length)];
          } while (differentFruit.name == currentFruit.name || 
                   targetFruits.any((fruit) => fruit.name == differentFruit.name));
          
          targetFruits.add(differentFruit);
        }
      }
      
      isShowingFeedback = false;
      feedbackMessage = '';
      showCelebration = false;
    });
    
    // Update progress animation
    _progressAnimation = Tween<double>(
      begin: _progressAnimation.value,
      end: currentRound / totalRounds,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOut,
    ));
    _progressAnimationController.forward();
    
    // Voice instruction for the new round
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        AACHelper.speakWithEmotion(
          'Find the ${currentFruit.name} fruit and drag it to the matching box!',
          tone: EmotionalTone.friendly,
        );
      }
    });
  }

  void _handleFruitDrop(int targetIndex) {
    if (isShowingFeedback) return;
    
    final isCorrect = targetIndex == correctTargetIndex;
    
    setState(() {
      isShowingFeedback = true;
      wasCorrect = isCorrect;
      
      if (isCorrect) {
        score++;
        final remaining = totalRounds - currentRound;
        feedbackMessage = remaining > 0 ? 'Great! $remaining more to go! ⭐' : 'Perfect! Last one! 🎉';
        
        // Show celebration explosion animation
        showCelebration = true;
        _celebrationAnimationController.forward();
        
        _successAnimationController.forward();
        
        // Play celebration sound effect and haptic feedback
        HapticFeedback.lightImpact();
        AACHelper.playSound(SoundEffect.celebration);
        
        // Voice feedback for correct match
        AACHelper.speakWithEmotion(
          'Excellent! You matched ${currentFruit.name} perfectly! Well done!',
          tone: EmotionalTone.excited,
        );
        
        // Move to next round after celebration animation
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) {
            _successAnimationController.reset();
            _celebrationAnimationController.reset();
            setState(() {
              showCelebration = false;
            });
            if (currentRound < totalRounds) {
              setState(() {
                currentRound++;
              });
              _startNewRound();
            } else {
              _showGameComplete();
            }
          }
        });
      } else {
        feedbackMessage = 'Try again! 🤔';
        _shakeAnimationController.forward().then((_) {
          if (mounted) {
            _shakeAnimationController.reset();
            setState(() {
              isShowingFeedback = false;
            });
          }
        });
        
        // Play error sound and haptic feedback
        HapticFeedback.heavyImpact();
        AACHelper.playSound(SoundEffect.error);
        
        // Voice feedback for incorrect match
        AACHelper.speakWithEmotion(
          'Oops! Try to find the ${currentFruit.name} fruit',
          tone: EmotionalTone.encouraging,
        );
      }
    });
  }

  void _showGameComplete() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('🎊 Game Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(
              'You scored $score out of $totalRounds!',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _getScoreMessage(),
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Play Again'),
            onPressed: () {
              Navigator.pop(context);
              _resetGame();
            },
          ),
          CupertinoDialogAction(
            child: const Text('Back to Practice'),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  String _getScoreMessage() {
    final percentage = (score / totalRounds * 100).round();
    if (percentage >= 90) return 'Outstanding! 🌟';
    if (percentage >= 80) return 'Great job! 🎯';
    if (percentage >= 70) return 'Well done! 👏';
    if (percentage >= 60) return 'Good effort! 👍';
    return 'Keep practicing! 💪';
  }

  void _resetGame() {
    setState(() {
      currentRound = 1;
      score = 0;
    });
    _progressAnimationController.reset();
    _startNewRound();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;

    return Stack(
      children: [
        // Main game content
        Container(
          padding: EdgeInsets.all(isLandscape ? screenWidth * 0.008 : screenWidth * 0.04),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Instructions
                _buildInstructions(screenWidth, screenHeight, isLandscape),
                
                SizedBox(height: isLandscape ? screenHeight * 0.01 : screenHeight * 0.04),
                
                // Draggable fruit
                _buildDraggableFruit(screenWidth, screenHeight, isLandscape),
                
                // Spacing between draggable and target fruits
                SizedBox(height: isLandscape ? screenHeight * 0.042 : screenHeight * 0.048),
                
                // Target fruit boxes
                _buildTargetFruits(screenWidth, screenHeight, isLandscape),
                
                // Feedback area
                if (isShowingFeedback) ...[
                  SizedBox(height: isLandscape ? screenHeight * 0.005 : screenHeight * 0.03),
                  _buildFeedback(screenWidth, screenHeight, isLandscape),
                ],
              ],
            ),
          ),
        ),
        
        // Celebration explosion overlay
        if (showCelebration)
          _buildCelebrationExplosion(screenWidth, screenHeight),
      ],
    );
  }

  Widget _buildInstructions(double screenWidth, double screenHeight, bool isLandscape) {
    return Container(
      padding: EdgeInsets.all(isLandscape ? screenWidth * 0.008 : screenWidth * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFF96CEB4).withOpacity(0.1),
        borderRadius: BorderRadius.circular(isLandscape ? 8 : 12),
        border: Border.all(
          color: const Color(0xFF96CEB4).withOpacity(0.3),
        ),
      ),
      child: Text(
        'Drag the ${currentFruit.name.toLowerCase()} fruit ${currentFruit.emoji} to the matching box below!',
        style: TextStyle(
          fontSize: isLandscape ? screenWidth * 0.018 : screenWidth * 0.04,
          color: const Color(0xFF2D3748),
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDraggableFruit(double screenWidth, double screenHeight, bool isLandscape) {
    final fruitSize = isLandscape ? screenHeight * 0.24 : screenWidth * 0.25;
    
    return AnimatedBuilder(
      animation: _successAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_successAnimation.value * 0.2),
          child: Draggable<GameFruit>(
            data: currentFruit,
            feedback: _buildFruitChip(currentFruit, fruitSize, true),
            childWhenDragging: Opacity(
              opacity: 0.5,
              child: _buildFruitChip(currentFruit, fruitSize, false),
            ),
            child: _buildFruitChip(currentFruit, fruitSize, false),
          ),
        );
      },
    );
  }

  Widget _buildFruitChip(GameFruit fruit, double size, bool isDragging) {
    return Container(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Fruit background
          Positioned.fill(
            child: fruit.fruit,
          ),
          // Fruit name text overlay
          Positioned.fill(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: size * 0.1,
                      vertical: size * 0.03,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(size * 0.05),
                    ),
                    child: Text(
                      fruit.name,
                      style: TextStyle(
                        fontSize: size * 0.1,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: size * 0.05),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetFruits(double screenWidth, double screenHeight, bool isLandscape) {
    final fruitSize = isLandscape ? screenHeight * 0.18 : screenWidth * 0.19;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: targetFruits.asMap().entries.map((entry) {
        final index = entry.key;
        final fruit = entry.value;
        
        return AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            final offset = index == correctTargetIndex && !wasCorrect && isShowingFeedback
                ? math.sin(_shakeAnimation.value * math.pi * 4) * 5
                : 0.0;
            
            return Transform.translate(
              offset: Offset(offset, 0),
              child: DragTarget<GameFruit>(
                onWillAccept: (data) => !isShowingFeedback,
                onAccept: (data) => _handleFruitDrop(index),
                builder: (context, candidateData, rejectedData) {
                  final isHighlighted = candidateData.isNotEmpty;
                  return Container(
                    width: fruitSize,
                    height: fruitSize,
                    alignment: Alignment.center,
                    // No colored box, only the fruit itself with a subtle border/shadow for feedback
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isHighlighted ? Colors.amber : Colors.transparent,
                        width: isHighlighted ? 4 : 0,
                      ),
                      boxShadow: isHighlighted
                          ? [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Container(
                      width: fruitSize * 0.95,
                      height: fruitSize * 0.95,
                      child: fruit.fruit,
                    ),
                  );
                },
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildFeedback(double screenWidth, double screenHeight, bool isLandscape) {
    return AnimatedBuilder(
      animation: wasCorrect ? _successAnimation : _shakeAnimation,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.06,
            vertical: isLandscape ? screenHeight * 0.005 : screenHeight * 0.02,
          ),
          decoration: BoxDecoration(
            color: wasCorrect
                ? const Color(0xFF48BB78).withOpacity(0.1)
                : const Color(0xFFFF6B6B).withOpacity(0.1),
            borderRadius: BorderRadius.circular(isLandscape ? 12 : 16),
            border: Border.all(
              color: wasCorrect
                  ? const Color(0xFF48BB78)
                  : const Color(0xFFFF6B6B),
              width: 2,
            ),
          ),
          child: Text(
            feedbackMessage,
            style: TextStyle(
              fontSize: isLandscape ? screenWidth * 0.025 : screenWidth * 0.05,
              fontWeight: FontWeight.bold,
              color: wasCorrect
                  ? const Color(0xFF48BB78)
                  : const Color(0xFFFF6B6B),
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  Widget _buildCelebrationExplosion(double screenWidth, double screenHeight) {
    return AnimatedBuilder(
      animation: _celebrationAnimation,
      builder: (context, child) {
        final explosionProgress = _explosionAnimation.value;
        final fadeProgress = _celebrationAnimation.value;
        
        return Positioned.fill(
          child: Container(
            child: Stack(
              children: [
                // Multiple explosion effects across the screen
                for (int i = 0; i < 12; i++)
                  Positioned(
                    left: (screenWidth * 0.1) + (i % 4) * (screenWidth * 0.25) + 
                          (math.sin(explosionProgress * math.pi * 2 + i) * 30),
                    top: (screenHeight * 0.2) + (i ~/ 4) * (screenHeight * 0.25) + 
                         (math.cos(explosionProgress * math.pi * 2 + i) * 20),
                    child: Transform.scale(
                      scale: explosionProgress * (1.0 + (i % 3) * 0.3),
                      child: Opacity(
                        opacity: (1.0 - fadeProgress).clamp(0.0, 1.0),
                        child: Text(
                          ['🎉', '⭐', '🎊', '✨', '🎈'][i % 5],
                          style: TextStyle(
                            fontSize: 24 + (explosionProgress * 16),
                          ),
                        ),
                      ),
                    ),
                  ),
                
                // Central celebration burst
                Center(
                  child: Transform.scale(
                    scale: explosionProgress * 2,
                    child: Opacity(
                      opacity: (1.0 - fadeProgress * 1.5).clamp(0.0, 1.0),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.yellow.withOpacity(0.8),
                              Colors.orange.withOpacity(0.6),
                              Colors.red.withOpacity(0.4),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '🎆',
                            style: TextStyle(fontSize: 48),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Sparkle effects
                for (int i = 0; i < 8; i++)
                  Positioned(
                    left: screenWidth * 0.5 + math.cos(i * math.pi / 4) * explosionProgress * 120,
                    top: screenHeight * 0.5 + math.sin(i * math.pi / 4) * explosionProgress * 120,
                    child: Transform.rotate(
                      angle: explosionProgress * math.pi * 4,
                      child: Opacity(
                        opacity: (1.0 - fadeProgress).clamp(0.0, 1.0),
                        child: Text(
                          '✨',
                          style: TextStyle(
                            fontSize: 20 + (explosionProgress * 10),
                          ),
                        ),
                      ),
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
