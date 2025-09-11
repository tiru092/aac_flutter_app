import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/auth_wrapper.dart';  // Use auth wrapper instead of direct home screen
import 'widgets/security_wrapper.dart';  // NEW: Security wrapper for enhanced protection
import 'services/migration_service.dart';  // NEW: Add migration service
import 'services/data_recovery_service.dart';  // NEW: Add data recovery service
import 'services/secure_logger.dart';  // Secure logging
import 'services/firebase_security_service.dart';  // Firebase security hardening
import 'services/data_services_initializer.dart';  // NEW: Centralized data services with Firebase UID

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  bool firebaseAvailable = false;
  
  // FAST STARTUP: Only do essential Firebase initialization
  try {
    await Firebase.initializeApp();
    firebaseAvailable = true;
    SecureLogger.info('Firebase initialized successfully');
    
    // DEFER heavy operations to background after UI loads
    _initializeBackgroundServices();
    
  } catch (e) {
    SecureLogger.error('Firebase initialization error', e);
    firebaseAvailable = false;
  }
  
  // Only do essential initialization here to avoid blocking UI
  try {
    // Set preferred orientations first
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  } catch (e) {
    SecureLogger.error('Main: Error setting system UI', e);
  }
  
  // Start the app with Firebase availability status
  runApp(AACApp(firebaseAvailable: firebaseAvailable));
}

// Background initialization to avoid blocking startup
void _initializeBackgroundServices() {
  // Run heavy operations in background after UI loads
  Future.microtask(() async {
    try {
      // IMPROVED: More robust Firebase cache handling
      try {
        final firestore = FirebaseFirestore.instance;
        
        // Check if Firestore is already initialized before attempting operations
        try {
          // Only terminate if it's actually running
          await firestore.terminate();
          SecureLogger.info('Firebase terminated successfully');
        } catch (terminateError) {
          SecureLogger.info('Firebase termination skipped (not initialized)');
        }
        
        // Only clear persistence if safe to do so
        try {
          await firestore.clearPersistence();
          SecureLogger.info('Firebase cache cleared to fix corruption');
        } catch (clearError) {
          SecureLogger.info('Could not clear Firebase cache (normal on fresh install)');
          // This is expected and not an error
        }
      } catch (cacheError) {
        SecureLogger.info('Firebase cache operations completed with expected warnings');
      }

      // Initialize Firebase security hardening
      try {
        SecureLogger.info('Initializing Firebase security hardening...');
        await FirebaseSecurityService().initialize();
        SecureLogger.info('Firebase security hardening initialized successfully');
      } catch (securityError) {
        SecureLogger.warning('Firebase security hardening failed (app will continue)', securityError);
      }

      // Perform data health check and recovery if needed
      try {
        SecureLogger.info('Performing data health check...');
        await DataRecoveryService.performDataHealthCheck();
        SecureLogger.info('Data health check completed');
      } catch (recoveryError) {
        SecureLogger.warning('Data recovery error (app will continue)', recoveryError);
      }

      // Perform migration to shared architecture if needed
      try {
        SecureLogger.info('Checking for migration to shared architecture...');
        await MigrationService.performMigrationIfNeeded();
        SecureLogger.info('Migration check completed successfully');
      } catch (migrationError) {
        SecureLogger.warning('Migration error (app will continue)', migrationError);
      }

      // NEW: Initialize centralized data services with Firebase UID single source of truth
      try {
        SecureLogger.info('Initializing data services with Firebase UID single source of truth...');
        await DataServicesInitializer().initialize();
        SecureLogger.info('✅ Data services initialized successfully with Firebase UID consistency');
        
        // Log service status for debugging
        DataServicesInitializer().logServiceStatus();
      } catch (dataServicesError) {
        SecureLogger.error('Data services initialization failed', dataServicesError);
      }
    } catch (e) {
      SecureLogger.error('Background initialization error', e);
    }
  });
}

class AACApp extends StatelessWidget {
  final bool firebaseAvailable;
  
  const AACApp({super.key, required this.firebaseAvailable});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'AAC Communication Helper',
      debugShowCheckedModeBanner: false,
      theme: const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: Color(0xFF4ECDC4),
        scaffoldBackgroundColor: Color(0xFFF8F9FA),
        textTheme: CupertinoTextThemeData(
          primaryColor: Color(0xFF2C3E50),
        ),
      ),
      // NEW: Wrap with security wrapper for enhanced protection
      home: SecurityWrapper(
        child: AuthWrapper(firebaseAvailable: firebaseAvailable),
      ),
    );
  }
}
