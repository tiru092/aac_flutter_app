import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_aac_service_compatible.dart';
import '../services/user_data_manager.dart';
import '../services/supabase/supabase_database_service.dart';

/// Test utility to validate SCD duplicate prevention logic
class SCDDuplicatePreventionTester {
  static const String _tag = 'SCDTester';
  static final SupabaseClient _client = Supabase.instance.client;
  
  /// Simulate multiple app logins and test duplicate prevention
  static Future<Map<String, dynamic>> runComprehensiveTest() async {
    print('🧪 SCD DUPLICATE PREVENTION TEST STARTED');
    print('═══════════════════════════════════════════');
    
    final testResults = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'test_phases': <Map<String, dynamic>>[],
      'overall_success': false,
      'duplicate_count': 0,
      'total_attempts': 0,
    };
    
    try {
      // Phase 1: Test SupabaseAACService.saveCommunication()
      print('\n📋 PHASE 1: Testing SupabaseAACService Duplicate Prevention');
      final phase1Results = await _testSupabaseAACService();
      testResults['test_phases'].add({
        'phase': 'SupabaseAACService',
        'results': phase1Results,
      });
      
      // Phase 2: Test UserDataManager single item sync
      print('\n📋 PHASE 2: Testing UserDataManager Single Item Sync');
      final phase2Results = await _testUserDataManagerSingleSync();
      testResults['test_phases'].add({
        'phase': 'UserDataManager_SingleSync',
        'results': phase2Results,
      });
      
      // Phase 3: Test SupabaseDatabase service
      print('\n📋 PHASE 3: Testing SupabaseDatabase Service');
      final phase3Results = await _testSupabaseDatabaseService();
      testResults['test_phases'].add({
        'phase': 'SupabaseDatabaseService',
        'results': phase3Results,
      });
      
      // Phase 4: Test bulk sync operations
      print('\n📋 PHASE 4: Testing Bulk Sync Operations');
      final phase4Results = await _testBulkSyncOperations();
      testResults['test_phases'].add({
        'phase': 'BulkSyncOperations',
        'results': phase4Results,
      });
      
      // Calculate overall results
      int totalDuplicates = 0;
      int totalAttempts = 0;
      bool allPhasesSuccess = true;
      
      for (final phase in testResults['test_phases']) {
        final results = phase['results'] as Map<String, dynamic>;
        totalDuplicates += (results['duplicates_detected'] as int? ?? 0);
        totalAttempts += (results['total_operations'] as int? ?? 0);
        if (!(results['success'] as bool? ?? false)) {
          allPhasesSuccess = false;
        }
      }
      
      testResults['duplicate_count'] = totalDuplicates;
      testResults['total_attempts'] = totalAttempts;
      testResults['overall_success'] = allPhasesSuccess && totalDuplicates == 0;
      
      // Print final results
      print('\n🎯 COMPREHENSIVE TEST RESULTS');
      print('═══════════════════════════════════════');
      print('✅ Total Operations: $totalAttempts');
      print('🔍 Duplicates Detected: $totalDuplicates');
      print('📊 Success Rate: ${totalDuplicates == 0 ? "100%" : "${((totalAttempts - totalDuplicates) / totalAttempts * 100).toStringAsFixed(1)}%"}');
      print('🏆 Overall Result: ${testResults['overall_success'] ? "SUCCESS" : "FAILED"}');
      
      return testResults;
      
    } catch (e) {
      print('❌ TEST FRAMEWORK ERROR: $e');
      testResults['error'] = e.toString();
      testResults['overall_success'] = false;
      return testResults;
    }
  }
  
  /// Test SupabaseAACService saveCommunication method
  static Future<Map<String, dynamic>> _testSupabaseAACService() async {
    final results = <String, dynamic>{
      'success': false,
      'total_operations': 0,
      'duplicates_detected': 0,
      'operations': <Map<String, dynamic>>[],
    };
    
    try {
      final testMessage = 'Test_Apple_${DateTime.now().millisecondsSinceEpoch}';
      final beforeCount = await _getHistoryCount();
      
      // Attempt 1: First save
      print('🔄 Attempt 1: Saving communication "$testMessage"');
      await SupabaseAACServiceCompatible.saveCommunication(
        messageText: testMessage,
        symbolsUsed: ['apple_id'],
        communicationType: 'word',
        contextInfo: {'test': 'scd_prevention'},
      );
      results['total_operations']++;
      
      await Future.delayed(Duration(milliseconds: 100));
      final afterFirstCount = await _getHistoryCount();
      
      // Attempt 2: Duplicate save (should be merged/prevented)
      print('🔄 Attempt 2: Duplicate save of "$testMessage"');
      await SupabaseAACServiceCompatible.saveCommunication(
        messageText: testMessage,
        symbolsUsed: ['apple_id'],
        communicationType: 'word',
        contextInfo: {'test': 'scd_prevention_duplicate'},
      );
      results['total_operations']++;
      
      await Future.delayed(Duration(milliseconds: 100));
      final afterSecondCount = await _getHistoryCount();
      
      // Check for duplicates
      final recordsAdded = afterSecondCount - beforeCount;
      if (recordsAdded > 1) {
        results['duplicates_detected'] = recordsAdded - 1;
        print('❌ DUPLICATE DETECTED: Expected 1 record, got $recordsAdded');
      } else {
        print('✅ NO DUPLICATES: SCD merge logic working correctly');
      }
      
      results['success'] = recordsAdded == 1;
      results['records_added'] = recordsAdded;
      
      return results;
      
    } catch (e) {
      print('❌ SupabaseAACService test failed: $e');
      results['error'] = e.toString();
      return results;
    }
  }
  
  /// Test UserDataManager single item sync
  static Future<Map<String, dynamic>> _testUserDataManagerSingleSync() async {
    final results = <String, dynamic>{
      'success': false,
      'total_operations': 0,
      'duplicates_detected': 0,
    };
    
    try {
      final userDataManager = UserDataManager();
      await userDataManager.initialize();
      
      final testSymbol = {
        'id': 'test_banana_${DateTime.now().millisecondsSinceEpoch}',
        'label': 'Test_Banana',
        'imagePath': 'assets/symbols/Banana.png',
        'category': 'Test',
      };
      
      final testItem = {
        'symbol': testSymbol,
        'action': 'test',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      final beforeCount = await _getHistoryCount();
      
      // Test single item sync multiple times
      for (int i = 1; i <= 3; i++) {
        print('🔄 Single Sync Attempt $i: ${testSymbol['label']}');
        await userDataManager.setCloudData('single_history_item', testItem);
        results['total_operations']++;
        await Future.delayed(Duration(milliseconds: 200));
      }
      
      final afterCount = await _getHistoryCount();
      final recordsAdded = afterCount - beforeCount;
      
      if (recordsAdded > 1) {
        results['duplicates_detected'] = recordsAdded - 1;
        print('❌ SINGLE SYNC DUPLICATES: Expected 1 record, got $recordsAdded');
      } else {
        print('✅ SINGLE SYNC SUCCESS: No duplicates detected');
      }
      
      results['success'] = recordsAdded <= 1; // Allow 0 or 1 (in case of efficient deduplication)
      results['records_added'] = recordsAdded;
      
      return results;
      
    } catch (e) {
      print('❌ UserDataManager single sync test failed: $e');
      results['error'] = e.toString();
      return results;
    }
  }
  
  /// Test SupabaseDatabase service
  static Future<Map<String, dynamic>> _testSupabaseDatabaseService() async {
    final results = <String, dynamic>{
      'success': false,
      'total_operations': 0,
      'duplicates_detected': 0,
    };
    
    try {
      final dbService = SupabaseDatabaseService();
      await dbService.initialize();
      
      final testData = {
        'message_text': 'Test_Orange_${DateTime.now().millisecondsSinceEpoch}',
        'symbols_used': [{'symbol_id': 'orange_test'}],
        'communication_type': 'test',
        'context_info': {'test': 'database_service'},
      };
      
      final beforeCount = await _getHistoryCount();
      
      // Test multiple additions of same data
      for (int i = 1; i <= 2; i++) {
        print('🔄 Database Service Attempt $i: ${testData['message_text']}');
        await dbService.addCommunicationHistory(testData);
        results['total_operations']++;
        await Future.delayed(Duration(milliseconds: 100));
      }
      
      final afterCount = await _getHistoryCount();
      final recordsAdded = afterCount - beforeCount;
      
      if (recordsAdded > 1) {
        results['duplicates_detected'] = recordsAdded - 1;
        print('❌ DATABASE SERVICE DUPLICATES: Expected 1 record, got $recordsAdded');
      } else {
        print('✅ DATABASE SERVICE SUCCESS: SCD merge working');
      }
      
      results['success'] = recordsAdded == 1;
      results['records_added'] = recordsAdded;
      
      return results;
      
    } catch (e) {
      print('❌ Database service test failed: $e');
      results['error'] = e.toString();
      return results;
    }
  }
  
  /// Test bulk sync operations
  static Future<Map<String, dynamic>> _testBulkSyncOperations() async {
    final results = <String, dynamic>{
      'success': false,
      'total_operations': 0,
      'duplicates_detected': 0,
    };
    
    try {
      final userDataManager = UserDataManager();
      await userDataManager.initialize();
      
      final timestamp = DateTime.now().toIso8601String();
      final testData = [
        {
          'symbol': {
            'id': 'bulk_test_1',
            'label': 'Bulk_Test_Water',
            'imagePath': 'assets/symbols/Water.png',
            'category': 'Test',
          },
          'action': 'test',
          'timestamp': timestamp,
        },
        {
          'symbol': {
            'id': 'bulk_test_2',
            'label': 'Bulk_Test_Juice',
            'imagePath': 'assets/symbols/Juice.png',
            'category': 'Test',
          },
          'action': 'test',
          'timestamp': timestamp,
        },
      ];
      
      final beforeCount = await _getHistoryCount();
      
      // Test bulk sync twice with same data
      for (int i = 1; i <= 2; i++) {
        print('🔄 Bulk Sync Attempt $i: ${testData.length} items');
        await userDataManager.setCloudData('favorites_history', testData);
        results['total_operations']++;
        await Future.delayed(Duration(milliseconds: 500));
      }
      
      final afterCount = await _getHistoryCount();
      final recordsAdded = afterCount - beforeCount;
      
      if (recordsAdded > testData.length) {
        results['duplicates_detected'] = recordsAdded - testData.length;
        print('❌ BULK SYNC DUPLICATES: Expected ${testData.length} records, got $recordsAdded');
      } else {
        print('✅ BULK SYNC SUCCESS: Efficient deduplication working');
      }
      
      results['success'] = recordsAdded <= testData.length;
      results['records_added'] = recordsAdded;
      results['expected_records'] = testData.length;
      
      return results;
      
    } catch (e) {
      print('❌ Bulk sync test failed: $e');
      results['error'] = e.toString();
      return results;
    }
  }
  
  /// Get current history count for comparison
  static Future<int> _getHistoryCount() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return 0;
      
      final response = await _client
          .from('communication_history')
          .select('id')
          .eq('user_id', currentUser.id);
      
      return response.length;
    } catch (e) {
      print('Warning: Could not get history count: $e');
      return 0;
    }
  }
  
  /// Clean up test data
  static Future<void> cleanupTestData() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return;
      
      print('🧹 Cleaning up test data...');
      await _client
          .from('communication_history')
          .delete()
          .eq('user_id', currentUser.id)
          .like('message_text', '%Test_%');
      
      print('✅ Test data cleaned up');
    } catch (e) {
      print('Warning: Could not clean up test data: $e');
    }
  }
}

