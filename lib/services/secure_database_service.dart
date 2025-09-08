import 'package:cloud_firestore/cloud_firestore.dart';
import 'secure_auth_service.dart';
import 'encryption_service.dart';
import '../utils/aac_logger.dart';

/// Secure Database Service that ensures all data operations are protected
/// This service wraps Firestore operations with security checks and encryption
class SecureDatabaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// CRITICAL: Get user's secure document reference with validation
  static DocumentReference? getUserDocument([String? userId]) {
    final uid = userId ?? SecureAuthService.currentUserId;
    if (uid == null) {
      AACLogger.warning('Attempted to access user document without authentication');
      return null;
    }
    return _firestore.collection('users').doc(uid);
  }
  
  /// CRITICAL: Get user's secure subcollection with validation
  static CollectionReference? getUserCollection(String collectionName, [String? userId]) {
    final userDoc = getUserDocument(userId);
    if (userDoc == null) return null;
    
    // Validate collection name to prevent injection
    if (!_isValidCollectionName(collectionName)) {
      AACLogger.error('Invalid collection name attempted: $collectionName');
      return null;
    }
    
    return userDoc.collection(collectionName);
  }
  
  /// Validate collection names to prevent security issues
  static bool _isValidCollectionName(String name) {
    const allowedCollections = [
      'symbols', 'favorites', 'history', 'profile', 'backups',
      'learning_goals', 'progress_tracking', 'settings'
    ];
    return allowedCollections.contains(name);
  }
  
  /// SECURE: Save document with encryption for sensitive fields
  static Future<bool> saveSecureDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
    List<String>? encryptFields,
    String? userId,
  }) async {
    try {
      final userCollection = getUserCollection(collection, userId);
      if (userCollection == null) {
        AACLogger.error('Cannot save document: No authenticated user');
        return false;
      }
      
      // Encrypt sensitive fields if specified
      final secureData = Map<String, dynamic>.from(data);
      if (encryptFields != null) {
        for (final field in encryptFields) {
          if (secureData.containsKey(field) && secureData[field] is String) {
            final encrypted = await EncryptionService().encrypt(secureData[field]);
            if (encrypted != secureData[field]) {
              secureData[field] = encrypted;
              secureData['${field}_encrypted'] = true;
            }
          }
        }
      }
      
      // Add security metadata
      secureData['created_at'] = FieldValue.serverTimestamp();
      secureData['updated_at'] = FieldValue.serverTimestamp();
      secureData['user_id_hash'] = SecureAuthService.hashUserId(
        userId ?? SecureAuthService.currentUserId!
      );
      
      await userCollection.doc(documentId).set(secureData, SetOptions(merge: true));
      
      AACLogger.info('Secure document saved: $collection/$documentId');
      return true;
    } catch (e) {
      AACLogger.error('Failed to save secure document: $e');
      return false;
    }
  }
  
  /// SECURE: Get document with automatic decryption
  static Future<Map<String, dynamic>?> getSecureDocument({
    required String collection,
    required String documentId,
    List<String>? decryptFields,
    String? userId,
  }) async {
    try {
      final userCollection = getUserCollection(collection, userId);
      if (userCollection == null) {
        AACLogger.error('Cannot get document: No authenticated user');
        return null;
      }
      
      final doc = await userCollection.doc(documentId).get();
      if (!doc.exists) return null;
      
      final data = doc.data() as Map<String, dynamic>;
      
      // Decrypt fields if specified and marked as encrypted
      if (decryptFields != null) {
        for (final field in decryptFields) {
          if (data.containsKey(field) && 
              data['${field}_encrypted'] == true &&
              data[field] is String) {
            final decrypted = await EncryptionService().decrypt(data[field]);
            if (decrypted != data[field]) {
              data[field] = decrypted;
              data.remove('${field}_encrypted');
            }
          }
        }
      }
      
      AACLogger.info('Secure document retrieved: $collection/$documentId');
      return data;
    } catch (e) {
      AACLogger.error('Failed to get secure document: $e');
      return null;
    }
  }
  
  /// SECURE: Query documents with user isolation
  static Query? getSecureQuery({
    required String collection,
    String? userId,
  }) {
    final userCollection = getUserCollection(collection, userId);
    if (userCollection == null) {
      AACLogger.error('Cannot create query: No authenticated user');
      return null;
    }
    
    return userCollection.orderBy('updated_at', descending: true);
  }
  
  /// SECURE: Delete document with audit trail
  static Future<bool> deleteSecureDocument({
    required String collection,
    required String documentId,
    String? userId,
    String? reason,
  }) async {
    try {
      final userCollection = getUserCollection(collection, userId);
      if (userCollection == null) {
        AACLogger.error('Cannot delete document: No authenticated user');
        return false;
      }
      
      // Create audit trail before deletion
      final auditData = {
        'deleted_at': FieldValue.serverTimestamp(),
        'collection': collection,
        'document_id': documentId,
        'user_id_hash': SecureAuthService.hashUserId(
          userId ?? SecureAuthService.currentUserId!
        ),
        'reason': reason ?? 'user_request',
      };
      
      // Store audit trail in compliance collection
      await _firestore.collection('audit_logs').add(auditData);
      
      // Delete the document
      await userCollection.doc(documentId).delete();
      
      AACLogger.info('Secure document deleted: $collection/$documentId');
      return true;
    } catch (e) {
      AACLogger.error('Failed to delete secure document: $e');
      return false;
    }
  }
  
  /// SECURE: Batch operations with user validation
  static WriteBatch createSecureBatch() {
    if (!SecureAuthService.isAuthenticated) {
      throw Exception('Cannot create batch: User not authenticated');
    }
    return _firestore.batch();
  }
  
  /// SECURE: Stream documents with automatic security filtering
  static Stream<QuerySnapshot>? getSecureStream({
    required String collection,
    int? limit,
    String? userId,
  }) {
    final query = getSecureQuery(collection: collection, userId: userId);
    if (query == null) return null;
    
    final limitedQuery = limit != null ? query.limit(limit) : query;
    return limitedQuery.snapshots();
  }
  
  /// SECURE: Update document with merge protection
  static Future<bool> updateSecureDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> updates,
    List<String>? encryptFields,
    String? userId,
  }) async {
    try {
      final userCollection = getUserCollection(collection, userId);
      if (userCollection == null) {
        AACLogger.error('Cannot update document: No authenticated user');
        return false;
      }
      
      // Prepare secure updates
      final secureUpdates = Map<String, dynamic>.from(updates);
      
      // Encrypt sensitive fields if specified
      if (encryptFields != null) {
        for (final field in encryptFields) {
          if (secureUpdates.containsKey(field) && secureUpdates[field] is String) {
            final encrypted = await EncryptionService().encrypt(secureUpdates[field]);
            if (encrypted != secureUpdates[field]) {
              secureUpdates[field] = encrypted;
              secureUpdates['${field}_encrypted'] = true;
            }
          }
        }
      }
      
      // Add update timestamp
      secureUpdates['updated_at'] = FieldValue.serverTimestamp();
      
      await userCollection.doc(documentId).update(secureUpdates);
      
      AACLogger.info('Secure document updated: $collection/$documentId');
      return true;
    } catch (e) {
      AACLogger.error('Failed to update secure document: $e');
      return false;
    }
  }
  
  /// Check if user has permission to access document
  static Future<bool> hasDocumentPermission({
    required String collection,
    required String documentId,
    String? userId,
  }) async {
    try {
      final doc = await getSecureDocument(
        collection: collection,
        documentId: documentId,
        userId: userId,
      );
      return doc != null;
    } catch (e) {
      AACLogger.error('Error checking document permission: $e');
      return false;
    }
  }
  
  /// Get user's data summary for parental controls
  static Future<Map<String, dynamic>> getUserDataSummary([String? userId]) async {
    try {
      final uid = userId ?? SecureAuthService.currentUserId;
      if (uid == null) throw Exception('No authenticated user');
      
      final collections = ['symbols', 'favorites', 'history', 'profile'];
        final summary = <String, dynamic>{};
        
        for (final collection in collections) {
          final query = getSecureQuery(collection: collection, userId: uid);
          if (query != null) {
            final snapshot = await query.get();
            summary['${collection}_count'] = snapshot.docs.length;
            
            if (snapshot.docs.isNotEmpty) {
              final latest = snapshot.docs.first.data() as Map<String, dynamic>?;
              summary['${collection}_last_updated'] = latest?['updated_at'];
            }
          }
        }      return summary;
    } catch (e) {
      AACLogger.error('Failed to get user data summary: $e');
      return {};
    }
  }
}
