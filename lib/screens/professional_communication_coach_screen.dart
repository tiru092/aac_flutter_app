import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../utils/aac_helper.dart';
import '../services/aac_analytics_service.dart';

/// Professional Communication Coaching Screen
/// Based on Avaz Communication Adventures and Proloquo Coach methodology
class ProfessionalCommunicationCoachScreen extends StatefulWidget {
  const ProfessionalCommunicationCoachScreen({super.key});

  @override
  State<ProfessionalCommunicationCoachScreen> createState() => _ProfessionalCommunicationCoachScreenState();
}

class _ProfessionalCommunicationCoachScreenState extends State<ProfessionalCommunicationCoachScreen> {
  
  int _selectedTabIndex = 0;
  int _currentActivityIndex = 0;
  Map<String, dynamic> _currentSession = {};
  bool _isActivityActive = false;
  
  // Communication coaching modules
  final List<Map<String, dynamic>> _coachingModules = [
    {
      'id': 'modeling_strategies',
      'title': 'AAC Modeling Strategies',
      'icon': '👥',
      'description': 'Learn effective ways to model AAC use',
      'activities': [
        {
          'title': 'Aided Language Stimulation',
          'description': 'Model AAC while speaking naturally',
          'instructions': [
            'Talk normally while pointing to AAC symbols',
            'Model every opportunity, not just when child needs to communicate',
            'Model more than you expect the child to say',
            'Keep models natural and conversational',
          ],
          'practice_scenario': 'Snack time conversation',
          'symbols_to_model': ['I', 'want', 'more', 'finished', 'good', 'yummy'],
          'tips': [
            'Point to symbols as you say each word',
            'Don\'t require immediate imitation',
            'Model throughout daily activities',
          ],
        },
        {
          'title': 'Expectant Pause Strategy',
          'description': 'Use strategic pauses to encourage communication',
          'instructions': [
            'Pause expectantly during routine activities',
            'Look at the child and wait for communication',
            'Count to 10 before prompting',
            'Celebrate any communication attempt',
          ],
          'practice_scenario': 'Getting ready to go outside',
          'symbols_to_model': ['go', 'outside', 'shoes', 'coat', 'ready'],
          'tips': [
            'Use expectant facial expressions',
            'Wait longer than feels comfortable',
            'Accept any form of communication',
          ],
        },
      ],
    },
    {
      'id': 'engagement_techniques',
      'title': 'Engagement Techniques',
      'icon': '🎯',
      'description': 'Strategies to increase motivation and participation',
      'activities': [
        {
          'title': 'Sabotage and Obstacles',
          'description': 'Create communication opportunities through gentle sabotage',
          'instructions': [
            'Put preferred items in clear containers they can\'t open',
            'Give them the "wrong" item and wait',
            'Start a preferred activity and then pause',
            'Forget an essential item and act confused',
          ],
          'practice_scenario': 'Art activity with missing supplies',
          'symbols_to_model': ['help', 'open', 'need', 'where', 'get'],
          'tips': [
            'Keep sabotage gentle and playful',
            'Be ready to help immediately when requested',
            'Make it obvious what they need to communicate',
          ],
        },
        {
          'title': 'Choice-Making Opportunities',
          'description': 'Offer meaningful choices throughout the day',
          'instructions': [
            'Offer choices between two preferred options',
            'Make choices visible with objects or pictures',
            'Wait for selection before proceeding',
            'Honor their choice whenever possible',
          ],
          'practice_scenario': 'Choosing between activities',
          'symbols_to_model': ['this', 'that', 'pick', 'choose', 'like'],
          'tips': [
            'Start with two clear options',
            'Make both choices appealing',
            'Use visual supports for choices',
          ],
        },
      ],
    },
    {
      'id': 'conversation_skills',
      'title': 'Conversation Development',
      'icon': '💬',
      'description': 'Building conversational competence',
      'activities': [
        {
          'title': 'Question-Answer Exchanges',
          'description': 'Practice structured conversation patterns',
          'instructions': [
            'Start with simple yes/no questions',
            'Progress to "what" and "where" questions',
            'Model answering questions using AAC',
            'Teach question words systematically',
          ],
          'practice_scenario': 'Looking at family photos',
          'symbols_to_model': ['who', 'what', 'where', 'yes', 'no'],
          'tips': [
            'Start with questions about present items',
            'Use real photos and meaningful contexts',
            'Accept partial answers and expand',
          ],
        },
        {
          'title': 'Topic Maintenance',
          'description': 'Keeping conversations going',
          'instructions': [
            'Add related comments to extend topics',
            'Ask follow-up questions',
            'Share related experiences',
            'Use "tell me more" prompts',
          ],
          'practice_scenario': 'Discussing weekend activities',
          'symbols_to_model': ['fun', 'tell', 'more', 'like', 'good'],
          'tips': [
            'Show genuine interest in their communication',
            'Add your own related comments',
            'Keep topics child-centered',
          ],
        },
      ],
    },
    {
      'id': 'daily_integration',
      'title': 'Daily Life Integration',
      'icon': '🏠',
      'description': 'Integrating AAC into everyday activities',
      'activities': [
        {
          'title': 'Routine-Based Communication',
          'description': 'Embed AAC in daily routines',
          'instructions': [
            'Identify communication opportunities in routines',
            'Create visual schedules with AAC symbols',
            'Practice routine language consistently',
            'Let child control pace when possible',
          ],
          'practice_scenario': 'Morning routine sequence',
          'symbols_to_model': ['wake up', 'brush teeth', 'eat', 'get dressed'],
          'tips': [
            'Start with most motivating routines',
            'Keep language consistent across days',
            'Let child initiate when ready',
          ],
        },
        {
          'title': 'Social Interaction Coaching',
          'description': 'Supporting social communication',
          'instructions': [
            'Model greetings and social scripts',
            'Practice turn-taking in activities',
            'Teach repair strategies for breakdowns',
            'Support peer interactions',
          ],
          'practice_scenario': 'Playing with siblings/friends',
          'symbols_to_model': ['hi', 'bye', 'play', 'my turn', 'your turn'],
          'tips': [
            'Model social language naturally',
            'Support but don\'t overwhelm interactions',
            'Celebrate social attempts',
          ],
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    AACAnalyticsService.startSession();
  }

  @override
  void dispose() {
    AACAnalyticsService.endSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemTeal,
        middle: Text(
          'Communication Coach',
          style: TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.bold),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Welcome Card
            _buildWelcomeCard(),
            
            // Segmented Control for modules
            Container(
              color: CupertinoColors.systemGrey6,
              padding: const EdgeInsets.all(16),
              child: CupertinoSegmentedControl<int>(
                children: {
                  for (int i = 0; i < _coachingModules.length; i++)
                    i: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_coachingModules[i]['icon'], style: const TextStyle(fontSize: 14)),
                          Text(_coachingModules[i]['title'].split(' ')[0], 
                               style: const TextStyle(fontSize: 10)),
                        ],
                      ),
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
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: _buildModuleContent(_coachingModules[_selectedTabIndex]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [CupertinoColors.systemTeal, CupertinoColors.systemTeal.darkColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.school, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Communication Coach',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Evidence-based strategies for AAC success',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            onPressed: _showCoachingTips,
            child: const Text(
              'Tips',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleContent(Map<String, dynamic> module) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Module Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.shade200),
            ),
          child: Row(
            children: [
              Text(
                module['icon'],
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module['title'],
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      module['description'],
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Activities
        ...module['activities'].map<Widget>((activity) => _buildActivityCard(activity)).toList(),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Activity Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.play_arrow, color: Colors.teal.shade600, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity['title'],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activity['description'],
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Activity Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Practice Scenario
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.theater_comedy, color: Colors.orange.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Practice Scenario: ${activity['practice_scenario']}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Instructions
                const Text(
                  'Instructions:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...activity['instructions'].map<Widget>((instruction) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.teal.shade400,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          instruction,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
                
                const SizedBox(height: 16),
                
                // Symbols to Model
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.touch_app, color: Colors.blue.shade600, size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            'Key Symbols to Model:',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: activity['symbols_to_model'].map<Widget>((symbol) => 
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              symbol,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ).toList(),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Tips
                const Text(
                  'Pro Tips:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...activity['tips'].map<Widget>((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb, color: Colors.amber, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tip,
                          style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
                
                const SizedBox(height: 20),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        color: Colors.teal.shade400,
                        borderRadius: BorderRadius.circular(8),
                        onPressed: () => _startPracticeSession(activity),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_circle, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('Start Practice', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                      onPressed: () => _showActivityDetails(activity),
                      child: Icon(Icons.info_outline, color: Colors.grey.shade600, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCoachingTips() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('🎯 Coaching Success Tips'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            Text('• Model more than you expect', style: TextStyle(fontSize: 14)),
            SizedBox(height: 8),
            Text('• Follow the child\'s lead and interests', style: TextStyle(fontSize: 14)),
            SizedBox(height: 8),
            Text('• Practice in natural, meaningful contexts', style: TextStyle(fontSize: 14)),
            SizedBox(height: 8),
            Text('• Celebrate all communication attempts', style: TextStyle(fontSize: 14)),
            SizedBox(height: 8),
            Text('• Be patient and persistent', style: TextStyle(fontSize: 14)),
            SizedBox(height: 8),
            Text('• Have realistic expectations', style: TextStyle(fontSize: 14)),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Got it!'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _startPracticeSession(Map<String, dynamic> activity) {
    setState(() {
      _isActivityActive = true;
      _currentSession = {
        'activity': activity,
        'startTime': DateTime.now(),
        'symbolsModeled': <String>[],
        'completed': false,
      };
    });

    // Track analytics
    AACAnalyticsService.trackSymbolUsage(
      'coaching_session_${activity['title']}',
      'communication_coaching',
      'practice_session'
    );

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('🎯 ${activity['title']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(
              'Practice scenario: ${activity['practice_scenario']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('Ready to start practicing? Remember to:'),
            const SizedBox(height: 8),
            const Text('• Model naturally while you speak'),
            const Text('• Wait for responses'),
            const Text('• Celebrate attempts'),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Start Practice'),
            onPressed: () {
              Navigator.pop(context);
              _showPracticeInterface(activity);
            },
          ),
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () {
              setState(() {
                _isActivityActive = false;
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showPracticeInterface(Map<String, dynamic> activity) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Practice: ${activity['title']}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Practice Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Scenario
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '🎭 Scenario: ${activity['practice_scenario']}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Symbol Practice Grid
                      const Text(
                        'Tap symbols as you model them:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1.2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: activity['symbols_to_model'].length,
                          itemBuilder: (context, index) {
                            final symbol = activity['symbols_to_model'][index];
                            final isModeled = _currentSession['symbolsModeled'].contains(symbol);
                            
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (!isModeled) {
                                    _currentSession['symbolsModeled'].add(symbol);
                                  }
                                });
                                AACHelper.speak(symbol);
                                AACAnalyticsService.trackSymbolUsage(symbol, 'practice', 'coaching_session');
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isModeled ? Colors.green.shade100 : Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isModeled ? Colors.green.shade400 : Colors.blue.shade300,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isModeled ? Icons.check_circle : Icons.touch_app,
                                      color: isModeled ? Colors.green.shade600 : Colors.blue.shade600,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      symbol,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isModeled ? Colors.green.shade700 : Colors.blue.shade700,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      // Progress
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.analytics, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Progress: ${_currentSession['symbolsModeled'].length}/${activity['symbols_to_model'].length} symbols modeled',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: _currentSession['symbolsModeled'].length / activity['symbols_to_model'].length,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade400),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActivityDetails(Map<String, dynamic> activity) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(activity['title']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(activity['description']),
            const SizedBox(height: 12),
            Text(
              'Scenario: ${activity['practice_scenario']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Symbols: ${activity['symbols_to_model'].join(", ")}'),
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
}
