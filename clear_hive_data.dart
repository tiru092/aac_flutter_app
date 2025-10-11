import 'dart:io';

void main() async {
  print('🧹 Clearing corrupted Hive data...');
  
  // Clear Hive data directories
  final directories = [
    Directory('build/app/outputs'),
    Directory('android/app/src/main/assets/hive'),
    Directory('assets/hive'),
  ];
  
  for (var dir in directories) {
    if (await dir.exists()) {
      print('Clearing directory: ${dir.path}');
      await dir.delete(recursive: true);
    }
  }
  
  // On Android, the data is stored in app data directory, 
  // which will be cleared when we reinstall the app
  print('✅ Hive data cleared. Please reinstall the app to complete the fix.');
}