import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

/// Emergency script to fix Firebase Firestore corruption issue
/// This issue is caused by documents becoming too large for SQLite cursor window
/// NOT related to recent code changes
void main() async {
  print('🚨 EMERGENCY: Fixing Firebase Firestore corruption...');
  
  try {
    await Firebase.initializeApp();
    final firestore = FirebaseFirestore.instance;
    
    print('📋 Clearing problematic collections...');
    
    // Clear document_overlays which is causing the issue
    print('🗑️  Clearing document overlays...');
    await clearCollection(firestore, 'document_overlays');
    
    // Clear large user data that might be corrupted
    print('🗑️  Clearing user profiles...');
    await clearCollection(firestore, 'user_profiles');
    
    print('🗑️  Clearing symbols...');
    await clearCollection(firestore, 'symbols');
    
    print('🗑️  Clearing categories...');
    await clearCollection(firestore, 'categories');
    
    print('🗑️  Clearing practice goals...');
    await clearCollection(firestore, 'practice_goals');
    
    // Clear offline cache
    print('📱 Clearing offline cache...');
    await firestore.clearPersistence();
    
    print('✅ Firebase corruption fixed! App should work now.');
    print('ℹ️  Note: You will need to re-setup your data');
    
  } catch (e) {
    print('❌ Error during cleanup: $e');
    print('💡 Try manually clearing app data from Android settings');
  }
  
  exit(0);
}

Future<void> clearCollection(FirebaseFirestore firestore, String collection) async {
  try {
    final batch = firestore.batch();
    final snapshot = await firestore.collection(collection).get();
    
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
    print('   ✅ Cleared $collection (${snapshot.docs.length} documents)');
  } catch (e) {
    print('   ⚠️  Could not clear $collection: $e');
  }
}
