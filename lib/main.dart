import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/auth_wrapper.dart';  // Use auth wrapper instead of direct home screen
import 'services/migration_service.dart';  // NEW: Add migration service
import 'services/data_recovery_service.dart';  // NEW: Add data recovery service
import 'services/connectivity_service.dart';  // NEW: Add connectivity service
import 'services/data_cache_service.dart';  // NEW: Add data cache service
import 'services/offline_features_service.dart';  // NEW: Add offline features service

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  bool firebaseAvailable = false;
  
  // Initialize Firebase with corruption fix
  try {
    await Firebase.initializeApp();
    
    // EMERGENCY FIX: Clear corrupt Firebase cache to prevent crashes
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.terminate();  // Disconnect from Firestore
      await firestore.clearPersistence();  // Clear local cache
      debugPrint('Firebase cache cleared to fix corruption');
    } catch (clearError) {
      debugPrint('Could not clear Firebase cache (normal on fresh install): $clearError');
    }
    
    firebaseAvailable = true;
    debugPrint('Firebase initialized successfully');
    
    // NEW: Perform data health check and recovery if needed
    try {
      debugPrint('Performing data health check...');
      await DataRecoveryService.performDataHealthCheck();
      debugPrint('Data health check completed');
    } catch (recoveryError) {
      debugPrint('Data recovery error (app will continue): $recoveryError');
      // Don't fail app startup if data recovery fails
    }
    
    // NEW: Perform migration to shared architecture if needed
    try {
      debugPrint('Checking for migration to shared architecture...');
      await MigrationService.performMigrationIfNeeded();
      debugPrint('Migration check completed successfully');
    } catch (migrationError) {
      debugPrint('Migration error (app will continue): $migrationError');
      // Don't fail app startup if migration fails
    }
    // NOTE: Enterprise services will be initialized in background after UI loads
    // This ensures offline-first functionality with fast app startup
    
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
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
    debugPrint('Main: Error setting system UI: $e');
  }
  
  // Start the app with Firebase availability status
  runApp(AACApp(firebaseAvailable: firebaseAvailable));
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
      // Direct auth wrapper - connectivity indicators removed since we have offline-first architecture
      home: AuthWrapper(firebaseAvailable: firebaseAvailable),
    );
  }
}
