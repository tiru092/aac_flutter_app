import 'dart:convert';

enum GoalCategory {
  expressiveLanguage,
  operational,
  socialCommunication,
}

enum DifficultyLevel {
  beginner,
  intermediate,
  advanced,
}

class AACLearningGoal {
  final String id;
  final String title;
  final String description;
  final GoalCategory category;
  final DifficultyLevel difficulty;
  final List<String> objectives;
  final List<String> activities;
  final List<String> examples;
  final String scientificBasis;
  final int estimatedWeeks;
  final List<String> prerequisites;
  final bool isASDFriendly;
  final String visualCue;

  const AACLearningGoal({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.objectives,
    required this.activities,
    required this.examples,
    required this.scientificBasis,
    required this.estimatedWeeks,
    required this.prerequisites,
    this.isASDFriendly = true,
    this.visualCue = '🎯',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'difficulty': difficulty.name,
      'objectives': objectives,
      'activities': activities,
      'examples': examples,
      'scientificBasis': scientificBasis,
      'estimatedWeeks': estimatedWeeks,
      'prerequisites': prerequisites,
      'isASDFriendly': isASDFriendly,
      'visualCue': visualCue,
    };
  }

  factory AACLearningGoal.fromJson(Map<String, dynamic> json) {
    return AACLearningGoal(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: GoalCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => GoalCategory.expressiveLanguage,
      ),
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => DifficultyLevel.beginner,
      ),
      objectives: List<String>.from(json['objectives'] as List),
      activities: List<String>.from(json['activities'] as List),
      examples: List<String>.from(json['examples'] as List),
      scientificBasis: json['scientificBasis'] as String,
      estimatedWeeks: json['estimatedWeeks'] as int,
      prerequisites: List<String>.from(json['prerequisites'] as List),
      isASDFriendly: json['isASDFriendly'] as bool? ?? true,
      visualCue: json['visualCue'] as String? ?? '🎯',
    );
  }
}

class AACLearningGoalData {
  static List<AACLearningGoal> getAllGoals() {
    return [
      ...getExpressiveLanguageGoals(),
      ...getOperationalGoals(),
      ...getSocialCommunicationGoals(),
    ];
  }

