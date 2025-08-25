import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/sync_management_service.dart';
import '../services/cloud_sync_service.dart';

class SyncStatusScreen extends StatefulWidget {
  final UserProfile currentUser;

  const SyncStatusScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends State<SyncStatusScreen> {
  final SyncManagementService _syncService = SyncManagementService();
  final CloudSyncService _cloudService = CloudSyncService();
  
  bool _isLoading = false;
  String _statusMessage = '';
  List<ProfileSyncStatus> _syncStatuses = [];
  SyncSettings? _syncSettings;
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
    _loadSyncSettings();
  }

  Future<void> _loadSyncStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final statuses = await _syncService.getSyncStatusForAllProfiles();
      final lastSync = await _syncService.getLastSyncTime();
      
      if (mounted) {
        setState(() {
          _syncStatuses = statuses;
          _lastSyncTime = lastSync;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error loading sync status: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSyncSettings() async {
    try {
      final settings = await _syncService.getSyncSettings();
      
      if (mounted) {
        setState(() {
          _syncSettings = settings;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error loading sync settings: $e';
        });
      }
    }
  }

  Future<void> _performFullSync() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Syncing all profiles...';
    });

    try {
      final result = await _syncService.performFullSync();
      
      if (result.success && mounted) {
        setState(() {
          _statusMessage = 'Sync completed successfully! ${result.profilesSynced} profiles synced.';
          _isLoading = false;
        });

        // Reload sync status
        await _loadSyncStatus();
      } else if (mounted) {
        setState(() {
          _statusMessage = 'Sync failed: ${result.errorMessage}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error during sync: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _forceSyncFromCloud() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Force syncing from cloud...';
    });

    try {
      final result = await _syncService.forceSyncFromCloud();
      
      if (result.success && mounted) {
        setState(() {
          _statusMessage = 'Force sync completed! ${result.profilesSynced} profiles loaded.';
          _isLoading = false;
        });

        // Reload sync status
        await _loadSyncStatus();
      } else if (mounted) {
        setState(() {
          _statusMessage = 'Force sync failed: ${result.errorMessage}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error during force sync: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleAutoSync() async {
    if (_syncSettings == null) return;

    try {
      if (_syncSettings!.autoSyncEnabled) {
        await _syncService.disableAutoSync();
      } else {
        await _syncService.enableAutoSync();
      }

      // Reload settings
      await _loadSyncSettings();
      
      if (mounted) {
        setState(() {
          _statusMessage = 'Auto-sync ${_syncSettings!.autoSyncEnabled ? 'enabled' : 'disabled'}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error toggling auto-sync: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Sync Status'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sync Status',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              if (_lastSyncTime != null) ...[
                Text(
                  'Last sync: ${_formatDateTime(_lastSyncTime!)}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if (_syncSettings != null) ...[
                _buildSyncSettingsCard(),
                const SizedBox(height: 20),
              ],
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
                    onPressed: _performFullSync,
                    child: const Text('Sync Now'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    onPressed: _forceSyncFromCloud,
                    child: const Text('Force Sync from Cloud'),
                  ),
                ),
                const SizedBox(height: 30),
              ],
              const Text(
                'Profile Sync Status',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              if (_syncStatuses.isEmpty) ...[
                const Text(
                  'No profiles found.',
                  style: TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ] else ...[
                Expanded(
                  child: ListView.builder(
                    itemCount: _syncStatuses.length,
                    itemBuilder: (context, index) {
                      return _buildProfileSyncStatusItem(_syncStatuses[index]);
                    },
                  ),
                ),
              ],
              if (_statusMessage.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _statusMessage.contains('Error') || _statusMessage.contains('failed')
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

  Widget _buildSyncSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sync Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Auto-sync',
                  style: TextStyle(fontSize: 16),
                ),
                CupertinoSwitch(
                  value: _syncSettings!.autoSyncEnabled,
                  onChanged: (value) {
                    _toggleAutoSync();
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Frequency: every ${_syncSettings!.syncFrequency.inMinutes} minutes',
              style: const TextStyle(
                fontSize: 14,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  _syncSettings!.syncOnProfileChange
                      ? CupertinoIcons.check_mark
                      : CupertinoIcons.xmark,
                  color: _syncSettings!.syncOnProfileChange
                      ? CupertinoColors.activeGreen
                      : CupertinoColors.destructiveRed,
                  size: 16,
                ),
                const SizedBox(width: 5),
                const Text(
                  'Sync on profile change',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Icon(
                  _syncSettings!.syncOnAppLaunch
                      ? CupertinoIcons.check_mark
                      : CupertinoIcons.xmark,
                  color: _syncSettings!.syncOnProfileChange
                      ? CupertinoColors.activeGreen
                      : CupertinoColors.destructiveRed,
                  size: 16,
                ),
                const SizedBox(width: 5),
                const Text(
                  'Sync on app launch',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSyncStatusItem(ProfileSyncStatus status) {
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
                  status.profileName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusIndicator(status.syncStatus),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              'ID: ${status.profileId}',
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemGrey,
              ),
            ),
            if (status.lastSync != null) ...[
              const SizedBox(height: 5),
              Text(
                'Last sync: ${_formatDateTime(status.lastSync!)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
            const SizedBox(height: 5),
            Text(
              'Devices: ${status.syncedDevices.length}',
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(SyncStatus status) {
    Color color;
    IconData icon;

    switch (status) {
      case SyncStatus.synced:
        color = CupertinoColors.activeGreen;
        icon = CupertinoIcons.check_mark_circled;
        break;
      case SyncStatus.pending:
        color = CupertinoColors.systemOrange;
        icon = CupertinoIcons.clock;
        break;
      case SyncStatus.conflict:
        color = CupertinoColors.systemYellow;
        icon = CupertinoIcons.exclamationmark_triangle;
        break;
      case SyncStatus.error:
        color = CupertinoColors.destructiveRed;
        icon = CupertinoIcons.xmark_circle;
        break;
      case SyncStatus.disabled:
        color = CupertinoColors.systemGrey;
        icon = CupertinoIcons.pause_circle;
        break;
      default:
        color = CupertinoColors.systemGrey;
        icon = CupertinoIcons.question_circle;
    }

    return Icon(
      icon,
      color: color,
      size: 20,
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}