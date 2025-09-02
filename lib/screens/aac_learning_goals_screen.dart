import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/aac_learning_goal.dart';
import '../services/goal_progress_service.dart';
import '../utils/aac_helper.dart';
import 'goal_detail_screen.dart';

class AACLearningGoalsScreen extends StatefulWidget {
  const AACLearningGoalsScreen({super.key});

  @override
  State<AACLearningGoalsScreen> createState() => _AACLearningGoalsScreenState();
}

class _AACLearningGoalsScreenState extends State<AACLearningGoalsScreen> 
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late Animation<Offset> _headerSlideAnimation;
  Map<String, bool> _completedGoals = {};
  Map<String, int> _goalProgress = {};

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _loadGoalProgress();
    _headerAnimationController.forward();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadGoalProgress() async {
    try {
      final progress = await GoalProgressService.getAllGoalProgress();
      setState(() {
        _goalProgress = progress;
        _completedGoals = progress.map((key, value) => MapEntry(key, value >= 100));
      });
    } catch (e) {
      debugPrint('Error loading goal progress: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFF6366F1),
        middle: const Text(
          '🎯 AAC Learning Goals',
          style: TextStyle(
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildExpressiveLanguageGoals(),
              const SizedBox(height: 24),
              _buildOperationalGoals(),
              const SizedBox(height: 24),
              _buildSocialCommunicationGoals(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SlideTransition(
      position: _headerSlideAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  CupertinoIcons.star_fill,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Scientifically Backed AAC Goals',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Evidence-based learning objectives designed specifically for children with ASD to develop meaningful communication skills.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildProgressIndicator(),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Track your progress and celebrate achievements!',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final totalGoals = AACLearningGoalData.getAllGoals().length;
    final completedCount = _completedGoals.values.where((completed) => completed).length;
    final progress = totalGoals > 0 ? completedCount / totalGoals : 0.0;

    return Container(
      width: 60,
      height: 60,
      child: Stack(
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 4,
            backgroundColor: Colors.white30,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          Center(
            child: Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpressiveLanguageGoals() {
    final goals = AACLearningGoalData.getExpressiveLanguageGoals();
    return _buildGoalSection(
      '🗣️ Expressive Language Goals',
      'Help children use AAC to express themselves meaningfully',
      goals,
      const Color(0xFF10B981),
    );
  }

  Widget _buildOperationalGoals() {
    final goals = AACLearningGoalData.getOperationalGoals();
    return _buildGoalSection(
      '⚙️ Operational Goals',
      'Master the technical skills needed to use AAC effectively',
      goals,
      const Color(0xFF3B82F6),
    );
  }

  Widget _buildSocialCommunicationGoals() {
    final goals = AACLearningGoalData.getSocialCommunicationGoals();
    return _buildGoalSection(
      '👥 Social Communication Goals',
      'Develop social interaction and pragmatic communication skills',
      goals,
      const Color(0xFFE11D48),
    );
  }

  Widget _buildGoalSection(String title, String description, List<AACLearningGoal> goals, Color accentColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: accentColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...goals.map((goal) => _buildGoalCard(goal, accentColor)).toList(),
        ],
      ),
    );
  }

  Widget _buildGoalCard(AACLearningGoal goal, Color accentColor) {
    final isCompleted = _completedGoals[goal.id] ?? false;
    final progress = _goalProgress[goal.id] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _navigateToGoalDetail(goal),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isCompleted ? accentColor.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCompleted ? accentColor : Colors.grey.withOpacity(0.3),
              width: isCompleted ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCompleted ? accentColor : accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  isCompleted ? CupertinoIcons.checkmark : CupertinoIcons.circle,
                  color: isCompleted ? Colors.white : accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isCompleted ? accentColor : const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      goal.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: progress / 100.0,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$progress%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                CupertinoIcons.chevron_right,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToGoalDetail(AACLearningGoal goal) async {
    await AACHelper.speak('Opening ${goal.title}');
    
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => GoalDetailScreen(goal: goal),
      ),
    ).then((_) {
      // Reload progress when returning from detail screen
      _loadGoalProgress();
    });
  }
}
