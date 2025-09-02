import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class InteractiveActivityCard extends StatefulWidget {
  final String title;
  final String description;
  final String emoji;
  final Color color;
  final VoidCallback? onTap;
  final bool isSelected;
  final List<String> sampleSymbols;

  const InteractiveActivityCard({
    super.key,
    required this.title,
    required this.description,
    required this.emoji,
    required this.color,
    this.onTap,
    this.isSelected = false,
    this.sampleSymbols = const [],
  });

  @override
  State<InteractiveActivityCard> createState() => _InteractiveActivityCardState();
}

class _InteractiveActivityCardState extends State<InteractiveActivityCard>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: widget.isSelected ? widget.color : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.isSelected
                    ? widget.color.withOpacity(0.4)
                    : Colors.black.withOpacity(0.1),
                blurRadius: widget.isSelected ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: widget.color,
              width: widget.isSelected ? 3 : 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with emoji and title
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: widget.isSelected
                            ? Colors.white.withOpacity(0.2)
                            : widget.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          widget.emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: widget.isSelected ? Colors.white : widget.color,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Description
                Text(
                  widget.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.isSelected
                        ? Colors.white.withOpacity(0.9)
                        : Colors.grey[600],
                    height: 1.3,
                  ),
                ),
                
                if (widget.sampleSymbols.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  
                  // Sample symbols preview
                  Text(
                    'Sample symbols:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: widget.isSelected
                          ? Colors.white.withOpacity(0.8)
                          : Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.sampleSymbols.take(4).map((symbol) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.isSelected
                              ? Colors.white.withOpacity(0.2)
                              : widget.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          symbol,
                          style: TextStyle(
                            fontSize: 11,
                            color: widget.isSelected
                                ? Colors.white
                                : widget.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Action indicator
                Row(
                  children: [
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: widget.isSelected
                            ? Colors.white
                            : widget.color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.isSelected
                                ? CupertinoIcons.play_fill
                                : CupertinoIcons.hand_raised,
                            size: 14,
                            color: widget.isSelected
                                ? widget.color
                                : Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.isSelected ? 'ACTIVE' : 'TAP TO START',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: widget.isSelected
                                  ? widget.color
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
