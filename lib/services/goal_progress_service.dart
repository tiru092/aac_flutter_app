import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoalProgressService {
  static const String _goalProgressPrefix = 'goal_progress_';
  static const String _objectiveProgressPrefix = 'objective_progress_';
  static const String _completedGoalsKey = 'completed_goals';
  static const String _goalStartDatesKey = 'goal_start_dates';

  // Firebase Firestore collection names
  static const String _userGoalsCollection = 'user_goals';
  static const String _progressCollection = 'progress';

  /// Get goal progress percentage (0-100)
  static Future<int> getGoalProgress(String goalId) async {
    try {
      // Try to get from Firebase first if user is online
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection(_userGoalsCollection)
              .doc(user.uid)
              .collection(_progressCollection)
              .doc(goalId)
              .get();

          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            final progress = data['progress'] as int? ?? 0;
            
            // Update local storage for offline access
            await _saveProgressToLocal(goalId, progress);
            return progress;
          }
        } catch (e) {
          debugPrint('Error fetching from Firebase: $e');
        }
      }

      // Fallback to local storage
      return await _getProgressFromLocal(goalId);
    } catch (e) {
      debugPrint('Error getting goal progress: $e');
      return 0;
    }
  }

  /// Update goal progress percentage
  static Future<void> updateGoalProgress(String goalId, int progress) async {
    try {
      // Validate progress value
      progress = progress.clamp(0, 100);

      // Save to local storage first
      await _saveProgressToLocal(goalId, progress);

      // Mark goal as completed if progress is 100%
      if (progress >= 100) {
        await markGoalAsCompleted(goalId);
      }

      // Try to sync with Firebase if user is online
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection(_userGoalsCollection)
              .doc(user.uid)
              .collection(_progressCollection)
              .doc(goalId)
              .set({
            'progress': progress,
            'goalId': goalId,
            'lastUpdated': FieldValue.serverTimestamp(),
            'completedAt': progress >= 100 ? FieldValue.serverTimestamp() : null,
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Error syncing with Firebase: $e');
        }
      }
    } catch (e) {
      debugPrint('Error updating goal progress: $e');
    }
  }

  /// Get objective completion status
  static Future<List<bool>> getObjectiveProgress(String goalId) async {
    try {
      // Try to get from Firebase first if user is online
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection(_userGoalsCollection)
              .doc(user.uid)
              .collection(_progressCollection)
              .doc(goalId)
              .get();

          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            final objectives = data['objectives'] as List<dynamic>? ?? [];
            final result = objectives.map((obj) => obj as bool).toList();
            
            // Update local storage
            await _saveObjectiveProgressToLocal(goalId, result);
            return result;
          }
        } catch (e) {
          debugPrint('Error fetching objectives from Firebase: $e');
        }
      }

      // Fallback to local storage
      return await _getObjectiveProgressFromLocal(goalId);
    } catch (e) {
      debugPrint('Error getting objective progress: $e');
      return [];
    }
  }

  /// Update objective completion status
  static Future<void> updateObjectiveProgress(String goalId, List<bool> objectives) async {
    try {
      // Save to local storage first
      await _saveObjectiveProgressToLocal(goalId, objectives);

      // Try to sync with Firebase if user is online
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection(_userGoalsCollection)
              .doc(user.uid)
              .collection(_progressCollection)
              .doc(goalId)
              .set({
            'objectives': objectives,
            'goalId': goalId,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Error syncing objectives with Firebase: $e');
        }
      }
    } catch (e) {
      debugPrint('Error updating objective progress: $e');
    }
  }

  /// Mark a goal as completed
  static Future<void> markGoalAsCompleted(String goalId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get current completed goals
      final completedGoalsJson = prefs.getString(_completedGoalsKey) ?? '[]';
      final completedGoals = List<String>.from(json.decode(completedGoalsJson));
      
      // Add goal if not already completed
      if (!completedGoals.contains(goalId)) {
        completedGoals.add(goalId);
        await prefs.setString(_completedGoalsKey, json.encode(completedGoals));
        
        // Record completion date
        final now = DateTime.now().millisecondsSinceEpoch;
        await prefs.setInt('completed_date_$goalId', now);
      }

      // Sync with Firebase if online
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection(_userGoalsCollection)
              .doc(user.uid)
              .set({
            'completedGoals': completedGoals,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          await FirebaseFirestore.instance
              .collection(_userGoalsCollection)
              .doc(user.uid)
              .collection(_progressCollection)
              .doc(goalId)
              .set({
            'completed': true,
            'completedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Error syncing completion with Firebase: $e');
        }
      }
    } catch (e) {
      debugPrint('Error marking goal as completed: $e');
    }
  }

  /// Get all goal progress as a map
  static Future<Map<String, int>> getAllGoalProgress() async {
    try {
      final Map<String, int> allProgress = {};
      
      // Try to get from Firebase first if user is online
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final querySnapshot = await FirebaseFirestore.instance
              .collection(_userGoalsCollection)
              .doc(user.uid)
              .collection(_progressCollection)
              .get();

          for (final doc in querySnapshot.docs) {
            final data = doc.data();
            final progress = data['progress'] as int? ?? 0;
            allProgress[doc.id] = progress;
            
            // Update local storage for offline access
            await _saveProgressToLocal(doc.id, progress);
          }
          
          if (allProgress.isNotEmpty) {
            return allProgress;
          }
        } catch (e) {
          debugPrint('Error fetching all progress from Firebase: $e');
        }
      }

      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final progressKeys = keys.where((key) => key.startsWith(_goalProgressPrefix));
      
      for (final key in progressKeys) {
        final goalId = key.substring(_goalProgressPrefix.length);
        final progress = prefs.getInt(key) ?? 0;
        allProgress[goalId] = progress;
      }

      return allProgress;
    } catch (e) {
      debugPrint('Error getting all goal progress: $e');
      return {};
    }
  }

  /// Get list of completed goal IDs
  static Future<List<String>> getCompletedGoals() async {
    try {
      // Try to get from Firebase first if user is online
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection(_userGoalsCollection)
              .doc(user.uid)
              .get();

          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            final completedGoals = List<String>.from(data['completedGoals'] ?? []);
            
            // Update local storage
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_completedGoalsKey, json.encode(completedGoals));
            return completedGoals;
          }
        } catch (e) {
          debugPrint('Error fetching completed goals from Firebase: $e');
        }
      }

      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      final completedGoalsJson = prefs.getString(_completedGoalsKey) ?? '[]';
      return List<String>.from(json.decode(completedGoalsJson));
    } catch (e) {
      debugPrint('Error getting completed goals: $e');
      return [];
    }
  }

  /// Check if a goal is completed
  static Future<bool> isGoalCompleted(String goalId) async {
    try {
      final completedGoals = await getCompletedGoals();
      return completedGoals.contains(goalId);
    } catch (e) {
      debugPrint('Error checking goal completion: $e');
      return false;
    }
  }

  /// Get goal start date
  static Future<DateTime?> getGoalStartDate(String goalId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('start_date_$goalId');
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting goal start date: $e');
      return null;
    }
  }

  /// Set goal start date
  static Future<void> setGoalStartDate(String goalId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingTimestamp = prefs.getInt('start_date_$goalId');
      
      // Only set if not already set
      if (existingTimestamp == null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        await prefs.setInt('start_date_$goalId', now);
      }
    } catch (e) {
      debugPrint('Error setting goal start date: $e');
    }
  }

  /// Get completion date for a goal
  static Future<DateTime?> getGoalCompletionDate(String goalId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('completed_date_$goalId');
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting goal completion date: $e');
      return null;
    }
  }

  /// Get overall progress statistics
  static Future<Map<String, dynamic>> getProgressStatistics() async {
    try {
      final completedGoals = await getCompletedGoals();
      
      // Calculate total goals attempted (goals with any progress)
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final progressKeys = keys.where((key) => key.startsWith(_goalProgressPrefix)).toList();
      
      int totalStarted = 0;
      int totalProgress = 0;
      
      for (final key in progressKeys) {
        final progress = prefs.getInt(key) ?? 0;
        if (progress > 0) {
          totalStarted++;
          totalProgress += progress;
        }
      }

      final averageProgress = totalStarted > 0 ? (totalProgress / totalStarted).round() : 0;

      return {
        'totalCompleted': completedGoals.length,
        'totalStarted': totalStarted,
        'averageProgress': averageProgress,
        'completionRate': totalStarted > 0 ? ((completedGoals.length / totalStarted) * 100).round() : 0,
      };
    } catch (e) {
      debugPrint('Error getting progress statistics: $e');
      return {
        'totalCompleted': 0,
        'totalStarted': 0,
        'averageProgress': 0,
        'completionRate': 0,
      };
    }
  }

  /// Reset all progress for a specific goal
  static Future<void> resetGoalProgress(String goalId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Remove from local storage
      await prefs.remove('$_goalProgressPrefix$goalId');
      await prefs.remove('$_objectiveProgressPrefix$goalId');
      await prefs.remove('start_date_$goalId');
      await prefs.remove('completed_date_$goalId');
      
      // Remove from completed goals list
      final completedGoalsJson = prefs.getString(_completedGoalsKey) ?? '[]';
      final completedGoals = List<String>.from(json.decode(completedGoalsJson));
      completedGoals.remove(goalId);
      await prefs.setString(_completedGoalsKey, json.encode(completedGoals));

      // Reset in Firebase if online
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection(_userGoalsCollection)
              .doc(user.uid)
              .collection(_progressCollection)
              .doc(goalId)
              .delete();
              
          await FirebaseFirestore.instance
              .collection(_userGoalsCollection)
              .doc(user.uid)
              .set({
            'completedGoals': completedGoals,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Error resetting goal in Firebase: $e');
        }
      }
    } catch (e) {
      debugPrint('Error resetting goal progress: $e');
    }
  }

  /// Sync all local progress with Firebase
  static Future<void> syncWithFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      // Sync goal progress
      final progressKeys = keys.where((key) => key.startsWith(_goalProgressPrefix));
      for (final key in progressKeys) {
        final goalId = key.substring(_goalProgressPrefix.length);
        final progress = prefs.getInt(key) ?? 0;
        
        await FirebaseFirestore.instance
            .collection(_userGoalsCollection)
            .doc(user.uid)
            .collection(_progressCollection)
            .doc(goalId)
            .set({
          'progress': progress,
          'goalId': goalId,
          'lastUpdated': FieldValue.serverTimestamp(),
          'syncedFromLocal': true,
        }, SetOptions(merge: true));
      }

      // Sync objective progress
      final objectiveKeys = keys.where((key) => key.startsWith(_objectiveProgressPrefix));
      for (final key in objectiveKeys) {
        final goalId = key.substring(_objectiveProgressPrefix.length);
        final objectivesJson = prefs.getString(key) ?? '[]';
        final objectives = List<bool>.from(json.decode(objectivesJson));
        
        await FirebaseFirestore.instance
            .collection(_userGoalsCollection)
            .doc(user.uid)
            .collection(_progressCollection)
            .doc(goalId)
            .set({
          'objectives': objectives,
          'goalId': goalId,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // Sync completed goals
      final completedGoalsJson = prefs.getString(_completedGoalsKey) ?? '[]';
      final completedGoals = List<String>.from(json.decode(completedGoalsJson));
      
      await FirebaseFirestore.instance
          .collection(_userGoalsCollection)
          .doc(user.uid)
          .set({
        'completedGoals': completedGoals,
        'lastUpdated': FieldValue.serverTimestamp(),
        'syncedFromLocal': true,
      }, SetOptions(merge: true));

      debugPrint('Successfully synced goal progress with Firebase');
    } catch (e) {
      debugPrint('Error syncing with Firebase: $e');
    }
  }

  // Private helper methods
  static Future<int> _getProgressFromLocal(String goalId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('$_goalProgressPrefix$goalId') ?? 0;
    } catch (e) {
      debugPrint('Error getting local progress: $e');
      return 0;
    }
  }

  static Future<void> _saveProgressToLocal(String goalId, int progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('$_goalProgressPrefix$goalId', progress);
      
      // Set start date if this is the first progress update
      if (progress > 0) {
        await setGoalStartDate(goalId);
      }
    } catch (e) {
      debugPrint('Error saving local progress: $e');
    }
  }

  static Future<List<bool>> _getObjectiveProgressFromLocal(String goalId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final objectivesJson = prefs.getString('$_objectiveProgressPrefix$goalId') ?? '[]';
      return List<bool>.from(json.decode(objectivesJson));
    } catch (e) {
      debugPrint('Error getting local objectives: $e');
      return [];
    }
  }

  static Future<void> _saveObjectiveProgressToLocal(String goalId, List<bool> objectives) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_objectiveProgressPrefix$goalId', json.encode(objectives));
    } catch (e) {
      debugPrint('Error saving local objectives: $e');
    }
  }
}
