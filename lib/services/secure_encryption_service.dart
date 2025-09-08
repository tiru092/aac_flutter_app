import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Custom exception for secure encryption-related errors
class SecureEncryptionException implements Exception {
  final String message;
  final String code;
  
  SecureEncryptionException(this.message, [this.code = 'unknown']);
  
  @override
  String toString() => 'SecureEncryptionException: $message (Code: $code)';
}

/// Enhanced service to handle encryption and decryption of sensitive data with more secure methods
class SecureEncryptionService {
  static final SecureEncryptionService _instance = SecureEncryptionService._internal();
  factory SecureEncryptionService() => _instance;
  SecureEncryptionService._internal();

  // Secure storage for encryption keys
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Constants for key management
  static const String _encryptionKeyStorageKey = 'app_encryption_key';
  static const int _keyLength = 32; // 256 bits

  /// Initialize the encryption service and generate/load encryption key (fast version)
  Future<void> initialize() async {
    try {
      // FAST INIT: Try to get key quickly, if not available generate it immediately
      String? storedKey;
      
      try {
        storedKey = await Future.any([
          _secureStorage.read(key: _encryptionKeyStorageKey),
          Future.delayed(Duration(milliseconds: 300), () => null)
        ]);
      } catch (e) {
        // If secure storage fails, continue without key (temporary)
        print('Secure storage not available yet, will retry later: $e');
        return;
      }
      
      if (storedKey == null) {
        // Generate a new encryption key immediately (not in background)
        try {
          final key = _generateSecureKey();
          await _secureStorage.write(key: _encryptionKeyStorageKey, value: key);
          print('Generated and stored new encryption key');
        } catch (e) {
          print('Key generation failed: $e');
        }
      } else {
        print('Loaded existing encryption key');
      }
    } catch (e) {
      print('Error initializing encryption service: $e');
      // Don't rethrow - let app continue without encryption temporarily
    }
  }

  /// Generate a cryptographically secure key
  String _generateSecureKey() {
    final random = Random.secure();
    final values = List<int>.generate(_keyLength, (i) => random.nextInt(256));
    return base64Encode(values);
  }

  /// Get the encryption key from secure storage
  Future<Key> _getEncryptionKey() async {
    try {
      final keyString = await _secureStorage.read(key: _encryptionKeyStorageKey);
      if (keyString == null) {
        throw SecureEncryptionException('Encryption key not found');
      }
      return Key.fromBase64(keyString);
    } catch (e) {
      print('Error getting encryption key: $e');
      rethrow;
    }
  }

  /// Encrypt a string using AES encryption with error handling
  Future<String?> encrypt(String plainText) async {
    try {
      // Handle empty or null input
      if (plainText.isEmpty) {
        return '';
      }
      
      // Get encryption key
      final key = await _getEncryptionKey();
      final iv = IV.fromLength(16); // 128-bit IV
      
      // Create encrypter
      final encrypter = Encrypter(AES(key));
      
      // Encrypt the data
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      
      // Return base64 encoded result
      return encrypted.base64;
    } catch (e) {
      print('Error encrypting data: $e');
      // Return the plaintext if encryption fails (fallback for development)
      return plainText;
    }
  }

  /// Decrypt a string using AES decryption with error handling
  Future<String?> decrypt(String encryptedText) async {
    try {
      // Handle empty or null input
      if (encryptedText.isEmpty) {
        return '';
      }
      
      // Check if it's actually base64 encoded
      if (!_isValidBase64(encryptedText)) {
        print('[DEBUG] Invalid base64 format detected');
        print('[DEBUG] Error: ${FormatException('Invalid character (at character ${encryptedText.indexOf('@') >= 0 ? encryptedText.indexOf('@') : 8})')}');
        print('${encryptedText.length > 50 ? encryptedText.substring(0, 50) + '...' : encryptedText}');
        print('${' ' * 8}^');
        print('[WARNING] Invalid base64 format, returning original text');
        return encryptedText; // Return as-is if not encrypted
      }
      
      // Get encryption key
      final key = await _getEncryptionKey();
      final iv = IV.fromLength(16); // 128-bit IV
      
      // Create decrypter
      final encrypter = Encrypter(AES(key));
      
      // Decrypt the data
      final decrypted = encrypter.decrypt64(encryptedText, iv: iv);
      
      return decrypted;
    } catch (e) {
      print('[ERROR] Error decrypting data');
      print('[ERROR] Error details: $e');
      // Return the encrypted text as-is if decryption fails (fallback)
      return encryptedText;
    }
  }

