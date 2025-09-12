import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// Emergency fix for Hive corruption that prevents data loading
class HiveCorruptionFix {
  static Future<void> fixHiveCorruption() async {
    try {
      print('[HIVE_FIX] Starting Hive corruption fix...');
      
      // Close all Hive boxes first
      try {
        await Hive.close();
        print('[HIVE_FIX] All Hive boxes closed');
      } catch (e) {
        print('[HIVE_FIX] Error closing boxes: $e');
      }
      
      // Get the app documents directory
      final appDocumentsDir = await getApplicationDocumentsDirectory();
      final hiveDir = Directory('${appDocumentsDir.path}/hive');
      
      if (await hiveDir.exists()) {
        print('[HIVE_FIX] Found Hive directory: ${hiveDir.path}');
        
        // Delete all Hive files
        await hiveDir.delete(recursive: true);
        print('[HIVE_FIX] Deleted corrupted Hive directory');
      }
      
      // Also check for Hive files in the app data directory
      final List<String> possibleHivePaths = [
        '${appDocumentsDir.path}',
        '${appDocumentsDir.path}/databases',
        '${appDocumentsDir.path}/cache',
      ];
      
      for (final path in possibleHivePaths) {
        final dir = Directory(path);
        if (await dir.exists()) {
          final files = await dir.list().toList();
          for (final file in files) {
            if (file.path.contains('.hive') || file.path.contains('.lock')) {
              try {
                await file.delete();
                print('[HIVE_FIX] Deleted: ${file.path}');
              } catch (e) {
                print('[HIVE_FIX] Could not delete ${file.path}: $e');
              }
            }
          }
        }
      }
      
      print('[HIVE_FIX] All corrupted Hive data cleared successfully');
      print('[HIVE_FIX] App will create fresh Hive databases on next start');
      
    } catch (e) {
      print('[HIVE_FIX] Error during Hive fix: $e');
    }
  }
}
