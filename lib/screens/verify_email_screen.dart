import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
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
              const SizedBox(height: 40),
              
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
              
              // Skip Button
              CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 14),
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    CupertinoPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
                  );
                },
                child: const Text(
                  'Skip for Now',
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