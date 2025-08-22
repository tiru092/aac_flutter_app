import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/backup_service.dart';
import '../utils/aac_helper.dart';

class BackupManagementScreen extends StatefulWidget {
  const BackupManagementScreen({super.key});

  @override
  State<BackupManagementScreen> createState() => _BackupManagementScreenState();
}

class _BackupManagementScreenState extends State<BackupManagementScreen>
    with TickerProviderStateMixin {
  final BackupService _backupService = BackupService();
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  List<BackupFile> _availableBackups = [];
  bool _isLoading = false;
  bool _isCreatingBackup = false;

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
    
    _loadAvailableBackups();
    _slideController.forward();
  }

  void _loadAvailableBackups() async {
    setState(() {
      _isLoading = true;
    });
    
    final backups = await _backupService.getAvailableBackups();
    
    setState(() {
      _availableBackups = backups;
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCreateBackupSection(),
                    const SizedBox(height: 24),
                    _buildExistingBackupsSection(),
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
                    '💾 Data Backup',
                    style: TextStyle(
                      fontSize: 20 * AACHelper.getTextSizeMultiplier(),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Backup & restore your data',
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

  Widget _buildCreateBackupSection() {
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
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF51CF66), Color(0xFF4ECDC4)],
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
                    CupertinoIcons.cloud_download,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Create New Backup',
                  style: TextStyle(
                    fontSize: 24 * AACHelper.getTextSizeMultiplier(),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Save all your symbols, settings, and data',
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
                _buildBackupInfoRow('📝 Symbols & Categories', 'All your custom communication symbols'),
                const SizedBox(height: 12),
                _buildBackupInfoRow('👥 User Profiles', 'Child and caregiver profiles with settings'),
                const SizedBox(height: 12),
                _buildBackupInfoRow('💬 Phrase History', 'Recent and favorite phrases'),
                const SizedBox(height: 12),
                _buildBackupInfoRow('🗣️ Voice Settings', 'Language and speech preferences'),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: _isCreatingBackup ? Colors.grey : const Color(0xFF51CF66),
                    borderRadius: BorderRadius.circular(16),
                    onPressed: _isCreatingBackup ? null : _createBackup,
                    child: _isCreatingBackup 
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CupertinoActivityIndicator(color: Colors.white),
                              const SizedBox(width: 12),
                              Text(
                                'Creating Backup...',
                                style: TextStyle(
                                  fontSize: 16 * AACHelper.getTextSizeMultiplier(),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                CupertinoIcons.add_circled_solid,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Create Backup Now',
                                style: TextStyle(
                                  fontSize: 16 * AACHelper.getTextSizeMultiplier(),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
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

  Widget _buildBackupInfoRow(String title, String description) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF51CF66),
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

  Widget _buildExistingBackupsSection() {
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
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.folder_fill,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Existing Backups',
                      style: TextStyle(
                        fontSize: 18 * AACHelper.getTextSizeMultiplier(),
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '${_availableBackups.length} backup(s) available',
                      style: TextStyle(
                        fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (_isLoading)
                  const CupertinoActivityIndicator()
                else
                  GestureDetector(
                    onTap: _loadAvailableBackups,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        CupertinoIcons.refresh,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_availableBackups.isEmpty)
            _buildEmptyBackupsState()
          else
            Column(
              children: _availableBackups.map((backup) => _buildBackupItem(backup)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyBackupsState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                CupertinoIcons.folder,
                size: 40,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No backups found',
              style: TextStyle(
                fontSize: 18 * AACHelper.getTextSizeMultiplier(),
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first backup to get started',
              style: TextStyle(
                fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupItem(BackupFile backup) {
    final fileSize = _formatFileSize(backup.size);
    final createdDate = _formatDate(backup.createdAt);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(
              CupertinoIcons.archivebox_fill,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  backup.fileName,
                  style: TextStyle(
                    fontSize: 16 * AACHelper.getTextSizeMultiplier(),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      createdDate,
                      style: TextStyle(
                        fontSize: 12 * AACHelper.getTextSizeMultiplier(),
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      fileSize,
                      style: TextStyle(
                        fontSize: 12 * AACHelper.getTextSizeMultiplier(),
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                if (backup.metadata != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${backup.metadata!.symbolCount} symbols • ${backup.metadata!.profileCount} profiles',
                    style: TextStyle(
                      fontSize: 12 * AACHelper.getTextSizeMultiplier(),
                      color: const Color(0xFF6C63FF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _shareBackup(backup),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ECDC4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.share,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showRestoreDialog(backup),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF51CF66),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.cloud_upload,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showDeleteDialog(backup),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.trash,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _createBackup() async {
    setState(() {
      _isCreatingBackup = true;
    });

    try {
      await AACHelper.accessibleHapticFeedback();
      
      final result = await _backupService.createFullBackup();
      
      setState(() {
        _isCreatingBackup = false;
      });

      if (result.success) {
        _showSuccessDialog('Backup Created', 
          'Your backup has been created successfully!\nFile: ${result.fileName}\nSize: ${_formatFileSize(result.size ?? 0)}');
        _loadAvailableBackups(); // Refresh the list
      } else {
        _showErrorDialog('Backup Failed', result.message);
      }
    } catch (e) {
      setState(() {
        _isCreatingBackup = false;
      });
      _showErrorDialog('Backup Error', 'An unexpected error occurred: $e');
    }
  }

  void _shareBackup(BackupFile backup) async {
    try {
      await AACHelper.accessibleHapticFeedback();
      
      final result = await _backupService.shareBackup(backup.filePath);
      
      if (!result.success) {
        _showErrorDialog('Share Failed', result.message);
      }
    } catch (e) {
      _showErrorDialog('Share Error', 'Failed to share backup: $e');
    }
  }

  void _showRestoreDialog(BackupFile backup) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Restore Backup'),
        content: Text('Do you want to restore from "${backup.fileName}"?\n\nThis will merge the backup data with your current data.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Replace All'),
            onPressed: () {
              Navigator.pop(context);
              _restoreBackup(backup, replaceAll: true);
            },
          ),
          CupertinoDialogAction(
            child: const Text('Merge'),
            onPressed: () {
              Navigator.pop(context);
              _restoreBackup(backup, replaceAll: false);
            },
          ),
        ],
      ),
    );
  }

  void _restoreBackup(BackupFile backup, {required bool replaceAll}) async {
    try {
      await AACHelper.accessibleHapticFeedback();
      
      final result = await _backupService.restoreFromBackup(backup.filePath, replaceAll: replaceAll);
      
      if (result.success) {
        _showSuccessDialog('Restore Complete', 
          'Backup restored successfully!\n${result.restoredItems?.toString() ?? 'Data has been restored.'}');
      } else {
        _showErrorDialog('Restore Failed', result.message);
      }
    } catch (e) {
      _showErrorDialog('Restore Error', 'Failed to restore backup: $e');
    }
  }

  void _showDeleteDialog(BackupFile backup) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Backup'),
        content: Text('Are you sure you want to delete "${backup.fileName}"?\n\nThis action cannot be undone.'),
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
              _deleteBackup(backup);
            },
          ),
        ],
      ),
    );
  }

  void _deleteBackup(BackupFile backup) async {
    try {
      await AACHelper.accessibleHapticFeedback();
      
      final success = await _backupService.deleteBackup(backup.filePath);
      
      if (success) {
        _loadAvailableBackups(); // Refresh the list
        _showSuccessDialog('Backup Deleted', 'The backup has been deleted successfully.');
      } else {
        _showErrorDialog('Delete Failed', 'Failed to delete the backup file.');
      }
    } catch (e) {
      _showErrorDialog('Delete Error', 'An error occurred while deleting: $e');
    }
  }

  void _showSuccessDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
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

  void _showErrorDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return '${difference.inHours}h ago';
      }
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }
}