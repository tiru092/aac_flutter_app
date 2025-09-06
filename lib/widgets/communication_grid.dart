import 'dart:io';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/symbol.dart';
import '../utils/aac_helper.dart';
import '../services/favorites_service.dart';
import 'edit_tile_dialog.dart';

enum ViewType { categories, symbols }

class CommunicationGrid extends StatefulWidget {
  final List<Symbol> symbols;
  final List<Category> categories;
  final Function(Symbol) onSymbolTap;
  final Function(Category) onCategoryTap;
  final Function(Symbol)? onSymbolEdit;
  final Function(Symbol)? onSymbolUpdate;
  final VoidCallback? onAddSymbol;
  final ViewType viewType;
  
  // New parameters for speak bar functionality
  final List<Symbol>? selectedSymbols;
  final VoidCallback? onSpeakSentence;
  final VoidCallback? onClearSentence;
  final Function(int)? onRemoveSymbolAt;

  const CommunicationGrid({
    super.key,
    required this.symbols,
    required this.categories,
    required this.onSymbolTap,
    required this.onCategoryTap,
    required this.viewType,
    this.onSymbolEdit,
    this.onSymbolUpdate,
    this.onAddSymbol,
    this.selectedSymbols,
    this.onSpeakSentence,
    this.onClearSentence,
    this.onRemoveSymbolAt,
  });

  @override
  State<CommunicationGrid> createState() => _CommunicationGridState();
}

