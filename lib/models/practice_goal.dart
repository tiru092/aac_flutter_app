class PracticeGoal {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final String iconEmoji;
  final List<PracticeActivity> activities;
  final int completedActivities;
  final int totalStars;
  final String color;

  PracticeGoal({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.iconEmoji,
    required this.activities,
    this.completedActivities = 0,
    this.totalStars = 0,
    required this.color,
  });

  double get progress => activities.isEmpty ? 0.0 : completedActivities / activities.length;
  
  PracticeGoal copyWith({
    String? id,
    String? name,
    String? description,
    String? iconPath,
    String? iconEmoji,
    List<PracticeActivity>? activities,
    int? completedActivities,
    int? totalStars,
    String? color,
  }) {
    return PracticeGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconPath: iconPath ?? this.iconPath,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      activities: activities ?? this.activities,
      completedActivities: completedActivities ?? this.completedActivities,
      totalStars: totalStars ?? this.totalStars,
      color: color ?? this.color,
    );
  }
}

class PracticeActivity {
  final String id;
  final String name;
  final String description;
  final PracticeType type;
  final List<PracticeItem> items;
  final bool isCompleted;
  final int starsEarned;

  PracticeActivity({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.items,
    this.isCompleted = false,
    this.starsEarned = 0,
  });

  PracticeActivity copyWith({
    String? id,
    String? name,
    String? description,
    PracticeType? type,
    List<PracticeItem>? items,
    bool? isCompleted,
    int? starsEarned,
  }) {
    return PracticeActivity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      items: items ?? this.items,
      isCompleted: isCompleted ?? this.isCompleted,
      starsEarned: starsEarned ?? this.starsEarned,
    );
  }
}

enum PracticeType {
  matchColors,
  matchShapes,
  animalSounds,
  dailyRoutines,
  emotions,
  wordPictureMatch,
  yesNoQuiz,
  counting,
  memoryMatch,
  dailyObjects,
}

class PracticeItem {
  final String id;
  final String question;
  final String? imagePath;
  final String? soundPath;
  final List<String> options;
  final String correctAnswer;
  final String? emoji;

  PracticeItem({
    required this.id,
    required this.question,
    this.imagePath,
    this.soundPath,
    required this.options,
    required this.correctAnswer,
    this.emoji,
  });
}

// Static data for the 10 practice goals
class PracticeGoalsData {
  static List<PracticeGoal> getAllGoals() {
    return [
      PracticeGoal(
        id: 'colors',
        name: 'Match Colors',
        description: 'Learn and match different colors',
        iconPath: 'assets/icons/colors.png',
        iconEmoji: '🌈',
        color: 'FF6B6B',
        activities: _getColorActivities(),
      ),
      PracticeGoal(
        id: 'shapes',
        name: 'Match Shapes',
        description: 'Identify and match basic shapes',
        iconPath: 'assets/icons/shapes.png',
        iconEmoji: '🔺',
        color: '4ECDC4',
        activities: _getShapeActivities(),
      ),
      PracticeGoal(
        id: 'animals',
        name: 'Animal Sounds',
        description: 'Match animals with their sounds',
        iconPath: 'assets/icons/animals.png',
        iconEmoji: '🐱',
        color: 'FFE66D',
        activities: _getAnimalActivities(),
      ),
      PracticeGoal(
        id: 'routines',
        name: 'Daily Routines',
        description: 'Practice daily life activities',
        iconPath: 'assets/icons/routines.png',
        iconEmoji: '🦷',
        color: '95E1D3',
        activities: _getRoutineActivities(),
      ),
      PracticeGoal(
        id: 'emotions',
        name: 'Emotions',
        description: 'Identify different emotions',
        iconPath: 'assets/icons/emotions.png',
        iconEmoji: '😊',
        color: 'F38BA8',
        activities: _getEmotionActivities(),
      ),
      PracticeGoal(
        id: 'words',
        name: 'Word & Picture',
        description: 'Match words with pictures',
        iconPath: 'assets/icons/words.png',
        iconEmoji: '📝',
        color: 'A8DADC',
        activities: _getWordActivities(),
      ),
      PracticeGoal(
        id: 'yesno',
        name: 'Yes/No Quiz',
        description: 'Answer fun yes/no questions',
        iconPath: 'assets/icons/quiz.png',
        iconEmoji: '✅',
        color: 'F1FAEE',
        activities: _getYesNoActivities(),
      ),
      PracticeGoal(
        id: 'counting',
        name: 'Counting',
        description: 'Count objects and match numbers',
        iconPath: 'assets/icons/numbers.png',
        iconEmoji: '🔢',
        color: '457B9D',
        activities: _getCountingActivities(),
      ),
      PracticeGoal(
        id: 'memory',
        name: 'Memory Match',
        description: 'Find matching pairs of cards',
        iconPath: 'assets/icons/memory.png',
        iconEmoji: '🃏',
        color: 'E63946',
        activities: _getMemoryActivities(),
      ),
      PracticeGoal(
        id: 'objects',
        name: 'Daily Objects',
        description: 'Match objects with their uses',
        iconPath: 'assets/icons/objects.png',
        iconEmoji: '🏠',
        color: '2A9D8F',
        activities: _getObjectActivities(),
      ),
    ];
  }

