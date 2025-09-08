import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_wrapper_service.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/verify_email_screen.dart';
import '../screens/profile_selection_screen.dart';

/// Widget that manages the authentication state and navigation
class AuthWrapper extends StatefulWidget {
  final bool firebaseAvailable;
  
  const AuthWrapper({super.key, this.firebaseAvailable = false});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthWrapperService _authWrapper = AuthWrapperService();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      await _authWrapper.initialize();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to initialize app. Please restart.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while initializing
    if (_isLoading) {
      return _LoadingScreen(
        firebaseAvailable: widget.firebaseAvailable,
      );
    }

    // Show error screen if initialization failed
    if (_errorMessage != null) {
      return _ErrorScreen(
        message: _errorMessage!,
        onRetry: () {
          setState(() {
            _isLoading = true;
            _errorMessage = null;
          });
          _initializeAuth();
        },
      );
    }

    // For production: Always require authentication when Firebase is available
    if (widget.firebaseAvailable) {
      debugPrint('AuthWrapper: Firebase available, requiring authentication');
      return _buildFirebaseAuthFlow();
    }

    // Fallback to offline mode only when Firebase is completely unavailable
    debugPrint('AuthWrapper: Firebase not available, using offline mode');
    return _buildOfflineFlow();
  }

  /// Build Firebase authentication flow
  Widget _buildFirebaseAuthFlow() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Handle auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _LoadingScreen(firebaseAvailable: widget.firebaseAvailable);
        }

        final user = snapshot.data;
        
        // User is signed in
        if (user != null) {
          return FutureBuilder<bool>(
            future: _authWrapper.isEmailVerificationRequired(),
            builder: (context, verificationSnapshot) {
              if (verificationSnapshot.connectionState == ConnectionState.waiting) {
                return _LoadingScreen(firebaseAvailable: widget.firebaseAvailable);
              }

              final needsVerification = verificationSnapshot.data ?? false;
              
              if (needsVerification) {
                return const VerifyEmailScreen();
              }

              // User is verified, check if they have a profile
              return FutureBuilder<bool>(
                future: _checkUserProfile(),
                builder: (context, profileSnapshot) {
                  if (profileSnapshot.connectionState == ConnectionState.waiting) {
                    return _LoadingScreen(firebaseAvailable: widget.firebaseAvailable);
                  }

                  final hasProfile = profileSnapshot.data ?? false;
                  
                  if (!hasProfile) {
                    return ProfileSelectionScreen(
                      onProfileSelected: (profile) {
                        // Profile selected, navigate to home
                        Navigator.pushReplacement(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                        );
                      },
                    );
                  }

                  return const HomeScreen();
                },
              );
            },
          );
        }

        // User is not signed in - show login screen (no offline option in production)
        return const LoginScreen();
      },
    );
  }

  /// Build offline flow when Firebase is not available
  Widget _buildOfflineFlow() {
    return FutureBuilder<bool>(
      future: _checkLocalProfiles(),
      builder: (context, localSnapshot) {
        if (localSnapshot.connectionState == ConnectionState.waiting) {
          return _LoadingScreen(firebaseAvailable: widget.firebaseAvailable);
        }

        final hasLocalProfiles = localSnapshot.data ?? false;
        
        if (hasLocalProfiles) {
          // Show profile selection or go directly to home
          return FutureBuilder<bool>(
            future: _hasActiveProfile(),
            builder: (context, activeSnapshot) {
              if (activeSnapshot.connectionState == ConnectionState.waiting) {
                return _LoadingScreen(firebaseAvailable: widget.firebaseAvailable);
              }

              final hasActiveProfile = activeSnapshot.data ?? false;
              
              if (hasActiveProfile) {
                return const HomeScreen();
              }

              return ProfileSelectionScreen(
                onProfileSelected: (profile) {
                  Navigator.pushReplacement(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const HomeScreen(),
                    ),
                  );
                },
              );
            },
          );
        }

        // No profiles - go directly to home (will create default profile)
        return const HomeScreen();
      },
    );
  }

  Future<bool> _checkUserProfile() async {
    try {
      return _authWrapper.currentProfile != null;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkLocalProfiles() async {
    try {
      final profiles = await _authWrapper.getAllProfiles();
      return profiles.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _hasActiveProfile() async {
    try {
      return _authWrapper.currentProfile != null;
    } catch (e) {
      return false;
    }
  }
}

/// Loading screen widget
class _LoadingScreen extends StatelessWidget {
  final bool firebaseAvailable;
  
  const _LoadingScreen({required this.firebaseAvailable});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF4ECDC4),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4ECDC4).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.bubble_left_bubble_right_fill,
                color: Colors.white,
                size: 60,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Loading indicator
            const CupertinoActivityIndicator(
              radius: 20,
              color: Color(0xFF4ECDC4),
            ),
            
            const SizedBox(height: 20),
            
            const Text(
              'Loading AAC Communicator...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              firebaseAvailable 
                ? 'Setting up your communication tools'
                : 'Starting in offline mode',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF718096),
              ),
            ),
            
            // Show offline mode indicator if Firebase is not available
            if (!firebaseAvailable) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F8FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF4ECDC4).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.wifi_slash,
                      color: const Color(0xFF4ECDC4),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Offline Mode',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4ECDC4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error screen widget
class _ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorScreen({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFE53E3E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  color: Color(0xFFE53E3E),
                  size: 50,
                ),
              ),
              
              const SizedBox(height: 30),
              
              const Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF718096),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Retry Button
              CupertinoButton.filled(
                onPressed: onRetry,
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Continue Offline Button
              CupertinoButton(
                onPressed: () {
                  // Enable offline mode and go to home
                  AuthWrapperService().enableOfflineMode().then((_) {
                    Navigator.pushReplacement(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                    );
                  });
                },
                child: const Text(
                  'Continue Offline',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6C63FF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}