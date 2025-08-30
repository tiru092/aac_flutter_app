class Practice {
  final String id;
  final String name;
  final String description;
  final String type; // 'matching', 'selection', 'counting', etc.
  final Map<String, dynamic> data; // Practice-specific data

  Practice({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.data,
  });
}

class Goal {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final String iconEmoji;
  final int colorValue;
  final List<Practice> practices;
  final int completedPractices;
  final int totalStars;

  Goal({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.iconEmoji,
    required this.colorValue,
    required this.practices,
    this.completedPractices = 0,
    this.totalStars = 0,
  });

  double get progress => practices.isEmpty ? 0.0 : completedPractices / practices.length;
}

class GoalsData {
  static List<Goal> getAllGoals() {
    return [
      Goal(
        id: 'colors',
        name: 'Match Colors',
        description: 'Learn and match different colors',
        iconPath: 'assets/icons/colors.png',
        iconEmoji: '🌈',
        colorValue: 0xFFFF6B6B,
        practices: _getColorPractices(),
        totalStars: 45,
      ),
      Goal(
        id: 'shapes',
        name: 'Match Shapes',
        description: 'Identify and match basic shapes',
        iconPath: 'assets/icons/shapes.png',
        iconEmoji: '🔺',
        colorValue: 0xFF4ECDC4,
        practices: _getShapePractices(),
        totalStars: 38,
      ),
      Goal(
        id: 'animals',
        name: 'Animal Sounds',
        description: 'Match animals with their sounds',
        iconPath: 'assets/icons/animals.png',
        iconEmoji: '🐱',
        colorValue: 0xFFFFE66D,
        practices: _getAnimalPractices(),
        totalStars: 52,
      ),
      Goal(
        id: 'routines',
        name: 'Daily Routines',
        description: 'Practice daily life activities',
        iconPath: 'assets/icons/routines.png',
        iconEmoji: '🦷',
        colorValue: 0xFF95E1D3,
        practices: _getRoutinePractices(),
        totalStars: 41,
      ),
      Goal(
        id: 'emotions',
        name: 'Emotions',
        description: 'Identify different emotions',
        iconPath: 'assets/icons/emotions.png',
        iconEmoji: '😊',
        colorValue: 0xFFF38BA8,
        practices: _getEmotionPractices(),
        totalStars: 36,
      ),
      Goal(
        id: 'words',
        name: 'Word & Picture',
        description: 'Match words with pictures',
        iconPath: 'assets/icons/words.png',
        iconEmoji: '📝',
        colorValue: 0xFFA8DADC,
        practices: _getWordPractices(),
        totalStars: 49,
      ),
      Goal(
        id: 'yesno',
        name: 'Yes/No Quiz',
        description: 'Answer fun yes/no questions',
        iconPath: 'assets/icons/quiz.png',
        iconEmoji: '✅',
        colorValue: 0xFFF1FAEE,
        practices: _getYesNoPractices(),
        totalStars: 33,
      ),
      Goal(
        id: 'counting',
        name: 'Counting',
        description: 'Count objects and match numbers',
        iconPath: 'assets/icons/numbers.png',
        iconEmoji: '🔢',
        colorValue: 0xFF457B9D,
        practices: _getCountingPractices(),
        totalStars: 47,
      ),
      Goal(
        id: 'memory',
        name: 'Memory Match',
        description: 'Find matching card pairs',
        iconPath: 'assets/icons/memory.png',
        iconEmoji: '🧠',
        colorValue: 0xFF9D4EDD,
        practices: _getMemoryPractices(),
        totalStars: 29,
      ),
      Goal(
        id: 'objects',
        name: 'Daily Objects',
        description: 'Match objects with their usage',
        iconPath: 'assets/icons/objects.png',
        iconEmoji: '🏠',
        colorValue: 0xFFFF8500,
        practices: _getObjectPractices(),
        totalStars: 44,
      ),
    ];
  }

  static List<Practice> _getColorPractices() {
    return List.generate(10, (index) => Practice(
      id: 'color_$index',
      name: 'Color Match ${index + 1}',
      description: 'Match the colors correctly',
      type: 'matching',
      data: {'colors': ['red', 'blue', 'green', 'yellow']},
    ));
  }

  static List<Practice> _getShapePractices() {
    return List.generate(10, (index) => Practice(
      id: 'shape_$index',
      name: 'Shape Match ${index + 1}',
      description: 'Identify and match shapes',
      type: 'matching',
      data: {'shapes': ['circle', 'square', 'triangle', 'rectangle']},
    ));
  }

  static List<Practice> _getAnimalPractices() {
    return List.generate(10, (index) => Practice(
      id: 'animal_$index',
      name: 'Animal Sound ${index + 1}',
      description: 'Match animal with its sound',
      type: 'audio_matching',
      data: {'animals': ['cat', 'dog', 'cow', 'bird']},
    ));
  }

  static List<Practice> _getRoutinePractices() {
    return List.generate(10, (index) => Practice(
      id: 'routine_$index',
      name: 'Daily Routine ${index + 1}',
      description: 'Practice daily activities',
      type: 'sequence',
      data: {'routines': ['brushing', 'washing', 'eating', 'sleeping']},
    ));
  }

  static List<Practice> _getEmotionPractices() {
    return List.generate(10, (index) => Practice(
      id: 'emotion_$index',
      name: 'Emotion ${index + 1}',
      description: 'Identify facial expressions',
      type: 'selection',
      data: {'emotions': ['happy', 'sad', 'angry', 'surprised']},
    ));
  }

  static List<Practice> _getWordPractices() {
    return List.generate(10, (index) => Practice(
      id: 'word_$index',
      name: 'Word Match ${index + 1}',
      description: 'Match words with pictures',
      type: 'word_picture',
      data: {'pairs': {'apple': 'fruit', 'car': 'vehicle', 'house': 'building'}},
    ));
  }

  static List<Practice> _getYesNoPractices() {
    return List.generate(10, (index) => Practice(
      id: 'yesno_$index',
      name: 'Yes/No ${index + 1}',
      description: 'Answer true or false questions',
      type: 'yes_no',
      data: {'questions': ['Is the sky blue?', 'Do fish fly?', 'Is ice cold?']},
    ));
  }

  static List<Practice> _getCountingPractices() {
    return List.generate(10, (index) => Practice(
      id: 'counting_$index',
      name: 'Count ${index + 1}',
      description: 'Count objects and match numbers',
      type: 'counting',
      data: {'range': [1, 10]},
    ));
  }

  static List<Practice> _getMemoryPractices() {
    return List.generate(10, (index) => Practice(
      id: 'memory_$index',
      name: 'Memory Level ${index + 1}',
      description: 'Find matching card pairs',
      type: 'memory_cards',
      data: {'pairs': (index + 1) * 2, 'difficulty': index < 3 ? 'easy' : index < 7 ? 'medium' : 'hard'},
    ));
  }

  static List<Practice> _getObjectPractices() {
    return List.generate(10, (index) => Practice(
      id: 'object_$index',
      name: 'Daily Object ${index + 1}',
      description: 'Match objects with their uses',
      type: 'object_usage',
      data: {'objects': ['spoon', 'toothbrush', 'pillow', 'book']},
    ));
  }
}
