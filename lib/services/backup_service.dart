import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import '../models/symbol.dart';
import '../models/user_profile.dart';
import '../services/symbol_database_service.dart';
import '../services/profile_service.dart';
import '../services/phrase_history_service.dart';
import '../services/language_service.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  Future<BackupResult> createFullBackup() async {
    try {
      // Get app directory for temporary backup files
      final appDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${appDir.path}/backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupName = 'aac_backup_$timestamp';
      final tempDir = Directory('${backupDir.path}/$backupName');
      await tempDir.create(recursive: true);

      // Create backup data
      final backupData = await _collectAllData();
      
      // Save individual JSON files
      final files = <String>[];
      
      // Save symbols and categories
      final symbolsFile = File('${tempDir.path}/symbols.json');
      await symbolsFile.writeAsString(jsonEncode(backupData.symbols));
      files.add('symbols.json');
      
      final categoriesFile = File('${tempDir.path}/categories.json');
      await categoriesFile.writeAsString(jsonEncode(backupData.categories));
      files.add('categories.json');
      
      // Save profiles
      final profilesFile = File('${tempDir.path}/profiles.json');
      await profilesFile.writeAsString(jsonEncode(backupData.profiles));
      files.add('profiles.json');
      
      // Save phrase history
      final historyFile = File('${tempDir.path}/phrase_history.json');
      await historyFile.writeAsString(jsonEncode(backupData.phraseHistory));
      files.add('phrase_history.json');
      
      // Save language settings
      final languageFile = File('${tempDir.path}/language_settings.json');
      await languageFile.writeAsString(jsonEncode(backupData.languageSettings));
      files.add('language_settings.json');
      
      // Save quick phrases
      final quickPhrasesFile = File('${tempDir.path}/quick_phrases.json');
      await quickPhrasesFile.writeAsString(jsonEncode(backupData.quickPhrases));
      files.add('quick_phrases.json');
      
      // Save metadata
      final metadataFile = File('${tempDir.path}/backup_metadata.json');
      await metadataFile.writeAsString(jsonEncode({
        'version': '1.0.0',
        'created_at': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
        'backup_type': 'full',
        'files': files,
        'symbol_count': backupData.symbols.length,
        'profile_count': backupData.profiles.length,
      }));
      files.add('backup_metadata.json');
      
      // Copy custom symbol images if any exist
      await _copyCustomImages(tempDir, backupData.symbols);
      
      // Create ZIP archive
      final zipFile = File('${backupDir.path}/$backupName.zip');
      await _createZipArchive(tempDir, zipFile);
      
      // Clean up temporary directory
      await tempDir.delete(recursive: true);
      
      return BackupResult(
        success: true,
        filePath: zipFile.path,
        fileName: '$backupName.zip',
        size: await zipFile.length(),
        message: 'Backup created successfully',
      );
      
    } catch (e) {
      return BackupResult(
        success: false,
        message: 'Failed to create backup: $e',
      );
    }
  }

  Future<BackupData> _collectAllData() async {
    final symbolService = SymbolDatabaseService();
    final profileService = ProfileService();
    final historyService = PhraseHistoryService();
    final languageService = LanguageService();
    
    // Collect all data from services
    return BackupData(
      symbols: symbolService.symbols.map((s) => s.toJson()).toList(),
      categories: symbolService.categories.map((c) => c.toJson()).toList(),
      profiles: profileService.profiles.map((p) => p.toJson()).toList(),
      phraseHistory: {
        'history': historyService.history.map((h) => h.toJson()).toList(),
        'favorites': historyService.favorites.map((f) => f.toJson()).toList(),
      },
      languageSettings: {
        'current_language': languageService.currentLanguage,
        'supported_languages': languageService.supportedLanguages
            .map((key, value) => MapEntry(key, value.toJson())),
        'tts_settings': languageService.ttsVoiceSettings?.toJson(),
      },
      quickPhrases: await _getQuickPhrases(),
    );
  }

  Future<List<Map<String, dynamic>>> _getQuickPhrases() async {
    // This would load quick phrases from SharedPreferences
    // Implementation depends on how quick phrases are stored
    return [];
  }

  Future<void> _copyCustomImages(Directory tempDir, List<Map<String, dynamic>> symbols) async {
    final imagesDir = Directory('${tempDir.path}/custom_images');
    
    for (final symbolData in symbols) {
      final imagePath = symbolData['imagePath'] as String?;
      if (imagePath != null && !imagePath.startsWith('assets/')) {
        // This is a custom image file
        final imageFile = File(imagePath);
        if (await imageFile.exists()) {
          if (!await imagesDir.exists()) {
            await imagesDir.create(recursive: true);
          }
          
          final fileName = imagePath.split('/').last;
          final destinationFile = File('${imagesDir.path}/$fileName');
          await imageFile.copy(destinationFile.path);
        }
      }
    }
  }

  Future<void> _createZipArchive(Directory sourceDir, File zipFile) async {
    final archive = Archive();
    
    await for (final entity in sourceDir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = entity.path.substring(sourceDir.path.length + 1);
        final fileBytes = await entity.readAsBytes();
        final archiveFile = ArchiveFile(relativePath, fileBytes.length, fileBytes);
        archive.addFile(archiveFile);
      }
    }
    
    final zipData = ZipEncoder().encode(archive);
    await zipFile.writeAsBytes(zipData!);
  }

  Future<BackupResult> shareBackup(String backupFilePath) async {
    try {
      final file = File(backupFilePath);
      if (!await file.exists()) {
        return BackupResult(
          success: false,
          message: 'Backup file not found',
        );
      }

      await Share.shareXFiles(
        [XFile(backupFilePath)],
        text: 'AAC App Backup',
        subject: 'AAC Communication App Data Backup',
      );

      return BackupResult(
        success: true,
        message: 'Backup shared successfully',
      );
    } catch (e) {
      return BackupResult(
        success: false,
        message: 'Failed to share backup: $e',
      );
    }
  }

  Future<List<BackupFile>> getAvailableBackups() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${appDir.path}/backups');
      
      if (!await backupDir.exists()) {
        return [];
      }

      final backupFiles = <BackupFile>[];
      
      await for (final entity in backupDir.list()) {
        if (entity is File && entity.path.endsWith('.zip')) {
          final stat = await entity.stat();
          final fileName = entity.path.split('/').last;
          
          // Try to extract metadata from backup
          BackupMetadata? metadata;
          try {
            metadata = await _extractBackupMetadata(entity);
          } catch (e) {
            // If metadata extraction fails, create basic info
          }
          
          backupFiles.add(BackupFile(
            fileName: fileName,
            filePath: entity.path,
            size: stat.size,
            createdAt: metadata?.createdAt ?? stat.modified,
            metadata: metadata,
          ));
        }
      }
      
      // Sort by creation date, newest first
      backupFiles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return backupFiles;
    } catch (e) {
      return [];
    }
  }

  Future<BackupMetadata?> _extractBackupMetadata(File zipFile) async {
    try {
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      // Find metadata file
      final metadataFile = archive.files.firstWhere(
        (file) => file.name == 'backup_metadata.json',
      );
      
      final metadataContent = String.fromCharCodes(metadataFile.content);
      final metadataJson = jsonDecode(metadataContent);
      
      return BackupMetadata.fromJson(metadataJson);
    } catch (e) {
      return null;
    }
  }

  Future<RestoreResult> restoreFromBackup(String backupFilePath, {bool replaceAll = false}) async {
    try {
      final backupFile = File(backupFilePath);
      if (!await backupFile.exists()) {
        return RestoreResult(
          success: false,
          message: 'Backup file not found',
        );
      }

      // Extract ZIP archive
      final bytes = await backupFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      // Create temporary directory for extraction
      final appDir = await getApplicationDocumentsDirectory();
      final tempDir = Directory('${appDir.path}/restore_temp_${DateTime.now().millisecondsSinceEpoch}');
      await tempDir.create(recursive: true);
      
      // Extract files
      for (final file in archive.files) {
        if (file.isFile) {
          final extractedFile = File('${tempDir.path}/${file.name}');
          await extractedFile.create(recursive: true);
          await extractedFile.writeAsBytes(file.content);
        }
      }
      
      // Validate backup
      final validationResult = await _validateBackup(tempDir);
      if (!validationResult.isValid) {
        await tempDir.delete(recursive: true);
        return RestoreResult(
          success: false,
          message: 'Invalid backup file: ${validationResult.error}',
        );
      }
      
      // Restore data
      final restoreStats = await _performRestore(tempDir, replaceAll);
      
      // Clean up
      await tempDir.delete(recursive: true);
      
      return RestoreResult(
        success: true,
        message: 'Data restored successfully',
        restoredItems: restoreStats,
      );
      
    } catch (e) {
      return RestoreResult(
        success: false,
        message: 'Failed to restore backup: $e',
      );
    }
  }

  Future<ValidationResult> _validateBackup(Directory backupDir) async {
    try {
      // Check if metadata file exists
      final metadataFile = File('${backupDir.path}/backup_metadata.json');
      if (!await metadataFile.exists()) {
        return ValidationResult(false, 'Missing backup metadata');
      }
      
      // Validate metadata
      final metadataContent = await metadataFile.readAsString();
      final metadata = jsonDecode(metadataContent);
      
      if (metadata['version'] == null) {
        return ValidationResult(false, 'Invalid backup version');
      }
      
      // Check required files
      final requiredFiles = ['symbols.json', 'categories.json', 'profiles.json'];
      for (final fileName in requiredFiles) {
        final file = File('${backupDir.path}/$fileName');
        if (!await file.exists()) {
          return ValidationResult(false, 'Missing required file: $fileName');
        }
      }
      
      return ValidationResult(true, null);
    } catch (e) {
      return ValidationResult(false, 'Validation error: $e');
    }
  }

  Future<RestoreStats> _performRestore(Directory backupDir, bool replaceAll) async {
    final stats = RestoreStats();
    
    try {
      final symbolService = SymbolDatabaseService();
      final profileService = ProfileService();
      final historyService = PhraseHistoryService();
      
      if (replaceAll) {
        // Clear existing data
        await symbolService.clearAllData();
        // Clear profiles (except current one)
        // Clear history
        await historyService.clearHistory();
      }
      
      // Restore symbols
      final symbolsFile = File('${backupDir.path}/symbols.json');
      if (await symbolsFile.exists()) {
        final symbolsContent = await symbolsFile.readAsString();
        final symbolsList = jsonDecode(symbolsContent) as List;
        
        for (final symbolData in symbolsList) {
          final symbol = Symbol.fromJson(symbolData);
          await symbolService.addSymbol(symbol);
          stats.symbolsRestored++;
        }
      }
      
      // Restore categories
      final categoriesFile = File('${backupDir.path}/categories.json');
      if (await categoriesFile.exists()) {
        final categoriesContent = await categoriesFile.readAsString();
        final categoriesList = jsonDecode(categoriesContent) as List;
        
        for (final categoryData in categoriesList) {
          final category = Category.fromJson(categoryData);
          await symbolService.addCategory(category);
          stats.categoriesRestored++;
        }
      }
      
      // Restore profiles (if not replace all or user chooses)
      final profilesFile = File('${backupDir.path}/profiles.json');
      if (await profilesFile.exists()) {
        final profilesContent = await profilesFile.readAsString();
        final profilesList = jsonDecode(profilesContent) as List;
        
        for (final profileData in profilesList) {
          final profile = UserProfile.fromJson(profileData);
          await profileService.addProfile(profile);
          stats.profilesRestored++;
        }
      }
      
      // Restore phrase history
      final historyFile = File('${backupDir.path}/phrase_history.json');
      if (await historyFile.exists()) {
        final historyContent = await historyFile.readAsString();
        final historyData = jsonDecode(historyContent);
        
        if (historyData['history'] != null) {
          for (final itemData in historyData['history']) {
            final item = PhraseHistoryItem.fromJson(itemData);
            await historyService.addToHistory(item.text);
            stats.historyItemsRestored++;
          }
        }
      }
      
      // Restore custom images
      await _restoreCustomImages(backupDir);
      
    } catch (e) {
      throw Exception('Restore failed: $e');
    }
    
    return stats;
  }

  Future<void> _restoreCustomImages(Directory backupDir) async {
    final imagesDir = Directory('${backupDir.path}/custom_images');
    if (!await imagesDir.exists()) return;
    
    // Get app documents directory for storing custom images
    final appDir = await getApplicationDocumentsDirectory();
    final customImagesDir = Directory('${appDir.path}/custom_images');
    if (!await customImagesDir.exists()) {
      await customImagesDir.create(recursive: true);
    }
    
    await for (final entity in imagesDir.list()) {
      if (entity is File) {
        final fileName = entity.path.split('/').last;
        final destinationFile = File('${customImagesDir.path}/$fileName');
        await entity.copy(destinationFile.path);
      }
    }
  }

  Future<bool> deleteBackup(String backupFilePath) async {
    try {
      final file = File(backupFilePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

// Data Classes
class BackupData {
  final List<Map<String, dynamic>> symbols;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> profiles;
  final Map<String, dynamic> phraseHistory;
  final Map<String, dynamic> languageSettings;
  final List<Map<String, dynamic>> quickPhrases;

  BackupData({
    required this.symbols,
    required this.categories,
    required this.profiles,
    required this.phraseHistory,
    required this.languageSettings,
    required this.quickPhrases,
  });
}

class BackupResult {
  final bool success;
  final String? filePath;
  final String? fileName;
  final int? size;
  final String message;

  BackupResult({
    required this.success,
    this.filePath,
    this.fileName,
    this.size,
    required this.message,
  });
}

class BackupFile {
  final String fileName;
  final String filePath;
  final int size;
  final DateTime createdAt;
  final BackupMetadata? metadata;

  BackupFile({
    required this.fileName,
    required this.filePath,
    required this.size,
    required this.createdAt,
    this.metadata,
  });
}

class BackupMetadata {
  final String version;
  final DateTime createdAt;
  final String appVersion;
  final String backupType;
  final List<String> files;
  final int symbolCount;
  final int profileCount;

  BackupMetadata({
    required this.version,
    required this.createdAt,
    required this.appVersion,
    required this.backupType,
    required this.files,
    required this.symbolCount,
    required this.profileCount,
  });

  factory BackupMetadata.fromJson(Map<String, dynamic> json) => BackupMetadata(
    version: json['version'],
    createdAt: DateTime.parse(json['created_at']),
    appVersion: json['app_version'],
    backupType: json['backup_type'],
    files: List<String>.from(json['files']),
    symbolCount: json['symbol_count'],
    profileCount: json['profile_count'],
  );
}

class RestoreResult {
  final bool success;
  final String message;
  final RestoreStats? restoredItems;

  RestoreResult({
    required this.success,
    required this.message,
    this.restoredItems,
  });
}

class RestoreStats {
  int symbolsRestored = 0;
  int categoriesRestored = 0;
  int profilesRestored = 0;
  int historyItemsRestored = 0;

  @override
  String toString() {
    return 'Restored: $symbolsRestored symbols, $categoriesRestored categories, $profilesRestored profiles, $historyItemsRestored history items';
  }
}

class ValidationResult {
  final bool isValid;
  final String? error;

  ValidationResult(this.isValid, this.error);
}