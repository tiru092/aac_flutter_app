import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:convert';
import '../models/symbol.dart';
import '../models/user_profile.dart';
import '../services/symbol_database_service.dart';
import '../services/profile_service.dart';
import '../services/phrase_history_service.dart';

class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentUser != null;

  // Authentication Methods
  Future<AuthResult> signInAnonymously() async {
    try {
      final UserCredential userCredential = await _auth.signInAnonymously();
      
      // Initialize user document in Firestore
      await _initializeUserDocument(userCredential.user!);
      
      return AuthResult(
        success: true,
        user: userCredential.user,
        message: 'Successfully signed in anonymously',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Failed to sign in: $e',
      );
    }
  }

  Future<AuthResult> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      return AuthResult(
        success: true,
        user: userCredential.user,
        message: 'Successfully signed in',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Failed to sign in: $e',
      );
    }
  }

  Future<AuthResult> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Initialize user document in Firestore
      await _initializeUserDocument(userCredential.user!);
      
      return AuthResult(
        success: true,
        user: userCredential.user,
        message: 'Account created successfully',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Failed to create account: $e',
      );
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Data Synchronization Methods
  Future<SyncResult> syncToCloud({bool forceUpload = false}) async {
    if (!isSignedIn) {
      return SyncResult(
        success: false,
        message: 'User not signed in',
      );
    }

    try {
      final userId = currentUser!.uid;
      final stats = SyncStats();
      
      // Get local data
      final symbolService = SymbolDatabaseService();
      final profileService = ProfileService();
      final historyService = PhraseHistoryService();
      
      // Check if cloud sync is needed
      if (!forceUpload) {
        final lastSync = await _getLastSyncTime(userId);
        final localModified = await _getLocalLastModified();
        
        if (lastSync != null && lastSync.isAfter(localModified)) {
          return SyncResult(
            success: true,
            message: 'Data is already synchronized',
            stats: stats,
          );
        }
      }
      
      // Sync symbols
      await _syncSymbolsToCloud(userId, symbolService.symbols, stats);
      
      // Sync categories
      await _syncCategoriesToCloud(userId, symbolService.categories, stats);
      
      // Sync profiles
      await _syncProfilesToCloud(userId, profileService.profiles, stats);
      
      // Sync phrase history
      await _syncHistoryToCloud(userId, historyService, stats);
      
      // Update last sync timestamp
      await _updateLastSyncTime(userId);
      
      return SyncResult(
        success: true,
        message: 'Data synchronized to cloud successfully',
        stats: stats,
      );
      
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Failed to sync to cloud: $e',
      );
    }
  }

  Future<SyncResult> syncFromCloud({bool forceDownload = false}) async {
    if (!isSignedIn) {
      return SyncResult(
        success: false,
        message: 'User not signed in',
      );
    }

    try {
      final userId = currentUser!.uid;
      final stats = SyncStats();
      
      // Check if download is needed
      if (!forceDownload) {
        final cloudModified = await _getCloudLastModified(userId);
        final lastSync = await _getLastSyncTime(userId);
        
        if (lastSync != null && lastSync.isAfter(cloudModified)) {
          return SyncResult(
            success: true,
            message: 'Local data is already up to date',
            stats: stats,
          );
        }
      }
      
      // Get services
      final symbolService = SymbolDatabaseService();
      final profileService = ProfileService();
      final historyService = PhraseHistoryService();
      
      // Sync symbols from cloud
      await _syncSymbolsFromCloud(userId, symbolService, stats);
      
      // Sync categories from cloud
      await _syncCategoriesFromCloud(userId, symbolService, stats);
      
      // Sync profiles from cloud
      await _syncProfilesFromCloud(userId, profileService, stats);
      
      // Sync history from cloud
      await _syncHistoryFromCloud(userId, historyService, stats);
      
      return SyncResult(
        success: true,
        message: 'Data synchronized from cloud successfully',
        stats: stats,
      );
      
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Failed to sync from cloud: $e',
      );
    }
  }

  Future<CloudStorageInfo> getCloudStorageInfo() async {
    if (!isSignedIn) {
      return CloudStorageInfo(
        totalSize: 0,
        usedSize: 0,
        symbolCount: 0,
        profileCount: 0,
        lastSyncTime: null,
      );
    }

    try {
      final userId = currentUser!.uid;
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        return CloudStorageInfo(
          totalSize: 0,
          usedSize: 0,
          symbolCount: 0,
          profileCount: 0,
          lastSyncTime: null,
        );
      }
      
      final data = userDoc.data()!;
      
      // Count symbols and profiles
      final symbolsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('symbols')
          .get();
          
      final profilesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('profiles')
          .get();
      
      return CloudStorageInfo(
        totalSize: data['storage_quota'] ?? 100 * 1024 * 1024, // 100MB default
        usedSize: data['storage_used'] ?? 0,
        symbolCount: symbolsSnapshot.docs.length,
        profileCount: profilesSnapshot.docs.length,
        lastSyncTime: data['last_sync'] != null 
            ? (data['last_sync'] as Timestamp).toDate()
            : null,
      );
      
    } catch (e) {
      return CloudStorageInfo(
        totalSize: 0,
        usedSize: 0,
        symbolCount: 0,
        profileCount: 0,
        lastSyncTime: null,
      );
    }
  }

  // Private helper methods
  Future<void> _initializeUserDocument(User user) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();
    
    if (!docSnapshot.exists) {
      await userDoc.set({
        'email': user.email,
        'created_at': FieldValue.serverTimestamp(),
        'last_sync': null,
        'storage_used': 0,
        'storage_quota': 100 * 1024 * 1024, // 100MB
        'app_version': '1.0.0',
      });
    }
  }

  Future<DateTime?> _getLastSyncTime(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final lastSync = userDoc.data()?['last_sync'];
      return lastSync != null ? (lastSync as Timestamp).toDate() : null;
    } catch (e) {
      return null;
    }
  }

  Future<DateTime> _getLocalLastModified() async {
    // This would check local database timestamps
    // For now, return current time minus 1 hour to trigger sync
    return DateTime.now().subtract(const Duration(hours: 1));
  }

  Future<DateTime> _getCloudLastModified(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final lastModified = userDoc.data()?['last_modified'];
      return lastModified != null 
          ? (lastModified as Timestamp).toDate() 
          : DateTime.fromMillisecondsSinceEpoch(0);
    } catch (e) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  Future<void> _updateLastSyncTime(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'last_sync': FieldValue.serverTimestamp(),
      'last_modified': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _syncSymbolsToCloud(String userId, List<Symbol> symbols, SyncStats stats) async {
    final batch = _firestore.batch();
    final symbolsRef = _firestore.collection('users').doc(userId).collection('symbols');
    
    // Clear existing symbols
    final existingSymbols = await symbolsRef.get();
    for (final doc in existingSymbols.docs) {
      batch.delete(doc.reference);
    }
    
    // Upload new symbols
    for (final symbol in symbols) {
      final symbolData = symbol.toJson();
      
      // Upload custom image if needed
      if (!symbol.imagePath.startsWith('assets/')) {
        try {
          final imageUrl = await _uploadImage(userId, symbol.imagePath);
          symbolData['cloud_image_url'] = imageUrl;
          stats.imagesUploaded++;
        } catch (e) {
          // Continue with local path if upload fails
        }
      }
      
      batch.set(symbolsRef.doc(symbol.id), symbolData);
      stats.symbolsUploaded++;
    }
    
    await batch.commit();
  }

  Future<void> _syncCategoriesToCloud(String userId, List<Category> categories, SyncStats stats) async {
    final batch = _firestore.batch();
    final categoriesRef = _firestore.collection('users').doc(userId).collection('categories');
    
    // Clear existing categories
    final existingCategories = await categoriesRef.get();
    for (final doc in existingCategories.docs) {
      batch.delete(doc.reference);
    }
    
    // Upload new categories
    for (final category in categories) {
      batch.set(categoriesRef.doc(category.name), category.toJson());
      stats.categoriesUploaded++;
    }
    
    await batch.commit();
  }

  Future<void> _syncProfilesToCloud(String userId, List<UserProfile> profiles, SyncStats stats) async {
    final batch = _firestore.batch();
    final profilesRef = _firestore.collection('users').doc(userId).collection('profiles');
    
    // Clear existing profiles
    final existingProfiles = await profilesRef.get();
    for (final doc in existingProfiles.docs) {
      batch.delete(doc.reference);
    }
    
    // Upload new profiles (excluding sensitive data like PINs)
    for (final profile in profiles) {
      final profileData = profile.toJson();
      // Remove PIN for security (handle separately if needed)
      profileData.remove('pin');
      
      batch.set(profilesRef.doc(profile.id), profileData);
      stats.profilesUploaded++;
    }
    
    await batch.commit();
  }

  Future<void> _syncHistoryToCloud(String userId, PhraseHistoryService historyService, SyncStats stats) async {
    final historyRef = _firestore.collection('users').doc(userId).collection('history');
    
    final historyData = {
      'history': historyService.history.map((h) => h.toJson()).toList(),
      'favorites': historyService.favorites.map((f) => f.toJson()).toList(),
      'updated_at': FieldValue.serverTimestamp(),
    };
    
    await historyRef.doc('phrase_history').set(historyData);
    stats.historyItemsUploaded = historyService.history.length;
  }

  Future<String> _uploadImage(String userId, String localPath) async {
    final file = File(localPath);
    final fileName = localPath.split('/').last;
    final ref = _storage.ref().child('users').child(userId).child('images').child(fileName);
    
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> _syncSymbolsFromCloud(String userId, SymbolDatabaseService symbolService, SyncStats stats) async {
    final symbolsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('symbols')
        .get();
    
    for (final doc in symbolsSnapshot.docs) {
      try {
        final symbolData = doc.data();
        
        // Download custom image if exists
        if (symbolData['cloud_image_url'] != null) {
          try {
            final localPath = await _downloadImage(symbolData['cloud_image_url']);
            symbolData['imagePath'] = localPath;
          } catch (e) {
            // Use cloud URL if download fails
            symbolData['imagePath'] = symbolData['cloud_image_url'];
          }
        }
        
        final symbol = Symbol.fromJson(symbolData);
        await symbolService.addSymbol(symbol);
        stats.symbolsDownloaded++;
      } catch (e) {
        // Skip invalid symbols
      }
    }
  }

  Future<void> _syncCategoriesFromCloud(String userId, SymbolDatabaseService symbolService, SyncStats stats) async {
    final categoriesSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .get();
    
    for (final doc in categoriesSnapshot.docs) {
      try {
        final category = Category.fromJson(doc.data());
        await symbolService.addCategory(category);
        stats.categoriesDownloaded++;
      } catch (e) {
        // Skip invalid categories
      }
    }
  }

  Future<void> _syncProfilesFromCloud(String userId, ProfileService profileService, SyncStats stats) async {
    final profilesSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('profiles')
        .get();
    
    for (final doc in profilesSnapshot.docs) {
      try {
        final profile = UserProfile.fromJson(doc.data());
        await profileService.addProfile(profile);
        stats.profilesDownloaded++;
      } catch (e) {
        // Skip invalid profiles
      }
    }
  }

  Future<void> _syncHistoryFromCloud(String userId, PhraseHistoryService historyService, SyncStats stats) async {
    final historyDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('history')
        .doc('phrase_history')
        .get();
    
    if (historyDoc.exists) {
      final historyData = historyDoc.data()!;
      
      if (historyData['history'] != null) {
        for (final itemData in historyData['history']) {
          final item = PhraseHistoryItem.fromJson(itemData);
          await historyService.addToHistory(item.text);
          stats.historyItemsDownloaded++;
        }
      }
    }
  }

  Future<String> _downloadImage(String imageUrl) async {
    // Implementation would download the image from Firebase Storage
    // and save it locally, returning the local path
    // For now, return the URL
    return imageUrl;
  }

  Future<bool> deleteCloudData() async {
    if (!isSignedIn) return false;
    
    try {
      final userId = currentUser!.uid;
      
      // Delete user's collections
      await _deleteCollection('users/$userId/symbols');
      await _deleteCollection('users/$userId/categories');
      await _deleteCollection('users/$userId/profiles');
      await _deleteCollection('users/$userId/history');
      
      // Delete user document
      await _firestore.collection('users').doc(userId).delete();
      
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _deleteCollection(String path) async {
    final batch = _firestore.batch();
    final collection = _firestore.collection(path);
    final snapshot = await collection.get();
    
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }
}

// Data Classes
class AuthResult {
  final bool success;
  final User? user;
  final String message;

  AuthResult({
    required this.success,
    this.user,
    required this.message,
  });
}

class SyncResult {
  final bool success;
  final String message;
  final SyncStats? stats;

  SyncResult({
    required this.success,
    required this.message,
    this.stats,
  });
}

class SyncStats {
  int symbolsUploaded = 0;
  int symbolsDownloaded = 0;
  int categoriesUploaded = 0;
  int categoriesDownloaded = 0;
  int profilesUploaded = 0;
  int profilesDownloaded = 0;
  int historyItemsUploaded = 0;
  int historyItemsDownloaded = 0;
  int imagesUploaded = 0;
  int imagesDownloaded = 0;

  @override
  String toString() {
    return 'Sync Stats:\n'
           'Symbols: ↑$symbolsUploaded ↓$symbolsDownloaded\n'
           'Categories: ↑$categoriesUploaded ↓$categoriesDownloaded\n'
           'Profiles: ↑$profilesUploaded ↓$profilesDownloaded\n'
           'History: ↑$historyItemsUploaded ↓$historyItemsDownloaded\n'
           'Images: ↑$imagesUploaded ↓$imagesDownloaded';
  }
}

class CloudStorageInfo {
  final int totalSize;
  final int usedSize;
  final int symbolCount;
  final int profileCount;
  final DateTime? lastSyncTime;

  CloudStorageInfo({
    required this.totalSize,
    required this.usedSize,
    required this.symbolCount,
    required this.profileCount,
    required this.lastSyncTime,
  });

  double get usagePercentage {
    if (totalSize == 0) return 0.0;
    return (usedSize / totalSize) * 100;
  }

  String get formattedUsedSize {
    if (usedSize < 1024) {
      return '$usedSize B';
    } else if (usedSize < 1024 * 1024) {
      return '${(usedSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(usedSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  String get formattedTotalSize {
    if (totalSize < 1024 * 1024) {
      return '${(totalSize / 1024).toStringAsFixed(0)} KB';
    } else {
      return '${(totalSize / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
  }
}