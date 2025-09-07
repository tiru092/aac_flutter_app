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

  void _handleCorrectMatch() {
    if (isShowingFeedback) return;
    
    setState(() {
      isShowingFeedback = true;
      wasCorrect = true;
      score += 10;
      feedbackMessage = 'Perfect! You found the ${currentCar.name}!';
    });
    
    // Play success animation and sound
    _successAnimationController.forward();
    HapticFeedback.mediumImpact();
    
    // Voice feedback
    AACHelper.speakWithEmotion(
      feedbackMessage,
      tone: EmotionalTone.excited,
    );
    
    // Move to next round after delay
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        _successAnimationController.reset();
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
  }

  void _handleIncorrectMatch() {
    if (isShowingFeedback) return;
    
    setState(() {
      isShowingFeedback = true;
      wasCorrect = false;
      feedbackMessage = 'Try again! Look for the ${currentCar.name}.';
    });
    
    // Play shake animation and error feedback
    _shakeAnimationController.forward().then((_) {
      _shakeAnimationController.reverse();
    });
    HapticFeedback.lightImpact();
    
    // Voice feedback
    AACHelper.speakWithEmotion(
      feedbackMessage,
      tone: EmotionalTone.encouraging,
    );
    
    // Reset feedback after delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          isShowingFeedback = false;
        });
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
    final percentage = (score / (totalRounds * 10) * 100).round();
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
      'Game complete! You scored $score out of ${totalRounds * 10} points. $performanceMessage',
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

  Widget _buildCarChip(GameCar car, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.2),
        color: Colors.transparent,
      ),
      child: Center(
        child: Text(
          car.emoji,
          style: TextStyle(
            fontSize: size * 0.6,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildTargetCars(double screenWidth, double screenHeight, bool isLandscape) {
    final targetSize = isLandscape ? screenHeight * 0.18 : screenWidth * 0.2;
    
    return Wrap(
      spacing: isLandscape ? screenWidth * 0.02 : screenWidth * 0.03,
      runSpacing: isLandscape ? screenHeight * 0.02 : screenHeight * 0.02,
      alignment: WrapAlignment.center,
      children: gameCars.map((car) {
        return DragTarget<GameCar>(
          builder: (context, candidateData, rejectedData) {
            final isHovering = candidateData.isNotEmpty;
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: targetSize,
              height: targetSize,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isHovering 
                      ? const Color(0xFFFF6B6B)
                      : const Color(0xFFE2E8F0),
                  width: isHovering ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Transform.scale(
                scale: isHovering ? 1.05 : 1.0,
                child: Center(
                  child: _buildCarChip(car, targetSize * 0.6),
                ),
              ),
            );
          },
          onWillAcceptWithDetails: (details) => details.data == currentCar,
          onAcceptWithDetails: (details) => _onCarMatched(details.data == currentCar),
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
                
                // Draggable car (if not in celebration mode)
                if (!showCelebration)
                  _buildDraggableCar(screenWidth, screenHeight, isLandscape),
                
                // Increased spacing between draggable and target cars
                if (!showCelebration)
                  SizedBox(height: isLandscape ? screenHeight * 0.042 : screenHeight * 0.048),
                
                // Target car boxes (if not in celebration mode)
                if (!showCelebration)
                  _buildTargetCars(screenWidth, screenHeight, isLandscape),
                
                // Celebration content
                if (showCelebration)
                  _buildCelebration(screenWidth, screenHeight, isLandscape),
                
                // Feedback message
                if (isShowingFeedback && !showCelebration)
                  _buildFeedback(screenWidth, screenHeight, isLandscape),
              ],
            ),
          ),
        ),
        
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
          if (!showCelebration) ...[
            SizedBox(height: screenHeight * 0.02),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(screenWidth * 0.03),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF6B6B).withOpacity(0.3),
                ),
              ),
              child: Text(
                'Drag the ${currentCar.name} to the matching box below!',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF2D3748),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDraggableCar(double screenWidth, double screenHeight, bool isLandscape) {
    final dragSize = isLandscape ? screenHeight * 0.24 : screenWidth * 0.25;
    
    return Center(
      child: AnimatedBuilder(
        animation: _successAnimation,
        builder: (context, child) {
          final scale = 1.0 + (_successAnimation.value * 0.2);
          
          return Transform.scale(
            scale: scale,
            child: Draggable<GameCar>(
              data: currentCar,
              feedback: Material(
                color: Colors.transparent,
                child: _buildCarChip(currentCar, dragSize),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: _buildCarChip(currentCar, dragSize),
              ),
              child: _buildCarChip(currentCar, dragSize),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCelebration(double screenWidth, double screenHeight, bool isLandscape) {
    return AnimatedBuilder(
      animation: _celebrationAnimation,
      builder: (context, child) {
        return Container(
          height: screenHeight * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: 1.0 + (_explosionAnimation.value * 0.5),
                  child: Container(
                    padding: EdgeInsets.all(screenWidth * 0.08),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B).withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFF6B6B),
                        width: 3,
                      ),
                    ),
                    child: Text(
                      '🎉',
                      style: TextStyle(
                        fontSize: screenWidth * 0.15,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.04),
                Text(
                  'Congratulations!',
                  style: TextStyle(
                    fontSize: screenWidth * 0.07,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFF6B6B),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                Text(
                  'You completed all $totalRounds rounds!',
                  style: TextStyle(
                    fontSize: screenWidth * 0.05,
                    color: const Color(0xFF4A5568),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.02),
                Text(
                  'Final Score: $score/${totalRounds * 10}',
                  style: TextStyle(
                    fontSize: screenWidth * 0.06,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                SizedBox(height: screenHeight * 0.04),
                ElevatedButton(
                  onPressed: _resetGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.1,
                      vertical: screenHeight * 0.02,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Play Again',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.w600,
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

  Widget _buildFeedback(double screenWidth, double screenHeight, bool isLandscape) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.04),
      margin: EdgeInsets.only(top: screenHeight * 0.02),
      decoration: BoxDecoration(
        color: wasCorrect 
            ? const Color(0xFF48BB78).withOpacity(0.1)
            : const Color(0xFFF56565).withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: wasCorrect 
              ? const Color(0xFF48BB78).withOpacity(0.3)
              : const Color(0xFFF56565).withOpacity(0.3),
        ),
      ),
      child: Text(
        feedbackMessage,
        style: TextStyle(
          fontSize: screenWidth * 0.04,
          fontWeight: FontWeight.w500,
          color: wasCorrect 
              ? const Color(0xFF22543D)
              : const Color(0xFF742A2A),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _onCarMatched(bool isCorrect) {
    setState(() {
      isShowingFeedback = true;
      wasCorrect = isCorrect;
      
      if (isCorrect) {
        feedbackMessage = 'Perfect! Great job matching the ${currentCar.name}!';
        score += 10;
        HapticFeedback.lightImpact();
        _successAnimationController.forward().then((_) => _successAnimationController.reverse());
        _progressAnimationController.animateTo(currentRound / totalRounds);
        
        // Play voice feedback
        AACHelper.speakWithEmotion(
          feedbackMessage,
          tone: EmotionalTone.excited,
        );
      } else {
        feedbackMessage = 'Try again! Look for the ${currentCar.name}.';
        HapticFeedback.mediumImpact();
        
        // Play voice feedback
        AACHelper.speakWithEmotion(
          feedbackMessage,
          tone: EmotionalTone.encouraging,
        );
      }
    });

    // Auto-advance after correct match
    if (isCorrect) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            isShowingFeedback = false;
          });
          
          if (currentRound < totalRounds) {
            _startNewRound();
          } else {
            _showGameComplete();
          }
        }
      });
    } else {
      // Hide feedback after incorrect match
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            isShowingFeedback = false;
          });
        }
      });
    }
  }
}
