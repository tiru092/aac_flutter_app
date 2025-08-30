import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import '../models/goal.dart';
import '../utils/aac_helper.dart';

class GoalService {
  static const String _goalsKey = 'user_goals';
  static const String _goalCategoriesKey = 'goal_categories';

  // Get all goals for the current user
  static Future<List<Goal>> getUserGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final goalsJson = prefs.getStringList(_goalsKey);
      
      if (goalsJson == null || goalsJson.isEmpty) {
        return [];
      }
      
      return goalsJson.map((json) {
        try {
          final map = jsonDecode(json);
          return Goal.fromMap(map);
        } catch (e) {
          print('Error parsing goal JSON: $e');
          return null;
        }
      }).whereType<Goal>().toList();
    } catch (e) {
      print('Error getting user goals: $e');
      throw AACException('Failed to load goals');
    }
  }

  // Save a goal
  static Future<void> saveGoal(Goal goal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingGoals = await getUserGoals();
      
      // Remove existing goal with same ID if it exists
      final filteredGoals = existingGoals.where((g) => g.id != goal.id).toList();
      
      // Add the new/updated goal
      filteredGoals.add(goal);
      
      // Save all goals
      final goalsJson = filteredGoals.map((g) => jsonEncode(g.toMap())).toList();
      await prefs.setStringList(_goalsKey, goalsJson);
    } catch (e) {
      print('Error saving goal: $e');
      throw AACException('Failed to save goal');
    }
  }

  // Delete a goal
  static Future<void> deleteGoal(String goalId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingGoals = await getUserGoals();
      
      // Remove the goal
      final filteredGoals = existingGoals.where((g) => g.id != goalId).toList();
      
      // Save updated list
      final goalsJson = filteredGoals.map((g) => jsonEncode(g.toMap())).toList();
      await prefs.setStringList(_goalsKey, goalsJson);
    } catch (e) {
      print('Error deleting goal: $e');
      throw AACException('Failed to delete goal');
    }
  }

  // Mark goal as completed
  static Future<void> completeGoal(String goalId) async {
    try {
      final goals = await getUserGoals();
      final goal = goals.firstWhere((g) => g.id == goalId);
      
      final updatedGoal = goal.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
      );
      
      await saveGoal(updatedGoal);
    } catch (e) {
      print('Error completing goal: $e');
      throw AACException('Failed to complete goal');
    }
  }

  // Mark goal as incomplete
  static Future<void> uncompleteGoal(String goalId) async {
    try {
      final goals = await getUserGoals();
      final goal = goals.firstWhere((g) => g.id == goalId);
      
      final updatedGoal = goal.copyWith(
        isCompleted: false,
        completedAt: null,
      );
      
      await saveGoal(updatedGoal);
    } catch (e) {
      print('Error uncompleting goal: $e');
      throw AACException('Failed to uncomplete goal');
    }
  }

  // Get goal categories
  static Future<List<String>> getGoalCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categoriesJson = prefs.getStringList(_goalCategoriesKey);
      
      if (categoriesJson == null || categoriesJson.isEmpty) {
        return ['Communication', 'Daily Living', 'Social', 'Education', 'Health', 'General'];
      }
      
      return categoriesJson;
    } catch (e) {
      print('Error getting goal categories: $e');
      return ['Communication', 'Daily Living', 'Social', 'Education', 'Health', 'General'];
    }
  }

  // Add a new category
  static Future<void> addGoalCategory(String category) async {
    try {
      final categories = await getGoalCategories();
      if (!categories.contains(category)) {
        categories.add(category);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_goalCategoriesKey, categories);
      }
    } catch (e) {
      print('Error adding goal category: $e');
      throw AACException('Failed to add category');
    }
  }

  // Get goals by category
  static Future<List<Goal>> getGoalsByCategory(String category) async {
    try {
      final goals = await getUserGoals();
      return goals.where((goal) => goal.category == category).toList();
    } catch (e) {
      print('Error getting goals by category: $e');
      throw AACException('Failed to get goals by category');
    }
  }

  // Get active goals (not completed)
  static Future<List<Goal>> getActiveGoals() async {
    try {
      final goals = await getUserGoals();
      return goals.where((goal) => !goal.isCompleted).toList();
    } catch (e) {
      print('Error getting active goals: $e');
      throw AACException('Failed to get active goals');
    }
  }

  // Get completed goals
  static Future<List<Goal>> getCompletedGoals() async {
    try {
      final goals = await getUserGoals();
      return goals.where((goal) => goal.isCompleted).toList();
    } catch (e) {
      print('Error getting completed goals: $e');
      throw AACException('Failed to get completed goals');
    }
  }

  // Get overdue goals
  static Future<List<Goal>> getOverdueGoals() async {
    try {
      final goals = await getUserGoals();
      return goals.where((goal) => goal.isOverdue).toList();
    } catch (e) {
      print('Error getting overdue goals: $e');
      throw AACException('Failed to get overdue goals');
    }
  }

  // Get goals due today
  static Future<List<Goal>> getGoalsDueToday() async {
    try {
      final goals = await getUserGoals();
      final today = DateTime.now();
      return goals.where((goal) => 
        !goal.isCompleted &&
        goal.targetDate.year == today.year &&
        goal.targetDate.month == today.month &&
        goal.targetDate.day == today.day
      ).toList();
    } catch (e) {
      print('Error getting goals due today: $e');
      throw AACException('Failed to get goals due today');
    }
  }

  // Get goals due this week
  static Future<List<Goal>> getGoalsDueThisWeek() async {
    try {
      final goals = await getUserGoals();
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      
      return goals.where((goal) => 
        !goal.isCompleted &&
        goal.targetDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        goal.targetDate.isBefore(endOfWeek.add(const Duration(days: 1)))
      ).toList();
    } catch (e) {
      print('Error getting goals due this week: $e');
      throw AACException('Failed to get goals due this week');
    }
  }

  // Generate a unique goal ID
  static String generateGoalId() {
    return 'goal_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(6)}';
  }

  // Generate random string for IDs
  static String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      length, (_) => chars.codeUnitAt(random.nextInt(chars.length))
    ));
  }

  // Clear all goals (for testing/debugging)
  static Future<void> clearAllGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_goalsKey);
    } catch (e) {
      print('Error clearing goals: $e');
      throw AACException('Failed to clear goals');
    }
  }
}
