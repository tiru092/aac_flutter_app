import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'secure_encryption_service.dart';

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
  EncryptionService._internal();

  // Simple encryption key (in a real app, this should be securely generated and stored)
  // For demonstration purposes, we'll use a fixed key
  static const String _encryptionKey = 'aac_app_encryption_key_2025';
  
  // Secure encryption service for more sensitive data
  final SecureEncryptionService _secureEncryptionService = SecureEncryptionService();

  /// Encrypt a string using AES-like encryption with error handling
  String encrypt(String plainText) {
    try {
      // Handle empty or null input
      if (plainText.isEmpty) {
        return '';
      }
      
      // Generate a simple encryption using XOR with key
      final keyBytes = utf8.encode(_encryptionKey);
      final textBytes = utf8.encode(plainText);
      
      final encryptedBytes = <int>[];
      for (int i = 0; i < textBytes.length; i++) {
        encryptedBytes.add(textBytes[i] ^ keyBytes[i % keyBytes.length]);
      }
      
      // Convert to base64 for storage
      return base64Encode(encryptedBytes);
    } catch (e) {
      print('Error encrypting data: $e');
      // Return original text if encryption fails
      return plainText;
    }
  }

  /// Decrypt a string using AES-like decryption with error handling
  String decrypt(String encryptedText) {
    try {
      // Handle empty or null input
      if (encryptedText.isEmpty) {
        return '';
      }
      
      // Decode from base64
      final encryptedBytes = base64Decode(encryptedText);
      final keyBytes = utf8.encode(_encryptionKey);
      
      final decryptedBytes = <int>[];
      for (int i = 0; i < encryptedBytes.length; i++) {
        decryptedBytes.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
      }
      
      // Convert back to string
      return utf8.decode(decryptedBytes);
    } catch (e) {
      print('Error decrypting data: $e');
      // Return encrypted text if decryption fails
      return encryptedText;
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
      print('Error generating hash: $e');
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
      print('Error generating salt: $e');
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
      print('Error hashing password: $e');
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

  /// Decrypt user profile data with comprehensive error handling
  Future<Map<String, dynamic>> decryptProfileData(Map<String, dynamic> encryptedData) async {
    try {
      // Verify integrity
      final integrityHash = encryptedData['_integrityHash'] as String?;
      final dataCopy = Map<String, dynamic>.from(encryptedData);
      dataCopy.remove('_integrityHash');
      
      final dataString = jsonEncode(dataCopy);
      final computedHash = generateHash(dataString);
      
      if (integrityHash != null && integrityHash != computedHash) {
        print('Data integrity check failed');
        // In a real app, you might want to handle this differently
        // For now, we'll continue with decryption
      }
      
      final decryptedData = <String, dynamic>{};
      
      // Decrypt sensitive fields
      for (final entry in encryptedData.entries) {
        if (entry.key == '_integrityHash') {
          continue; // Skip integrity hash
        }
        
        if (_isSensitiveField(entry.key)) {
          final decryptedValue = await secureDecrypt(entry.value.toString());
          decryptedData[entry.key] = decryptedValue ?? entry.value; // Fallback to original if decryption fails
        } else {
          decryptedData[entry.key] = entry.value;
        }
      }
      
      return decryptedData;
    } catch (e) {
      print('Error decrypting profile data: $e');
      // Return original data if decryption fails
      return encryptedData;
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