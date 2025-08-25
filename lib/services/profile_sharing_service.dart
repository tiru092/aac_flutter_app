import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../services/cloud_sync_service.dart';
import '../services/auth_service.dart';

/// Custom exception for profile sharing-related errors
class ProfileSharingException implements Exception {
  final String message;
  
  ProfileSharingException(this.message);
  
  @override
  String toString() => 'ProfileSharingException: $message';
}

/// Service to handle profile sharing and collaboration features
class ProfileSharingService {
  static final ProfileSharingService _instance = ProfileSharingService._internal();
  factory ProfileSharingService() => _instance;
  ProfileSharingService._internal();

  static const String _sharedProfilesKey = 'shared_profiles';
  final CloudSyncService _cloudSyncService = CloudSyncService();
  final AuthService _authService = AuthService();

  /// Share a profile with another user
  Future<bool> shareProfile({
    required String profileId,
    required String sharedWithEmail,
    required SharingPermission permission,
    String? message,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw ProfileSharingException('User not authenticated');
      }

      // In a real implementation, you would:
      // 1. Verify the email exists in your user database
      // 2. Send an invitation to the user
      // 3. Store the sharing information in the database
      
      // For this example, we'll simulate the process
      final sharedProfile = SharedProfile(
        profileId: profileId,
        sharedWithUserId: 'user_${sharedWithEmail.hashCode}', // Simulated user ID
        sharedWithUserEmail: sharedWithEmail,
        permission: permission,
        sharedAt: DateTime.now(),
        sharedByUserId: currentUser.uid,
        message: message,
      );

      // Add to local storage
      await _addSharedProfileLocally(sharedProfile);

      // Sync to cloud if available
      if (_cloudSyncService.isCloudSyncAvailable) {
        try {
          await _cloudSyncService.shareProfileWithUser(profileId, sharedWithEmail);
        } catch (e) {
          print('Warning: Failed to sync profile sharing to cloud: $e');
        }
      }

      print('Profile $profileId shared with $sharedWithEmail');
      return true;
    } catch (e) {
      print('Error sharing profile: $e');
      return false;
    }
  }

  /// Get profiles shared with a user
  Future<List<SharedProfile>> getProfilesSharedWithUser() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        return [];
      }

      // Try to load from cloud first if available
      if (_cloudSyncService.isCloudSyncAvailable) {
        // In a real implementation, you would fetch shared profiles from Firestore
        // For this example, we'll return local data
      }

      // Load from local storage
      return await _getSharedProfilesLocally();
    } catch (e) {
      print('Error getting shared profiles: $e');
      return [];
    }
  }

  /// Get profiles shared by a user
  Future<List<SharedProfile>> getProfilesSharedByUser() async {
    try {
      // This would fetch profiles that the current user has shared with others
      // Implementation would depend on your specific data structure
      return [];
    } catch (e) {
      print('Error getting profiles shared by user: $e');
      return [];
    }
  }

  /// Accept a profile sharing invitation
  Future<bool> acceptSharedProfile(String profileId) async {
    try {
      // In a real implementation, you would:
      // 1. Verify the user has been invited to this profile
      // 2. Add the profile to the user's profile list
      // 3. Update the sharing status in the database
      
      print('Shared profile $profileId accepted');
      return true;
    } catch (e) {
      print('Error accepting shared profile: $e');
      return false;
    }
  }

  /// Reject a profile sharing invitation
  Future<bool> rejectSharedProfile(String profileId) async {
    try {
      // In a real implementation, you would:
      // 1. Verify the user has been invited to this profile
      // 2. Remove the invitation
      // 3. Update the sharing status in the database
      
      print('Shared profile $profileId rejected');
      return true;
    } catch (e) {
      print('Error rejecting shared profile: $e');
      return false;
    }
  }

  /// Remove a shared profile
  Future<bool> removeSharedProfile(String profileId) async {
    try {
      // Remove from local storage
      await _removeSharedProfileLocally(profileId);
      
      // Update in cloud if available
      if (_cloudSyncService.isCloudSyncAvailable) {
        // In a real implementation, you would update the sharing status in Firestore
      }
      
      print('Shared profile $profileId removed');
      return true;
    } catch (e) {
      print('Error removing shared profile: $e');
      return false;
    }
  }

  /// Update sharing permissions for a shared profile
  Future<bool> updateSharingPermissions({
    required String profileId,
    required String sharedWithUserId,
    required SharingPermission newPermission,
  }) async {
    try {
      // In a real implementation, you would:
      // 1. Verify the current user has permission to update sharing
      // 2. Update the sharing permissions in the database
      
      print('Sharing permissions updated for profile $profileId');
      return true;
    } catch (e) {
      print('Error updating sharing permissions: $e');
      return false;
    }
  }

  /// Check if a user has access to a profile
  Future<bool> hasAccessToProfile(String profileId) async {
    try {
      // Check if the user owns the profile or has it shared with them
      final sharedProfiles = await getProfilesSharedWithUser();
      return sharedProfiles.any((shared) => shared.profileId == profileId);
    } catch (e) {
      print('Error checking profile access: $e');
      return false;
    }
  }

  /// Get sharing details for a profile
  Future<List<SharedProfile>> getSharingDetails(String profileId) async {
    try {
      // Get all sharing information for a specific profile
      final allSharedProfiles = await getProfilesSharedWithUser();
      return allSharedProfiles.where((shared) => shared.profileId == profileId).toList();
    } catch (e) {
      print('Error getting sharing details: $e');
      return [];
    }
  }

  /// Enable real-time collaboration for a profile
  Future<bool> enableCollaboration(String profileId) async {
    try {
      // Enable real-time collaboration features for a profile
      // This might involve setting up WebSockets or similar technology
      
      print('Real-time collaboration enabled for profile $profileId');
      return true;
    } catch (e) {
      print('Error enabling collaboration: $e');
      return false;
    }
  }

  /// Disable real-time collaboration for a profile
  Future<bool> disableCollaboration(String profileId) async {
    try {
      // Disable real-time collaboration features for a profile
      
      print('Real-time collaboration disabled for profile $profileId');
      return true;
    } catch (e) {
      print('Error disabling collaboration: $e');
      return false;
    }
  }

  /// Send a collaboration message
  Future<bool> sendCollaborationMessage({
    required String profileId,
    required String message,
    required String recipientUserId,
  }) async {
    try {
      // Send a real-time message to a collaborator
      // This would typically use WebSockets or a similar technology
      
      print('Collaboration message sent to $recipientUserId for profile $profileId');
      return true;
    } catch (e) {
      print('Error sending collaboration message: $e');
      return false;
    }
  }

  /// Get collaboration status for a profile
  Future<bool> isCollaborationEnabled(String profileId) async {
    try {
      // Check if real-time collaboration is enabled for a profile
      // In a real implementation, this would check the profile settings
      return false;
    } catch (e) {
      print('Error checking collaboration status: $e');
      return false;
    }
  }

  // Private methods

  Future<void> _addSharedProfileLocally(SharedProfile sharedProfile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing shared profiles
      final sharedProfilesJson = prefs.getStringList(_sharedProfilesKey) ?? [];
      final sharedProfiles = sharedProfilesJson
          .map((json) => jsonDecode(json) as Map<String, dynamic>)
          .map((json) => SharedProfile.fromJson(json))
          .toList();
      
      // Add new shared profile
      sharedProfiles.add(sharedProfile);
      
      // Save updated list
      final updatedSharedProfilesJson = sharedProfiles
          .map((profile) => jsonEncode(profile.toJson()))
          .toList();
      
      await prefs.setStringList(_sharedProfilesKey, updatedSharedProfilesJson);
    } catch (e) {
      print('Error adding shared profile locally: $e');
      rethrow;
    }
  }

  Future<List<SharedProfile>> _getSharedProfilesLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get shared profiles
      final sharedProfilesJson = prefs.getStringList(_sharedProfilesKey) ?? [];
      return sharedProfilesJson
          .map((json) => jsonDecode(json) as Map<String, dynamic>)
          .map((json) => SharedProfile.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting shared profiles locally: $e');
      return [];
    }
  }

  Future<void> _removeSharedProfileLocally(String profileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing shared profiles
      final sharedProfilesJson = prefs.getStringList(_sharedProfilesKey) ?? [];
      final sharedProfiles = sharedProfilesJson
          .map((json) => jsonDecode(json) as Map<String, dynamic>)
          .map((json) => SharedProfile.fromJson(json))
          .toList();
      
      // Remove shared profile
      sharedProfiles.removeWhere((profile) => profile.profileId == profileId);
      
      // Save updated list
      final updatedSharedProfilesJson = sharedProfiles
          .map((profile) => jsonEncode(profile.toJson()))
          .toList();
      
      await prefs.setStringList(_sharedProfilesKey, updatedSharedProfilesJson);
    } catch (e) {
      print('Error removing shared profile locally: $e');
      rethrow;
    }
  }
}