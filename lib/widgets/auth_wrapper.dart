import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/unified_supabase_auth_service.dart';
import '../services/data_services_initializer_robust.dart';
import '../services/aac_localizations.dart';
import '../services/secure_logger.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';

/// Widget that manages the authentication state and navigation
class AuthWrapper extends StatefulWidget {
  final bool supabaseAvailable;
  
  const AuthWrapper({super.key, this.supabaseAvailable = true});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Stream<User?>? _authStream;

  @override
  void initState() {
    super.initState();
    // Initialize Supabase auth service and stream
    UnifiedSupabaseAuthService.initialize();
    _authStream = UnifiedSupabaseAuthService.userChanges;
  }

  /// Simple initialization - load local data first, sync in background
  Future<void> _initializeAndSyncUserData() async {
    try {
      SecureLogger.info('Simple initialization: Loading local data first...');
      
      // Check if already initialized
      if (DataServicesInitializer.instance.isInitialized) {
        print('🔥 DIAGNOSTIC: AuthWrapper - DataServices already initialized, running DIRECT FIX anyway...');
        SecureLogger.info('Data services already initialized, running direct FavoritesService fix');
        
        // DIRECT FIX: Ensure FavoritesService is properly initialized with Supabase UID
        print('🔥 DIRECT FIX: Checking FavoritesService initialization...');
        final favoritesService = DataServicesInitializer.instance.favoritesService;
        if (favoritesService != null) {
          print('🔥 DIRECT FIX: FavoritesService exists, checking if initialized...');
          // Get current Supabase user UID
          final currentUser = Supabase.instance.client.auth.currentUser;
          if (currentUser != null) {
            print('🔥 DIRECT FIX: Getting UserDataManager...');
            final userDataManager = DataServicesInitializer.instance.userDataManager;
            print('🔥 DIRECT FIX: Calling initializeWithUid with Supabase UID: ${currentUser.id}');
            await favoritesService.initializeWithUid(currentUser.id, userDataManager);
            print('🔥 DIRECT FIX: ✅ FavoritesService initialized successfully with Supabase!');
          } else {
            print('🔥 DIRECT FIX: ❌ No Supabase user found');
          }
        } else {
          print('🔥 DIRECT FIX: ❌ FavoritesService is null');
        }
        
        // Start background sync without waiting
        _startBackgroundSync();
        return;
      }
      
      print('🔥 DIAGNOSTIC: AuthWrapper - About to call DataServicesInitializer.initialize()');
      
      // Initialize with local data only - this should be fast
      await DataServicesInitializer.instance.initialize();
      SecureLogger.info('Local data initialization completed');
      
      // DIRECT FIX: Ensure FavoritesService is properly initialized with Supabase UID
      print('🔥 DIRECT FIX: Checking FavoritesService initialization...');
      final favoritesService = DataServicesInitializer.instance.favoritesService;
      if (favoritesService != null) {
        print('🔥 DIRECT FIX: FavoritesService exists, checking if initialized...');
        // Get current Supabase user UID
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser != null) {
          print('🔥 DIRECT FIX: Getting UserDataManager...');
          final userDataManager = DataServicesInitializer.instance.userDataManager;
          print('🔥 DIRECT FIX: Calling initializeWithUid with Supabase UID: ${currentUser.id}');
          await favoritesService.initializeWithUid(currentUser.id, userDataManager);
          print('🔥 DIRECT FIX: ✅ FavoritesService initialized successfully with Supabase!');
        } else {
          print('🔥 DIRECT FIX: ❌ No Supabase user found');
        }
      } else {
        print('🔥 DIRECT FIX: ❌ FavoritesService is null');
      }
      
      // Start background sync without blocking UI
      _startBackgroundSync();
      
    } catch (e) {
      SecureLogger.warning('Local data initialization failed, will use defaults: $e');
      // Don't rethrow - let user proceed with default data
    }
  }
  
  /// Start background sync without blocking UI
  void _startBackgroundSync() {
    Future.microtask(() async {
      try {
        SecureLogger.info('Starting background cloud sync...');
        await DataServicesInitializer.instance.syncUserDataFromCloud();
        SecureLogger.info('Background cloud sync completed');
      } catch (e) {
        SecureLogger.warning('Background sync failed (app continues normally): $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Using Supabase Auth - always available
    SecureLogger.info('AuthWrapper: Building auth flow with Supabase.');
    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen(message: 'Connecting to services...');
        }

        final user = snapshot.data;

        if (user == null) {
          // User is logged out, reset services and show login screen
          return FutureBuilder(
            future: DataServicesInitializer.instance.reset(),
            builder: (context, resetSnapshot) {
              if (resetSnapshot.connectionState == ConnectionState.waiting) {
                return const _LoadingScreen(message: 'Signing out...');
              }
              if (resetSnapshot.hasError) {
                SecureLogger.error("Error during service reset: ${resetSnapshot.error}");
              }
              return const LoginScreen();
            },
          );
        }

        // User is logged in, initialize local data quickly and proceed to home
        return FutureBuilder(
          future: _initializeAndSyncUserData(),
          builder: (context, initSnapshot) {
            if (initSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen(message: 'Loading your data...');
            }
            
            // Always proceed to home screen - don't show error screens for initialization
            // User can use the app with local/default data while background sync happens
            SecureLogger.info("✅ Proceeding to HomeScreen (local data loaded)");
            return const HomeScreen();
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  final String message;
  const _LoadingScreen({this.message = 'Loading...'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CupertinoActivityIndicator(radius: 16),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorScreen({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.exclamationmark_triangle, size: 50, color: Colors.red),
              const SizedBox(height: 20),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 20),
              CupertinoButton.filled(
                onPressed: onRetry,
                child: Text(AACLocalizations.of(context)?.translate('try_again') ?? 'Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}