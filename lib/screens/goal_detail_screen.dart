import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/aac_learning_goal.dart';
import '../services/goal_progress_service.dart';
import '../utils/aac_helper.dart';

class GoalDetailScreen extends StatefulWidget {
  final AACLearningGoal goal;

  const GoalDetailScreen({
    super.key,
    required this.goal,
  });

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;
  
  int _currentProgress = 0;
  bool _isCompleted = false;
  List<bool> _objectiveChecklist = [];

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _objectiveChecklist = List.filled(widget.goal.objectives.length, false);
    _loadProgress();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    try {
      final progress = await GoalProgressService.getGoalProgress(widget.goal.id);
      final objectiveProgress = await GoalProgressService.getObjectiveProgress(widget.goal.id);
      
      setState(() {
        _currentProgress = progress;
        _isCompleted = progress >= 100;
        if (objectiveProgress.isNotEmpty) {
          _objectiveChecklist = objectiveProgress;
        }
      });
    } catch (e) {
      debugPrint('Error loading goal progress: $e');
    }
  }

  Future<void> _updateObjectiveProgress(int index, bool completed) async {
    setState(() {
      _objectiveChecklist[index] = completed;
    });

    // Calculate overall progress based on completed objectives
    final completedCount = _objectiveChecklist.where((completed) => completed).length;
    final newProgress = ((completedCount / _objectiveChecklist.length) * 100).round();
    
    setState(() {
      _currentProgress = newProgress;
      _isCompleted = newProgress >= 100;
    });

    // Save progress
    await GoalProgressService.updateGoalProgress(widget.goal.id, newProgress);
    await GoalProgressService.updateObjectiveProgress(widget.goal.id, _objectiveChecklist);

    // Celebrate completion
    if (_isCompleted && completedCount == _objectiveChecklist.length) {
      await AACHelper.speak('Congratulations! Goal completed!');
      _showCompletionCelebration();
    } else if (completed) {
      await AACHelper.speak('Great job! Objective completed!');
    }
  }

  void _showCompletionCelebration() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('🎉 Goal Completed!'),
        content: Text('Congratulations! You\'ve completed "${widget.goal.title}". Keep up the great work!'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Awesome!'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _getAccentColor();
    
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: accentColor,
        middle: Text(
          widget.goal.visualCue + ' Goal Details',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(
            CupertinoIcons.back,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGoalHeader(accentColor),
                  const SizedBox(height: 24),
                  _buildProgressSection(accentColor),
                  const SizedBox(height: 24),
                  _buildObjectivesSection(accentColor),
                  const SizedBox(height: 24),
                  _buildActivitiesSection(accentColor),
                  const SizedBox(height: 24),
                  _buildExamplesSection(accentColor),
                  const SizedBox(height: 24),
                  _buildScientificBasisSection(accentColor),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getAccentColor() {
    switch (widget.goal.category) {
      case GoalCategory.expressiveLanguage:
        return const Color(0xFF10B981);
      case GoalCategory.operational:
        return const Color(0xFF3B82F6);
      case GoalCategory.socialCommunication:
        return const Color(0xFFE11D48);
    }
  }

  Widget _buildGoalHeader(Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accentColor, accentColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.goal.visualCue,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.goal.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.goal.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildDifficultyChip(),
              const SizedBox(width: 12),
              _buildDurationChip(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyChip() {
    final difficultyColors = {
      DifficultyLevel.beginner: Colors.green,
      DifficultyLevel.intermediate: Colors.orange,
      DifficultyLevel.advanced: Colors.red,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.star_fill,
            color: difficultyColors[widget.goal.difficulty],
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            widget.goal.difficulty.name.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CupertinoIcons.clock,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${widget.goal.estimatedWeeks} WEEKS',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(Color accentColor) {
    return _buildSection(
      title: 'Your Progress',
      icon: CupertinoIcons.chart_bar_fill,
      accentColor: accentColor,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: _currentProgress / 100.0,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  minHeight: 8,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$_currentProgress%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isCompleted)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(CupertinoIcons.checkmark_circle_fill, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Congratulations! This goal is completed!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildObjectivesSection(Color accentColor) {
    return _buildSection(
      title: 'Learning Objectives',
      icon: CupertinoIcons.list_bullet,
      accentColor: accentColor,
      child: Column(
        children: widget.goal.objectives.asMap().entries.map((entry) {
          final index = entry.key;
          final objective = entry.value;
          final isChecked = _objectiveChecklist[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _updateObjectiveProgress(index, !isChecked),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isChecked ? accentColor.withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isChecked ? accentColor : Colors.grey.withOpacity(0.3),
                    width: isChecked ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isChecked ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                      color: isChecked ? accentColor : Colors.grey[400],
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        objective,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isChecked ? accentColor : const Color(0xFF374151),
                          decoration: isChecked ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActivitiesSection(Color accentColor) {
    return _buildSection(
      title: 'Practice Activities',
      icon: CupertinoIcons.game_controller_solid,
      accentColor: accentColor,
      child: Column(
        children: widget.goal.activities.map((activity) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    activity,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF374151),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExamplesSection(Color accentColor) {
    return _buildSection(
      title: 'Real Examples',
      icon: CupertinoIcons.chat_bubble_text_fill,
      accentColor: accentColor,
      child: Column(
        children: widget.goal.examples.map((example) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _speakExample(example),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.speaker_2_fill,
                      color: accentColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        example,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: accentColor,
                          height: 1.3,
                        ),
                      ),
                    ),
                    Icon(
                      CupertinoIcons.play_circle,
                      color: accentColor.withOpacity(0.6),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildScientificBasisSection(Color accentColor) {
    return _buildSection(
      title: 'Scientific Foundation',
      icon: CupertinoIcons.book_fill,
      accentColor: accentColor,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  CupertinoIcons.lab_flask_solid,
                  color: Colors.blue,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Research Evidence',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.goal.scientificBasis,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF374151),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color accentColor,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: accentColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  Future<void> _speakExample(String example) async {
    await AACHelper.speak(example);
  }
}
