import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'utils/aac_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
  
  runApp(const AACApp());
}

class AACApp extends StatelessWidget {
  const AACApp({super.key});

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
      home: const HomeScreen(),
    );
  }
}

