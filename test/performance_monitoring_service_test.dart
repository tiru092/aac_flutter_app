import 'package:flutter_test/flutter_test.dart';
import 'package:aac_flutter_app/services/performance_monitoring_service.dart';

void main() {
  group('PerformanceMonitoringService Tests', () {
    late PerformanceMonitoringService performanceMonitoringService;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      performanceMonitoringService = PerformanceMonitoringService();
    });

    tearDown(() {
      // Clean up after each test
    });

    group('PerformanceMonitoringException Tests', () {
      test('should create PerformanceMonitoringException with message', () {
        final exception = PerformanceMonitoringException('Test message');
        expect(exception.message, 'Test message');
      });

      test('should convert PerformanceMonitoringException to string', () {
        final exception = PerformanceMonitoringException('Test message');
        expect(exception.toString(), 'PerformanceMonitoringException: Test message');
      });
    });

    group('Data Classes Tests', () {
      test('should create MemoryInfo with correct values', () {
        final timestamp = DateTime.now();
        final memoryInfo = MemoryInfo(
          timestamp: timestamp,
          current: 1000000,
          max: 2000000,
        );
        
        expect(memoryInfo.timestamp, timestamp);
        expect(memoryInfo.current, 1000000);
        expect(memoryInfo.max, 2000000);
      });

      test('should create FrameInfo with correct values', () {
        final timestamp = DateTime.now();
        final frameInfo = FrameInfo(
          timestamp: timestamp,
          buildTime: 16.5,
        );
        
        expect(frameInfo.timestamp, timestamp);
        expect(frameInfo.buildTime, 16.5);
      });

      test('should create NetworkInfo with correct values', () {
        final timestamp = DateTime.now();
        final networkInfo = NetworkInfo(
          timestamp: timestamp,
          url: 'https://example.com/api',
          method: 'GET',
          latency: 150.0,
          responseCode: 200,
          responseSize: 1024,
        );
        
        expect(networkInfo.timestamp, timestamp);
        expect(networkInfo.url, 'https://example.com/api');
        expect(networkInfo.method, 'GET');
        expect(networkInfo.latency, 150.0);
        expect(networkInfo.responseCode, 200);
        expect(networkInfo.responseSize, 1024);
      });

      test('should create FrameStats with correct values', () {
        final frameStats = FrameStats(
          averageBuildTime: 15.5,
          maxBuildTime: 32.0,
          droppedFrames: 5,
          totalFrames: 1000,
        );
        
        expect(frameStats.averageBuildTime, 15.5);
        expect(frameStats.maxBuildTime, 32.0);
        expect(frameStats.droppedFrames, 5);
        expect(frameStats.totalFrames, 1000);
      });

      test('should create NetworkStats with correct values', () {
        final networkStats = NetworkStats(
          averageLatency: 125.5,
          slowRequests: 3,
          totalRequests: 50,
        );
        
        expect(networkStats.averageLatency, 125.5);
        expect(networkStats.slowRequests, 3);
        expect(networkStats.totalRequests, 50);
      });

      test('should create PerformanceReport with correct values', () {
        final timestamp = DateTime.now();
        final memoryInfo = MemoryInfo(timestamp: timestamp, current: 1000000, max: 2000000);
        final frameStats = FrameStats(averageBuildTime: 15.5, maxBuildTime: 32.0, droppedFrames: 5, totalFrames: 1000);
        final networkStats = NetworkStats(averageLatency: 125.5, slowRequests: 3, totalRequests: 50);
        final customMetrics = <String, List<double>>{'test_metric': [1.0, 2.0, 3.0]};
        
        final report = PerformanceReport(
          timestamp: timestamp,
          memoryInfo: memoryInfo,
          frameStats: frameStats,
          networkStats: networkStats,
          customMetrics: customMetrics,
        );
        
        expect(report.timestamp, timestamp);
        expect(report.memoryInfo, memoryInfo);
        expect(report.frameStats, frameStats);
        expect(report.networkStats, networkStats);
        expect(report.customMetrics, customMetrics);
      });
    });

    group('Timer Tests', () {
      test('should start and stop timer', () {
        performanceMonitoringService.startTimer('test_timer');
        final elapsed = performanceMonitoringService.stopTimer('test_timer');
        
        expect(elapsed, greaterThanOrEqualTo(0));
      });

      test('should record metric', () {
        performanceMonitoringService.recordMetric('test_metric', 42.5);
        final average = performanceMonitoringService.getAverageMetric('test_metric');
        final max = performanceMonitoringService.getMaxMetric('test_metric');
        
        expect(average, 42.5);
        expect(max, 42.5);
      });
    });
  });
}