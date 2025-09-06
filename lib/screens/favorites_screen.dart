import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../services/favorites_service.dart';
import '../models/symbol.dart';
import '../utils/aac_helper.dart';

/// Production-ready Favorites Screen
/// Shows favorite symbols and usage history for ASD users
/// Optimized for accessibility and ease of use
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  
  int _selectedTab = 0; // Track selected tab for CupertinoSegmentedControl
  List<Symbol> _favorites = [];
  List<HistoryItem> _history = [];
  List<Symbol> _mostUsed = [];
  
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
    _initializeFavorites();
  }

  Future<void> _initializeFavorites() async {
    try {
      await _favoritesService.initialize();
      
      // Set up real-time streams
      _favoritesSubscription = _favoritesService.favoritesStream.listen((favorites) {
        if (mounted) {
          setState(() {
            _favorites = favorites;
            _mostUsed = _favoritesService.getMostUsedSymbols(limit: 10);
          });
        }
      });
      
      _historySubscription = _favoritesService.historyStream.listen((history) {
        if (mounted) {
          setState(() {
            _history = history;
            _mostUsed = _favoritesService.getMostUsedSymbols(limit: 10);
          });
        }
      });
      
      // Load initial data
      setState(() {
        _favorites = _favoritesService.favoriteSymbols;
        _history = _favoritesService.usageHistory;
        _mostUsed = _favoritesService.getMostUsedSymbols(limit: 10);
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
    return CupertinoPageScaffold(
      backgroundColor: _backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: _primaryColor,
        middle: const Text(
          'Favorites & History',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.back, color: Colors.white),
        ),
        trailing: _buildClearButton(),
      ),
      child: SafeArea(
        child: Column(
          children: [
              // Tab bar - Using CupertinoSegmentedControl instead of TabBar
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CupertinoSegmentedControl<int>(
                  children: {
                    0: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.heart_fill, size: 18),
                          SizedBox(width: 6),
                          Text('Favorites'),
                        ],
                      ),
                    ),
                    1: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.clock_fill, size: 18),
                          SizedBox(width: 6),
                          Text('History'),
                        ],
                      ),
                    ),
                    2: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.chart_bar_fill, size: 18),
                          SizedBox(width: 6),
                          Text('Most Used'),
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
                  borderColor: _primaryColor,
                  selectedColor: _primaryColor,
                  unselectedColor: _backgroundColor,
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
    );
  }

  Widget _buildClearButton() {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _showClearDialog(),
      child: const Icon(
        CupertinoIcons.clear_circled,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  /// Build the current tab based on selected index
  Widget _buildCurrentTab() {
    switch (_selectedTab) {
      case 0:
        return _buildFavoritesTab();
      case 1:
        return _buildHistoryTab();
      case 2:
        return _buildMostUsedTab();
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
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0,
        ),
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final symbol = _favorites[index];
          return _buildSymbolCard(symbol, showRemoveButton: true);
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

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final historyItem = _history[index];
        return _buildHistoryItem(historyItem);
      },
    );
  }

  Widget _buildMostUsedTab() {
    if (_mostUsed.isEmpty) {
      return _buildEmptyState(
        icon: CupertinoIcons.chart_bar,
        title: 'No Usage Data Yet',
        message: 'Use symbols regularly and your most used ones will appear here.',
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0,
        ),
        itemCount: _mostUsed.length,
        itemBuilder: (context, index) {
          final symbol = _mostUsed[index];
          final usageCount = _getUsageCount(symbol);
          return _buildSymbolCard(symbol, usageCount: usageCount);
        },
      ),
    );
  }

  Widget _buildSymbolCard(Symbol symbol, {bool showRemoveButton = false, int? usageCount}) {
    return GestureDetector(
      onTap: () => _onSymbolTap(symbol),
      child: Container(
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AACHelper.getCategoryColor(symbol.category).withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
                        color: AACHelper.getCategoryColor(symbol.category).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: symbol.imagePath.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                symbol.imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildDefaultIcon(symbol.category);
                                },
                              ),
                            )
                          : _buildDefaultIcon(symbol.category),
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
            
            // Remove button for favorites
            if (showRemoveButton)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _removeFromFavorites(symbol),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.minus,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            
            // Usage count badge
            if (usageCount != null)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _successColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$usageCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
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
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AACHelper.getCategoryColor(symbol.category).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Symbol image
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AACHelper.getCategoryColor(symbol.category).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: symbol.imagePath.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      symbol.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultIcon(symbol.category);
                      },
                    ),
                  )
                : _buildDefaultIcon(symbol.category),
          ),
          
          const SizedBox(width: 12),
          
          // Symbol info
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
                Text(
                  '${historyItem.action} • $timeAgo',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Play button
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _onSymbolTap(symbol),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.play_fill,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
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

  Widget _buildDefaultIcon(String category) {
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

  int _getCrossAxisCount() {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 800) return 4;
    if (screenWidth > 600) return 3;
    return 2;
  }

  int _getUsageCount(Symbol symbol) {
    return _history.where((item) => item.symbol.id == symbol.id).length;
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

  void _onSymbolTap(Symbol symbol) async {
    try {
      // Play the symbol
      await AACHelper.speak(symbol.label);
      
      // Record usage
      await _favoritesService.recordUsage(symbol, action: 'played');
      
    } catch (e) {
      debugPrint('Error playing symbol: $e');
    }
  }

  void _removeFromFavorites(Symbol symbol) async {
    try {
      await _favoritesService.removeFromFavorites(symbol);
    } catch (e) {
      debugPrint('Error removing from favorites: $e');
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
              _favoritesService.clearFavorites();
            },
          ),
          CupertinoDialogAction(
            child: const Text('Clear History'),
            onPressed: () {
              Navigator.pop(context);
              _favoritesService.clearHistory();
            },
          ),
          CupertinoDialogAction(
            child: const Text('Clear All'),
            onPressed: () {
              Navigator.pop(context);
              _favoritesService.clearFavorites();
              _favoritesService.clearHistory();
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
}
