import 'package:flutter_test/flutter_test.dart';
import 'package:aac_flutter_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Generate mocks
@GenerateMocks([FirebaseAuth, FirebaseFirestore, User, UserCredential])
import 'auth_error_handling_test.mocks.dart';

void main() {
  group('AuthService Error Handling Tests', () {
    late AuthService authService;
    late MockFirebaseAuth mockAuth;
    late MockFirebaseFirestore mockFirestore;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockFirestore = MockFirebaseFirestore();
      authService = AuthService(auth: mockAuth, firestore: mockFirestore);
    });

    group('Sign Up Error Handling', () {
      test('handles email-already-in-use error', () async {
        final exception = FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'The email address is already in use by another account.',
        );
        
        when(mockAuth.createUserWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(exception);

        expect(
          authService.signUpWithEmail(
            email: 'test@example.com',
            password: 'password123',
            name: 'Test User',
          ),
          throwsA(
            predicate((e) => e is AuthException && e.code == 'email-already-in-use'),
          ),
        );
      });

      test('handles invalid-email error', () async {
        final exception = FirebaseAuthException(
          code: 'invalid-email',
          message: 'The email address is badly formatted.',
        );
        
        when(mockAuth.createUserWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(exception);

        expect(
          authService.signUpWithEmail(
            email: 'invalid-email',
            password: 'password123',
            name: 'Test User',
          ),
          throwsA(
            predicate((e) => e is AuthException && e.code == 'invalid-email'),
          ),
        );
      });

      test('handles weak-password error', () async {
        final exception = FirebaseAuthException(
          code: 'weak-password',
          message: 'The password must be 6 characters long or more.',
        );
        
        when(mockAuth.createUserWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(exception);

        expect(
          authService.signUpWithEmail(
            email: 'test@example.com',
            password: '123',
            name: 'Test User',
          ),
          throwsA(
            predicate((e) => e is AuthException && e.code == 'weak-password'),
          ),
        );
      });

      test('handles network-request-failed error', () async {
        final exception = FirebaseAuthException(
          code: 'network-request-failed',
          message: 'A network error has occurred.',
        );
        
        when(mockAuth.createUserWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(exception);

        expect(
          authService.signUpWithEmail(
            email: 'test@example.com',
            password: 'password123',
            name: 'Test User',
          ),
          throwsA(
            predicate((e) => e is AuthException && e.code == 'network-request-failed'),
          ),
        );
      });
    });

    group('Sign In Error Handling', () {
      test('handles user-not-found error', () async {
        final exception = FirebaseAuthException(
          code: 'user-not-found',
          message: 'There is no user record corresponding to this identifier.',
        );
        
        when(mockAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(exception);

        expect(
          authService.signInWithEmail(
            email: 'test@example.com',
            password: 'password123',
          ),
          throwsA(
            predicate((e) => e is AuthException && e.code == 'user-not-found'),
          ),
        );
      });

      test('handles wrong-password error', () async {
        final exception = FirebaseAuthException(
          code: 'wrong-password',
          message: 'The password is invalid or the user does not have a password.',
        );
        
        when(mockAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(exception);

        expect(
          authService.signInWithEmail(
            email: 'test@example.com',
            password: 'wrongpassword',
          ),
          throwsA(
            predicate((e) => e is AuthException && e.code == 'wrong-password'),
          ),
        );
      });

      test('handles invalid-credential error', () async {
        final exception = FirebaseAuthException(
          code: 'invalid-credential',
          message: 'The supplied auth credential is malformed or has expired.',
        );
        
        when(mockAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(exception);

        expect(
          authService.signInWithEmail(
            email: 'test@example.com',
            password: 'password123',
          ),
          throwsA(
            predicate((e) => e is AuthException && e.code == 'invalid-credential'),
          ),
        );
      });
    });

    group('Reset Password Error Handling', () {
      test('handles user-not-found error during password reset', () async {
        final exception = FirebaseAuthException(
          code: 'user-not-found',
          message: 'There is no user record corresponding to this identifier.',
        );
        
        when(mockAuth.sendPasswordResetEmail(email: anyNamed('email')))
            .thenThrow(exception);

        expect(
          authService.resetPassword('nonexistent@example.com'),
          throwsA(
            predicate((e) => e is AuthException && e.code == 'user-not-found'),
          ),
        );
      });

      test('handles invalid-email error during password reset', () async {
        final exception = FirebaseAuthException(
          code: 'invalid-email',
          message: 'The email address is badly formatted.',
        );
        
        when(mockAuth.sendPasswordResetEmail(email: anyNamed('email')))
            .thenThrow(exception);

        expect(
          authService.resetPassword('invalid-email'),
          throwsA(
            predicate((e) => e is AuthException && e.code == 'invalid-email'),
          ),
        );
      });
    });

    group('Verification Email Error Handling', () {
      test('handles no user error when sending verification email', () async {
        when(mockAuth.currentUser).thenReturn(null);

        expect(
          authService.sendVerificationEmail(),
          throwsA(
            predicate((e) => e is AuthException && e.code == 'no_user'),
          ),
        );
      });

      test('handles too-many-requests error when sending verification email', () async {
        final mockUser = MockUser();
        final exception = FirebaseAuthException(
          code: 'too-many-requests',
          message: 'We have blocked all requests from this device due to unusual activity.',
        );
        
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.sendEmailVerification()).thenThrow(exception);

        expect(
          authService.sendVerificationEmail(),
          throwsA(
            predicate((e) => e is AuthException && e.code == 'too-many-requests'),
          ),
        );
      });
    });
  });
}