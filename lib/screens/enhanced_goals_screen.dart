import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/goal.dart';
import '../models/enhanced_goal.dart';
import '../services/goal_service.dart';
import '../services/arasaac_service.dart';
import '../widgets/goal_card.dart';
import '../widgets/goal_mascot.dart';
import '../utils/aac_helper.dart';
import 'add_goal_screen.dart';
import 'goal_practice_screen.dart';

class EnhancedGoalsScreen extends StatefulWidget {
  const EnhancedGoalsScreen({super.key});

  @override
  State<EnhancedGoalsScreen> createState() => _EnhancedGoalsScreenState();
}

class _EnhancedGoalsScreenState extends State<EnhancedGoalsScreen>
    with TickerProviderStateMixin {
  List<EnhancedGoal> _enhancedGoals = [];
  List<EnhancedGoal> _activeGoals = [];
  List<EnhancedGoal> _completedGoals = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _currentView = 'active'; // 'active', 'completed', 'all'
  
  late AnimationController _viewSwitchController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadGoals();
    _createSampleGoalsIfNeeded();
  }

  void _setupAnimations() {
    _viewSwitchController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _viewSwitchController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _viewSwitchController.dispose();
    super.dispose();
  }

  Future<void> _createSampleGoalsIfNeeded() async {
    try {
      final existingGoals = await GoalService.getUserGoals();
      if (existingGoals.isEmpty) {
        // Create sample goals with ARASAAC pictograms
        final sampleGoals = await _createEnhancedSampleGoals();
        
        // Save sample goals
        for (final goal in sampleGoals) {
          await GoalService.saveGoal(goal.toGoal());
        }
        
        debugPrint('Created ${sampleGoals.length} enhanced sample goals');
        _loadGoals(); // Reload to show new goals
      }
    } catch (e) {
      debugPrint('Error creating sample goals: $e');
    }
  }

  Future<List<EnhancedGoal>> _createEnhancedSampleGoals() async {
    final goals = <EnhancedGoal>[];

    // Communication goals
    goals.add(EnhancedGoal(
      id: 'sample_comm_1',
      title: 'Say "Please" and "Thank you"',
      description: 'Practice using polite words when asking for things',
      targetDate: DateTime.now().add(const Duration(days: 7)),
      category: GoalCategory.communication,
      frequency: GoalFrequency.weekly,
      priority: 3,
      createdAt: DateTime.now(),
      isCompleted: false,
      targetValue: 5,
      currentProgress: 1,
      arasaacPictogramId: await ArasaacService.getPictogramForGoalTitle('please thank you'),
    ));

    goals.add(EnhancedGoal(
      id: 'sample_comm_2',
      title: 'Express one feeling each day',
      description: 'Use words to express emotions like happy, sad, or excited',
      targetDate: DateTime.now().add(const Duration(days: 14)),
      category: GoalCategory.emotional,
      frequency: GoalFrequency.weekly,
      priority: 4,
      createdAt: DateTime.now(),
      isCompleted: false,
      targetValue: 7,
      currentProgress: 3,
      arasaacPictogramId: await ArasaacService.getPictogramForGoalTitle('feelings emotion'),
    ));

    // Social goals
    goals.add(EnhancedGoal(
      id: 'sample_social_1',
      title: 'Ask for help when needed',
      description: 'Practice saying "I need help" when something is difficult',
      targetDate: DateTime.now().add(const Duration(days: 10)),
      category: GoalCategory.social,
      frequency: GoalFrequency.weekly,
      priority: 3,
      createdAt: DateTime.now(),
      isCompleted: false,
      targetValue: 3,
      currentProgress: 0,
      arasaacPictogramId: await ArasaacService.getPictogramForGoalTitle('help'),
    ));

    goals.add(EnhancedGoal(
      id: 'sample_social_2',
      title: 'Share with friends',
      description: 'Practice sharing toys or snacks with friends',
      targetDate: DateTime.now().add(const Duration(days: 21)),
      category: GoalCategory.social,
      frequency: GoalFrequency.monthly,
      priority: 2,
      createdAt: DateTime.now(),
      isCompleted: false,
      targetValue: 10,
      currentProgress: 6,
      arasaacPictogramId: await ArasaacService.getPictogramForGoalTitle('share friends'),
    ));

    // Learning goals
    goals.add(EnhancedGoal(
      id: 'sample_learn_1',
      title: 'Learn 5 new words this week',
      description: 'Practice using AAC symbols to learn new vocabulary',
      targetDate: DateTime.now().add(const Duration(days: 7)),
      category: GoalCategory.learning,
      frequency: GoalFrequency.weekly,
      priority: 5,
      createdAt: DateTime.now(),
      isCompleted: true,
      completedAt: DateTime.now().subtract(const Duration(days: 1)),
      targetValue: 5,
      currentProgress: 5,
      arasaacPictogramId: await ArasaacService.getPictogramForGoalTitle('learn words'),
    ));

    // Daily living goals
    goals.add(EnhancedGoal(
      id: 'sample_daily_1',
      title: 'Use AAC app during meals',
      description: 'Communicate wants and needs during breakfast, lunch, and dinner',
      targetDate: DateTime.now().add(const Duration(days: 14)),
      category: GoalCategory.dailyLiving,
      frequency: GoalFrequency.weekly,
      priority: 4,
      createdAt: DateTime.now(),
      isCompleted: false,
      targetValue: 21, // 3 meals x 7 days
      currentProgress: 12,
      arasaacPictogramId: await ArasaacService.getPictogramForGoalTitle('meal food'),
    ));

    return goals;
  }

  Future<void> _loadGoals() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final goals = await GoalService.getUserGoals();
      final enhancedGoals = <EnhancedGoal>[];

      for (final goal in goals) {
        // Try to get ARASAAC pictogram if not already set
        int? pictogramId;
        try {
          pictogramId = await ArasaacService.getPictogramForGoalTitle(goal.title);
        } catch (e) {
          // Use category fallback
          pictogramId = await ArasaacService.getPictogramForGoalCategory(goal.category.name);
        }

        enhancedGoals.add(EnhancedGoal.fromGoal(goal, arasaacId: pictogramId));
      }

      setState(() {
        _enhancedGoals = enhancedGoals;
        _activeGoals = enhancedGoals.where((goal) => !goal.isCompleted).toList();
        _completedGoals = enhancedGoals.where((goal) => goal.isCompleted).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load goals: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<EnhancedGoal> get _currentGoals {
    switch (_currentView) {
      case 'active':
        return _activeGoals;
      case 'completed':
        return _completedGoals;
      case 'all':
        return _enhancedGoals;
      default:
        return _activeGoals;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: _buildNavigationBar(),
      child: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : _errorMessage != null
                ? _buildErrorState()
                : _buildMainContent(),
      ),
    );
  }

  CupertinoNavigationBar _buildNavigationBar() {
    return CupertinoNavigationBar(
      middle: const Text(
        '🎯 My Goals',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: CupertinoColors.systemBackground.withOpacity(0.8),
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        child: const Icon(CupertinoIcons.add_circled_solid),
        onPressed: _addNewGoal,
      ),
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        child: const Icon(CupertinoIcons.back),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CupertinoActivityIndicator(radius: 20),
          SizedBox(height: 16),
          Text(
            'Loading your amazing goals...',
            style: TextStyle(
              fontSize: 16,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('😕', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.systemRed.darkColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: const TextStyle(
              fontSize: 14,
              color: CupertinoColors.systemGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CupertinoButton.filled(
            child: const Text('Try Again'),
            onPressed: _loadGoals,
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildMascotSection(),
        _buildViewSelector(),
        Expanded(
          child: AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return _buildGoalsList();
            },
          ),
        ),
        _buildArasaacAttribution(),
      ],
    );
  }

  Widget _buildMascotSection() {
    final currentGoal = _activeGoals.isNotEmpty ? _activeGoals.first : null;
    
    return GoalMascot(
      currentGoal: currentGoal,
      allGoals: _enhancedGoals,
      onTap: () {
        // Animate to first active goal if exists
        if (currentGoal != null) {
          _handleGoalTap(currentGoal);
        }
      },
    );
  }

  Widget _buildViewSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(15),
      ),
      child: CupertinoSlidingSegmentedControl<String>(
        groupValue: _currentView,
        children: {
          'active': _buildSegmentChild('🎯 Active', _activeGoals.length),
          'completed': _buildSegmentChild('✅ Done', _completedGoals.length),
          'all': _buildSegmentChild('📋 All', _enhancedGoals.length),
        },
        onValueChanged: (value) {
          if (value != null) {
            setState(() {
              _currentView = value;
            });
            _viewSwitchController.forward().then((_) {
              _viewSwitchController.reset();
            });
          }
        },
      ),
    );
  }

  Widget _buildSegmentChild(String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              color: CupertinoColors.systemGrey.darkColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsList() {
    final goals = _currentGoals;

    if (goals.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: goals.length,
      itemBuilder: (context, index) {
        final goal = goals[index];
        return GoalCard(
          goal: goal,
          onTap: () => _handleGoalTap(goal),
          onEdit: () => _editGoal(goal),
          onPractice: () => _startPracticeSession(goal),
          onProgressUpdate: (progress) => _updateProgress(goal, progress),
          showMascot: index == 0 && _currentView == 'active',
        );
      },
    );
  }

  Widget _buildEmptyState() {
    String emoji;
    String title;
    String subtitle;

    switch (_currentView) {
      case 'active':
        emoji = '🎯';
        title = 'No active goals yet!';
        subtitle = 'Tap the + button to create your first goal and start your journey!';
        break;
      case 'completed':
        emoji = '🏆';
        title = 'No completed goals yet!';
        subtitle = 'Keep working on your active goals to see them here!';
        break;
      default:
        emoji = '📝';
        title = 'No goals created yet!';
        subtitle = 'Start by creating your first goal!';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 80)),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: CupertinoColors.label,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: CupertinoColors.systemGrey.darkColor,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (_currentView == 'active' || _currentView == 'all') ...[
              const SizedBox(height: 32),
              CupertinoButton.filled(
                child: const Text('Create My First Goal'),
                onPressed: _addNewGoal,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildArasaacAttribution() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.info_circle,
            size: 16,
            color: CupertinoColors.systemGrey.darkColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              ArasaacService.attributionText,
              style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemGrey.darkColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _handleGoalTap(EnhancedGoal goal) async {
    await AACHelper.speak('Goal: ${goal.title}. ${goal.mascotEncouragement}');
    
    // Show goal details or progress update dialog
    _showGoalDetails(goal);
  }

  void _showGoalDetails(EnhancedGoal goal) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(goal.title),
        content: Column(
          children: [
            const SizedBox(height: 16),
            Text(goal.description),
            const SizedBox(height: 16),
            Text(
              'Progress: ${goal.currentProgress}/${goal.targetValue} (${goal.progressPercentage}%)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(goal.mascotEncouragement),
          ],
        ),
        actions: [
          if (!goal.isCompleted)
            CupertinoDialogAction(
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.play_circle, size: 16),
                  SizedBox(width: 4),
                  Text('Practice'),
                ],
              ),
              onPressed: () {
                Navigator.pop(context);
                _startPracticeSession(goal);
              },
            ),
          if (!goal.isCompleted)
            CupertinoDialogAction(
              child: const Text('Update Progress'),
              onPressed: () {
                Navigator.pop(context);
                _showProgressUpdateDialog(goal);
              },
            ),
          CupertinoDialogAction(
            child: const Text('Edit'),
            onPressed: () {
              Navigator.pop(context);
              _editGoal(goal);
            },
          ),
          CupertinoDialogAction(
            child: const Text('Close'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showProgressUpdateDialog(EnhancedGoal goal) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Update Progress'),
        content: Column(
          children: [
            const SizedBox(height: 16),
            Text('Current: ${goal.currentProgress}/${goal.targetValue}'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CupertinoButton(
                  child: const Text('📈 +1'),
                  onPressed: () {
                    Navigator.pop(context);
                    _updateProgress(goal, goal.currentProgress + 1);
                  },
                ),
                CupertinoButton(
                  child: const Text('🎯 Complete'),
                  onPressed: () {
                    Navigator.pop(context);
                    _updateProgress(goal, goal.targetValue);
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _updateProgress(EnhancedGoal goal, int newProgress) async {
    try {
      final wasCompleted = goal.isCompleted;
      final clampedProgress = newProgress.clamp(0, goal.targetValue);
      final isNowCompleted = clampedProgress >= goal.targetValue;

      final updatedGoal = goal.copyWith(
        currentProgress: clampedProgress,
        isCompleted: isNowCompleted,
        completedAt: isNowCompleted && !wasCompleted ? DateTime.now() : goal.completedAt,
      );

      await GoalService.saveGoal(updatedGoal.toGoal());

      // Show celebration if just completed
      if (isNowCompleted && !wasCompleted) {
        await AACHelper.speak('🎉 Congratulations! You completed ${goal.title}! You are amazing!');
      }

      _loadGoals(); // Refresh the list
    } catch (e) {
      debugPrint('Error updating progress: $e');
    }
  }

  void _addNewGoal() async {
    final result = await Navigator.push<Goal>(
      context,
      CupertinoPageRoute(
        builder: (context) => const AddGoalScreen(),
      ),
    );

    if (result != null) {
      _loadGoals();
    }
  }

  void _editGoal(EnhancedGoal goal) async {
    final result = await Navigator.push<Goal>(
      context,
      CupertinoPageRoute(
        builder: (context) => AddGoalScreen(goal: goal.toGoal()),
      ),
    );

    if (result != null) {
      _loadGoals();
    }
  }

  void _startPracticeSession(EnhancedGoal goal) async {
    final practiceProgress = await Navigator.push<int>(
      context,
      CupertinoPageRoute(
        builder: (context) => GoalPracticeScreen(goal: goal),
      ),
    );

    // Update goal progress if practice session returned progress
    if (practiceProgress != null && practiceProgress > 0) {
      final newProgress = goal.currentProgress + practiceProgress;
      _updateProgress(goal, newProgress);
    }
  }
}
