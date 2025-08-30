import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/auth_wrapper_service.dart';
import '../services/firebase_config_service.dart';
import '../services/connectivity_service.dart';
import '../utils/auth_diagnostics.dart';
import 'sign_up_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authWrapper = AuthWrapperService();
  
  bool _isLoading = false;
  String? _errorMessage;
  int _retryCount = 0;
  static const int maxRetries = 3;
  bool _showConnectionStatus = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    await _signInWithRetry();
  }

  Future<void> _signInWithRetry([bool isRetry = false]) async {
    debugPrint('LoginScreen: Starting sign-in process for ${_emailController.text.trim()} (retry: $isRetry, count: $_retryCount)');
    
    // Input validation
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields';
      });
      return;
    }

    // Check Firebase availability before attempting sign in
    if (!FirebaseConfigService.canUseFirebaseServices()) {
      debugPrint('LoginScreen: Firebase services not available');
      setState(() {
        _errorMessage = 'Authentication services are currently unavailable. Please check your internet connection and try again.';
        _showConnectionStatus = true;
      });
      return;
    }

    // Check internet connectivity before proceeding
    final hasInternet = await ConnectivityService.hasInternetConnection();
    if (!hasInternet) {
      debugPrint('LoginScreen: No internet connection');
      setState(() {
        _errorMessage = 'No internet connection. Please check your network settings and try again.';
        _showConnectionStatus = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      if (!isRetry) {
        _errorMessage = null;
        _showConnectionStatus = false;
      }
    });

    try {
      debugPrint('LoginScreen: Attempting authentication with Firebase');
      final result = await _authWrapper.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      debugPrint('LoginScreen: Sign-in result - success: ${result.isSuccess}, message: ${result.message}');

      if (mounted) {
        if (result.isSuccess) {
          // Reset retry count on success
          _retryCount = 0;
          
          debugPrint('LoginScreen: Sign-in successful, checking verification status');
          // Add a small delay to allow Firebase to sync verification status
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Check if email verification is required
          final needsVerification = await _authWrapper.isEmailVerificationRequired();
          debugPrint('LoginScreen: needsVerification: $needsVerification');
          if (needsVerification) {
            // Show a helpful message and let AuthWrapper handle navigation
            showCupertinoDialog(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                title: const Text('Email Verification Required'),
                content: const Text('Please verify your email to continue. Check your inbox for a verification link!'),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('OK'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
            return;
          }
          
          debugPrint('LoginScreen: Email verified, navigating to home screen');
          // Navigate to home screen
          Navigator.pushAndRemoveUntil(
            context,
            CupertinoPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        } else {
          // Use the specific error message from the auth result
          final errorMsg = _getUserFriendlyErrorMessage(result.message);
          
          // Check if this is a retryable error and we haven't exceeded max retries
          if (_isRetryableError(result.message) && _retryCount < maxRetries && !isRetry) {
            debugPrint('LoginScreen: Retryable error detected, will offer retry option');
            setState(() {
              _errorMessage = '$errorMsg\n\nThis might be a temporary issue. You can try again.';
            });
          } else {
            setState(() {
              _errorMessage = errorMsg;
            });
          }
          
          debugPrint('LoginScreen: Sign-in failed with message: ${result.message}');
        }
      }
    } catch (e) {
      debugPrint('LoginScreen: Exception during sign-in: $e');
      if (mounted) {
        String errorMessage;
        
        // Provide specific error messages based on the exception
        if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your internet connection and try again.';
        } else if (e.toString().contains('too-many-requests')) {
          errorMessage = 'Too many login attempts. Please wait a few minutes and try again.';
        } else if (e.toString().contains('user-not-found')) {
          errorMessage = 'No account found with this email. Please check your email or create a new account.';
        } else if (e.toString().contains('wrong-password') || e.toString().contains('invalid-credential')) {
          errorMessage = 'Incorrect password. Please try again or use "Forgot Password" to reset it.';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = 'Please enter a valid email address.';
        } else if (e.toString().contains('user-disabled')) {
          errorMessage = 'This account has been disabled. Please contact support.';
        } else {
          errorMessage = 'Sign in failed. Please check your email and password, then try again.';
        }
        
        // Check if this is a retryable error and we haven't exceeded max retries
        if (_isRetryableError(e.toString()) && _retryCount < maxRetries && !isRetry) {
          errorMessage += '\n\nThis might be a temporary issue. You can try again.';
        }
        
        setState(() {
          _errorMessage = errorMessage;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Check if an error is retryable (network issues, temporary Firebase issues)
  bool _isRetryableError(String error) {
    final lowerError = error.toLowerCase();
    return lowerError.contains('network') ||
           lowerError.contains('connection') ||
           lowerError.contains('timeout') ||
           lowerError.contains('firebase') ||
           lowerError.contains('service') ||
           lowerError.contains('unavailable');
  }

  /// Retry the sign-in process
  Future<void> _retrySignIn() async {
    if (_retryCount < maxRetries) {
      _retryCount++;
      debugPrint('LoginScreen: Retrying sign-in (attempt $_retryCount/$maxRetries)');
      await _signInWithRetry(true);
    }
  }

  /// Check and display connection status
  Future<void> _checkConnectionStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final statusMessage = await ConnectivityService.getConnectionStatusMessage();
      
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Connection Status'),
            content: Text(statusMessage),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
              if (!statusMessage.contains('working properly')) ...[
                CupertinoDialogAction(
                  child: const Text('Try Again'),
                  onPressed: () {
                    Navigator.pop(context);
                    // Reset connection status and allow retry
                    setState(() {
                      _showConnectionStatus = false;
                      _errorMessage = null;
                    });
                  },
                ),
              ],
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('LoginScreen: Error checking connection status: $e');
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Connection Check Failed'),
            content: const Text('Unable to check connection status. Please verify your internet connection manually.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Convert technical error messages to user-friendly ones
  String _getUserFriendlyErrorMessage(String technicalMessage) {
    final lowerMsg = technicalMessage.toLowerCase();
    
    if (lowerMsg.contains('user-not-found') || lowerMsg.contains('no user found')) {
      return 'No account found with this email. Please check your email or create a new account.';
    } else if (lowerMsg.contains('wrong-password') || lowerMsg.contains('incorrect password') || lowerMsg.contains('invalid-credential')) {
      return 'Incorrect password. Please try again or use "Forgot Password" to reset it.';
    } else if (lowerMsg.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    } else if (lowerMsg.contains('user-disabled')) {
      return 'This account has been disabled. Please contact support.';
    } else if (lowerMsg.contains('too-many-requests')) {
      return 'Too many login attempts. Please wait a few minutes and try again.';
    } else if (lowerMsg.contains('network') || lowerMsg.contains('connection')) {
      return 'Network error. Please check your internet connection and try again.';
    } else if (lowerMsg.contains('email-already-in-use')) {
      return 'An account already exists with this email. Please sign in instead.';
    } else if (lowerMsg.contains('weak-password')) {
      return 'Password is too weak. Please use a stronger password.';
    } else {
      // Return the original message if we can't improve it
      return technicalMessage;
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Email Required'),
          content: const Text('Please enter your email address first'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Reset Password'),
        content: Text('Send password reset email to ${_emailController.text}?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: const Text('Send'),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _authWrapper.resetPassword(_emailController.text.trim());
                if (mounted) {
                  showCupertinoDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: const Text('Email Sent'),
                      content: const Text('Check your email to reset your password'),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text('OK'),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  showCupertinoDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: const Text('Error'),
                      content: const Text('Failed to send reset email'),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text('OK'),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _continueOffline() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authWrapper.enableOfflineMode();
      
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          CupertinoPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to continue offline. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Run comprehensive authentication diagnostics
  Future<void> _runDiagnostics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('LoginScreen: Running authentication diagnostics...');
      final diagnosticResult = await AuthDiagnostics.runCompleteDiagnostics();
      
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Row(
              children: [
                Icon(
                  diagnosticResult.success ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.exclamationmark_triangle_fill,
                  color: diagnosticResult.success ? CupertinoColors.systemGreen : CupertinoColors.systemRed,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text('System Diagnostics'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // Status summary
                  ...diagnosticResult.messages.map((message) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      message,
                      style: const TextStyle(fontSize: 13),
                      textAlign: TextAlign.left,
                    ),
                  )),
                  
                  // Recommendations
                  if (diagnosticResult.recommendations.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Recommendations:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 5),
                    ...diagnosticResult.recommendations.asMap().entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${entry.key + 1}. ${entry.value}',
                        style: const TextStyle(fontSize: 13),
                        textAlign: TextAlign.left,
                      ),
                    )),
                  ],
                ],
              ),
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
              if (diagnosticResult.success) ...[
                CupertinoDialogAction(
                  child: const Text('Try Login Again'),
                  onPressed: () {
                    Navigator.pop(context);
                    // Reset error states and allow user to try again
                    setState(() {
                      _errorMessage = null;
                      _showConnectionStatus = false;
                      _retryCount = 0;
                    });
                  },
                ),
              ],
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('LoginScreen: Error running diagnostics: $e');
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Diagnostic Error'),
            content: Text('Unable to run diagnostics: ${e.toString()}'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // App Logo/Icon
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ECDC4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    CupertinoIcons.bubble_left_bubble_right_fill,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Welcome Text
              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              const Text(
                'Sign in to sync your data across devices',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF718096),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Error Message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFED7D7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFE53E3E),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      // Show retry button for retryable errors
                      if (_errorMessage!.contains('try again') && 
                          _retryCount < maxRetries && 
                          _isRetryableError(_errorMessage!)) ...[
                        const SizedBox(height: 8),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: const Color(0xFF4ECDC4),
                          borderRadius: BorderRadius.circular(8),
                          onPressed: _isLoading ? null : _retrySignIn,
                          child: Text(
                            'Retry (${_retryCount + 1}/$maxRetries)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      // Show connection status button for connection-related errors
                      if (_showConnectionStatus) ...[
                        const SizedBox(height: 8),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: const Color(0xFF9F7AEA),
                          borderRadius: BorderRadius.circular(8),
                          onPressed: _isLoading ? null : _checkConnectionStatus,
                          child: const Text(
                            'Check Connection',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              // Email Field
              const Text(
                'Email',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A5568),
                ),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _emailController,
                placeholder: 'Enter your email',
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF2D3748),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Password Field
              const Text(
                'Password',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A5568),
                ),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _passwordController,
                placeholder: 'Enter your password',
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
                obscureText: true,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF2D3748),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Forgot Password
              GestureDetector(
                onTap: _resetPassword,
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4ECDC4),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Sign In Button
              CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 14),
                color: const Color(0xFF4ECDC4),
                borderRadius: BorderRadius.circular(12),
                onPressed: _isLoading ? null : _signIn,
                child: _isLoading
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              
              const SizedBox(height: 20),
              
              // Continue Offline Button
              CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 14),
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                onPressed: _isLoading ? null : _continueOffline,
                child: const Text(
                  'Continue Offline',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6C63FF),
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Diagnostic Button (only show when there are issues)
              if (_errorMessage != null || _showConnectionStatus) ...[
                Center(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    onPressed: _isLoading ? null : _runDiagnostics,
                    child: const Text(
                      '🔧 Run System Diagnostics',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF9F7AEA),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              // Sign Up Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Don\'t have an account? ',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF718096),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => const SignUpScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4ECDC4),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Offline Mode Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F8FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF4ECDC4).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      CupertinoIcons.info_circle,
                      color: const Color(0xFF4ECDC4),
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Offline Mode Available',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'You can use the app without signing in. Your data will be stored locally on this device.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF718096),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}