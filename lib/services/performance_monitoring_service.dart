import 'dart:io';
import 'dart:developer' as developer;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_performance/firebase_performance.dart';
import '../services/crash_reporting_service.dart';

/// Custom exception for performance monitoring-related errors
class PerformanceMonitoringException implements Exception {
  final String message;
  
  PerformanceMonitoringException(this.message);
  
  @override
  String toString() => 'PerformanceMonitoringException: $message';
}

/// Service to monitor and optimize app performance
class PerformanceMonitoringService {
  static final PerformanceMonitoringService _instance = PerformanceMonitoringService._internal();
  factory PerformanceMonitoringService() => _instance;
  PerformanceMonitoringService._internal();

  // Performance metrics tracking
  final Map<String, Stopwatch> _timers = {};
  final Map<String, List<double>> _metrics = {};
  final List<MemoryInfo> _memoryHistory = [];
  final List<FrameInfo> _frameHistory = [];
  final List<NetworkInfo> _networkHistory = [];
  
  // Firebase Performance integration
  final FirebasePerformance _firebasePerformance = FirebasePerformance.instance;
  bool _isFirebasePerformanceEnabled = false;
  
  // Crash reporting service
  final CrashReportingService _crashReportingService = CrashReportingService();
  
  // Configuration
  static const int _maxHistorySize = 1000;
  static const Duration _monitoringInterval = Duration(seconds: 5);
  
  // Performance thresholds
  static const double _frameBuildTimeThreshold = 16.67; // 60 FPS target
  static const double _memoryUsageThreshold = 100 * 1024 * 1024; // 100 MB
  static const double _networkLatencyThreshold = 5000; // 5 seconds
  
  /// Initialize performance monitoring service
  Future<void> initialize() async {
    try {
      // Enable Firebase Performance monitoring in release mode
      _isFirebasePerformanceEnabled = !kDebugMode;
      await _firebasePerformance.setPerformanceCollectionEnabled(_isFirebasePerformanceEnabled);
      
      // Start periodic monitoring
      _startPeriodicMonitoring();
      
      // Register frame callback for frame timing
      SchedulerBinding.instance.addPersistentFrameCallback(_onFrameCallback);
      
      print('Performance monitoring service initialized');
    } catch (e) {
      await _crashReportingService.reportException(
        PerformanceMonitoringException('Error initializing performance monitoring: $e')
      );
      print('Error initializing performance monitoring: $e');
    }
  }

  /// Start monitoring performance
  void startMonitoring() {
    try {
      // Start periodic monitoring
      _startPeriodicMonitoring();
      
      // Register frame callback for frame timing
      SchedulerBinding.instance.addPersistentFrameCallback(_onFrameCallback);
      
      print('Performance monitoring started');
    } catch (e) {
      print('Error starting performance monitoring: $e');
    }
  }
  
  /// Stop monitoring performance
  void stopMonitoring() {
    try {
      // Stop all timers
      _timers.forEach((_, timer) => timer.stop());
      _timers.clear();
      
      // Clear history
      _memoryHistory.clear();
      _frameHistory.clear();
      _metrics.clear();
      _networkHistory.clear();
      
      print('Performance monitoring stopped');
    } catch (e) {
      print('Error stopping performance monitoring: $e');
    }
  }
  
  /// Start a performance timer
  void startTimer(String name) {
    try {
      if (_timers.containsKey(name)) {
        _timers[name]!.reset();
      } else {
        _timers[name] = Stopwatch()..start();
      }
    } catch (e) {
      print('Error starting timer $name: $e');
    }
  }
  
  /// Stop a performance timer and record the result
  double stopTimer(String name) {
    try {
      final timer = _timers[name];
      if (timer != null) {
        timer.stop();
        final elapsed = timer.elapsedMilliseconds.toDouble();
        
        // Record metric
        _recordMetric(name, elapsed);
        
        // Log if threshold exceeded
        if (name == 'frame_build' && elapsed > _frameBuildTimeThreshold) {
          developer.log('Frame build time exceeded threshold: ${elapsed}ms', 
              name: 'Performance');
        }
        
        return elapsed;
      }
      return 0.0;
    } catch (e) {
      print('Error stopping timer $name: $e');
      return 0.0;
    }
  }
  
  /// Record a custom metric
  void recordMetric(String name, double value) {
    try {
      _recordMetric(name, value);
    } catch (e) {
      print('Error recording metric $name: $e');
    }
  }
  
