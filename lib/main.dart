import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'widgets/auth_wrapper.dart';  // Use auth wrapper instead of direct home screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  bool firebaseAvailable = false;
  
  // Initialize Firebase with better error handling
  try {
    debugPrint('Main: Attempting to initialize Firebase...');
    await Firebase.initializeApp();
    firebaseAvailable = true;
    debugPrint('Main: Firebase initialized successfully');
  } catch (e) {
    debugPrint('Main: Firebase initialization error: $e');
    if (e.toString().contains('INVALID_API_KEY')) {
      debugPrint('Main: Invalid Firebase API key - check firebase configuration');
    } else if (e.toString().contains('NETWORK_ERROR')) {
      debugPrint('Main: Network error during Firebase initialization');
    } else if (e.toString().contains('duplicate-app')) {
      debugPrint('Main: Firebase app already initialized');
      firebaseAvailable = true; // This is actually OK
    }
    
    // If it's just a network issue, we still want to try using Firebase later
    if (e.toString().contains('NETWORK_ERROR') || e.toString().contains('network')) {
      firebaseAvailable = true; // Let the app try to use Firebase services
    }
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
