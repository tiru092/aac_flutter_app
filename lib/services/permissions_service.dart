import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

/// Custom exception for permissions-related errors
class PermissionsException implements Exception {
  final String message;
  
  PermissionsException(this.message);
  
  @override
  String toString() => 'PermissionsException: $message';
}

/// Service to handle role-based access control with granular permissions
class PermissionsService {
  static final PermissionsService _instance = PermissionsService._internal();
  factory PermissionsService() => _instance;
  PermissionsService._internal();

  static const String _userPermissionsKey = 'user_permissions';
  static const String _rolePermissionsKey = 'role_permissions';

  /// Check if a user has a specific permission
  Future<bool> hasPermission(String userId, Permission permission) async {
    try {
      // Get user's role
      final userRole = await _getUserRole(userId);
      if (userRole == null) {
        return false;
      }

      // Check role-based permissions
      final roleHasPermission = await _checkRolePermission(userRole, permission);
      if (roleHasPermission) {
        return true;
      }

      // Check user-specific permissions
      final userHasPermission = await _checkUserPermission(userId, permission);
      return userHasPermission;
    } catch (e) {
      print('Error checking permission: $e');
      return false;
    }
  }

  /// Check if a user has a specific role
  Future<bool> hasRole(String userId, UserRole role) async {
    try {
      final userRole = await _getUserRole(userId);
      return userRole == role;
    } catch (e) {
      print('Error checking role: $e');
      return false;
    }
  }

  /// Get all permissions for a user
  Future<List<Permission>> getUserPermissions(String userId) async {
    try {
      // Get user's role
      final userRole = await _getUserRole(userId);
      final permissions = <Permission>[];

      // Add role-based permissions
      if (userRole != null) {
        final rolePermissions = await _getRolePermissions(userRole);
        permissions.addAll(rolePermissions);
      }

      // Add user-specific permissions
      final userPermissions = await _getUserSpecificPermissions(userId);
      permissions.addAll(userPermissions);

      // Remove any denied permissions
      final deniedPermissions = await _getUserDeniedPermissions(userId);
      permissions.removeWhere((permission) => deniedPermissions.contains(permission));

      return permissions.toSet().toList(); // Remove duplicates
    } catch (e) {
      print('Error getting user permissions: $e');
      return [];
    }
  }

  /// Grant a permission to a user
  Future<void> grantPermission(String userId, Permission permission) async {
    try {
      await _addUserPermission(userId, permission, PermissionStatus.granted);
      print('Permission $permission granted to user $userId');
    } catch (e) {
      print('Error granting permission: $e');
      rethrow;
    }
  }

  /// Deny a permission to a user
  Future<void> denyPermission(String userId, Permission permission) async {
    try {
      await _addUserPermission(userId, permission, PermissionStatus.denied);
      print('Permission $permission denied for user $userId');
    } catch (e) {
      print('Error denying permission: $e');
      rethrow;
    }
  }

  /// Revoke a user-specific permission (removes grant/deny)
  Future<void> revokePermission(String userId, Permission permission) async {
    try {
      await _removeUserPermission(userId, permission);
      print('Permission $permission revoked for user $userId');
    } catch (e) {
      print('Error revoking permission: $e');
      rethrow;
    }
  }

  /// Get all users with a specific role
  Future<List<String>> getUsersWithRole(UserRole role) async {
    try {
      // In a real implementation, this would query the database
      // For this example, we'll return an empty list
      return [];
    } catch (e) {
      print('Error getting users with role: $e');
      return [];
    }
  }

  /// Assign a role to a user
  Future<void> assignRole(String userId, UserRole role) async {
    try {
      await _setUserRole(userId, role);
      print('Role $role assigned to user $userId');
    } catch (e) {
      print('Error assigning role: $e');
      rethrow;
    }
  }

  /// Remove a role from a user
  Future<void> removeRole(String userId) async {
    try {
      await _removeUserRole(userId);
      print('Role removed from user $userId');
    } catch (e) {
      print('Error removing role: $e');
      rethrow;
    }
  }

