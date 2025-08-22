import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/symbol.dart';
import '../utils/aac_helper.dart';

class SentenceBar extends StatefulWidget {
  final List<Symbol> selectedSymbols;
  final Function(Symbol) onAddSymbol;
  final Function(int) onRemoveAt;
  final VoidCallback onClear;
  final VoidCallback onUndo;
  final VoidCallback onSpeak;

  const SentenceBar({
    super.key,
    required this.selectedSymbols,
    required this.onAddSymbol,
    required this.onRemoveAt,
    required this.onClear,
    required this.onUndo,
    required this.onSpeak,
  });

  @override
  State<SentenceBar> createState() => _SentenceBarState();
}

class _SentenceBarState extends State<SentenceBar>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _bounceController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
    
    _slideController.forward();
  }

  void _animateSymbolAdd() {
    _bounceController.forward().then((_) {
      _bounceController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6C63FF).withOpacity(0.1),
              const Color(0xFF4ECDC4).withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with title and action buttons
            _buildHeader(),
            // Symbol chips area
            _buildSymbolChipsArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C63FF),
            const Color(0xFF4ECDC4),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(23),
          topRight: Radius.circular(23),
        ),
      ),
      child: Row(
        children: [
          // Title
          const Icon(
            CupertinoIcons.chat_bubble_text_fill,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'My Sentence',
            style: TextStyle(
              fontSize: 18 * AACHelper.getTextSizeMultiplier(),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${widget.selectedSymbols.length}',
              style: TextStyle(
                fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // UNDO Button
        _buildActionButton(
          icon: CupertinoIcons.arrow_uturn_left_circle_fill,
          label: 'Undo',
          color: const Color(0xFFFFE66D),
          onTap: widget.selectedSymbols.isNotEmpty ? widget.onUndo : null,
        ),
        const SizedBox(width: 8),
        // CLEAR Button
        _buildActionButton(
          icon: CupertinoIcons.clear_thick_circled,
          label: 'Clear',
          color: const Color(0xFFFF6B6B),
          onTap: widget.selectedSymbols.isNotEmpty ? widget.onClear : null,
        ),
        const SizedBox(width: 8),
        // SPEAK Button
        _buildActionButton(
          icon: CupertinoIcons.speaker_2_fill,
          label: 'Speak',
          color: const Color(0xFF51CF66),
          onTap: widget.selectedSymbols.isNotEmpty ? widget.onSpeak : null,
          isPrimary: true,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
    bool isPrimary = false,
  }) {
    final isEnabled = onTap != null;
    
    return Semantics(
      label: label,
      button: true,
      enabled: isEnabled,
      child: GestureDetector(
        onTap: isEnabled ? () async {
          await AACHelper.accessibleHapticFeedback();
          onTap();
        } : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: isPrimary ? 16 : 12,
            vertical: isPrimary ? 10 : 8,
          ),
          decoration: BoxDecoration(
            color: isEnabled 
                ? color
                : Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(isPrimary ? 20 : 16),
            boxShadow: isEnabled ? [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ] : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isEnabled ? Colors.white : Colors.grey,
                size: isPrimary ? 20 : 18,
              ),
              if (isPrimary) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                    fontWeight: FontWeight.bold,
                    color: isEnabled ? Colors.white : Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSymbolChipsArea() {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 80,
        maxHeight: 120,
      ),
      padding: const EdgeInsets.all(16),
      child: widget.selectedSymbols.isEmpty
          ? _buildEmptyState()
          : _buildSymbolChips(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.add_circled,
            size: 40,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap symbols to build your sentence',
            style: TextStyle(
              fontSize: 16 * AACHelper.getTextSizeMultiplier(),
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymbolChips() {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _bounceAnimation.value,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: widget.selectedSymbols.asMap().entries.map((entry) {
                final index = entry.key;
                final symbol = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildSymbolChip(symbol, index),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSymbolChip(Symbol symbol, int index) {
    final colors = AACHelper.getAccessibleColors();
    final chipColor = colors[index % colors.length];
    
    return Semantics(
      label: 'Symbol: ${symbol.label}, position ${index + 1}, double tap to remove',
      button: true,
      child: GestureDetector(
        onTap: () async {
          await AACHelper.accessibleHapticFeedback();
          widget.onRemoveAt(index);
        },
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 60,
            maxWidth: 120,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                chipColor,
                chipColor.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: chipColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  symbol.label,
                  style: TextStyle(
                    fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.xmark,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _bounceController.dispose();
    super.dispose();
  }
}