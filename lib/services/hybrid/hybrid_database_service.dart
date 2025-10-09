import 'package:cloud_firestore/cloud_firestore.dart' as firebase;
import 'package:flutter/foundation.dart';
import '../firebase_supabase_migration_service.dart';
import '../supabase/index.dart';

/// Hybrid Database Service
/// Manages data operations across Firebase and Supabase during migration
class HybridDatabaseService {
  static HybridDatabaseService? _instance;
  
  // Firebase service (existing)
  final firebase.FirebaseFirestore _firestore;
  
  HybridDatabaseService._internal({firebase.FirebaseFirestore? firestore})
      : _firestore = firestore ?? firebase.FirebaseFirestore.instance;
  
  factory HybridDatabaseService() {
    _instance ??= HybridDatabaseService._internal();
    return _instance!;
  }
  
  /// Get user profile from primary data source
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      if (!migrationService.isMigrationEnabled || migrationService.isFirebasePrimary) {
        // Firebase primary - get from Firebase
        return await _getUserProfileFromFirebase(userId);
      } else {
        // Supabase primary - get from Supabase with Firebase fallback
        try {
          final supabaseData = await supabaseService.database.getUserProfile();
          return supabaseData;
        } catch (e) {
          if (kDebugMode) {
            print('HybridDatabaseService WARNING: Supabase getUserProfile failed, falling back to Firebase: $e');
          }
          return await _getUserProfileFromFirebase(userId);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('HybridDatabaseService ERROR: Hybrid getUserProfile failed: $e');
      }
      rethrow;
    }
  }
  
  /// Create or update user profile in both systems
  Future<void> upsertUserProfile(String userId, Map<String, dynamic> profileData) async {
    try {
      // For now, just write to Firebase
      await _upsertUserProfileToFirebase(userId, profileData);
      
      if (kDebugMode) {
        print('HybridDatabaseService: User profile upserted to Firebase');
      }
    } catch (e) {
      if (kDebugMode) {
        print('HybridDatabaseService ERROR: Hybrid upsertUserProfile failed: $e');
      }
      rethrow;
    }
  }
  
  /// Get categories from primary data source
  Future<List<Map<String, dynamic>>> getCategories(String userId) async {
    try {
      // For now, just use Firebase
      return await _getCategoriesFromFirebase(userId);
    } catch (e) {
      if (kDebugMode) {
        print('HybridDatabaseService ERROR: Hybrid getCategories failed: $e');
      }
      rethrow;
    }
  }
  
  /// Create category in both systems
  Future<Map<String, dynamic>> createCategory(String userId, Map<String, dynamic> categoryData) async {
    try {
      // For now, just create in Firebase
      return await _createCategoryInFirebase(userId, categoryData);
    } catch (e) {
      if (kDebugMode) {
        print('HybridDatabaseService ERROR: Hybrid createCategory failed: $e');
      }
      rethrow;
    }
  }
  
  /// Get communication history from primary data source
  Future<List<Map<String, dynamic>>> getCommunicationHistory(String userId, {int limit = 50}) async {
    try {
      // For now, just use Firebase
      return await _getCommunicationHistoryFromFirebase(userId, limit: limit);
    } catch (e) {
      if (kDebugMode) {
        print('HybridDatabaseService ERROR: Hybrid getCommunicationHistory failed: $e');
      }
      rethrow;
    }
  }
  
  /// Add communication history to both systems
  Future<void> addCommunicationHistory(String userId, Map<String, dynamic> historyData) async {
    try {
      // For now, just add to Firebase
      await _addCommunicationHistoryToFirebase(userId, historyData);
      
      if (kDebugMode) {
        print('HybridDatabaseService: Communication history added to Firebase');
      }
    } catch (e) {
      if (kDebugMode) {
        print('HybridDatabaseService ERROR: Hybrid addCommunicationHistory failed: $e');
      }
      rethrow;
    }
  }
  
  // Firebase-specific implementations
  
  Future<Map<String, dynamic>?> _getUserProfileFromFirebase(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.exists ? doc.data() : null;
  }
  
  Future<void> _upsertUserProfileToFirebase(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).set(data, firebase.SetOptions(merge: true));
  }
  
  Future<List<Map<String, dynamic>>> _getCategoriesFromFirebase(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .orderBy('name')
        .get();
    
    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }
  
  Future<Map<String, dynamic>> _createCategoryInFirebase(String userId, Map<String, dynamic> data) async {
    final docRef = await _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .add(data);
    
    return {
      'id': docRef.id,
      ...data,
    };
  }
  
  Future<List<Map<String, dynamic>>> _getCommunicationHistoryFromFirebase(String userId, {int limit = 50}) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('communication_history')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    
    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }
  
  Future<void> _addCommunicationHistoryToFirebase(String userId, Map<String, dynamic> data) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('communication_history')
        .add(data);
  }
}