/// Centralized Firebase path registry to ensure consistent paths across all services
/// This prevents path inconsistencies that cause Hive/Firebase sync mismatches
class FirebasePathRegistry {
  static const String _usersCollection = 'users';
  static const String _userProfilesCollection = 'user_profiles';
  static const String _symbolsSubcollection = 'symbols';
  static const String _categoriesSubcollection = 'categories';
  static const String _customCategoriesSubcollection = 'custom_categories';
  
  // Global default collections (shared across all users)
  static const String globalDefaultSymbols = 'global_default_symbols';
  static const String globalDefaultCategories = 'global_default_categories';
  
  /// Get user's document path: users/{uid}
  static String userDocument(String uid) => '$_usersCollection/$uid';
  
  /// Get user's symbols collection path: users/{uid}/symbols
  static String userSymbols(String uid) => '$_usersCollection/$uid/$_symbolsSubcollection';
  
  /// Get specific user symbol document path: users/{uid}/symbols/{symbolId}
  static String userSymbolDocument(String uid, String symbolId) => '${userSymbols(uid)}/$symbolId';
  
  /// Get user's custom categories collection path: user_profiles/{uid}/custom_categories
  static String userCustomCategories(String uid) => '$_userProfilesCollection/$uid/$_customCategoriesSubcollection';
  
  /// Get specific user custom category document path: user_profiles/{uid}/custom_categories/{categoryId}
  static String userCustomCategoryDocument(String uid, String categoryId) => '${userCustomCategories(uid)}/$categoryId';
  
  // DEPRECATED PATHS - Use new paths above
  /// @deprecated Use userCustomCategories() instead
  static String userCategories(String uid) => '$_usersCollection/$uid/$_categoriesSubcollection';
  
  /// @deprecated Use userCustomCategoryDocument() instead  
  static String userCategoryDocument(String uid, String categoryId) => '${userCategories(uid)}/$categoryId';
  
  /// Get legacy custom categories path for migration only
  static String legacyUserCustomCategories(String uid) => '$_usersCollection/$uid/custom_categories';
  
  // Hive box naming consistency
  /// Get Hive box name for user symbols
  static String hiveUserSymbolsBox(String uid) => 'symbols_$uid';
  
  /// Get Hive box name for user categories  
  static String hiveUserCategoriesBox(String uid) => 'categories_$uid';
  
  /// Get Hive box name for user favorites
  static String hiveUserFavoritesBox(String uid) => 'favorites_$uid';
  
  /// Get Hive box name for user custom symbols (for CustomSymbolsService)
  static String hiveCustomSymbolsBox(String uid) => 'custom_symbols_$uid';
  
  /// Get Hive box name for user custom categories (for CustomCategoriesService)
  static String hiveCustomCategoriesBox(String uid) => 'custom_categories_$uid';
}
