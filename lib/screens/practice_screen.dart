import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/practice_goal.dart';

class PracticeScreen extends StatefulWidget {
  final PracticeGoal goal;

  const PracticeScreen({
    Key? key,
    required this.goal,
  }) : super(key: key);

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _successController;
  late Animation<double> _progressAnimation;
  late Animation<double> _successAnimation;
  
  int currentActivityIndex = 0;
  int currentItemIndex = 0;
  int correctAnswers = 0;
  bool isAnswered = false;
  String? selectedAnswer;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _successController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    
    _successAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    ));

    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _successController.dispose();
    super.dispose();
  }

  int get totalQuestions {
    return widget.goal.activities
        .expand((activity) => activity.items)
        .length;
  }

  int get currentQuestionIndex {
    int index = 0;
    for (int i = 0; i < currentActivityIndex; i++) {
      index += widget.goal.activities[i].items.length;
    }
    return index + currentItemIndex;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: _buildAppBar(context, isLandscape),
          body: SafeArea(
            child: _buildBody(context, isLandscape, constraints),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isLandscape) {
    final cardColor = _parseColor(widget.goal.color);
    
    return AppBar(
      backgroundColor: cardColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Text(
            widget.goal.iconEmoji,
            style: TextStyle(fontSize: isLandscape ? 20 : 24),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.goal.name,
              style: TextStyle(
                color: Colors.white,
                fontSize: isLandscape ? 18 : 20,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(isLandscape ? 60 : 80),
        child: _buildProgressSection(context, isLandscape),
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context, bool isLandscape) {
    final progress = totalQuestions > 0 
        ? currentQuestionIndex / totalQuestions 
        : 0.0;
    
    return Container(
      padding: EdgeInsets.all(isLandscape ? 12 : 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${currentQuestionIndex + 1} of $totalQuestions',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: isLandscape ? 14 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.yellow, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '$correctAnswers',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isLandscape ? 14 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: isLandscape ? 8 : 12),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (progress * _progressAnimation.value).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isLandscape, BoxConstraints constraints) {
    if (widget.goal.activities.isEmpty) {
      return const Center(
        child: Text('No activities available'),
      );
    }

    if (currentActivityIndex >= widget.goal.activities.length) {
      return _buildCompletionScreen(context, isLandscape);
    }

    final currentActivity = widget.goal.activities[currentActivityIndex];
    
    if (currentItemIndex >= currentActivity.items.length) {
      return _buildCompletionScreen(context, isLandscape);
    }

    final currentItem = currentActivity.items[currentItemIndex];

    return Padding(
      padding: EdgeInsets.all(isLandscape ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildQuestionCard(context, currentActivity, currentItem, isLandscape),
          SizedBox(height: isLandscape ? 20 : 32),
          Expanded(
            child: _buildAnswerOptions(context, currentItem, isLandscape),
          ),
          SizedBox(height: isLandscape ? 16 : 24),
          if (isAnswered) _buildNextButton(context, isLandscape),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context, PracticeActivity activity, 
                           PracticeItem item, bool isLandscape) {
    return Container(
      padding: EdgeInsets.all(isLandscape ? 20 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (item.emoji != null) ...[
            Text(
              item.emoji!,
              style: TextStyle(
                fontSize: isLandscape ? 32 : 48,
              ),
            ),
            SizedBox(height: isLandscape ? 12 : 16),
          ],
          Text(
            activity.name,
            style: TextStyle(
              fontSize: isLandscape ? 18 : 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D4356),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isLandscape ? 8 : 12),
          Text(
            item.question,
            style: TextStyle(
              fontSize: isLandscape ? 16 : 18,
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOptions(BuildContext context, PracticeItem item, bool isLandscape) {
    final cardColor = _parseColor(widget.goal.color);
    
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isLandscape ? 3 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isLandscape ? 1.2 : 1.0,
      ),
      itemCount: item.options.length,
      itemBuilder: (context, index) {
        final option = item.options[index];
        final isSelected = selectedAnswer == option;
        final isCorrect = option == item.correctAnswer;
        
        Color backgroundColor = Colors.white;
        Color borderColor = const Color(0xFFE2E8F0);
        
        if (isAnswered && isSelected) {
          backgroundColor = isCorrect 
              ? const Color(0xFF10B981).withOpacity(0.1)
              : const Color(0xFFEF4444).withOpacity(0.1);
          borderColor = isCorrect 
              ? const Color(0xFF10B981)
              : const Color(0xFFEF4444);
        } else if (isSelected) {
          backgroundColor = cardColor.withOpacity(0.1);
          borderColor = cardColor;
        }

        return GestureDetector(
          onTap: isAnswered ? null : () => _selectAnswer(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(color: borderColor, width: 2),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isAnswered && isSelected)
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    size: isLandscape ? 32 : 40,
                  ),
                SizedBox(height: isLandscape ? 8 : 12),
                Text(
                  option,
                  style: TextStyle(
                    fontSize: isLandscape ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D4356),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNextButton(BuildContext context, bool isLandscape) {
    final cardColor = _parseColor(widget.goal.color);
    final isLastQuestion = currentQuestionIndex >= totalQuestions - 1;
    
    return AnimatedBuilder(
      animation: _successAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * _successAnimation.value),
          child: ElevatedButton(
            onPressed: _nextQuestion,
            style: ElevatedButton.styleFrom(
              backgroundColor: cardColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                vertical: isLandscape ? 12 : 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isLastQuestion ? 'Complete!' : 'Next Question',
                  style: TextStyle(
                    fontSize: isLandscape ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isLastQuestion ? Icons.celebration : Icons.arrow_forward,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletionScreen(BuildContext context, bool isLandscape) {
    final cardColor = _parseColor(widget.goal.color);
    final accuracy = totalQuestions > 0 
        ? (correctAnswers / totalQuestions * 100).round()
        : 0;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.celebration,
              size: isLandscape ? 60 : 80,
              color: cardColor,
            ),
          ),
          SizedBox(height: isLandscape ? 20 : 32),
          Text(
            'Great Job!',
            style: TextStyle(
              fontSize: isLandscape ? 28 : 32,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D4356),
            ),
          ),
          SizedBox(height: isLandscape ? 12 : 16),
          Text(
            'You completed all activities!',
            style: TextStyle(
              fontSize: isLandscape ? 16 : 18,
              color: const Color(0xFF64748B),
            ),
          ),
          SizedBox(height: isLandscape ? 20 : 32),
          Container(
            padding: EdgeInsets.all(isLandscape ? 16 : 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Your Score',
                  style: TextStyle(
                    fontSize: isLandscape ? 16 : 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
                SizedBox(height: isLandscape ? 8 : 12),
                Text(
                  '$correctAnswers/$totalQuestions',
                  style: TextStyle(
                    fontSize: isLandscape ? 24 : 28,
                    fontWeight: FontWeight.bold,
                    color: cardColor,
                  ),
                ),
                SizedBox(height: isLandscape ? 4 : 8),
                Text(
                  '$accuracy% Accuracy',
                  style: TextStyle(
                    fontSize: isLandscape ? 14 : 16,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isLandscape ? 24 : 40),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: cardColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isLandscape ? 32 : 40,
                vertical: isLandscape ? 12 : 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Back to Goals',
              style: TextStyle(
                fontSize: isLandscape ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectAnswer(String answer) {
    if (isAnswered) return;
    
    setState(() {
      selectedAnswer = answer;
      isAnswered = true;
    });

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Check if correct
    final currentActivity = widget.goal.activities[currentActivityIndex];
    final currentItem = currentActivity.items[currentItemIndex];
    
    if (answer == currentItem.correctAnswer) {
      correctAnswers++;
      _successController.forward().then((_) {
        _successController.reset();
      });
      // Success sound would go here
    } else {
      // Error sound would go here
    }

    // Auto-advance after delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && isAnswered) {
        _nextQuestion();
      }
    });
  }

  void _nextQuestion() {
    final currentActivity = widget.goal.activities[currentActivityIndex];
    
    // Move to next item in current activity
    if (currentItemIndex < currentActivity.items.length - 1) {
      setState(() {
        currentItemIndex++;
        isAnswered = false;
        selectedAnswer = null;
      });
    } 
    // Move to next activity
    else if (currentActivityIndex < widget.goal.activities.length - 1) {
      setState(() {
        currentActivityIndex++;
        currentItemIndex = 0;
        isAnswered = false;
        selectedAnswer = null;
      });
    }
    // Completed all questions
    else {
      return;
    }

    _progressController.reset();
    _progressController.forward();
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
      return const Color(0xFF4CAF50);
    }
  }
}
