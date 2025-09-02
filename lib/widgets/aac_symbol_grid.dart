import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AACSymbolGrid extends StatefulWidget {
  final List<Map<String, dynamic>> symbols;
  final Function(String text, String emoji) onSymbolTap;
  final Color accentColor;

  const AACSymbolGrid({
    super.key,
    required this.symbols,
    required this.onSymbolTap,
    required this.accentColor,
  });

  @override
  State<AACSymbolGrid> createState() => _AACSymbolGridState();
}

class _AACSymbolGridState extends State<AACSymbolGrid>
    with TickerProviderStateMixin {
  
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.symbols.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      ),
    );
    
    _scaleAnimations = _controllers.map((controller) =>
      Tween<double>(begin: 1.0, end: 0.95).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      ),
    ).toList();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleSymbolTap(int index) {
    final symbol = widget.symbols[index];
    
    // Animate the button press
    _controllers[index].forward().then((_) {
      _controllers[index].reverse();
    });
    
    // Call the callback
    widget.onSymbolTap(symbol['text'], symbol['image']);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        final screenWidth = constraints.maxWidth;
        
        // Dynamic column calculation for better space utilization
        int crossAxisCount;
        if (isLandscape) {
          // In landscape: Always show exactly 3 columns
          crossAxisCount = 3;
        } else {
          // In portrait: 2 columns for larger layout size
          crossAxisCount = 2;
        }

        // Adjust spacing and padding based on screen size
        final basePadding = isLandscape ? screenWidth * 0.02 : screenWidth * 0.03;
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
          itemCount: widget.symbols.length,
          itemBuilder: (context, index) {
            final symbol = widget.symbols[index];
            
            return ScaleTransition(
              scale: _scaleAnimations[index],
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _handleSymbolTap(index),
                child: LayoutBuilder(
                  builder: (context, cardConstraints) {
                    final cardWidth = cardConstraints.maxWidth;
                    final cardHeight = cardConstraints.maxHeight;
                    
                    // Calculate responsive sizes
                    final emojiSize = isLandscape ? cardWidth * 0.35 : cardWidth * 0.4;
                    final fontSize = isLandscape ? cardWidth * 0.08 : cardWidth * 0.09;
                    
                    return Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: widget.accentColor.withOpacity(0.3),
                          width: 3,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Large symbol/emoji - responsive size
                          Text(
                            symbol['image'],
                            style: TextStyle(fontSize: emojiSize.clamp(24, 48)),
                          ),
                          SizedBox(height: cardHeight * 0.08),
                          
                          // Text label - responsive size
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: cardWidth * 0.1),
                            child: Text(
                              symbol['text'],
                              style: TextStyle(
                                fontSize: fontSize.clamp(10, 14),
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
