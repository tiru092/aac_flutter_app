import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/symbol.dart';
import '../utils/aac_logger.dart';

/// Enterprise-level shared resource management service
/// 
/// Architecture:
/// - Global default symbols/categories stored once in 'global_defaults' collection
/// - User-specific data stored in 'user_profiles/{uid}/custom_symbols' 
/// - Images stored efficiently with Firebase Storage references
/// - Massive scalability improvement - default resources shared across all users
class SharedResourceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Global collections for shared resources (read-only for users)
  static const String _globalSymbolsCollection = 'global_default_symbols';
  static const String _globalCategoriesCollection = 'global_default_categories';
  
  // User-specific collections for custom uploads only
  static const String _userCustomSymbolsPath = 'user_profiles';
  
  /// Initialize global default resources (admin/setup operation)
  /// This runs once during app deployment to populate shared defaults
  static Future<void> initializeGlobalDefaults() async {
    try {
      AACLogger.info('Initializing global default resources...', tag: 'SharedResourceService');
      
      // Check if already initialized
      final globalSymbolsDoc = await _firestore
          .collection(_globalSymbolsCollection)
          .limit(1)
          .get();
      
      if (globalSymbolsDoc.docs.isNotEmpty) {
        AACLogger.info('Global defaults already exist, skipping initialization', tag: 'SharedResourceService');
        return;
      }
      
      // Initialize default categories
      await _initializeDefaultCategories();
      
      // Initialize default symbols 
      await _initializeDefaultSymbols();
      
      AACLogger.info('Global default resources initialized successfully', tag: 'SharedResourceService');
      
    } catch (e) {
      AACLogger.error('Error initializing global defaults: $e', tag: 'SharedResourceService');
      rethrow;
    }
  }
  
  /// Get global default symbols (shared across all users)
  static Future<List<Symbol>> getGlobalDefaultSymbols() async {
    try {
      AACLogger.debug('Fetching global default symbols...', tag: 'SharedResourceService');
      
      final snapshot = await _firestore
          .collection(_globalSymbolsCollection)
          .orderBy('category')
          .orderBy('label')
          .get();
      
      final symbols = snapshot.docs
          .map((doc) => Symbol.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
      
      AACLogger.debug('Loaded ${symbols.length} global default symbols', tag: 'SharedResourceService');
      return symbols;
      
    } catch (e) {
      AACLogger.error('Error fetching global default symbols: $e', tag: 'SharedResourceService');
      return [];
    }
  }
  
  /// Get global default categories (shared across all users)
  static Future<List<Category>> getGlobalDefaultCategories() async {
    try {
      AACLogger.debug('Fetching global default categories...', tag: 'SharedResourceService');
      
      final snapshot = await _firestore
          .collection(_globalCategoriesCollection)
          .orderBy('name')
          .get();
      
      final categories = snapshot.docs
          .map((doc) => Category.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
      
      AACLogger.debug('Loaded ${categories.length} global default categories', tag: 'SharedResourceService');
      return categories;
      
    } catch (e) {
      AACLogger.error('Error fetching global default categories: $e', tag: 'SharedResourceService');
      return [];
    }
  }
  
  /// Get user's custom symbols only (not including defaults)
  static Future<List<Symbol>> getUserCustomSymbols(String userUid) async {
    try {
      AACLogger.debug('Fetching custom symbols for user: $userUid', tag: 'SharedResourceService');
      
      final snapshot = await _firestore
          .collection('$_userCustomSymbolsPath/$userUid/custom_symbols')
          .orderBy('dateCreated', descending: true)
          .get();
      
      final customSymbols = snapshot.docs
          .map((doc) => Symbol.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
      
      AACLogger.debug('Loaded ${customSymbols.length} custom symbols for user', tag: 'SharedResourceService');
      return customSymbols;
      
    } catch (e) {
      AACLogger.error('Error fetching user custom symbols: $e', tag: 'SharedResourceService');
      return [];
    }
  }
  
  /// Get user's custom categories only (not including defaults)
  static Future<List<Category>> getUserCustomCategories(String userUid) async {
    try {
      AACLogger.debug('Fetching custom categories for user: $userUid', tag: 'SharedResourceService');
      
      final snapshot = await _firestore
          .collection('$_userCustomSymbolsPath/$userUid/custom_categories')
          .orderBy('dateCreated', descending: true)
          .get();
      
      final customCategories = snapshot.docs
          .map((doc) => Category.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
      
      AACLogger.debug('Loaded ${customCategories.length} custom categories for user', tag: 'SharedResourceService');
      return customCategories;
      
    } catch (e) {
      AACLogger.error('Error fetching user custom categories: $e', tag: 'SharedResourceService');
      return [];
    }
  }
  
  /// Get combined symbols: global defaults + user customs
  /// This is the main method the UI should use
  static Future<List<Symbol>> getAllSymbolsForUser(String userUid) async {
    try {
      AACLogger.debug('Fetching all symbols for user: $userUid', tag: 'SharedResourceService');
      
      // Fetch both in parallel for performance
      final results = await Future.wait([
        getGlobalDefaultSymbols(),
        getUserCustomSymbols(userUid),
      ]);
      
      final globalSymbols = results[0] as List<Symbol>;
      final customSymbols = results[1] as List<Symbol>;
      
      // Combine: defaults first, then user customs
      final allSymbols = [...globalSymbols, ...customSymbols];
      
      AACLogger.debug('Combined symbols: ${globalSymbols.length} global + ${customSymbols.length} custom = ${allSymbols.length} total', tag: 'SharedResourceService');
      return allSymbols;
      
    } catch (e) {
      AACLogger.error('Error fetching all symbols for user: $e', tag: 'SharedResourceService');
      return [];
    }
  }
  
  /// Get combined categories: global defaults + user customs  
  /// This is the main method the UI should use
  static Future<List<Category>> getAllCategoriesForUser(String userUid) async {
    try {
      AACLogger.debug('Fetching all categories for user: $userUid', tag: 'SharedResourceService');
      
      // Fetch both in parallel for performance
      final results = await Future.wait([
        getGlobalDefaultCategories(),
        getUserCustomCategories(userUid),
      ]);
      
      final globalCategories = results[0] as List<Category>;
      final customCategories = results[1] as List<Category>;
      
      // Combine: defaults first, then user customs
      final allCategories = [...globalCategories, ...customCategories];
      
      AACLogger.debug('Combined categories: ${globalCategories.length} global + ${customCategories.length} custom = ${allCategories.length} total', tag: 'SharedResourceService');
      return allCategories;
      
    } catch (e) {
      AACLogger.error('Error fetching all categories for user: $e', tag: 'SharedResourceService');
      return [];
    }
  }
  
  /// Add custom symbol for user (image uploaded to user-specific storage)
  static Future<bool> addUserCustomSymbol(String userUid, Symbol symbol, {String? imagePath}) async {
    try {
      AACLogger.info('Adding custom symbol for user $userUid: ${symbol.label}', tag: 'SharedResourceService');
      
      String finalImagePath = symbol.imagePath;
      
      // Upload image to user-specific Firebase Storage if provided
      if (imagePath != null && !imagePath.startsWith('assets/') && !imagePath.startsWith('emoji:')) {
        finalImagePath = await _uploadUserImage(userUid, imagePath, 'symbol_${DateTime.now().millisecondsSinceEpoch}');
      }
      
      // Create symbol with uploaded image path
      final symbolData = symbol.copyWith(
        imagePath: finalImagePath,
        isDefault: false, // User custom symbols are never defaults
        dateCreated: DateTime.now(),
      ).toJson();
      
      // Add metadata
      symbolData['userUid'] = userUid;
      symbolData['createdAt'] = FieldValue.serverTimestamp();
      symbolData['updatedAt'] = FieldValue.serverTimestamp();
      
      // Store in user's custom collection
      await _firestore
          .collection('$_userCustomSymbolsPath/$userUid/custom_symbols')
          .add(symbolData);
      
      AACLogger.info('Successfully added custom symbol: ${symbol.label}', tag: 'SharedResourceService');
      return true;
      
    } catch (e) {
      AACLogger.error('Error adding custom symbol: $e', tag: 'SharedResourceService');
      return false;
    }
  }
  
  /// Add custom category for user (icon uploaded to user-specific storage)
  static Future<bool> addUserCustomCategory(String userUid, Category category, {String? iconPath}) async {
    try {
      AACLogger.info('Adding custom category for user $userUid: ${category.name}', tag: 'SharedResourceService');
      
      String finalIconPath = category.iconPath;
      
      // Upload icon to user-specific Firebase Storage if provided
      if (iconPath != null && !iconPath.startsWith('assets/')) {
        finalIconPath = await _uploadUserImage(userUid, iconPath, 'category_icon_${DateTime.now().millisecondsSinceEpoch}');
      }
      
      // Create category with uploaded icon path
      final categoryData = category.copyWith(
        iconPath: finalIconPath,
        isDefault: false, // User custom categories are never defaults
        dateCreated: DateTime.now(),
      ).toJson();
      
      // Add metadata
      categoryData['userUid'] = userUid;
      categoryData['createdAt'] = FieldValue.serverTimestamp();
      categoryData['updatedAt'] = FieldValue.serverTimestamp();
      
      // Store in user's custom collection
      await _firestore
          .collection('$_userCustomSymbolsPath/$userUid/custom_categories')
          .add(categoryData);
      
      AACLogger.info('Successfully added custom category: ${category.name}', tag: 'SharedResourceService');
      return true;
      
    } catch (e) {
      AACLogger.error('Error adding custom category: $e', tag: 'SharedResourceService');
      return false;
    }
  }
  
  /// Upload user image/icon to Firebase Storage with proper organization
  static Future<String> _uploadUserImage(String userUid, String localPath, String fileName) async {
    try {
      AACLogger.debug('Uploading user image: $fileName', tag: 'SharedResourceService');
      
      // Organized storage path: users/{uid}/images/{filename}
      final storageRef = _storage.ref().child('users/$userUid/images/$fileName');
      
      // Upload file
      final uploadTask = await storageRef.putFile(File(localPath));
      
      // Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      AACLogger.debug('Image uploaded successfully: $downloadUrl', tag: 'SharedResourceService');
      return downloadUrl;
      
    } catch (e) {
      AACLogger.error('Error uploading user image: $e', tag: 'SharedResourceService');
      rethrow;
    }
  }
  
  /// Delete user custom symbol
  static Future<bool> deleteUserCustomSymbol(String userUid, String symbolId) async {
    try {
      AACLogger.info('Deleting custom symbol: $symbolId for user: $userUid', tag: 'SharedResourceService');
      
      // Get symbol data first to delete associated image
      final doc = await _firestore
          .collection('$_userCustomSymbolsPath/$userUid/custom_symbols')
          .doc(symbolId)
          .get();
      
      if (doc.exists) {
        final symbolData = doc.data()!;
        final imagePath = symbolData['imagePath'] as String?;
        
        // Delete associated image from storage if it's a Firebase Storage URL
        if (imagePath != null && imagePath.startsWith('https://firebasestorage.googleapis.com')) {
          await _deleteUserImage(imagePath);
        }
        
        // Delete document
        await doc.reference.delete();
        
        AACLogger.info('Successfully deleted custom symbol', tag: 'SharedResourceService');
        return true;
      }
      
      return false;
      
    } catch (e) {
      AACLogger.error('Error deleting custom symbol: $e', tag: 'SharedResourceService');
      return false;
    }
  }
  
  /// Delete user custom category
  static Future<bool> deleteUserCustomCategory(String userUid, String categoryId) async {
    try {
      AACLogger.info('Deleting custom category: $categoryId for user: $userUid', tag: 'SharedResourceService');
      
      // Get category data first to delete associated icon
      final doc = await _firestore
          .collection('$_userCustomSymbolsPath/$userUid/custom_categories')
          .doc(categoryId)
          .get();
      
      if (doc.exists) {
        final categoryData = doc.data()!;
        final iconPath = categoryData['iconPath'] as String?;
        
        // Delete associated icon from storage if it's a Firebase Storage URL
        if (iconPath != null && iconPath.startsWith('https://firebasestorage.googleapis.com')) {
          await _deleteUserImage(iconPath);
        }
        
        // Delete document
        await doc.reference.delete();
        
        AACLogger.info('Successfully deleted custom category', tag: 'SharedResourceService');
        return true;
      }
      
      return false;
      
    } catch (e) {
      AACLogger.error('Error deleting custom category: $e', tag: 'SharedResourceService');
      return false;
    }
  }
  
  /// Delete user image from Firebase Storage
  static Future<void> _deleteUserImage(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      AACLogger.debug('Deleted image from storage: $downloadUrl', tag: 'SharedResourceService');
    } catch (e) {
      AACLogger.warning('Could not delete image from storage: $e', tag: 'SharedResourceService');
      // Don't rethrow - image deletion failure shouldn't stop document deletion
    }
  }
  
  /// Initialize default categories in global collection
  static Future<void> _initializeDefaultCategories() async {
    try {
      final batch = _firestore.batch();
      final collection = _firestore.collection(_globalCategoriesCollection);
      
      final defaultCategories = [
        {
          'name': 'Food & Drinks',
          'iconPath': 'assets/icons/food.png',
          'colorCode': 0xFFFF6B6B,
          'isDefault': true,
          'dateCreated': DateTime.now().toIso8601String(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Vehicles',
          'iconPath': 'assets/icons/vehicles.png',
          'colorCode': 0xFF4ECDC4,
          'isDefault': true,
          'dateCreated': DateTime.now().toIso8601String(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Emotions',
          'iconPath': 'assets/icons/emotions.png',
          'colorCode': 0xFFFFE66D,
          'isDefault': true,
          'dateCreated': DateTime.now().toIso8601String(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Actions',
          'iconPath': 'assets/icons/actions.png',
          'colorCode': 0xFF6C63FF,
          'isDefault': true,
          'dateCreated': DateTime.now().toIso8601String(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Family',
          'iconPath': 'assets/icons/family.png',
          'colorCode': 0xFFFF9F43,
          'isDefault': true,
          'dateCreated': DateTime.now().toIso8601String(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Basic Needs',
          'iconPath': 'assets/icons/needs.png',
          'colorCode': 0xFF51CF66,
          'isDefault': true,
          'dateCreated': DateTime.now().toIso8601String(),
          'createdAt': FieldValue.serverTimestamp(),
        },
      ];
      
      for (final categoryData in defaultCategories) {
        final docRef = collection.doc(); // Auto-generate ID
        batch.set(docRef, categoryData);
      }
      
      await batch.commit();
      AACLogger.info('Global default categories initialized', tag: 'SharedResourceService');
      
    } catch (e) {
      AACLogger.error('Error initializing default categories: $e', tag: 'SharedResourceService');
      rethrow;
    }
  }
  
  /// Initialize default symbols in global collection (subset for brevity)
  static Future<void> _initializeDefaultSymbols() async {
    try {
      final batch = _firestore.batch();
      final collection = _firestore.collection(_globalSymbolsCollection);
      
      // Core essential symbols - this would be expanded with full symbol set
      final defaultSymbols = [
        {
          'label': 'Apple',
          'imagePath': 'assets/symbols/Apple.png',
          'category': 'Food & Drinks',
          'description': 'Red apple fruit',
          'isDefault': true,
          'dateCreated': DateTime.now().toIso8601String(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'label': 'Water',
          'imagePath': 'assets/symbols/Water.png',
          'category': 'Food & Drinks',
          'description': 'Glass of water',
          'isDefault': true,
          'dateCreated': DateTime.now().toIso8601String(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'label': 'Car',
          'imagePath': 'assets/symbols/Car.png',
          'category': 'Vehicles',
          'description': 'Family car',
          'isDefault': true,
          'dateCreated': DateTime.now().toIso8601String(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'label': 'Happy',
          'imagePath': 'emoji:😊',
          'category': 'Emotions',
          'description': 'Feeling happy',
          'isDefault': true,
          'dateCreated': DateTime.now().toIso8601String(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        // TODO: Migrate all symbols from SampleData to this global collection
      ];
      
      for (final symbolData in defaultSymbols) {
        final docRef = collection.doc(); // Auto-generate ID
        batch.set(docRef, symbolData);
      }
      
      await batch.commit();
      AACLogger.info('Global default symbols initialized', tag: 'SharedResourceService');
      
    } catch (e) {
      AACLogger.error('Error initializing default symbols: $e', tag: 'SharedResourceService');
      rethrow;
    }
  }
  
  /// Get storage statistics for monitoring
  static Future<Map<String, dynamic>> getStorageStats(String userUid) async {
    try {
      final customSymbols = await getUserCustomSymbols(userUid);
      final customCategories = await getUserCustomCategories(userUid);
      final globalSymbols = await getGlobalDefaultSymbols();
      final globalCategories = await getGlobalDefaultCategories();
      
      return {
        'user_custom_symbols': customSymbols.length,
        'user_custom_categories': customCategories.length,
        'global_default_symbols': globalSymbols.length,
        'global_default_categories': globalCategories.length,
        'total_symbols_available': globalSymbols.length + customSymbols.length,
        'total_categories_available': globalCategories.length + customCategories.length,
        'storage_efficiency': '${((globalSymbols.length / (globalSymbols.length + customSymbols.length)) * 100).toStringAsFixed(1)}% shared resources',
      };
    } catch (e) {
      AACLogger.error('Error getting storage stats: $e', tag: 'SharedResourceService');
      return {'error': e.toString()};
    }
  }
}
