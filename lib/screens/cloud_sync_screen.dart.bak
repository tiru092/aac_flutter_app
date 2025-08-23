import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/cloud_sync_service.dart';
import '../utils/aac_helper.dart';

class CloudSyncScreen extends StatefulWidget {
  const CloudSyncScreen({super.key});

  @override
  State<CloudSyncScreen> createState() => _CloudSyncScreenState();
}

class _CloudSyncScreenState extends State<CloudSyncScreen>
    with TickerProviderStateMixin {
  final CloudSyncService _cloudSyncService = CloudSyncService();
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  bool _isLoading = false;
  bool _isSyncing = false;
  CloudStorageInfo? _storageInfo;
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    _loadCloudInfo();
    _slideController.forward();
  }

  void _loadCloudInfo() async {
    setState(() {
      _isLoading = true;
    });
    
    final storageInfo = await _cloudSyncService.getCloudStorageInfo();
    
    setState(() {
      _storageInfo = storageInfo;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.grey.shade50,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (_cloudSyncService.isSignedIn) ...[
                      _buildCloudStatusSection(),
                      const SizedBox(height: 24),
                      _buildSyncActionsSection(),
                      const SizedBox(height: 24),
                      _buildStorageInfoSection(),
                    ] else ...[
                      _buildSignInSection(),
                    ],
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    CupertinoIcons.back,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '☁️ Cloud Sync',
                    style: TextStyle(
                      fontSize: 20 * AACHelper.getTextSizeMultiplier(),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _cloudSyncService.isSignedIn 
                        ? 'Connected and synchronized'
                        : 'Sign in to sync your data',
                    style: TextStyle(
                      fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignInSection() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Icon(
                        CupertinoIcons.cloud,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sync Across Devices',
                      style: TextStyle(
                        fontSize: 24 * AACHelper.getTextSizeMultiplier(),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Keep your symbols, settings, and data synchronized across all your devices',
                      style: TextStyle(
                        fontSize: 16 * AACHelper.getTextSizeMultiplier(),
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildBenefitRow('🔄 Auto Sync', 'Automatically sync when connected'),
                    const SizedBox(height: 12),
                    _buildBenefitRow('📱 Multi-Device', 'Access your data on any device'),
                    const SizedBox(height: 12),
                    _buildBenefitRow('🔒 Secure', 'Your data is encrypted and protected'),
                    const SizedBox(height: 12),
                    _buildBenefitRow('💾 Backup', 'Never lose your communication data'),
                    const SizedBox(height: 24),
                    
                    CupertinoTextField(
                      controller: _emailController,
                      placeholder: 'Email address',
                      keyboardType: TextInputType.emailAddress,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(16),
                    ),
                    const SizedBox(height: 12),
                    CupertinoTextField(
                      controller: _passwordController,
                      placeholder: 'Password',
                      obscureText: true,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(16),
                    ),
                    const SizedBox(height: 24),
                    
                    Row(
                      children: [
                        Expanded(
                          child: CupertinoButton(
                            color: const Color(0xFF51CF66),
                            borderRadius: BorderRadius.circular(16),
                            onPressed: _isLoading ? null : _signIn,
                            child: _isLoading 
                                ? const CupertinoActivityIndicator(color: Colors.white)
                                : Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 16 * AACHelper.getTextSizeMultiplier(),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CupertinoButton(
                            color: const Color(0xFF6C63FF),
                            borderRadius: BorderRadius.circular(16),
                            onPressed: _isLoading ? null : _createAccount,
                            child: Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 16 * AACHelper.getTextSizeMultiplier(),
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CupertinoButton(
                      onPressed: _isLoading ? null : _signInAnonymously,
                      child: Text(
                        'Continue as Guest',
                        style: TextStyle(
                          fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitRow(String title, String description) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF6C63FF),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16 * AACHelper.getTextSizeMultiplier(),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCloudStatusSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF51CF66), Color(0xFF4ECDC4)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.checkmark_alt_circle_fill,
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
                        'Cloud Connected',
                        style: TextStyle(
                          fontSize: 20 * AACHelper.getTextSizeMultiplier(),
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        _cloudSyncService.currentUser?.email ?? 'Anonymous User',
                        style: TextStyle(
                          fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (_storageInfo?.lastSyncTime != null)
                        Text(
                          'Last sync: ${_formatSyncTime(_storageInfo!.lastSyncTime!)}',
                          style: TextStyle(
                            fontSize: 12 * AACHelper.getTextSizeMultiplier(),
                            color: const Color(0xFF51CF66),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _signOut,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      CupertinoIcons.square_arrow_right,
                      color: Colors.grey,
                      size: 20,
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

  Widget _buildSyncActionsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Synchronization',
              style: TextStyle(
                fontSize: 18 * AACHelper.getTextSizeMultiplier(),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const Divider(height: 1),
          _buildSyncActionItem(
            icon: CupertinoIcons.cloud_upload,
            title: 'Upload to Cloud',
            subtitle: 'Backup your data to the cloud',
            color: const Color(0xFF4ECDC4),
            onTap: _isSyncing ? null : () => _syncToCloud(),
          ),
          _buildSyncActionItem(
            icon: CupertinoIcons.cloud_download,
            title: 'Download from Cloud',
            subtitle: 'Restore data from the cloud',
            color: const Color(0xFF51CF66),
            onTap: _isSyncing ? null : () => _syncFromCloud(),
          ),
          _buildSyncActionItem(
            icon: CupertinoIcons.refresh,
            title: 'Auto Sync',
            subtitle: 'Sync both directions automatically',
            color: const Color(0xFF6C63FF),
            onTap: _isSyncing ? null : () => _autoSync(),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16 * AACHelper.getTextSizeMultiplier(),
            fontWeight: FontWeight.w600,
            color: onTap != null ? Colors.black87 : Colors.grey.shade400,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14 * AACHelper.getTextSizeMultiplier(),
            color: Colors.grey.shade600,
          ),
        ),
        trailing: _isSyncing 
            ? const CupertinoActivityIndicator()
            : Icon(
                CupertinoIcons.chevron_right,
                color: onTap != null ? Colors.grey : Colors.grey.shade300,
              ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildStorageInfoSection() {
    if (_storageInfo == null) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  CupertinoIcons.graph_circle,
                  color: Color(0xFF6C63FF),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Storage Usage',
                  style: TextStyle(
                    fontSize: 18 * AACHelper.getTextSizeMultiplier(),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Storage Progress Bar
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                widthFactor: _storageInfo!.usagePercentage / 100,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _storageInfo!.usagePercentage > 80
                          ? [const Color(0xFFFF6B6B), const Color(0xFFFF9F43)]
                          : [const Color(0xFF6C63FF), const Color(0xFF4ECDC4)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_storageInfo!.formattedUsedSize} used',
                  style: TextStyle(
                    fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '${_storageInfo!.formattedTotalSize} total',
                  style: TextStyle(
                    fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStorageStatItem(
                    'Symbols',
                    _storageInfo!.symbolCount.toString(),
                    CupertinoIcons.square_grid_2x2,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.shade200,
                ),
                Expanded(
                  child: _buildStorageStatItem(
                    'Profiles',
                    _storageInfo!.profileCount.toString(),
                    CupertinoIcons.person_2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF6C63FF),
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18 * AACHelper.getTextSizeMultiplier(),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12 * AACHelper.getTextSizeMultiplier(),
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  void _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorDialog('Please enter both email and password');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _cloudSyncService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      setState(() {
        _isLoading = false;
      });

      if (result.success) {
        _loadCloudInfo();
        _showSuccessDialog('Successfully signed in!');
      } else {
        _showErrorDialog(result.message);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Sign in failed: $e');
    }
  }

  void _createAccount() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorDialog('Please enter both email and password');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _cloudSyncService.createUserWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      setState(() {
        _isLoading = false;
      });

      if (result.success) {
        _loadCloudInfo();
        _showSuccessDialog('Account created successfully!');
      } else {
        _showErrorDialog(result.message);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Account creation failed: $e');
    }
  }

  void _signInAnonymously() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _cloudSyncService.signInAnonymously();

      setState(() {
        _isLoading = false;
      });

      if (result.success) {
        _loadCloudInfo();
        _showSuccessDialog('Connected as guest user!');
      } else {
        _showErrorDialog(result.message);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Guest sign in failed: $e');
    }
  }

  void _signOut() async {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out? Your local data will remain on this device.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Sign Out'),
            onPressed: () async {
              Navigator.pop(context);
              await _cloudSyncService.signOut();
              setState(() {
                _storageInfo = null;
              });
              _showSuccessDialog('Signed out successfully');
            },
          ),
        ],
      ),
    );
  }

  void _syncToCloud() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final result = await _cloudSyncService.syncToCloud();
      
      setState(() {
        _isSyncing = false;
      });

      if (result.success) {
        _loadCloudInfo();
        _showSuccessDialog('Data uploaded to cloud successfully!\n\n${result.stats?.toString() ?? ''}');
      } else {
        _showErrorDialog(result.message);
      }
    } catch (e) {
      setState(() {
        _isSyncing = false;
      });
      _showErrorDialog('Upload failed: $e');
    }
  }

  void _syncFromCloud() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final result = await _cloudSyncService.syncFromCloud();
      
      setState(() {
        _isSyncing = false;
      });

      if (result.success) {
        _showSuccessDialog('Data downloaded from cloud successfully!\n\n${result.stats?.toString() ?? ''}');
      } else {
        _showErrorDialog(result.message);
      }
    } catch (e) {
      setState(() {
        _isSyncing = false;
      });
      _showErrorDialog('Download failed: $e');
    }
  }

  void _autoSync() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      // First sync to cloud, then from cloud
      final uploadResult = await _cloudSyncService.syncToCloud();
      final downloadResult = await _cloudSyncService.syncFromCloud();
      
      setState(() {
        _isSyncing = false;
      });

      if (uploadResult.success && downloadResult.success) {
        _loadCloudInfo();
        _showSuccessDialog('Auto sync completed successfully!');
      } else {
        _showErrorDialog('Auto sync partially failed:\n${uploadResult.message}\n${downloadResult.message}');
      }
    } catch (e) {
      setState(() {
        _isSyncing = false;
      });
      _showErrorDialog('Auto sync failed: $e');
    }
  }

  void _showSuccessDialog(String message) {
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

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
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

  String _formatSyncTime(DateTime syncTime) {
    final now = DateTime.now();
    final difference = now.difference(syncTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}