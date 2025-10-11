// Simple profile sync fix for the main app
// Add this to your home_screen.dart or create a button to run this

import '../services/unified_supabase_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileSyncFix {
  static Future<void> fixProfileSync() async {
    try {
      print('🔧 Starting profile sync fix...');
      
      final user = UnifiedSupabaseAuthService.currentUser;
      if (user == null) {
        print('❌ No user signed in');
        return;
      }
      
      print('👤 Current user: ${user.email}');
      print('🆔 Supabase User ID: ${user.id}');
      
      // Fix local profile ID to match Supabase User ID
      final prefs = await SharedPreferences.getInstance();
      final currentProfileId = prefs.getString('current_profile_id');
      
      print('📝 Current local profile ID: ${currentProfileId ?? 'None'}');
      
      if (currentProfileId != user.id) {
        print('🔧 Fixing profile ID mismatch...');
        await prefs.setString('current_profile_id', user.id);
        print('✅ Profile ID updated to Supabase User ID');
      }
      
      // Check Firebase data
      final firestore = FirebaseFirestore.instance;
      final profileDoc = await firestore.collection('user_profiles').doc(user.id).get();
      
      if (profileDoc.exists) {
        print('✅ Found Firebase profile data');
        final data = profileDoc.data()!;
        
        if (data.containsKey('userCategories')) {
          final categories = data['userCategories'];
          print('📁 Found ${categories is List ? categories.length : 0} categories in Firebase');
        }
        
        if (data.containsKey('userSymbols')) {
          final symbols = data['userSymbols'];
          print('🔣 Found ${symbols is List ? symbols.length : 0} symbols in Firebase');
        }
      } else {
        print('❌ No Firebase profile data found');
      }
      
      print('✅ Profile sync fix completed');
      print('🔄 Please restart the app to reload data');
      
    } catch (e) {
      print('❌ Error fixing profile sync: $e');
    }
  }
}
