import 'package:flutter_test/flutter_test.dart';
import 'package:aac_flutter_app/services/crash_reporting_service.dart';

void main() {
  group('CrashReportingService Tests', () {
    late CrashReportingService crashReportingService;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      crashReportingService = CrashReportingService();
    });

    tearDown(() {
      // Clean up after each test
    });

    group('CrashReportingException Tests', () {
      test('should create CrashReportingException with message', () {
        final exception = CrashReportingException('Test message');
        expect(exception.message, 'Test message');
      });

      test('should convert CrashReportingException to string', () {
        final exception = CrashReportingException('Test message');
        expect(exception.toString(), 'CrashReportingException: Test message');
      });
    });

    group('LogLevel Tests', () {
      test('should have correct LogLevel values', () {
        expect(LogLevel.verbose.index, 0);
        expect(LogLevel.debug.index, 1);
        expect(LogLevel.info.index, 2);
        expect(LogLevel.warning.index, 3);
        expect(LogLevel.error.index, 4);
        expect(LogLevel.fatal.index, 5);
      });
    });

    group('ErrorInfo Tests', () {
      test('should create ErrorInfo with correct values', () {
        final exception = CrashReportingException('Test exception');
        final stackTrace = StackTrace.current;
        final timestamp = DateTime.now();
        
        final errorInfo = ErrorInfo(
          timestamp: timestamp,
          exception: exception,
          stackTrace: stackTrace,
          isFatal: true,
        );
        
        expect(errorInfo.timestamp, timestamp);
        expect(errorInfo.exception, exception);
        expect(errorInfo.stackTrace, stackTrace);
        expect(errorInfo.isFatal, true);
      });
    });
  });
}