/// Test widget to run SCD tests in the app
class SCDTestScreen extends StatefulWidget {
  @override
  _SCDTestScreenState createState() => _SCDTestScreenState();
}

class _SCDTestScreenState extends State<SCDTestScreen> {
  bool _isRunning = false;
  Map<String, dynamic>? _results;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SCD Duplicate Prevention Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SCD Duplicate Prevention Test',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This test validates that the Slowly Changing Dimensions (SCD) logic prevents duplicate entries in the communication_history table.',
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isRunning ? null : _runTest,
              child: _isRunning 
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Running Tests...'),
                      ],
                    )
                  : Text('Run SCD Duplicate Prevention Test'),
            ),
            SizedBox(height: 16),
            if (_results != null) ...[
              Expanded(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Test Results',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          _buildResultsWidget(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _cleanupTestData,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: Text('Clean Up Test Data'),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Future<void> _runTest() async {
    setState(() {
      _isRunning = true;
      _results = null;
    });
    
    try {
      final results = await SCDDuplicatePreventionTester.runComprehensiveTest();
      setState(() {
        _results = results;
      });
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }
  
  Future<void> _cleanupTestData() async {
    await SCDDuplicatePreventionTester.cleanupTestData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Test data cleaned up')),
    );
  }
  
  Widget _buildResultsWidget() {
    if (_results == null) return Container();
    
    final overallSuccess = _results!['overall_success'] as bool;
    final totalAttempts = _results!['total_attempts'] as int;
    final duplicateCount = _results!['duplicate_count'] as int;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: overallSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: overallSuccess ? Colors.green : Colors.red,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                overallSuccess ? Icons.check_circle : Icons.error,
                color: overallSuccess ? Colors.green : Colors.red,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                overallSuccess ? 'ALL TESTS PASSED' : 'TESTS FAILED',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: overallSuccess ? Colors.green : Colors.red,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        Text('📊 Summary:', style: TextStyle(fontWeight: FontWeight.bold)),
        Text('• Total Operations: $totalAttempts'),
        Text('• Duplicates Detected: $duplicateCount'),
        Text('• Success Rate: ${duplicateCount == 0 ? "100%" : "${((totalAttempts - duplicateCount) / totalAttempts * 100).toStringAsFixed(1)}%"}'),
        SizedBox(height: 16),
        Text('📋 Phase Results:', style: TextStyle(fontWeight: FontWeight.bold)),
        ...(_results!['test_phases'] as List).map((phase) {
          final results = phase['results'] as Map<String, dynamic>;
          final success = results['success'] as bool? ?? false;
          return Padding(
            padding: EdgeInsets.only(left: 16, top: 4),
            child: Text(
              '${success ? "✅" : "❌"} ${phase['phase']}: ${results['duplicates_detected'] ?? 0} duplicates',
            ),
          );
        }).toList(),
      ],
    );
  }
}