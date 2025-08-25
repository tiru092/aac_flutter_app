# Backup and Data Management for AAC Communication Helper

This document outlines the implementation plan for cloud backup configuration, data export/import functionality, and user data migration tools for the AAC Communication Helper app.

## Cloud Backup Configuration

### 1. Firebase Cloud Storage Integration

#### Setup Dependencies
In `pubspec.yaml`:
```yaml
dependencies:
  firebase_storage: ^13.0.0
  archive: ^3.4.10  # For creating backup archives
```

#### Backup Service Implementation
```dart
// lib/services/backup_service.dart
import 'package:firebase_storage/firebase_storage.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class BackupService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  
  /// Creates a complete backup of user data
  static Future<String> createBackup(String userId) async {
    try {
      // Create backup directory
      final tempDir = await getTemporaryDirectory();
      final backupDir = Directory('${tempDir.path}/backup_$userId');
      await backupDir.create(recursive: true);
      
      // Export user profiles
      final profiles = await ProfileService.getAllProfiles();
      final profilesJson = profiles.map((p) => p.toJson()).toList();
      final profilesFile = File('${backupDir.path}/profiles.json');
      await profilesFile.writeAsString(jsonEncode(profilesJson));
      
      // Export symbols
      final symbols = await SymbolDatabaseService.getAllSymbols();
      final symbolsJson = symbols.map((s) => s.toJson()).toList();
      final symbolsFile = File('${backupDir.path}/symbols.json');
      await symbolsFile.writeAsString(jsonEncode(symbolsJson));
      
      // Export communication history
      final history = await CommunicationHistoryService.getHistory();
      final historyFile = File('${backupDir.path}/history.json');
      await historyFile.writeAsString(jsonEncode(history));
      
      // Export custom images (if any)
      await _exportCustomImages(backupDir.path);
      
      // Create ZIP archive
      final zipPath = '${tempDir.path}/backup_$userId.zip';
      final zipFile = File(zipPath);
      
      final encoder = ZipFileEncoder();
      encoder.create(zipPath);
      await encoder.addDirectory(backupDir);
      encoder.close();
      
      // Clean up temporary directory
      await backupDir.delete(recursive: true);
      
      return zipPath;
    } catch (e) {
      ErrorReportingService.recordError(e, StackTrace.current);
      rethrow;
    }
  }
  
  /// Uploads backup to cloud storage
  static Future<String> uploadBackup(String backupPath, String userId) async {
    try {
      final fileName = 'backups/$userId/backup_${DateTime.now().millisecondsSinceEpoch}.zip';
      final ref = _storage.ref().child(fileName);
      
      final uploadTask = ref.putFile(File(backupPath));
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Record backup in user's backup history
      await BackupManagementService.recordBackup(userId, fileName, downloadUrl);
      
      // Clean up local backup file
      await File(backupPath).delete();
      
      return downloadUrl;
    } catch (e) {
      ErrorReportingService.recordError(e, StackTrace.current);
      rethrow;
    }
  }
  
  /// Performs complete backup process
  static Future<String> performBackup(String userId) async {
    final backupPath = await createBackup(userId);
    final downloadUrl = await uploadBackup(backupPath, userId);
    return downloadUrl;
  }
  
  /// Exports custom images to backup directory
  static Future<void> _exportCustomImages(String backupDirPath) async {
    final customImagesDir = Directory('${backupDirPath}/images');
    await customImagesDir.create(recursive: true);
    
    // Get all symbols with custom images
    final symbolsWithImages = await SymbolDatabaseService.getSymbolsWithCustomImages();
    
    for (final symbol in symbolsWithImages) {
      if (symbol.imagePath != null && symbol.imagePath!.startsWith('file://')) {
        final sourceFile = File(symbol.imagePath!.replaceFirst('file://', ''));
        if (await sourceFile.exists()) {
          final fileName = symbol.id + '_' + sourceFile.uri.pathSegments.last;
          final destFile = File('${customImagesDir.path}/$fileName');
          await sourceFile.copy(destFile.path);
        }
      }
    }
  }
}
```

### 2. Automated Backup Scheduling

