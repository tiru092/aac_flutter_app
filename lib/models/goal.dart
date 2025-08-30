enum GoalFrequency {
  weekly,
  biweekly,
  monthly,
}

enum GoalCategory {
  communication,
  social,
  dailyLiving,
  learning,
  emotional,
  routine,
}

class Goal {
  final String id;
  final String title;
  final String description;
  final DateTime targetDate;
  final DateTime startDate;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final GoalCategory category;
  final GoalFrequency frequency;
  final int priority; // 1-5, where 5 is highest priority
  final int currentProgress; // For tracking progress (0-100)
  final int targetValue; // Target value for the goal (e.g., 5 for "learn 5 words")

  Goal({
    required this.id,
    required this.title,
    required this.description,
    required this.targetDate,
    DateTime? startDate,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
    this.category = GoalCategory.communication,
    this.frequency = GoalFrequency.weekly,
    this.priority = 3,
    this.currentProgress = 0,
    this.targetValue = 1,
  }) : startDate = startDate ?? DateTime.now();

  // Helper methods
  String get categoryDisplayName {
    switch (category) {
      case GoalCategory.communication:
        return 'Communication';
      case GoalCategory.social:
        return 'Social';
      case GoalCategory.dailyLiving:
        return 'Daily Living';
      case GoalCategory.learning:
        return 'Learning';
      case GoalCategory.emotional:
        return 'Emotional';
      case GoalCategory.routine:
        return 'Routine';
    }
  }

  String get frequencyDisplayName {
    switch (frequency) {
      case GoalFrequency.weekly:
        return 'Weekly';
      case GoalFrequency.biweekly:
        return 'Bi-weekly';
      case GoalFrequency.monthly:
        return 'Monthly';
    }
  }

  String get priorityDisplayName {
    switch (priority) {
      case 1:
        return 'Very Low';
      case 2:
        return 'Low';
      case 3:
        return 'Medium';
      case 4:
        return 'High';
      case 5:
        return 'Very High';
      default:
        return 'Medium';
    }
  }

  int get progressPercentage {
    if (targetValue <= 0) return 0;
    return ((currentProgress / targetValue) * 100).clamp(0, 100).round();
  }

  bool get isOverdue {
    return !isCompleted && DateTime.now().isAfter(targetDate);
  }

  int get daysRemaining {
    if (isCompleted) return 0;
    return targetDate.difference(DateTime.now()).inDays;
  }

  int get priorityColor {
    switch (priority) {
      case 1:
        return 0xFFA0AEC0; // Gray
      case 2:
        return 0xFF48BB78; // Green
      case 3:
        return 0xFF4299E1; // Blue
      case 4:
        return 0xFFED8936; // Orange
      case 5:
        return 0xFFE53E3E; // Red
      default:
        return 0xFF4299E1; // Blue
    }
  }

  // Convert Goal to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'targetDate': targetDate.toIso8601String(),
      'startDate': startDate.toIso8601String(),
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'category': category.name,
      'frequency': frequency.name,
      'priority': priority,
      'currentProgress': currentProgress,
      'targetValue': targetValue,
    };
  }

  // Create Goal from Map
  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      targetDate: DateTime.parse(map['targetDate']),
      startDate: map['startDate'] != null ? DateTime.parse(map['startDate']) : null,
      isCompleted: map['isCompleted'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      category: GoalCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => GoalCategory.communication,
      ),
      frequency: GoalFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
        orElse: () => GoalFrequency.weekly,
      ),
      priority: map['priority'] ?? 3,
      currentProgress: map['currentProgress'] ?? 0,
      targetValue: map['targetValue'] ?? 1,
    );
  }

  // Copy with method for immutability
  Goal copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? targetDate,
    DateTime? startDate,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    GoalCategory? category,
    GoalFrequency? frequency,
    int? priority,
    int? currentProgress,
    int? targetValue,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetDate: targetDate ?? this.targetDate,
      startDate: startDate ?? this.startDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      priority: priority ?? this.priority,
      currentProgress: currentProgress ?? this.currentProgress,
      targetValue: targetValue ?? this.targetValue,
    );
  }



  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Goal && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Goal(id: $id, title: $title, isCompleted: $isCompleted)';
  }
}

// Extension for GoalCategory to add display name
extension GoalCategoryExtension on GoalCategory {
  String get displayName {
    switch (this) {
      case GoalCategory.communication:
        return 'Communication';
      case GoalCategory.social:
        return 'Social';
      case GoalCategory.dailyLiving:
        return 'Daily Living';
      case GoalCategory.learning:
        return 'Learning';
      case GoalCategory.emotional:
        return 'Emotional';
      case GoalCategory.routine:
        return 'Routine';
    }
  }
}
