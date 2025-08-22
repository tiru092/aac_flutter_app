import 'package:flutter/cupertino.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../widgets/pin_input_dialog.dart';
import '../utils/aac_helper.dart';

class ProfileSelectionScreen extends StatefulWidget {
  final Function(UserProfile) onProfileSelected;

  const ProfileSelectionScreen({
    super.key,
    required this.onProfileSelected,
  });

  @override
  State<ProfileSelectionScreen> createState() => _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState extends State<ProfileSelectionScreen>
    with TickerProviderStateMixin {
  final ProfileService _profileService = ProfileService();
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    _slideController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildChildProfiles(),
                    const SizedBox(height: 24),
                    _buildCaregiverProfiles(),
                    const SizedBox(height: 24),
                    _buildCreateProfileButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.person_2_fill,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Select Profile',
            style: TextStyle(
              fontSize: 20 * AACHelper.getTextSizeMultiplier(),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                CupertinoIcons.xmark,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildProfiles() {
    final childProfiles = _profileService.getChildProfiles();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              CupertinoIcons.smiley,
              color: Color(0xFFFFE66D),
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Child Profiles',
              style: TextStyle(
                fontSize: 18 * AACHelper.getTextSizeMultiplier(),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (childProfiles.isEmpty)
          _buildEmptyProfilesMessage('No child profiles available')
        else
          ...childProfiles.map((profile) => _buildProfileCard(profile, false)),
      ],
    );
  }

  Widget _buildCaregiverProfiles() {
    final caregiverProfiles = _profileService.getCaregiverProfiles();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              CupertinoIcons.shield_fill,
              color: Color(0xFF6C63FF),
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Caregiver Profiles',
              style: TextStyle(
                fontSize: 18 * AACHelper.getTextSizeMultiplier(),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (caregiverProfiles.isEmpty)
          _buildEmptyProfilesMessage('No caregiver profiles available')
        else
          ...caregiverProfiles.map((profile) => _buildProfileCard(profile, true)),
      ],
    );
  }

  Widget _buildEmptyProfilesMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.info_circle,
            color: Colors.grey.shade400,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 14 * AACHelper.getTextSizeMultiplier(),
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(UserProfile profile, bool requiresPin) {
    final isCurrentProfile = _profileService.currentProfile?.id == profile.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCurrentProfile
              ? [const Color(0xFF51CF66), const Color(0xFF51CF66).withOpacity(0.8)]
              : profile.role == UserRole.child
                  ? [const Color(0xFFFFE66D), const Color(0xFFFFE66D).withOpacity(0.8)]
                  : [const Color(0xFF6C63FF), const Color(0xFF6C63FF).withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isCurrentProfile ? const Color(0xFF51CF66) : 
                   profile.role == UserRole.child ? const Color(0xFFFFE66D) : 
                   const Color(0xFF6C63FF)).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _selectProfile(profile, requiresPin),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: profile.avatarPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.asset(
                            profile.avatarPath!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          profile.role == UserRole.child 
                              ? CupertinoIcons.smiley_fill
                              : CupertinoIcons.shield_fill,
                          color: Colors.white,
                          size: 30,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: TextStyle(
                          fontSize: 18 * AACHelper.getTextSizeMultiplier(),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.role == UserRole.child ? 'Child Profile' : 'Caregiver Profile',
                        style: TextStyle(
                          fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      if (isCurrentProfile) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Current',
                            style: TextStyle(
                              fontSize: 12 * AACHelper.getTextSizeMultiplier(),
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (requiresPin)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      CupertinoIcons.lock_fill,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateProfileButton() {
    return GestureDetector(
      onTap: _showCreateProfileDialog,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF6C63FF).withOpacity(0.05),
        ),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                CupertinoIcons.add,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create New Profile',
              style: TextStyle(
                fontSize: 16 * AACHelper.getTextSizeMultiplier(),
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6C63FF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectProfile(UserProfile profile, bool requiresPin) async {
    if (requiresPin) {
      _showPinDialog(profile);
    } else {
      await _profileService.setCurrentProfile(profile.id);
      widget.onProfileSelected(profile);
      Navigator.pop(context);
    }
  }

  void _showPinDialog(UserProfile profile) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => PinInputDialog(
        title: 'Enter PIN',
        subtitle: 'Enter your 4-digit PIN to access caregiver mode',
        onPinEntered: (pin) async {
          final isValid = await _profileService.authenticateCaregiver(profile.id, pin);
          
          if (isValid) {
            await _profileService.setCurrentProfile(profile.id);
            widget.onProfileSelected(profile);
            Navigator.pop(context); // Close PIN dialog
            Navigator.pop(context); // Close profile selection
          } else {
            // Show error feedback
            await AACHelper.accessibleHapticFeedback();
          }
        },
        onCancel: () => Navigator.pop(context),
        showForgotPin: true,
      ),
    );
  }

  void _showCreateProfileDialog() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Create New Profile'),
        message: const Text('What type of profile would you like to create?'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _createChildProfile();
            },
            child: const Text('Child Profile'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _createCaregiverProfile();
            },
            child: const Text('Caregiver Profile (with PIN)'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _createChildProfile() async {
    final nameController = TextEditingController();
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Create Child Profile'),
        content: Column(
          children: [
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: nameController,
              placeholder: 'Enter child\'s name',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final profile = UserProfile(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  role: UserRole.child,
                  createdAt: DateTime.now(),
                  settings: ProfileSettings(),
                );
                
                await _profileService.addProfile(profile);
                setState(() {});
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _createCaregiverProfile() {
    // This would open a more detailed form for caregiver profile creation
    // including name, PIN, and optional avatar selection
    // Implementation would be similar to child profile but with PIN fields
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }
}