#### Backup Scheduling Service
```dart
// lib/services/backup_scheduling_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class BackupSchedulingService {
  static const String _lastBackupKey = 'last_backup_timestamp';
  static const String _backupFrequencyKey = 'backup_frequency';
  
  /// Checks if backup is due
  static Future<bool> isBackupDue() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBackup = prefs.getInt(_lastBackupKey) ?? 0;
    final frequency = prefs.getString(_backupFrequencyKey) ?? 'weekly';
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final frequencyMs = _getFrequencyInMilliseconds(frequency);
    
    return (now - lastBackup) > frequencyMs;
  }
  
  /// Records successful backup
  static Future<void> recordBackupSuccess() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastBackupKey, DateTime.now().millisecondsSinceEpoch);
  }
  
  /// Sets backup frequency
  static Future<void> setBackupFrequency(String frequency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backupFrequencyKey, frequency); // 'daily', 'weekly', 'monthly'
  }
  
  static int _getFrequencyInMilliseconds(String frequency) {
    switch (frequency) {
      case 'daily':
        return 24 * 60 * 60 * 1000;
      case 'weekly':
        return 7 * 24 * 60 * 60 * 1000;
      case 'monthly':
        return 30 * 24 * 60 * 60 * 1000;
      default:
        return 7 * 24 * 60 * 60 * 1000; // weekly default
    }
  }
  
  /// Automatic backup function
  static Future<void> performAutomaticBackup(String userId) async {
    if (await isBackupDue()) {
      try {
        await BackupService.performBackup(userId);
        await recordBackupSuccess();
        AnalyticsService.logUserAction('automatic_backup_completed');
      } catch (e) {
        AnalyticsService.logUserAction('automatic_backup_failed');
        ErrorReportingService.recordError(e, StackTrace.current);
      }
    }
  }
}
```

## Data Export/Import Functionality

### 1. Data Export Service

#### Export Formats
```dart
// lib/services/data_export_service.dart
import 'dart:convert';
import 'package:share_plus/share_plus.dart';

class DataExportService {
  /// Exports data in JSON format
  static Future<void> exportAsJson(String userId) async {
    try {
      // Gather all data
      final data = {
        'export_date': DateTime.now().toIso8601String(),
        'user_id': userId,
        'profiles': (await ProfileService.getAllProfiles()).map((p) => p.toJson()).toList(),
        'symbols': (await SymbolDatabaseService.getAllSymbols()).map((s) => s.toJson()).toList(),
        'history': await CommunicationHistoryService.getHistory(),
        'settings': await SettingsService.getAllSettings(),
      };
      
      // Create JSON file
      final jsonString = jsonEncode(data);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/aac_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);
      
      // Share file
      await Share.shareFiles([file.path], text: 'AAC Communication Helper Backup');
      
      AnalyticsService.logUserAction('data_exported', {'format': 'json'});
    } catch (e) {
      ErrorReportingService.recordError(e, StackTrace.current);
      rethrow;
    }
  }
  
  /// Exports data in CSV format (for symbols)
  static Future<void> exportSymbolsAsCsv() async {
    try {
      final symbols = await SymbolDatabaseService.getAllSymbols();
      
      final csv = StringBuffer();
      // CSV header
      csv.writeln('ID,Label,Category,Image Path,Is Emoji');
      
      // CSV rows
      for (final symbol in symbols) {
        csv.writeln([
          symbol.id,
          symbol.label,
          symbol.category,
          symbol.imagePath ?? '',
          symbol.isEmoji.toString(),
        ].join(','));
      }
      
      // Create CSV file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/symbols_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv.toString());
      
      // Share file
      await Share.shareFiles([file.path], text: 'AAC Symbols Export');
      
      AnalyticsService.logUserAction('symbols_exported', {'format': 'csv'});
    } catch (e) {
      ErrorReportingService.recordError(e, StackTrace.current);
      rethrow;
    }
  }
  
  /// Exports communication history
  static Future<void> exportHistory() async {
    try {
      final history = await CommunicationHistoryService.getHistory();
      
      final csv = StringBuffer();
      // CSV header
      csv.writeln('Timestamp,Symbol,Category,Profile');
      
      // CSV rows
      for (final entry in history) {
        csv.writeln([
          entry.timestamp.toIso8601String(),
          entry.symbolLabel,
          entry.category,
          entry.profileId,
        ].join(','));
      }
      
      // Create CSV file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/communication_history_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv.toString());
      
      // Share file
      await Share.shareFiles([file.path], text: 'AAC Communication History');
      
      AnalyticsService.logUserAction('history_exported');
    } catch (e) {
      ErrorReportingService.recordError(e, StackTrace.current);
      rethrow;
    }
  }
}
```

