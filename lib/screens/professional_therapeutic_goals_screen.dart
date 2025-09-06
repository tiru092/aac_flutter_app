import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/aac_helper.dart';
import '../services/aac_analytics_service.dart';

/// Professional Therapeutic Goals Screen
/// Based on evidence-based AAC intervention practices
class ProfessionalTherapeuticGoalsScreen extends StatefulWidget {
  const ProfessionalTherapeuticGoalsScreen({super.key});

  @override
  State<ProfessionalTherapeuticGoalsScreen> createState() => _ProfessionalTherapeuticGoalsScreenState();
}

class _ProfessionalTherapeuticGoalsScreenState extends State<ProfessionalTherapeuticGoalsScreen> {
  
  int _selectedTabIndex = 0;
  Map<String, dynamic> _weeklyReport = {};
  Map<String, dynamic> _languageMilestones = {};
  bool _isLoading = true;
  
  // Therapeutic goal categories
  final List<Map<String, dynamic>> _goalCategories = [
    {
      'id': 'communication_functions',
      'title': 'Communication Functions',
      'icon': '💬',
      'description': 'Requesting, commenting, asking questions, protesting',
      'goals': [
        {
          'id': 'requesting',
          'title': 'Requesting Objects/Actions',
          'description': 'Use AAC to request preferred items and activities',
          'targetCriteria': 'Request 10 different items/actions in a session',
          'currentProgress': 0.0,
          'evidence': 'Light & McNaughton (2012) - Core vocabulary research',
        },
        {
          'id': 'commenting',
          'title': 'Making Comments',
          'description': 'Share observations and experiences using AAC',
          'targetCriteria': 'Make 5 spontaneous comments per session',
          'currentProgress': 0.0,
          'evidence': 'Beukelman & Mirenda (2013) - Pragmatic functions',
        },
        {
          'id': 'questioning',
          'title': 'Asking Questions',
          'description': 'Use question words to gather information',
          'targetCriteria': 'Ask 3 different types of questions per session',
          'currentProgress': 0.0,
          'evidence': 'Sennott & Bowker (2009) - Question development',
        },
      ],
    },
    {
      'id': 'language_development',
      'title': 'Language Development',
      'icon': '📚',
      'description': 'Vocabulary growth, sentence construction, grammar',
      'goals': [
        {
          'id': 'vocabulary_expansion',
          'title': 'Core Vocabulary Usage',
          'description': 'Use high-frequency core words across contexts',
          'targetCriteria': 'Use 50 different core words weekly',
          'currentProgress': 0.0,
          'evidence': 'Banajee et al. (2003) - Core vocabulary frequency',
        },
        {
          'id': 'sentence_construction',
          'title': 'Multi-Word Combinations',
          'description': 'Combine symbols to create meaningful sentences',
          'targetCriteria': 'Create 10 sentences with 3+ words daily',
          'currentProgress': 0.0,
          'evidence': 'Sutton et al. (2010) - Sentence development in AAC',
        },
        {
          'id': 'grammar_development',
          'title': 'Grammatical Markers',
          'description': 'Use grammatical elements (plurals, tense, etc.)',
          'targetCriteria': 'Use 5 different grammatical markers weekly',
          'currentProgress': 0.0,
          'evidence': 'Smith & Grove (2003) - Grammar in AAC systems',
        },
      ],
    },
    {
      'id': 'social_communication',
      'title': 'Social Communication',
      'icon': '👥',
      'description': 'Turn-taking, social routines, conversational skills',
      'goals': [
        {
          'id': 'turn_taking',
          'title': 'Conversational Turn-Taking',
          'description': 'Engage in back-and-forth communication exchanges',
          'targetCriteria': 'Maintain 5-turn conversations',
          'currentProgress': 0.0,
          'evidence': 'Kent-Walsh & McNaughton (2005) - Conversation skills',
        },
        {
          'id': 'social_routines',
          'title': 'Social Routines',
          'description': 'Use greetings, polite forms, and social scripts',
          'targetCriteria': 'Use appropriate social forms in 80% of interactions',
          'currentProgress': 0.0,
          'evidence': 'Calculator (2009) - Social competence in AAC',
        },
        {
          'id': 'topic_initiation',
          'title': 'Topic Initiation',
          'description': 'Start conversations about various topics',
          'targetCriteria': 'Initiate 3 different topics per session',
          'currentProgress': 0.0,
          'evidence': 'Light et al. (2007) - Conversation initiation strategies',
        },
      ],
    },
    {
      'id': 'academic_participation',
      'title': 'Academic Participation',
      'icon': '🎓',
      'description': 'Classroom communication, literacy support, learning',
      'goals': [
        {
          'id': 'classroom_participation',
          'title': 'Active Class Participation',
          'description': 'Use AAC to participate in academic activities',
          'targetCriteria': 'Participate in 80% of classroom opportunities',
          'currentProgress': 0.0,
          'evidence': 'Erickson & Geist (2016) - AAC in educational settings',
        },
        {
          'id': 'literacy_support',
          'title': 'Reading and Writing Support',
          'description': 'Use AAC to support literacy development',
          'targetCriteria': 'Complete 5 literacy activities using AAC weekly',
          'currentProgress': 0.0,
          'evidence': 'Sturm & Clendon (2004) - AAC and literacy',
        },
        {
          'id': 'content_discussion',
          'title': 'Content Area Discussion',
          'description': 'Discuss academic subjects using AAC',
          'targetCriteria': 'Contribute to discussions in 3 subject areas weekly',
          'currentProgress': 0.0,
          'evidence': 'Soto et al. (2001) - AAC in curriculum access',
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadProgressData();
  }

  Future<void> _loadProgressData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final weeklyReport = await AACAnalyticsService.getWeeklyReport();
      final languageMilestones = AACAnalyticsService.getLanguageMilestones();
      
      setState(() {
        _weeklyReport = weeklyReport;
        _languageMilestones = languageMilestones;
        _isLoading = false;
      });

      // Update goal progress based on analytics
      _updateGoalProgress();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        _showErrorDialog('Error loading analytics data: $e');
      }
    }
  }

