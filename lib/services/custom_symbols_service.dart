import 'dart:async';
import '../models/symbol.dart';
import '../utils/aac_logger.dart';
import 'user_data_manager.dart';
import 'shared_resource_service.dart';
import 'symbols_migration_service.dart';
import 'supabase_aac_service_compatible.dart';

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

  /// Load custom symbols with Supabase-first approach for session persistence
  Future<void> _loadCustomSymbols() async {
    AACLogger.info('🔥🚀 CustomSymbolsService: _loadCustomSymbols() method STARTED for UID: $_currentUid', tag: 'CustomSymbolsService');
    List<Symbol> supabaseSymbols = [];
    List<Symbol> localSymbols = [];
    
    try {
      // STEP 1: Load from Supabase FIRST for session persistence
      AACLogger.info('🔥� CustomSymbolsService: Loading from Supabase for session persistence...', tag: 'CustomSymbolsService');
      try {
        supabaseSymbols = await SharedResourceService.getUserCustomSymbols(_currentUid!);
        AACLogger.info('🔥💾 CustomSymbolsService: Found ${supabaseSymbols.length} symbols in Supabase.', tag: 'CustomSymbolsService');
      } catch (supabaseError) {
        AACLogger.warning('🔥💾 CustomSymbolsService: Supabase load failed: $supabaseError', tag: 'CustomSymbolsService');
      }
      
      // STEP 2: Load from local storage as backup (for offline scenarios)
      try {
        AACLogger.info('🔥📱 CustomSymbolsService: Loading from local storage as backup...', tag: 'CustomSymbolsService');
        localSymbols = await _userDataManager!.getCustomSymbols();
        AACLogger.info('🔥📱 CustomSymbolsService: Found ${localSymbols.length} symbols locally.', tag: 'CustomSymbolsService');
      } catch (localError) {
        AACLogger.error('🔥📱 CustomSymbolsService: Local load failed: $localError', tag: 'CustomSymbolsService');
      }
      
      // STEP 3: SUPABASE FIRST strategy for session persistence
      if (supabaseSymbols.isNotEmpty) {
        // PRIMARY: Use Supabase data for persistence across sessions
        _customSymbols = supabaseSymbols;
        await _saveToLocal(); // Update local cache
        AACLogger.info('🔥✅ CustomSymbolsService: Using Supabase data (${_customSymbols.length} symbols) - Ensures session persistence', tag: 'CustomSymbolsService');
      } else if (localSymbols.isNotEmpty) {
        // FALLBACK: Use local data if Supabase is unavailable (offline mode)
        _customSymbols = localSymbols;
        AACLogger.info('🔥✅ CustomSymbolsService: Using local data (${_customSymbols.length} symbols) - Offline fallback', tag: 'CustomSymbolsService');
      } else {
        // FALLBACK: No data anywhere, start fresh
        _customSymbols = [];
        AACLogger.info('🔥✅ CustomSymbolsService: Starting fresh - No data found anywhere', tag: 'CustomSymbolsService');
      }
      
      // STEP 4: Update UI with loaded data
      _symbolsController.add(_customSymbols);
      AACLogger.info('🔥✅ CustomSymbolsService: Data loading completed - ${_customSymbols.length} symbols available for persistent sessions', tag: 'CustomSymbolsService');
      
    } catch (e, stackTrace) {
      AACLogger.error('🔥❌ CustomSymbolsService: Error loading symbols: $e', stackTrace: stackTrace, tag: 'CustomSymbolsService');
      _customSymbols = []; // Fallback to empty list
      _symbolsController.add(_customSymbols);
    }
  }

  /// Perform background sync to merge any new Firebase data with local Hive data
  Future<void> _performBackgroundSync(List<Symbol> firebaseSymbols) async {
    try {
      bool hasChanges = false;
      
      // Check if Firebase has any symbols not in local storage
      for (final fbSymbol in firebaseSymbols) {
        if (!_customSymbols.any((local) => local.id == fbSymbol.id)) {
          _customSymbols.add(fbSymbol);
          hasChanges = true;
          AACLogger.info('CustomSymbolsService: Background sync - Added new symbol from Firebase: ${fbSymbol.label}', tag: 'CustomSymbolsService');
        }
      }
      
      // Check if local storage has symbols not in Firebase (keep them)
      // This ensures that local-only changes are preserved
      final localOnlySymbols = _customSymbols.where((local) => 
        !firebaseSymbols.any((fb) => fb.id == local.id)).toList();
      
      if (localOnlySymbols.isNotEmpty) {
        AACLogger.info('CustomSymbolsService: Found ${localOnlySymbols.length} local-only symbols (preserving them)', tag: 'CustomSymbolsService');
      }
      
      if (hasChanges) {
        await _saveToLocal(); // Update local storage
        _symbolsController.add(_customSymbols); // Update UI
        AACLogger.info('CustomSymbolsService: Background sync completed - merged ${firebaseSymbols.length} Firebase symbols', tag: 'CustomSymbolsService');
      }
      
    } catch (e, stackTrace) {
      AACLogger.error('CustomSymbolsService: Background sync failed: $e', stackTrace: stackTrace, tag: 'CustomSymbolsService');
    }
  }

  /// Add a new custom symbol - DIRECT INSERTION WITH SESSION PERSISTENCE
  Future<bool> addCustomSymbol(Symbol symbol) async {
    if (!_isInitialized) {
      AACLogger.warning('CustomSymbolsService: Cannot add symbol - service not initialized', tag: 'CustomSymbolsService');
      return false;
    }

    try {
      // Check for duplicates
      if (_customSymbols.any((s) => s.id == symbol.id || s.label == symbol.label)) {
        AACLogger.warning('🔥⚠️ CustomSymbolsService: Symbol "${symbol.label}" already exists, skipping add', tag: 'CustomSymbolsService');
        return false;
      }
      
      AACLogger.info('🔥💾 CustomSymbolsService: Adding custom symbol: ${symbol.label}', tag: 'CustomSymbolsService');
      
      // 1. IMMEDIATE UI UPDATE: Add to in-memory list and notify listeners
      _customSymbols.add(symbol);
      _symbolsController.add(_customSymbols);
      AACLogger.info('🔥📱 CustomSymbolsService: UI updated immediately with new symbol', tag: 'CustomSymbolsService');
      
      // 2. DIRECT INSERT to Supabase for session persistence
      await _insertDirectlyToSupabase(symbol);
      AACLogger.info('🔥💾 CustomSymbolsService: Symbol inserted to Supabase for persistence', tag: 'CustomSymbolsService');
      
      // 3. UPDATE LOCAL CACHE for offline access
      await _saveToLocal();
      AACLogger.info('🔥📱 CustomSymbolsService: Local cache updated', tag: 'CustomSymbolsService');
      
      AACLogger.info('🔥✅ CustomSymbolsService: Successfully added symbol "${symbol.label}" with session persistence', tag: 'CustomSymbolsService');
      return true;
      
    } catch (e, stackTrace) {
      AACLogger.error('🔥❌ CustomSymbolsService: Failed to add symbol: $e', stackTrace: stackTrace, tag: 'CustomSymbolsService');
      
      // Rollback UI changes if Supabase insert failed
      _customSymbols.removeWhere((s) => s.id == symbol.id);
      _symbolsController.add(_customSymbols);
      AACLogger.info('🔥🔄 CustomSymbolsService: Rolled back UI changes due to error', tag: 'CustomSymbolsService');
      
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

  /// Save symbol to local storage only
  Future<void> _saveSymbolToLocal(Symbol symbol) async {
    try {
      // Generate ID if needed
      final key = symbol.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      if (symbol.id == null) {
        symbol.id = key;
      }
      
      // Save to local Hive box via UserDataManager (local only, no cloud sync)
      final box = _userDataManager!.userSymbolsBox;
      await box.put(key, symbol);
      
      AACLogger.info('🔥 LOCAL STORAGE: Symbol "${symbol.label}" saved locally', tag: 'CustomSymbolsService');
    } catch (e) {
      AACLogger.error('🔥 LOCAL STORAGE: Error saving symbol locally: $e', tag: 'CustomSymbolsService');
      rethrow;
    }
  }

  /// Insert symbol directly to Supabase (bypassing batch sync)
  Future<void> _insertDirectlyToSupabase(Symbol symbol) async {
    try {
      print('🔥 DIRECT INSERT: Inserting custom symbol to Supabase: ${symbol.label}');
      
      await SupabaseAACService.createCustomSymbol(
        label: symbol.label,
        description: symbol.description,
        imagePath: symbol.imagePath,
        categoryId: symbol.category, // category is String, not Category object
        speechText: symbol.speechText ?? symbol.label,
        colorCode: symbol.colorCode,
        tags: const [], // Symbol model doesn't have tags, use empty list
        isShared: false, // Symbol model doesn't have isShared, default to false
      );
      
      print('🔥 DIRECT INSERT: ✅ Custom symbol inserted successfully to Supabase');
      AACLogger.info('🔥 DIRECT INSERT: Custom symbol "${symbol.label}" inserted to Supabase', tag: 'CustomSymbolsService');
    } catch (e) {
      print('🔥 DIRECT INSERT: ❌ Error inserting custom symbol to Supabase: $e');
      AACLogger.error('🔥 DIRECT INSERT: Error inserting custom symbol to Supabase: $e', tag: 'CustomSymbolsService');
      // Don't rethrow - let local operations continue even if cloud sync fails
    }
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