### 2. Data Import Service

#### Import Functionality
```dart
// lib/services/data_import_service.dart
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class DataImportService {
  /// Imports data from JSON backup
  static Future<void> importFromJson(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString);
      
      // Import profiles
      if (data['profiles'] != null) {
        for (final profileJson in data['profiles']) {
          final profile = Profile.fromJson(profileJson);
          await ProfileService.saveProfile(profile);
        }
      }
      
      // Import symbols
      if (data['symbols'] != null) {
        for (final symbolJson in data['symbols']) {
          final symbol = Symbol.fromJson(symbolJson);
          await SymbolDatabaseService.saveSymbol(symbol);
        }
      }
      
      // Import history
      if (data['history'] != null) {
        await CommunicationHistoryService.importHistory(
          List<Map<String, dynamic>>.from(data['history'])
        );
      }
      
      // Import settings
      if (data['settings'] != null) {
        await SettingsService.importSettings(
          Map<String, dynamic>.from(data['settings'])
        );
      }
      
      AnalyticsService.logUserAction('data_imported', {'format': 'json'});
    } catch (e) {
      ErrorReportingService.recordError(e, StackTrace.current);
      rethrow;
    }
  }
  
  /// Imports symbols from CSV
  static Future<void> importSymbolsFromCsv(String filePath) async {
    try {
      final file = File(filePath);
      final lines = await file.readAsLines();
      
      // Skip header
      for (var i = 1; i < lines.length; i++) {
        final parts = lines[i].split(',');
        if (parts.length >= 4) {
          final symbol = Symbol(
            id: parts[0],
            label: parts[1],
            category: parts[2],
            imagePath: parts[3].isEmpty ? null : parts[3],
          );
          await SymbolDatabaseService.saveSymbol(symbol);
        }
      }
      
      AnalyticsService.logUserAction('symbols_imported', {'format': 'csv'});
    } catch (e) {
      ErrorReportingService.recordError(e, StackTrace.current);
      rethrow;
    }
  }
  
  /// Selects file for import
  static Future<void> selectImportFile() async {
    final picker = ImagePicker();
    final result = await picker.pickFile();
    
    if (result != null) {
      final filePath = result.path;
      final extension = filePath.split('.').last.toLowerCase();
      
      switch (extension) {
        case 'json':
          await importFromJson(filePath);
          break;
        case 'csv':
          await importSymbolsFromCsv(filePath);
          break;
        default:
          throw Exception('Unsupported file format: $extension');
      }
    }
  }
}
```

## User Data Migration Tools

### 1. Cross-Device Migration