  void _updateGoalProgress() {
    // Update progress based on actual usage data
    for (final category in _goalCategories) {
      for (final goal in category['goals']) {
        goal['currentProgress'] = _calculateGoalProgress(goal['id']);
      }
    }
    setState(() {});
  }

  double _calculateGoalProgress(String goalId) {
    if (_weeklyReport.isEmpty) return 0.0;

    final totalWords = _weeklyReport['totalWords'] ?? 0;
    final totalSentences = _weeklyReport['totalSentences'] ?? 0;
    final totalSessions = _weeklyReport['totalSessions'] ?? 0;

    switch (goalId) {
      case 'requesting':
        return (totalWords / 70).clamp(0.0, 1.0); // 10 requests × 7 days
      case 'commenting':
        return (totalSentences / 35).clamp(0.0, 1.0); // 5 comments × 7 days
      case 'vocabulary_expansion':
        final categories = _weeklyReport['mostUsedCategories'] as Map<String, dynamic>? ?? {};
        return (categories.length / 8).clamp(0.0, 1.0); // 8 core categories
      case 'sentence_construction':
        return (totalSentences / 70).clamp(0.0, 1.0); // 10 sentences × 7 days
      case 'turn_taking':
        return (totalSessions / 7).clamp(0.0, 1.0); // Daily practice
      case 'classroom_participation':
        return (totalWords / 100).clamp(0.0, 1.0); // Academic usage estimate
      default:
        return (totalWords / 50).clamp(0.0, 1.0); // General usage
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBlue,
        middle: Text(
          'Therapeutic Goals',
          style: TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.bold),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Progress Overview Card
            _buildProgressOverview(),
            
            // Segmented Control for tabs
            Container(
              color: CupertinoColors.systemGrey6,
              padding: const EdgeInsets.all(16),
              child: CupertinoSegmentedControl<int>(
                children: const {
                  0: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text('Functions'),
                  ),
                  1: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text('Language'),
                  ),
                  2: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text('Social'),
                  ),
                  3: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text('Academic'),
                  ),
                },
                onValueChanged: (int value) {
                  setState(() {
                    _selectedTabIndex = value;
                  });
                },
                groupValue: _selectedTabIndex,
              ),
            ),
            
            // Tab Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator(radius: 20))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 50), // Add bottom padding
                      child: _buildGoalCategory(_goalCategories[_selectedTabIndex]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressOverview() {
    if (_isLoading) {
      return Container(
        height: 120,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [CupertinoColors.systemBlue, CupertinoColors.systemBlue.darkColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CupertinoActivityIndicator(radius: 15, color: CupertinoColors.white),
        ),
      );
    }

    final currentLevel = _languageMilestones['currentLevel'] ?? 'Assessment Needed';
    final nextMilestone = _languageMilestones['nextMilestone'] ?? {};
    final progress = nextMilestone['progress'] ?? 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [CupertinoColors.systemBlue, CupertinoColors.systemBlue.darkColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemBlue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.chart_bar_alt_fill, color: CupertinoColors.white, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Language Development Progress',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Level:',
                      style: TextStyle(color: CupertinoColors.white.withOpacity(0.9), fontSize: 14),
                    ),
                    Text(
                      currentLevel,
                      style: const TextStyle(color: CupertinoColors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Progress to Next:',
                      style: TextStyle(color: CupertinoColors.white.withOpacity(0.9), fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: CupertinoColors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(CupertinoColors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(progress * 100).toInt()}% Complete',
                      style: const TextStyle(color: CupertinoColors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 20),
              
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Icon(CupertinoIcons.chart_bar_alt_fill, color: CupertinoColors.white, size: 24),
                          const SizedBox(height: 4),
                          Text(
                            '${_weeklyReport['totalWords'] ?? 0}',
                            style: const TextStyle(color: CupertinoColors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'Words This Week',
                            style: TextStyle(color: CupertinoColors.white, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCategory(Map<String, dynamic> category) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
          child: Row(
            children: [
              Text(
                category['icon'],
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category['title'],
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category['description'],
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Goals List
        ...category['goals'].map<Widget>((goal) => _buildGoalCard(goal)).toList(),
        ],
      ),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    final progress = goal['currentProgress'] as double;
    final isCompleted = progress >= 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted ? CupertinoColors.systemGreen : CupertinoColors.systemGrey4,
          width: isCompleted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Goal Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green.shade100 : Colors.indigo.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isCompleted ? Colors.green.shade600 : Colors.indigo.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  goal['title'],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? Colors.green.shade600 : Colors.indigo.shade600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Goal Description
          Text(
            goal['description'],
            style: const TextStyle(fontSize: 16),
          ),
          
          const SizedBox(height: 8),
          
          // Target Criteria
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.flag, color: Colors.orange.shade600, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Target: ${goal['targetCriteria']}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Progress',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? Colors.green.shade400 : Colors.indigo.shade400,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Evidence Base
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.science, color: Colors.blue.shade600, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Evidence: ${goal['evidence']}',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          ),
          
          // Action Buttons
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: Colors.indigo.shade400,
                  borderRadius: BorderRadius.circular(8),
                  onPressed: () => _showGoalStrategies(goal),
                  child: const Text('View Strategies', style: TextStyle(fontSize: 14)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                  onPressed: () => _showProgressDetails(goal),
                  child: Text(
                    'Details',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showGoalStrategies(Map<String, dynamic> goal) {
    final strategies = _getStrategiesForGoal(goal['id']);
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Strategies: ${goal['title']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            ...strategies.map((strategy) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: Text(strategy, style: const TextStyle(fontSize: 14))),
                ],
              ),
            )).toList(),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Close'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showProgressDetails(Map<String, dynamic> goal) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Progress Details: ${goal['title']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text('Current Progress: ${(goal['currentProgress'] * 100).toInt()}%'),
            const SizedBox(height: 8),
            Text('Target: ${goal['targetCriteria']}'),
            const SizedBox(height: 8),
            Text('Weekly Usage: ${_weeklyReport['totalWords'] ?? 0} words'),
            const SizedBox(height: 8),
            Text('Sessions: ${_weeklyReport['totalSessions'] ?? 0} this week'),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Close'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  List<String> _getStrategiesForGoal(String goalId) {
    switch (goalId) {
      case 'requesting':
        return [
          'Model requesting during preferred activities',
          'Use expectant pause to encourage requests',
          'Place preferred items in sight but out of reach',
          'Prompt "I want..." sentence starters',
        ];
      case 'commenting':
        return [
          'Model comments during shared activities',
          'Use "I see..." and "That\'s..." frames',
          'Comment on unexpected or exciting events',
          'Wait for child to initiate comments',
        ];
      case 'vocabulary_expansion':
        return [
          'Introduce 2-3 new core words weekly',
          'Use new words across multiple contexts',
          'Practice word combinations daily',
          'Focus on high-frequency words first',
        ];
      case 'sentence_construction':
        return [
          'Start with 2-word combinations',
          'Use sentence starters and frames',
          'Model longer sentences during activities',
          'Practice expanding simple sentences',
        ];
      case 'turn_taking':
        return [
          'Practice back-and-forth exchanges',
          'Use visual turn-taking cues',
          'Start with simple question-answer formats',
          'Model appropriate response timing',
        ];
      default:
        return [
          'Practice regularly in natural contexts',
          'Model target behaviors consistently',
          'Provide positive reinforcement',
          'Track progress systematically',
        ];
    }
  }
}