  /// Get average value for a metric
  double getAverageMetric(String name) {
    try {
      final values = _metrics[name];
      if (values != null && values.isNotEmpty) {
        return values.reduce((a, b) => a + b) / values.length;
      }
      return 0.0;
    } catch (e) {
      print('Error getting average metric $name: $e');
      return 0.0;
    }
  }
  
  /// Get maximum value for a metric
  double getMaxMetric(String name) {
    try {
      final values = _metrics[name];
      if (values != null && values.isNotEmpty) {
        return values.reduce((a, b) => a > b ? a : b);
      }
      return 0.0;
    } catch (e) {
      print('Error getting max metric $name: $e');
      return 0.0;
    }
  }
  
  /// Get memory information
  MemoryInfo getCurrentMemoryInfo() {
    try {
      final memoryInfo = MemoryInfo(
        timestamp: DateTime.now(),
        current: _getCurrentMemoryUsage(),
        max: _getMaxMemoryUsage(),
      );
      
      // Add to history
      _memoryHistory.add(memoryInfo);
      
      // Trim history if too large
      if (_memoryHistory.length > _maxHistorySize) {
        _memoryHistory.removeAt(0);
      }
      
      // Log if threshold exceeded
      if (memoryInfo.current > _memoryUsageThreshold) {
        developer.log('Memory usage exceeded threshold: ${memoryInfo.current} bytes', 
            name: 'Performance');
      }
      
      return memoryInfo;
    } catch (e) {
      print('Error getting memory info: $e');
      return MemoryInfo(
        timestamp: DateTime.now(),
        current: 0,
        max: 0,
      );
    }
  }
  
  /// Start monitoring a network request with Firebase Performance
  Future<HttpMetric?> startNetworkTrace(String url, String method) async {
    try {
      if (!_isFirebasePerformanceEnabled) return null;
      
      final metric = _firebasePerformance.newHttpMetric(url, HttpMethod.valueOf(method));
      await metric.start();
      return metric;
    } catch (e) {
      print('Error starting network trace: $e');
      return null;
    }
  }
  
  /// Stop monitoring a network request
  Future<void> stopNetworkTrace(HttpMetric? metric, int? responseCode, int? responseSize) async {
    try {
      if (metric == null || !_isFirebasePerformanceEnabled) return;
      
      if (responseCode != null) {
        metric.httpResponseCode = responseCode;
      }
      
      if (responseSize != null) {
        metric.responsePayloadSize = responseSize;
      }
      
      await metric.stop();
    } catch (e) {
      print('Error stopping network trace: $e');
    }
  }
  
  /// Record network information
  void recordNetworkInfo(NetworkInfo info) {
    try {
      _networkHistory.add(info);
      
      // Trim history if too large
      if (_networkHistory.length > _maxHistorySize) {
        _networkHistory.removeAt(0);
      }
      
      // Log if threshold exceeded
      if (info.latency > _networkLatencyThreshold) {
        developer.log('Network latency exceeded threshold: ${info.latency}ms', 
            name: 'Performance');
      }
    } catch (e) {
      print('Error recording network info: $e');
    }
  }
  
  /// Get performance report
  PerformanceReport generateReport() {
    try {
      final memoryInfo = getCurrentMemoryInfo();
      
      // Calculate frame statistics
      double avgFrameTime = 0.0;
      double maxFrameTime = 0.0;
      int droppedFrames = 0;
      
      if (_frameHistory.isNotEmpty) {
        final frameTimes = _frameHistory.map((f) => f.buildTime).toList();
        avgFrameTime = frameTimes.reduce((a, b) => a + b) / frameTimes.length;
        maxFrameTime = frameTimes.reduce((a, b) => a > b ? a : b);
        droppedFrames = _frameHistory
            .where((f) => f.buildTime > _frameBuildTimeThreshold)
            .length;
      }
      
      // Calculate network statistics
      double avgNetworkLatency = 0.0;
      int slowNetworkRequests = 0;
      
      if (_networkHistory.isNotEmpty) {
        final latencies = _networkHistory.map((n) => n.latency).toList();
        avgNetworkLatency = latencies.reduce((a, b) => a + b) / latencies.length;
        slowNetworkRequests = _networkHistory
            .where((n) => n.latency > _networkLatencyThreshold)
            .length;
      }
      
      return PerformanceReport(
        timestamp: DateTime.now(),
        memoryInfo: memoryInfo,
        frameStats: FrameStats(
          averageBuildTime: avgFrameTime,
          maxBuildTime: maxFrameTime,
          droppedFrames: droppedFrames,
          totalFrames: _frameHistory.length,
        ),
        networkStats: NetworkStats(
          averageLatency: avgNetworkLatency,
          slowRequests: slowNetworkRequests,
          totalRequests: _networkHistory.length,
        ),
        customMetrics: Map.from(_metrics),
      );
    } catch (e) {
      print('Error generating performance report: $e');
      return PerformanceReport(
        timestamp: DateTime.now(),
        memoryInfo: MemoryInfo(timestamp: DateTime.now(), current: 0, max: 0),
        frameStats: FrameStats(averageBuildTime: 0, maxBuildTime: 0, droppedFrames: 0, totalFrames: 0),
        networkStats: NetworkStats(averageLatency: 0, slowRequests: 0, totalRequests: 0),
        customMetrics: {},
      );
    }
  }
  