  /// Check if a feature is accessible to a user
  Future<bool> isFeatureAccessible(String userId, Feature feature) async {
    try {
      // Check if the feature requires specific permissions
      final requiredPermissions = _getFeatureRequiredPermissions(feature);
      
      // If no permissions required, feature is accessible
      if (requiredPermissions.isEmpty) {
        return true;
      }

      // Check if user has any of the required permissions
      for (final permission in requiredPermissions) {
        if (await hasPermission(userId, permission)) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error checking feature accessibility: $e');
      return false;
    }
  }

  /// Get role hierarchy (higher roles include permissions of lower roles)
  Future<List<UserRole>> getRoleHierarchy(UserRole role) async {
    try {
      switch (role) {
        case UserRole.child:
          return [UserRole.child];
        case UserRole.caregiver:
          return [UserRole.child, UserRole.caregiver];
        case UserRole.therapist:
          return [UserRole.child, UserRole.caregiver, UserRole.therapist];
        case UserRole.administrator:
          return [UserRole.child, UserRole.caregiver, UserRole.therapist, UserRole.administrator];
        default:
          return [role];
      }
    } catch (e) {
      print('Error getting role hierarchy: $e');
      return [role];
    }
  }

  /// Get default permissions for a role
  Future<List<Permission>> getDefaultRolePermissions(UserRole role) async {
    try {
      return _getDefaultPermissionsForRole(role);
    } catch (e) {
      print('Error getting default role permissions: $e');
      return [];
    }
  }

  /// Create a custom role with specific permissions
  Future<void> createCustomRole(String roleName, List<Permission> permissions) async {
    try {
      // In a real implementation, this would store the custom role in the database
      print('Custom role $roleName created with ${permissions.length} permissions');
    } catch (e) {
      print('Error creating custom role: $e');
      rethrow;
    }
  }

  /// Get audit log of permission changes
  Future<List<PermissionAuditLog>> getPermissionAuditLog(String userId) async {
    try {
      // In a real implementation, this would fetch audit logs from the database
      // For this example, we'll return an empty list
      return [];
    } catch (e) {
      print('Error getting permission audit log: $e');
      return [];
    }
  }

  // Private methods

  Future<UserRole?> _getUserRole(String userId) async {
    try {
      // In a real implementation, this would fetch the user's role from the database
      // For this example, we'll use a simplified approach with shared preferences
      final prefs = await SharedPreferences.getInstance();
      final roleString = prefs.getString('user_role_$userId');
      
      if (roleString == null) {
        return null;
      }
      
      return UserRole.values.firstWhere(
        (role) => role.toString() == roleString,
        orElse: () => UserRole.child,
      );
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  Future<void> _setUserRole(String userId, UserRole role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role_$userId', role.toString());
    } catch (e) {
      print('Error setting user role: $e');
      rethrow;
    }
  }

  Future<void> _removeUserRole(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_role_$userId');
    } catch (e) {
      print('Error removing user role: $e');
      rethrow;
    }
  }

  Future<bool> _checkRolePermission(UserRole role, Permission permission) async {
    try {
      final rolePermissions = await _getRolePermissions(role);
      return rolePermissions.contains(permission);
    } catch (e) {
      print('Error checking role permission: $e');
      return false;
    }
  }

  Future<List<Permission>> _getRolePermissions(UserRole role) async {
    try {
      return _getDefaultPermissionsForRole(role);
    } catch (e) {
      print('Error getting role permissions: $e');
      return [];
    }
  }

  Future<bool> _checkUserPermission(String userId, Permission permission) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final permissionsJson = prefs.getString('$_userPermissionsKey_$userId');
      
      if (permissionsJson == null) {
        return false;
      }
      
      final permissionsData = jsonDecode(permissionsJson) as List;
      final permissions = permissionsData
          .map((data) => UserPermission.fromJson(Map<String, dynamic>.from(data)))
          .toList();
      
      final userPermission = permissions.firstWhere(
        (perm) => perm.permission == permission,
        orElse: () => UserPermission(
          permission: permission,
          status: PermissionStatus.denied,
          grantedAt: DateTime.now(),
        ),
      );
      
      return userPermission.status == PermissionStatus.granted;
    } catch (e) {
      print('Error checking user permission: $e');
      return false;
    }
  }

  Future<List<Permission>> _getUserSpecificPermissions(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final permissionsJson = prefs.getString('$_userPermissionsKey_$userId');
      
      if (permissionsJson == null) {
        return [];
      }
      
      final permissionsData = jsonDecode(permissionsJson) as List;
      final permissions = permissionsData
          .map((data) => UserPermission.fromJson(Map<String, dynamic>.from(data)))
          .where((perm) => perm.status == PermissionStatus.granted)
          .map((perm) => perm.permission)
          .toList();
      
      return permissions;
    } catch (e) {
      print('Error getting user specific permissions: $e');
      return [];
    }
  }

  Future<List<Permission>> _getUserDeniedPermissions(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final permissionsJson = prefs.getString('$_userPermissionsKey_$userId');
      
      if (permissionsJson == null) {
        return [];
      }
      
      final permissionsData = jsonDecode(permissionsJson) as List;
      final permissions = permissionsData
          .map((data) => UserPermission.fromJson(Map<String, dynamic>.from(data)))
          .where((perm) => perm.status == PermissionStatus.denied)
          .map((perm) => perm.permission)
          .toList();
      
      return permissions;
    } catch (e) {
      print('Error getting user denied permissions: $e');
      return [];
    }
  }

  Future<void> _addUserPermission(
    String userId, 
    Permission permission, 
    PermissionStatus status
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing permissions
      final permissionsJson = prefs.getString('$_userPermissionsKey_$userId');
      final permissions = permissionsJson != null
          ? (jsonDecode(permissionsJson) as List)
              .map((data) => UserPermission.fromJson(Map<String, dynamic>.from(data)))
              .toList()
          : <UserPermission>[];
      
      // Remove existing permission if it exists
      permissions.removeWhere((perm) => perm.permission == permission);
      
      // Add new permission
      permissions.add(UserPermission(
        permission: permission,
        status: status,
        grantedAt: DateTime.now(),
      ));
      
      // Save updated permissions
      final updatedPermissionsJson = permissions
          .map((perm) => perm.toJson())
          .toList();
      
      await prefs.setString(
        '$_userPermissionsKey_$userId',
        jsonEncode(updatedPermissionsJson),
      );
    } catch (e) {
      print('Error adding user permission: $e');
      rethrow;
    }
  }

  Future<void> _removeUserPermission(String userId, Permission permission) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing permissions
      final permissionsJson = prefs.getString('$_userPermissionsKey_$userId');
      
      if (permissionsJson == null) {
        return;
      }
      
      final permissions = (jsonDecode(permissionsJson) as List)
          .map((data) => UserPermission.fromJson(Map<String, dynamic>.from(data)))
          .toList();
      
      // Remove permission
      permissions.removeWhere((perm) => perm.permission == permission);
      
      // Save updated permissions
      final updatedPermissionsJson = permissions
          .map((perm) => perm.toJson())
          .toList();
      
      await prefs.setString(
        '$_userPermissionsKey_$userId',
        jsonEncode(updatedPermissionsJson),
      );
    } catch (e) {
      print('Error removing user permission: $e');
      rethrow;
    }
  }

  List<Permission> _getDefaultPermissionsForRole(UserRole role) {
    try {
      switch (role) {
        case UserRole.child:
          return [
            Permission.useCommunicationGrid,
            Permission.playRecordedSounds,
            Permission.viewOwnProfile,
            Permission.viewOwnHistory,
          ];
        case UserRole.caregiver:
          return [
            Permission.useCommunicationGrid,
            Permission.playRecordedSounds,
            Permission.viewOwnProfile,
            Permission.viewOwnHistory,
            Permission.createSymbols,
            Permission.editSymbols,
            Permission.createCategories,
            Permission.editCategories,
            Permission.manageOwnProfile,
            Permission.viewOtherProfiles,
          ];
        case UserRole.therapist:
          return [
            Permission.useCommunicationGrid,
            Permission.playRecordedSounds,
            Permission.viewOwnProfile,
            Permission.viewOwnHistory,
            Permission.createSymbols,
            Permission.editSymbols,
            Permission.deleteSymbols,
            Permission.createCategories,
            Permission.editCategories,
            Permission.deleteCategories,
            Permission.manageOwnProfile,
            Permission.viewOtherProfiles,
            Permission.editOtherProfiles,
            Permission.createCustomVoices,
            Permission.manageTherapySettings,
          ];
        case UserRole.administrator:
          return [
            Permission.useCommunicationGrid,
            Permission.playRecordedSounds,
            Permission.viewOwnProfile,
            Permission.viewOwnHistory,
            Permission.createSymbols,
            Permission.editSymbols,
            Permission.deleteSymbols,
            Permission.createCategories,
            Permission.editCategories,
            Permission.deleteCategories,
            Permission.manageOwnProfile,
            Permission.viewOtherProfiles,
            Permission.editOtherProfiles,
            Permission.deleteOtherProfiles,
            Permission.createCustomVoices,
            Permission.manageTherapySettings,
            Permission.manageAppSettings,
            Permission.manageUsers,
            Permission.viewAnalytics,
            Permission.managePermissions,
          ];
        default:
          return [];
      }
    } catch (e) {
      print('Error getting default permissions for role: $e');
      return [];
    }
  }

  List<Permission> _getFeatureRequiredPermissions(Feature feature) {
    try {
      switch (feature) {
        case Feature.communicationGrid:
          return [Permission.useCommunicationGrid];
        case Feature.symbolCreation:
          return [Permission.createSymbols];
        case Feature.symbolEditing:
          return [Permission.editSymbols];
        case Feature.symbolDeletion:
          return [Permission.deleteSymbols];
        case Feature.categoryManagement:
          return [Permission.createCategories, Permission.editCategories];
        case Feature.profileManagement:
          return [Permission.manageOwnProfile];
        case Feature.voiceCustomization:
          return [Permission.createCustomVoices];
        case Feature.therapySettings:
          return [Permission.manageTherapySettings];
        case Feature.adminPanel:
          return [Permission.manageAppSettings, Permission.manageUsers];
        case Feature.analytics:
          return [Permission.viewAnalytics];
        case Feature.permissionsManagement:
          return [Permission.managePermissions];
        default:
          return [];
      }
    } catch (e) {
      print('Error getting feature required permissions: $e');
      return [];
    }
  }
}

