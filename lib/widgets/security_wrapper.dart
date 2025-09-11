import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/secure_auth_service.dart';
import '../services/coppa_compliance_service.dart';
import '../utils/aac_logger.dart';

/// Security Wrapper Widget that ensures proper authentication and compliance
/// This widget wraps the main app and provides security layer
class SecurityWrapper extends StatefulWidget {
  final Widget child;
  final Widget? loadingWidget;
  final Widget? signInWidget;
  
  const SecurityWrapper({
    Key? key,
    required this.child,
    this.loadingWidget,
    this.signInWidget,
  }) : super(key: key);

  @override
  State<SecurityWrapper> createState() => _SecurityWrapperState();
}

class _SecurityWrapperState extends State<SecurityWrapper> with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeSecurity();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SecureAuthService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
        _onAppPaused();
        break;
      case AppLifecycleState.detached:
        _onAppDetached();
        break;
      default:
        break;
    }
  }

  Future<void> _initializeSecurity() async {
    try {
      AACLogger.info('Initializing security wrapper');
      
      // Listen to authentication state changes for security monitoring
      FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
      
      // Initialize security monitoring without blocking the UI
      // The AuthWrapper child will handle the actual authentication flow
      setState(() {
        _isAuthenticated = FirebaseAuth.instance.currentUser != null;
        _isLoading = false;
      });
      
      // Initialize secure session if user is already authenticated
      if (_isAuthenticated) {
        await SecureAuthService.initializeSecureSession();
      }
      
    } catch (e) {
      AACLogger.error('Failed to initialize security wrapper: $e');
      setState(() {
        _isLoading = false;
        _isAuthenticated = false;
      });
    }
  }

  Future<void> _onAuthStateChanged(User? user) async {
    try {
      final wasAuthenticated = _isAuthenticated;
      final isNowAuthenticated = user != null;
      
      if (isNowAuthenticated && !wasAuthenticated) {
        // User just signed in
        AACLogger.info('User authenticated, initializing secure session');
        await SecureAuthService.initializeSecureSession();
      } else if (!isNowAuthenticated && wasAuthenticated) {
        // User just signed out
        AACLogger.info('User signed out, cleaning up security');
      }
      
      setState(() {
        _isAuthenticated = isNowAuthenticated;
      });
      
    } catch (e) {
      AACLogger.error('Error handling auth state change: $e');
    }
  }

  void _onAppResumed() {
    if (SecureAuthService.isAuthenticated) {
      SecureAuthService.updateUserActivity();
      AACLogger.info('App resumed, updating user activity');
    }
  }

  void _onAppPaused() {
    if (SecureAuthService.isAuthenticated) {
      SecureAuthService.updateUserActivity();
      AACLogger.info('App paused, updating user activity');
    }
  }

  void _onAppDetached() {
    AACLogger.info('App detached, cleaning up security resources');
    SecureAuthService.dispose();
  }

  Widget _buildLoadingWidget() {
    return widget.loadingWidget ?? 
      const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing security...'),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }
    
    // Always pass through to child (AuthWrapper) - let it handle authentication UI
    // SecurityWrapper provides background security monitoring only
    return widget.child;
  }
}
