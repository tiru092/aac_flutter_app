// Enhanced HomeScreen data loading methods for shared architecture
// This replaces the old data loading methods in home_screen.dart

import '../services/enhanced_user_profile_service.dart';
import '../services/shared_resource_service.dart';
import '../utils/aac_logger.dart';

/// NEW: Enhanced data loading using SharedResourceService
/// This replaces _initializeImmediately() and _loadDataAsync()
class EnhancedHomeScreenDataLoader {
  
  /// Load data using new shared architecture
  /// This method should replace the old _loadDataAsync() in HomeScreen
  static Future<Map<String, dynamic>> loadAllDataForUser() async {
    try {
      AACLogger.info('Loading data using shared architecture...', tag: 'HomeScreenDataLoader');
      
      // Load both symbols and categories in parallel for performance
      final results = await Future.wait([
        UserProfileService.getAllSymbolsForUser(),
        UserProfileService.getAllCategoriesForUser(),
      ]);
      
      final allSymbols = results[0] as List<Symbol>;
      final allCategories = results[1] as List<Category>;
      
      // Separate custom categories for UI
      final customCategories = allCategories.where((cat) => !cat.isDefault).toList();
      
      AACLogger.info('Loaded ${allSymbols.length} symbols and ${allCategories.length} categories', tag: 'HomeScreenDataLoader');
      
      return {
        'success': true,
        'allSymbols': allSymbols,
        'categories': allCategories,
        'customCategories': customCategories,
        'message': 'Data loaded successfully using shared architecture',
      };
      
    } catch (e) {
      AACLogger.error('Error loading data with shared architecture: $e', tag: 'HomeScreenDataLoader');
      
      // Fallback to sample data if shared architecture fails
      return await _loadFallbackData();
    }
  }
  
  /// Fallback to sample data if shared architecture fails
  static Future<Map<String, dynamic>> _loadFallbackData() async {
    try {
      AACLogger.warning('Falling back to sample data...', tag: 'HomeScreenDataLoader');
      
      final sampleSymbols = SampleData.getSampleSymbols();
      final sampleCategories = SampleData.getSampleCategories();
      
      return {
        'success': true,
        'allSymbols': sampleSymbols,
        'categories': sampleCategories,
        'customCategories': <Category>[],
        'message': 'Using sample data (shared architecture failed)',
        'fallback': true,
      };
      
    } catch (e) {
      AACLogger.error('Even fallback data loading failed: $e', tag: 'HomeScreenDataLoader');
      
      return {
        'success': false,
        'allSymbols': <Symbol>[],
        'categories': <Category>[],
        'customCategories': <Category>[],
        'message': 'All data loading failed: $e',
        'error': e.toString(),
      };
    }
  }
  
  /// Get storage statistics for current user
  static Future<Map<String, dynamic>> getStorageStats() async {
    try {
      return await UserProfileService.getStorageStats();
    } catch (e) {
      AACLogger.error('Error getting storage stats: $e', tag: 'HomeScreenDataLoader');
      return {'error': e.toString()};
    }
  }
  
  /// Add custom symbol using new architecture
  static Future<bool> addCustomSymbol(Symbol symbol, {String? imagePath}) async {
    try {
      AACLogger.info('Adding custom symbol: ${symbol.label}', tag: 'HomeScreenDataLoader');
      
      final success = await UserProfileService.addCustomSymbol(symbol, imagePath: imagePath);
      
      if (success) {
        AACLogger.info('Successfully added custom symbol', tag: 'HomeScreenDataLoader');
      }
      
      return success;
      
    } catch (e) {
      AACLogger.error('Error adding custom symbol: $e', tag: 'HomeScreenDataLoader');
      return false;
    }
  }
  
  /// Add custom category using new architecture
  static Future<bool> addCustomCategory(Category category, {String? iconPath}) async {
    try {
      AACLogger.info('Adding custom category: ${category.name}', tag: 'HomeScreenDataLoader');
      
      final success = await UserProfileService.addCustomCategory(category, iconPath: iconPath);
      
      if (success) {
        AACLogger.info('Successfully added custom category', tag: 'HomeScreenDataLoader');
      }
      
      return success;
      
    } catch (e) {
      AACLogger.error('Error adding custom category: $e', tag: 'HomeScreenDataLoader');
      return false;
    }
  }
  
  /// Delete custom symbol using new architecture
  static Future<bool> deleteCustomSymbol(String symbolId) async {
    try {
      AACLogger.info('Deleting custom symbol: $symbolId', tag: 'HomeScreenDataLoader');
      
      final success = await UserProfileService.deleteCustomSymbol(symbolId);
      
      if (success) {
        AACLogger.info('Successfully deleted custom symbol', tag: 'HomeScreenDataLoader');
      }
      
      return success;
      
    } catch (e) {
      AACLogger.error('Error deleting custom symbol: $e', tag: 'HomeScreenDataLoader');
      return false;
    }
  }
  
