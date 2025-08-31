import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Custom exception for authentication-related errors
class AuthException implements Exception {
  final String message;
  final String code;
  
  AuthException(this.message, [this.code = 'unknown']);
  
  @override
  String toString() => 'AuthException: $message (Code: $code)';
}

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // Constructor with optional dependency injection for testing
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // Static helper methods for input validation (can be tested independently)
  static void validateSignUpInputs({
    required String email,
    required String password,
    required String name,
  }) {
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      throw AuthException('Email, password, and name are required', 'invalid_input');
    }
    
    if (password.length < 6) {
      throw AuthException('Password must be at least 6 characters long', 'weak_password');
    }
  }

  static void validateSignInInputs({
    required String email,
    required String password,
  }) {
    if (email.isEmpty || password.isEmpty) {
      throw AuthException('Email and password are required', 'invalid_input');
    }
  }

  static void validateResetPasswordInput(String email) {
    if (email.isEmpty) {
      throw AuthException('Email is required', 'invalid_input');
    }
  }

  static void validateLinkProfileInput(String profileId) {
    if (profileId.isEmpty) {
      throw AuthException('Profile ID is required', 'invalid_input');
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth status stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Validate inputs using static helper method
      AuthService.validateSignUpInputs(
        email: email,
        password: password,
        name: name,
      );
      
      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send verification email immediately after signup
      try {
        await userCredential.user?.sendEmailVerification();
        print('Verification email sent during signup to: $email');
      } catch (emailError) {
        print('Warning: Failed to send verification email during signup: $emailError');
        // Don't throw error here - user can request resend later
      }

      // Add user to Firestore
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'emailVerified': false,
        'signupCompleted': false, // Track if signup process is complete
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      switch (e.code) {
        case 'email-already-in-use':
          throw AuthException('Email is already in use. Please sign in instead or use a different email.', e.code);
        case 'invalid-email':
          throw AuthException('Invalid email address. Please check the format and try again.', e.code);
        case 'operation-not-allowed':
          throw AuthException('Email/password accounts are not enabled. Please contact support.', e.code);
        case 'weak-password':
          throw AuthException('Password is too weak. Please use a stronger password with at least 6 characters.', e.code);
        case 'network-request-failed':
          throw AuthException('Network error. Please check your internet connection and try again.', e.code);
        case 'too-many-requests':
          throw AuthException('Too many requests. Please try again later.', e.code);
        default:
          throw AuthException(e.message ?? 'Unknown error during sign up. Please try again.', e.code);
      }
    } on FirebaseException catch (e) {
      // Handle general Firebase errors
      throw AuthException('Firebase error: ${e.message ?? 'Unknown error'}. Please try again.', e.code);
    } catch (e) {
      // Handle any other errors
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException('Failed to sign up due to an unexpected error. Please try again later.', 'signup_failed');
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Validate inputs using static helper method
      AuthService.validateSignInInputs(
        email: email,
        password: password,
      );
      
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      switch (e.code) {
        case 'invalid-email':
          throw AuthException('Invalid email address. Please check the format and try again.', e.code);
        case 'user-disabled':
          throw AuthException('User account has been disabled. Please contact support.', e.code);
        case 'user-not-found':
          throw AuthException('No user found with this email. Please check your email or sign up for a new account.', e.code);
        case 'wrong-password':
          throw AuthException('Incorrect password. Please try again or reset your password.', e.code);
        case 'network-request-failed':
          throw AuthException('Network error. Please check your internet connection and try again.', e.code);
        case 'too-many-requests':
          throw AuthException('Too many failed attempts. Please try again later or reset your password.', e.code);
        case 'invalid-credential':
          throw AuthException('Invalid credentials. Please check your email and password.', e.code);
        default:
          throw AuthException(e.message ?? 'Unknown error during sign in. Please try again.', e.code);
      }
    } on FirebaseException catch (e) {
      // Handle general Firebase errors
      throw AuthException('Firebase error: ${e.message ?? 'Unknown error'}. Please try again.', e.code);
    } catch (e) {
      // Handle any other errors
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException('Failed to sign in due to an unexpected error. Please try again later.', 'signin_failed');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AuthException('Failed to sign out: ${e.toString()}', 'signout_failed');
    }
  }

  // Send verification email with improved settings
  Future<void> sendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthException('No user is currently signed in. Please sign in first.', 'no_user');
      }
      
      // Reload user first to get latest state
      await user.reload();
      
      // Check if already verified
      if (user.emailVerified) {
        throw AuthException('Email is already verified.', 'already_verified');
      }
      
      // Send verification email with basic settings
      await user.sendEmailVerification();
      
      // Log successful send for debugging
      print('Verification email sent to: ${user.email}');
      
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'too-many-requests':
          throw AuthException('Too many requests. Please wait a few minutes before requesting another verification email.', e.code);
        case 'network-request-failed':
          throw AuthException('Network error. Please check your internet connection and try again.', e.code);
        case 'invalid-recipient-email':
          throw AuthException('Invalid recipient email address. Please contact support.', e.code);
        case 'user-token-expired':
          throw AuthException('Your session has expired. Please sign in again.', e.code);
        default:
          throw AuthException(e.message ?? 'Failed to send verification email. Please try again.', e.code);
      }
    } on FirebaseException catch (e) {
      // Handle general Firebase errors
      throw AuthException('Firebase error: ${e.message ?? 'Unknown error'}. Please try again.', e.code);
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException('Failed to send verification email due to an unexpected error. Please try again later.', 'verification_failed');
    }
  }

  // Check if email is verified
  Future<bool> isEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('AuthService: No current user for email verification check');
        throw AuthException('No user is currently signed in. Please sign in again.', 'no_user');
      }
      
      // Always reload to get the latest verification status
      await user.reload();
      final updatedUser = _auth.currentUser;
      
      if (updatedUser == null) {
        debugPrint('AuthService: User became null after reload');
        throw AuthException('User session expired. Please sign in again.', 'session_expired');
      }
      
      final isVerified = updatedUser.emailVerified;
      debugPrint('AuthService: Email verification status for ${updatedUser.email}: $isVerified');
      
      return isVerified;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: Firebase error checking email verification: $e');
      switch (e.code) {
        case 'network-request-failed':
          throw AuthException('Network error. Please check your internet connection and try again.', e.code);
        case 'too-many-requests':
          throw AuthException('Too many requests. Please wait a moment and try again.', e.code);
        case 'user-token-expired':
          throw AuthException('Your session has expired. Please sign in again.', e.code);
        default:
          throw AuthException('Failed to check verification status: ${e.message}', e.code);
      }
    } catch (e) {
      debugPrint('AuthService: Unexpected error checking email verification: $e');
      throw AuthException('An unexpected error occurred. Please try again.', 'unknown_error');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      // Validate input using static helper method
      AuthService.validateResetPasswordInput(email);
      
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          throw AuthException('Invalid email address. Please check the format and try again.', e.code);
        case 'user-not-found':
          throw AuthException('No user found with this email. Please check your email or sign up for a new account.', e.code);
        case 'too-many-requests':
          throw AuthException('Too many requests. Please try again later.', e.code);
        case 'network-request-failed':
          throw AuthException('Network error. Please check your internet connection and try again.', e.code);
        default:
          throw AuthException(e.message ?? 'Failed to send password reset email. Please try again.', e.code);
      }
    } on FirebaseException catch (e) {
      // Handle general Firebase errors
      throw AuthException('Firebase error: ${e.message ?? 'Unknown error'}. Please try again.', e.code);
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException('Failed to reset password due to an unexpected error. Please try again later.', 'reset_password_failed');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthException('No user is currently signed in', 'no_user');
      }
      
      // Update auth profile
      if (name != null || photoURL != null) {
        await user.updateDisplayName(name);
        await user.updatePhotoURL(photoURL);
      }

      // Update Firestore user document
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (photoURL != null) data['photoURL'] = photoURL;
      
      if (data.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .update(data);
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'too-many-requests':
          throw AuthException('Too many requests. Please try again later', e.code);
        default:
          throw AuthException(e.message ?? 'Failed to update user profile', e.code);
      }
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException('Failed to update user profile: ${e.toString()}', 'update_profile_failed');
    }
  }

  // Link user with UserProfile
  Future<void> linkUserWithProfile(String profileId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthException('No user is currently signed in', 'no_user');
      }
      
      // Validate input using static helper method
      AuthService.validateLinkProfileInput(profileId);
      
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({
        'linkedProfiles': FieldValue.arrayUnion([profileId]),
      });
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException('Failed to link user with profile: ${e.toString()}', 'link_profile_failed');
    }
  }
  
  // Get user's profiles
  Future<List<String>> getUserProfiles() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return [];
      }
      
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
          
      final data = doc.data();
      if (data != null && data.containsKey('linkedProfiles')) {
        return List<String>.from(data['linkedProfiles']);
      }
      
      return [];
    } catch (e) {
      throw AuthException('Failed to get user profiles: ${e.toString()}', 'get_profiles_failed');
    }
  }
}