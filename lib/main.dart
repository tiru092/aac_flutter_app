import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/auth_wrapper.dart';  // Use auth wrapper instead of direct home screen

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
      // Use auth wrapper to handle authentication flow
      home: AuthWrapper(firebaseAvailable: firebaseAvailable),
    );
  }
}
