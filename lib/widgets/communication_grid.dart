import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/symbol.dart';
import '../utils/aac_helper.dart';
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
    return widget.viewType == ViewType.categories
        ? _buildCategoryGrid()
        : _buildSymbolGrid();
  }

  Widget _buildCategoryGrid() {
    if (widget.categories.isEmpty) {
      return _buildEmptyState();
    }

    return AnimatedBuilder(
      animation: _gridAnimation,
      builder: (context, child) {
        return GridView.builder(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.0,
          ),
          itemCount: widget.categories.length,
          itemBuilder: (context, index) {
            final category = widget.categories[index];
            final delay = index * 0.1;
            
            return AnimatedBuilder(
              animation: _gridAnimationController,
              builder: (context, child) {
                final animationValue = Curves.easeOutBack.transform(
                  (_gridAnimation.value - delay).clamp(0.0, 1.0),
                );
                
                return Transform.scale(
                  scale: animationValue,
                  child: _buildCategoryCard(category, index),
                );
              },
            );
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
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Category icon/emoji with improved contrast
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isHighContrast ? Colors.black : Colors.white.withOpacity(0.5), 
                              width: isHighContrast ? 3 : 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _getCategoryEmoji(category.name),
                              style: TextStyle(
                                fontSize: 50 * AACHelper.getTextSizeMultiplier(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          category.name,
                          style: TextStyle(
                            fontSize: 22 * AACHelper.getTextSizeMultiplier(),
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
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            '$symbolCount symbols',
                            style: TextStyle(
                              fontSize: 12 * AACHelper.getTextSizeMultiplier(),
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
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0,
          ),
          itemCount: widget.symbols.length, // Remove +1 for add tile
          itemBuilder: (context, index) {
            final delay = index * 0.05;
            
            return AnimatedBuilder(
              animation: _gridAnimationController,
              builder: (context, child) {
                final animationValue = Curves.easeOutBack.transform(
                  (_gridAnimation.value - delay).clamp(0.0, 1.0),
                );
                
                return Transform.scale(
                  scale: animationValue,
                  child: _buildSymbolCard(widget.symbols[index], index),
                );
              },
            );
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
                // Only speak once and add to sentence
                widget.onSymbolTap(symbol);
                await AACHelper.accessibleHapticFeedback();
                _showSymbolPopup(symbol);
              },
              onLongPress: () async {
                await AACHelper.accessibleHapticFeedback();
                _showEditSymbolDialog(symbol);
              },
              child: Container(
                decoration: BoxDecoration(
                  // Use solid white background with category color accent
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: categoryColor,
                    width: isHighContrast ? 4 : 3,
                  ),
                  boxShadow: isHighContrast ? [] : [
                    BoxShadow(
                      color: categoryColor.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: symbol.imagePath.startsWith('emoji:')
                              ? Container(
                                  decoration: BoxDecoration(
                                    color: categoryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      symbol.imagePath.substring(6), // Remove 'emoji:' prefix
                                      style: const TextStyle(fontSize: 48),
                                    ),
                                  ),
                                )
                              : symbol.imagePath.startsWith('assets/')
                                  ? Image.asset(
                                      symbol.imagePath,
                                      fit: BoxFit.contain,
                                      semanticLabel: symbol.label,
                                      errorBuilder: (context, error, stackTrace) {
                                        return _buildErrorIcon();
                                      },
                                    )
                                  : Image.file(
                                      File(symbol.imagePath),
                                      fit: BoxFit.contain,
                                      semanticLabel: symbol.label,
                                      errorBuilder: (context, error, stackTrace) {
                                        return _buildErrorIcon();
                                      },
                                    ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          // Use solid category color for text background
                          color: categoryColor,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(17),
                            bottomRight: Radius.circular(17),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            symbol.label,
                            style: TextStyle(
                              fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: const Offset(0.5, 0.5),
                                  blurRadius: 1,
                                  color: Colors.black.withOpacity(0.3),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
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
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: GestureDetector(
                onTap: () {}, // Prevent tap from propagating
                child: _SymbolMaximizedView(symbol: symbol),
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
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

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
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _bounceController,
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
    
    return Container(
      margin: const EdgeInsets.all(40),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with category color
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: categoryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Text(
                  widget.symbol.category,
                  style: TextStyle(
                    fontSize: 16 * AACHelper.getTextSizeMultiplier(),
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.symbol.label,
                  style: TextStyle(
                    fontSize: 28 * AACHelper.getTextSizeMultiplier(),
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Symbol image with pulse animation
          Padding(
            padding: const EdgeInsets.all(40),
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 250,
                    height: 250,
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
                                style: const TextStyle(fontSize: 120),
                              ),
                            )
                          : widget.symbol.imagePath.startsWith('assets/')
                              ? Image.asset(
                                  widget.symbol.imagePath,
                                  fit: BoxFit.contain,
                                  semanticLabel: widget.symbol.label,
                                )
                              : Image.file(
                                  File(widget.symbol.imagePath),
                                  fit: BoxFit.contain,
                                  semanticLabel: widget.symbol.label,
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
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                widget.symbol.description!,
                style: TextStyle(
                  fontSize: 18 * AACHelper.getTextSizeMultiplier(),
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          
          const SizedBox(height: 30),
          
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: CupertinoIcons.speaker_3_fill,
                label: 'Speak Again',
                color: categoryColor,
                onTap: () async {
                  _bounceController.forward().then((_) {
                    _bounceController.reverse();
                  });
                  await AACHelper.accessibleHapticFeedback();
                  await AACHelper.speak(widget.symbol.label);
                },
              ),
              _buildActionButton(
                icon: CupertinoIcons.xmark_circle_fill,
                label: 'Close',
                color: Colors.grey[600]!,
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _bounceAnimation.value,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12 * AACHelper.getTextSizeMultiplier(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bounceController.dispose();
    super.dispose();
  }
}