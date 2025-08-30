import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/practice_goal.dart';

class PracticeGoalsScreenWorking extends StatefulWidget {
  const PracticeGoalsScreenWorking({super.key});

  @override
  State<PracticeGoalsScreenWorking> createState() => _PracticeGoalsScreenWorkingState();
}

class _PracticeGoalsScreenWorkingState extends State<PracticeGoalsScreenWorking> with TickerProviderStateMixin {
  late AnimationController _cardAnimationController;
  late List<AnimationController> _cardControllers;
  late List<Animation<double>> _cardAnimations;
  final List<PracticeGoal> goals = PracticeGoalsData.getAllGoals();

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Create individual controllers for each card
    _cardControllers = List.generate(goals.length, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 600 + (index * 50)),
        vsync: this,
      );
    });
    
    // Create animations for each card
    _cardAnimations = _cardControllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutBack,
      ));
    }).toList();

    // Start animations with staggered timing
    _startStaggeredAnimations();
  }

  void _startStaggeredAnimations() {
    for (int i = 0; i < _cardControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 120), () {
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
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              CupertinoIcons.back,
              color: Color(0xFF2D4356),
              size: 24,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          centerTitle: true,
          title: const Text(
            'Practice Goals',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D4356),
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildGoalsSection(context),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalsSection(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, isLandscape, screenSize),
          SizedBox(height: screenSize.height * 0.02),
          isLandscape 
              ? _buildLandscapeGrid(context, screenSize)
              : _buildPortraitGrid(context, screenSize),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, bool isLandscape, Size screenSize) {
    final double headerFontSize = isLandscape 
        ? screenSize.width * 0.032 
        : screenSize.width * 0.058;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: screenSize.width * 0.02,
        vertical: screenSize.height * 0.015,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(screenSize.width * 0.025),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              CupertinoIcons.star_circle_fill,
              color: Colors.white,
              size: isLandscape ? screenSize.width * 0.025 : screenSize.width * 0.045,
            ),
          ),
          SizedBox(width: screenSize.width * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  'Practice Goals',
                  style: GoogleFonts.nunito(
                    fontSize: headerFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  minFontSize: 16,
                ),
                AutoSizeText(
                  'Fun activities to improve communication',
                  style: GoogleFonts.nunito(
                    fontSize: headerFontSize * 0.6,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  maxLines: 1,
                  minFontSize: 10,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitGrid(BuildContext context, Size screenSize) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
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
                false,
                BoxConstraints(
                  maxWidth: screenSize.width * 0.4,
                  maxHeight: screenSize.height * 0.25,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLandscapeGrid(BuildContext context, Size screenSize) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 1.0,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
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
                true,
                BoxConstraints(
                  maxWidth: screenSize.width * 0.18,
                  maxHeight: screenSize.height * 0.45,
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
    int index,
    bool isLandscape,
    BoxConstraints constraints,
  ) {
    return GestureDetector(
      onTap: () => _navigateToPracticeScreen(context, goal),
      child: Container(
        constraints: constraints,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildCardHeader(goal, isLandscape, constraints),
            _buildCardContent(goal, isLandscape, constraints),
            _buildCardFooter(goal, isLandscape, constraints),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(PracticeGoal goal, bool isLandscape, BoxConstraints constraints) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isLandscape ? 8 : 12),
      decoration: BoxDecoration(
        color: Color(int.parse('FF\${goal.color}', radix: 16)),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          Text(
            goal.iconEmoji,
            style: TextStyle(fontSize: isLandscape ? 20 : 28),
          ),
          const SizedBox(height: 4),
          AutoSizeText(
            goal.name,
            style: GoogleFonts.nunito(
              fontSize: isLandscape ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            minFontSize: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildCardContent(PracticeGoal goal, bool isLandscape, BoxConstraints constraints) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(isLandscape ? 6 : 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AutoSizeText(
              goal.description,
              style: GoogleFonts.nunito(
                fontSize: isLandscape ? 9 : 11,
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
              maxLines: isLandscape ? 2 : 3,
              minFontSize: 7,
            ),
            SizedBox(height: isLandscape ? 4 : 6),
            Text(
              '\${goal.activities.length} activities',
              style: GoogleFonts.nunito(
                fontSize: isLandscape ? 8 : 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardFooter(PracticeGoal goal, bool isLandscape, BoxConstraints constraints) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isLandscape ? 6 : 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.play_circle_fill,
            color: Color(int.parse('FF\${goal.color}', radix: 16)),
            size: isLandscape ? 14 : 16,
          ),
          const SizedBox(width: 4),
          AutoSizeText(
            'Start',
            style: GoogleFonts.nunito(
              fontSize: isLandscape ? 9 : 11,
              fontWeight: FontWeight.w600,
              color: Color(int.parse('FF\${goal.color}', radix: 16)),
            ),
            maxLines: 1,
            minFontSize: 7,
          ),
        ],
      ),
    );
  }

  void _navigateToPracticeScreen(BuildContext context, PracticeGoal goal) async {
    // Temporarily disabled navigation to fix import issue
    // TODO: Re-enable when PracticeScreen import is fixed
    print('Goal tapped: \${goal.name}');
    
    // Show a simple dialog for now
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(goal.name),
        content: Text('This will navigate to practice activities for \${goal.name}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
