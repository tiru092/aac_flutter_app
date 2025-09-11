import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import '../services/data_services_initializer_robust.dart';
import '../models/symbol.dart';
import '../utils/aac_helper.dart';
import '../services/favorites_service.dart';

/// Production-ready Favorites Screen
/// Shows favorite symbols and usage history for ASD users
/// Optimized for accessibility and ease of use
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  // Use centralized FavoritesService instance
  FavoritesService? _favoritesService;
  
  int _selectedTab = 0; // Track selected tab for CupertinoSegmentedControl
  List<Symbol> _favorites = [];
  List<HistoryItem> _history = [];
  
  // Selection mode state
  bool _isSelectionMode = false;
  Set<String> _selectedSymbols = {}; // Store symbol IDs for selection
  
  StreamSubscription? _favoritesSubscription;
  StreamSubscription? _historySubscription;
  
  // ASD-friendly colors
  final Color _primaryColor = const Color(0xFF4ECDC4);
  final Color _accentColor = const Color(0xFF45B7B8);
  final Color _backgroundColor = const Color(0xFFF8F9FA);
  final Color _cardColor = Colors.white;
  final Color _successColor = const Color(0xFF26de81);
  final Color _warningColor = const Color(0xFFffa726);

  @override
  void initState() {
    super.initState();
    _favoritesService = DataServicesInitializer.instance.favoritesService;
    _initializeFavorites();
  }

  Future<void> _initializeFavorites() async {
    try {
      // Check if FavoritesService is available
      if (_favoritesService == null) {
        debugPrint('FavoritesScreen: FavoritesService not available');
        return;
      }
      
      // Load initial data first
      final initialFavorites = _favoritesService!.favoriteSymbols;
      final initialHistory = _favoritesService!.usageHistory;
      
      // Update state with initial data immediately
      if (mounted) {
        setState(() {
          _favorites = initialFavorites;
          _history = initialHistory;
        });
      }
      
      // Set up real-time streams
      _favoritesSubscription = _favoritesService!.favoritesStream.listen((favorites) {
        if (mounted) {
          setState(() {
            _favorites = favorites;
          });
        }
      });
      
      _historySubscription = _favoritesService!.historyStream.listen((history) {
        if (mounted) {
          setState(() {
            _history = history;
          });
        }
      });
      
    } catch (e) {
      debugPrint('FavoritesScreen: Initialization error: $e');
    }
  }

  @override
  void dispose() {
    _favoritesSubscription?.cancel();
    _historySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          // Ensure we're properly returning to the home screen
          debugPrint('FavoritesScreen: Back navigation triggered');
        }
      },
      child: CupertinoPageScaffold(
        backgroundColor: _backgroundColor,
        navigationBar: CupertinoNavigationBar(
          backgroundColor: _primaryColor,
          border: null,
          middle: const Text(
            'Favorites & History',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          leading: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CupertinoButton(
              padding: const EdgeInsets.all(8),
              onPressed: () {
                debugPrint('FavoritesScreen: Back button pressed');
                Navigator.pop(context);
              },
              child: const Icon(
                CupertinoIcons.chevron_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          trailing: _isSelectionMode ? _buildSelectionModeButtons() : _buildClearButton(),
        ),
      child: SafeArea(
        child: Column(
          children: [
            // Tab bar - Using CupertinoSegmentedControl with better alignment
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CupertinoSegmentedControl<int>(
                children: {
                  0: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _selectedTab == 0 ? Colors.black.withOpacity(0.1) : Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.heart_fill, 
                          size: 18,
                          color: _selectedTab == 0 ? Colors.white : Colors.white,
                        ),
                        const SizedBox(width: 8),
                        DefaultTextStyle(
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                          child: const Text('Favorites'),
                        ),
                      ],
                    ),
                  ),
                  1: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _selectedTab == 1 ? Colors.black.withOpacity(0.1) : Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.clock_fill, 
                          size: 18,
                          color: _selectedTab == 1 ? Colors.white : Colors.white,
                        ),
                        const SizedBox(width: 8),
                        DefaultTextStyle(
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                          child: const Text('History'),
                        ),
                      ],
                    ),
                  ),
                },
                groupValue: _selectedTab,
                onValueChanged: (int? value) {
                  if (value != null) {
                    setState(() {
                      _selectedTab = value;
                    });
                  }
                },
                borderColor: _primaryColor.withOpacity(0.3),
                selectedColor: _primaryColor,
                unselectedColor: Colors.transparent,
                pressedColor: _primaryColor.withOpacity(0.2),
              ),
            ),
              
              // Tab content
              Expanded(
                child: _buildCurrentTab(),
              ),
            ],
        ),
      ),
    ));
  }

  Widget _buildClearButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.all(8),
        onPressed: () => _showClearDialog(),
        child: const Icon(
          CupertinoIcons.clear_circled,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildSelectionModeButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Delete selected button
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: _selectedSymbols.isNotEmpty ? () => _showRemoveSelectedDialog() : null,
            child: Icon(
              CupertinoIcons.delete,
              color: _selectedSymbols.isNotEmpty ? Colors.white : Colors.white54,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Cancel selection mode button
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: _exitSelectionMode,
            child: const Icon(
              CupertinoIcons.xmark,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  /// Build the current tab based on selected index
  Widget _buildCurrentTab() {
    switch (_selectedTab) {
      case 0:
        return _buildFavoritesTab();
      case 1:
        return _buildHistoryTab();
      default:
        return _buildFavoritesTab();
    }
  }

  Widget _buildFavoritesTab() {
    if (_favorites.isEmpty) {
      return _buildEmptyState(
        icon: CupertinoIcons.heart,
        title: 'No Favorites Yet',
        message: 'Add symbols to favorites by tapping the heart icon when using them.',
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0,
        ),
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final symbol = _favorites[index];
          return _buildSymbolCard(symbol);
        },
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_history.isEmpty) {
      return _buildEmptyState(
        icon: CupertinoIcons.clock,
        title: 'No History Yet',
        message: 'Start using symbols and they will appear here in your history.',
      );
    }

    // Group history by date like Avaz app
    final groupedHistory = _groupHistoryByDate(_history);
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedHistory.length,
      itemBuilder: (context, index) {
        final dateGroup = groupedHistory[index];
        return _buildDateGroup(dateGroup);
      },
    );
  }

  Widget _buildSymbolCard(Symbol symbol) {
    final categoryColor = AACHelper.getCategoryColor(symbol.category);
    final symbolId = symbol.id ?? symbol.label; // Use label as fallback ID
    final isSelected = _selectedSymbols.contains(symbolId);
    
    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleSymbolSelection(symbol);
        } else {
          _onSymbolTap(symbol);
        }
      },
      onLongPress: () => _startSelectionMode(symbol),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? categoryColor.withOpacity(0.3) : _cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? categoryColor : categoryColor.withOpacity(0.3),
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: categoryColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Symbol image
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: symbol.imagePath.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildSymbolImage(symbol, context),
                            )
                          : _buildDefaultIcon(symbol.category, context),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Symbol label
                  Expanded(
                    flex: 1,
                    child: Text(
                      symbol.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            // Selection checkbox in selection mode
            if (_isSelectionMode)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected ? _successColor : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSelected ? CupertinoIcons.check_mark : CupertinoIcons.circle,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(HistoryItem historyItem) {
    final symbol = historyItem.symbol;
    final timeAgo = _getTimeAgo(historyItem.timestamp);
    final actionIcon = _getActionIcon(historyItem.action);
    final actionColor = _getActionColor(historyItem.action);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AACHelper.getCategoryColor(symbol.category).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Symbol image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AACHelper.getCategoryColor(symbol.category).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AACHelper.getCategoryColor(symbol.category).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: _buildSymbolImage(symbol, context),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Symbol info and action
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  symbol.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      actionIcon,
                      size: 14,
                      color: actionColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      historyItem.action,
                      style: TextStyle(
                        fontSize: 13,
                        color: actionColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      ' • $timeAgo',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (symbol.category.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    symbol.category,
                    style: TextStyle(
                      fontSize: 12,
                      color: AACHelper.getCategoryColor(symbol.category),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Add to favorites button
              CupertinoButton(
                padding: const EdgeInsets.all(8),
                onPressed: _favoritesService != null ? () async {
                  if (_favoritesService!.isFavorite(symbol)) {
                    await _favoritesService!.removeFromFavorites(symbol);
                  } else {
                    await _favoritesService!.addToFavorites(symbol);
                  }
                } : null,
                child: Icon(
                  _favoritesService?.isFavorite(symbol) == true
                      ? CupertinoIcons.heart_fill 
                      : CupertinoIcons.heart,
                  size: 20,
                  color: _favoritesService?.isFavorite(symbol) == true
                      ? CupertinoColors.systemRed 
                      : CupertinoColors.systemGrey,
                ),
              ),
              
              // Play button
              CupertinoButton(
                padding: const EdgeInsets.all(8),
                onPressed: () => _playSymbolFromHistory(symbol),
                child: const Icon(
                  CupertinoIcons.play_circle_fill,
                  size: 24,
                  color: CupertinoColors.systemBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to get action icon
  IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'played':
      case 'spoken':
        return CupertinoIcons.speaker_3_fill;
      case 'added':
        return CupertinoIcons.plus_circle_fill;
      case 'favorited':
        return CupertinoIcons.heart_fill;
      case 'edited':
        return CupertinoIcons.pencil_circle_fill;
      default:
        return CupertinoIcons.circle_fill;
    }
  }

  // Helper method to get action color
  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'played':
      case 'spoken':
        return CupertinoColors.systemGreen;
      case 'added':
        return CupertinoColors.systemBlue;
      case 'favorited':
        return CupertinoColors.systemRed;
      case 'edited':
        return CupertinoColors.systemOrange;
      default:
        return CupertinoColors.systemGrey;
    }
  }

  // Group history by date like Avaz app
  List<DateHistoryGroup> _groupHistoryByDate(List<HistoryItem> history) {
    final Map<String, List<HistoryItem>> groupedMap = {};
    
    for (final item in history) {
      final dateKey = _getDateKey(item.timestamp);
      if (!groupedMap.containsKey(dateKey)) {
        groupedMap[dateKey] = [];
      }
      groupedMap[dateKey]!.add(item);
    }
    
    // Convert to list and sort by date (newest first)
    final groups = groupedMap.entries.map((entry) {
      return DateHistoryGroup(
        dateKey: entry.key,
        items: entry.value,
        date: entry.value.first.timestamp,
      );
    }).toList();
    
    groups.sort((a, b) => b.date.compareTo(a.date));
    return groups;
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(date.year, date.month, date.day);
    
    if (itemDate == today) {
      return 'Today';
    } else if (itemDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildDateGroup(DateHistoryGroup group) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _primaryColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header with play all button (like Avaz)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.dateKey,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${group.items.length} symbols used',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Play all button like Avaz app
                CupertinoButton(
                  padding: const EdgeInsets.all(12),
                  onPressed: () => _playAllFromGroup(group),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          CupertinoIcons.play_fill,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Play All',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // History items for this date
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: group.items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildHistoryItem(group.items[index]);
            },
          ),
        ],
      ),
    );
  }

  // Play all symbols from a date group like Avaz app
  Future<void> _playAllFromGroup(DateHistoryGroup group) async {
    try {
      await AACHelper.accessibleHapticFeedback();
      
      // Create sentence from all symbols in the group
      final allSymbols = group.items.map((item) => item.symbol.label).toList();
      final sentence = allSymbols.join(' ');
      
      // Show loading indicator
      _showPlayingAllDialog(group.dateKey, allSymbols.length);
      
      // Speak the combined sentence
      await AACHelper.speak(sentence);
      
      // Don't record usage again when playing from history
      // This prevents duplicating history entries
      
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
      
    } catch (e) {
      debugPrint('Error playing group: $e');
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _showPlayingAllDialog(String dateKey, int count) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: Text('🔊 Playing $dateKey'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const CupertinoActivityIndicator(),
            const SizedBox(height: 16),
            Text('Speaking $count symbols together...'),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startSelectionMode(Symbol symbol) {
    final symbolId = symbol.id ?? symbol.label;
    setState(() {
      _isSelectionMode = true;
      _selectedSymbols.clear();
      _selectedSymbols.add(symbolId);
    });
  }

  void _toggleSymbolSelection(Symbol symbol) {
    final symbolId = symbol.id ?? symbol.label;
    setState(() {
      if (_selectedSymbols.contains(symbolId)) {
        _selectedSymbols.remove(symbolId);
        // Exit selection mode if no symbols are selected
        if (_selectedSymbols.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedSymbols.add(symbolId);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedSymbols.clear();
    });
  }

  void _removeSelectedSymbols() async {
    if (_favoritesService == null) return;
    
    for (String symbolId in _selectedSymbols) {
      final symbol = _favorites.firstWhere((s) => (s.id ?? s.label) == symbolId);
      await _favoritesService!.removeFromFavorites(symbol);
    }
    _exitSelectionMode();
  }

  void _onSymbolTap(Symbol symbol) async {
    try {
      // Provide haptic feedback first
      await AACHelper.accessibleHapticFeedback();
      
      // Record usage (don't speak here - it will be spoken in the maximized view)
      if (_favoritesService != null) {
        await _favoritesService!.recordUsage(symbol, action: 'played');
      }
      
      // Show maximized view like the main page
      _showSymbolPopup(symbol);
      
    } catch (e) {
      debugPrint('Error playing symbol: $e');
    }
  }

  void _showSymbolPopup(Symbol symbol) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss symbol view',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 450),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnimation = Tween<double>(
          begin: 0.2,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutQuint,
        ));
        
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ));
        
        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: GestureDetector(
                  onTap: () {}, // Prevent tap from bubbling up
                  child: _SymbolMaximizedView(symbol: symbol),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _playSymbol(Symbol symbol) async {
    try {
      // Play the symbol
      await AACHelper.speak(symbol.label);
      
      // Record usage
      if (_favoritesService != null) {
        await _favoritesService!.recordUsage(symbol, action: 'played');
      }
      
    } catch (e) {
      debugPrint('Error playing symbol: $e');
    }
  }

  // Play symbol from history without recording usage again
  void _playSymbolFromHistory(Symbol symbol) async {
    try {
      // Only play the symbol, don't record usage again
      await AACHelper.speak(symbol.label);
      
    } catch (e) {
      debugPrint('Error playing symbol from history: $e');
    }
  }

  void _showClearDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Clear Data'),
        content: const Text('What would you like to clear?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Clear Favorites'),
            onPressed: () {
              Navigator.pop(context);
              if (_favoritesService != null) {
                _favoritesService!.clearFavorites();
              }
            },
          ),
          CupertinoDialogAction(
            child: const Text('Clear History'),
            onPressed: () {
              Navigator.pop(context);
              if (_favoritesService != null) {
                _favoritesService!.clearHistory();
              }
            },
          ),
          CupertinoDialogAction(
            child: const Text('Clear All'),
            onPressed: () {
              Navigator.pop(context);
              if (_favoritesService != null) {
                _favoritesService!.clearFavorites();
                _favoritesService!.clearHistory();
              }
            },
          ),
          CupertinoDialogAction(
            child: const Text('Cancel'),
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showRemoveSelectedDialog() {
    final selectedCount = _selectedSymbols.length;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Remove from Favorites'),
        content: Text('Remove $selectedCount selected symbol${selectedCount > 1 ? 's' : ''} from favorites?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Remove'),
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _removeSelectedSymbols();
            },
          ),
          CupertinoDialogAction(
            child: const Text('Cancel'),
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // Show success feedback when symbol is removed
  void _showRemovalFeedback(String symbolLabel) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.12,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _successColor.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '✅ Removed "$symbolLabel" from favorites',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    overlay.insert(overlayEntry);
    
    // Remove after 2.5 seconds
    Timer(const Duration(milliseconds: 2500), () {
      overlayEntry.remove();
    });
  }

  // Show error feedback
  void _showErrorFeedback(String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.12,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemRed.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.exclamationmark_triangle_fill,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    overlay.insert(overlayEntry);
    
    // Remove after 2.5 seconds
    Timer(const Duration(milliseconds: 2500), () {
      overlayEntry.remove();
    });
  }
}

class _SymbolMaximizedView extends StatefulWidget {
  final Symbol symbol;

  const _SymbolMaximizedView({required this.symbol});

  @override
  State<_SymbolMaximizedView> createState() => _SymbolMaximizedViewState();
}

class _SymbolMaximizedViewState extends State<_SymbolMaximizedView>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Start pulse animation
    _pulseController.repeat(reverse: true);
    
    // Speak the symbol immediately when maximized
    AACHelper.speak(widget.symbol.label);
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = AACHelper.getCategoryColor(widget.symbol.category);
    final isHighContrast = AACHelper.isHighContrastEnabled;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;
    
    return Container(
      margin: EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
      constraints: BoxConstraints(
        maxWidth: isLandscape 
          ? MediaQuery.of(context).size.width * 0.72  // Reduced by 20% for horizontal view (0.9 * 0.8 = 0.72)
          : MediaQuery.of(context).size.width * 0.9,  // Keep original 90% for vertical view
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: isHighContrast ? Border.all(
          color: categoryColor,
          width: 6,
        ) : null,
        boxShadow: isHighContrast ? [] : [
          BoxShadow(
            color: categoryColor.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
            spreadRadius: 5,
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with category color and action buttons
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: isLandscape 
                  ? MediaQuery.of(context).size.height * 0.012
                  : MediaQuery.of(context).size.height * 0.015,
              ),
              decoration: BoxDecoration(
                color: categoryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Action buttons on left
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                      // Speak Again button
                      GestureDetector(
                        onTap: () async {
                          try {
                            await AACHelper.accessibleHapticFeedback();
                            await AACHelper.speak(widget.symbol.label);
                          } catch (e) {
                            print('Error speaking symbol: $e');
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8C00),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF8C00).withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            CupertinoIcons.speaker_3_fill,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.015),
                      // Close button  
                      GestureDetector(
                        onTap: () async {
                          try {
                            await AACHelper.accessibleHapticFeedback();
                            Navigator.pop(context);
                          } catch (e) {
                            print('Error closing popup: $e');
                            Navigator.pop(context);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8C00),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF8C00).withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            CupertinoIcons.xmark,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Symbol label in center
                  Expanded(
                    child: Text(
                      widget.symbol.label,
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.06,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  ),
                  // Empty space for balance
                  SizedBox(width: MediaQuery.of(context).size.width * 0.1),
                ],
              ),
            ),
            
            // Symbol image with pulse animation
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.04,
                vertical: MediaQuery.of(context).size.height * 0.015,
              ),
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final screenHeight = MediaQuery.of(context).size.height;
                  final isLandscape = screenWidth > screenHeight;
                  
                  final maxImageSize = isLandscape 
                    ? screenHeight * 0.6
                    : screenWidth * 0.75;
                  final imageSize = maxImageSize.clamp(250.0, 500.0);
                  
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Stack( // Wrap in a Stack
                      children: [
                        Container(
                          width: imageSize,
                          height: imageSize,
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: categoryColor.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: _buildSymbolImage(widget.symbol, context),
                          ),
                        ),
                        // Symbol label below the image
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              widget.symbol.label,
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width * 0.045 * AACHelper.getTextSizeMultiplier(),
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Description if available
            if (widget.symbol.description != null && widget.symbol.description!.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.05,
                  vertical: MediaQuery.of(context).size.height * 0.015,
                ),
                child: Text(
                  widget.symbol.description!,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.045 * AACHelper.getTextSizeMultiplier(),
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            
            SizedBox(height: MediaQuery.of(context).size.height * 0.025),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
}

/// Date-grouped history for Avaz-style display
class DateHistoryGroup {
  final String dateKey;
  final List<HistoryItem> items;
  final DateTime date;

  DateHistoryGroup({
    required this.dateKey,
    required this.items,
    required this.date,
  });
}

// Helper method to build symbol image
Widget _buildSymbolImage(Symbol symbol, BuildContext context) {
  if (symbol.imagePath.startsWith('emoji:')) {
    return Center(
      child: Text(
        symbol.imagePath.substring(6), // Remove 'emoji:' prefix
        style: const TextStyle(fontSize: 40),
      ),
    );
  } else if (symbol.imagePath.startsWith('assets/')) {
    return Image.asset(
      symbol.imagePath,
      fit: BoxFit.contain,
      semanticLabel: symbol.label,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(symbol.category, context),
    );
  } else {
    return Image.file(
      File(symbol.imagePath),
      fit: BoxFit.contain,
      semanticLabel: symbol.label,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(symbol.category, context),
    );
  }
}

Widget _buildDefaultIcon(String category, BuildContext context) {
  return Icon(
    _getCategoryIcon(category),
    size: 30,
    color: AACHelper.getCategoryColor(category),
  );
}

IconData _getCategoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'food & drinks':
    case 'food':
      return CupertinoIcons.bag_fill;
    case 'emotions':
      return CupertinoIcons.smiley;
    case 'actions':
      return CupertinoIcons.hand_raised;
    case 'family':
      return CupertinoIcons.person_2_fill;
    case 'basic needs':
      return CupertinoIcons.heart_fill;
    case 'vehicles':
      return CupertinoIcons.car;
    case 'animals':
      return CupertinoIcons.paw;
    case 'toys':
      return CupertinoIcons.gamecontroller;
    case 'colors':
      return CupertinoIcons.paintbrush;
    case 'numbers':
      return CupertinoIcons.number;
    case 'letters':
      return CupertinoIcons.textformat_abc;
    default:
      return CupertinoIcons.circle_fill;
  }
}

String _getTimeAgo(DateTime timestamp) {
  final now = DateTime.now();
  final difference = now.difference(timestamp);
  
  if (difference.inMinutes < 1) {
    return 'Just now';
  } else if (difference.inHours < 1) {
    return '${difference.inMinutes}m ago';
  } else if (difference.inDays < 1) {
    return '${difference.inHours}h ago';
  } else if (difference.inDays < 7) {
    return '${difference.inDays}d ago';
  } else {
    return '${(difference.inDays / 7).floor()}w ago';
  }
}