#### Migration Service
```dart
// lib/services/migration_service.dart
class MigrationService {
  /// Prepares migration package for transfer to new device
  static Future<String> prepareMigrationPackage(String userId) async {
    try {
      // Create migration directory
      final tempDir = await getTemporaryDirectory();
      final migrationDir = Directory('${tempDir.path}/migration_$userId');
      await migrationDir.create(recursive: true);
      
      // Export essential data
      final data = {
        'migration_date': DateTime.now().toIso8601String(),
        'user_id': userId,
        'profiles': (await ProfileService.getAllProfiles()).map((p) => p.toJson()).toList(),
        'symbols': (await SymbolDatabaseService.getAllSymbols()).map((s) => s.toJson()).toList(),
        'settings': await SettingsService.getAllSettings(),
      };
      
      // Save to file
      final jsonString = jsonEncode(data);
      final dataFile = File('${migrationDir.path}/migration_data.json');
      await dataFile.writeAsString(jsonString);
      
      // Export custom images
      await _exportCustomImagesForMigration(migrationDir.path);
      
      // Create ZIP archive
      final zipPath = '${tempDir.path}/migration_$userId.zip';
      final encoder = ZipFileEncoder();
      encoder.create(zipPath);
      await encoder.addDirectory(migrationDir);
      encoder.close();
      
      // Clean up temporary directory
      await migrationDir.delete(recursive: true);
      
      return zipPath;
    } catch (e) {
      ErrorReportingService.recordError(e, StackTrace.current);
      rethrow;
    }
  }
  
  /// Imports migration package on new device
  static Future<void> importMigrationPackage(String filePath) async {
    try {
      // Extract ZIP file
      final tempDir = await getTemporaryDirectory();
      final extractDir = Directory('${tempDir.path}/extracted_migration');
      await extractDir.create(recursive: true);
      
      final inputStream = InputFileStream(filePath);
      final archive = ZipDecoder().decodeBuffer(inputStream);
      extractArchiveToDisk(archive, extractDir.path);
      inputStream.close();
      
      // Read migration data
      final dataFile = File('${extractDir.path}/migration_data.json');
      final jsonString = await dataFile.readAsString();
      final data = jsonDecode(jsonString);
      
      // Import profiles
      if (data['profiles'] != null) {
        for (final profileJson in data['profiles']) {
          final profile = Profile.fromJson(profileJson);
          await ProfileService.saveProfile(profile);
        }
      }
      
      // Import symbols
      if (data['symbols'] != null) {
        for (final symbolJson in data['symbols']) {
          final symbol = Symbol.fromJson(symbolJson);
          await SymbolDatabaseService.saveSymbol(symbol);
        }
      }
      
      // Import settings
      if (data['settings'] != null) {
        await SettingsService.importSettings(
          Map<String, dynamic>.from(data['settings'])
        );
      }
      
      // Import custom images
      await _importCustomImagesFromMigration(extractDir.path);
      
      // Clean up
      await extractDir.delete(recursive: true);
      
      AnalyticsService.logUserAction('migration_completed');
    } catch (e) {
      ErrorReportingService.recordError(e, StackTrace.current);
      rethrow;
    }
  }
  
  static Future<void> _exportCustomImagesForMigration(String migrationDirPath) async {
    final imagesDir = Directory('${migrationDirPath}/images');
    await imagesDir.create(recursive: true);
    
    final symbolsWithImages = await SymbolDatabaseService.getSymbolsWithCustomImages();
    
    for (final symbol in symbolsWithImages) {
      if (symbol.imagePath != null && symbol.imagePath!.startsWith('file://')) {
        final sourceFile = File(symbol.imagePath!.replaceFirst('file://', ''));
        if (await sourceFile.exists()) {
          final fileName = '${symbol.id}_${sourceFile.uri.pathSegments.last}';
          final destFile = File('${imagesDir.path}/$fileName');
          await sourceFile.copy(destFile.path);
        }
      }
    }
  }
  
  static Future<void> _importCustomImagesFromMigration(String extractDirPath) async {
    final imagesDir = Directory('${extractDirPath}/images');
    if (await imagesDir.exists()) {
      final imageFiles = imagesDir.listSync();
      
      final appDir = await getApplicationDocumentsDirectory();
      final symbolsDir = Directory('${appDir.path}/symbols');
      await symbolsDir.create(recursive: true);
      
      for (final fileEntity in imageFiles) {
        if (fileEntity is File) {
          final fileName = fileEntity.uri.pathSegments.last;
          final destFile = File('${symbolsDir.path}/$fileName');
          await fileEntity.copy(destFile.path);
        }
      }
    }
  }
}
```

### 2. Version Migration

#### Handling Data Structure Changes
```dart
// lib/services/version_migration_service.dart
class VersionMigrationService {
  static const String _currentDataVersion = '1.0.0';
  static const String _dataVersionKey = 'data_version';
  
  /// Checks and performs necessary migrations
  static Future<void> checkAndPerformMigrations() async {
    final prefs = await SharedPreferences.getInstance();
    final storedVersion = prefs.getString(_dataVersionKey) ?? '1.0.0';
    
    if (storedVersion != _currentDataVersion) {
      await _performMigrations(storedVersion, _currentDataVersion);
      await prefs.setString(_dataVersionKey, _currentDataVersion);
    }
  }
  
  static Future<void> _performMigrations(String fromVersion, String toVersion) async {
    // Example migration from 1.0.0 to 1.1.0
    if (fromVersion == '1.0.0' && toVersion == '1.1.0') {
      await _migrateFrom100To110();
    }
    
    // Add more migrations as needed
  }
  
  static Future<void> _migrateFrom100To110() async {
    // Example: Add new fields to existing symbols
    final allSymbols = await SymbolDatabaseService.getAllSymbols();
    
    for (final symbol in allSymbols) {
      // Add new property with default value
      symbol.isFavorite = false;
      await SymbolDatabaseService.saveSymbol(symbol);
    }
    
    AnalyticsService.logUserAction('data_migrated', {
      'from_version': '1.0.0',
      'to_version': '1.1.0',
    });
  }
}
```

