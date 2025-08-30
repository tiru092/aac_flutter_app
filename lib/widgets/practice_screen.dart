import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/goal_models.dart';

class PracticeScreen extends StatefulWidget {
  final Goal goal;
  
  const PracticeScreen({
    super.key,
    required this.goal,
  });

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _cardAnimations;
  late Animation<double> _headerAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _cardAnimations = List.generate(
      widget.goal.practices.length,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            0.2 + (index * 0.1).clamp(0.0, 0.8),
            0.5 + (index * 0.1).clamp(0.0, 1.0),
            curve: Curves.elasticOut,
          ),
        ),
      ),
    );
  }

  void _startAnimations() {
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Color(widget.goal.colorValue).withOpacity(0.9),
        middle: Text(
          widget.goal.name,
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(
            CupertinoIcons.back,
            color: Colors.white,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(widget.goal.colorValue).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isLandscape = constraints.maxWidth > constraints.maxHeight;
              final crossAxisCount = isLandscape ? 4 : 2;
              final aspectRatio = isLandscape ? 1.2 : 1.0;

              return Column(
                children: [
                  // Header Section
                  AnimatedBuilder(
                    animation: _headerAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, -30 * (1 - _headerAnimation.value)),
                        child: Opacity(
                          opacity: _headerAnimation.value,
                          child: Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(widget.goal.colorValue).withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  widget.goal.iconEmoji,
                                  style: const TextStyle(fontSize: 48),
                                ),
                                const SizedBox(height: 12),
                                AutoSizeText(
                                  widget.goal.name,
                                  style: GoogleFonts.nunito(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Color(widget.goal.colorValue),
                                  ),
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 8),
                                AutoSizeText(
                                  widget.goal.description,
                                  style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildStatItem(
                                      'Practices',
                                      widget.goal.practices.length.toString(),
                                      CupertinoIcons.gamecontroller,
                                    ),
                                    _buildStatItem(
                                      'Completed',
                                      widget.goal.completedPractices.toString(),
                                      CupertinoIcons.checkmark_circle_fill,
                                    ),
                                    _buildStatItem(
                                      'Stars',
                                      widget.goal.totalStars.toString(),
                                      CupertinoIcons.star_fill,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Practices Grid
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: aspectRatio,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: widget.goal.practices.length,
                      itemBuilder: (context, index) {
                        return AnimatedBuilder(
                          animation: _cardAnimations[index],
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _cardAnimations[index].value,
                              child: Opacity(
                                opacity: _cardAnimations[index].value,
                                child: _buildPracticeCard(
                                  widget.goal.practices[index],
                                  index,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Color(widget.goal.colorValue),
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(widget.goal.colorValue),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPracticeCard(Practice practice, int index) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _startPractice(practice),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Color(widget.goal.colorValue).withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(widget.goal.colorValue).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Color(widget.goal.colorValue).withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                _getPracticeIcon(practice.type),
                color: Color(widget.goal.colorValue),
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            AutoSizeText(
              practice.name,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
            const SizedBox(height: 4),
            AutoSizeText(
              practice.description,
              style: GoogleFonts.nunito(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPracticeIcon(String type) {
    switch (type) {
      case 'matching':
        return CupertinoIcons.square_grid_3x2;
      case 'selection':
        return CupertinoIcons.hand_point_left;
      case 'counting':
        return CupertinoIcons.number;
      case 'listening':
        return CupertinoIcons.ear;
      case 'drawing':
        return CupertinoIcons.pencil;
      case 'memory':
        return CupertinoIcons.memories;
      case 'puzzle':
        return CupertinoIcons.game_controller;
      case 'sorting':
        return CupertinoIcons.sort_down;
      case 'quiz':
        return CupertinoIcons.question_circle;
      default:
        return CupertinoIcons.play;
    }
  }

  void _startPractice(Practice practice) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(practice.name),
        content: Text('Starting practice: ${practice.description}'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Start'),
            onPressed: () {
              Navigator.of(context).pop();
              // Here you would navigate to the actual practice activity
              // For now, just show a success message
              _showPracticeDemo(practice);
            },
          ),
        ],
      ),
    );
  }

  void _showPracticeDemo(Practice practice) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Practice Demo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Practice: ${practice.name}'),
            const SizedBox(height: 8),
            Text('Type: ${practice.type}'),
            const SizedBox(height: 8),
            const Text('This would open the actual practice activity.'),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
