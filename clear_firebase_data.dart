import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Script to clear all local Firebase and app data
/// Run this to fix Firebase database corruption issues
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print('Clearing all app data...');
    
    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('✓ Cleared SharedPreferences');
    
    // Initialize Firebase
    await Firebase.initializeApp();
    print('✓ Initialized Firebase');
    
    // Clear Firestore cache
    await FirebaseFirestore.instance.clearPersistence();
    print('✓ Cleared Firestore cache');
    
    // Terminate Firestore
    await FirebaseFirestore.instance.terminate();
    print('✓ Terminated Firestore');
    
    print('All data cleared successfully!');
    print('You can now restart the app.');
    
  } catch (e) {
    print('Error clearing data: $e');
  }
}
