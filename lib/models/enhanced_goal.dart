import 'package:flutter/material.dart';
import '../models/goal.dart';

/// Enhanced goal with ARASAAC pictogram and visual elements
class EnhancedGoal extends Goal {
  final int? arasaacPictogramId;
  final String mascotMessage;
  final Color cardColor;
  final String progressIcon;
  final List<String> celebrationStickers;
  final String completionSound;

  EnhancedGoal({
    required super.id,
    required super.title,
    required super.description,
    required super.targetDate,
    super.startDate,
    super.isCompleted = false,
    required super.createdAt,
    super.completedAt,
    super.category = GoalCategory.communication,
    super.frequency = GoalFrequency.weekly,
    super.priority = 3,
    super.currentProgress = 0,
    super.targetValue = 1,
    this.arasaacPictogramId,
    this.mascotMessage = '',
    this.cardColor = const Color(0xFF4ECDC4),
    this.progressIcon = '🌈',
    this.celebrationStickers = const ['🌟', '🎉', '🏆'],
    this.completionSound = 'celebration',
  });

  /// Get the appropriate progress icon based on frequency
  String get frequencyProgressIcon {
    switch (frequency) {
      case GoalFrequency.weekly:
        return '🌈'; // Rainbow path
      case GoalFrequency.biweekly:
        return '🌸'; // Flower growing
      case GoalFrequency.monthly:
        return '🧩'; // Puzzle pieces
    }
  }

  /// Get mascot encouragement message based on progress
  String get mascotEncouragement {
    final progress = progressPercentage;
    if (isCompleted) {
      return "🎉 Amazing! You completed '$title'! You're a superstar! 🌟";
    } else if (progress >= 75) {
      return "🚀 Wow! You're almost there! Keep going, champion! 💪";
    } else if (progress >= 50) {
      return "⭐ Great progress on '$title'! You're doing fantastic! 🎈";
    } else if (progress >= 25) {
      return "🌱 Nice start! Every step counts. You've got this! 😊";
    } else {
      return "🌟 Ready to work on '$title'? Let's make it fun! 🎯";
    }
  }

  /// Get category-specific card colors
  Color get categoryCardColor {
    switch (category) {
      case GoalCategory.communication:
        return const Color(0xFF74B9FF); // Bright blue
      case GoalCategory.social:
        return const Color(0xFF6C5CE7); // Purple
      case GoalCategory.dailyLiving:
        return const Color(0xFF00B894); // Green
      case GoalCategory.learning:
        return const Color(0xFFE17055); // Orange
      case GoalCategory.emotional:
        return const Color(0xFFFF7675); // Pink
      case GoalCategory.routine:
        return const Color(0xFFFAB1A0); // Peach
    }
  }

  /// Get completion celebration stickers
  List<String> get completionCelebration {
    switch (category) {
      case GoalCategory.communication:
        return ['💬', '🗣️', '🎙️', '📢', '🎉'];
      case GoalCategory.social:
        return ['👫', '🤝', '❤️', '🎈', '🌟'];
      case GoalCategory.dailyLiving:
        return ['🏠', '✨', '🌈', '⭐', '🎯'];
      case GoalCategory.learning:
        return ['📚', '🧠', '💡', '🏆', '🎓'];
      case GoalCategory.emotional:
        return ['😊', '💖', '🌻', '🦋', '🌈'];
      case GoalCategory.routine:
        return ['⏰', '📅', '✅', '🎊', '💫'];
    }
  }

  /// Create EnhancedGoal from regular Goal
  factory EnhancedGoal.fromGoal(Goal goal, {int? arasaacId}) {
    return EnhancedGoal(
      id: goal.id,
      title: goal.title,
      description: goal.description,
      targetDate: goal.targetDate,
      startDate: goal.startDate,
      isCompleted: goal.isCompleted,
      createdAt: goal.createdAt,
      completedAt: goal.completedAt,
      category: goal.category,
      frequency: goal.frequency,
      priority: goal.priority,
      currentProgress: goal.currentProgress,
      targetValue: goal.targetValue,
      arasaacPictogramId: arasaacId,
    );
  }

  /// Convert to regular Goal for storage
  Goal toGoal() {
    return Goal(
      id: id,
      title: title,
      description: description,
      targetDate: targetDate,
      startDate: startDate,
      isCompleted: isCompleted,
      createdAt: createdAt,
      completedAt: completedAt,
      category: category,
      frequency: frequency,
      priority: priority,
      currentProgress: currentProgress,
      targetValue: targetValue,
    );
  }

  @override
  EnhancedGoal copyWith({
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
    int? arasaacPictogramId,
    String? mascotMessage,
    Color? cardColor,
    String? progressIcon,
    List<String>? celebrationStickers,
    String? completionSound,
  }) {
    return EnhancedGoal(
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
      arasaacPictogramId: arasaacPictogramId ?? this.arasaacPictogramId,
      mascotMessage: mascotMessage ?? this.mascotMessage,
      cardColor: cardColor ?? this.cardColor,
      progressIcon: progressIcon ?? this.progressIcon,
      celebrationStickers: celebrationStickers ?? this.celebrationStickers,
      completionSound: completionSound ?? this.completionSound,
    );
  }
}
