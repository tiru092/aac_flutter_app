import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MessageBuilder extends StatefulWidget {
  final List<String> messageItems;
  final VoidCallback? onSpeak;
  final VoidCallback? onClear;
  final Color accentColor;

  const MessageBuilder({
    super.key,
    required this.messageItems,
    this.onSpeak,
    this.onClear,
    required this.accentColor,
  });

  @override
  State<MessageBuilder> createState() => _MessageBuilderState();
}

class _MessageBuilderState extends State<MessageBuilder>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Start pulsing animation when there are items
    if (widget.messageItems.isNotEmpty) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(MessageBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Control animation based on message content
    if (widget.messageItems.isNotEmpty && oldWidget.messageItems.isEmpty) {
      _animationController.repeat(reverse: true);
    } else if (widget.messageItems.isEmpty && oldWidget.messageItems.isNotEmpty) {
      _animationController.stop();
      _animationController.reset();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.accentColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.chat_bubble_text,
                  color: widget.accentColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'My Message Builder',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.accentColor,
                  ),
                ),
                const Spacer(),
                if (widget.messageItems.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.accentColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.messageItems.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Message Display Area
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 80),
            padding: const EdgeInsets.all(16),
            child: widget.messageItems.isEmpty
                ? _buildEmptyState()
                : _buildMessageDisplay(),
          ),
          
          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Speak Button
                Expanded(
                  child: ScaleTransition(
                    scale: _pulseAnimation,
                    child: CupertinoButton(
                      color: widget.messageItems.isEmpty 
                          ? Colors.grey.withOpacity(0.5)
                          : widget.accentColor,
                      onPressed: widget.messageItems.isEmpty 
                          ? null 
                          : () {
                              widget.onSpeak?.call();
                              _showSpeakingAnimation();
                            },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.speaker_2_fill,
                            size: 24,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'SPEAK',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Clear Button
                CupertinoButton(
                  color: Colors.red.withOpacity(0.8),
                  onPressed: widget.messageItems.isEmpty ? null : widget.onClear,
                  child: const Icon(
                    CupertinoIcons.clear_circled_solid,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(
            CupertinoIcons.hand_raised,
            size: 40,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Tap symbols below to build your message!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageDisplay() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.messageItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        
        return GestureDetector(
          onTap: () => _removeMessageItem(index),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: widget.accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.accentColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.accentColor,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  CupertinoIcons.xmark_circle_fill,
                  size: 16,
                  color: widget.accentColor.withOpacity(0.6),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _removeMessageItem(int index) {
    // This would need to be handled by the parent widget
    // For now, just show a visual indication
    setState(() {
      // Parent widget should handle actual removal
    });
  }

  void _showSpeakingAnimation() {
    // Add speaking animation feedback
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    
    // Show snackbar with speaking indication
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              CupertinoIcons.speaker_2_fill,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            const Text(
              'Speaking your message...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
        backgroundColor: widget.accentColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
