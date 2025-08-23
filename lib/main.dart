import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'utils/aac_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  bool firebaseInitialized = false;
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    firebaseInitialized = true;
  } catch (e) {
    print('Firebase initialization failed: $e');
    // Continue without Firebase
  }
  
  try {
    // Initialize database and TTS
    await AACHelper.initializeDatabase();
    await AACHelper.initializeTTS();
    
    // Initialize SharedPreferences
    await SharedPreferences.getInstance();
    
    // Set preferred orientations (portrait only for children)
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  } catch (e) {
    print('Error during initialization: $e');
    // Continue with app startup even if initialization fails
  }
  
  runApp(AACApp(firebaseInitialized: firebaseInitialized));
}

class AACApp extends StatelessWidget {
  final bool firebaseInitialized;
  
  const AACApp({super.key, required this.firebaseInitialized});

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
      home: firebaseInitialized
          ? StreamBuilder<User?>(
              stream: AuthService().authStateChanges,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CupertinoActivityIndicator(
                        radius: 20,
                        color: Color(0xFF4299E1),
                      ),
                    ),
                  );
                }
                
                if (snapshot.hasData) {
                  return const HomeScreen();
                }
                
                return const LoginScreen();
              },
            )
          : const HomeScreen(),
    );
  }
}

