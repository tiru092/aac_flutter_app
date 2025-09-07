import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/aac_helper.dart';

/// Data class for game shapes
class GameShape {
  final String name;
  final Color color;
  final String emoji;
  final Widget shape;

  const GameShape(this.name, this.color, this.emoji, this.shape);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameShape && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}

/// Shape Matching Game Screen with drag and drop functionality
class ShapeMatchingGameScreen extends StatefulWidget {
  const ShapeMatchingGameScreen({super.key});

  @override
  State<ShapeMatchingGameScreen> createState() => _ShapeMatchingGameScreenState();
}

class _ShapeMatchingGameScreenState extends State<ShapeMatchingGameScreen>
    with TickerProviderStateMixin {
  
  // Game configuration
  static const int totalRounds = 10;
  int currentRound = 1;
  int score = 0;
  
  // Current game state
  late GameShape currentShape;
  late List<GameShape> targetShapes;
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
  
  // Game shapes with names for accessibility - 10 unique shapes with proper visual representations
  final List<GameShape> gameShapes = [
    GameShape('Circle', const Color(0xFFFF6B6B), '⭕', _buildCircleShape(const Color(0xFFFF6B6B))),
    GameShape('Square', const Color(0xFF4ECDC4), '🟦', _buildSquareShape(const Color(0xFF4ECDC4))),
    GameShape('Triangle', const Color(0xFF45B7D1), '🔺', _buildTriangleShape(const Color(0xFF45B7D1))),
    GameShape('Rectangle', const Color(0xFF96CEB4), '🟫', _buildRectangleShape(const Color(0xFF96CEB4))),
    GameShape('Star', const Color(0xFFFFE66D), '⭐', _buildStarShape(const Color(0xFFFFE66D))),
    GameShape('Heart', const Color(0xFFF38BA8), '❤️', _buildHeartShape(const Color(0xFFF38BA8))),
    GameShape('Diamond', const Color(0xFFB983FF), '💎', _buildDiamondShape(const Color(0xFFB983FF))),
    GameShape('Oval', const Color(0xFFFF8A95), '🥚', _buildOvalShape(const Color(0xFFFF8A95))),
    GameShape('Pentagon', const Color(0xFF20C997), '🛑', _buildPentagonShape(const Color(0xFF20C997))),
    GameShape('Hexagon', const Color(0xFF6610F2), '⬡', _buildHexagonShape(const Color(0xFF6610F2))),
  ];

  static Widget _buildCircleShape(Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  static Widget _buildSquareShape(Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  static Widget _buildTriangleShape(Color color) {
    return CustomPaint(
      painter: TrianglePainter(color),
      size: const Size.square(100),
    );
  }

  static Widget _buildRectangleShape(Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  static Widget _buildStarShape(Color color) {
    return CustomPaint(
      painter: StarPainter(color),
      size: const Size.square(100),
    );
  }

  static Widget _buildHeartShape(Color color) {
    return CustomPaint(
      painter: HeartPainter(color),
      size: const Size.square(100),
    );
  }

  static Widget _buildDiamondShape(Color color) {
    return CustomPaint(
      painter: DiamondPainter(color),
      size: const Size.square(100),
    );
  }

  static Widget _buildOvalShape(Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  static Widget _buildPentagonShape(Color color) {
    return CustomPaint(
      painter: PentagonPainter(color),
      size: const Size.square(100),
    );
  }

  static Widget _buildHexagonShape(Color color) {
    return CustomPaint(
      painter: HexagonPainter(color),
      size: const Size.square(100),
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
      // Select random shape for this round
      currentShape = gameShapes[math.Random().nextInt(gameShapes.length)];
      
      // Create target shapes list (one correct, two wrong)
      targetShapes = [];
      correctTargetIndex = math.Random().nextInt(3);
      
      // Add the correct shape at the correct index
      for (int i = 0; i < 3; i++) {
        if (i == correctTargetIndex) {
          targetShapes.add(currentShape);
        } else {
          // Add different shapes
          GameShape differentShape;
          do {
            differentShape = gameShapes[math.Random().nextInt(gameShapes.length)];
          } while (differentShape.name == currentShape.name || 
                   targetShapes.any((shape) => shape.name == differentShape.name));
          
          targetShapes.add(differentShape);
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
          'Find the ${currentShape.name} shape and drag it to the matching box!',
          tone: EmotionalTone.friendly,
        );
      }
    });
  }

  void _handleShapeDrop(int targetIndex) {
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
          'Excellent! You matched ${currentShape.name} perfectly! Well done!',
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
          'Oops! Try to find the ${currentShape.name} shape',
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
                // Instructions (removed progress indicator to save space)
                _buildInstructions(screenWidth, screenHeight, isLandscape),
                
                SizedBox(height: isLandscape ? screenHeight * 0.01 : screenHeight * 0.04),
                
                // Draggable shape
                _buildDraggableShape(screenWidth, screenHeight, isLandscape),
                
                // Increased spacing between draggable and target shapes - additional 20% more space
                SizedBox(height: isLandscape ? screenHeight * 0.042 : screenHeight * 0.048),
                
                // Target shape boxes
                _buildTargetShapes(screenWidth, screenHeight, isLandscape),
                
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
        color: const Color(0xFF45B7D1).withOpacity(0.1),
        borderRadius: BorderRadius.circular(isLandscape ? 8 : 12),
        border: Border.all(
          color: const Color(0xFF45B7D1).withOpacity(0.3),
        ),
      ),
      child: Text(
        'Drag the ${currentShape.name.toLowerCase()} shape ${currentShape.emoji} to the matching box below!',
        style: TextStyle(
          fontSize: isLandscape ? screenWidth * 0.018 : screenWidth * 0.04,
          color: const Color(0xFF2D3748),
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDraggableShape(double screenWidth, double screenHeight, bool isLandscape) {
    // Make the shape much bigger for practice in horizontal view - increased by 60% from 0.15 to 0.24
    final shapeSize = isLandscape ? screenHeight * 0.24 : screenWidth * 0.25;
    
    return AnimatedBuilder(
      animation: _successAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_successAnimation.value * 0.2),
          child: Draggable<GameShape>(
            data: currentShape,
            feedback: _buildShapeChip(currentShape, shapeSize, true),
            childWhenDragging: Opacity(
              opacity: 0.5,
              child: _buildShapeChip(currentShape, shapeSize, false),
            ),
            child: _buildShapeChip(currentShape, shapeSize, false),
          ),
        );
      },
    );
  }

  Widget _buildShapeChip(GameShape shape, double size, bool isDragging) {
    return Container(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Shape background
          Positioned.fill(
            child: shape.name == 'Rectangle' 
                ? Container(
                    width: size * 1.4,
                    height: size * 0.8,
                    child: shape.shape,
                  )
                : shape.shape,
          ),
          // Shape name text overlay
          Positioned.fill(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    shape.emoji,
                    style: TextStyle(fontSize: size * 0.2),
                  ),
                  SizedBox(height: size * 0.05),
                  Text(
                    shape.name,
                    style: TextStyle(
                      fontSize: size * 0.1,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.8),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetShapes(double screenWidth, double screenHeight, bool isLandscape) {
    // Increased target box size for better visibility and separation
    final boxSize = isLandscape ? screenHeight * 0.22 : screenWidth * 0.22;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: targetShapes.asMap().entries.map((entry) {
        final index = entry.key;
        final shape = entry.value;
        
        return AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            final offset = index == correctTargetIndex && !wasCorrect && isShowingFeedback
                ? math.sin(_shakeAnimation.value * math.pi * 4) * 5
                : 0.0;
            
            return Transform.translate(
              offset: Offset(offset, 0),
              child: DragTarget<GameShape>(
                onWillAccept: (data) => !isShowingFeedback,
                onAccept: (data) => _handleShapeDrop(index),
                builder: (context, candidateData, rejectedData) {
                  final isHighlighted = candidateData.isNotEmpty;
                  
                  return Container(
                    width: boxSize,
                    height: boxSize,
                    decoration: BoxDecoration(
                      color: isHighlighted 
                          ? shape.color.withOpacity(0.3)
                          : shape.color.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isHighlighted 
                            ? Colors.white 
                            : shape.color,
                        width: isHighlighted ? 4 : 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: shape.color.withOpacity(0.3),
                          blurRadius: isHighlighted ? 16 : 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Shape in background
                        Positioned.fill(
                          child: Container(
                            margin: EdgeInsets.all(boxSize * 0.15),
                            child: shape.name == 'Rectangle' 
                                ? Container(
                                    width: boxSize * 0.7 * 1.4,
                                    height: boxSize * 0.7 * 0.8,
                                    child: shape.shape,
                                  )
                                : shape.shape,
                          ),
                        ),
                        // Emoji overlay
                        Center(
                          child: Text(
                            shape.emoji,
                            style: TextStyle(fontSize: boxSize * 0.25),
                          ),
                        ),
                      ],
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

// Custom painters for different shapes
class TrianglePainter extends CustomPainter {
  final Color color;
  
  TrianglePainter(this.color);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
    
    // White border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(path, borderPaint);
    
    // Shadow
    canvas.drawShadow(path, color.withOpacity(0.3), 4, false);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StarPainter extends CustomPainter {
  final Color color;
  
  StarPainter(this.color);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.4;
    
    for (int i = 0; i < 10; i++) {
      final angle = (i * math.pi / 5) - (math.pi / 2);
      final radius = i.isEven ? outerRadius : innerRadius;
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
    
    // White border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(path, borderPaint);
    
    // Shadow
    canvas.drawShadow(path, color.withOpacity(0.3), 4, false);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HeartPainter extends CustomPainter {
  final Color color;
  
  HeartPainter(this.color);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path();
    final width = size.width;
    final height = size.height;
    
    path.moveTo(width / 2, height * 0.8);
    path.cubicTo(width * 0.2, height * 0.5, width * 0.2, height * 0.2, width / 2, height * 0.3);
    path.cubicTo(width * 0.8, height * 0.2, width * 0.8, height * 0.5, width / 2, height * 0.8);
    
    canvas.drawPath(path, paint);
    
    // White border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(path, borderPaint);
    
    // Shadow
    canvas.drawShadow(path, color.withOpacity(0.3), 4, false);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DiamondPainter extends CustomPainter {
  final Color color;
  
  DiamondPainter(this.color);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(0, size.height / 2);
    path.close();
    
    canvas.drawPath(path, paint);
    
    // White border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(path, borderPaint);
    
    // Shadow
    canvas.drawShadow(path, color.withOpacity(0.3), 4, false);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PentagonPainter extends CustomPainter {
  final Color color;
  
  PentagonPainter(this.color);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width / 2;
    
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi / 5) - (math.pi / 2);
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
    
    // White border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(path, borderPaint);
    
    // Shadow
    canvas.drawShadow(path, color.withOpacity(0.3), 4, false);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HexagonPainter extends CustomPainter {
  final Color color;
  
  HexagonPainter(this.color);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width / 2;
    
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
    
    // White border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(path, borderPaint);
    
    // Shadow
    canvas.drawShadow(path, color.withOpacity(0.3), 4, false);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
