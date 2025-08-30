import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/practice_goal.dart';
import 'practice_screen.dart';

class GoalsSection extends StatefulWidget {
  const GoalsSection({super.key});

  @override
  State<GoalsSection> createState() => _GoalsSectionState();
}

class _GoalsSectionState extends State<GoalsSection>
    with TickerProviderStateMixin {
  late List<AnimationController> _cardControllers;
  late List<Animation<double>> _cardAnimations;
  final List<PracticeGoal> goals = PracticeGoalsData.getAllGoals();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _cardControllers = List.generate(
      goals.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 600 + (index * 80)),
        vsync: this,
      ),
    );

    _cardAnimations = _cardControllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
      ));
    }).toList();

    // Start animations with stagger
    _startStaggeredAnimations();
  }

  void _startStaggeredAnimations() {
    for (int i = 0; i < _cardControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 80), () {
        if (mounted) {
          _cardControllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: isLandscape ? screenSize.height * 0.65 : screenSize.height * 0.55,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context, isLandscape, screenSize),
          SizedBox(height: screenSize.height * 0.008),
          Expanded(
            child: _buildGoalsGrid(context, isLandscape, screenSize),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isLandscape, Size screenSize) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.04),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isLandscape ? 5 : 7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366f1).withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              CupertinoIcons.star_circle_fill,
              color: Colors.white,
              size: isLandscape ? 16 : 18,
            ),
          ),
          SizedBox(width: screenSize.width * 0.025),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AutoSizeText(
                  'Practice Goals',
                  style: GoogleFonts.nunito(
                    fontSize: isLandscape ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1f2937),
                  ),
                  maxLines: 1,
                  minFontSize: 14,
                ),
                AutoSizeText(
                  'Fun activities to improve communication',
                  style: GoogleFonts.nunito(
                    fontSize: isLandscape ? 11 : 13,
                    color: const Color(0xFF6b7280),
                  ),
                  maxLines: 1,
                  minFontSize: 9,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsGrid(BuildContext context, bool isLandscape, Size screenSize) {
    final crossAxisCount = isLandscape ? 4 : 2;
    final childAspectRatio = isLandscape ? 1.15 : 0.95;
    
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(
        horizontal: screenSize.width * 0.02,
        vertical: screenSize.height * 0.005,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: screenSize.width * 0.025,
        mainAxisSpacing: screenSize.height * 0.012,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: goals.length,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _cardAnimations[index],
          builder: (context, child) {
            final animValue = _cardAnimations[index].value.clamp(0.0, 1.0);
            return Transform.scale(
              scale: 0.8 + (animValue * 0.2), // Scale from 0.8 to 1.0
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - animValue)), // Slide up effect
                child: Opacity(
                  opacity: animValue,
                  child: _buildGoalCard(context, goals[index], isLandscape, screenSize),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGoalCard(
    BuildContext context,
    PracticeGoal goal,
    bool isLandscape,
    Size screenSize,
  ) {
    final color = Color(int.parse('FF${goal.color}', radix: 16));
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openPracticeScreen(context, goal),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.85),
                color.withOpacity(0.65),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(isLandscape ? 10.0 : 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildGoalIcon(goal, isLandscape, screenSize),
                    _buildProgressStars(goal, isLandscape, screenSize),
                  ],
                ),
                SizedBox(height: isLandscape ? 6 : 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AutoSizeText(
                        goal.name,
                        style: GoogleFonts.nunito(
                          fontSize: isLandscape ? 13 : 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        minFontSize: 10,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isLandscape ? 3 : 4),
                      Expanded(
                        child: AutoSizeText(
                          goal.description,
                          style: GoogleFonts.nunito(
                            fontSize: isLandscape ? 10 : 11,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          maxLines: isLandscape ? 2 : 3,
                          minFontSize: 7,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isLandscape ? 4 : 6),
                _buildProgressBar(goal, isLandscape),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalIcon(PracticeGoal goal, bool isLandscape, Size screenSize) {
    return Container(
      padding: EdgeInsets.all(isLandscape ? 6 : 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        goal.iconEmoji,
        style: TextStyle(
          fontSize: isLandscape ? 16 : 18,
        ),
      ),
    );
  }

  Widget _buildProgressStars(PracticeGoal goal, bool isLandscape, Size screenSize) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          CupertinoIcons.star_fill,
          color: Colors.amber,
          size: isLandscape ? 12 : 14,
        ),
        const SizedBox(width: 3),
        AutoSizeText(
          '${goal.totalStars}',
          style: GoogleFonts.nunito(
            fontSize: isLandscape ? 10 : 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          maxLines: 1,
          minFontSize: 8,
        ),
      ],
    );
  }

  Widget _buildProgressBar(PracticeGoal goal, bool isLandscape) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AutoSizeText(
              'Progress',
              style: GoogleFonts.nunito(
                fontSize: isLandscape ? 8 : 9,
                color: Colors.white.withOpacity(0.8),
              ),
              maxLines: 1,
              minFontSize: 7,
            ),
            AutoSizeText(
              '${goal.completedActivities}/${goal.activities.length}',
              style: GoogleFonts.nunito(
                fontSize: isLandscape ? 8 : 9,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              minFontSize: 7,
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: goal.progress.clamp(0.0, 1.0), // Ensure valid progress value
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: isLandscape ? 3 : 4,
          ),
        ),
      ],
    );
  }

  void _openPracticeScreen(BuildContext context, PracticeGoal goal) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PracticeScreen(goal: goal),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}

  @override
  void initState() {
    super.initState();
    
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Create individual animation controllers for each card
    _cardControllers = List.generate(
      goals.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 400 + (index * 50)),
        vsync: this,
      ),
    );
    
    // Create staggered animations with simpler curve
    _cardAnimations = _cardControllers.map((controller) {
      return CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
      );
    }).toList();
    
    // Start animations with stagger
    _startStaggeredAnimations();
  }
  
  void _startStaggeredAnimations() async {
    for (int i = 0; i < _cardControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 80), () {
        if (mounted) {
          _cardControllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = MediaQuery.of(context).size.height;
        final isLandscape = screenWidth > screenHeight;
        
        return SingleChildScrollView(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.02,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Section Header
                _buildSectionHeader(context, isLandscape, screenWidth),
                
                SizedBox(height: screenHeight * 0.02),
                
                // Goals Cards - Both views use vertical scrolling now
                _buildGoalsGrid(context, isLandscape, screenWidth, screenHeight),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildSectionHeader(BuildContext context, bool isLandscape, double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isLandscape ? 6 : 8), // Reduced padding
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10), // Reduced border radius
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366f1).withOpacity(0.3),
                  blurRadius: 6, // Reduced shadow
                  offset: const Offset(0, 3), // Reduced offset
                ),
              ],
            ),
            child: Icon(
              CupertinoIcons.star_circle_fill,
              color: Colors.white,
              size: isLandscape ? 16 : 20, // Reduced icon sizes
            ),
          ),
          const SizedBox(width: 10), // Reduced spacing
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Added this
              children: [
                AutoSizeText(
                  'Practice Goals',
                  style: GoogleFonts.nunito(
                    fontSize: isLandscape ? screenWidth * 0.02 : screenWidth * 0.045, // Reduced font sizes
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1f2937),
                  ),
                  maxLines: 1,
                  minFontSize: 14, // Reduced min font
                ),
                AutoSizeText(
                  'Fun activities to improve communication',
                  style: GoogleFonts.nunito(
                    fontSize: isLandscape ? screenWidth * 0.012 : screenWidth * 0.028, // Reduced font sizes
                    color: const Color(0xFF6b7280),
                  ),
                  maxLines: 1,
                  minFontSize: 8, // Reduced min font
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGoalsGrid(BuildContext context, bool isLandscape, double screenWidth, double screenHeight) {
    if (isLandscape) {
      // Landscape - Grid layout with vertical scrolling
      final crossAxisCount = screenWidth > 1200 ? 5 : screenWidth > 800 ? 4 : 3;
      
      return GridView.builder(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.1,
          crossAxisSpacing: screenWidth * 0.015,
          mainAxisSpacing: screenHeight * 0.015,
        ),
        itemCount: goals.length,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _cardAnimations[index],
            builder: (context, child) {
              final animValue = _cardAnimations[index].value.clamp(0.0, 1.0);
              return Transform.scale(
                scale: animValue,
                child: Transform.translate(
                  offset: Offset(0, 10 * (1 - animValue)),
                  child: Opacity(
                    opacity: animValue,
                    child: _buildGoalCard(
                      context,
                      goals[index],
                      index,
                      double.infinity,
                      double.infinity,
                      true,
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } else {
      // Portrait - Grid layout with vertical scrolling (2 columns)
      return GridView.builder(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.9, // Made taller to reduce height
          crossAxisSpacing: screenWidth * 0.03,
          mainAxisSpacing: screenHeight * 0.01, // Reduced spacing
        ),
        itemCount: goals.length,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _cardAnimations[index],
            builder: (context, child) {
              final animValue = _cardAnimations[index].value.clamp(0.0, 1.0);
              return Transform.scale(
                scale: animValue,
                child: Transform.translate(
                  offset: Offset(0, 15 * (1 - animValue)),
                  child: Opacity(
                    opacity: animValue,
                    child: _buildGoalCard(
                      context,
                      goals[index],
                      index,
                      double.infinity,
                      double.infinity,
                      false,
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    }
  }
  
  Widget _buildGoalCard(
    BuildContext context,
    PracticeGoal goal,
    int index,
    double cardWidth,
    double cardHeight,
    bool isLandscape,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final color = Color(int.parse('FF${goal.color}', radix: 16));
    
    return Container(
      width: cardWidth,
      height: cardHeight,
      margin: EdgeInsets.symmetric(
        horizontal: isLandscape ? 0 : screenWidth * 0.01,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openPracticeScreen(context, goal),
          borderRadius: BorderRadius.circular(16), // Reduced border radius
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.8),
                  color.withOpacity(0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16), // Reduced border radius
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8, // Reduced shadow
                  offset: const Offset(0, 4), // Reduced offset
                  spreadRadius: 1, // Reduced spread
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(isLandscape ? 10.0 : 12.0), // Reduced padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Added this
                children: [
                  // Icon and Progress Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildGoalIcon(goal, isLandscape, screenWidth),
                      _buildProgressStars(goal, isLandscape, screenWidth),
                    ],
                  ),
                  
                  SizedBox(height: isLandscape ? 6 : 8), // Reduced spacing
                  
                  // Goal Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min, // Added this
                      children: [
                        AutoSizeText(
                          goal.name,
                          style: GoogleFonts.nunito(
                            fontSize: isLandscape ? screenWidth * 0.016 : screenWidth * 0.038, // Reduced font sizes
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          minFontSize: 10, // Reduced min font
                        ),
                        
                        const SizedBox(height: 3), // Reduced spacing
                        
                        AutoSizeText(
                          goal.description,
                          style: GoogleFonts.nunito(
                            fontSize: isLandscape ? screenWidth * 0.011 : screenWidth * 0.028, // Reduced font sizes
                            color: Colors.white.withOpacity(0.9),
                          ),
                          maxLines: isLandscape ? 2 : 3,
                          minFontSize: 7, // Reduced min font
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 4), // Reduced spacing
                  
                  // Progress Bar
                  _buildProgressBar(goal, isLandscape),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildGoalIcon(PracticeGoal goal, bool isLandscape, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(isLandscape ? 6 : 8), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10), // Reduced border radius
      ),
      child: Text(
        goal.iconEmoji,
        style: TextStyle(
          fontSize: isLandscape ? screenWidth * 0.02 : screenWidth * 0.045, // Reduced font sizes
        ),
      ),
    );
  }
  
  Widget _buildProgressStars(PracticeGoal goal, bool isLandscape, double screenWidth) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          CupertinoIcons.star_fill,
          color: Colors.amber,
          size: isLandscape ? screenWidth * 0.012 : screenWidth * 0.028, // Reduced icon sizes
        ),
        const SizedBox(width: 3), // Reduced spacing
        AutoSizeText(
          '${goal.totalStars}',
          style: GoogleFonts.nunito(
            fontSize: isLandscape ? screenWidth * 0.01 : screenWidth * 0.025, // Reduced font sizes
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          maxLines: 1,
          minFontSize: 7, // Reduced min font
        ),
      ],
    );
  }
  
  Widget _buildProgressBar(PracticeGoal goal, bool isLandscape) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Added this
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AutoSizeText(
              'Progress',
              style: GoogleFonts.nunito(
                fontSize: isLandscape ? 8 : 10, // Reduced font sizes
                color: Colors.white.withOpacity(0.8),
              ),
              maxLines: 1,
              minFontSize: 6, // Reduced min font
            ),
            AutoSizeText(
              '${goal.completedActivities}/${goal.activities.length}',
              style: GoogleFonts.nunito(
                fontSize: isLandscape ? 8 : 10, // Reduced font sizes
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              minFontSize: 6, // Reduced min font
            ),
          ],
        ),
        const SizedBox(height: 3), // Reduced spacing
        ClipRRect(
          borderRadius: BorderRadius.circular(8), // Reduced border radius
          child: LinearProgressIndicator(
            value: goal.progress,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: isLandscape ? 3 : 4, // Reduced height
          ),
        ),
      ],
    );
  }
  
  void _openPracticeScreen(BuildContext context, PracticeGoal goal) async {
    // Add haptic feedback
    try {
      // Using a simple vibration pattern if available
      // You can implement proper haptic feedback here
    } catch (e) {
      // Ignore haptic feedback errors
    }
    
    // Navigate to practice screen
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PracticeScreen(goal: goal),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
    
    // Refresh goals data if needed (for progress updates)
    if (mounted) {
      setState(() {
        // Refresh goals from data source
      });
    }
  }
}
