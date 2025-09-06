import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/data_cache_service.dart';
import '../utils/aac_helper.dart';

/// Enterprise-grade data availability and caching settings screen
class DataAvailabilityScreen extends StatefulWidget {
  const DataAvailabilityScreen({super.key});

  @override
  State<DataAvailabilityScreen> createState() => _DataAvailabilityScreenState();
}

class _DataAvailabilityScreenState extends State<DataAvailabilityScreen> {
  final DataCacheService _cacheService = DataCacheService.instance;
  
  // Settings state
  bool _backgroundProcessingEnabled = true;
  bool _aggressiveCaching = false;
  int _maxCacheItems = 1000;
  
  // Cache statistics
  Map<String, dynamic> _cacheStats = {};
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadCacheStatistics();
  }

  Future<void> _loadSettings() async {
    // Load current cache preferences (would be implemented in service)
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadCacheStatistics() async {
    try {
      final stats = await _cacheService.getCacheStatistics();
      setState(() {
        _cacheStats = stats;
      });
    } catch (e) {
      debugPrint('Failed to load cache statistics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Color(0xFF4ECDC4),
        middle: Text(
          '💾 Data Availability',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      child: SafeArea(
        child: _isLoading 
            ? const Center(child: CupertinoActivityIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildCacheStatusSection(),
                  const SizedBox(height: 16),
                  _buildCacheSettingsSection(),
                  const SizedBox(height: 16),
                  _buildCacheActionsSection(),
                  const SizedBox(height: 16),
                  _buildCacheStatisticsSection(),
                  const SizedBox(height: 16),
                  _buildOfflineFeaturesSection(),
                ],
              ),
      ),
    );
  }

  Widget _buildCacheStatusSection() {
    return Container(
      decoration: BoxDecoration(
        color: AACHelper.isHighContrastEnabled ? Colors.white : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: AACHelper.isHighContrastEnabled
            ? Border.all(color: Colors.black, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.checkmark_shield_fill,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              title: Text(
                'Cache Status: Active',
                style: TextStyle(
                  fontSize: 17 * AACHelper.getTextSizeMultiplier(),
                  fontWeight: FontWeight.w600,
                  color: AACHelper.isHighContrastEnabled 
                      ? Colors.black 
                      : Colors.black87,
                ),
              ),
              subtitle: Text(
                'Intelligent pre-caching enabled for optimal offline experience',
                style: TextStyle(
                  fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                  color: AACHelper.isHighContrastEnabled 
                      ? Colors.black54 
                      : Colors.grey[600],
                ),
              ),
            ),
            if (_cacheStats.isNotEmpty) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Items Cached',
                      '${_cacheStats['itemCount'] ?? 0}',
                      CupertinoIcons.cube_box,
                    ),
                    _buildStatItem(
                      'Cache Size',
                      _cacheStats['cacheSizeFormatted'] ?? '0 B',
                      CupertinoIcons.archivebox,
                    ),
                    _buildStatItem(
                      'Hit Rate',
                      '${((_cacheStats['hitRate'] ?? 0.0) * 100).toStringAsFixed(1)}%',
                      CupertinoIcons.speedometer,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: const Color(0xFF4ECDC4),
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16 * AACHelper.getTextSizeMultiplier(),
            fontWeight: FontWeight.bold,
            color: AACHelper.isHighContrastEnabled 
                ? Colors.black 
                : Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12 * AACHelper.getTextSizeMultiplier(),
            color: AACHelper.isHighContrastEnabled 
                ? Colors.black54 
                : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCacheSettingsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AACHelper.isHighContrastEnabled ? Colors.white : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: AACHelper.isHighContrastEnabled
            ? Border.all(color: Colors.black, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            // Background Processing Toggle
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              activeColor: const Color(0xFF4ECDC4),
              title: Text(
                'Background Caching',
                style: TextStyle(
                  fontSize: 17 * AACHelper.getTextSizeMultiplier(),
                  fontWeight: FontWeight.w600,
                  color: AACHelper.isHighContrastEnabled 
                      ? Colors.black 
                      : Colors.black87,
                ),
              ),
              subtitle: Text(
                'Automatically cache frequently used items in background',
                style: TextStyle(
                  fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                  color: AACHelper.isHighContrastEnabled 
                      ? Colors.black54 
                      : Colors.grey[600],
                ),
              ),
              value: _backgroundProcessingEnabled,
              onChanged: (value) async {
                setState(() {
                  _backgroundProcessingEnabled = value;
                  _isUpdating = true;
                });
                
                try {
                  await _cacheService.setCachePreferences(
                    backgroundProcessingEnabled: value,
                  );
                  
                  if (mounted) {
                    _showSettingsConfirmation('Background caching ${value ? 'enabled' : 'disabled'}');
                  }
                } catch (e) {
                  debugPrint('Failed to update background processing: $e');
                } finally {
                  if (mounted) {
                    setState(() {
                      _isUpdating = false;
                    });
                  }
                }
              },
            ),
            const Divider(height: 1),
            // Aggressive Caching Toggle
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              activeColor: const Color(0xFF4ECDC4),
              title: Text(
                'Aggressive Pre-Caching',
                style: TextStyle(
                  fontSize: 17 * AACHelper.getTextSizeMultiplier(),
                  fontWeight: FontWeight.w600,
                  color: AACHelper.isHighContrastEnabled 
                      ? Colors.black 
                      : Colors.black87,
                ),
              ),
              subtitle: Text(
                'Cache more data for better offline performance (uses more storage)',
                style: TextStyle(
                  fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                  color: AACHelper.isHighContrastEnabled 
                      ? Colors.black54 
                      : Colors.grey[600],
                ),
              ),
              value: _aggressiveCaching,
              onChanged: (value) async {
                setState(() {
                  _aggressiveCaching = value;
                  _isUpdating = true;
                });
                
                try {
                  await _cacheService.setCachePreferences(
                    aggressiveCaching: value,
                  );
                  
                  if (mounted) {
                    _showSettingsConfirmation('Aggressive caching ${value ? 'enabled' : 'disabled'}');
                  }
                } catch (e) {
                  debugPrint('Failed to update aggressive caching: $e');
                } finally {
                  if (mounted) {
                    setState(() {
                      _isUpdating = false;
                    });
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheActionsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AACHelper.isHighContrastEnabled ? Colors.white : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: AACHelper.isHighContrastEnabled
            ? Border.all(color: Colors.black, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF4ECDC4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.refresh_bold,
                  color: Color(0xFF4ECDC4),
                  size: 24,
                ),
              ),
              title: Text(
                'Refresh Cache Now',
                style: TextStyle(
                  fontSize: 17 * AACHelper.getTextSizeMultiplier(),
                  fontWeight: FontWeight.w600,
                  color: AACHelper.isHighContrastEnabled 
                      ? Colors.black 
                      : Colors.black87,
                ),
              ),
              subtitle: Text(
                'Update cached data with latest content',
                style: TextStyle(
                  fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                  color: AACHelper.isHighContrastEnabled 
                      ? Colors.black54 
                      : Colors.grey[600],
                ),
              ),
              trailing: _isUpdating 
                  ? const CupertinoActivityIndicator()
                  : const Icon(CupertinoIcons.chevron_right, color: Colors.grey),
              onTap: _isUpdating ? null : () => _refreshCache(),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.clear_fill,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              title: Text(
                'Clear Cache',
                style: TextStyle(
                  fontSize: 17 * AACHelper.getTextSizeMultiplier(),
                  fontWeight: FontWeight.w600,
                  color: AACHelper.isHighContrastEnabled 
                      ? Colors.black 
                      : Colors.black87,
                ),
              ),
              subtitle: Text(
                'Remove all cached data (will rebuild automatically)',
                style: TextStyle(
                  fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                  color: AACHelper.isHighContrastEnabled 
                      ? Colors.black54 
                      : Colors.grey[600],
                ),
              ),
              trailing: const Icon(CupertinoIcons.chevron_right, color: Colors.grey),
              onTap: () => _showClearCacheConfirmation(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheStatisticsSection() {
    if (_cacheStats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: AACHelper.isHighContrastEnabled ? Colors.white : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: AACHelper.isHighContrastEnabled
            ? Border.all(color: Colors.black, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              CupertinoIcons.chart_bar_alt_fill,
              color: Colors.blue,
              size: 24,
            ),
          ),
          title: Text(
            'Detailed Statistics',
            style: TextStyle(
              fontSize: 17 * AACHelper.getTextSizeMultiplier(),
              fontWeight: FontWeight.w600,
              color: AACHelper.isHighContrastEnabled 
                  ? Colors.black 
                  : Colors.black87,
            ),
          ),
          subtitle: Text(
            'View detailed caching performance metrics',
            style: TextStyle(
              fontSize: 14 * AACHelper.getTextSizeMultiplier(),
              color: AACHelper.isHighContrastEnabled 
                  ? Colors.black54 
                  : Colors.grey[600],
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatRow('Memory Cache Items', '${_cacheStats['memoryItemCount'] ?? 0}'),
                  _buildStatRow('Total Accesses', '${_cacheStats['totalAccesses'] ?? 0}'),
                  _buildStatRow('Background Processing', _cacheStats['backgroundProcessingEnabled'] == true ? 'Enabled' : 'Disabled'),
                  if (_cacheStats['lastUpdate'] != null)
                    _buildStatRow('Last Update', _formatDateTime(_cacheStats['lastUpdate'])),
                  const SizedBox(height: 16),
                  const Text(
                    'Cache automatically optimizes based on your usage patterns to provide the best offline experience.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14 * AACHelper.getTextSizeMultiplier(),
              color: AACHelper.isHighContrastEnabled 
                  ? Colors.black87 
                  : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14 * AACHelper.getTextSizeMultiplier(),
              fontWeight: FontWeight.w500,
              color: AACHelper.isHighContrastEnabled 
                  ? Colors.black 
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineFeaturesSection() {
    return Container(
      decoration: BoxDecoration(
        color: AACHelper.isHighContrastEnabled ? Colors.white : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: AACHelper.isHighContrastEnabled
            ? Border.all(color: Colors.black, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.wifi_slash,
                  color: Colors.purple,
                  size: 24,
                ),
              ),
              title: Text(
                'Available Offline Features',
                style: TextStyle(
                  fontSize: 17 * AACHelper.getTextSizeMultiplier(),
                  fontWeight: FontWeight.w600,
                  color: AACHelper.isHighContrastEnabled 
                      ? Colors.black 
                      : Colors.black87,
                ),
              ),
              subtitle: Text(
                'These features work without internet connection',
                style: TextStyle(
                  fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                  color: AACHelper.isHighContrastEnabled 
                      ? Colors.black54 
                      : Colors.grey[600],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildFeatureItem('Communication Board', 'Full access to all communication items', CupertinoIcons.chat_bubble_2_fill),
                  _buildFeatureItem('Voice Synthesis', 'Text-to-speech functionality', CupertinoIcons.speaker_3_fill),
                  _buildFeatureItem('Categories & Navigation', 'Browse and organize content', CupertinoIcons.folder_fill),
                  _buildFeatureItem('Personal Settings', 'All accessibility and user preferences', CupertinoIcons.settings),
                  _buildFeatureItem('Usage Statistics', 'Track communication patterns', CupertinoIcons.chart_bar_fill),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.green,
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
                    fontSize: 15 * AACHelper.getTextSizeMultiplier(),
                    fontWeight: FontWeight.w500,
                    color: AACHelper.isHighContrastEnabled 
                        ? Colors.black 
                        : Colors.black87,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13 * AACHelper.getTextSizeMultiplier(),
                    color: AACHelper.isHighContrastEnabled 
                        ? Colors.black54 
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshCache() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      // Refresh all cache types
      await _cacheService.preCacheFrequentlyUsed();
      await _cacheService.preCacheCategories();
      await _cacheService.preCacheUserProfiles();
      
      // Reload statistics
      await _loadCacheStatistics();
      
      if (mounted) {
        _showSettingsConfirmation('Cache refreshed successfully');
      }
    } catch (e) {
      debugPrint('Failed to refresh cache: $e');
      if (mounted) {
        _showSettingsConfirmation('Failed to refresh cache');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  void _showClearCacheConfirmation() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Clear Cache'),
          content: const Text(
            'This will remove all cached data. The app will automatically rebuild the cache based on your usage. Continue?',
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Clear Cache'),
              onPressed: () async {
                Navigator.pop(context);
                await _clearCache();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearCache() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      await _cacheService.clearCache();
      await _loadCacheStatistics();
      
      if (mounted) {
        _showSettingsConfirmation('Cache cleared successfully');
      }
    } catch (e) {
      debugPrint('Failed to clear cache: $e');
      if (mounted) {
        _showSettingsConfirmation('Failed to clear cache');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  void _showSettingsConfirmation(String message) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Settings Updated'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null) return 'Unknown';
    
    try {
      final dateTime = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
