// Example: How to integrate hybrid services into your AAC Flutter App
// This demonstrates the minimal changes needed to enable Supabase migration

import 'package:flutter/material.dart';
import 'lib/services/hybrid/index.dart';

class ExampleIntegration {
  
  // 1. Initialize hybrid services (add to main.dart)
  static Future<void> initializeHybridServices() async {
    try {
      // Enable hybrid Firebase + Supabase operation
      await hybridServices.initialize();
      
      print('✅ Hybrid services initialized successfully');
      
      // Optional: Test connectivity to both services
      final connectivity = await hybridServices.testConnectivity();
      print('Firebase: ${connectivity['firebase']}');
      print('Supabase: ${connectivity['supabase']}');
      
    } catch (e) {
      print('⚠️ Hybrid services initialization failed: $e');
      print('📝 App will continue with Firebase-only mode');
    }
  }
  
  // 2. Use hybrid authentication (replace existing auth calls)
  static Future<void> exampleLogin(String email, String password) async {
    try {
      // This automatically handles both Firebase and Supabase
      final result = await hybridServices.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('Login successful:');
      print('- Firebase: ${result['firebase']['success']}');
      print('- Supabase: ${result['supabase']?['success'] ?? 'N/A'}');
      
    } catch (e) {
      print('Login failed: $e');
    }
  }
  
  // 3. Use hybrid user profile service (replace existing profile calls)
  static Future<void> exampleProfileManagement() async {
    try {
      // Get active profile (works with both systems)
      final profile = await hybridServices.userProfile.getActiveProfile();
      
      if (profile != null) {
        print('Active profile: ${profile.name}');
        
        // Update profile (automatically syncs to both systems)
        await hybridServices.userProfile.updateProfile(profile);
        
        print('Profile updated successfully');
      }
      
    } catch (e) {
      print('Profile management failed: $e');
    }
  }
  
  // 4. Migration control (for admin/developer use)
  static Future<void> exampleMigrationControl() async {
    try {
      // Get current migration status
      final status = hybridServices.getMigrationStatus();
      print('Migration Status:');
      print('- Initialized: ${status['initialized']}');
      print('- Migration enabled: ${status['migration']['migrationEnabled']}');
      print('- Primary service: ${status['migration']['primaryService']}');
      
      // Switch to Supabase as primary (optional, when ready)
      if (status['migration']['migrationEnabled']) {
        await hybridServices.switchToSupabasePrimary();
        print('✅ Switched to Supabase as primary service');
      }
      
    } catch (e) {
      print('Migration control failed: $e');
    }
  }
  
  // 5. Rollback to Firebase-only (emergency use)
  static Future<void> emergencyRollback() async {
    try {
      await hybridServices.disableMigration();
      print('✅ Rolled back to Firebase-only mode');
      
    } catch (e) {
      print('Rollback failed: $e');
    }
  }
}

// Example main.dart integration
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (existing code - no changes needed)
  // await Firebase.initializeApp();
  
  // NEW: Initialize hybrid services for migration
  await ExampleIntegration.initializeHybridServices();
  
  runApp(MyApp());
}

// Example widget usage
class MyProfileWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile?>(
      // NEW: Use hybrid service instead of direct Firebase
      future: hybridServices.userProfile.getActiveProfile(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final profile = snapshot.data!;
          return ListTile(
            title: Text(profile.name),
            subtitle: Text(profile.email ?? 'No email'),
            trailing: IconButton(
              icon: Icon(Icons.edit),
              onPressed: () async {
                // Use hybrid service for updates
                await hybridServices.userProfile.updateProfile(profile);
              },
            ),
          );
        }
        return CircularProgressIndicator();
      },
    );
  }
}

// Migration monitoring widget (for developers)
class MigrationStatusWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: Future.value(hybridServices.getMigrationStatus()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox();
        
        final status = snapshot.data!;
        final migration = status['migration'];
        
        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Migration Status', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Enabled: ${migration['migrationEnabled']}'),
                Text('Primary: ${migration['primaryService']}'),
                Text('Supabase Ready: ${migration['supabaseConnected']}'),
                
                SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await hybridServices.switchToSupabasePrimary();
                        // Refresh UI
                      },
                      child: Text('Switch to Supabase'),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        await hybridServices.disableMigration();
                        // Refresh UI
                      },
                      child: Text('Rollback to Firebase'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/*
INTEGRATION SUMMARY:

✅ Minimal Code Changes Required:
1. Add hybrid service initialization to main.dart
2. Replace direct Firebase calls with hybrid service calls
3. Optional: Add migration status monitoring

✅ Zero Breaking Changes:
- All existing Firebase functionality preserved
- Hybrid services provide same interface
- Automatic fallback to Firebase if Supabase fails

✅ Migration Control:
- Enable/disable migration at runtime
- Switch primary service when ready
- Monitor migration status
- Emergency rollback capability

✅ Production Ready:
- Comprehensive error handling
- Logging and monitoring
- Gradual migration support
- Risk-free deployment
*/