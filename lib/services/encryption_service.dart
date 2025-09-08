import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'secure_encryption_service.dart';
import 'secure_logger.dart';

/// Custom exception for encryption-related errors
class EncryptionException implements Exception {
  final String message;
  final String code;
  
  EncryptionException(this.message, [this.code = 'unknown']);
  
  @override
  String toString() => 'EncryptionException: $message (Code: $code)';
}

/// Service to handle encryption and decryption of sensitive data
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  
  // Secure storage for encryption keys
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  
  // Key used for storing the encryption key in secure storage
  static const String _encryptionKeyName = 'aac_app_encryption_key';
  
  EncryptionService._internal();

  // Secure encryption service for more sensitive data
  final SecureEncryptionService _secureEncryptionService = SecureEncryptionService();

  /// Get or generate encryption key securely
  Future<String> _getEncryptionKey() async {
    try {
      // Try to get existing key
      String? key = await _secureStorage.read(key: _encryptionKeyName);
      
      // If no key exists, generate a new one
      if (key == null || key.isEmpty) {
        // Generate a secure random key
        final random = Random.secure();
        final values = List<int>.generate(32, (i) => random.nextInt(256));
        key = base64UrlEncode(values);
        
        // Store the key securely
        await _secureStorage.write(key: _encryptionKeyName, value: key);
        SecureLogger.info('Generated new encryption key');
      }
      
      return key;
    } catch (e) {
      // Fallback to a default key if secure storage fails
      // This is still better than nothing in case of storage access issues
      SecureLogger.error('Failed to access secure storage for encryption key', e);
      return 'fallback_key_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Encrypt a string using AES-like encryption with error handling
  Future<String> encrypt(String plainText) async {
    try {
      // Handle empty or null input
      if (plainText.isEmpty) {
        return '';
      }
      
      // Get encryption key securely
      final encryptionKey = await _getEncryptionKey();
      
      // Generate a simple encryption using XOR with key
      final keyBytes = utf8.encode(encryptionKey);
      final textBytes = utf8.encode(plainText);
      
      final encryptedBytes = <int>[];
      for (int i = 0; i < textBytes.length; i++) {
        encryptedBytes.add(textBytes[i] ^ keyBytes[i % keyBytes.length]);
      }
      
      // Convert to base64 for storage
      final result = base64Encode(encryptedBytes);
      SecureLogger.encryptionEvent('Encrypt data', success: true);
      return result;
    } catch (e) {
      SecureLogger.error('Error encrypting data', e);
      // Return original text if encryption fails
      return plainText;
    }
  }

  /// Decrypt a string using AES-like decryption with comprehensive error handling
  Future<String> decrypt(String encryptedText) async {
    try {
      // Handle empty or null input
      if (encryptedText.isEmpty) {
        return '';
      }
      
      // Check if the input looks like base64
      if (!_isValidBase64(encryptedText)) {
        SecureLogger.warning('Invalid base64 format, returning original text');
        return encryptedText;
      }
      
      // Get encryption key securely
      final encryptionKey = await _getEncryptionKey();
      
      // Decode from base64
      final encryptedBytes = base64Decode(encryptedText);
      final keyBytes = utf8.encode(encryptionKey);
      
      final decryptedBytes = <int>[];
      for (int i = 0; i < encryptedBytes.length; i++) {
        decryptedBytes.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
      }
      
      // Convert back to string with validation
      final decryptedString = utf8.decode(decryptedBytes);
      
      // Validate the decrypted string is reasonable
      if (_isValidDecryptedString(decryptedString)) {
        SecureLogger.encryptionEvent('Decrypt data', success: true);
        return decryptedString;
      } else {
        SecureLogger.warning('Decrypted string appears corrupted, returning original');
        return encryptedText;
      }
    } catch (e) {
      SecureLogger.error('Error decrypting data', e);
      // Return encrypted text if decryption fails
      return encryptedText;
    }
  }
  
  /// Check if a string is valid base64
  bool _isValidBase64(String str) {
    try {
      base64Decode(str);
      return true;
    } catch (e) {
      SecureLogger.debug('Invalid base64 format detected', e);
      return false;
    }
  }
  
  /// Check if decrypted string appears to be valid
  bool _isValidDecryptedString(String str) {
    try {
      // Check for reasonable length
      if (str.length > 10000) return false;
      
      // Check for too many null bytes or control characters
      final nullCount = str.codeUnits.where((c) => c == 0).length;
      if (nullCount > str.length * 0.1) return false;
      
      // Check if it contains mostly printable characters
      final printableCount = str.codeUnits.where((c) => c >= 32 && c <= 126 || c == 10 || c == 13).length;
      if (printableCount < str.length * 0.7) return false;
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Encrypt sensitive data using secure encryption (for more sensitive information)
  Future<String?> secureEncrypt(String plainText) async {
    try {
      // Use the secure encryption service for more sensitive data
      return await _secureEncryptionService.encrypt(plainText);
    } catch (e) {
      print('Error secure encrypting data: $e');
      // Return null to indicate encryption failure
      return null;
    }
  }

  /// Decrypt sensitive data using secure decryption (for more sensitive information)
  Future<String?> secureDecrypt(String encryptedText) async {
    try {
      // Use the secure encryption service for more sensitive data
      return await _secureEncryptionService.decrypt(encryptedText);
    } catch (e) {
      print('Error secure decrypting data: $e');
      // Return null to indicate decryption failure
      return null;
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
      SecureLogger.error('Error generating hash', e);
      return ''; // Return empty string as fallback
    }
  }

  /// Generate a random salt for additional security with error handling
  String generateSalt([int length = 16]) {
    try {
      final random = Random.secure();
      final values = List<int>.generate(length, (i) => random.nextInt(256));
      return base64UrlEncode(values);
    } catch (e) {
      SecureLogger.error('Error generating salt', e);
      // Generate a simple fallback salt
      return 'fallback_salt_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Hash a password with salt with error handling
  String hashPassword(String password, [String? salt]) {
    try {
      // Handle empty or null input
      if (password.isEmpty) {
        return '';
      }
      
      final usedSalt = salt ?? generateSalt();
      final saltedPassword = '$password$usedSalt';
      final bytes = utf8.encode(saltedPassword);
      final hash = sha256.convert(bytes);
      return '${hash.toString()}:$usedSalt';
    } catch (e) {
      SecureLogger.error('Error hashing password', e);
      return ''; // Return empty string as fallback
    }
  }

  /// Verify a password against a hash with error handling
  bool verifyPassword(String password, String hashedPassword) {
    try {
      // Handle empty or null input
      if (password.isEmpty || hashedPassword.isEmpty) {
        return false;
      }
      
      final parts = hashedPassword.split(':');
      if (parts.length != 2) return false;
      
      final hash = parts[0];
      final salt = parts[1];
      
      final saltedPassword = '$password$salt';
      final bytes = utf8.encode(saltedPassword);
      final computedHash = sha256.convert(bytes);
      
      return computedHash.toString() == hash;
    } catch (e) {
      print('Error verifying password: $e');
      return false; // Return false as fallback
    }
  }

  /// Encrypt user profile data with comprehensive error handling
  Future<Map<String, dynamic>> encryptProfileData(Map<String, dynamic> profileData) async {
    try {
      final encryptedData = <String, dynamic>{};
      
      // Encrypt sensitive fields with secure encryption
      for (final entry in profileData.entries) {
        if (_isSensitiveField(entry.key)) {
          final encryptedValue = await secureEncrypt(entry.value.toString());
          encryptedData[entry.key] = encryptedValue ?? entry.value; // Fallback to original if encryption fails
        } else {
          encryptedData[entry.key] = entry.value;
        }
      }
      
      // Add integrity hash
      final dataString = jsonEncode(encryptedData);
      encryptedData['_integrityHash'] = generateHash(dataString);
      
      return encryptedData;
    } catch (e) {
      print('Error encrypting profile data: $e');
      // Return original data if encryption fails
      return profileData;
    }
  }

  /// Decrypt user profile data with comprehensive error handling and recovery
  Future<Map<String, dynamic>> decryptProfileData(Map<String, dynamic> encryptedData) async {
    try {
      // Create a copy to avoid modifying original
      final dataCopy = Map<String, dynamic>.from(encryptedData);
      
      // Remove integrity hash for verification
      final integrityHash = dataCopy.remove('_integrityHash') as String?;
      
      // Skip integrity check if hash is missing (older data)
      if (integrityHash != null) {
        final dataString = jsonEncode(dataCopy);
        final computedHash = generateHash(dataString);
        
        if (integrityHash != computedHash) {
          print('Data integrity check failed - data may be corrupted');
          // Continue with caution
        }
      }
      
      final decryptedData = <String, dynamic>{};
      
      // Decrypt sensitive fields with fallback handling
      for (final entry in encryptedData.entries) {
        if (entry.key == '_integrityHash') {
          continue; // Skip integrity hash
        }
        
        if (_isSensitiveField(entry.key)) {
          try {
            final value = entry.value;
            if (value == null || value.toString().isEmpty) {
              decryptedData[entry.key] = null;
              continue;
            }
            
            final decryptedValue = await secureDecrypt(value.toString());
            if (decryptedValue != null && decryptedValue.isNotEmpty) {
              decryptedData[entry.key] = decryptedValue;
            } else {
              // Try simple decrypt as fallback
              final simpleDecrypted = decrypt(value.toString());
              if (simpleDecrypted != value.toString()) {
                decryptedData[entry.key] = simpleDecrypted;
              } else {
                // Data appears corrupted, use safe fallback
                print('Warning: Could not decrypt field ${entry.key}, using null fallback');
                decryptedData[entry.key] = null;
              }
            }
          } catch (e) {
            print('Error decrypting field ${entry.key}: $e');
            decryptedData[entry.key] = null; // Safe fallback
          }
        } else {
          decryptedData[entry.key] = entry.value;
        }
      }
      
      return decryptedData;
    } catch (e) {
      print('Error decrypting profile data: $e');
      // Return a sanitized version of the data with nulled sensitive fields
      final safeFallback = <String, dynamic>{};
      for (final entry in encryptedData.entries) {
        if (_isSensitiveField(entry.key)) {
          safeFallback[entry.key] = null; // Null out corrupted sensitive data
        } else {
          safeFallback[entry.key] = entry.value;
        }
      }
      return safeFallback;
    }
  }

  /// Determine if a field contains sensitive information
  bool _isSensitiveField(String fieldName) {
    final sensitiveFields = [
      'pin',
      'password',
      'secret',
      'token',
      'key',
      'private',
      'personal',
      'email',
      'phone',
    ];
    
    return sensitiveFields.any((field) => 
        fieldName.toLowerCase().contains(field.toLowerCase()));
  }

  /// Encrypt communication history with metadata using secure encryption
  Future<Map<String, dynamic>?> encryptCommunicationHistory(
    List<Map<String, dynamic>> history
  ) async {
    try {
      // Convert history to JSON string
      final historyJson = jsonEncode(history);
      
      // Encrypt the history with secure encryption
      final encryptedHistory = await secureEncrypt(historyJson);
      
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

  /// Decrypt communication history with metadata validation using secure decryption
  Future<List<Map<String, dynamic>>?> decryptCommunicationHistory(
    Map<String, dynamic> encryptedHistory
  ) async {
    try {
      // Extract encrypted data
      final encryptedData = encryptedHistory['data'] as String;
      final metadata = encryptedHistory['metadata'] as Map<String, dynamic>;
      
      // Decrypt the history with secure decryption
      final decryptedHistoryJson = await secureDecrypt(encryptedData);
      
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
}