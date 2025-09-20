import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/symbol.dart';
import '../utils/aac_logger.dart';
import 'user_data_manager.dart';
import 'shared_resource_service.dart';
import 'symbols_migration_service.dart';

/// Service for managing custom symbols with bidirectional Hive-Firebase sync
/// Ensures custom symbols persist across sign-out/sign-in cycles
/// Architecture: Hive first (fast), Firebase background sync (newest data wins)
class CustomSymbolsService {
  static const String _customSymbolsKey = 'custom_symbols';
  
  UserDataManager? _userDataManager;
  String? _currentUid;
  bool _isInitialized = false;
  
  List<Symbol> _customSymbols = [];
  final StreamController<List<Symbol>> _symbolsController = StreamController<List<Symbol>>.broadcast();

  /// Stream of custom symbols updates
  Stream<List<Symbol>> get symbolsStream => _symbolsController.stream;
  
  /// Current list of custom symbols
  List<Symbol> get customSymbols => List.unmodifiable(_customSymbols);
  
  bool get isInitialized => _isInitialized;

  /// Initialize with Firebase UID and UserDataManager
  Future<void> initializeWithUid(String uid, UserDataManager userDataManager) async {
    if (_isInitialized && _currentUid == uid) {
      AACLogger.info('🔥 CustomSymbolsService: Already initialized for UID: $_currentUid', tag: 'CustomSymbolsService');
      return;
    }

    // CRITICAL FIX: Validate UID matches current Firebase user
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid != uid) {
      throw Exception('CustomSymbolsService: UID mismatch! Expected: ${currentUser?.uid}, Got: $uid');
    }

