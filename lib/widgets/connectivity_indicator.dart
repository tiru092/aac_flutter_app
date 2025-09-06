import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import '../utils/aac_logger.dart';

/// Enterprise-grade connectivity indicator widget with comprehensive visual feedback
class ConnectivityIndicator extends StatefulWidget {
  final ConnectivityIndicatorStyle style;
  final bool showDetails;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  const ConnectivityIndicator({
    super.key,
    this.style = ConnectivityIndicatorStyle.minimal,
    this.showDetails = false,
    this.onTap,
    this.padding,
  });

  @override
  State<ConnectivityIndicator> createState() => _ConnectivityIndicatorState();
}

class _ConnectivityIndicatorState extends State<ConnectivityIndicator>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  
  ConnectivityService get _connectivityService => ConnectivityService();

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    // Start fade-in animation
    _fadeController.forward();
    
    // Listen to connectivity changes
    _connectivityService.addListener(_onConnectivityChanged);
    
    // Start appropriate animation based on current state
    _updateAnimations();
  }

  @override
  void dispose() {
    _connectivityService.removeListener(_onConnectivityChanged);
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onConnectivityChanged() {
    if (mounted) {
      setState(() {
        _updateAnimations();
      });
    }
  }

  void _updateAnimations() {
    if (!_connectivityService.isOnline) {
      // Pulse when offline to draw attention
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _fadeAnimation]),
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: _buildIndicator(),
          ),
        );
      },
    );
  }

  Widget _buildIndicator() {
    switch (widget.style) {
      case ConnectivityIndicatorStyle.minimal:
        return _buildMinimalIndicator();
      case ConnectivityIndicatorStyle.detailed:
        return _buildDetailedIndicator();
      case ConnectivityIndicatorStyle.banner:
        return _buildBannerIndicator();
      case ConnectivityIndicatorStyle.badge:
        return _buildBadgeIndicator();
    }
  }

  Widget _buildMinimalIndicator() {
    final isOnline = _connectivityService.isOnline;
    final quality = _connectivityService.connectionQuality;
    
    return GestureDetector(
      onTap: widget.onTap ?? _showConnectivityDetails,
      child: Container(
        padding: widget.padding ?? const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _getStatusColor(isOnline, quality).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _getStatusColor(isOnline, quality),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getStatusIcon(isOnline, quality),
              color: _getStatusColor(isOnline, quality),
              size: 16,
            ),
            if (widget.showDetails) ...[
              const SizedBox(width: 6),
              Text(
                _getStatusText(isOnline, quality),
                style: TextStyle(
                  color: _getStatusColor(isOnline, quality),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedIndicator() {
    final isOnline = _connectivityService.isOnline;
    final isFirebaseConnected = _connectivityService.isConnectedToFirebase;
    final quality = _connectivityService.connectionQuality;
    final latency = _connectivityService.lastLatency;
    
    return GestureDetector(
      onTap: widget.onTap ?? _showConnectivityDetails,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getStatusColor(isOnline, quality),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _getStatusColor(isOnline, quality).withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStatusIcon(isOnline, quality),
                  color: _getStatusColor(isOnline, quality),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _getStatusText(isOnline, quality),
                  style: TextStyle(
                    color: _getStatusColor(isOnline, quality),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildConnectionQualityBar(quality),
                const SizedBox(width: 8),
                Text(
                  '${latency.inMilliseconds}ms',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            if (isOnline && !isFirebaseConnected) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.exclamationmark_triangle,
                    color: Colors.orange,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Cloud sync unavailable',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBannerIndicator() {
    final isOnline = _connectivityService.isOnline;
    final quality = _connectivityService.connectionQuality;
    
    if (isOnline && quality > 50) {
      return const SizedBox.shrink(); // Hide banner when connection is good
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getStatusColor(isOnline, quality),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(isOnline, quality),
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getStatusText(isOnline, quality),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getStatusDescription(isOnline, quality),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (widget.onTap != null || !isOnline)
            IconButton(
              onPressed: widget.onTap ?? _showConnectivityDetails,
              icon: Icon(
                isOnline ? CupertinoIcons.info : CupertinoIcons.arrow_counterclockwise,
                color: Colors.white,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBadgeIndicator() {
    final isOnline = _connectivityService.isOnline;
    final quality = _connectivityService.connectionQuality;
    
    return GestureDetector(
      onTap: widget.onTap ?? _showConnectivityDetails,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: _getStatusColor(isOnline, quality),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionQualityBar(int quality) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        final isActive = quality > (index + 1) * 25;
        return Container(
          width: 3,
          height: 8 + (index * 2),
          margin: const EdgeInsets.only(right: 1),
          decoration: BoxDecoration(
            color: isActive
                ? _getQualityColor(quality)
                : Colors.grey[300],
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }

  Color _getStatusColor(bool isOnline, int quality) {
    if (!isOnline) return Colors.red[600]!;
    
    if (quality >= 80) return Colors.green[600]!;
    if (quality >= 60) return Colors.blue[600]!;
    if (quality >= 40) return Colors.orange[600]!;
    return Colors.red[600]!;
  }

  Color _getQualityColor(int quality) {
    if (quality >= 80) return Colors.green;
    if (quality >= 60) return Colors.blue;
    if (quality >= 40) return Colors.orange;
    return Colors.red;
  }

  IconData _getStatusIcon(bool isOnline, int quality) {
    if (!isOnline) return CupertinoIcons.wifi_slash;
    
    if (quality >= 80) return CupertinoIcons.wifi;
    if (quality >= 60) return CupertinoIcons.wifi;
    if (quality >= 40) return CupertinoIcons.exclamationmark_triangle;
    return CupertinoIcons.wifi_slash;
  }

  String _getStatusText(bool isOnline, int quality) {
    if (!isOnline) return 'Offline';
    
    if (quality >= 80) return 'Excellent';
    if (quality >= 60) return 'Good';
    if (quality >= 40) return 'Fair';
    return 'Poor';
  }

  String _getStatusDescription(bool isOnline, int quality) {
    if (!isOnline) {
      return 'Working offline. Some features may be limited.';
    }
    
    if (quality >= 80) return 'All features available';
    if (quality >= 60) return 'Good connection quality';
    if (quality >= 40) return 'Some features may be slower';
    return 'Limited functionality due to poor connection';
  }

  void _showConnectivityDetails() {
    final status = _connectivityService.getDetailedStatus();
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => ConnectivityDetailsDialog(status: status),
    );
  }
}

/// Different styles for the connectivity indicator
enum ConnectivityIndicatorStyle {
  minimal,   // Small icon with optional text
  detailed,  // Full information card
  banner,    // Full-width notification banner
  badge,     // Simple colored dot
}

/// Detailed connectivity status dialog
class ConnectivityDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> status;

  const ConnectivityDetailsDialog({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoActionSheet(
      title: const Text(
        'Connection Status',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      message: Column(
        children: [
          _buildStatusRow('Internet Connection', status['isOnline'] ? 'Connected' : 'Offline'),
          _buildStatusRow('Cloud Sync', status['isConnectedToFirebase'] ? 'Available' : 'Unavailable'),
          _buildStatusRow('Connection Quality', '${status['connectionQuality']}%'),
          _buildStatusRow('Latency', '${status['lastLatency']}ms'),
          if (status['lastSuccessfulConnection'] != null)
            _buildStatusRow('Last Connected', _formatDateTime(status['lastSuccessfulConnection'])),
          if (status['totalConnections'] > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Statistics',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            _buildStatusRow('Total Connections', '${status['totalConnections']}'),
            _buildStatusRow('Total Disconnections', '${status['totalDisconnections']}'),
            _buildStatusRow('Total Offline Time', _formatDuration(status['totalOfflineTime'])),
          ],
        ],
      ),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () async {
            Navigator.pop(context);
            await ConnectivityService().refreshConnectivity();
          },
          child: const Text('Refresh Connection'),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(context),
        child: const Text('Close'),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null) return 'Never';
    
    try {
      final dateTime = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      return '${difference.inDays}d ago';
    } catch (e) {
      return 'Unknown';
    }
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}

/// Overlay widget that shows connectivity status across the entire app
class ConnectivityOverlay extends StatefulWidget {
  final Widget child;
  final bool enableBanner;
  final bool enableStatusIndicator;

  const ConnectivityOverlay({
    super.key,
    required this.child,
    this.enableBanner = true,
    this.enableStatusIndicator = true,
  });

  @override
  State<ConnectivityOverlay> createState() => _ConnectivityOverlayState();
}

class _ConnectivityOverlayState extends State<ConnectivityOverlay> {
  ConnectivityService get _connectivityService => ConnectivityService();
  bool _showBanner = false;

  @override
  void initState() {
    super.initState();
    _connectivityService.addListener(_onConnectivityChanged);
    _updateBannerVisibility();
  }

  @override
  void dispose() {
    _connectivityService.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  void _onConnectivityChanged() {
    if (mounted) {
      setState(() {
        _updateBannerVisibility();
      });
    }
  }

  void _updateBannerVisibility() {
    // Show banner when offline or poor connection
    _showBanner = widget.enableBanner && 
                 (!_connectivityService.isOnline || 
                  _connectivityService.connectionQuality < 50);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        
        // Top banner for connectivity issues
        if (_showBanner)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: ConnectivityIndicator(
                style: ConnectivityIndicatorStyle.banner,
              ),
            ),
          ),
        
        // Status indicator in top-right corner
        if (widget.enableStatusIndicator)
          Positioned(
            top: 50,
            right: 16,
            child: SafeArea(
              child: ConnectivityIndicator(
                style: ConnectivityIndicatorStyle.minimal,
                showDetails: false,
              ),
            ),
          ),
      ],
    );
  }
}