## Backup Management UI

### 1. Backup Management Screen

```dart
// lib/screens/backup_management_screen.dart
class BackupManagementScreen extends StatefulWidget {
  @override
  _BackupManagementScreenState createState() => _BackupManagementScreenState();
}

class _BackupManagementScreenState extends State<BackupManagementScreen> {
  bool _isBackingUp = false;
  List<BackupInfo> _backups = [];
  
  @override
  void initState() {
    super.initState();
    _loadBackups();
  }
  
  Future<void> _loadBackups() async {
    final backups = await BackupManagementService.getBackupHistory();
    setState(() {
      _backups = backups;
    });
  }
  
  Future<void> _performBackup() async {
    setState(() {
      _isBackingUp = true;
    });
    
    try {
      final userId = AuthService.currentUserId;
      final downloadUrl = await BackupService.performBackup(userId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup completed successfully!')),
      );
      
      await _loadBackups();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup failed: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isBackingUp = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Backup Management')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cloud Backup', style: Theme.of(context).textTheme.headline6),
                    SizedBox(height: 16),
                    Text('Automatically backup your profiles, symbols, and communication history to the cloud.'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isBackingUp ? null : _performBackup,
                      child: _isBackingUp
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white), strokeWidth: 2),
                                SizedBox(width: 8),
                                Text('Backing Up...'),
                              ],
                            )
                          : Text('Backup Now'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            Text('Backup History', style: Theme.of(context).textTheme.headline6),
            SizedBox(height: 16),
            Expanded(
              child: _backups.isEmpty
                  ? Center(child: Text('No backups found'))
                  : ListView.builder(
                      itemCount: _backups.length,
                      itemBuilder: (context, index) {
                        final backup = _backups[index];
                        return Card(
                          child: ListTile(
                            title: Text('Backup from ${backup.timestamp}'),
                            subtitle: Text('${backup.size} • ${backup.status}'),
                            trailing: IconButton(
                              icon: Icon(Icons.download),
                              onPressed: () => _downloadBackup(backup),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _downloadBackup(BackupInfo backup) async {
    // Implementation for downloading backup
  }
}
```

## Security Considerations

### 1. Data Encryption for Backups

```dart
// lib/services/encrypted_backup_service.dart
import 'package:encrypt/encrypt.dart';

class EncryptedBackupService {
  static final _key = Key.fromUtf8('your-32-character-secret-key-here');
  static final _iv = IV.fromLength(16);
  static final _encrypter = Encrypter(AES(_key));
  
  /// Encrypts backup data before upload
  static Future<String> encryptBackupData(String data) async {
    try {
      final encrypted = _encrypter.encrypt(data, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      ErrorReportingService.recordError(e, StackTrace.current);
      rethrow;
    }
  }
  
  /// Decrypts backup data after download
  static Future<String> decryptBackupData(String encryptedData) async {
    try {
      final encrypted = Encrypted.from64(encryptedData);
      final decrypted = _encrypter.decrypt(encrypted, iv: _iv);
      return decrypted;
    } catch (e) {
      ErrorReportingService.recordError(e, StackTrace.current);
      rethrow;
    }
  }
}
```

## Implementation Checklist

### Immediate Actions
- [ ] Implement basic backup service with Firebase Storage
- [ ] Create data export functionality (JSON, CSV)
- [ ] Implement data import functionality
- [ ] Add backup scheduling service
- [ ] Create backup management UI

### Short-term Goals (1-2 weeks)
- [ ] Implement cross-device migration tools
- [ ] Add version migration service
- [ ] Implement encrypted backups
- [ ] Add backup history tracking
- [ ] Create automated backup notifications

### Long-term Goals (1-2 months)
- [ ] Implement selective backup/restore
- [ ] Add backup compression for large datasets
- [ ] Create backup verification system
- [ ] Implement incremental backups
- [ ] Add backup size optimization
- [ ] Create backup analytics and monitoring

This backup and data management system ensures that users never lose their important communication data, can easily transfer their setup between devices, and have multiple options for exporting and importing their information while maintaining security and privacy standards.