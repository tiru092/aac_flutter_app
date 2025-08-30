import 'package:flutter/material.dart';
import '../models/practice_goal.dart';
import '../screens/practice_screen.dart';

class GoalsSection extends StatefulWidget {
  final List<PracticeGoal>? customGoals;
  final Function(PracticeGoal)? onGoalTap;

  const GoalsSection({
    Key? key,
    this.customGoals,
    this.onGoalTap,
  }) : super(key: key);

  @override
  State<GoalsSection> createState() => _GoalsSectionState();
}

class _GoalsSectionState extends State<GoalsSection> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<AnimationController> _cardControllers;
  late List<Animation<double>> _cardAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    final goalsList = widget.customGoals ?? _getDefaultGoals();
    _cardControllers = List.generate(
      goalsList.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 600 + (index * 100)),
        vsync: this,
      ),
    );
    
    _cardAnimations = _cardControllers.map((controller) =>
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.elasticOut),
      ),
    ).toList();

    // Start animations with staggered delay
    for (int i = 0; i < _cardControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _cardControllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<PracticeGoal> _getDefaultGoals() {
    return PracticeGoalsData.getAllGoals();
  }

  @override
  Widget build(BuildContext context) {
    final goalsList = widget.customGoals ?? _getDefaultGoals();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, isLandscape, screenWidth),
            SizedBox(height: isLandscape ? 12 : 8),
            Expanded(
              child: _buildGoalsGrid(context, goalsList, isLandscape, screenWidth, screenHeight),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, bool isLandscape, double screenWidth) {
    final fontSize = isLandscape 
        ? screenWidth * 0.025  // Smaller font for landscape
        : screenWidth * 0.055; // Larger font for portrait
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isLandscape ? 20 : 16,
        vertical: isLandscape ? 8 : 4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Practice Goals',
            style: TextStyle(
              fontSize: fontSize.clamp(18.0, 28.0),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D4356),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star,
                  size: isLandscape ? 14 : 16,
                  color: const Color(0xFFFFD700),
                ),
                const SizedBox(width: 4),
                Text(
                  '⭐ 85',
                  style: TextStyle(
                    fontSize: isLandscape ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsGrid(BuildContext context, List<PracticeGoal> goals, 
                        bool isLandscape, double screenWidth, double screenHeight) {
    if (isLandscape) {
      return _buildLandscapeLayout(context, goals, screenWidth, screenHeight);
    } else {
      return _buildPortraitLayout(context, goals, screenWidth, screenHeight);
    }
  }

  Widget _buildPortraitLayout(BuildContext context, List<PracticeGoal> goals, 
                             double screenWidth, double screenHeight) {
    const crossAxisCount = 2; // 2 columns in portrait mode
    const cardAspectRatio = 1.2;
    final spacing = screenWidth * 0.03;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: cardAspectRatio,
        ),
        itemCount: goals.length,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _cardAnimations[index],
            builder: (context, child) {
              return Transform.scale(
                scale: _cardAnimations[index].value,
                child: _buildGoalCard(
                  context, 
                  goals[index], 
                  index, 
                  false, // isLandscape
                  screenWidth, 
                  screenHeight
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, List<PracticeGoal> goals, 
                              double screenWidth, double screenHeight) {
    final crossAxisCount = screenWidth > 1200 ? 5 : (screenWidth > 800 ? 4 : 3);
    const cardAspectRatio = 0.85;
    final spacing = screenWidth * 0.02;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: cardAspectRatio,
        ),
        itemCount: goals.length,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _cardAnimations[index],
            builder: (context, child) {
              return Transform.scale(
                scale: _cardAnimations[index].value,
                child: _buildGoalCard(
                  context, 
                  goals[index], 
                  index, 
                  true, // isLandscape
                  screenWidth, 
                  screenHeight
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, PracticeGoal goal, int index, 
                       bool isLandscape, double screenWidth, double screenHeight) {
    final cardColor = _parseColor(goal.color);
    final titleFontSize = isLandscape 
        ? (screenWidth * 0.012).clamp(12.0, 16.0)
        : (screenWidth * 0.035).clamp(14.0, 18.0);
    final descFontSize = isLandscape 
        ? (screenWidth * 0.01).clamp(10.0, 13.0)
        : (screenWidth * 0.028).clamp(11.0, 14.0);
    final emojiSize = isLandscape 
        ? (screenWidth * 0.025).clamp(20.0, 32.0)
        : (screenWidth * 0.08).clamp(32.0, 48.0);

    return GestureDetector(
      onTap: () => _onGoalTapped(goal),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cardColor,
              cardColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(isLandscape ? 16 : 20),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: isLandscape ? 60 : 80,
                height: isLandscape ? 60 : 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Content
            Padding(
              padding: EdgeInsets.all(isLandscape ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildProgressStars(goal.totalStars, 3),
                      Text(
                        goal.iconEmoji,
                        style: TextStyle(fontSize: emojiSize),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Goal title
                  Text(
                    goal.name,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isLandscape ? 4 : 8),
                  // Description
                  Text(
                    goal.description,
                    style: TextStyle(
                      fontSize: descFontSize,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  // Progress bar
                  _buildProgressBar(goal.progress),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStars(int total, int earned) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < earned ? Icons.star : Icons.star_border,
          color: Colors.white,
          size: 16,
        );
      }),
    );
  }

  Widget _buildProgressBar(double progress) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      // Handle colors without # prefix
      if (!colorString.startsWith('#') && !colorString.startsWith('0x')) {
        colorString = 'FF$colorString'; // Add FF for full opacity
      }
      if (colorString.startsWith('#')) {
        colorString = colorString.replaceAll('#', 'FF');
      }
      return Color(int.parse(colorString, radix: 16));
    } catch (e) {
      return const Color(0xFF4CAF50); // Default green
    }
  }

  void _onGoalTapped(PracticeGoal goal) {
    if (widget.onGoalTap != null) {
      widget.onGoalTap!(goal);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PracticeScreen(goal: goal),
        ),
      );
    }
  }
}
