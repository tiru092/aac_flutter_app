import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/enhanced_goal.dart';
import '../models/goal.dart';
import '../services/arasaac_service.dart';
import '../utils/aac_helper.dart';
import 'dart:math' as math;

class GoalCard extends StatefulWidget {
  final EnhancedGoal goal;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onPractice;
  final Function(int)? onProgressUpdate;
  final bool showMascot;

  const GoalCard({
    super.key,
    required this.goal,
    required this.onTap,
    this.onEdit,
    this.onPractice,
    this.onProgressUpdate,
    this.showMascot = true,
  });

  @override
  State<GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<GoalCard>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _progressController;
  late AnimationController _celebrationController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _celebrationAnimation;

  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.goal.progressPercentage / 100.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));

    _celebrationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    ));

    // Start progress animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _progressController.forward();
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _progressController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  void _handleTap() async {
    // Bounce animation
    await _bounceController.forward();
    _bounceController.reverse();

    // Play sound based on progress
    if (widget.goal.isCompleted) {
      await AACHelper.speak('Goal completed! ${widget.goal.title}');
      _triggerCelebration();
    } else {
      await AACHelper.speak(widget.goal.title);
    }

    widget.onTap();
  }

  void _triggerCelebration() {
    setState(() {
      _showConfetti = true;
    });
    _celebrationController.forward();
    
    // Hide confetti after animation
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _showConfetti = false;
        });
        _celebrationController.reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _bounceAnimation.value,
          child: Container(
            margin: const EdgeInsets.all(8),
            child: Stack(
              children: [
                _buildMainCard(),
                if (_showConfetti) _buildConfettiOverlay(),
                if (widget.showMascot) _buildMascotBubble(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainCard() {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.goal.categoryCardColor,
              widget.goal.categoryCardColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: widget.goal.categoryCardColor.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              _buildCardContent(),
              _buildProgressIndicator(),
              if (widget.goal.isCompleted) _buildCompletedBadge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildPictogram(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.goal.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.goal.category.displayName,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildFrequencyIcon(),
            ],
          ),
          const Spacer(),
          _buildProgressSection(),
          if (!widget.goal.isCompleted && widget.onPractice != null)
            _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildPictogram() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: widget.goal.arasaacPictogramId != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: CachedNetworkImage(
                imageUrl: ArasaacService.getPictogramUrl(
                  widget.goal.arasaacPictogramId!,
                  size: 200,
                ),
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CupertinoActivityIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) => _buildFallbackIcon(),
              ),
            )
          : _buildFallbackIcon(),
    );
  }

  Widget _buildFallbackIcon() {
    final categoryIcons = {
      GoalCategory.communication: '💬',
      GoalCategory.social: '👥',
      GoalCategory.dailyLiving: '🏠',
      GoalCategory.learning: '📚',
      GoalCategory.emotional: '💝',
      GoalCategory.routine: '📅',
    };

    return Center(
      child: Text(
        categoryIcons[widget.goal.category] ?? '🎯',
        style: const TextStyle(fontSize: 24),
      ),
    );
  }

  Widget _buildFrequencyIcon() {
    String icon;
    switch (widget.goal.frequency) {
      case GoalFrequency.weekly:
        icon = '☀️'; // Sun for daily progress
        break;
      case GoalFrequency.biweekly:
        icon = '🌸'; // Flower for growing progress
        break;
      case GoalFrequency.monthly:
        icon = '🧩'; // Puzzle piece for building
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        icon,
        style: const TextStyle(fontSize: 20),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${widget.goal.currentProgress}/${widget.goal.targetValue}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${widget.goal.progressPercentage}%',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildFrequencyProgressBar(),
      ],
    );
  }

  Widget _buildFrequencyProgressBar() {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _progressAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.white.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Practice button
          GestureDetector(
            onTap: widget.onPractice,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.play_circle,
                    color: Colors.white.withOpacity(0.9),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Practice',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Progress update button
          if (widget.onProgressUpdate != null)
            GestureDetector(
              onTap: () => widget.onProgressUpdate!(widget.goal.currentProgress + 1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.plus_circle,
                      color: Colors.white.withOpacity(0.9),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+1',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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

  Widget _buildProgressIndicator() {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          widget.goal.frequency.name.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedBadge() {
    return Positioned(
      top: -5,
      right: -5,
      child: AnimatedBuilder(
        animation: _celebrationAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: 0.8 + (0.4 * _celebrationAnimation.value),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '🏆',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMascotBubble() {
    if (widget.goal.mascotEncouragement.isEmpty) return const SizedBox.shrink();

    return Positioned(
      bottom: -10,
      left: 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Text('🤖', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.goal.mascotEncouragement,
                style: TextStyle(
                  color: widget.goal.categoryCardColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfettiOverlay() {
    return AnimatedBuilder(
      animation: _celebrationAnimation,
      builder: (context, child) {
        return Positioned.fill(
          child: CustomPaint(
            painter: ConfettiPainter(
              animation: _celebrationAnimation,
              stickers: widget.goal.completionCelebration,
            ),
          ),
        );
      },
    );
  }
}

class ConfettiPainter extends CustomPainter {
  final Animation<double> animation;
  final List<String> stickers;
  final List<Offset> positions;
  final List<double> rotations;

  ConfettiPainter({
    required this.animation,
    required this.stickers,
  }) : positions = List.generate(20, (index) {
          final random = math.Random(index);
          return Offset(
            random.nextDouble(),
            random.nextDouble(),
          );
        }),
        rotations = List.generate(20, (index) {
          final random = math.Random(index + 100);
          return random.nextDouble() * 2 * math.pi;
        });

  @override
  void paint(Canvas canvas, Size size) {
    if (animation.value == 0) return;

    for (int i = 0; i < positions.length; i++) {
      final position = Offset(
        positions[i].dx * size.width,
        positions[i].dy * size.height - (size.height * animation.value * 0.5),
      );

      final rotation = rotations[i] * animation.value * 4;
      final scale = 0.5 + (animation.value * 0.5);

      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(rotation);
      canvas.scale(scale);

      // Draw sticker emoji
      final textPainter = TextPainter(
        text: TextSpan(
          text: stickers[i % stickers.length],
          style: const TextStyle(fontSize: 20),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, const Offset(-10, -10));

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return animation.value != oldDelegate.animation.value;
  }
}
