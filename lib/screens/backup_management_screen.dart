import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/backup_service.dart';

class BackupManagementScreen extends StatefulWidget {
  final UserProfile currentUser;

  const BackupManagementScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<BackupManagementScreen> createState() => _BackupManagementScreenState();
}

class _BackupManagementScreenState extends State<BackupManagementScreen> {
  final BackupService _backupService = BackupService();
  
  bool _isLoading = false;
  String _statusMessage = '';
  List<BackupInfo> _backupHistory = [];
  DateTime? _lastBackupTime;

  @override
  void initState() {
    super.initState();
    _loadBackupHistory();
    _loadLastBackupTime();
  }

  Future<void> _loadBackupHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final history = await _backupService.getBackupHistory();
      
      if (mounted) {
        setState(() {
          _backupHistory = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error loading backup history: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadLastBackupTime() async {
    try {
      final lastBackup = await _backupService.getLastBackupTimestamp();
      
      if (mounted) {
        setState(() {
          _lastBackupTime = lastBackup;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error loading last backup time: $e';
        });
      }
    }
  }

  Future<void> _createLocalBackup() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Creating local backup...';
    });

    try {
      final result = await _backupService.createLocalBackup(
        backupName: 'Manual Backup ${DateTime.now().toString().split(' ')[0]}',
      );
      
      if (result.success && mounted) {
        setState(() {
          _statusMessage = 'Local backup created successfully!';
          _isLoading = false;
        });

        // Reload backup history
        await _loadBackupHistory();
        await _loadLastBackupTime();
      } else if (mounted) {
        setState(() {
          _statusMessage = 'Failed to create local backup: ${result.errorMessage}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error creating local backup: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createCloudBackup() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Creating cloud backup...';
    });

    try {
      final result = await _backupService.createCloudBackup(
        backupName: 'Cloud Backup ${DateTime.now().toString().split(' ')[0]}',
      );
      
      if (result.success && mounted) {
        setState(() {
          _statusMessage = 'Cloud backup created successfully!';
          _isLoading = false;
        });

        // Reload backup history
        await _loadBackupHistory();
        await _loadLastBackupTime();
      } else if (mounted) {
        setState(() {
          _statusMessage = 'Failed to create cloud backup: ${result.errorMessage}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error creating cloud backup: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _restoreFromBackup(BackupInfo backup) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Restoring from backup...';
    });

    try {
      final result = await _backupService.restoreFromLocalBackup(backup.filePath);
      
      if (result.success && mounted) {
        setState(() {
          _statusMessage = 'Restore completed successfully! ${result.profilesRestored} profiles restored.';
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _statusMessage = 'Restore failed: ${result.errorMessage}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error during restore: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteBackup(BackupInfo backup) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Deleting backup...';
    });

    try {
      final success = await _backupService.deleteBackup(backup.id);
      
      if (success && mounted) {
        setState(() {
          _statusMessage = 'Backup deleted successfully!';
          _isLoading = false;
        });

        // Reload backup history
        await _loadBackupHistory();
      } else if (mounted) {
        setState(() {
          _statusMessage = 'Failed to delete backup';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error deleting backup: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _exportProfiles() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Exporting profiles...';
    });

    try {
      final filePath = await _backupService.exportProfilesToJson();
      
      if (mounted) {
        setState(() {
          _statusMessage = 'Profiles exported successfully to: $filePath';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error exporting profiles: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Color(0xFF4ECDC4),
        middle: Text(
          '💾 Backup Management',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Status message
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _statusMessage.contains('Error') 
                      ? const Color(0xFFFFECEB)
                      : const Color(0xFFE6FFFA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _statusMessage.contains('Error') 
                        ? const Color(0xFFE53E3E)
                        : const Color(0xFF38A169),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _statusMessage.contains('Error') 
                          ? CupertinoIcons.exclamationmark_triangle
                          : CupertinoIcons.check_mark,
                      color: _statusMessage.contains('Error') 
                          ? const Color(0xFFE53E3E)
                          : const Color(0xFF38A169),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: const TextStyle(
                          color: Color(0xFF2D3748),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 24,
                      onPressed: () {
                        setState(() {
                          _statusMessage = '';
                        });
                      },
                      child: const Icon(
                        CupertinoIcons.clear,
                        color: Color(0xFF718096),
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Last backup info
            if (_lastBackupTime != null)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Last Backup',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Date: ${_lastBackupTime!.toString().split(' ')[0]}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4A5568),
                      ),
                    ),
                    Text(
                      'Time: ${_lastBackupTime!.toString().split(' ')[1].split('.')[0]}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4A5568),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Backup actions
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Backup Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoButton(
                          color: const Color(0xFF4ECDC4),
                          borderRadius: BorderRadius.circular(8),
                          onPressed: _isLoading ? null : _createLocalBackup,
                          child: const Text(
                            'Create Local Backup',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CupertinoButton(
                          color: const Color(0xFF6C63FF),
                          borderRadius: BorderRadius.circular(8),
                          onPressed: _isLoading ? null : _createCloudBackup,
                          child: const Text(
                            'Create Cloud Backup',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CupertinoButton(
                    color: const Color(0xFF38A169),
                    borderRadius: BorderRadius.circular(8),
                    onPressed: _isLoading ? null : _exportProfiles,
                    child: const Text(
                      'Export Profiles to JSON',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Backup history
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Backup History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _isLoading && _backupHistory.isEmpty
                          ? const Center(
                              child: CupertinoActivityIndicator(
                                radius: 16,
                                color: Color(0xFF4299E1),
                              ),
                            )
                          : _backupHistory.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No backups found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF718096),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(8),
                                  itemCount: _backupHistory.length,
                                  itemBuilder: (context, index) {
                                    final backup = _backupHistory[index];
                                    return Container(
                                      margin: const EdgeInsets.symmetric(vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                        leading: Icon(
                                          backup.isCloudBackup
                                              ? CupertinoIcons.cloud
                                              : CupertinoIcons.device_phone_portrait,
                                          color: backup.isCloudBackup
                                              ? const Color(0xFF6C63FF)
                                              : const Color(0xFF4ECDC4),
                                          size: 28,
                                        ),
                                        title: Text(
                                          backup.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF2D3748),
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Date: ${backup.createdAt.toString().split(' ')[0]}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF4A5568),
                                              ),
                                            ),
                                            Text(
                                              'Size: ${(backup.size / 1024).toStringAsFixed(1)} KB',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF4A5568),
                                              ),
                                            ),
                                            Text(
                                              backup.isEncrypted ? '🔒 Encrypted' : '🔓 Unencrypted',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: backup.isEncrypted
                                                    ? const Color(0xFF38A169)
                                                    : const Color(0xFFE53E3E),
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CupertinoButton(
                                              padding: EdgeInsets.zero,
                                              minSize: 30,
                                              onPressed: () => _restoreFromBackup(backup),
                                              child: const Icon(
                                                CupertinoIcons.arrow_down_doc,
                                                color: Color(0xFF4ECDC4),
                                                size: 20,
                                              ),
                                            ),
                                            CupertinoButton(
                                              padding: EdgeInsets.zero,
                                              minSize: 30,
                                              onPressed: () => _deleteBackup(backup),
                                              child: const Icon(
                                                CupertinoIcons.delete,
                                                color: Color(0xFFE53E3E),
                                                size: 20,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}