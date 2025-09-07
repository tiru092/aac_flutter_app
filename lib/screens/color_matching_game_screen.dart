import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Color Matching Game Screen with drag and drop functionality
class ColorMatchingGameScreen extends StatefulWidget {
  const ColorMatchingGameScreen({super.key});

  @override
  State<ColorMatchingGameScreen> createState() => _ColorMatchingGameScreenState();
}

class _ColorMatchingGameScreenState extends State<ColorMatchingGameScreen>
    with TickerProviderStateMixin {
  
  // Game configuration
  static const int totalRounds = 10;
  int currentRound = 1;
  int score = 0;
  
  // Current game state
  late GameColor currentColor;
  late List<GameColor> targetColors;
  int correctTargetIndex = 0;
  
  // Animation controllers
  late AnimationController _successAnimationController;
  late AnimationController _shakeAnimationController;
  late AnimationController _progressAnimationController;
  late Animation<double> _successAnimation;
  late Animation<double> _shakeAnimation;
  late Animation<double> _progressAnimation;
  
  // Game feedback state
  bool isShowingFeedback = false;
  String feedbackMessage = '';
  bool wasCorrect = false;
  
  // Game colors with names for accessibility
  final List<GameColor> gameColors = [
    GameColor('Red', const Color(0xFFFF6B6B), '🔴'),
    GameColor('Blue', const Color(0xFF4ECDC4), '🔵'),
    GameColor('Green', const Color(0xFF95E1D3), '🟢'),
    GameColor('Yellow', const Color(0xFFFFE66D), '🟡'),
    GameColor('Purple', const Color(0xFFB983FF), '🟣'),
    GameColor('Orange', const Color(0xFFFF8E53), '🟠'),
    GameColor('Pink', const Color(0xFFFF8A95), '🩷'),
    GameColor('Cyan', const Color(0xFF17A2B8), '🔷'),
    GameColor('Lime', const Color(0xFF7ED321), '🟢'),
    GameColor('Indigo', const Color(0xFF6610F2), '🔮'),
    GameColor('Teal', const Color(0xFF20C997), '🌊'),
    GameColor('Brown', const Color(0xFF8D6E63), '🤎'),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startNewRound();
  }

  void _initializeAnimations() {
    _successAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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
  }

  @override
  void dispose() {
    _successAnimationController.dispose();
    _shakeAnimationController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }

  void _startNewRound() {
    setState(() {
      // Select random color for this round
      currentColor = gameColors[math.Random().nextInt(gameColors.length)];
      
      // Create target colors list (one correct, two wrong)
      targetColors = [];
      correctTargetIndex = math.Random().nextInt(3);
      
      // Add the correct color at the correct index
      for (int i = 0; i < 3; i++) {
        if (i == correctTargetIndex) {
          targetColors.add(currentColor);
        } else {
          // Add different colors
          GameColor differentColor;
          do {
            differentColor = gameColors[math.Random().nextInt(gameColors.length)];
          } while (differentColor.name == currentColor.name || 
                   targetColors.any((color) => color.name == differentColor.name));
          
          targetColors.add(differentColor);
        }
      }
      
      isShowingFeedback = false;
      feedbackMessage = '';
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
  }

  void _handleColorDrop(int targetIndex) {
    if (isShowingFeedback) return;
    
    final isCorrect = targetIndex == correctTargetIndex;
    
    setState(() {
      isShowingFeedback = true;
      wasCorrect = isCorrect;
      
      if (isCorrect) {
        score++;
        feedbackMessage = 'Matched! 🎉';
        _successAnimationController.forward();
        
        // Play success haptic feedback
        HapticFeedback.lightImpact();
        
        // Move to next round after animation
        Future.delayed(const Duration(milliseconds: 1500), () {
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
        
        // Play error haptic feedback
        HapticFeedback.heavyImpact();
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

    return Container(
      padding: EdgeInsets.all(isLandscape ? screenWidth * 0.015 : screenWidth * 0.04),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(screenWidth, screenHeight, isLandscape),
            
            SizedBox(height: isLandscape ? screenHeight * 0.01 : screenHeight * 0.03),
            
            // Instructions
            _buildInstructions(screenWidth, screenHeight, isLandscape),
            
            SizedBox(height: isLandscape ? screenHeight * 0.015 : screenHeight * 0.04),
            
            // Draggable color
            _buildDraggableColor(screenWidth, screenHeight, isLandscape),
            
            SizedBox(height: isLandscape ? screenHeight * 0.015 : screenHeight * 0.04),
            
            // Target color boxes
            _buildTargetColors(screenWidth, screenHeight, isLandscape),
            
            // Feedback area
            if (isShowingFeedback) ...[
              SizedBox(height: isLandscape ? screenHeight * 0.01 : screenHeight * 0.03),
              _buildFeedback(screenWidth, screenHeight, isLandscape),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(double screenWidth, double screenHeight, bool isLandscape) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: isLandscape ? screenHeight * 0.005 : screenHeight * 0.02,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
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
                'Round $currentRound of $totalRounds',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
              ),
              Row(
                children: [
                  Icon(
                    CupertinoIcons.star_fill,
                    color: const Color(0xFFFFE66D),
                    size: screenWidth * 0.05,
                  ),
                  SizedBox(width: screenWidth * 0.01),
                  Text(
                    '$score',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.01),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: _progressAnimation.value,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
                minHeight: 6,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions(double screenWidth, double screenHeight, bool isLandscape) {
    return Container(
      padding: EdgeInsets.all(isLandscape ? screenWidth * 0.015 : screenWidth * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFF4ECDC4).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4ECDC4).withOpacity(0.3),
        ),
      ),
      child: Text(
        'Drag the ${currentColor.name.toLowerCase()} color ${currentColor.emoji} to the matching box below!',
        style: TextStyle(
          fontSize: isLandscape ? screenWidth * 0.025 : screenWidth * 0.04,
          color: const Color(0xFF2D3748),
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDraggableColor(double screenWidth, double screenHeight, bool isLandscape) {
    // Reduce the color size to half in horizontal view as requested - making it even smaller
    final colorSize = isLandscape ? screenHeight * 0.08 : screenWidth * 0.25;
    
    return AnimatedBuilder(
      animation: _successAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_successAnimation.value * 0.2),
          child: Draggable<GameColor>(
            data: currentColor,
            feedback: _buildColorChip(currentColor, colorSize, true),
            childWhenDragging: Opacity(
              opacity: 0.5,
              child: _buildColorChip(currentColor, colorSize, false),
            ),
            child: _buildColorChip(currentColor, colorSize, false),
          ),
        );
      },
    );
  }

  Widget _buildColorChip(GameColor color, double size, bool isDragging) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.color,
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [
          BoxShadow(
            color: color.color.withOpacity(0.4),
            blurRadius: isDragging ? 20 : 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white,
          width: 4,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              color.emoji,
              style: TextStyle(fontSize: size * 0.3),
            ),
            Text(
              color.name,
              style: TextStyle(
                fontSize: size * 0.12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetColors(double screenWidth, double screenHeight, bool isLandscape) {
    final boxSize = isLandscape ? screenHeight * 0.1 : screenWidth * 0.2;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: targetColors.asMap().entries.map((entry) {
        final index = entry.key;
        final color = entry.value;
        
        return AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            final offset = index == correctTargetIndex && !wasCorrect && isShowingFeedback
                ? math.sin(_shakeAnimation.value * math.pi * 4) * 5
                : 0.0;
            
            return Transform.translate(
              offset: Offset(offset, 0),
              child: DragTarget<GameColor>(
                onWillAccept: (data) => !isShowingFeedback,
                onAccept: (data) => _handleColorDrop(index),
                builder: (context, candidateData, rejectedData) {
                  final isHighlighted = candidateData.isNotEmpty;
                  
                  return Container(
                    width: boxSize,
                    height: boxSize,
                    decoration: BoxDecoration(
                      color: isHighlighted 
                          ? color.color.withOpacity(0.3)
                          : color.color.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isHighlighted 
                            ? Colors.white 
                            : color.color,
                        width: isHighlighted ? 4 : 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.color.withOpacity(0.3),
                          blurRadius: isHighlighted ? 16 : 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        color.emoji,
                        style: TextStyle(fontSize: boxSize * 0.4),
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

  Widget _buildFeedback(double screenWidth, double screenHeight, bool isLandscape) {
    return AnimatedBuilder(
      animation: wasCorrect ? _successAnimation : _shakeAnimation,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.06,
            vertical: isLandscape ? screenHeight * 0.01 : screenHeight * 0.02,
          ),
          decoration: BoxDecoration(
            color: wasCorrect
                ? const Color(0xFF48BB78).withOpacity(0.1)
                : const Color(0xFFFF6B6B).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
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
              fontSize: isLandscape ? screenWidth * 0.035 : screenWidth * 0.05,
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
}

/// Data class for game colors
class GameColor {
  final String name;
  final Color color;
  final String emoji;

  const GameColor(this.name, this.color, this.emoji);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameColor && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}
