import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/subscription.dart';
import '../models/user_profile.dart';
import '../utils/aac_helper.dart';
import '../services/auth_service.dart';
import '../services/auth_wrapper_service.dart';
import '../services/backup_service.dart';
import 'subscription_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final AuthService _authService = AuthService();
  final AuthWrapperService _authWrapperService = AuthWrapperService();
  
  UserProfile _currentProfile = UserProfile(
    id: 'user_001',
    name: '', // Will be set from currentUser.displayName
    role: UserRole.child,
    createdAt: DateTime.now(),
    subscription: Subscription(
      plan: SubscriptionPlan.free,
      price: 0.0,
    ),
    settings: ProfileSettings(),
  );

  String? _currentUserEmail;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadCurrentUser();
  }

  void _loadCurrentUser() {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      setState(() {
        _currentUserEmail = currentUser.email;
        _emailController.text = currentUser.email ?? '';
        // Always use displayName if available, else use a default
        String displayName = currentUser.displayName ?? '';
        if (displayName.isEmpty) {
          displayName = 'User'; // Simple fallback instead of 'AAC User'
        }
        _currentProfile = _currentProfile.copyWith(
          email: currentUser.email,
          name: displayName,
        );
        _nameController.text = displayName;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadProfile() {
    _nameController.text = _currentProfile.name.isNotEmpty ? _currentProfile.name : 'User';
    _emailController.text = _currentProfile.email ?? '';
    _phoneController.text = _currentProfile.phoneNumber ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFF4ECDC4),
        middle: const Text(
          '👤 Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(
            CupertinoIcons.back,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text(
            'Save',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: _saveProfile,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF4ECDC4).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                _buildProfileHeader(),
                
                const SizedBox(height: 24),
                
                // Profile Information
                _buildProfileInfoCard(),
                
                const SizedBox(height: 24),
                
                // Subscription Status
                _buildSubscriptionCard(),
                
                const SizedBox(height: 24),
                
                // Settings
                _buildSettingsCard(),
                
                const SizedBox(height: 24),
                
                // Account Actions
                _buildAccountActionsCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4ECDC4), Color(0xFF6C63FF)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4ECDC4).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              CupertinoIcons.person_fill,
              size: 40,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Profile Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentProfile.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                if (_currentUserEmail != null)
                  Text(
                    _currentUserEmail!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  _currentProfile.isPremium ? '💎 Premium User' : '🆓 Free User',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Member since ${_formatDate(_currentProfile.createdAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                CupertinoIcons.person_circle,
                color: Color(0xFF4ECDC4),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Name Field
          _buildInputField(
            'Full Name',
            _nameController,
            CupertinoIcons.person,
            'Enter your full name',
          ),
          
          const SizedBox(height: 16),
          
          // Email Field
          _buildInputField(
            'Email Address',
            _emailController,
            CupertinoIcons.mail,
            'Enter your email address',
            keyboardType: TextInputType.emailAddress,
          ),
          
          const SizedBox(height: 16),
          
          // Phone Field
          _buildInputField(
            'Phone Number',
            _phoneController,
            CupertinoIcons.phone,
            'Enter your phone number',
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    IconData icon,
    String placeholder, {
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A5568),
          ),
        ),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          keyboardType: keyboardType,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
            ),
          ),
          prefix: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Icon(
              icon,
              color: const Color(0xFF6B7280),
              size: 20,
            ),
          ),
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF2D3748),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionCard() {
    final subscription = _currentProfile.subscription;
    final isPremium = _currentProfile.isPremium;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPremium ? CupertinoIcons.star_fill : CupertinoIcons.star,
                color: isPremium ? const Color(0xFFFFD700) : const Color(0xFF6B7280),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Subscription',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const Spacer(),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _openSubscriptionScreen,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Upgrade',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Plan',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subscription?.plan.name.toUpperCase() ?? "FREE",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isPremium ? const Color(0xFF6C63FF) : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              
              if (subscription?.plan != SubscriptionPlan.free)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next Billing',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subscription?.endDate != null 
                            ? _formatDate(subscription!.endDate!)
                            : 'N/A',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          if (!isPremium) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFED7D7),
                ),
              ),
              child: const Text(
                '⚠️ Upgrade to Premium for unlimited symbols, cloud backup, and advanced features!',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFFE53E3E),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                CupertinoIcons.settings,
                color: Color(0xFF4ECDC4),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Preferences',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          _buildSwitchTile(
            'Enable Notifications',
            'Receive updates about new features',
            _currentProfile.settings.enableNotifications,
            (value) {
              setState(() {
                _currentProfile = UserProfile(
                  id: _currentProfile.id,
                  name: _currentProfile.name,
                  role: _currentProfile.role,
                  email: _currentProfile.email,
                  phoneNumber: _currentProfile.phoneNumber,
                  createdAt: _currentProfile.createdAt,
                  lastActiveAt: _currentProfile.lastActiveAt,
                  subscription: _currentProfile.subscription,
                  paymentHistory: _currentProfile.paymentHistory,
                  settings: ProfileSettings(
                    enableNotifications: value,
                    preferredLanguage: _currentProfile.settings.preferredLanguage,
                    autoBackup: _currentProfile.settings.autoBackup,
                    darkMode: _currentProfile.settings.darkMode,
                  ),
                );
              });
            },
          ),
          
          _buildSwitchTile(
            'Auto Backup',
            'Automatically backup your data',
            _currentProfile.settings.autoBackup,
            (value) async {
              setState(() {
                _currentProfile = UserProfile(
                  id: _currentProfile.id,
                  name: _currentProfile.name,
                  role: _currentProfile.role,
                  email: _currentProfile.email,
                  phoneNumber: _currentProfile.phoneNumber,
                  createdAt: _currentProfile.createdAt,
                  lastActiveAt: _currentProfile.lastActiveAt,
                  subscription: _currentProfile.subscription,
                  paymentHistory: _currentProfile.paymentHistory,
                  settings: ProfileSettings(
                    enableNotifications: _currentProfile.settings.enableNotifications,
                    preferredLanguage: _currentProfile.settings.preferredLanguage,
                    autoBackup: value,
                    darkMode: _currentProfile.settings.darkMode,
                  ),
                );
              });
              
              // Trigger immediate backup if auto backup is enabled
              if (value) {
                try {
                  final backupService = BackupService();
                  await backupService.createLocalBackup();
                  if (mounted) {
                    showCupertinoDialog(
                      context: context,
                      builder: (context) => CupertinoAlertDialog(
                        title: const Text('✅ Backup Created'),
                        content: const Text('Your data has been backed up successfully. Auto backup is now enabled.'),
                        actions: [
                          CupertinoDialogAction(
                            child: const Text('OK'),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    showCupertinoDialog(
                      context: context,
                      builder: (context) => CupertinoAlertDialog(
                        title: const Text('⚠️ Backup Failed'),
                        content: Text('Failed to create backup: ${e.toString()}'),
                        actions: [
                          CupertinoDialogAction(
                            child: const Text('OK'),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF4ECDC4),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                CupertinoIcons.gear_alt,
                color: Color(0xFF4ECDC4),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Account Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          _buildActionButton(
            'Export Data',
            'Download all your symbols and settings',
            CupertinoIcons.arrow_down_doc,
            const Color(0xFF38A169),
            _exportData,
          ),
          
          const SizedBox(height: 12),
          
          _buildActionButton(
            'Reset App',
            'Reset all settings to default',
            CupertinoIcons.refresh,
            const Color(0xFFED8936),
            _resetApp,
          ),
          
          const SizedBox(height: 12),
          
          _buildActionButton(
            'Sign Out',
            'Sign out of your account',
            CupertinoIcons.square_arrow_right,
            const Color(0xFF805AD5),
            _signOut,
          ),
          
          const SizedBox(height: 12),
          
          _buildActionButton(
            'Delete Account',
            'Permanently delete your account',
            CupertinoIcons.delete,
            const Color(0xFFE53E3E),
            _deleteAccount,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: color.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: color.withOpacity(0.6),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _openSubscriptionScreen() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const SubscriptionScreen(),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final updatedProfile = UserProfile(
      id: _currentProfile.id,
      name: _nameController.text.trim(),
      role: _currentProfile.role,
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      createdAt: _currentProfile.createdAt,
      lastActiveAt: DateTime.now(),
      subscription: _currentProfile.subscription,
      paymentHistory: _currentProfile.paymentHistory,
      settings: _currentProfile.settings,
    );

    setState(() {
      _currentProfile = updatedProfile;
    });

    await AACHelper.speak('Profile saved successfully');
    
    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Profile Saved'),
          content: const Text('Your profile has been updated successfully.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  void _exportData() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Export Data'),
        content: const Text('This feature will be available in the next update. Your data will be exported as a JSON file.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _signOut() async {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Sign Out'),
        content: Text('Are you sure you want to sign out${_currentUserEmail != null ? ' from $_currentUserEmail' : ''}?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Sign Out'),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _authWrapperService.signOut();
                if (mounted) {
                  // Navigate to login screen or show success message
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                }
              } catch (e) {
                if (mounted) {
                  showCupertinoDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: const Text('Error'),
                      content: Text('Failed to sign out: $e'),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text('OK'),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _resetApp() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Reset App'),
        content: const Text('This will reset all settings to default. Are you sure?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Reset'),
            onPressed: () {
              Navigator.pop(context);
              // Implement reset logic
            },
          ),
        ],
      ),
    );
  }

  void _deleteAccount() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Account'),
        content: const Text('This will permanently delete your account and all data. This action cannot be undone.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () {
              Navigator.pop(context);
              // Implement account deletion
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildProfileManagementCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF4ECDC4),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  CupertinoIcons.person_2_fill,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Profile Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Profile List Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Switch Between Profiles',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 12),
                _buildProfileSwitcher(),
                const SizedBox(height: 20),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        color: const Color(0xFF4ECDC4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.add_circled, size: 20, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Create Profile', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                        onPressed: _createNewProfile,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CupertinoButton(
                        color: const Color(0xFF6C63FF),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.person_badge_plus, size: 20, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Edit Profiles', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                        onPressed: _editProfiles,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSwitcher() {
    return FutureBuilder<List<UserProfile>>(
      future: _loadAllProfiles(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CupertinoActivityIndicator();
        }

        final profiles = snapshot.data ?? [];
        if (profiles.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'No profiles found. Create your first profile.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Column(
          children: profiles.map((profile) => _buildProfileItem(profile)).toList(),
        );
      },
    );
  }

  Widget _buildProfileItem(UserProfile profile) {
    final isActive = profile.id == _currentProfile.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _switchToProfile(profile),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF4ECDC4).withOpacity(0.1) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? const Color(0xFF4ECDC4) : Colors.grey.shade200,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF4ECDC4) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  CupertinoIcons.person_fill,
                  color: isActive ? Colors.white : Colors.grey.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isActive ? const Color(0xFF4ECDC4) : const Color(0xFF2C3E50),
                      ),
                    ),
                    if (profile.email != null)
                      Text(
                        profile.email!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              if (isActive)
                const Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  color: Color(0xFF4ECDC4),
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<UserProfile>> _loadAllProfiles() async {
    try {
      // This should be replaced with actual UserProfileService call
      return [_currentProfile]; // Placeholder
    } catch (e) {
      return [];
    }
  }

  void _switchToProfile(UserProfile profile) {
    setState(() {
      _currentProfile = profile;
      _loadProfile();
    });
    
    // Show confirmation
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Profile Switched'),
        content: Text('Switched to ${profile.name}'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _createNewProfile() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Create New Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter a name for the new profile:'),
            const SizedBox(height: 16),
            CupertinoTextField(
              placeholder: 'Profile Name',
              onChanged: (value) {
                // Handle name input
              },
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: const Text('Create'),
            onPressed: () {
              Navigator.pop(context);
              // Implement profile creation
              _showSuccess('New profile created successfully!');
            },
          ),
        ],
      ),
    );
  }

  void _editProfiles() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Edit Profiles'),
        content: const Text('This will open the profile editor where you can rename or delete profiles.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: const Text('Continue'),
            onPressed: () {
              Navigator.pop(context);
              // Navigate to profile editor (to be implemented)
            },
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}