  static List<PracticeActivity> _getColorActivities() {
    final colors = ['Red', 'Blue', 'Green', 'Yellow', 'Orange', 'Purple', 'Pink', 'Brown', 'Black', 'White'];
    final colorEmojis = ['🔴', '🔵', '🟢', '🟡', '🟠', '🟣', '🩷', '🟤', '⚫', '⚪'];
    
    return List.generate(10, (index) => PracticeActivity(
      id: 'color_$index',
      name: 'Match ${colors[index]}',
      description: 'Find the ${colors[index].toLowerCase()} object',
      type: PracticeType.matchColors,
      items: [
        PracticeItem(
          id: 'color_item_$index',
          question: 'Which one is ${colors[index].toLowerCase()}?',
          emoji: colorEmojis[index],
          options: [colors[index], colors[(index + 1) % colors.length], colors[(index + 2) % colors.length]],
          correctAnswer: colors[index],
        ),
      ],
    ));
  }

  static List<PracticeActivity> _getShapeActivities() {
    final shapes = ['Circle', 'Square', 'Triangle', 'Rectangle', 'Star', 'Heart', 'Diamond', 'Oval', 'Pentagon', 'Hexagon'];
    final shapeEmojis = ['⭕', '🟦', '🔺', '🟫', '⭐', '❤️', '💎', '🥚', '🛑', '⬡'];
    
    return List.generate(10, (index) => PracticeActivity(
      id: 'shape_$index',
      name: 'Match ${shapes[index]}',
      description: 'Find the ${shapes[index].toLowerCase()} shape',
      type: PracticeType.matchShapes,
      items: [
        PracticeItem(
          id: 'shape_item_$index',
          question: 'Which shape is a ${shapes[index].toLowerCase()}?',
          emoji: shapeEmojis[index],
          options: [shapes[index], shapes[(index + 1) % shapes.length], shapes[(index + 2) % shapes.length]],
          correctAnswer: shapes[index],
        ),
      ],
    ));
  }

  static List<PracticeActivity> _getAnimalActivities() {
    final animals = ['Cat', 'Dog', 'Cow', 'Duck', 'Lion', 'Elephant', 'Bird', 'Frog', 'Horse', 'Pig'];
    final animalEmojis = ['🐱', '🐶', '🐮', '🦆', '🦁', '🐘', '🐦', '🐸', '🐴', '🐷'];
    final sounds = ['Meow', 'Woof', 'Moo', 'Quack', 'Roar', 'Trumpet', 'Chirp', 'Ribbit', 'Neigh', 'Oink'];
    
    return List.generate(10, (index) => PracticeActivity(
      id: 'animal_$index',
      name: '${animals[index]} Sound',
      description: 'What sound does a ${animals[index].toLowerCase()} make?',
      type: PracticeType.animalSounds,
      items: [
        PracticeItem(
          id: 'animal_item_$index',
          question: 'What sound does a ${animals[index].toLowerCase()} make?',
          emoji: animalEmojis[index],
          soundPath: 'assets/sounds/${animals[index].toLowerCase()}.mp3',
          options: [sounds[index], sounds[(index + 1) % sounds.length], sounds[(index + 2) % sounds.length]],
          correctAnswer: sounds[index],
        ),
      ],
    ));
  }

  static List<PracticeActivity> _getRoutineActivities() {
    final routines = ['Brush Teeth', 'Wash Hands', 'Eat Food', 'Sleep', 'Take Bath', 'Get Dressed', 'Comb Hair', 'Drink Water', 'Exercise', 'Read Book'];
    final routineEmojis = ['🦷', '🧼', '🍽️', '😴', '🛁', '👕', '🪮', '💧', '🏃', '📚'];
    
    return List.generate(10, (index) => PracticeActivity(
      id: 'routine_$index',
      name: routines[index],
      description: 'Practice ${routines[index].toLowerCase()}',
      type: PracticeType.dailyRoutines,
      items: [
        PracticeItem(
          id: 'routine_item_$index',
          question: 'When do you ${routines[index].toLowerCase()}?',
          emoji: routineEmojis[index],
          options: ['Morning', 'Afternoon', 'Evening'],
          correctAnswer: index < 4 ? 'Morning' : index < 7 ? 'Afternoon' : 'Evening',
        ),
      ],
    ));
  }

  static List<PracticeActivity> _getEmotionActivities() {
    final emotions = ['Happy', 'Sad', 'Angry', 'Excited', 'Scared', 'Surprised', 'Tired', 'Calm', 'Confused', 'Proud'];
    final emotionEmojis = ['😊', '😢', '😠', '🤩', '😨', '😲', '😴', '😌', '😕', '😊'];
    
    return List.generate(10, (index) => PracticeActivity(
      id: 'emotion_$index',
      name: '${emotions[index]} Face',
      description: 'Identify the ${emotions[index].toLowerCase()} emotion',
      type: PracticeType.emotions,
      items: [
        PracticeItem(
          id: 'emotion_item_$index',
          question: 'How does this person feel?',
          emoji: emotionEmojis[index],
          options: [emotions[index], emotions[(index + 1) % emotions.length], emotions[(index + 2) % emotions.length]],
          correctAnswer: emotions[index],
        ),
      ],
    ));
  }

