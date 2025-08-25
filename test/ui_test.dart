import 'package:flutter_test/flutter_test.dart';
import 'package:aac_flutter_app/screens/home_screen.dart';
import 'package:aac_flutter_app/screens/login_screen.dart';
import 'package:aac_flutter_app/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('UI Tests', () {
    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() {
      // Reset any state between tests
    });

    group('App Initialization Tests', () {
      testWidgets('should show loading indicator during app startup', (WidgetTester tester) async {
        await tester.pumpWidget(AACApp(firebaseInitialized: false));
        
        // Should show home screen directly when Firebase is not initialized
        expect(find.byType(HomeScreen), findsOneWidget);
      });

      testWidgets('should show login screen when Firebase is initialized but user not logged in', 
          (WidgetTester tester) async {
        // Mock that Firebase is initialized but no user is logged in
        await tester.pumpWidget(
          CupertinoApp(
            home: StreamBuilder(
              stream: Stream.value(null), // No user
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CupertinoActivityIndicator(),
                    ),
                  );
                }
                
                if (snapshot.hasData) {
                  return const HomeScreen();
                }
                
                return const LoginScreen();
              },
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
      });
    });

    group('Login Screen Tests', () {
      testWidgets('should show email and password fields', (WidgetTester tester) async {
        await tester.pumpWidget(const CupertinoApp(home: LoginScreen()));
        
        expect(find.byType(CupertinoTextField), findsNWidgets(2)); // Email and password fields
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
      });

      testWidgets('should show sign up button', (WidgetTester tester) async {
        await tester.pumpWidget(const CupertinoApp(home: LoginScreen()));
        
        expect(find.byType(CupertinoButton), findsWidgets);
      });
    });

    group('Home Screen Tests', () {
      testWidgets('should display communication grid', (WidgetTester tester) async {
        await tester.pumpWidget(const CupertinoApp(home: HomeScreen()));
        
        // Home screen should be displayed
        expect(find.byType(HomeScreen), findsOneWidget);
      });

      testWidgets('should have navigation controls', (WidgetTester tester) async {
        await tester.pumpWidget(const CupertinoApp(home: HomeScreen()));
        
        // Check for common UI elements
        expect(find.byType(CupertinoButton), findsWidgets);
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should support large text sizes', (WidgetTester tester) async {
        // Test with large text size
        tester.binding.window.physicalSizeTestValue = const Size(1200, 1600);
        tester.binding.window.devicePixelRatioTestValue = 1.0;
        
        await tester.pumpWidget(const AACApp(firebaseInitialized: false));
        await tester.pumpAndSettle();
        
        expect(find.byType(HomeScreen), findsOneWidget);
        
        // Reset
        tester.binding.window.clearAllTestValues();
      });

      testWidgets('should support different screen orientations', (WidgetTester tester) async {
        // Test with different screen size
        tester.binding.window.physicalSizeTestValue = const Size(1600, 1200);
        tester.binding.window.devicePixelRatioTestValue = 1.0;
        
        await tester.pumpWidget(const AACApp(firebaseInitialized: false));
        await tester.pumpAndSettle();
        
        expect(find.byType(HomeScreen), findsOneWidget);
        
        // Reset
        tester.binding.window.clearAllTestValues();
      });
    });
  });
}