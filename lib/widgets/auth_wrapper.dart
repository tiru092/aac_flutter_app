import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/data_services_initializer_robust.dart';
import '../services/secure_logger.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';

/// Widget that manages the authentication state and navigation
class AuthWrapper extends StatefulWidget {
  final bool firebaseAvailable;
  
  const AuthWrapper({super.key, this.firebaseAvailable = false});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Stream<User?>? _authStream;

  @override
  void initState() {
    super.initState();
    if (widget.firebaseAvailable) {
      _authStream = FirebaseAuth.instance.authStateChanges();
    }
  }

  /// Initialize data services and sync user data from Firebase
  Future<void> _initializeAndSyncUserData() async {
    try {
      // Check if already initialized to avoid duplicate initialization
      if (DataServicesInitializer.instance.isInitialized) {
        SecureLogger.info('Data services already initialized, skipping initialization');
        return;
      }
      
      // Step 1: Initialize all data services
      await DataServicesInitializer.instance.initialize();
      
      // Step 2: Sync disabled temporarily to prevent deployment issues
      // TODO: Fix sync method null safety issue
      // await DataServicesInitializer.instance.syncUserDataFromCloud();
      
      SecureLogger.info('User data initialization completed successfully');
    } catch (e) {
      SecureLogger.warning('Data services initialization failed in AuthWrapper (will retry in background): $e');
      // Don't rethrow - let the background initialization in main.dart handle it
      // This prevents the UI from showing an error when background initialization will fix it
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.firebaseAvailable) {
      SecureLogger.info('AuthWrapper: Firebase not available, running in offline mode.');
      return const HomeScreen();
    }

    SecureLogger.info('AuthWrapper: Firebase is available, building auth flow.');
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

        // User is logged in, directly check if services are initialized 
        // Skip AuthWrapper initialization since main.dart handles it
        return StreamBuilder<bool>(
          stream: Stream.periodic(const Duration(milliseconds: 500), (_) => DataServicesInitializer.instance.isInitialized),
          builder: (context, streamSnapshot) {
            final isInitialized = streamSnapshot.data ?? false;
                
            if (isInitialized) {
              SecureLogger.info("✅ Data services confirmed initialized, proceeding to HomeScreen");
              return const HomeScreen();
            } else {
              return const _LoadingScreen(message: 'Loading your data...');
            }
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
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}