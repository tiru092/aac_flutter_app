import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/profile_sharing_service.dart';

class ProfileSharingScreen extends StatefulWidget {
  final UserProfile profile;

  const ProfileSharingScreen({Key? key, required this.profile}) : super(key: key);

  @override
  State<ProfileSharingScreen> createState() => _ProfileSharingScreenState();
}

class _ProfileSharingScreenState extends State<ProfileSharingScreen> {
  final ProfileSharingService _sharingService = ProfileSharingService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  
  SharingPermission _selectedPermission = SharingPermission.view;
  bool _isLoading = false;
  String _statusMessage = '';
  List<SharedProfile> _sharedProfiles = [];

  @override
  void initState() {
    super.initState();
    _loadSharedProfiles();
  }

  Future<void> _loadSharedProfiles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sharedProfiles = await _sharingService.getSharingDetails(widget.profile.id);
      if (mounted) {
        setState(() {
          _sharedProfiles = sharedProfiles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error loading shared profiles: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _shareProfile() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter an email address';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      final success = await _sharingService.shareProfile(
        profileId: widget.profile.id,
        sharedWithEmail: _emailController.text,
        permission: _selectedPermission,
        message: _messageController.text,
      );

      if (success && mounted) {
        setState(() {
          _statusMessage = 'Profile shared successfully!';
          _emailController.clear();
          _messageController.clear();
          _isLoading = false;
        });

        // Reload shared profiles
        await _loadSharedProfiles();
      } else if (mounted) {
        setState(() {
          _statusMessage = 'Failed to share profile';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error sharing profile: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeSharedProfile(String profileId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _sharingService.removeSharedProfile(profileId);
      
      if (success && mounted) {
        setState(() {
          _statusMessage = 'Shared profile removed';
          _isLoading = false;
        });

        // Reload shared profiles
        await _loadSharedProfiles();
      } else if (mounted) {
        setState(() {
          _statusMessage = 'Failed to remove shared profile';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error removing shared profile: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Share Profile'),
        previousPageTitle: 'Back',
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Share Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Share "${widget.profile.name}" with others',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              CupertinoTextField(
                controller: _emailController,
                placeholder: 'Enter email address',
                prefix: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(CupertinoIcons.mail),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              const Text(
                'Permission Level',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ...SharingPermission.values.map((permission) {
                return CupertinoButton(
                  onPressed: () {
                    setState(() {
                      _selectedPermission = permission;
                    });
                  },
                  color: _selectedPermission == permission
                      ? CupertinoColors.activeBlue
                      : CupertinoColors.systemGrey4,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getPermissionLabel(permission),
                        style: TextStyle(
                          color: _selectedPermission == permission
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                        ),
                      ),
                      if (_selectedPermission == permission)
                        const Icon(
                          CupertinoIcons.check_mark,
                          color: CupertinoColors.white,
                        ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 20),
              CupertinoTextField(
                controller: _messageController,
                placeholder: 'Add a message (optional)',
                maxLines: 3,
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
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed: _shareProfile,
                    child: const Text('Share Profile'),
                  ),
                ),
              ],
              if (_statusMessage.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _statusMessage.contains('Error') || _statusMessage.contains('Failed')
                        ? CupertinoColors.destructiveRed
                        : CupertinoColors.activeGreen,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 30),
              const Text(
                'Shared With',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              if (_sharedProfiles.isEmpty) ...[
                const Text(
                  'This profile has not been shared with anyone yet.',
                  style: TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ] else ...[
                Expanded(
                  child: ListView.builder(
                    itemCount: _sharedProfiles.length,
                    itemBuilder: (context, index) {
                      final sharedProfile = _sharedProfiles[index];
                      return _buildSharedProfileItem(sharedProfile);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSharedProfileItem(SharedProfile sharedProfile) {
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
                  sharedProfile.sharedWithUserEmail,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                CupertinoButton(
                  onPressed: () => _removeSharedProfile(sharedProfile.profileId),
                  padding: EdgeInsets.zero,
                  child: const Icon(
                    CupertinoIcons.delete,
                    color: CupertinoColors.destructiveRed,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              'Permission: ${_getPermissionLabel(sharedProfile.permission)}',
              style: const TextStyle(
                fontSize: 14,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Shared on: ${sharedProfile.sharedAt.toString().split(' ')[0]}',
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemGrey,
              ),
            ),
            if (sharedProfile.message != null && sharedProfile.message!.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                'Message: ${sharedProfile.message}',
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getPermissionLabel(SharingPermission permission) {
    switch (permission) {
      case SharingPermission.view:
        return 'View Only';
      case SharingPermission.edit:
        return 'View & Edit';
      case SharingPermission.collaborate:
        return 'Real-time Collaboration';
      default:
        return 'View Only';
    }
  }
}