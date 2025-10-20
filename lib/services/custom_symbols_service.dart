import 'dart:async';
import '../models/symbol.dart';
import '../utils/aac_logger.dart';
import 'user_data_manager.dart';

/// Service for managing custom symbols with local-first Hive storage
/// Simplified architecture: Hive first (fast), no complex sync logic
/// Ensures custom symbols persist across app restarts and sessions
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
      AACLogger.info('CustomSymbolsService: Already initialized for UID: $_currentUid', tag: 'CustomSymbolsService');
      return;
    }

    try {
      AACLogger.info('CustomSymbolsService: Initializing with UID: $uid', tag: 'CustomSymbolsService');

      // Reset any previous state
      _customSymbols.clear();
      _currentUid = uid;
      _userDataManager = userDataManager;

      // Load symbols from local storage
      await _loadCustomSymbols();

      _isInitialized = true;
      AACLogger.info('CustomSymbolsService: ✅ Initialized successfully for UID: $uid with ${_customSymbols.length} symbols', tag: 'CustomSymbolsService');
    } catch (e, stacktrace) {
      AACLogger.error('CustomSymbolsService: Initialization failed: $e', stackTrace: stacktrace, tag: 'CustomSymbolsService');
      _customSymbols = [];
      _symbolsController.add(_customSymbols);
      _isInitialized = true; // Initialize to prevent crashes, but with empty data.
    }
  }

  /// Load custom symbols from local Hive storage
  Future<void> _loadCustomSymbols() async {
    AACLogger.info('CustomSymbolsService: Loading symbols from local storage for UID: $_currentUid', tag: 'CustomSymbolsService');

    try {
      // Load from local Hive storage
      final localBox = await _userDataManager!.getCustomSymbolsBox();
      final localData = localBox.get(_customSymbolsKey);

      if (localData != null && localData is List && localData.isNotEmpty) {
        try {
          _customSymbols = localData.map((data) => Symbol.fromJson(Map<String, dynamic>.from(data))).toList();
          AACLogger.info('CustomSymbolsService: Found ${_customSymbols.length} symbols in local storage', tag: 'CustomSymbolsService');
        } catch (parseError) {
          AACLogger.error('CustomSymbolsService: Error parsing local data: $parseError - Clearing corrupted data', tag: 'CustomSymbolsService');
          // Clear corrupted data
          await localBox.delete(_customSymbolsKey);
          _customSymbols = [];
        }
      } else {
        AACLogger.info('CustomSymbolsService: No local data found, starting fresh', tag: 'CustomSymbolsService');
        _customSymbols = [];
      }

      // Update UI with loaded data
      _symbolsController.add(_customSymbols);
      AACLogger.info('CustomSymbolsService: ✅ Data loading completed - ${_customSymbols.length} symbols available', tag: 'CustomSymbolsService');

    } catch (e, stackTrace) {
      AACLogger.error('CustomSymbolsService: Error loading symbols: $e', stackTrace: stackTrace, tag: 'CustomSymbolsService');
      _customSymbols = []; // Fallback to empty list
      _symbolsController.add(_customSymbols);
    }
  }



  /// Add a new custom symbol with local-first storage
  Future<bool> addCustomSymbol(Symbol symbol) async {
    if (!_isInitialized) {
      AACLogger.warning('CustomSymbolsService: Cannot add symbol - service not initialized', tag: 'CustomSymbolsService');
      return false;
    }

    try {
      // Check for duplicates
      if (_customSymbols.any((s) => s.id == symbol.id || s.label == symbol.label)) {
        AACLogger.warning('CustomSymbolsService: Symbol "${symbol.label}" already exists, skipping add', tag: 'CustomSymbolsService');
        return false;
      }

      AACLogger.info('CustomSymbolsService: Adding custom symbol: ${symbol.label}', tag: 'CustomSymbolsService');

      // Add to in-memory list and save to local storage
      _customSymbols.add(symbol);
      await _saveToLocal();
      _symbolsController.add(_customSymbols);

      AACLogger.info('CustomSymbolsService: ✅ Successfully added symbol "${symbol.label}" to local storage', tag: 'CustomSymbolsService');
      return true;

    } catch (e, stackTrace) {
      AACLogger.error('CustomSymbolsService: Failed to add symbol: $e', stackTrace: stackTrace, tag: 'CustomSymbolsService');

      // Rollback UI changes if save failed
      _customSymbols.removeWhere((s) => s.id == symbol.id);
      _symbolsController.add(_customSymbols);

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

      // Remove from local storage and update UI
      _customSymbols.removeWhere((symbol) => symbol.id == symbolId);
      await _saveToLocal();
      _symbolsController.add(_customSymbols);

      AACLogger.info('CustomSymbolsService: ✅ Removed symbol: $symbolId', tag: 'CustomSymbolsService');
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
