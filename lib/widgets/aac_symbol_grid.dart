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
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: widget.symbols.length,
      itemBuilder: (context, index) {
        final symbol = widget.symbols[index];
        
        return ScaleTransition(
          scale: _scaleAnimations[index],
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _handleSymbolTap(index),
            child: Container(
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
                  // Large symbol/emoji
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: widget.accentColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        symbol['image'],
                        style: const TextStyle(
                          fontSize: 32,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Text label with better formatting
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      symbol['text'],
                      style: const TextStyle(
                        fontSize: 14,
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
            ),
          ),
        );
      },
    );
  }
}
