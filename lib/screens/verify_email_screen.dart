import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';
import '../screens/login_screen.dart';
import 'home_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _authService = AuthService();
  bool _isVerifying = false;
  String? _errorMessage;
  int _countdown = 30;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    
    // Debug: Check user status on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser;
      debugPrint('VerifyEmailScreen: Init - User: ${user?.email}, Verified: ${user?.emailVerified}');
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdown = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdown--;
      });
      if (_countdown <= 0) {
        timer.cancel();
      }
    });
  }

  Future<void> _checkEmailVerification() async {
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      // First check if user is still signed in
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _errorMessage = 'Your session has expired. Please sign in again to verify your email.';
          _isVerifying = false;
        });
        return;
      }

      // Reload user to get latest verification status
      await currentUser.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;
      
      if (refreshedUser == null) {
        setState(() {
          _errorMessage = 'Your session has expired. Please sign in again to verify your email.';
          _isVerifying = false;
        });
        return;
      }

      final isVerified = refreshedUser.emailVerified;
      debugPrint('VerifyEmailScreen: Email verification status: $isVerified');
      
      if (isVerified) {
        if (mounted) {
          // Grant free trial after successful email verification
          try {
            final isEligible = await SubscriptionService.isEligibleForFreeTrial();
            if (isEligible) {
              final trialSubscription = await SubscriptionService.startFreeTrial();
              if (trialSubscription != null) {
                showCupertinoDialog(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    title: const Text('🎉 Welcome!'),
                    content: const Text('Your 30-day free trial has started!'),
                    actions: [
                      CupertinoDialogAction(
                        child: const Text('Great!'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                );
              }
            }
          } catch (e) {
            debugPrint('Failed to start free trial: $e');
            // Don't block user flow if trial setup fails
          }
          
          // Show success message before navigating
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('✅ Email Verified'),
              content: const Text('Your email has been verified successfully!'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Continue'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Navigate to home screen
                    Navigator.pushAndRemoveUntil(
                      context,
                      CupertinoPageRoute(builder: (context) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Email not verified yet. Please check your inbox and click the verification link. '
              'If you haven\'t received the email, please check your spam folder and try resending.';
          _isVerifying = false;
        });
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('VerifyEmailScreen: Firebase error: $e');
      setState(() {
        switch (e.code) {
          case 'user-not-found':
            _errorMessage = 'Your account was not found. Please sign up again or contact support.';
            break;
          case 'network-request-failed':
            _errorMessage = 'Network error. Please check your internet connection and try again.';
            break;
          case 'too-many-requests':
            _errorMessage = 'Too many attempts. Please wait a moment and try again.';
            break;
          case 'user-token-expired':
            _errorMessage = 'Your session has expired. Please sign in again.';
            break;
          default:
            _errorMessage = 'Firebase error: ${e.message ?? "Unknown error"}. Please try again.';
        }
        _isVerifying = false;
      });
    } catch (e) {
      debugPrint('VerifyEmailScreen: Unexpected error: $e');
      setState(() {
        _errorMessage = 'Verification check failed. Please ensure you have a stable internet connection and try again.';
        _isVerifying = false;
      });
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_countdown > 0) return;
    
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      await _authService.sendVerificationEmail();
      setState(() {
        _errorMessage = 'Verification email sent successfully! Please check your inbox (and spam folder).';
        _isVerifying = false;
        _startCountdown();
      });
      
      // Show success message
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('📧 Email Sent'),
            content: const Text('Verification email sent! Please check your inbox.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = 'Firebase error: ${e.message}. Please try again.';
        _isVerifying = false;
        _startCountdown();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send verification email. Please check your internet connection and try again.';
        _isVerifying = false;
        _startCountdown();
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          CupertinoPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Sign Out Failed'),
            content: const Text('Failed to sign out. Please try again.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _skipVerification() async {
    // Show a dialog explaining that email verification is required
    await showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Email Verification Required'),
        content: const Text(
          'You must verify your email before continuing. Please check your inbox for the verification link.'
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _signOut,
          child: const Icon(
            CupertinoIcons.back,
            color: Color(0xFF4ECDC4),
          ),
        ),
        middle: const Text(
          'Email Verification',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _signOut,
          child: const Text(
            'Sign Out',
            style: TextStyle(
              color: Color(0xFF4ECDC4),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // Email Icon
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ECDC4),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    CupertinoIcons.mail_solid,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Title
              const Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Description
              const Text(
                'We have sent a verification email to your inbox. Please click the link in the email to verify your account.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF718096),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Additional Help Text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF7DD3FC)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      CupertinoIcons.info_circle,
                      color: Color(0xFF0EA5E9),
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Didn\'t receive the email?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0EA5E9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '• Check your spam/junk folder\n• Make sure the email address is correct\n• Wait a few minutes for delivery\n• Try resending the email',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF374151),
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Error Message with better formatting
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _errorMessage!.contains('session') || _errorMessage!.contains('sign in again')
                        ? const Color(0xFFFEF3C7) // Yellow for session issues
                        : const Color(0xFFFED7D7), // Red for other errors
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _errorMessage!.contains('session') || _errorMessage!.contains('sign in again')
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFE53E3E),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _errorMessage!.contains('session') || _errorMessage!.contains('sign in again')
                            ? CupertinoIcons.exclamationmark_triangle
                            : CupertinoIcons.xmark_circle,
                        color: _errorMessage!.contains('session') || _errorMessage!.contains('sign in again')
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFFE53E3E),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: _errorMessage!.contains('session') || _errorMessage!.contains('sign in again')
                                ? const Color(0xFF92400E)
                                : const Color(0xFFE53E3E),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // If session expired, show sign in button
                if (_errorMessage!.contains('session') || _errorMessage!.contains('sign in again')) ...[
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    color: const Color(0xFF6C63FF),
                    borderRadius: BorderRadius.circular(12),
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      CupertinoPageRoute(builder: (context) => const LoginScreen()),
                    ),
                    child: const Text(
                      'Go to Sign In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ],
              
              // Check Verification Button
              CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 14),
                color: const Color(0xFF4ECDC4),
                borderRadius: BorderRadius.circular(12),
                onPressed: _isVerifying ? null : _checkEmailVerification,
                child: _isVerifying
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : const Text(
                        'I\'ve Verified My Email',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
              
              const SizedBox(height: 20),
              
              // Resend Email Button
              CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 14),
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                onPressed: _countdown > 0 ? null : _resendVerificationEmail,
                child: Text(
                  _countdown > 0 
                      ? 'Resend Email in $_countdown seconds' 
                      : 'Resend Verification Email',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6C63FF),
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Skip for now button (helpful for users stuck in verification loop)
              CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 14),
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                onPressed: _skipVerification,
                child: const Text(
                  'Skip for Now (Continue Anyway)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4ECDC4),
                  ),
                ),
              ),
              
              const SizedBox(height: 10),
              
              // Use Different Email Button
              CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 14),
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                onPressed: _signOut,
                child: const Text(
                  'Use Different Email Address',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF718096),
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