import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../services/goal_service.dart';
import '../utils/aac_helper.dart';
// ...existing imports...
import 'add_goal_screen.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  List<Goal> _goals = [];
  List<Goal> _activeGoals = [];
  List<Goal> _completedGoals = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _currentView = 'active'; // 'active', 'completed', 'all'

  @override
  void initState() {
    super.initState();
    _loadGoals();
    _createSampleGoalsIfNeeded();
  }

  Future<void> _createSampleGoalsIfNeeded() async {
    try {
      final existingGoals = await GoalService.getUserGoals();
      if (existingGoals.isEmpty) {
        // Create sample goals for kids to explore
        final sampleGoals = [
          Goal(
            id: 'sample_1',
            title: 'Say "Please" and "Thank you"',
            description: 'Practice using polite words when asking for things',
            targetDate: DateTime.now().add(const Duration(days: 7)),
            category: GoalCategory.communication,
            frequency: GoalFrequency.weekly,
            priority: 3,
            createdAt: DateTime.now(),
            isCompleted: false,
          ),
          Goal(
            id: 'sample_2', 
            title: 'Tell someone how I feel',
            description: 'Use words to express emotions like happy, sad, or excited',
            targetDate: DateTime.now().add(const Duration(days: 14)),
            category: GoalCategory.communication,
            frequency: GoalFrequency.biweekly,
            priority: 4,
            createdAt: DateTime.now(),
            isCompleted: false,
          ),
          Goal(
            id: 'sample_3',
            title: 'Ask for help when I need it',
            description: 'Practice saying "I need help" when something is difficult',
            targetDate: DateTime.now().add(const Duration(days: 10)),
            category: GoalCategory.social,
            frequency: GoalFrequency.weekly,
            priority: 3,
            createdAt: DateTime.now(),
            isCompleted: false,
          ),
          Goal(
            id: 'sample_4',
            title: 'Share with friends',
            description: 'Practice sharing toys or snacks with friends',
            targetDate: DateTime.now().add(const Duration(days: 21)),
            category: GoalCategory.social,
            frequency: GoalFrequency.monthly,
            priority: 2,
            createdAt: DateTime.now(),
            isCompleted: false,
          ),
          Goal(
            id: 'sample_5',
            title: 'Use AAC app every day',
            description: 'Practice using communication symbols daily',
            targetDate: DateTime.now().add(const Duration(days: 30)),
            category: GoalCategory.communication,
            frequency: GoalFrequency.weekly,
            priority: 5,
            createdAt: DateTime.now(),
            isCompleted: false,
          ),
          // AAC-specific activities for kids
          Goal(
            id: 'sample_color_matching',
            title: 'Match Colors',
            description: 'Match objects by color such as red, blue, and yellow',
            targetDate: DateTime.now().add(const Duration(days: 7)),
            category: GoalCategory.learning,
            frequency: GoalFrequency.weekly,
            priority: 4,
            createdAt: DateTime.now(),
            isCompleted: false,
          ),
          Goal(
            id: 'sample_cards_matching',
            title: 'Match Picture Cards',
            description: 'Match pairs of picture cards based on similarity',
            targetDate: DateTime.now().add(const Duration(days: 10)),
            category: GoalCategory.learning,
            frequency: GoalFrequency.weekly,
            priority: 3,
            createdAt: DateTime.now(),
            isCompleted: false,
          ),
          Goal(
            id: 'sample_object_tracking',
            title: 'Track Moving Objects',
            description: 'Follow and point to moving objects',
            targetDate: DateTime.now().add(const Duration(days: 8)),
            category: GoalCategory.learning,
            frequency: GoalFrequency.weekly,
            priority: 4,
            createdAt: DateTime.now(),
            isCompleted: false,
          ),
          Goal(
            id: 'sample_shapes_recognition',
            title: 'Recognize Basic Shapes',
            description: 'Identify shapes like circle, square, and triangle',
            targetDate: DateTime.now().add(const Duration(days: 14)),
            category: GoalCategory.learning,
            frequency: GoalFrequency.biweekly,
            priority: 3,
            createdAt: DateTime.now(),
            isCompleted: false,
          ),
          Goal(
            id: 'sample_count_objects',
            title: 'Count Objects Up to 5',
            description: 'Use AAC symbols to count objects up to five',
            targetDate: DateTime.now().add(const Duration(days: 7)),
            category: GoalCategory.learning,
            frequency: GoalFrequency.weekly,
            priority: 4,
            createdAt: DateTime.now(),
            isCompleted: false,
          ),
          // Additional AAC-focused activities
          Goal(
            id: 'sample_symbol_matching',
            title: 'Match Symbols to Objects',
            description: 'Match AAC symbols to real objects or pictures',
            targetDate: DateTime.now().add(const Duration(days: 10)),
            category: GoalCategory.learning,
            frequency: GoalFrequency.weekly,
            priority: 4,
            createdAt: DateTime.now(),
            isCompleted: false,
          ),
          Goal(
            id: 'sample_sequence_tasks',
            title: 'Sequence Daily Tasks',
            description: 'Arrange pictogram cards in the correct order to show a routine',
            targetDate: DateTime.now().add(const Duration(days: 14)),
            category: GoalCategory.learning,
            frequency: GoalFrequency.biweekly,
            priority: 3,
            createdAt: DateTime.now(),
            isCompleted: false,
          ),
          Goal(
            id: 'sample_emotion_recognition',
            title: 'Recognize Emotions',
            description: 'Identify emotions like happy, sad, angry using pictograms',
            targetDate: DateTime.now().add(const Duration(days: 7)),
            category: GoalCategory.learning,
            frequency: GoalFrequency.weekly,
            priority: 3,
            createdAt: DateTime.now(),
            isCompleted: false,
          ),
          Goal(
            id: 'sample_sentence_construction',
            title: 'Construct Simple Sentences',
            description: 'Use AAC symbols to form simple sentences like "I want apple"',
            targetDate: DateTime.now().add(const Duration(days: 21)),
            category: GoalCategory.communication,
            frequency: GoalFrequency.weekly,
            priority: 5,
            createdAt: DateTime.now(),
            isCompleted: false,
          ),
        ];
        
        // Save sample goals
        for (final goal in sampleGoals) {
          await GoalService.saveGoal(goal);
        }
        
        debugPrint('Created ${sampleGoals.length} sample goals for kids');
      }
    } catch (e) {
      debugPrint('Error creating sample goals: $e');
    }
  }

  Future<void> _loadGoals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final goals = await GoalService.getUserGoals();
      setState(() {
        _goals = goals;
        _activeGoals = goals.where((goal) => !goal.isCompleted).toList();
        _completedGoals = goals.where((goal) => goal.isCompleted).toList();
        _isLoading = false;
      });
    } on AACException catch (e) {
      setState(() {
        _errorMessage = 'Failed to load goals: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Unexpected error loading goals';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleGoalCompletion(Goal goal) async {
    try {
      if (goal.isCompleted) {
        await GoalService.uncompleteGoal(goal.id);
      } else {
        await GoalService.completeGoal(goal.id);
      }
      await _loadGoals();
    } on AACException catch (e) {
      _showErrorDialog('Failed to update goal: ${e.message}');
    } catch (e) {
      _showErrorDialog('Failed to update goal');
    }
  }

  Future<void> _deleteGoal(Goal goal) async {
    try {
      await GoalService.deleteGoal(goal.id);
      await _loadGoals();
    } on AACException catch (e) {
      _showErrorDialog('Failed to delete goal: ${e.message}');
    } catch (e) {
      _showErrorDialog('Failed to delete goal');
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Goal goal) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Are you sure you want to delete "${goal.title}"?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.pop(context);
              _deleteGoal(goal);
            },
          ),
        ],
      ),
    );
  }

  void _navigateToAddGoal({Goal? existingGoal}) async {
    final result = await Navigator.push<Goal>(
      context,
      CupertinoPageRoute(
        builder: (context) => AddGoalScreen(goal: existingGoal),
      ),
    );

    if (result != null) {
      await _loadGoals();
    }
  }

  List<Goal> _getCurrentGoals() {
    switch (_currentView) {
      case 'active':
        return _activeGoals;
      case 'completed':
        return _completedGoals;
      case 'all':
      default:
        return _goals;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Goals & Progress'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _navigateToAddGoal(),
          child: const Icon(CupertinoIcons.add_circled_solid, size: 24),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // View selector tabs
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground,
                border: Border(
                  bottom: BorderSide(color: CupertinoColors.separator),
                ),
              ),
              child: Row(
                children: [
                  _buildViewTab('Active', 'active', _activeGoals.length),
                  _buildViewTab('Completed', 'completed', _completedGoals.length),
                  _buildViewTab('All', 'all', _goals.length),
                ],
              ),
            ),

            // Error message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.exclamationmark_triangle, color: CupertinoColors.systemRed),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: CupertinoColors.systemRed),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => setState(() => _errorMessage = null),
                      child: const Icon(CupertinoIcons.clear, color: CupertinoColors.systemRed, size: 16),
                    ),
                  ],
                ),
              ),

            // Loading indicator
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CupertinoActivityIndicator(radius: 16),
                ),
              ),

            // Empty state
            if (!_isLoading && _getCurrentGoals().isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.flag,
                        size: 64,
                        color: CupertinoColors.systemGrey3,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _currentView == 'completed' 
                          ? 'No completed goals yet'
                          : 'No goals yet',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentView == 'completed'
                          ? 'Complete some goals to see them here'
                          : 'Tap + to add your first goal',
                        style: const TextStyle(
                          color: CupertinoColors.systemGrey2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      if (_currentView != 'completed')
                        CupertinoButton(
                          onPressed: () => _navigateToAddGoal(),
                          child: const Text('Add First Goal'),
                        ),
                    ],
                  ),
                ),
              ),

            // Goals list
            if (!_isLoading && _getCurrentGoals().isNotEmpty)
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _getCurrentGoals().length,
                  itemBuilder: (context, index) {
                    final goal = _getCurrentGoals()[index];
                    return _buildGoalCard(goal);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewTab(String label, String value, int count) {
    final isSelected = _currentView == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentView = value),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? CupertinoColors.activeBlue : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? CupertinoColors.activeBlue : CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? CupertinoColors.activeBlue : CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalCard(Goal goal) {
    final isOverdue = goal.isOverdue;
    final daysRemaining = goal.daysRemaining;
    final priorityColor = Color(goal.priorityColor);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CupertinoContextMenu(
        actions: [
          CupertinoContextMenuAction(
            onPressed: () {
              Navigator.pop(context);
              _navigateToAddGoal(existingGoal: goal);
            },
            trailingIcon: CupertinoIcons.pencil,
            child: const Text('Edit'),
          ),
          CupertinoContextMenuAction(
            onPressed: () {
              Navigator.pop(context);
              _showDeleteConfirmation(goal);
            },
            trailingIcon: CupertinoIcons.delete,
            isDestructiveAction: true,
            child: const Text('Delete'),
          ),
        ],
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _navigateToAddGoal(existingGoal: goal),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with priority and completion
                Row(
                  children: [
                    // Priority indicator
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: priorityColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      goal.priorityDisplayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: priorityColor,
                      ),
                    ),
                    const Spacer(),
                    // Category
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        goal.category.displayName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Title
                Text(
                  goal.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label,
                  ),
                ),

                // Description
                if (goal.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    goal.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.systemGrey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 16),

                // Footer with dates and actions
                Row(
                  children: [
                    // Due date info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Due: ${_formatDate(goal.targetDate)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isOverdue ? CupertinoColors.systemRed : CupertinoColors.systemGrey,
                              fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          if (!goal.isCompleted && !isOverdue)
                            Text(
                              '${daysRemaining} ${daysRemaining == 1 ? 'day' : 'days'} left',
                              style: const TextStyle(
                                fontSize: 12,
                                color: CupertinoColors.systemGreen,
                              ),
                            ),
                          if (goal.isCompleted && goal.completedAt != null)
                            Text(
                              'Completed: ${_formatDate(goal.completedAt!)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: CupertinoColors.systemGreen,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Toggle completion button
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _toggleGoalCompletion(goal),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: goal.isCompleted 
                            ? CupertinoColors.systemGreen 
                            : CupertinoColors.systemGrey5,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          goal.isCompleted ? CupertinoIcons.checkmark_alt : CupertinoIcons.add,
                          size: 16,
                          color: goal.isCompleted ? CupertinoColors.white : CupertinoColors.systemGrey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));

    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return 'Today';
    } else if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      return 'Tomorrow';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
