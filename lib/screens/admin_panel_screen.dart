import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/permissions_service.dart';
import '../services/user_profile_service.dart';

class AdminPanelScreen extends StatefulWidget {
  final UserProfile currentUser;

  const AdminPanelScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final PermissionsService _permissionsService = PermissionsService();
  
  bool _isLoading = false;
  String _statusMessage = '';
  List<UserProfile> _users = [];
  UserProfile? _selectedUser;
  UserRole? _selectedRole;
  Permission? _selectedPermission;
  PermissionStatus? _permissionStatus;
  bool _showAddUserForm = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch users from the user profile service
      final users = await UserProfileService.getAllProfiles();
      
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error loading users: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _assignRole() async {
    if (_selectedUser == null || _selectedRole == null) {
      setState(() {
        _statusMessage = 'Please select a user and role';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      await _permissionsService.assignRole(_selectedUser!.id, _selectedRole!);
      
      if (mounted) {
        setState(() {
          _statusMessage = 'Role assigned successfully!';
          _isLoading = false;
        });

        // Reload users
        await _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error assigning role: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _managePermission() async {
    if (_selectedUser == null || _selectedPermission == null || _permissionStatus == null) {
      setState(() {
        _statusMessage = 'Please select a user, permission, and status';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      if (_permissionStatus == PermissionStatus.granted) {
        await _permissionsService.grantPermission(_selectedUser!.id, _selectedPermission!);
      } else {
        await _permissionsService.denyPermission(_selectedUser!.id, _selectedPermission!);
      }
      
      if (mounted) {
        setState(() {
          _statusMessage = 'Permission updated successfully!';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error updating permission: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addUser() async {
    if (_nameController.text.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter a name for the user';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      final newUser = await UserProfileService.createProfile(
        name: _nameController.text,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        phoneNumber: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      );
      
      if (mounted) {
        setState(() {
          _statusMessage = 'User added successfully!';
          _isLoading = false;
          _showAddUserForm = false;
          _nameController.clear();
          _emailController.clear();
          _phoneController.clear();
        });

        // Reload users
        await _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error adding user: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteUser(UserProfile user) async {
    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      await UserProfileService.deleteProfile(user.id);
      
      if (mounted) {
        setState(() {
          _statusMessage = 'User deleted successfully!';
          _isLoading = false;
        });

        // Reload users
        await _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error deleting user: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _confirmDeleteUser(UserProfile user) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete the user "${user.name}"? This action cannot be undone.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(user);
            },
            isDestructiveAction: true,
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Admin Panel'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Admin Panel',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Manage user roles and permissions',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              if (_isLoading) ...[
                const Center(
                  child: CupertinoActivityIndicator(
                    radius: 20,
                  ),
                ),
                const SizedBox(height: 20),
              ] else ...[
                // Add User Section
                if (_showAddUserForm) ...[
                  const Text(
                    'Add New User',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  CupertinoTextField(
                    controller: _nameController,
                    placeholder: 'Name',
                    prefix: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(CupertinoIcons.person),
                    ),
                  ),
                  const SizedBox(height: 10),
                  CupertinoTextField(
                    controller: _emailController,
                    placeholder: 'Email (optional)',
                    keyboardType: TextInputType.emailAddress,
                    prefix: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(CupertinoIcons.mail),
                    ),
                  ),
                  const SizedBox(height: 10),
                  CupertinoTextField(
                    controller: _phoneController,
                    placeholder: 'Phone (optional)',
                    keyboardType: TextInputType.phone,
                    prefix: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(CupertinoIcons.phone),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoButton(
                          onPressed: _addUser,
                          child: const Text('Add User'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CupertinoButton(
                          onPressed: () {
                            setState(() {
                              _showAddUserForm = false;
                              _nameController.clear();
                              _emailController.clear();
                              _phoneController.clear();
                            });
                          },
                          child: const Text('Cancel'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed: () {
                        setState(() {
                          _showAddUserForm = true;
                        });
                      },
                      child: const Text('Add New User'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                
                // Role Assignment Section
                const Text(
                  'Assign Role',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _buildUserSelector(),
                const SizedBox(height: 10),
                _buildRoleSelector(),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed: _assignRole,
                    child: const Text('Assign Role'),
                  ),
                ),
                const SizedBox(height: 30),
                
                // Permission Management Section
                const Text(
                  'Manage Permissions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _buildUserSelector(forPermission: true),
                const SizedBox(height: 10),
                _buildPermissionSelector(),
                const SizedBox(height: 10),
                _buildPermissionStatusSelector(),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed: _managePermission,
                    child: const Text('Update Permission'),
                  ),
                ),
                const SizedBox(height: 30),
                
                // User List
                const Text(
                  'Users',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      return _buildUserItem(_users[index]);
                    },
                  ),
                ),
              ],
              if (_statusMessage.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _statusMessage.contains('Error')
                        ? CupertinoColors.destructiveRed
                        : CupertinoColors.activeGreen,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserSelector({bool forPermission = false}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: CupertinoColors.systemGrey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CupertinoButton(
        onPressed: () {
          _showUserSelectionDialog(forPermission: forPermission);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedUser != null ? _selectedUser!.name : 'Select User',
              style: TextStyle(
                color: _selectedUser != null 
                    ? CupertinoColors.label 
                    : CupertinoColors.systemGrey,
              ),
            ),
            const Icon(CupertinoIcons.chevron_down),
          ],
        ),
      ),
    );
  }

  void _showUserSelectionDialog({bool forPermission = false}) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Select User'),
        actions: _users.map((user) {
          return CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                if (forPermission) {
                  _selectedUser = user;
                } else {
                  _selectedUser = user;
                }
              });
            },
            child: Text(user.name),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: CupertinoColors.systemGrey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CupertinoButton(
        onPressed: () {
          _showRoleSelectionDialog();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedRole != null 
                  ? _getRoleLabel(_selectedRole!) 
                  : 'Select Role',
              style: TextStyle(
                color: _selectedRole != null 
                    ? CupertinoColors.label 
                    : CupertinoColors.systemGrey,
              ),
            ),
            const Icon(CupertinoIcons.chevron_down),
          ],
        ),
      ),
    );
  }

  void _showRoleSelectionDialog() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Select Role'),
        actions: UserRole.values.map((role) {
          return CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedRole = role;
              });
            },
            child: Text(_getRoleLabel(role)),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Widget _buildPermissionSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: CupertinoColors.systemGrey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CupertinoButton(
        onPressed: () {
          _showPermissionSelectionDialog();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedPermission != null 
                  ? _getPermissionLabel(_selectedPermission!) 
                  : 'Select Permission',
              style: TextStyle(
                color: _selectedPermission != null 
                    ? CupertinoColors.label 
                    : CupertinoColors.systemGrey,
              ),
            ),
            const Icon(CupertinoIcons.chevron_down),
          ],
        ),
      ),
    );
  }

  void _showPermissionSelectionDialog() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Select Permission'),
        actions: Permission.values.map((permission) {
          return CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedPermission = permission;
              });
            },
            child: Text(_getPermissionLabel(permission)),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Widget _buildPermissionStatusSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: CupertinoColors.systemGrey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CupertinoButton(
        onPressed: () {
          _showPermissionStatusDialog();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _permissionStatus != null 
                  ? _permissionStatus == PermissionStatus.granted 
                      ? 'Grant' 
                      : 'Deny'
                  : 'Select Status',
              style: TextStyle(
                color: _permissionStatus != null 
                    ? CupertinoColors.label 
                    : CupertinoColors.systemGrey,
              ),
            ),
            const Icon(CupertinoIcons.chevron_down),
          ],
        ),
      ),
    );
  }

  void _showPermissionStatusDialog() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Select Status'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _permissionStatus = PermissionStatus.granted;
              });
            },
            child: const Text('Grant'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _permissionStatus = PermissionStatus.denied;
              });
            },
            child: const Text('Deny'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Widget _buildUserItem(UserProfile user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user.role),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getRoleLabel(user.role),
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (user.email != null) ...[
              const SizedBox(height: 5),
              Text(
                'Email: ${user.email}',
                style: const TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
            if (user.phoneNumber != null) ...[
              const SizedBox(height: 5),
              Text(
                'Phone: ${user.phoneNumber}',
                style: const TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
            const SizedBox(height: 5),
            Text(
              'User ID: ${user.id}',
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Created: ${user.createdAt.toString().split(' ')[0]}',
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                CupertinoButton(
                  onPressed: () {
                    setState(() {
                      _selectedUser = user;
                    });
                  },
                  padding: EdgeInsets.zero,
                  child: const Text(
                    'Select',
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CupertinoButton(
                  onPressed: () => _confirmDeleteUser(user),
                  padding: EdgeInsets.zero,
                  child: const Text(
                    'Delete',
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.destructiveRed,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.child:
        return 'Child';
      case UserRole.caregiver:
        return 'Caregiver';
      case UserRole.therapist:
        return 'Therapist';
      case UserRole.administrator:
        return 'Administrator';
      default:
        return 'Unknown';
    }
  }

  String _getPermissionLabel(Permission permission) {
    return permission.toString().split('.').last.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim();
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.child:
        return CupertinoColors.activeBlue;
      case UserRole.caregiver:
        return CupertinoColors.activeGreen;
      case UserRole.therapist:
        return CupertinoColors.systemOrange;
      case UserRole.administrator:
        return CupertinoColors.destructiveRed;
      default:
        return CupertinoColors.systemGrey;
    }
  }
}