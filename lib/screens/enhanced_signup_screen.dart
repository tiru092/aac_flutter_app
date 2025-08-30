import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/auth_wrapper_service.dart';
import '../services/subscription_service.dart';
import '../models/subscription.dart';
import 'verify_email_screen.dart';
import 'home_screen.dart';

class EnhancedSignUpScreen extends StatefulWidget {
  const EnhancedSignUpScreen({super.key});

  @override
  State<EnhancedSignUpScreen> createState() => _EnhancedSignUpScreenState();
}

class _EnhancedSignUpScreenState extends State<EnhancedSignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authWrapper = AuthWrapperService();
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _startWithTrial = true; // Default to starting with trial
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    // Validate inputs
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields';
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters';
      });
      return;
    }

    if (!_agreeToTerms) {
      setState(() {
        _errorMessage = 'Please agree to the Terms of Service and Privacy Policy';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create Firebase account
      final result = await _authWrapper.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
      );

      if (mounted) {
        if (result.isSuccess) {
          // Start free trial if selected
          if (_startWithTrial) {
            final trialSubscription = await SubscriptionService.startFreeTrial();
            if (trialSubscription != null) {
              debugPrint('Free trial started successfully');
            }
          }

          // Navigate to email verification screen
          Navigator.pushReplacement(
            context,
            CupertinoPageRoute(builder: (context) => const VerifyEmailScreen()),
          );
        } else {
          setState(() {
            _errorMessage = result.message;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Registration failed. Please try again.';
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        previousPageTitle: 'Login',
        middle: Text('Create Account'),
        backgroundColor: CupertinoColors.systemBackground,
        border: Border(),
      ),
      backgroundColor: CupertinoColors.systemBackground,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              
              // App Logo/Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    CupertinoIcons.sparkles,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              const Text(
                'Join AAC Communicator',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              const Text(
                'Start your communication journey with a free trial',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF718096),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 30),
              
              // Free Trial Offer Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            CupertinoIcons.gift,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🎉 30-Day FREE Trial',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Try all premium features free',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CupertinoSwitch(
                          value: _startWithTrial,
                          onChanged: (value) {
                            setState(() {
                              _startWithTrial = value;
                            });
                          },
                          activeColor: Colors.white,
                          trackColor: Colors.white.withOpacity(0.3),
                        ),
                      ],
                    ),
                    
                    if (_startWithTrial) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '✨ Unlimited symbols & categories\n☁️ Cloud backup & sync\n🎙️ Advanced voice features\n👨‍👩‍👧‍👦 Family sharing\n🆘 Priority support',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
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
              
              // Name Field
              _buildInputField(
                label: 'Full Name',
                controller: _nameController,
                placeholder: 'Enter your full name',
                icon: CupertinoIcons.person,
              ),
              
              const SizedBox(height: 20),
              
              // Email Field
              _buildInputField(
                label: 'Email Address',
                controller: _emailController,
                placeholder: 'Enter your email',
                icon: CupertinoIcons.mail,
                keyboardType: TextInputType.emailAddress,
              ),
              
              const SizedBox(height: 20),
              
              // Password Field
              _buildInputField(
                label: 'Password',
                controller: _passwordController,
                placeholder: 'Create a strong password',
                icon: CupertinoIcons.lock,
                obscureText: true,
              ),
              
              const SizedBox(height: 20),
              
              // Confirm Password Field
              _buildInputField(
                label: 'Confirm Password',
                controller: _confirmPasswordController,
                placeholder: 'Confirm your password',
                icon: CupertinoIcons.lock_shield,
                obscureText: true,
              ),
              
              const SizedBox(height: 24),
              
              // Terms and Conditions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 24,
                    onPressed: () {
                      setState(() {
                        _agreeToTerms = !_agreeToTerms;
                      });
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _agreeToTerms ? const Color(0xFF4ECDC4) : Colors.transparent,
                        border: Border.all(
                          color: _agreeToTerms ? const Color(0xFF4ECDC4) : Colors.grey,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _agreeToTerms
                          ? const Icon(
                              CupertinoIcons.checkmark,
                              color: Colors.white,
                              size: 16,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'I agree to the Terms of Service and Privacy Policy. I understand that the free trial will automatically convert to a paid subscription unless cancelled.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF718096),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              
              // Sign Up Button
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  borderRadius: BorderRadius.circular(12),
                  onPressed: _isLoading ? null : _signUp,
                  child: _isLoading
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : Text(
                          _startWithTrial ? 'Start Free Trial' : 'Create Account',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Pricing Information
              if (_startWithTrial)
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
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.info_circle,
                            color: Color(0xFF4ECDC4),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Trial Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Free for 30 days, then ₹249/month\n• Cancel anytime during trial\n• No charges until trial ends\n• Full access to premium features',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF718096),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 30),
              
              // Alternative Options
              const Text(
                'Or continue with basic features',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF718096),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              CupertinoButton(
                onPressed: () {
                  setState(() {
                    _startWithTrial = false;
                  });
                },
                child: const Text(
                  'Create Free Account',
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

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A5568),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  icon,
                  color: const Color(0xFF718096),
                  size: 20,
                ),
              ),
              Expanded(
                child: CupertinoTextField(
                  controller: controller,
                  placeholder: placeholder,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(),
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}