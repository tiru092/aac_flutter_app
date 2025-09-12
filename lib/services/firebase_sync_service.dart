
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/symbol.dart';
import 'crash_reporting_service.dart';

class FirebaseSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CrashReportingService _crashReportingService = CrashReportingService();

  Future<void> syncSymbolsToCloud(String userId, List<Symbol> symbols) async {
    try {
      if (symbols.isEmpty) return;

      final WriteBatch batch = _firestore.batch();
      final CollectionReference symbolsRef =
          _firestore.collection('users').doc(userId).collection('symbols');

      for (final symbol in symbols) {
        final DocumentReference docRef = symbolsRef.doc(symbol.id);
        batch.set(docRef, symbol.toJson());
      }

      await batch.commit();
    } on FirebaseException catch (e, s) {
      _crashReportingService.reportError(e, s,
          'Firebase error syncing symbols to cloud');
      throw Exception('Firebase error syncing symbols: ${e.message}');
    } catch (e, s) {
      _crashReportingService.reportError(e, s,
          'Unexpected error syncing symbols to cloud');
      throw Exception('Unexpected error syncing symbols: $e');
    }
  }

  Future<List<Symbol>> getSymbolsFromCloud(String userId, {DateTime? lastSync}) async {
    try {
      Query query = _firestore.collection('users').doc(userId).collection('symbols');
      if (lastSync != null) {
        query = query.where('lastModified', isGreaterThan: lastSync);
      }
      final QuerySnapshot snapshot = await query.get();

      return snapshot.docs
          .map((doc) => Symbol.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } on FirebaseException catch (e, s) {
      _crashReportingService.reportError(e, s,
          'Firebase error getting symbols from cloud');
      throw Exception('Firebase error getting symbols: ${e.message}');
    } catch (e, s) {
      _crashReportingService.reportError(e, s,
          'Unexpected error getting symbols from cloud');
      throw Exception('Unexpected error getting symbols: $e');
    }
  }

  Future<void> deleteSymbolFromCloud(String userId, String symbolId) async {
    try {
      await _firestore.collection('users').doc(userId).collection('symbols').doc(symbolId).delete();
    } on FirebaseException catch (e, s) {
      _crashReportingService.reportError(e, s,
          'Firebase error deleting symbol from cloud');
      throw Exception('Firebase error deleting symbol: ${e.message}');
    } catch (e, s) {
      _crashReportingService.reportError(e, s,
          'Unexpected error deleting symbol from cloud');
      throw Exception('Unexpected error deleting symbol: $e');
    }
  }

  Future<void> syncCategoriesToCloud(String userId, List<Category> categories) async {
    try {
      if (categories.isEmpty) return;

      final WriteBatch batch = _firestore.batch();
      final CollectionReference categoriesRef =
          _firestore.collection('users').doc(userId).collection('categories');

      for (final category in categories) {
        final DocumentReference docRef = categoriesRef.doc(category.id);
        batch.set(docRef, category.toJson());
      }

      await batch.commit();
    } on FirebaseException catch (e, s) {
      _crashReportingService.reportError(e, s,
          'Firebase error syncing categories to cloud');
      throw Exception('Firebase error syncing categories: ${e.message}');
    } catch (e, s) {
      _crashReportingService.reportError(e, s,
          'Unexpected error syncing categories to cloud');
      throw Exception('Unexpected error syncing categories: $e');
    }
  }

  Future<List<Category>> getCategoriesFromCloud(String userId, {DateTime? lastSync}) async {
    try {
      Query query = _firestore.collection('users').doc(userId).collection('categories');
      if (lastSync != null) {
        query = query.where('lastModified', isGreaterThan: lastSync);
      }
      final QuerySnapshot snapshot = await query.get();

      return snapshot.docs
          .map((doc) => Category.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } on FirebaseException catch (e, s) {
      _crashReportingService.reportError(e, s,
          'Firebase error getting categories from cloud');
      throw Exception('Firebase error getting categories: ${e.message}');
    } catch (e, s) {
      _crashReportingService.reportError(e, s,
          'Unexpected error getting categories from cloud');
      throw Exception('Unexpected error getting categories: $e');
    }
  }

  Future<void> deleteCategoryFromCloud(String userId, String categoryId) async {
    try {
      await _firestore.collection('users').doc(userId).collection('categories').doc(categoryId).delete();
    } on FirebaseException catch (e, s) {
      _crashReportingService.reportError(e, s,
          'Firebase error deleting category from cloud');
      throw Exception('Firebase error deleting category: ${e.message}');
    } catch (e, s) {
      _crashReportingService.reportError(e, s,
          'Unexpected error deleting category from cloud');
      throw Exception('Unexpected error deleting category: $e');
    }
  }
}