  static List<AACLearningGoal> getExpressiveLanguageGoals() {
    return [
      AACLearningGoal(
        id: 'exp_basic_requests',
        title: 'Request Preferred Items (2 Symbols)',
        description: 'Use 2-symbol combinations to request preferred items',
        category: GoalCategory.expressiveLanguage,
        difficulty: DifficultyLevel.beginner,
        visualCue: '🤲',
        objectives: [
          'Combine "I want" + object symbol',
          'Use gesture + symbol combination',
          'Request during natural opportunities',
          'Maintain eye contact during request'
        ],
        activities: [
          'Snack time requesting with "I want" + food symbol',
          'Toy selection using "give me" + toy symbol',
          'Drink requests with "I want" + drink symbol',
          'Book reading with "read" + book symbol'
        ],
        examples: [
          '"I want" + "cookie" during snack time',
          '"Give me" + "ball" during play time',
          '"I want" + "water" when thirsty',
          '"Play" + "music" for entertainment'
        ],
        scientificBasis: 'Research by Light & Drager (2007) shows that 2-symbol combinations are foundational for AAC language development and should be taught before longer utterances.',
        estimatedWeeks: 4,
        prerequisites: ['Single symbol recognition', 'Basic cause-effect understanding'],
      ),
      
      AACLearningGoal(
        id: 'exp_greetings',
        title: 'Use Appropriate Greetings',
        description: 'Select and use context-appropriate greeting messages',
        category: GoalCategory.expressiveLanguage,
        difficulty: DifficultyLevel.beginner,
        visualCue: '👋',
        objectives: [
          'Use "Hi" for familiar people',
          'Use "Hello" for formal situations',
          'Use "Bye" when leaving',
          'Match greeting to time of day'
        ],
        activities: [
          'Morning greetings with family',
          'Greeting classmates at school',
          'Saying goodbye after visits',
          'Phone call greetings practice'
        ],
        examples: [
          '"Hi" + person\'s name for friends',
          '"Good morning" for morning time',
          '"Bye bye" when leaving places',
          '"Hello" for meeting new people'
        ],
        scientificBasis: 'Pragmatic language research by Wetherby & Prizant (2000) emphasizes the importance of social greetings as foundational communication skills for children with ASD.',
        estimatedWeeks: 3,
        prerequisites: ['Basic symbol recognition'],
      ),

      AACLearningGoal(
        id: 'exp_comments',
        title: 'Make Comments During Activities',
        description: 'Express observations and feelings during shared activities',
        category: GoalCategory.expressiveLanguage,
        difficulty: DifficultyLevel.intermediate,
        visualCue: '💭',
        objectives: [
          'Comment on ongoing activities',
          'Share observations about environment',
          'Express feelings about experiences',
          'Describe what they see or hear'
        ],
        activities: [
          'Commenting during story reading',
          'Describing artwork or crafts',
          'Sharing observations during walks',
          'Commenting on movies or videos'
        ],
        examples: [
          '"That\'s fun!" during play activities',
          '"I see" + object during exploration',
          '"That\'s funny" during funny videos',
          '"Look at me" to gain attention'
        ],
        scientificBasis: 'Joint attention research by Mundy & Newell (2007) shows that commenting develops joint attention skills crucial for social communication in children with ASD.',
        estimatedWeeks: 6,
        prerequisites: ['2-symbol combinations', 'Basic vocabulary'],
      ),

      AACLearningGoal(
        id: 'exp_questions',
        title: 'Ask Questions Using AAC',
        description: 'Use question words and structures to seek information',
        category: GoalCategory.expressiveLanguage,
        difficulty: DifficultyLevel.intermediate,
        visualCue: '❓',
        objectives: [
          'Use "What\'s that?" for unknown objects',
          'Ask "Where is?" for missing items',
          'Use "Who is?" for people identification',
          'Ask "Why?" for explanations'
        ],
        activities: [
          'Asking about new objects',
          'Finding missing items',
          'Identifying people in photos',
          'Asking for explanations'
        ],
        examples: [
          '"What\'s that?" + pointing to object',
          '"Where is" + "my toy"?',
          '"Who is" + pointing to person',
          '"Why" + "sad?" when seeing emotions'
        ],
        scientificBasis: 'Research by Binger & Light (2006) demonstrates that question-asking skills are essential for active participation in social interactions and learning.',
        estimatedWeeks: 8,
        prerequisites: ['2-symbol combinations', 'WH-word recognition'],
      ),

      AACLearningGoal(
        id: 'exp_protests',
        title: 'Protest or Reject Items',
        description: 'Appropriately express when they don\'t want something',
        category: GoalCategory.expressiveLanguage,
        difficulty: DifficultyLevel.beginner,
        visualCue: '🚫',
        objectives: [
          'Use "No" to reject unwanted items',
          'Use "I don\'t want" for clear rejection',
          'Use "Stop" to end activities',
          'Use "Finished" when done'
        ],
        activities: [
          'Rejecting non-preferred foods',
          'Stopping unwanted activities',
          'Declining offers politely',
          'Ending tasks when complete'
        ],
        examples: [
          '"No" + pushing away unwanted item',
          '"I don\'t want" + food symbol',
          '"Stop" during overwhelming activities',
          '"All done" when finishing tasks'
        ],
        scientificBasis: 'Carr & Durand (1985) research shows that appropriate rejection skills reduce challenging behaviors and increase positive communication in children with ASD.',
        estimatedWeeks: 3,
        prerequisites: ['Basic symbol recognition'],
      ),

      AACLearningGoal(
        id: 'exp_emotions',
        title: 'Express Emotions',
        description: 'Communicate feelings and emotional states effectively',
        category: GoalCategory.expressiveLanguage,
        difficulty: DifficultyLevel.intermediate,
        visualCue: '😊',
        objectives: [
          'Express basic emotions (happy, sad, mad)',
          'Describe intensity of feelings',
          'Share emotional responses to events',
          'Request help when overwhelmed'
        ],
        activities: [
          'Emotion check-ins during the day',
          'Sharing feelings about activities',
          'Describing reactions to stories',
          'Expressing comfort needs'
        ],
        examples: [
          '"I feel" + "happy" after fun activities',
          '"I feel" + "sad" when upset',
          '"I feel" + "excited" for special events',
          '"Help me" when feeling overwhelmed'
        ],
        scientificBasis: 'Emotion regulation research by Prizant et al. (2006) emphasizes that emotional expression through AAC supports self-regulation and reduces behavioral challenges.',
        estimatedWeeks: 10,
        prerequisites: ['Basic vocabulary', 'Emotion recognition'],
      ),

      AACLearningGoal(
        id: 'exp_protest_reject',
        title: 'Protest or Reject Items',
        description: 'Express refusal or protest using appropriate communication',
        category: GoalCategory.expressiveLanguage,
        difficulty: DifficultyLevel.beginner,
        visualCue: '✋',
        objectives: [
          'Use "No" symbol appropriately',
          'Say "I don\'t want" + item',
          'Express "Stop" during activities',
          'Reject politely with alternatives'
        ],
        activities: [
          'Food refusal during meals',
          'Activity choice with rejection options',
          'Stop requests during play',
          'Alternative choice making'
        ],
        examples: [
          '"No" when offered non-preferred food',
          '"I don\'t want that" for activities',
          '"Stop" during overwhelming situations',
          '"Different one" for alternative choices'
        ],
        scientificBasis: 'Self-advocacy research by Test et al. (2005) shows that refusal and protest skills are essential for self-determination in individuals with disabilities.',
        estimatedWeeks: 4,
        prerequisites: ['Basic symbol recognition'],
      ),

      AACLearningGoal(
        id: 'exp_attention_seeking',
        title: 'Use Pre-stored Messages to Gain Attention',
        description: 'Access and use pre-programmed messages for social interaction',
        category: GoalCategory.expressiveLanguage,
        difficulty: DifficultyLevel.intermediate,
        visualCue: '👀',
        objectives: [
          'Navigate to pre-stored messages',
          'Use "Look at me" appropriately',
          'Call for help when needed',
          'Get attention before communicating'
        ],
        activities: [
          'Attention-getting before requests',
          'Showing completed work',
          'Getting help during difficulties',
          'Sharing exciting discoveries'
        ],
        examples: [
          '"Look at me!" before showing work',
          '"Help me" when stuck on tasks',
          '"Watch this" for demonstrations',
          '"Come here" for social invitations'
        ],
        scientificBasis: 'Joint attention research by Mundy et al. (2003) emphasizes the importance of attention-directing behaviors for social communication development.',
        estimatedWeeks: 5,
        prerequisites: ['Navigation skills', 'Basic social awareness'],
      ),

      AACLearningGoal(
        id: 'exp_story_telling',
        title: 'Retell a Story Using AAC Symbols',
        description: 'Use symbol sequences to retell familiar stories',
        category: GoalCategory.expressiveLanguage,
        difficulty: DifficultyLevel.advanced,
        visualCue: '📚',
        objectives: [
          'Sequence story events using symbols',
          'Include main characters and actions',
          'Use temporal words (first, then, last)',
          'Add descriptive details'
        ],
        activities: [
          'Familiar book retelling',
          'Personal experience sharing',
          'Picture sequence storytelling',
          'Video recap narration'
        ],
        examples: [
          '"First" + "girl" + "walk" + "forest"',
          '"Then" + "wolf" + "talk" + "girl"',
          '"Last" + "hunter" + "save" + "girl"',
          '"The end" story conclusion'
        ],
        scientificBasis: 'Narrative development research by Boudreau & Hedberg (1999) shows that story retelling develops language organization and sequencing skills.',
        estimatedWeeks: 10,
        prerequisites: ['Multi-word messages', 'Temporal understanding'],
      ),

      AACLearningGoal(
        id: 'exp_event_description',
        title: 'Describe an Event Using 3 Symbol Combinations',
        description: 'Create descriptive messages about experiences and events',
        category: GoalCategory.expressiveLanguage,
        difficulty: DifficultyLevel.intermediate,
        visualCue: '🎬',
        objectives: [
          'Use agent + action + object combinations',
          'Describe past events accurately',
          'Include location information',
          'Add time references when possible'
        ],
        activities: [
          'Daily routine descriptions',
          'Field trip recounting',
          'Home activity sharing',
          'Weekend event description'
        ],
        examples: [
          '"I" + "went" + "park"',
          '"Mom" + "cooked" + "dinner"',
          '"We" + "played" + "outside"',
          '"Dog" + "ran" + "fast"'
        ],
        scientificBasis: 'Language complexity research by Light & McNaughton (2014) demonstrates that 3-word combinations support semantic and syntactic development.',
        estimatedWeeks: 7,
        prerequisites: ['2-symbol combinations', 'Basic grammar'],
      ),

      AACLearningGoal(
        id: 'exp_emotions',
        title: 'Express Emotions',
        description: 'Communicate feelings and emotional states effectively',
        category: GoalCategory.expressiveLanguage,
        difficulty: DifficultyLevel.beginner,
        visualCue: '😊',
        objectives: [
          'Identify and express basic emotions',
          'Use emotion symbols appropriately',
          'Connect emotions to situations',
          'Ask for comfort when upset'
        ],
        activities: [
          'Emotion identification games',
          'Feeling check-ins',
          'Story character emotions',
          'Personal emotion sharing'
        ],
        examples: [
          '"I feel happy" after success',
          '"I feel sad" when disappointed',
          '"I feel angry" during conflicts',
          '"I need help" when frustrated'
        ],
        scientificBasis: 'Emotional regulation research by Samson et al. (2015) shows that emotion expression supports self-regulation in children with ASD.',
        estimatedWeeks: 6,
        prerequisites: ['Basic symbol recognition', 'Emotion awareness'],
      ),

      AACLearningGoal(
        id: 'exp_interjections',
        title: 'Use Interjections',
        description: 'Express spontaneous reactions and exclamations',
        category: GoalCategory.expressiveLanguage,
        difficulty: DifficultyLevel.beginner,
        visualCue: '🎉',
        objectives: [
          'Use "Wow!" for surprising events',
          'Say "Yay!" for celebrations',
          'Express "Oops!" for mistakes',
          'Use "Uh oh!" for problems'
        ],
        activities: [
          'Surprise box activities',
          'Celebration moments',
          'Mistake acknowledgment',
          'Problem recognition games'
        ],
        examples: [
          '"Wow!" seeing something amazing',
          '"Yay!" for achievements',
          '"Oops!" when making mistakes',
          '"Uh oh!" when things break'
        ],
        scientificBasis: 'Pragmatic language research by Adams (2002) indicates that interjections support natural communication flow and social interaction.',
        estimatedWeeks: 3,
        prerequisites: ['Basic symbol recognition'],
      ),
    ];
  }

