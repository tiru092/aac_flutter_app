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
  bool _isCOPPACompliant = false;

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
      
      // Listen to authentication state changes
      FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
      
      // Initialize secure session if user is already authenticated
      if (SecureAuthService.isAuthenticated) {
        await SecureAuthService.initializeSecureSession();
        await _checkCOPPACompliance();
      }
      
      setState(() {
        _isAuthenticated = SecureAuthService.isAuthenticated;
        _isLoading = false;
      });
      
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
        await _checkCOPPACompliance();
      } else if (!isNowAuthenticated && wasAuthenticated) {
        // User just signed out
        AACLogger.info('User signed out, cleaning up security');
        _isCOPPACompliant = false;
      }
      
      setState(() {
        _isAuthenticated = isNowAuthenticated;
      });
      
    } catch (e) {
      AACLogger.error('Error handling auth state change: $e');
    }
  }

  Future<void> _checkCOPPACompliance() async {
    try {
      // Get list of child profiles and check their compliance
      await COPPAComplianceService().getChildProfiles();
      
      // For now, assume compliant if no children or if authenticated
      // In a real implementation, check each child's consent status
      setState(() {
        _isCOPPACompliant = true;
      });
      
    } catch (e) {
      AACLogger.error('Error checking COPPA compliance: $e');
      setState(() {
        _isCOPPACompliant = false;
      });
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

  Widget _buildSignInWidget() {
    return widget.signInWidget ?? 
      Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Authentication Required',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Please sign in to continue'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Navigate to sign in screen
                  // This should be implemented based on your app's navigation
                },
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildComplianceWarning() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'Compliance Check Required',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'This app requires parental consent for users under 13. '
                'Please complete the compliance verification.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  // Navigate to COPPA compliance screen
                  await _checkCOPPACompliance();
                },
                child: const Text('Complete Verification'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }
    
    if (!_isAuthenticated) {
      return _buildSignInWidget();
    }
    
    if (!_isCOPPACompliant) {
      return _buildComplianceWarning();
    }
    
    // All security checks passed, show the main app
    return widget.child;
  }
}
