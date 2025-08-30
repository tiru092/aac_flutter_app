import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/practice_goal.dart';
import 'practice_screen.dart';

class GoalsSection extends StatelessWidget {
  const GoalsSection({super.key});

  static final List<PracticeGoal> goals = PracticeGoalsData.getAllGoals();

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: isLandscape ? screenSize.height * 0.7 : screenSize.height * 0.6,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: screenSize.width * 0.03,
        vertical: screenSize.height * 0.01,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context, isLandscape, screenSize),
          SizedBox(height: screenSize.height * 0.01),
          Expanded(
            child: _buildGoalsGrid(context, isLandscape, screenSize),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isLandscape, Size screenSize) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.02),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isLandscape ? 4 : 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366f1).withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              CupertinoIcons.star_circle_fill,
              color: Colors.white,
              size: isLandscape ? 14 : 16,
            ),
          ),
          SizedBox(width: screenSize.width * 0.02),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AutoSizeText(
                  'Practice Goals',
                  style: GoogleFonts.nunito(
                    fontSize: isLandscape ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1f2937),
                  ),
                  maxLines: 1,
                  minFontSize: 12,
                ),
                AutoSizeText(
                  'Fun activities to improve communication',
                  style: GoogleFonts.nunito(
                    fontSize: isLandscape ? 10 : 12,
                    color: const Color(0xFF6b7280),
                  ),
                  maxLines: 1,
                  minFontSize: 8,
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
    final childAspectRatio = isLandscape ? 1.2 : 1.0;
    
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.01),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: screenSize.width * 0.02,
        mainAxisSpacing: screenSize.height * 0.01,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: goals.length,
      itemBuilder: (context, index) {
        return _buildGoalCard(context, goals[index], isLandscape, screenSize);
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.8),
                color.withOpacity(0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(isLandscape ? 8.0 : 10.0),
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
                SizedBox(height: isLandscape ? 4 : 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AutoSizeText(
                        goal.name,
                        style: GoogleFonts.nunito(
                          fontSize: isLandscape ? 12 : 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        minFontSize: 8,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isLandscape ? 2 : 3),
                      AutoSizeText(
                        goal.description,
                        style: GoogleFonts.nunito(
                          fontSize: isLandscape ? 9 : 10,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        maxLines: isLandscape ? 2 : 3,
                        minFontSize: 6,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isLandscape ? 2 : 4),
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
      padding: EdgeInsets.all(isLandscape ? 4 : 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        goal.iconEmoji,
        style: TextStyle(
          fontSize: isLandscape ? 14 : 16,
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
          size: isLandscape ? 10 : 12,
        ),
        const SizedBox(width: 2),
        AutoSizeText(
          '${goal.totalStars}',
          style: GoogleFonts.nunito(
            fontSize: isLandscape ? 8 : 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          maxLines: 1,
          minFontSize: 6,
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
                fontSize: isLandscape ? 7 : 8,
                color: Colors.white.withOpacity(0.8),
              ),
              maxLines: 1,
              minFontSize: 6,
            ),
            AutoSizeText(
              '${goal.completedActivities}/${goal.activities.length}',
              style: GoogleFonts.nunito(
                fontSize: isLandscape ? 7 : 8,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              minFontSize: 6,
            ),
          ],
        ),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: goal.progress,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: isLandscape ? 2 : 3,
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
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }
}
