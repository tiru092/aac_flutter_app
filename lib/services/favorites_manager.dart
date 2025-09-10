import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:svarah/models/symbol.dart'; // Assuming Symbol model exists and has a Hive adapter
import 'package:svarah/utils/aac_logger.dart';

class FavoritesManager {
  static final FavoritesManager _instance = FavoritesManager._internal();
  factory FavoritesManager() => _instance;
  FavoritesManager._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _userId;
  Box<String>? _favoritesBox; // Stores symbol IDs

  Future<void> init() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userId = user.uid;
      final boxName = 'favorites_$_userId';
      _favoritesBox = await Hive.openBox<String>(boxName);
      AACLogger.info('FavoritesManager initialized for user: $_userId', tag: 'Favorites');
    }
  }

  // Add a symbol to favorites in both Firestore and Hive
  Future<void> addFavorite(String symbolId) async {
    if (_userId == null) {
      AACLogger.warning('Cannot add favorite, user not logged in.', tag: 'Favorites');
      return;
    }

    try {
      // Add to Firestore
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('favorites')
          .doc(symbolId)
          .set({'addedAt': FieldValue.serverTimestamp()});

      // Add to Hive
      await _favoritesBox?.put(symbolId, symbolId);

      AACLogger.info('Added favorite: $symbolId', tag: 'Favorites');
    } catch (e) {
      AACLogger.error('Failed to add favorite: $e', tag: 'Favorites');
      rethrow;
    }
  }

  // Remove a symbol from favorites in both Firestore and Hive
  Future<void> removeFavorite(String symbolId) async {
    if (_userId == null) {
      AACLogger.warning('Cannot remove favorite, user not logged in.', tag: 'Favorites');
      return;
    }

    try {
      // Remove from Firestore
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('favorites')
          .doc(symbolId)
          .delete();

      // Remove from Hive
      await _favoritesBox?.delete(symbolId);

      AACLogger.info('Removed favorite: $symbolId', tag: 'Favorites');
    } catch (e) {
      AACLogger.error('Failed to remove favorite: $e', tag: 'Favorites');
      rethrow;
    }
  }

  // Get all favorite symbol IDs from Hive
  List<String> getFavoriteIds() {
    if (_favoritesBox == null) {
      return [];
    }
    return _favoritesBox!.values.toList();
  }

  // Check if a symbol is a favorite
  bool isFavorite(String symbolId) {
    return _favoritesBox?.containsKey(symbolId) ?? false;
  }

  // Sync favorites from Firestore to Hive
  Future<void> syncFavoritesFromFirestore() async {
    if (_userId == null || _favoritesBox == null) {
      AACLogger.warning('Cannot sync favorites, user not logged in or box not open.', tag: 'Favorites');
      return;
    }

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('favorites')
          .get();

      final firestoreIds = querySnapshot.docs.map((doc) => doc.id).toSet();
      final localIds = _favoritesBox!.keys.cast<String>().toSet();

      // Add missing favorites to Hive
      for (final id in firestoreIds.difference(localIds)) {
        await _favoritesBox!.put(id, id);
      }

      // Remove extra favorites from Hive
      for (final id in localIds.difference(firestoreIds)) {
        await _favoritesBox!.delete(id);
      }

      AACLogger.info('Favorites synced from Firestore. Total favorites: ${firestoreIds.length}', tag: 'Favorites');
    } catch (e) {
      AACLogger.error('Failed to sync favorites from Firestore: $e', tag: 'Favorites');
    }
  }
}
