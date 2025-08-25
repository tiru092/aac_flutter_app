import 'package:flutter_test/flutter_test.dart';
import 'package:aac_flutter_app/services/cloud_sync_service.dart';

void main() {
  group('CloudSyncService Tests', () {
    late CloudSyncService cloudSyncService;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      cloudSyncService = CloudSyncService();
    });

    tearDown(() {
      // Clean up after each test
    });

    group('CloudSyncException Tests', () {
      test('should create CloudSyncException with message and code', () {
        final exception = CloudSyncException('Test message', 'test_code');
        expect(exception.message, 'Test message');
        expect(exception.code, 'test_code');
      });

      test('should create CloudSyncException with default code', () {
        final exception = CloudSyncException('Test message');
        expect(exception.message, 'Test message');
        expect(exception.code, 'unknown');
      });

      test('should convert CloudSyncException to string', () {
        final exception = CloudSyncException('Test message', 'test_code');
        expect(exception.toString(), 'CloudSyncException: Test message (Code: test_code)');
      });
    });

    group('Data Classes Tests', () {
      test('should create SyncResult with correct values', () {
        final result = SyncResult(
          success: true,
          totalProfiles: 5,
          successfulSyncs: 4,
          failedSyncs: 1,
          duration: Duration(seconds: 10),
        );
        
        expect(result.success, true);
        expect(result.totalProfiles, 5);
        expect(result.successfulSyncs, 4);
        expect(result.failedSyncs, 1);
        expect(result.duration, Duration(seconds: 10));
      });

      test('should create SyncStatusInfo with correct values', () {
        final statusInfo = SyncStatusInfo(
          profileId: 'test_profile',
          status: SyncStatus.syncedToThisDevice,
          lastSync: DateTime.now(),
        );
        
        expect(statusInfo.profileId, 'test_profile');
        expect(statusInfo.status, SyncStatus.syncedToThisDevice);
        expect(statusInfo.lastSync, isNotNull);
      });

      test('should create DeviceSyncInfo with correct values', () {
        final deviceInfo = DeviceSyncInfo(
          deviceId: 'device_123',
          deviceName: 'Test Device',
          lastSync: DateTime.now(),
          isCurrentDevice: true,
        );
        
        expect(deviceInfo.deviceId, 'device_123');
        expect(deviceInfo.deviceName, 'Test Device');
        expect(deviceInfo.isCurrentDevice, true);
      });
    });
  });
}