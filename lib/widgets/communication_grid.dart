import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/symbol.dart';
import '../utils/aac_helper.dart';

enum ViewType { categories, symbols }

class CommunicationGrid extends StatefulWidget {
  final List<Symbol> symbols;
  final List<Category> categories;
  final Function(Symbol) onSymbolTap;
  final Function(Category) onCategoryTap;
  final ViewType viewType;

  const CommunicationGrid({
    super.key,
    required this.symbols,
    required this.categories,
    required this.onSymbolTap,
    required this.onCategoryTap,
    required this.viewType,
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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AACHelper.isHighContrastEnabled
                      ? [Colors.black, Colors.white]
                      : [
                          Color(category.colorCode),
                          Color(category.colorCode).withOpacity(0.8),
                        ],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Color(category.colorCode).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
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
                        // Category icon/emoji
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
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
                            shadows: [
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
          itemCount: widget.symbols.length,
          itemBuilder: (context, index) {
            final symbol = widget.symbols[index];
            final delay = index * 0.05;
            
            return AnimatedBuilder(
              animation: _gridAnimationController,
              builder: (context, child) {
                final animationValue = Curves.easeOutBack.transform(
                  (_gridAnimation.value - delay).clamp(0.0, 1.0),
                );
                
                return Transform.scale(
                  scale: animationValue,
                  child: _buildSymbolCard(symbol, index),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSymbolCard(Symbol symbol, int index) {
    final colors = AACHelper.getAccessibleColors();
    final cardColor = colors[index % colors.length];

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
                await AACHelper.speak(symbol.label);
                await AACHelper.accessibleHapticFeedback();
                widget.onSymbolTap(symbol);
                _showSymbolPopup(symbol);
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AACHelper.isHighContrastEnabled
                        ? [Colors.white, Colors.black]
                        : [
                            Colors.white,
                            cardColor.withOpacity(0.15),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AACHelper.isHighContrastEnabled
                        ? Colors.black
                        : cardColor.withOpacity(0.4),
                    width: AACHelper.isHighContrastEnabled ? 4 : 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cardColor.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
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
                          child: symbol.imagePath.startsWith('assets/')
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
                          color: AACHelper.isHighContrastEnabled
                              ? Colors.black
                              : cardColor.withOpacity(0.1),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(25),
                            bottomRight: Radius.circular(25),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            symbol.label,
                            style: TextStyle(
                              fontSize: 16 * AACHelper.getTextSizeMultiplier(),
                              fontWeight: FontWeight.bold,
                              color: AACHelper.isHighContrastEnabled
                                  ? Colors.white
                                  : Colors.black87,
                              shadows: AACHelper.isHighContrastEnabled
                                  ? []
                                  : [
                                      Shadow(
                                        offset: const Offset(0.5, 0.5),
                                        blurRadius: 1,
                                        color: Colors.white,
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
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _SymbolPopup(symbol: symbol),
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

  @override
  void dispose() {
    _gridAnimationController.dispose();
    _pressAnimationController.dispose();
    super.dispose();
  }
}

class _SymbolPopup extends StatelessWidget {
  final Symbol symbol;

  const _SymbolPopup({required this.symbol});

  @override
  Widget build(BuildContext context) {
    return CupertinoPopupSurface(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 30),
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: symbol.imagePath.startsWith('assets/')
                    ? Image.asset(
                        symbol.imagePath,
                        fit: BoxFit.contain,
                      )
                    : Image.file(
                        File(symbol.imagePath),
                        fit: BoxFit.contain,
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              symbol.label,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (symbol.description != null) ...[
              const SizedBox(height: 12),
              Text(
                symbol.description!,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPopupButton(
                  icon: CupertinoIcons.speaker_2_fill,
                  label: 'Speak Again',
                  color: AACHelper.childFriendlyColors[2],
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    await AACHelper.speak(symbol.label);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            CupertinoButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Widget _buildPopupButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Semantics(
      label: label,
      button: true,
      enabled: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AACHelper.isHighContrastEnabled
                  ? [Colors.black, Colors.white]
                  : [color, color.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: AACHelper.isHighContrastEnabled
                ? Border.all(color: Colors.white, width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: AACHelper.isHighContrastEnabled
                    ? Colors.white
                    : Colors.white,
                size: 28,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: AACHelper.isHighContrastEnabled
                      ? Colors.white
                      : Colors.white,
                  fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}