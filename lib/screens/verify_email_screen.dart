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
      final isVerified = await _authService.isEmailVerified();
      
      if (isVerified) {
        if (mounted) {
          // Grant free trial after successful email verification
          try {
            final isEligible = await SubscriptionService.isEligibleForFreeTrial();
            if (isEligible) {
              final trialSubscription = await SubscriptionService.startFreeTrial();
              if (trialSubscription != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🎉 Welcome! Your 30-day free trial has started!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 4),
                  ),
                );
              }
            }
          } catch (e) {
            debugPrint('Failed to start free trial: $e');
            // Don't block user flow if trial setup fails
          }
          
          // Show success message before navigating
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email verified successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          
          Navigator.pushAndRemoveUntil(
            context,
            CupertinoPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Email not verified. Please check your inbox and click the verification link. '
              'If you haven\'t received the email, please check your spam folder.';
          _isVerifying = false;
          _startCountdown();
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = 'Firebase error: ${e.message}. Please try again.';
        _isVerifying = false;
        _startCountdown();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to check verification status. Please check your internet connection and try again.';
        _isVerifying = false;
        _startCountdown();
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent!'),
            backgroundColor: Colors.green,
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to sign out. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _skipVerification() async {
    // Show a confirmation dialog first
    final bool? shouldSkip = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Skip Email Verification?'),
        content: const Text(
          'You can continue without verifying your email, but some features may be limited. '
          'You can verify your email later in the profile settings.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Continue Anyway'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (shouldSkip == true && mounted) {
      // Navigate to home screen, bypassing verification
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Email verification skipped. You can verify later in profile settings.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      
      Navigator.pushAndRemoveUntil(
        context,
        CupertinoPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    }
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
              
              // Error Message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFED7D7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFE53E3E),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              // Check Verification Button
              CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 14),
                color: const Color(0xFF4ECDC4),
                borderRadius: BorderRadius.circular(12),
                onPressed: _isVerifying || _countdown > 0 ? null : _checkEmailVerification,
                child: _isVerifying
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : const Text(
                        'I\'ve Verified My Email',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
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