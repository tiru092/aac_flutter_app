import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/practice_goal.dart';
// import 'practice_screen.dart';

class GoalsSectionFixed extends StatefulWidget {
  const GoalsSectionFixed({super.key});

  @override
  State<GoalsSectionFixed> createState() => _GoalsSectionFixedState();
}

class _GoalsSectionFixedState extends State<GoalsSectionFixed>
    with TickerProviderStateMixin {
  late AnimationController _cardAnimationController;
  late List<AnimationController> _cardControllers;
  late List<Animation<double>> _cardAnimations;
  final List<PracticeGoal> goals = PracticeGoalsData.getAllGoals();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Goals Section - Fixed Version',
            style: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Text('Found ${goals.length} goals'),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _cardControllers = [];
    _cardAnimations = [];
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