  /// Start periodic monitoring
  void _startPeriodicMonitoring() {
    try {
      // Periodically collect memory info
      Future.delayed(_monitoringInterval, () {
        if (_memoryHistory.isNotEmpty) { // Only if monitoring is active
          getCurrentMemoryInfo();
          _startPeriodicMonitoring(); // Schedule next collection
        }
      });
    } catch (e) {
      print('Error starting periodic monitoring: $e');
    }
  }
  
  /// Frame callback for timing information
  void _onFrameCallback(Duration duration) {
    try {
      final buildTime = duration.inMicroseconds / 1000.0; // Convert to milliseconds
      
      final frameInfo = FrameInfo(
        timestamp: DateTime.now(),
        buildTime: buildTime,
      );
      
      _frameHistory.add(frameInfo);
      
      // Trim history if too large
      if (_frameHistory.length > _maxHistorySize) {
        _frameHistory.removeAt(0);
      }
      
      // Record metric
      _recordMetric('frame_build_time', buildTime);
    } catch (e) {
      print('Error in frame callback: $e');
    }
  }
  
  /// Record a metric value
  void _recordMetric(String name, double value) {
    try {
      if (!_metrics.containsKey(name)) {
        _metrics[name] = [];
      }
      
      _metrics[name]!.add(value);
      
      // Trim history if too large
      if (_metrics[name]!.length > _maxHistorySize) {
        _metrics[name]!.removeAt(0);
      }
    } catch (e) {
      print('Error recording metric $name: $e');
    }
  }
  
  /// Get current memory usage
  int _getCurrentMemoryUsage() {
    try {
      // This is a simplified approach. In a real app, you might use platform channels
      // to get more accurate memory information
      return 0;
    } catch (e) {
      return 0;
    }
  }
  
  /// Get maximum memory usage
  int _getMaxMemoryUsage() {
    try {
      // This is a simplified approach. In a real app, you might use platform channels
      // to get more accurate memory information
      return 0;
    } catch (e) {
      return 0;
    }
  }
}

// Data classes for performance information

class MemoryInfo {
  final DateTime timestamp;
  final int current;
  final int max;
  
  MemoryInfo({
    required this.timestamp,
    required this.current,
    required this.max,
  });
}

class FrameInfo {
  final DateTime timestamp;
  final double buildTime;
  
  FrameInfo({
    required this.timestamp,
    required this.buildTime,
  });
}

class NetworkInfo {
  final DateTime timestamp;
  final String url;
  final String method;
  final double latency;
  final int responseCode;
  final int responseSize;
  
  NetworkInfo({
    required this.timestamp,
    required this.url,
    required this.method,
    required this.latency,
    required this.responseCode,
    required this.responseSize,
  });
}

class PerformanceReport {
  final DateTime timestamp;
  final MemoryInfo memoryInfo;
  final FrameStats frameStats;
  final NetworkStats networkStats;
  final Map<String, List<double>> customMetrics;
  
  PerformanceReport({
    required this.timestamp,
    required this.memoryInfo,
    required this.frameStats,
    required this.networkStats,
    required this.customMetrics,
  });
}

class FrameStats {
  final double averageBuildTime;
  final double maxBuildTime;
  final int droppedFrames;
  final int totalFrames;
  
  FrameStats({
    required this.averageBuildTime,
    required this.maxBuildTime,
    required this.droppedFrames,
    required this.totalFrames,
  });
}

class NetworkStats {
  final double averageLatency;
  final int slowRequests;
  final int totalRequests;
  
  NetworkStats({
    required this.averageLatency,
    required this.slowRequests,
    required this.totalRequests,
  });
}