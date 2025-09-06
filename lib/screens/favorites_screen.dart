import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
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
              child: _buildSymbolImage(symbol),
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
                onPressed: () async {
                  if (_favoritesService.isFavorite(symbol)) {
                    await _favoritesService.removeFromFavorites(symbol);
                  } else {
                    await _favoritesService.addToFavorites(symbol);
                  }
                },
                child: Icon(
                  _favoritesService.isFavorite(symbol) 
                      ? CupertinoIcons.heart_fill 
                      : CupertinoIcons.heart,
                  size: 20,
                  color: _favoritesService.isFavorite(symbol) 
                      ? CupertinoColors.systemRed 
                      : CupertinoColors.systemGrey,
                ),
              ),
              
              // Play button
              CupertinoButton(
                padding: const EdgeInsets.all(8),
                onPressed: () => _playSymbol(symbol),
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

  // Helper method to build symbol image
  Widget _buildSymbolImage(Symbol symbol) {
    if (symbol.imagePath.startsWith('emoji:')) {
      return Center(
        child: Text(
          symbol.imagePath.substring(6),
          style: const TextStyle(fontSize: 30),
        ),
      );
    } else if (symbol.imagePath.startsWith('assets/')) {
      return Image.asset(
        symbol.imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(symbol.category),
      );
    } else {
      return Image.file(
        File(symbol.imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(symbol.category),
      );
    }
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
      
      // Record this as a group play action
      for (final item in group.items) {
        await _favoritesService.recordUsage(item.symbol, action: 'group_played');
      }
      
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

  void _playSymbol(Symbol symbol) async {
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
      // Add haptic feedback
      await AACHelper.accessibleHapticFeedback();
      
      // Show confirmation dialog for better user experience
      final bool? confirmed = await showCupertinoDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: const Text('Remove from Favorites'),
            content: Text('Remove "${symbol.label}" from your favorites?'),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('Remove'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );
      
      if (confirmed == true) {
        await _favoritesService.removeFromFavorites(symbol);
        
        // Show success feedback
        _showRemovalFeedback(symbol.label);
      }
    } catch (e) {
      debugPrint('Error removing from favorites: $e');
      // Show error feedback
      _showErrorFeedback('Failed to remove from favorites');
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