    try {
      AACLogger.info('🔥⚡ CustomSymbolsService: STARTING INITIALIZATION with UID: $uid', tag: 'CustomSymbolsService');
      
      // Reset any previous state
      _customSymbols.clear();
      _currentUid = uid;
      _userDataManager = userDataManager;

      AACLogger.info('🔥🔄 CustomSymbolsService: About to call _loadCustomSymbols()...', tag: 'CustomSymbolsService');
      await _loadCustomSymbols();

      _isInitialized = true;
      AACLogger.info('🔥✅ CustomSymbolsService: INITIALIZATION COMPLETED for UID: $uid with ${_customSymbols.length} symbols', tag: 'CustomSymbolsService');
    } catch (e, stacktrace) {
      AACLogger.error('🔥❌ CustomSymbolsService: Initialization failed: $e', stackTrace: stacktrace, tag: 'CustomSymbolsService');
      _customSymbols = [];
      _symbolsController.add(_customSymbols);
      _isInitialized = true; // Initialize to prevent crashes, but with empty data.
    }
  }

  /// Load custom symbols from storage - prioritize Hive first, then sync with Firebase
  Future<void> _loadCustomSymbols() async {
    AACLogger.info('🔥🚀 CustomSymbolsService: _loadCustomSymbols() method STARTED for UID: $_currentUid', tag: 'CustomSymbolsService');
    List<Symbol> hiveSymbols = [];
    List<Symbol> firebaseSymbols = [];
    bool hiveDataExists = false;
    
    try {
      // STEP 0: Check for and perform migration if needed
      AACLogger.info('🔥🔄 CustomSymbolsService: Starting migration check for UID: $_currentUid', tag: 'CustomSymbolsService');
      
      try {
        final needsMigration = await SymbolsMigrationService.needsMigration(_currentUid!);
        AACLogger.info('🔥🔄 CustomSymbolsService: Migration check result: $needsMigration', tag: 'CustomSymbolsService');
        
        if (needsMigration) {
          AACLogger.info('🔥🔄 CustomSymbolsService: Migration needed - migrating symbols from old path...', tag: 'CustomSymbolsService');
          final migrationSuccess = await SymbolsMigrationService.migrateUserSymbols(_currentUid!);
          
          if (migrationSuccess) {
            AACLogger.info('🔥✅ CustomSymbolsService: Symbols migration completed successfully', tag: 'CustomSymbolsService');
          } else {
            AACLogger.warning('🔥⚠️ CustomSymbolsService: Symbols migration failed, continuing with available data', tag: 'CustomSymbolsService');
          }
        } else {
          AACLogger.info('🔥✅ CustomSymbolsService: No migration needed', tag: 'CustomSymbolsService');
        }
      } catch (migrationError) {
        AACLogger.error('🔥❌ CustomSymbolsService: Migration check/execution failed: $migrationError', tag: 'CustomSymbolsService');
        // Continue with normal loading process
      }
      
      // STEP 1: Always load from local Hive storage first (faster, works offline)
      AACLogger.info('CustomSymbolsService: Loading symbols from local Hive storage...', tag: 'CustomSymbolsService');
      final localBox = await _userDataManager!.getCustomSymbolsBox();
      final localData = localBox.get(_customSymbolsKey);
      
      if (localData != null && localData is List && localData.isNotEmpty) {
        try {
          hiveSymbols = localData.map((data) => Symbol.fromJson(Map<String, dynamic>.from(data))).toList();
          hiveDataExists = true;
          AACLogger.info('CustomSymbolsService: Found ${hiveSymbols.length} symbols in local Hive storage.', tag: 'CustomSymbolsService');
        } catch (parseError) {
          AACLogger.error('CustomSymbolsService: Error parsing Hive data (corrupted?): $parseError - Clearing corrupted data', tag: 'CustomSymbolsService');
          // Clear corrupted data
          await localBox.delete(_customSymbolsKey);
          hiveSymbols = [];
          hiveDataExists = false;
        }
      } else {
        AACLogger.info('CustomSymbolsService: No local data found in Hive.', tag: 'CustomSymbolsService');
      }
      
      // STEP 2: Try to load from Firebase (for validation/sync)
      try {
        AACLogger.info('CustomSymbolsService: Loading from Firebase for sync validation...', tag: 'CustomSymbolsService');
        firebaseSymbols = await SharedResourceService.getUserCustomSymbols(_currentUid!);
        AACLogger.info('CustomSymbolsService: Found ${firebaseSymbols.length} symbols in Firebase.', tag: 'CustomSymbolsService');
      } catch (firebaseError) {
        AACLogger.warning('CustomSymbolsService: Firebase load failed: $firebaseError', tag: 'CustomSymbolsService');
        // Continue with Hive data only
      }
      
      // STEP 3: Determine final data source with clear priority
      if (hiveDataExists && hiveSymbols.isNotEmpty) {
        // PRIORITY: Use Hive data (local data has highest priority)
        _customSymbols = hiveSymbols;
        AACLogger.info('CustomSymbolsService: ✅ Using Hive data (${_customSymbols.length} symbols) - Local data takes priority', tag: 'CustomSymbolsService');
        
        // Background sync: if Firebase has data, check for any new items
        if (firebaseSymbols.isNotEmpty) {
          // Run background sync asynchronously to not block UI
          _performBackgroundSync(firebaseSymbols);
        }
      } else if (firebaseSymbols.isNotEmpty) {
        // FALLBACK: Use Firebase data if no local data exists
        _customSymbols = firebaseSymbols;
        await _saveToLocal(); // Cache Firebase data locally
        AACLogger.info('CustomSymbolsService: ✅ Using Firebase data (${_customSymbols.length} symbols) - No local data, downloading from cloud', tag: 'CustomSymbolsService');
      } else {
        // FALLBACK: No data anywhere, start fresh
        _customSymbols = [];
        AACLogger.info('CustomSymbolsService: ✅ Starting fresh - No data found in Hive or Firebase', tag: 'CustomSymbolsService');
      }
      
      // STEP 4: Update UI with loaded data
      _symbolsController.add(_customSymbols);
      AACLogger.info('CustomSymbolsService: ✅ Data loading completed - ${_customSymbols.length} symbols available', tag: 'CustomSymbolsService');
      
    } catch (e, stackTrace) {
      AACLogger.error('CustomSymbolsService: Error loading symbols: $e', stackTrace: stackTrace, tag: 'CustomSymbolsService');
      _customSymbols = []; // Fallback to empty list
      _symbolsController.add(_customSymbols);
    }
  }

  /// Perform background sync to merge any new Firebase data with local Hive data
  /// IMPROVED: Better conflict resolution for timestamp-based updates
  Future<void> _performBackgroundSync(List<Symbol> firebaseSymbols) async {
    try {
      bool hasChanges = false;
      
      // Check if Firebase has any symbols not in local storage
      for (final fbSymbol in firebaseSymbols) {
        final localSymbol = _customSymbols.firstWhere((local) => local.id == fbSymbol.id, 
          orElse: () => Symbol(label: '', imagePath: ''));
        
        if (localSymbol.label.isEmpty) {
          // New symbol from Firebase - add it
          _customSymbols.add(fbSymbol);
          hasChanges = true;
          AACLogger.info('CustomSymbolsService: Background sync - Added new symbol from Firebase: ${fbSymbol.label}', tag: 'CustomSymbolsService');
        } else {
          // IMPROVED: Handle conflicts based on timestamps if available
          final fbDate = fbSymbol.dateCreated ?? DateTime.fromMillisecondsSinceEpoch(0);
          final localDate = localSymbol.dateCreated ?? DateTime.fromMillisecondsSinceEpoch(0);
          
          if (fbDate.isAfter(localDate)) {
            // Firebase version is newer - update local
            final index = _customSymbols.indexWhere((local) => local.id == fbSymbol.id);
            if (index != -1) {
              _customSymbols[index] = fbSymbol;
              hasChanges = true;
              AACLogger.info('CustomSymbolsService: Background sync - Updated symbol from Firebase (newer): ${fbSymbol.label}', tag: 'CustomSymbolsService');
            }
          }
        }
      }
      
      // Check if local storage has symbols not in Firebase (sync them up)
      final localOnlySymbols = _customSymbols.where((local) => 
        !firebaseSymbols.any((fb) => fb.id == local.id)).toList();
      
      if (localOnlySymbols.isNotEmpty) {
        AACLogger.info('CustomSymbolsService: Found ${localOnlySymbols.length} local-only symbols (will sync to Firebase)', tag: 'CustomSymbolsService');
        // IMPROVED: Sync local-only symbols to Firebase to prevent data loss
        for (final localSymbol in localOnlySymbols) {
          _syncToFirebaseInBackground(localSymbol);
        }
      }
      
      if (hasChanges) {
        await _saveToLocal(); // Update local storage
        _symbolsController.add(_customSymbols); // Update UI
        AACLogger.info('CustomSymbolsService: Background sync completed with conflict resolution', tag: 'CustomSymbolsService');
      }
      
    } catch (e, stackTrace) {
      AACLogger.error('CustomSymbolsService: Background sync failed: $e', stackTrace: stackTrace, tag: 'CustomSymbolsService');
    }
  }

  /// Add a new custom symbol
  Future<bool> addCustomSymbol(Symbol symbol) async {
    if (!_isInitialized) {
      AACLogger.warning('CustomSymbolsService: Cannot add symbol - service not initialized', tag: 'CustomSymbolsService');
      return false;
    }

    try {
      AACLogger.info('CustomSymbolsService: Adding custom symbol: ${symbol.label}', tag: 'CustomSymbolsService');
      
      // STEP 1: Add to local Hive storage immediately (instant UI update)
      _customSymbols.add(symbol);
      await _saveToLocal();
      _symbolsController.add(_customSymbols);
      
      // STEP 2: Sync to Firebase in background (don't block UI)
      _syncToFirebaseInBackground(symbol);
      
      AACLogger.info('CustomSymbolsService: ✅ Added symbol locally: ${symbol.label}', tag: 'CustomSymbolsService');
      return true;
      
    } catch (e, stackTrace) {
      AACLogger.error('CustomSymbolsService: Failed to add symbol: $e', stackTrace: stackTrace, tag: 'CustomSymbolsService');
      return false;
    }
  }

  /// Remove a custom symbol
  Future<bool> removeCustomSymbol(String symbolId) async {
    if (!_isInitialized) {
      AACLogger.warning('CustomSymbolsService: Cannot remove symbol - service not initialized', tag: 'CustomSymbolsService');
      return false;
    }

    try {
      AACLogger.info('CustomSymbolsService: Removing custom symbol: $symbolId', tag: 'CustomSymbolsService');
      
      // STEP 1: Remove from local Hive storage immediately (instant UI update)
      _customSymbols.removeWhere((symbol) => symbol.id == symbolId);
      await _saveToLocal();
      _symbolsController.add(_customSymbols);
      
      // STEP 2: Remove from Firebase in background (don't block UI)
      _removeFromFirebaseInBackground(symbolId);
      
      AACLogger.info('CustomSymbolsService: ✅ Removed symbol locally: $symbolId', tag: 'CustomSymbolsService');
      return true;
      
    } catch (e, stackTrace) {
      AACLogger.error('CustomSymbolsService: Failed to remove symbol: $e', stackTrace: stackTrace, tag: 'CustomSymbolsService');
      return false;
    }
  }

  /// Save current symbols to local Hive storage
  Future<void> _saveToLocal() async {
    try {
      final localBox = await _userDataManager!.getCustomSymbolsBox();
      final symbolData = _customSymbols.map((symbol) => symbol.toJson()).toList();
      await localBox.put(_customSymbolsKey, symbolData);
      AACLogger.debug('CustomSymbolsService: Saved ${_customSymbols.length} symbols to local storage', tag: 'CustomSymbolsService');
    } catch (e, stackTrace) {
      AACLogger.error('CustomSymbolsService: Failed to save to local storage: $e', stackTrace: stackTrace, tag: 'CustomSymbolsService');
    }
  }

  /// Sync symbol to Firebase in background (non-blocking)
  Future<void> _syncToFirebaseInBackground(Symbol symbol) async {
    try {
      await SharedResourceService.addUserCustomSymbol(_currentUid!, symbol);
      AACLogger.debug('CustomSymbolsService: ✅ Background sync to Firebase completed for: ${symbol.label}', tag: 'CustomSymbolsService');
    } catch (e) {
      AACLogger.warning('CustomSymbolsService: Background Firebase sync failed for ${symbol.label}: $e', tag: 'CustomSymbolsService');
      // Don't propagate error - local data is still intact
    }
  }

  /// Remove symbol from Firebase in background (non-blocking)
  Future<void> _removeFromFirebaseInBackground(String symbolId) async {
    try {
      await SharedResourceService.deleteUserCustomSymbol(_currentUid!, symbolId);
      AACLogger.debug('CustomSymbolsService: ✅ Background removal from Firebase completed for: $symbolId', tag: 'CustomSymbolsService');
    } catch (e) {
      AACLogger.warning('CustomSymbolsService: Background Firebase removal failed for $symbolId: $e', tag: 'CustomSymbolsService');
      // Don't propagate error - local removal was successful
    }
  }

  /// Reset service state (call during sign-out)
  void resetServiceState() {
    AACLogger.info('CustomSymbolsService: Resetting service state', tag: 'CustomSymbolsService');
    _customSymbols.clear();
    
    // Only add to stream if controller is not closed
    if (!_symbolsController.isClosed) {
      _symbolsController.add(_customSymbols);
    }
    
    _currentUid = null;
    _userDataManager = null;
    _isInitialized = false;
  }

  /// Dispose resources
  void dispose() {
    AACLogger.info('CustomSymbolsService: Disposing service', tag: 'CustomSymbolsService');
    
    // Reset state first (while controller is still open)
    _customSymbols.clear();
    _currentUid = null;
    _userDataManager = null;
    _isInitialized = false;
    
    // Then close the controller
    if (!_symbolsController.isClosed) {
      _symbolsController.close();
    }
  }
}