  static List<PracticeActivity> _getWordActivities() {
    final words = ['Apple', 'Ball', 'Car', 'Dog', 'Elephant', 'Fish', 'Grapes', 'House', 'Ice Cream', 'Jump'];
    final wordEmojis = ['🍎', '⚽', '🚗', '🐶', '🐘', '🐠', '🍇', '🏠', '🍦', '🦘'];
    
    return List.generate(10, (index) => PracticeActivity(
      id: 'word_$index',
      name: 'Match ${words[index]}',
      description: 'Match the word ${words[index].toLowerCase()} with its picture',
      type: PracticeType.wordPictureMatch,
      items: [
        PracticeItem(
          id: 'word_item_$index',
          question: 'Which picture matches the word "${words[index]}"?',
          emoji: wordEmojis[index],
          options: [words[index], words[(index + 1) % words.length], words[(index + 2) % words.length]],
          correctAnswer: words[index],
        ),
      ],
    ));
  }

  static List<PracticeActivity> _getYesNoActivities() {
    final questions = [
      'Is the sun yellow?',
      'Do fish live in water?',
      'Can cats fly?',
      'Is ice cold?',
      'Do elephants have wings?',
      'Is grass green?',
      'Can you eat rocks?',
      'Do birds have feathers?',
      'Is fire hot?',
      'Can dogs meow?',
    ];
    final answers = ['Yes', 'Yes', 'No', 'Yes', 'No', 'Yes', 'No', 'Yes', 'Yes', 'No'];
    final emojis = ['☀️', '🐠', '🐱', '🧊', '🐘', '🌱', '🪨', '🐦', '🔥', '🐶'];
    
    return List.generate(10, (index) => PracticeActivity(
      id: 'yesno_$index',
      name: 'Question ${index + 1}',
      description: 'Answer the yes/no question',
      type: PracticeType.yesNoQuiz,
      items: [
        PracticeItem(
          id: 'yesno_item_$index',
          question: questions[index],
          emoji: emojis[index],
          options: ['Yes', 'No'],
          correctAnswer: answers[index],
        ),
      ],
    ));
  }

  static List<PracticeActivity> _getCountingActivities() {
    return List.generate(10, (index) => PracticeActivity(
      id: 'count_$index',
      name: 'Count ${index + 1}',
      description: 'Count objects and find the right number',
      type: PracticeType.counting,
      items: [
        PracticeItem(
          id: 'count_item_$index',
          question: 'How many objects do you see?',
          emoji: '${index + 1}️⃣',
          options: ['${index + 1}', '${index + 2}', '${index}'],
          correctAnswer: '${index + 1}',
        ),
      ],
    ));
  }

  static List<PracticeActivity> _getMemoryActivities() {
    final themes = ['Animals', 'Fruits', 'Colors', 'Shapes', 'Numbers', 'Letters', 'Toys', 'Food', 'Transportation', 'Nature'];
    final themeEmojis = ['🐱', '🍎', '🌈', '⭕', '1️⃣', 'A️⃣', '🧸', '🍕', '🚗', '🌳'];
    
    return List.generate(10, (index) => PracticeActivity(
      id: 'memory_$index',
      name: '${themes[index]} Memory',
      description: 'Find matching pairs of ${themes[index].toLowerCase()}',
      type: PracticeType.memoryMatch,
      items: [
        PracticeItem(
          id: 'memory_item_$index',
          question: 'Find the matching pair',
          emoji: themeEmojis[index],
          options: ['Match 1', 'Match 2'],
          correctAnswer: 'Match 1',
        ),
      ],
    ));
  }

  static List<PracticeActivity> _getObjectActivities() {
    final objects = ['Spoon', 'Toothbrush', 'Bed', 'Chair', 'Cup', 'Book', 'Scissors', 'Umbrella', 'Key', 'Phone'];
    final uses = ['Eating', 'Brushing teeth', 'Sleeping', 'Sitting', 'Drinking', 'Reading', 'Cutting', 'Rain protection', 'Opening doors', 'Calling'];
    final objectEmojis = ['🥄', '🦷', '🛏️', '🪑', '☕', '📚', '✂️', '☂️', '🔑', '📱'];
    
    return List.generate(10, (index) => PracticeActivity(
      id: 'object_$index',
      name: '${objects[index]} Use',
      description: 'What do you use ${objects[index].toLowerCase()} for?',
      type: PracticeType.dailyObjects,
      items: [
        PracticeItem(
          id: 'object_item_$index',
          question: 'What do you use ${objects[index].toLowerCase()} for?',
          emoji: objectEmojis[index],
          options: [uses[index], uses[(index + 1) % uses.length], uses[(index + 2) % uses.length]],
          correctAnswer: uses[index],
        ),
      ],
    ));
  }
}
