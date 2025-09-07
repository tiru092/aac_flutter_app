import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/aac_helper.dart';

/// Data class for game cars
class GameCar {
  final String name;
  final Color color;
  final String emoji;
  final Widget car;

  const GameCar(this.name, this.color, this.emoji, this.car);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameCar && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}

/// Car Matching Game Screen with drag and drop functionality
class CarMatchingGameScreen extends StatefulWidget {
  const CarMatchingGameScreen({super.key});

  @override
  State<CarMatchingGameScreen> createState() => _CarMatchingGameScreenState();
}

class _CarMatchingGameScreenState extends State<CarMatchingGameScreen>
    with TickerProviderStateMixin {
  
  // Game configuration
  static const int totalRounds = 10;
  int currentRound = 1;
  int score = 0;
  
  // Current game state
  late GameCar currentCar;
  late List<GameCar> targetCars;
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
  
  // Game cars with names for accessibility - 10 unique cars as pure emojis
  final List<GameCar> gameCars = [
    GameCar('Police Car', const Color(0xFF4A90E2), '🚓', Container()),
    GameCar('Fire Engine', const Color(0xFFFF6B6B), '🚒', Container()),
    GameCar('Ambulance', const Color(0xFF20C997), '🚑', Container()),
    GameCar('Taxi', const Color(0xFFFFE66D), '🚕', Container()),
    GameCar('Bus', const Color(0xFFFF8A95), '🚌', Container()),
    GameCar('Racing Car', const Color(0xFFB983FF), '🏎️', Container()),
    GameCar('Truck', const Color(0xFF6C757D), '🚚', Container()),
    GameCar('SUV', const Color(0xFF8B4513), '🚙', Container()),
    GameCar('Convertible', const Color(0xFFFF69B4), '🚗', Container()),
    GameCar('Van', const Color(0xFF32CD32), '🚐', Container()),
  ];

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
      // Select random car for this round
      currentCar = gameCars[math.Random().nextInt(gameCars.length)];
      
      // Create target cars list (one correct, two wrong)
      targetCars = [];
      correctTargetIndex = math.Random().nextInt(3);
      
      // Add the correct car at the correct index
      for (int i = 0; i < 3; i++) {
        if (i == correctTargetIndex) {
          targetCars.add(currentCar);
        } else {
          // Add different cars
          GameCar differentCar;
          do {
            differentCar = gameCars[math.Random().nextInt(gameCars.length)];
          } while (differentCar.name == currentCar.name || 
                   targetCars.any((car) => car.name == differentCar.name));
          
          targetCars.add(differentCar);
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
          'Find the ${currentCar.name} and drag it to the matching box!',
          tone: EmotionalTone.friendly,
        );
      }
    });
  }

  void _handleCarDrop(int targetIndex) {
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
        
        // Voice feedback for correct match
        AACHelper.speakWithEmotion(
          'Excellent! You matched ${currentCar.name} perfectly! Well done!',
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
        
        // Voice feedback for incorrect match
        AACHelper.speakWithEmotion(
          'Oops! Try to find the ${currentCar.name}',
          tone: EmotionalTone.encouraging,
        );
      }
    });
  }

  void _showGameComplete() {
    setState(() {
      showCelebration = true;
    });
    
    _celebrationAnimationController.forward();
    HapticFeedback.heavyImpact();
    
    // Calculate performance message
    final percentage = (score / totalRounds * 100).round();
    String performanceMessage;
    EmotionalTone tone;
    
    if (percentage >= 90) {
      performanceMessage = 'Outstanding! You\'re a car matching expert!';
      tone = EmotionalTone.excited;
    } else if (percentage >= 70) {
      performanceMessage = 'Great job! You did really well with the cars!';
      tone = EmotionalTone.excited;
    } else if (percentage >= 50) {
      performanceMessage = 'Good effort! Keep practicing with the cars!';
      tone = EmotionalTone.encouraging;
    } else {
      performanceMessage = 'Nice try! Let\'s practice more with cars!';
      tone = EmotionalTone.encouraging;
    }
    
    AACHelper.speakWithEmotion(
      'Game complete! You scored $score out of $totalRounds. $performanceMessage',
      tone: tone,
    );
  }

  void _resetGame() {
    setState(() {
      currentRound = 1;
      score = 0;
      showCelebration = false;
      isShowingFeedback = false;
    });
    
    _celebrationAnimationController.reset();
    _progressAnimationController.reset();
    _startNewRound();
  }

  Widget _buildCarChip(GameCar car, double size, bool isDragging) {
    return Container(
      width: size,
      height: size,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              car.emoji,
              style: TextStyle(fontSize: size * 0.6),
            ),
            SizedBox(height: size * 0.05),
            Text(
              car.name,
              style: TextStyle(
                fontSize: size * 0.12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetCars(double screenWidth, double screenHeight, bool isLandscape) {
    // Use the same size as fruit matching game
    final carSize = isLandscape ? screenHeight * 0.22 : screenWidth * 0.22;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: targetCars.asMap().entries.map((entry) {
        final index = entry.key;
        final car = entry.value;
        
        return AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            final offset = index == correctTargetIndex && !wasCorrect && isShowingFeedback
                ? math.sin(_shakeAnimation.value * math.pi * 4) * 5
                : 0.0;
            
            return Transform.translate(
              offset: Offset(offset, 0),
              child: DragTarget<GameCar>(
                onWillAccept: (data) => !isShowingFeedback,
                onAccept: (data) => _handleCarDrop(index),
                builder: (context, candidateData, rejectedData) {
                  final isHighlighted = candidateData.isNotEmpty;
                  return Container(
                    width: carSize,
                    height: carSize,
                    alignment: Alignment.center,
                    // Pure emoji without any background container
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(carSize / 2),
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
                    child: Center(
                      child: Text(
                        car.emoji,
                        style: TextStyle(fontSize: carSize * 0.6),
                      ),
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
                
                // Draggable car
                _buildDraggableCar(screenWidth, screenHeight, isLandscape),
                
                // Spacing between draggable and target cars
                SizedBox(height: isLandscape ? screenHeight * 0.042 : screenHeight * 0.048),
                
                // Target car boxes
                _buildTargetCars(screenWidth, screenHeight, isLandscape),
                
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
        
        // Back button
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          child: SafeArea(
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  CupertinoIcons.back,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions(double screenWidth, double screenHeight, bool isLandscape) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.02,
      ),
      margin: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 60, // Space for back button
        bottom: screenHeight * 0.02,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Round $currentRound/$totalRounds',
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
              ),
              Text(
                'Score: $score',
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFF6B6B),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.015),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: _progressAnimation.value,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFFF6B6B),
                ),
                minHeight: 8,
              );
            },
          ),
          SizedBox(height: screenHeight * 0.02),
          Container(
            padding: EdgeInsets.all(isLandscape ? screenWidth * 0.008 : screenWidth * 0.04),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(isLandscape ? 8 : 12),
              border: Border.all(
                color: const Color(0xFFFF6B6B).withOpacity(0.3),
              ),
            ),
            child: Text(
              'Drag the ${currentCar.name.toLowerCase()} ${currentCar.emoji} to the matching box below!',
              style: TextStyle(
                fontSize: isLandscape ? screenWidth * 0.018 : screenWidth * 0.04,
                color: const Color(0xFF2D3748),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableCar(double screenWidth, double screenHeight, bool isLandscape) {
    // Use the same size as fruit matching game
    final carSize = isLandscape ? screenHeight * 0.24 : screenWidth * 0.25;
    
    return AnimatedBuilder(
      animation: _successAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_successAnimation.value * 0.2),
          child: Draggable<GameCar>(
            data: currentCar,
            feedback: _buildCarChip(currentCar, carSize, true),
            childWhenDragging: Opacity(
              opacity: 0.5,
              child: _buildCarChip(currentCar, carSize, false),
            ),
            child: _buildCarChip(currentCar, carSize, false),
          ),
        );
      },
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

  String _getScoreMessage() {
    final percentage = (score / totalRounds * 100).round();
    if (percentage >= 90) return 'Outstanding! 🌟';
    if (percentage >= 80) return 'Great job! 🎯';
    if (percentage >= 70) return 'Well done! 👏';
    if (percentage >= 60) return 'Good effort! 👍';
    return 'Keep practicing! 💪';
  }
}