  static List<AACLearningGoal> getOperationalGoals() {
    return [
      AACLearningGoal(
        id: 'op_navigation',
        title: 'Navigate AAC System Independently',
        description: 'Move through different pages and categories without help',
        category: GoalCategory.operational,
        difficulty: DifficultyLevel.beginner,
        visualCue: '🧭',
        objectives: [
          'Find home button from any page',
          'Navigate to different categories',
          'Use back button appropriately',
          'Access favorite symbols quickly'
        ],
        activities: [
          'Guided navigation practice',
          'Symbol hunting games',
          'Timed navigation challenges',
          'Independent exploration time'
        ],
        examples: [
          'Going from "Food" to "Toys" category',
          'Finding "Home" from any location',
          'Accessing "Feelings" from main page',
          'Using favorites during conversations'
        ],
        scientificBasis: 'Beukelman & Mirenda (2013) emphasize that operational competence is prerequisite to effective AAC use and must be systematically taught.',
        estimatedWeeks: 6,
        prerequisites: ['Basic touch/tap skills', 'Visual scanning abilities'],
      ),

      AACLearningGoal(
        id: 'op_symbol_search',
        title: 'Search and Find Symbols',
        description: 'Locate needed symbols efficiently across the system',
        category: GoalCategory.operational,
        difficulty: DifficultyLevel.intermediate,
        visualCue: '🔍',
        objectives: [
          'Use search function effectively',
          'Predict symbol locations',
          'Use category organization',
          'Create personal symbol collections'
        ],
        activities: [
          'Symbol scavenger hunts',
          'Category sorting games',
          'Speed symbol finding',
          'Personal favorites setup'
        ],
        examples: [
          'Finding "elephant" in Animals category',
          'Searching for "birthday" in Events',
          'Locating "hungry" in Feelings',
          'Finding "playground" in Places'
        ],
        scientificBasis: 'Research by Wilkinson & Hennig (2007) shows that efficient symbol location skills directly impact communication rate and user satisfaction with AAC.',
        estimatedWeeks: 8,
        prerequisites: ['Basic navigation skills', 'Category understanding'],
      ),

      AACLearningGoal(
        id: 'op_message_building',
        title: 'Build Multi-Symbol Messages',
        description: 'Combine multiple symbols to create meaningful sentences',
        category: GoalCategory.operational,
        difficulty: DifficultyLevel.advanced,
        visualCue: '🧩',
        objectives: [
          'Combine 3+ symbols meaningfully',
          'Use proper word order',
          'Edit and revise messages',
          'Use punctuation symbols'
        ],
        activities: [
          'Sentence building practice',
          'Story creation with symbols',
          'Message editing exercises',
          'Conversation building games'
        ],
        examples: [
          '"I want big red ball"',
          '"Can you help me please"',
          '"I feel very happy today"',
          '"Let\'s go to the park together"'
        ],
        scientificBasis: 'Syntactic development research by Sutton et al. (2010) demonstrates that multi-symbol message construction follows predictable developmental patterns in AAC users.',
        estimatedWeeks: 12,
        prerequisites: ['2-symbol combinations', 'Basic grammar understanding'],
      ),
    ];
  }