class _CommunicationGridState extends State<CommunicationGrid>
    with TickerProviderStateMixin {
  late AnimationController _gridAnimationController;
  late Animation<double> _gridAnimation;
  late AnimationController _pressAnimationController;
  late Animation<double> _pressAnimation;
  final FavoritesService _favoritesService = FavoritesService();

  @override
  void initState() {
    super.initState();
    _gridAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _gridAnimation = CurvedAnimation(
      parent: _gridAnimationController,
      curve: Curves.easeOutBack,
    );
    
    _pressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _pressAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _pressAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _gridAnimationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;
    
    if (widget.viewType == ViewType.categories) {
      return _buildCategoryGrid();
    }
    
    if (isLandscape && widget.selectedSymbols != null && 
        widget.onSpeakSentence != null && 
        widget.onClearSentence != null) {
      // Horizontal view with speak bar - only show when symbols are selected
      return Column(
        children: [
          Expanded(
            child: _buildSymbolGrid(),
          ),
          // Only show speak bar when there are selected symbols
          if (widget.selectedSymbols != null && widget.selectedSymbols!.isNotEmpty) 
            _buildSpeakBar(),
        ],
      );
    }
    
    // Default: just return the symbol grid (vertical view stays unchanged)
    return _buildSymbolGrid();
  }

  Widget _buildCategoryGrid() {
    if (widget.categories.isEmpty) {
      return _buildEmptyState();
    }

    return AnimatedBuilder(
      animation: _gridAnimation,
      builder: (context, child) {
        // More responsive columns based on screen size and orientation
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final isLandscape = screenWidth > screenHeight;
        
        // Dynamic column calculation for better space utilization
        int crossAxisCount;
        if (isLandscape) {
          // In landscape: Always show exactly 3 columns as requested
          crossAxisCount = 3;
        } else {
          // In portrait: 2 columns for larger layout size
          crossAxisCount = 2;
        }

        // Adjust spacing and padding based on screen size
        final basePadding = isLandscape ? screenWidth * 0.03 : screenWidth * 0.05;
        final spacing = isLandscape ? screenWidth * 0.02 : screenWidth * 0.04;

        return GridView.builder(
          padding: EdgeInsets.all(basePadding),
          physics: const BouncingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            // Adjust aspect ratio for consistent sizing
            childAspectRatio: isLandscape ? 1.2 : 1.1,
          ),
          itemCount: widget.categories.length,
          itemBuilder: (context, index) {
            final category = widget.categories[index];
            final delay = index * 0.1;

            return _buildCategoryCard(category, index);
          },
        );
      },
    );
  }

  Widget _buildCategoryCard(Category category, int index) {
    final symbolCount = widget.symbols
        .where((symbol) => symbol.category == category.name)
        .length;
    
    // Get therapy-tested color for this category
    final categoryColor = AACHelper.getCategoryColor(category.name);
    final isHighContrast = AACHelper.isHighContrastEnabled;
    
    return Semantics(
      label: 'Category: ${category.name}, $symbolCount symbols available, Double tap to open',
      button: true,
      enabled: true,
      child: AnimatedBuilder(
        animation: _pressAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pressAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                // Use solid category color instead of gradient
                color: categoryColor,
                borderRadius: BorderRadius.circular(28),
                border: isHighContrast ? Border.all(
                  color: Colors.black,
                  width: 4,
                ) : null,
                boxShadow: isHighContrast ? [] : [
                  BoxShadow(
                    color: categoryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTapDown: (_) => _pressAnimationController.forward(),
                  onTapUp: (_) => _pressAnimationController.reverse(),
                  onTapCancel: () => _pressAnimationController.reverse(),
                  onTap: () async {
                    await AACHelper.speak(category.name);
                    await AACHelper.accessibleHapticFeedback();
                    widget.onCategoryTap(category);
                  },
                  child: Padding(
                    padding: _getResponsiveCategoryPadding(context),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Category icon/emoji with responsive sizing
                        Container(
                          width: _getCategoryIconSize(context),
                          height: _getCategoryIconSize(context),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isHighContrast ? Colors.black : Colors.white.withOpacity(0.5), 
                              width: isHighContrast ? 3 : 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _getCategoryEmoji(category.name),
                              style: TextStyle(
                                fontSize: _getCategoryEmojiSize(context) * AACHelper.getTextSizeMultiplier(),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: _getResponsiveSpacing(context)),
                        Text(
                          category.name,
                          style: TextStyle(
                            fontSize: _getCategoryTextSize(context) * AACHelper.getTextSizeMultiplier(),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: isHighContrast ? [] : [
                              Shadow(
                                offset: const Offset(1, 1),
                                blurRadius: 2,
                                color: Colors.black.withOpacity(0.3),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: _getResponsiveSpacing(context) * 0.5),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: _getResponsiveSpacing(context) * 2,
                            vertical: _getResponsiveSpacing(context) * 0.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$symbolCount symbols',
                            style: TextStyle(
                              fontSize: _getCategoryCountTextSize(context) * AACHelper.getTextSizeMultiplier(),
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSymbolGrid() {
    if (widget.symbols.isEmpty) {
      return _buildEmptyState();
    }

    return AnimatedBuilder(
      animation: _gridAnimation,
      builder: (context, child) {
        // Responsive columns based on screen width
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final isLandscape = screenWidth > screenHeight;
        
        final crossAxisCount = isLandscape ? 3 : 2;

        final padding = MediaQuery.of(context).size.width * 0.04;

        return GridView.builder(
          padding: EdgeInsets.all(padding),
          physics: const BouncingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: padding, // 4% of screen width
            mainAxisSpacing: padding, // 4% of screen width
            // Make cells more consistent in sizing
            childAspectRatio: isLandscape ? 1.15 : 1.05,
          ),
          itemCount: widget.symbols.length, // Remove +1 for add tile
          itemBuilder: (context, index) {
            final delay = index * 0.05;

            return _buildSymbolCard(widget.symbols[index], index);
          },
        );
      },
    );
  }

  Widget _buildSymbolCard(Symbol symbol, int index) {
    // Get therapy-tested color for this symbol's category
    final categoryColor = AACHelper.getCategoryColor(symbol.category);
    final isHighContrast = AACHelper.isHighContrastEnabled;

    return Semantics(
      label: 'Symbol: ${symbol.label}, ${symbol.description ?? ''}, Double tap to speak',
      button: true,
      enabled: true,
      child: AnimatedBuilder(
        animation: _pressAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pressAnimation.value,
            child: GestureDetector(
              onTapDown: (_) => _pressAnimationController.forward(),
              onTapUp: (_) => _pressAnimationController.reverse(),
              onTapCancel: () => _pressAnimationController.reverse(),
              onTap: () async {
                // Haptic feedback first
                await AACHelper.accessibleHapticFeedback();
                // Only speak once and add to sentence
                widget.onSymbolTap(symbol);
                // Show maximized view
                _showSymbolPopup(symbol);
              },
              onLongPress: () {
                // Show edit dialog
                _showEditSymbolDialog(symbol);
              },
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isHighContrast ? Colors.white : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: isHighContrast ? Border.all(
                        color: categoryColor,
                        width: 4,
                      ) : null,
                      boxShadow: isHighContrast ? [] : [
                        BoxShadow(
                          color: categoryColor.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Symbol image area - 70% of card height
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Builder(
                                builder: (context) {
                                  // Calculate deterministic image size based on screen dimensions and grid layout
                                  final screenWidth = MediaQuery.of(context).size.width;
                                  final screenHeight = MediaQuery.of(context).size.height;
                                  final isLandscape = screenWidth > screenHeight;

                                  // Calculate cell dimensions based on grid configuration
                                  final crossAxisCount = isLandscape ? 3 : 2;
                                  final padding = screenWidth * 0.04;
                                  final spacing = screenWidth * 0.04;

                                  // Available width for grid: screenWidth - (padding * 2) - (spacing * (crossAxisCount - 1))
                                  final availableWidth = screenWidth - (padding * 2) - (spacing * (crossAxisCount - 1));
                                  final cellWidth = availableWidth / crossAxisCount;

                                  // Cell height based on aspect ratio
                                  final aspectRatio = isLandscape ? 1.15 : 1.05;
                                  final cellHeight = cellWidth * aspectRatio;

                                  // Base size is minimum of width and height (typically width in this layout)
                                  final baseSize = math.min(cellWidth, cellHeight);
                                  final imageSize = (baseSize * 0.8).clamp(48.0, 200.0);
                                  
                                  Widget imageWidget;
                                  if (symbol.imagePath.startsWith('emoji:')) {
                                    imageWidget = Center(
                                      child: Text(
                                        symbol.imagePath.substring(6),
                                        style: TextStyle(fontSize: imageSize * 0.6),
                                      ),
                                    );
                                  } else if (symbol.imagePath.startsWith('assets/')) {
                                    imageWidget = Image.asset(
                                      symbol.imagePath,
                                      fit: BoxFit.contain,
                                      semanticLabel: symbol.label,
                                      filterQuality: FilterQuality.high,
                                      errorBuilder: (context, error, stackTrace) => _buildErrorIcon(),
                                    );
                                  } else {
                                    imageWidget = Image.file(
                                      File(symbol.imagePath),
                                      fit: BoxFit.contain,
                                      semanticLabel: symbol.label,
                                      filterQuality: FilterQuality.high,
                                      errorBuilder: (context, error, stackTrace) => _buildErrorIcon(),
                                    );
                                  }
                                  
                                  return Center(
                                    child: SizedBox(
                                      width: imageSize,
                                      height: imageSize,
                                      child: FittedBox(
                                        fit: BoxFit.contain,
                                        child: imageWidget,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        // Symbol label area - 30% of card height
                        Expanded(
                          flex: 1,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: categoryColor,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(17),
                                bottomRight: Radius.circular(17),
                              ),
                            ),
                            child: Center(
                              child: AutoSizeText(
                                symbol.label,
                                maxLines: 2,
                                minFontSize: 11,
                                maxFontSize: 18,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Favorite button overlay
                  Positioned(
                    top: 4,
                    right: 4,
                    child: _FavoriteButtonWrapper(
                      symbol: symbol,
                      favoritesService: _favoritesService,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Responsive helper methods for better layout adaptation
  EdgeInsets _getResponsiveCategoryPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;
    
    if (isLandscape) {
      return EdgeInsets.all(screenWidth * 0.02); // Tighter padding in landscape
    } else {
      return EdgeInsets.all(screenWidth * 0.03); // More generous padding in portrait
    }
  }

  double _getCategoryIconSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;
    
    if (isLandscape) {
      // Base size on height in landscape to fit vertically
      return (screenHeight * 0.12).clamp(60.0, 100.0);
    } else {
      // Base size on width in portrait
      return (screenWidth * 0.15).clamp(70.0, 120.0);
    }
  }

  double _getCategoryEmojiSize(BuildContext context) {
    final iconSize = _getCategoryIconSize(context);
    return iconSize * 0.5; // Emoji should be about 50% of container size
  }

  double _getResponsiveSpacing(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return screenHeight * 0.01; // 1% of screen height
  }

  double _getCategoryTextSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;
    
    if (isLandscape) {
      return (screenWidth * 0.025).clamp(12.0, 20.0); // Smaller text in landscape
    } else {
      return (screenWidth * 0.04).clamp(14.0, 24.0); // Normal text in portrait
    }
  }

  double _getCategoryCountTextSize(BuildContext context) {
    final textSize = _getCategoryTextSize(context);
    return textSize * 0.75; // Count text should be smaller than category name
  }

  Widget _buildErrorIcon() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        CupertinoIcons.photo,
        size: 40,
        color: Colors.grey,
      ),
    );
  }

  String _getCategoryEmoji(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'food & drinks':
      case 'food':
        return '🍎';
      case 'vehicles':
        return '🚗';
      case 'emotions':
        return '😊';
      case 'actions':
        return '🏃';
      case 'family':
        return '👨‍👩‍👧‍👦';
      case 'basic needs':
        return '🙏';
      case 'custom':
        return '⭐';
      default:
        return '📝';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AACHelper.childFriendlyColors[0].withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              CupertinoIcons.add_circled,
              size: 60,
              color: AACHelper.childFriendlyColors[0],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No symbols yet!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first symbol',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSpeakBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.02,
        vertical: screenHeight * 0.008,
      ),
      constraints: BoxConstraints(
        minHeight: screenHeight * 0.08,
        maxHeight: screenHeight * 0.12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Selected symbols area
          if (widget.selectedSymbols != null && widget.selectedSymbols!.isNotEmpty)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                child: Row(
                  children: widget.selectedSymbols!.asMap().entries.map((entry) {
                    final categoryColor = AACHelper.getCategoryColor(entry.value.category);
                    return Padding(
                      padding: EdgeInsets.only(right: screenWidth * 0.01),
                      child: GestureDetector(
                        onTap: () => widget.onRemoveSymbolAt?.call(entry.key),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: categoryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            entry.value.label,
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          
          // Speak button
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.02),
            child: ElevatedButton.icon(
              onPressed: widget.onSpeakSentence,
              icon: Icon(CupertinoIcons.speaker_3, size: 20),
              label: Text('Speak'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38A169),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
          
          // Clear button
          if (widget.selectedSymbols != null && widget.selectedSymbols!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(right: screenWidth * 0.02),
              child: IconButton(
                onPressed: widget.onClearSentence,
                icon: Icon(CupertinoIcons.clear_thick),
                color: const Color(0xFFE53E3E),
              ),
            ),
        ],
      ),
    );
  }

  void _showSymbolPopup(Symbol symbol) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss symbol view',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 450), // Slower animation
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // Custom transition builder for both entry and exit animations
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
            onTap: () => Navigator.pop(context), // Close when tapping outside
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: GestureDetector(
                  onTap: () {}, // Prevent tap from bubbling up when tapping on the content
                  child: _SymbolMaximizedView(symbol: symbol),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditSymbolDialog(Symbol symbol) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => EditTileDialog(
        symbol: symbol,
        onSave: (updatedSymbol) {
          widget.onSymbolUpdate?.call(updatedSymbol);
        },
        onDelete: () {
          widget.onSymbolEdit?.call(symbol);
        },
      ),
    );
  }

  // Show feedback when favorite button is tapped
  void _showFavoritesFeedback(BuildContext context, String message, bool wasRemoved) {
    // Use CupertinoSnackBar for iOS-style feedback
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
              color: wasRemoved 
                  ? CupertinoColors.systemGrey6 
                  : CupertinoColors.systemRed.withOpacity(0.9),
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
                Icon(
                  wasRemoved ? CupertinoIcons.heart : CupertinoIcons.heart_fill,
                  color: wasRemoved ? CupertinoColors.systemGrey : Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: wasRemoved ? CupertinoColors.systemGrey : Colors.white,
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
    
    // Remove after 2 seconds
    Timer(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  @override
  void dispose() {
    _gridAnimationController.dispose();
    _pressAnimationController.dispose();
    super.dispose();
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
      margin: EdgeInsets.all(MediaQuery.of(context).size.width * 0.06), // 6% of screen width for margin
      constraints: BoxConstraints(
        maxWidth: isLandscape 
          ? MediaQuery.of(context).size.width * 0.72  // Reduced by 20% for horizontal view (0.9 * 0.8 = 0.72)
          : MediaQuery.of(context).size.width * 0.9,  // Keep original 90% for vertical view
        maxHeight: MediaQuery.of(context).size.height * 0.8, // Max 80% of screen height
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
          // Header with category color and action buttons on left
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: isLandscape 
                ? MediaQuery.of(context).size.height * 0.012  // Reduced by 20% for horizontal view
                : MediaQuery.of(context).size.height * 0.015, // Keep original for vertical view
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
                // Action buttons on left (Speak Again and Close) - Orange colored
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
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8C00), // Orange color
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF8C00).withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
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
                          Navigator.pop(context); // Fallback close
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8C00), // Orange color
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF8C00).withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
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
                  child: AutoSizeText(
                    widget.symbol.label,
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.06, // Reduced from 0.07 to 0.06
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    minFontSize: 16,
                  ),
                ),
                // Empty space for balance
                SizedBox(width: MediaQuery.of(context).size.width * 0.1),
              ],
            ),
          ),
          
          // Symbol image with pulse animation - made larger to occupy more space
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.04, // Reduced from 6% to 4%
              vertical: MediaQuery.of(context).size.height * 0.015, // Reduced from 2.5% to 1.5%
            ),
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                // Calculate responsive width based on screen size - made much larger
                final screenWidth = MediaQuery.of(context).size.width;
                final screenHeight = MediaQuery.of(context).size.height;
                final isLandscape = screenWidth > screenHeight;
                
                // Increase max image size significantly
                final maxImageSize = isLandscape 
                  ? screenHeight * 0.6  // Increased from 0.4 to 0.6 in landscape
                  : screenWidth * 0.75; // Increased from 0.6 to 0.75 in portrait
                final imageSize = maxImageSize.clamp(250.0, 500.0); // Increased min from 200 to 250, max from 400 to 500
                
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: imageSize,
                    height: imageSize,
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: categoryColor.withOpacity(0.3),
                        width: 3,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: widget.symbol.imagePath.startsWith('emoji:')
                          ? Center(
                              child: Text(
                                widget.symbol.imagePath.substring(6), // Remove 'emoji:' prefix
                                style: TextStyle(fontSize: imageSize * 0.4), // Scale emoji with image size
                              ),
                            )
                          : widget.symbol.imagePath.startsWith('assets/')
                              ? Image.asset(
                                  widget.symbol.imagePath,
                                  fit: BoxFit.contain,
                                  semanticLabel: widget.symbol.label,
                                  filterQuality: FilterQuality.high, // HD quality
                                  width: imageSize,
                                  height: imageSize,
                                )
                              : Image.file(
                                  File(widget.symbol.imagePath),
                                  fit: BoxFit.contain,
                                  semanticLabel: widget.symbol.label,
                                  filterQuality: FilterQuality.high, // HD quality
                                  width: imageSize,
                                  height: imageSize,
                                ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Description if available
          if (widget.symbol.description != null && widget.symbol.description!.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.05, // 5% of screen width
                vertical: MediaQuery.of(context).size.height * 0.015, // 1.5% of screen height
              ),
              child: Text(
                widget.symbol.description!,
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.045 * AACHelper.getTextSizeMultiplier(), // 4.5% of screen width
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          
          SizedBox(height: MediaQuery.of(context).size.height * 0.025), // 2.5% of screen height
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

/// Wrapper for Favorite Button that properly handles state changes
class _FavoriteButtonWrapper extends StatefulWidget {
  final Symbol symbol;
  final FavoritesService favoritesService;

  const _FavoriteButtonWrapper({
    required this.symbol,
    required this.favoritesService,
  });

  @override
  State<_FavoriteButtonWrapper> createState() => _FavoriteButtonWrapperState();
}

class _FavoriteButtonWrapperState extends State<_FavoriteButtonWrapper> {
  late bool _isFavorite;
  StreamSubscription? _favoritesSubscription;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.favoritesService.isFavorite(widget.symbol);
    
    // Listen to favorites stream for real-time updates
    _favoritesSubscription = widget.favoritesService.favoritesStream.listen((favorites) {
      final newIsFavorite = widget.favoritesService.isFavorite(widget.symbol);
      if (mounted && newIsFavorite != _isFavorite) {
        setState(() {
          _isFavorite = newIsFavorite;
        });
      }
    });
  }

  @override
  void dispose() {
    _favoritesSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FavoriteButton(
      symbol: widget.symbol,
      isFavorite: _isFavorite,
      favoritesService: widget.favoritesService,
      onToggle: () async {
        // Force immediate UI update for responsiveness
        setState(() {
          _isFavorite = !_isFavorite;
        });
        
        // Actually perform the favorite operation
        try {
          if (_isFavorite) {
            await widget.favoritesService.addToFavorites(widget.symbol);
          } else {
            await widget.favoritesService.removeFromFavorites(widget.symbol);
          }
        } catch (e) {
          // If the operation fails, revert the UI state
          debugPrint('Error toggling favorite: $e');
          setState(() {
            _isFavorite = !_isFavorite;
          });
        }
      },
    );
  }
}

/// Enhanced Favorite Button with Pop Sound and Heart Animation
class _FavoriteButton extends StatefulWidget {
  final Symbol symbol;
  final bool isFavorite;
  final FavoritesService favoritesService;
  final Future<void> Function()? onToggle;

  const _FavoriteButton({
    required this.symbol,
    required this.isFavorite,
    required this.favoritesService,
    this.onToggle,
  });

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton>
    with TickerProviderStateMixin {
  late AnimationController _heartController;
  late AnimationController _pulseController;
  late Animation<double> _heartAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Heart enlarging animation
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heartAnimation = Tween<double>(
      begin: 1.0,
      end: 1.4,
    ).animate(CurvedAnimation(
      parent: _heartController,
      curve: Curves.elasticOut,
    ));

    // Pulse animation for favorited state
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

    // Start pulse if already favorited
    if (widget.isFavorite) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_FavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle pulse animation based on favorite state
    if (widget.isFavorite && !oldWidget.isFavorite) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isFavorite && oldWidget.isFavorite) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _heartController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _playPopSound() async {
    try {
      // Simple pop sound using haptic feedback - production ready
      // This provides immediate tactile feedback without audio interference
      await AACHelper.accessibleHapticFeedback();
      
      // Optional: You could add a sound asset here in the future
      // For now, haptic feedback provides the "pop" sensation
    } catch (e) {
      // Ignore sound errors - don't break functionality
      debugPrint('Pop feedback failed: $e');
    }
  }

  Future<void> _onTap() async {
    try {
      // Call immediate UI update
      widget.onToggle?.call();
      
      // Haptic feedback
      await AACHelper.accessibleHapticFeedback();
      
      // Play pop sound
      _playPopSound();
      
      // Heart enlarging animation
      await _heartController.forward();
      _heartController.reverse();
      
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_heartAnimation, _pulseAnimation]),
        builder: (context, child) {
          final scale = _heartAnimation.value * 
                       (widget.isFavorite ? _pulseAnimation.value : 1.0);
          
          return Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: widget.isFavorite 
                    ? CupertinoColors.systemRed.withOpacity(0.15)
                    : Colors.white.withOpacity(0.95),
                shape: BoxShape.circle,
                border: widget.isFavorite 
                    ? Border.all(
                        color: CupertinoColors.systemRed.withOpacity(0.4), 
                        width: 2,
                      )
                    : Border.all(
                        color: Colors.grey.withOpacity(0.3), 
                        width: 1,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: widget.isFavorite 
                        ? CupertinoColors.systemRed.withOpacity(0.3)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: widget.isFavorite ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                widget.isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                size: 18,
                color: widget.isFavorite 
                    ? const Color(0xFFFF1744) // Bright red for better visibility
                    : CupertinoColors.systemGrey2,
              ),
            ),
          );
        },
      ),
    );
  }
}
