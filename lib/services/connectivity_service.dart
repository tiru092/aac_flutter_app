import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/aac_logger.dart';

/// Connection type enumeration
enum ConnectionType {
  wifi,
  mobile,
  ethernet,
  none,
  unknown,
}

/// Connection quality enumeration
enum ConnectionQuality {
  poor,
  fair,
  good,
  excellent,
}

/// Connectivity status data class
class ConnectivityStatus {
  final bool isOnline;
  final ConnectionType connectionType;
  final ConnectionQuality connectionQuality;
  final Duration? latency;
  final DateTime? lastConnected;
  final DateTime? lastDisconnected;
  final bool isFirebaseReachable;

  ConnectivityStatus({
    required this.isOnline,
    required this.connectionType,
    required this.connectionQuality,
    this.latency,
    this.lastConnected,
    this.lastDisconnected,
    required this.isFirebaseReachable,
  });
}

/// Enterprise-grade connectivity monitoring service
/// Provides comprehensive offline/online status tracking with visual indicators
class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  static ConnectivityService get instance => _instance;
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  // Core connectivity state
  bool _isOnline = true;
  bool _isConnectedToFirebase = false;
  bool _isInitialized = false;
  
  // Connection quality metrics
  int _connectionQuality = 100; // 0-100 scale
  Duration _lastLatency = Duration.zero;
  DateTime? _lastSuccessfulConnection;
  DateTime? _lastConnectionLoss;
  
  // Monitoring configuration
  Timer? _connectivityTimer;
  Timer? _latencyTimer;
  static const Duration _checkInterval = Duration(seconds: 30);
  static const Duration _latencyCheckInterval = Duration(minutes: 2);
  
  // Status stream
  final StreamController<ConnectivityStatus> _statusController = StreamController<ConnectivityStatus>.broadcast();
  Stream<ConnectivityStatus> get statusStream => _statusController.stream;
  
  // Statistics
  final Map<String, dynamic> _statistics = {};
  
  // Settings
  bool _indicatorVisible = true;
  bool _backgroundMonitoring = true;
  
  // Firebase endpoints for testing
  static const List<String> _testEndpoints = [
    'https://firestore.googleapis.com',
    'https://firebase.googleapis.com',
    'https://www.google.com', // Fallback endpoint
  ];
  
  // Notification settings
  bool _showNotifications = true;
  bool _enableAutoRecovery = true;
  
  // Statistics
  int _totalConnections = 0;
  int _totalDisconnections = 0;
  Duration _totalOfflineTime = Duration.zero;
  DateTime? _lastOfflineStart;
  
  // Getters for public access
  bool get isOnline => _isOnline;
  bool get isConnectedToFirebase => _isConnectedToFirebase;
  bool get isInitialized => _isInitialized;
  int get connectionQuality => _connectionQuality;
  Duration get lastLatency => _lastLatency;
  DateTime? get lastSuccessfulConnection => _lastSuccessfulConnection;
  DateTime? get lastConnectionLoss => _lastConnectionLoss;
  bool get showNotifications => _showNotifications;
  bool get enableAutoRecovery => _enableAutoRecovery;
  
  // Statistics getters
  int get totalConnections => _totalConnections;
  int get totalDisconnections => _totalDisconnections;
  Duration get totalOfflineTime => _totalOfflineTime;
  
  /// Initialize the connectivity service with enterprise-grade monitoring
  Future<void> initialize() async {
    if (_isInitialized) {
      AACLogger.info('ConnectivityService already initialized', tag: 'Connectivity');
      return;
    }

    try {
      AACLogger.info('Initializing ConnectivityService...', tag: 'Connectivity');
      
      // Load saved preferences
      await _loadPreferences();
      
      // Perform initial connectivity check
      await _performInitialCheck();
      
      // Start monitoring timers
      _startMonitoring();
      
      _isInitialized = true;
      AACLogger.info('ConnectivityService initialized successfully', tag: 'Connectivity');
      
      notifyListeners();
    } catch (e) {
      AACLogger.error('Failed to initialize ConnectivityService: $e', tag: 'Connectivity');
      // Set fallback offline state
      _isOnline = false;
      _isConnectedToFirebase = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Load user preferences for connectivity monitoring
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _showNotifications = prefs.getBool('connectivity_notifications') ?? true;
      _enableAutoRecovery = prefs.getBool('connectivity_auto_recovery') ?? true;
      _totalConnections = prefs.getInt('connectivity_total_connections') ?? 0;
      _totalDisconnections = prefs.getInt('connectivity_total_disconnections') ?? 0;
      
      // Load offline time from milliseconds
      final offlineMs = prefs.getInt('connectivity_total_offline_ms') ?? 0;
      _totalOfflineTime = Duration(milliseconds: offlineMs);
      
      AACLogger.info('Connectivity preferences loaded', tag: 'Connectivity');
    } catch (e) {
      AACLogger.error('Failed to load connectivity preferences: $e', tag: 'Connectivity');
    }
  }

  /// Save connectivity statistics and preferences
  Future<void> _saveStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('connectivity_total_connections', _totalConnections);
      await prefs.setInt('connectivity_total_disconnections', _totalDisconnections);
      await prefs.setInt('connectivity_total_offline_ms', _totalOfflineTime.inMilliseconds);
    } catch (e) {
      AACLogger.error('Failed to save connectivity statistics: $e', tag: 'Connectivity');
    }
  }

  /// Perform comprehensive initial connectivity check
  Future<void> _performInitialCheck() async {
    AACLogger.info('Performing initial connectivity check...', tag: 'Connectivity');
    
    // Check basic internet connectivity
    final hasInternet = await _checkInternetConnectivity();
    
    // Check Firebase connectivity
    final hasFirebase = await _checkFirebaseConnectivity();
    
    // Measure initial latency
    final latency = await _measureLatency();
    
    _updateConnectivityState(
      isOnline: hasInternet,
      isConnectedToFirebase: hasFirebase,
      latency: latency,
    );
    
    AACLogger.info(
      'Initial connectivity check completed - Internet: $hasInternet, Firebase: $hasFirebase, Latency: ${latency.inMilliseconds}ms',
      tag: 'Connectivity'
    );
  }

  /// Start background monitoring timers
  void _startMonitoring() {
    // Main connectivity check timer
    _connectivityTimer = Timer.periodic(_checkInterval, (_) async {
      await _performConnectivityCheck();
    });
    
    // Latency measurement timer
    _latencyTimer = Timer.periodic(_latencyCheckInterval, (_) async {
      if (_isOnline) {
        final latency = await _measureLatency();
        _lastLatency = latency;
        _updateConnectionQuality();
        notifyListeners();
      }
    });
    
    AACLogger.info('Connectivity monitoring timers started', tag: 'Connectivity');
  }

  /// Perform periodic connectivity check
  Future<void> _performConnectivityCheck() async {
    try {
      final hasInternet = await _checkInternetConnectivity();
      final hasFirebase = await _checkFirebaseConnectivity();
      final latency = await _measureLatency();
      
      _updateConnectivityState(
        isOnline: hasInternet,
        isConnectedToFirebase: hasFirebase,
        latency: latency,
      );
    } catch (e) {
      AACLogger.error('Error during connectivity check: $e', tag: 'Connectivity');
      // On error, assume offline to be safe
      _updateConnectivityState(
        isOnline: false,
        isConnectedToFirebase: false,
        latency: Duration(seconds: 30), // High latency indicates issues
      );
    }
  }

  /// Check basic internet connectivity
  Future<bool> _checkInternetConnectivity() async {
    try {
      // Try multiple endpoints for reliability
      for (final endpoint in _testEndpoints) {
        try {
          final client = HttpClient();
          client.connectionTimeout = const Duration(seconds: 10);
          final uri = Uri.parse(endpoint);
          final request = await client.getUrl(uri);
          request.followRedirects = false;
          request.persistentConnection = false;
          
          final response = await request.close();
          client.close();
          if (response.statusCode == 200 || response.statusCode == 302) {
            return true;
          }
        } catch (e) {
          // Try next endpoint
          continue;
        }
      }
      return false;
    } catch (e) {
      AACLogger.warning('Internet connectivity check failed: $e', tag: 'Connectivity');
      return false;
    }
  }

  /// Check Firebase-specific connectivity
  Future<bool> _checkFirebaseConnectivity() async {
    try {
      // Try to connect to Firestore endpoint
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 15);
      final uri = Uri.parse('https://firestore.googleapis.com');
      final request = await client.getUrl(uri);
      
      final response = await request.close();
      client.close();
      return response.statusCode == 200 || response.statusCode == 401; // 401 is expected without auth
    } catch (e) {
      AACLogger.warning('Firebase connectivity check failed: $e', tag: 'Connectivity');
      return false;
    }
  }

  /// Measure network latency
  Future<Duration> _measureLatency() async {
    if (!_isOnline) return const Duration(seconds: 30);
    
    try {
      final stopwatch = Stopwatch()..start();
      
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final uri = Uri.parse('https://www.google.com');
      final request = await client.headUrl(uri);
      
      final response = await request.close();
      stopwatch.stop();
      client.close();
      
      if (response.statusCode == 200) {
        return stopwatch.elapsed;
      }
      
      return const Duration(seconds: 10); // Default high latency
    } catch (e) {
      return const Duration(seconds: 30); // Very high latency on error
    }
  }

  /// Update connectivity state and handle transitions
  void _updateConnectivityState({
    required bool isOnline,
    required bool isConnectedToFirebase,
    required Duration latency,
  }) {
    final wasOnline = _isOnline;
    final wasConnectedToFirebase = _isConnectedToFirebase;
    
    _isOnline = isOnline;
    _isConnectedToFirebase = isConnectedToFirebase;
    _lastLatency = latency;
    
    // Handle state transitions
    if (!wasOnline && isOnline) {
      _handleConnectionRestored();
    } else if (wasOnline && !isOnline) {
      _handleConnectionLost();
    }
    
    // Update Firebase connection tracking
    if (!wasConnectedToFirebase && isConnectedToFirebase) {
      _handleFirebaseConnected();
    } else if (wasConnectedToFirebase && !isConnectedToFirebase) {
      _handleFirebaseDisconnected();
    }
    
    _updateConnectionQuality();
    notifyListeners();
  }

  /// Handle connection restored event
  void _handleConnectionRestored() {
    _lastSuccessfulConnection = DateTime.now();
    _totalConnections++;
    
    // Calculate offline duration
    if (_lastConnectionLoss != null) {
      final offlineDuration = DateTime.now().difference(_lastConnectionLoss!);
      _totalOfflineTime += offlineDuration;
    }
    
    _saveStatistics();
    
    AACLogger.info('Internet connection restored', tag: 'Connectivity');
    
    // Attempt Firebase reconnection if auto-recovery is enabled
    if (_enableAutoRecovery && !_isConnectedToFirebase) {
      _attemptFirebaseReconnection();
    }
  }

  /// Handle connection lost event
  void _handleConnectionLost() {
    _lastConnectionLoss = DateTime.now();
    _totalDisconnections++;
    _connectionQuality = 0;
    
    _saveStatistics();
    
    AACLogger.warning('Internet connection lost', tag: 'Connectivity');
  }

  /// Handle Firebase connected event
  void _handleFirebaseConnected() {
    AACLogger.info('Firebase connection established', tag: 'Connectivity');
  }

  /// Handle Firebase disconnected event
  void _handleFirebaseDisconnected() {
    AACLogger.warning('Firebase connection lost', tag: 'Connectivity');
  }

  /// Update connection quality based on latency and stability
  void _updateConnectionQuality() {
    if (!_isOnline) {
      _connectionQuality = 0;
      return;
    }
    
    // Calculate quality based on latency (lower is better)
    if (_lastLatency.inMilliseconds < 100) {
      _connectionQuality = 100; // Excellent
    } else if (_lastLatency.inMilliseconds < 300) {
      _connectionQuality = 80; // Good
    } else if (_lastLatency.inMilliseconds < 1000) {
      _connectionQuality = 60; // Fair
    } else if (_lastLatency.inMilliseconds < 3000) {
      _connectionQuality = 40; // Poor
    } else {
      _connectionQuality = 20; // Very Poor
    }
    
    // Reduce quality if Firebase is not connected
    if (!_isConnectedToFirebase) {
      _connectionQuality = (_connectionQuality * 0.8).round();
    }
  }

  /// Attempt to reconnect to Firebase
  Future<void> _attemptFirebaseReconnection() async {
    AACLogger.info('Attempting Firebase reconnection...', tag: 'Connectivity');
    
    try {
      // Give a small delay for network stabilization
      await Future.delayed(const Duration(seconds: 2));
      
      final hasFirebase = await _checkFirebaseConnectivity();
      if (hasFirebase) {
        _isConnectedToFirebase = true;
        notifyListeners();
        AACLogger.info('Firebase reconnection successful', tag: 'Connectivity');
      }
    } catch (e) {
      AACLogger.error('Firebase reconnection failed: $e', tag: 'Connectivity');
    }
  }

  /// Manual connectivity refresh
  Future<void> refreshConnectivity() async {
    AACLogger.info('Manual connectivity refresh requested', tag: 'Connectivity');
    await _performConnectivityCheck();
  }

  /// Get detailed connectivity status
  Map<String, dynamic> getDetailedStatus() {
    return {
      'isOnline': _isOnline,
      'isConnectedToFirebase': _isConnectedToFirebase,
      'connectionQuality': _connectionQuality,
      'lastLatency': _lastLatency.inMilliseconds,
      'lastSuccessfulConnection': _lastSuccessfulConnection?.toIso8601String(),
      'lastConnectionLoss': _lastConnectionLoss?.toIso8601String(),
      'totalConnections': _totalConnections,
      'totalDisconnections': _totalDisconnections,
      'totalOfflineTime': _totalOfflineTime.inMilliseconds,
      'isInitialized': _isInitialized,
    };
  }

  /// Configure notification settings
  Future<void> setNotificationSettings({
    bool? showNotifications,
    bool? enableAutoRecovery,
  }) async {
    if (showNotifications != null) {
      _showNotifications = showNotifications;
    }
    
    if (enableAutoRecovery != null) {
      _enableAutoRecovery = enableAutoRecovery;
    }
    
    // Save to preferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('connectivity_notifications', _showNotifications);
      await prefs.setBool('connectivity_auto_recovery', _enableAutoRecovery);
    } catch (e) {
      AACLogger.error('Failed to save connectivity settings: $e', tag: 'Connectivity');
    }
    
    notifyListeners();
  }

  /// Reset connectivity statistics
  Future<void> resetStatistics() async {
    _totalConnections = 0;
    _totalDisconnections = 0;
    _totalOfflineTime = Duration.zero;
    _lastSuccessfulConnection = null;
    _lastConnectionLoss = null;
    
    await _saveStatistics();
    notifyListeners();
    
    AACLogger.info('Connectivity statistics reset', tag: 'Connectivity');
  }

  /// Set indicator visibility
  Future<void> setIndicatorVisible(bool visible) async {
    _indicatorVisible = visible;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('connectivity_indicator_visible', visible);
  }

  /// Set background monitoring
  Future<void> setBackgroundMonitoring(bool enabled) async {
    _backgroundMonitoring = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('connectivity_background_monitoring', enabled);
    
    if (enabled && _connectivityTimer == null) {
      _startMonitoring();
    } else if (!enabled && _connectivityTimer != null) {
      _connectivityTimer?.cancel();
      _connectivityTimer = null;
    }
  }

  /// Get connectivity statistics
  Future<Map<String, dynamic>> getStatistics() async {
    return {
      'totalConnections': _totalConnections,
      'totalDisconnections': _totalDisconnections,
      'totalOfflineTime': _totalOfflineTime.inSeconds,
      'lastSuccessfulConnection': _lastSuccessfulConnection?.toIso8601String(),
      'lastConnectionLoss': _lastConnectionLoss?.toIso8601String(),
      'isOnline': _isOnline,
      'connectionQuality': _connectionQuality,
    };
  }

  /// Get current connectivity status
  ConnectivityStatus getCurrentStatus() {
    return ConnectivityStatus(
      isOnline: _isOnline,
      connectionType: _determineConnectionType(),
      connectionQuality: _determineConnectionQuality(),
      latency: _lastLatency,
      lastConnected: _lastSuccessfulConnection,
      lastDisconnected: _lastConnectionLoss,
      isFirebaseReachable: _isConnectedToFirebase,
    );
  }

  ConnectionType _determineConnectionType() {
    // Simplified - in a real app you'd use connectivity_plus package
    return _isOnline ? ConnectionType.wifi : ConnectionType.none;
  }

  ConnectionQuality _determineConnectionQuality() {
    if (!_isOnline) return ConnectionQuality.poor;
    if (_connectionQuality >= 80) return ConnectionQuality.excellent;
    if (_connectionQuality >= 60) return ConnectionQuality.good;
    if (_connectionQuality >= 40) return ConnectionQuality.fair;
    return ConnectionQuality.poor;
  }

  void _emitStatus() {
    _statusController.add(getCurrentStatus());
  }

  /// Dispose of resources
  @override
  void dispose() {
    _connectivityTimer?.cancel();
    _latencyTimer?.cancel();
    super.dispose();
    AACLogger.info('ConnectivityService disposed', tag: 'Connectivity');
  }
}
