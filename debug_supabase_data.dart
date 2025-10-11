import 'dart:io';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://ealnaxzytlhpewasltbv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVhbG5heHp5dGxocGV3YXNsdGJ2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzM5MzQzMTQsImV4cCI6MjA0OTUxMDMxNH0.oAujNyj8Mc8y7BTT5BNttRhi_Kp4Frc8U6JLpgHNEB4',
  );

  final userId = 'a2c90b93-2854-4ce6-960f-8708d0484aeb';
  
  print('🔍 Checking Supabase data for user: $userId');
  
  try {
    // Check user_favorites table
    final favoritesResult = await Supabase.instance.client
        .from('user_favorites')
        .select('*')
        .eq('user_id', userId);
    print('📊 user_favorites: ${favoritesResult.length} records');
    for (final fav in favoritesResult) {
      print('  - $fav');
    }
    
    // Check user_custom_categories table
    final categoriesResult = await Supabase.instance.client
        .from('user_custom_categories')
        .select('*')
        .eq('user_id', userId);
    print('📊 user_custom_categories: ${categoriesResult.length} records');
    for (final cat in categoriesResult) {
      print('  - $cat');
    }
    
    // Check user_custom_symbols table
    final symbolsResult = await Supabase.instance.client
        .from('user_custom_symbols')
        .select('*')
        .eq('profile_id', userId);
    print('📊 user_custom_symbols: ${symbolsResult.length} records');
    for (final sym in symbolsResult) {
      print('  - ${sym['label']}: ${sym['id']}');
    }
    
    // Check communication_history table
    final historyResult = await Supabase.instance.client
        .from('communication_history')
        .select('*')
        .eq('user_id', userId);
    print('📊 communication_history: ${historyResult.length} records');
    
  } catch (e) {
    print('❌ Error checking Supabase data: $e');
  }
}