// Data classes

enum Permission {
  // Basic permissions
  useCommunicationGrid,
  playRecordedSounds,
  viewOwnProfile,
  viewOwnHistory,
  
  // Symbol management
  createSymbols,
  editSymbols,
  deleteSymbols,
  
  // Category management
  createCategories,
  editCategories,
  deleteCategories,
  
  // Profile management
  manageOwnProfile,
  viewOtherProfiles,
  editOtherProfiles,
  deleteOtherProfiles,
  
  // Voice customization
  createCustomVoices,
  
  // Therapy settings
  manageTherapySettings,
  
  // Admin permissions
  manageAppSettings,
  manageUsers,
  viewAnalytics,
  managePermissions,
}

enum PermissionStatus {
  granted,
  denied,
}

class UserPermission {
  final Permission permission;
  final PermissionStatus status;
  final DateTime grantedAt;
  final String? grantedBy;

  UserPermission({
    required this.permission,
    required this.status,
    required this.grantedAt,
    this.grantedBy,
  });

  Map<String, dynamic> toJson() => {
        'permission': permission.toString(),
        'status': status.toString(),
        'grantedAt': grantedAt.toIso8601String(),
        'grantedBy': grantedBy,
      };

  factory UserPermission.fromJson(Map<String, dynamic> json) => UserPermission(
        permission: Permission.values.firstWhere(
          (p) => p.toString() == json['permission'],
          orElse: () => Permission.useCommunicationGrid,
        ),
        status: PermissionStatus.values.firstWhere(
          (s) => s.toString() == json['status'],
          orElse: () => PermissionStatus.denied,
        ),
        grantedAt: DateTime.parse(json['grantedAt']),
        grantedBy: json['grantedBy'],
      );
}

enum Feature {
  communicationGrid,
  symbolCreation,
  symbolEditing,
  symbolDeletion,
  categoryManagement,
  profileManagement,
  voiceCustomization,
  therapySettings,
  adminPanel,
  analytics,
  permissionsManagement,
}

class PermissionAuditLog {
  final String userId;
  final Permission permission;
  final PermissionStatus status;
  final DateTime timestamp;
  final String? performedBy;
  final String? reason;

  PermissionAuditLog({
    required this.userId,
    required this.permission,
    required this.status,
    required this.timestamp,
    this.performedBy,
    this.reason,
  });
}