  static List<AACLearningGoal> getSocialCommunicationGoals() {
    return [
      AACLearningGoal(
        id: 'soc_turn_taking',
        title: 'Take Turns in Conversation',
        description: 'Engage in back-and-forth communication exchanges',
        category: GoalCategory.socialCommunication,
        difficulty: DifficultyLevel.intermediate,
        visualCue: '🔄',
        objectives: [
          'Wait for partner\'s response',
          'Respond appropriately to questions',
          'Add new information to conversation',
          'Signal when finished speaking'
        ],
        activities: [
          'Structured conversation practice',
          'Question-answer games',
          'Story-telling turn-taking',
          'Interview role-playing'
        ],
        examples: [
          'Answering "How are you?" then asking back',
          'Sharing information then listening',
          'Asking follow-up questions',
          'Taking turns describing pictures'
        ],
        scientificBasis: 'Social communication research by Prizant & Wetherby (1998) shows that turn-taking skills are fundamental for meaningful social interactions in children with ASD.',
        estimatedWeeks: 10,
        prerequisites: ['Basic responding skills', '2-symbol combinations'],
      ),

      AACLearningGoal(
        id: 'soc_attention',
        title: 'Gain and Direct Attention',
        description: 'Use AAC to get others\' attention and direct it to objects or events',
        category: GoalCategory.socialCommunication,
        difficulty: DifficultyLevel.beginner,
        visualCue: '👀',
        objectives: [
          'Use "Look" to direct attention',
          'Use "Listen" for auditory attention',
          'Point while using AAC',
          'Make eye contact when communicating'
        ],
        activities: [
          'Attention-getting practice',
          'Show-and-tell activities',
          'Joint attention games',
          'Pointing and naming exercises'
        ],
        examples: [
          '"Look at me" + pointing to self',
          '"Look" + "airplane" when seeing planes',
          '"Listen" + "music" for favorite songs',
          '"See" + "cat" when spotting animals'
        ],
        scientificBasis: 'Joint attention research by Mundy et al. (2003) demonstrates that attention-directing skills are crucial for social communication development in children with ASD.',
        estimatedWeeks: 5,
        prerequisites: ['Basic symbol recognition', 'Understanding of pointing'],
      ),

      AACLearningGoal(
        id: 'soc_sharing',
        title: 'Share Experiences and Information',
        description: 'Tell others about events, experiences, and personal interests',
        category: GoalCategory.socialCommunication,
        difficulty: DifficultyLevel.advanced,
        visualCue: '📢',
        objectives: [
          'Share past experiences',
          'Describe current activities',
          'Express personal preferences',
          'Tell simple stories'
        ],
        activities: [
          'Daily experience sharing',
          'Weekend story telling',
          'Preference surveys',
          'Photo-supported narratives'
        ],
        examples: [
          '"I went" + "swimming" + "yesterday"',
          '"I like" + "pizza" + "very much"',
          '"We saw" + "elephants" + "at zoo"',
          '"My favorite" + "color" + "is blue"'
        ],
        scientificBasis: 'Narrative development research by McCabe et al. (2013) shows that experience sharing builds social connections and language complexity in AAC users.',
        estimatedWeeks: 16,
        prerequisites: ['Multi-symbol combinations', 'Sequencing skills'],
      ),
    ];
  }
}