  /// Delete custom category using new architecture
  static Future<bool> deleteCustomCategory(String categoryId) async {
    try {
      AACLogger.info('Deleting custom category: $categoryId', tag: 'HomeScreenDataLoader');
      
      final success = await UserProfileService.deleteCustomCategory(categoryId);
      
      if (success) {
        AACLogger.info('Successfully deleted custom category', tag: 'HomeScreenDataLoader');
      }
      
      return success;
      
    } catch (e) {
      AACLogger.error('Error deleting custom category: $e', tag: 'HomeScreenDataLoader');
      return false;
    }
  }
}

/// Updated HomeScreen methods to use shared architecture
/// These should replace the existing methods in home_screen.dart

/*
  /// NEW: Replace _loadDataAsync() with this method
  Future<void> _loadDataWithSharedArchitecture() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      // Load data using new shared architecture
      final result = await EnhancedHomeScreenDataLoader.loadAllDataForUser();
      
      if (mounted) {
        setState(() {
          if (result['success'] == true) {
            _allSymbols = result['allSymbols'] as List<Symbol>;
            _categories = result['categories'] as List<Category>;
            _customCategories = result['customCategories'] as List<Category>;
            _errorMessage = result['fallback'] == true ? result['message'] : null;
          } else {
            _errorMessage = result['message'];
          }
          _isLoading = false;
        });
      }
      
      // Load speech settings
      _loadSpeechSettings();
      
    } catch (e) {
      AACLogger.error('Error in _loadDataWithSharedArchitecture: $e', tag: 'HomeScreen');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading data: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  /// NEW: Replace _onSymbolUpdate() to use shared architecture
  void _onSymbolUpdateWithSharedArchitecture(Symbol updatedSymbol) async {
    try {
      AACLogger.debug('Symbol update received: ${updatedSymbol.label}', tag: 'HomeScreen');
      
      // Check if this is a custom symbol or default symbol
      if (!updatedSymbol.isDefault) {
        // For custom symbols, we may need to update in Firebase
        // Implementation depends on whether this is an edit of existing custom symbol
        // For now, just update the local list
      }
      
      setState(() {
        // Find and update the symbol in _allSymbols
        final index = _allSymbols.indexWhere((s) => s.id == updatedSymbol.id);
        if (index != -1) {
          _allSymbols[index] = updatedSymbol;
        }
      });
      
      _trySpeak('Symbol updated successfully');
      
    } catch (e) {
      AACLogger.error('Error updating symbol: $e', tag: 'HomeScreen');
      _showErrorDialog('Failed to update symbol');
    }
  }
  
  /// NEW: Replace _onSymbolDelete() to use shared architecture
  void _onSymbolDeleteWithSharedArchitecture(Symbol deletedSymbol) async {
    try {
      AACLogger.debug('Symbol deletion received: ${deletedSymbol.label}', tag: 'HomeScreen');
      
      // If it's a custom symbol, delete from Firebase
      if (!deletedSymbol.isDefault && deletedSymbol.id != null) {
        final success = await EnhancedHomeScreenDataLoader.deleteCustomSymbol(deletedSymbol.id!);
        if (!success) {
          _showErrorDialog('Failed to delete symbol from server');
          return;
        }
      }
      
      setState(() {
        // Remove the symbol from _allSymbols
        _allSymbols.removeWhere((s) => s.id == deletedSymbol.id);
      });
      
      _trySpeak('Symbol deleted successfully');
      
    } catch (e) {
      AACLogger.error('Error deleting symbol: $e', tag: 'HomeScreen');
      _showErrorDialog('Failed to delete symbol');
    }
  }
  
  /// NEW: Add method to show storage statistics
  void _showStorageStats() async {
    try {
      final stats = await EnhancedHomeScreenDataLoader.getStorageStats();
      
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Storage Statistics'),
          content: Text(
            'Custom Symbols: ${stats['user_custom_symbols'] ?? 'Unknown'}\n'
            'Custom Categories: ${stats['user_custom_categories'] ?? 'Unknown'}\n'
            'Total Symbols: ${stats['total_symbols_available'] ?? 'Unknown'}\n'
            'Total Categories: ${stats['total_categories_available'] ?? 'Unknown'}\n'
            'Efficiency: ${stats['storage_efficiency'] ?? 'Unknown'}'
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      
    } catch (e) {
      _showErrorDialog('Error loading storage statistics: $e');
    }
  }
*/

/// Required imports for the enhanced home screen methods
import '../models/symbol.dart';
import '../utils/sample_data.dart';
