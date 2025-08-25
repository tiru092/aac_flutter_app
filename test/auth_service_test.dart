import 'package:flutter_test/flutter_test.dart';
import 'package:aac_flutter_app/services/auth_service.dart';

void main() {
  group('AuthException Tests', () {
    test('should create AuthException with message and code', () {
      final exception = AuthException('Test message', 'test_code');
      expect(exception.message, 'Test message');
      expect(exception.code, 'test_code');
    });

    test('should create AuthException with default code', () {
      final exception = AuthException('Test message');
      expect(exception.message, 'Test message');
      expect(exception.code, 'unknown');
    });

    test('should convert AuthException to string', () {
      final exception = AuthException('Test message', 'test_code');
      expect(exception.toString(), 'AuthException: Test message (Code: test_code)');
    });
  });

  group('Input Validation Tests', () {
    group('validateSignUpInputs', () {
      test('should throw exception when email is empty', () {
        expect(
          () => AuthService.validateSignUpInputs(
            email: '', 
            password: 'password123', 
            name: 'Test User'
          ),
          throwsA(predicate((e) => e is AuthException && e.code == 'invalid_input')),
        );
      });

      test('should throw exception when password is empty', () {
        expect(
          () => AuthService.validateSignUpInputs(
            email: 'test@example.com', 
            password: '', 
            name: 'Test User'
          ),
          throwsA(predicate((e) => e is AuthException && e.code == 'invalid_input')),
        );
      });

      test('should throw exception when name is empty', () {
        expect(
          () => AuthService.validateSignUpInputs(
            email: 'test@example.com', 
            password: 'password123', 
            name: ''
          ),
          throwsA(predicate((e) => e is AuthException && e.code == 'invalid_input')),
        );
      });

      test('should throw exception when password is too short', () {
        expect(
          () => AuthService.validateSignUpInputs(
            email: 'test@example.com', 
            password: '123', 
            name: 'Test User'
          ),
          throwsA(predicate((e) => e is AuthException && e.code == 'weak_password')),
        );
      });

      test('should not throw exception when all inputs are valid', () {
        expect(
          () => AuthService.validateSignUpInputs(
            email: 'test@example.com', 
            password: 'password123', 
            name: 'Test User'
          ),
          returnsNormally,
        );
      });
    });

    group('validateSignInInputs', () {
      test('should throw exception when email is empty', () {
        expect(
          () => AuthService.validateSignInInputs(
            email: '', 
            password: 'password123'
          ),
          throwsA(predicate((e) => e is AuthException && e.code == 'invalid_input')),
        );
      });

      test('should throw exception when password is empty', () {
        expect(
          () => AuthService.validateSignInInputs(
            email: 'test@example.com', 
            password: ''
          ),
          throwsA(predicate((e) => e is AuthException && e.code == 'invalid_input')),
        );
      });

      test('should not throw exception when all inputs are valid', () {
        expect(
          () => AuthService.validateSignInInputs(
            email: 'test@example.com', 
            password: 'password123'
          ),
          returnsNormally,
        );
      });
    });

    group('validateResetPasswordInput', () {
      test('should throw exception when email is empty', () {
        expect(
          () => AuthService.validateResetPasswordInput(''),
          throwsA(predicate((e) => e is AuthException && e.code == 'invalid_input')),
        );
      });

      test('should not throw exception when email is valid', () {
        expect(
          () => AuthService.validateResetPasswordInput('test@example.com'),
          returnsNormally,
        );
      });
    });

    group('validateLinkProfileInput', () {
      test('should throw exception when profile ID is empty', () {
        expect(
          () => AuthService.validateLinkProfileInput(''),
          throwsA(predicate((e) => e is AuthException && e.code == 'invalid_input')),
        );
      });

      test('should not throw exception when profile ID is valid', () {
        expect(
          () => AuthService.validateLinkProfileInput('profile123'),
          returnsNormally,
        );
      });
    });
  });
}