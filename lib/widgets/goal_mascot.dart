import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/enhanced_goal.dart';
import '../utils/aac_helper.dart';
import 'dart:math' as math;

class GoalMascot extends StatefulWidget {
  final EnhancedGoal? currentGoal;
  final List<EnhancedGoal> allGoals;
  final VoidCallback? onTap;

  const GoalMascot({
    super.key,
    this.currentGoal,
    this.allGoals = const [],
    this.onTap,
  });

  @override
  State<GoalMascot> createState() => _GoalMascotState();
}

class _GoalMascotState extends State<GoalMascot>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _blinkController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _blinkAnimation;

  final List<String> _mascotEmojis = ['🤖', '🐻', '🦄', '🐙', '🦜'];
  String _currentMascot = '🤖';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startPeriodicAnimation();
  }

  void _setupAnimations() {
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    _blinkAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _blinkController,
      curve: Curves.easeInOut,
    ));
  }

  void _startPeriodicAnimation() {
    // Bounce every 5 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _bounceController.forward().then((_) {
          if (mounted) {
            _bounceController.reset();
            _startPeriodicAnimation();
          }
        });
      }
    });

    // Random blink
    Future.delayed(Duration(seconds: 3 + math.Random().nextInt(5)), () {
      if (mounted) {
        _blinkController.forward().then((_) {
          if (mounted) {
            _blinkController.reverse();
            _startPeriodicAnimation();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  String get _encouragementMessage {
    if (widget.currentGoal != null) {
      return widget.currentGoal!.mascotEncouragement;
    }

    final completedGoals = widget.allGoals.where((g) => g.isCompleted).length;
    final totalGoals = widget.allGoals.length;

    if (totalGoals == 0) {
      return "🌟 Ready to set some amazing goals? Let's make progress together! 🎯";
    } else if (completedGoals == totalGoals) {
      return "🎉 WOW! You completed ALL your goals! You're absolutely incredible! 🏆";
    } else if (completedGoals > 0) {
      return "⭐ You've completed $completedGoals goals! Keep up the fantastic work! 💪";
    } else {
      return "🚀 You have $totalGoals goals to work on. Let's start with one! You've got this! 🌈";
    }
  }

  String get _mascotExpression {
    if (widget.currentGoal?.isCompleted == true) {
      return '🎉'; // Celebrating
    }
    
    return _currentMascot;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await AACHelper.speak(_encouragementMessage);
        widget.onTap?.call();
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF6C5CE7),
              Color(0xFF74B9FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C5CE7).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildMascotAvatar(),
            const SizedBox(height: 12),
            _buildSpeechBubble(),
          ],
        ),
      ),
    );
  }

  Widget _buildMascotAvatar() {
    return AnimatedBuilder(
      animation: Listenable.merge([_bounceAnimation, _blinkAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -10 * _bounceAnimation.value),
          child: Transform.scale(
            scale: 1.0 + (0.1 * _bounceAnimation.value),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 3,
                ),
              ),
              child: Center(
                child: AnimatedOpacity(
                  opacity: 0.2 + (0.8 * _blinkAnimation.value),
                  duration: const Duration(milliseconds: 100),
                  child: Text(
                    _mascotExpression,
                    style: TextStyle(
                      fontSize: 40,
                      shadows: [
                        Shadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpeechBubble() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.chat_bubble_fill,
                color: Colors.white.withOpacity(0.8),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Your Goal Buddy says:',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _encouragementMessage,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: CupertinoIcons.volume_up,
          label: 'Speak',
          onTap: () => AACHelper.speak(_encouragementMessage),
        ),
        _buildActionButton(
          icon: CupertinoIcons.heart_fill,
          label: 'Cheer',
          onTap: _triggerCheer,
        ),
        _buildActionButton(
          icon: CupertinoIcons.refresh,
          label: 'New Tip',
          onTap: _changeMascot,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white.withOpacity(0.9),
              size: 18,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _triggerCheer() async {
    await AACHelper.speak('You are amazing! Keep going!');
    _bounceController.forward().then((_) {
      if (mounted) {
        _bounceController.reset();
      }
    });
  }

  void _changeMascot() {
    setState(() {
      final random = math.Random();
      _currentMascot = _mascotEmojis[random.nextInt(_mascotEmojis.length)];
    });
    _bounceController.forward().then((_) {
      if (mounted) {
        _bounceController.reset();
      }
    });
  }
}

/// Floating mascot that can appear anywhere on screen
class FloatingMascot extends StatefulWidget {
  final String message;
  final VoidCallback? onDismiss;

  const FloatingMascot({
    super.key,
    required this.message,
    this.onDismiss,
  });

  @override
  State<FloatingMascot> createState() => _FloatingMascotState();
}

class _FloatingMascotState extends State<FloatingMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
    ));

    _controller.forward();

    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            MediaQuery.of(context).size.width * _slideAnimation.value,
            0,
          ),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTap: _dismiss,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.orange, Colors.deepOrange],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
