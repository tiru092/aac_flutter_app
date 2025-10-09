import 'package:flutter/material.dart';
import 'services/data_services_initializer_robust.dart';
import 'services/unified_supabase_auth_service.dart';
import 'models/symbol.dart';

/// Debug screen to test favorites functionality
class DebugFavoritesScreen extends StatefulWidget {
  const DebugFavoritesScreen({super.key});

  @override
  State<DebugFavoritesScreen> createState() => _DebugFavoritesScreenState();
}

class _DebugFavoritesScreenState extends State<DebugFavoritesScreen> {
  String _debugOutput = 'Starting debug...';

  @override
  void initState() {
    super.initState();
    _runDebug();
  }

  Future<void> _runDebug() async {
    String output = '';

    try {
      // Check authentication
      output += 'User ID: ${UnifiedSupabaseAuthService.currentUserId}\n';
      output += 'Is authenticated: ${UnifiedSupabaseAuthService.isAuthenticated}\n\n';

      // Check data services initializer
      final services = DataServicesInitializer.instance;
      output += 'Services initialized: ${services.isInitialized}\n';
      output += 'Has favorites service: ${services.hasFavoritesService}\n';
      
      if (services.hasFavoritesService) {
        final favService = services.favoritesService!;
        output += 'Favorites service initialized: ${favService.isInitialized}\n';
        output += 'Current favorites count: ${favService.favoriteSymbols.length}\n';
        
        // Test adding a favorite
        final testSymbol = Symbol(
          id: 'test-symbol',
          label: 'Test',
          imagePath: 'assets/icons/test.png',
          category: 'Test',
        );
        
        output += '\nTesting add to favorites...\n';
        await favService.addToFavorites(testSymbol);
        output += 'After add - favorites count: ${favService.favoriteSymbols.length}\n';
        output += 'Is test symbol favorite: ${favService.isFavorite(testSymbol)}\n';
        
        // Test removing
        output += '\nTesting remove from favorites...\n';
        await favService.removeFromFavorites(testSymbol);
        output += 'After remove - favorites count: ${favService.favoriteSymbols.length}\n';
        output += 'Is test symbol favorite: ${favService.isFavorite(testSymbol)}\n';
      }

      // Check user data manager
      try {
        final userManager = services.userDataManager;
        output += '\nUser data manager initialized: ${userManager.isInitialized}\n';
        output += 'Current user ID: ${userManager.currentUserId}\n';
        
        // Test favorites box access
        final favBox = await userManager.getFavoritesBox();
        output += 'Favorites box keys: ${favBox.keys.toList()}\n';
        
      } catch (e) {
        output += '\nUser data manager error: $e\n';
      }

    } catch (e, stackTrace) {
      output += '\nDebug error: $e\n';
      output += 'Stack trace: $stackTrace\n';
    }

    if (mounted) {
      setState(() {
        _debugOutput = output;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Favorites'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runDebug,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          _debugOutput,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      ),
    );
  }
}