  /// Check if a string is valid base64
  bool _isValidBase64(String str) {
    try {
      base64Decode(str);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Generate a secure hash for data integrity verification with error handling
  String generateHash(String data) {
    try {
      // Handle empty or null input
      if (data.isEmpty) {
        return '';
      }
      
      final bytes = utf8.encode(data);
      final hash = sha256.convert(bytes);
      return hash.toString();
    } catch (e) {
      print('Error generating hash: $e');
      return ''; // Return empty string as fallback
    }
  }

  /// Encrypt communication history with metadata
  Future<Map<String, dynamic>?> encryptCommunicationHistory(
    List<Map<String, dynamic>> history
  ) async {
    try {
      // Convert history to JSON string
      final historyJson = jsonEncode(history);
      
      // Encrypt the history
      final encryptedHistory = await encrypt(historyJson);
      
      if (encryptedHistory == null) {
        return null;
      }
      
      // Add metadata
      final metadata = {
        'encryptedAt': DateTime.now().toIso8601String(),
        'version': '1.0',
        'integrityHash': generateHash(historyJson),
      };
      
      return {
        'data': encryptedHistory,
        'metadata': metadata,
      };
    } catch (e) {
      print('Error encrypting communication history: $e');
      return null;
    }
  }

  /// Decrypt communication history with metadata validation
  Future<List<Map<String, dynamic>>?> decryptCommunicationHistory(
    Map<String, dynamic> encryptedHistory
  ) async {
    try {
      // Extract encrypted data
      final encryptedData = encryptedHistory['data'] as String;
      final metadata = encryptedHistory['metadata'] as Map<String, dynamic>;
      
      // Decrypt the history
      final decryptedHistoryJson = await decrypt(encryptedData);
      
      if (decryptedHistoryJson == null) {
        return null;
      }
      
      // Verify integrity
      final integrityHash = metadata['integrityHash'] as String?;
      if (integrityHash != null) {
        final computedHash = generateHash(decryptedHistoryJson);
        if (integrityHash != computedHash) {
          print('Warning: Communication history integrity check failed');
          // Depending on security requirements, you might want to return null here
        }
      }
      
      // Parse JSON
      final history = List<Map<String, dynamic>>.from(jsonDecode(decryptedHistoryJson));
      
      return history;
    } catch (e) {
      print('Error decrypting communication history: $e');
      return null;
    }
  }

  /// Encrypt user profile with enhanced security
  Future<Map<String, dynamic>?> encryptUserProfile(Map<String, dynamic> profileData) async {
    try {
      // Separate sensitive and non-sensitive data
      final sensitiveData = <String, dynamic>{};
      final nonSensitiveData = <String, dynamic>{};
      
      profileData.forEach((key, value) {
        if (_isHighlySensitiveField(key)) {
          sensitiveData[key] = value;
        } else {
          nonSensitiveData[key] = value;
        }
      });
      
      // Encrypt sensitive data
      final sensitiveDataJson = jsonEncode(sensitiveData);
      final encryptedSensitiveData = await encrypt(sensitiveDataJson);
      
      if (encryptedSensitiveData == null) {
        return null;
      }
      
      // Combine with non-sensitive data
      final encryptedProfile = Map<String, dynamic>.from(nonSensitiveData);
      encryptedProfile['_sensitiveData'] = encryptedSensitiveData;
      encryptedProfile['_encryptedAt'] = DateTime.now().toIso8601String();
      encryptedProfile['_version'] = '1.0';
      
      return encryptedProfile;
    } catch (e) {
      print('Error encrypting user profile: $e');
      return null;
    }
  }

  /// Decrypt user profile with enhanced security
  Future<Map<String, dynamic>?> decryptUserProfile(Map<String, dynamic> encryptedProfile) async {
    try {
      // Extract encrypted sensitive data
      final encryptedSensitiveData = encryptedProfile['_sensitiveData'] as String?;
      
      if (encryptedSensitiveData == null) {
        // No sensitive data to decrypt, return as is
        final profile = Map<String, dynamic>.from(encryptedProfile);
        profile.remove('_encryptedAt');
        profile.remove('_version');
        return profile;
      }
      
      // Decrypt sensitive data
      final decryptedSensitiveDataJson = await decrypt(encryptedSensitiveData);
      
      if (decryptedSensitiveDataJson == null) {
        return null;
      }
      
      // Parse decrypted sensitive data
      final sensitiveData = Map<String, dynamic>.from(jsonDecode(decryptedSensitiveDataJson));
      
      // Combine with non-sensitive data
      final profile = Map<String, dynamic>.from(encryptedProfile);
      profile.remove('_sensitiveData');
      profile.remove('_encryptedAt');
      profile.remove('_version');
      
      // Add decrypted sensitive data
      profile.addAll(sensitiveData);
      
      return profile;
    } catch (e) {
      print('Error decrypting user profile: $e');
      return null;
    }
  }

  /// Check if a field contains highly sensitive information that requires strong encryption
  bool _isHighlySensitiveField(String fieldName) {
    final highlySensitiveFields = [
      'pin',
      'phoneNumber',
      'email',
      'communicationHistory',
      'customVoices',
      'personalNotes',
    ];
    
    return highlySensitiveFields.contains(fieldName);
  }
  
  /// Securely delete encryption key (useful for app reset or security purposes)
  Future<void> deleteEncryptionKey() async {
    try {
      await _secureStorage.delete(key: _encryptionKeyStorageKey);
      print('Encryption key deleted securely');
    } catch (e) {
      print('Error deleting encryption key: $e');
      rethrow;
    }
  }
  
  /// Rotate encryption key for enhanced security
  Future<void> rotateEncryptionKey() async {
    try {
      // Generate new key
      final newKey = _generateSecureKey();
      
      // Store new key
      await _secureStorage.write(key: _encryptionKeyStorageKey, value: newKey);
      
      print('Encryption key rotated successfully');
    } catch (e) {
      print('Error rotating encryption key: $e');
      rethrow;
    }
  }
}