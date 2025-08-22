import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/aac_helper.dart';

class PinInputDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final Function(String) onPinEntered;
  final VoidCallback? onCancel;
  final bool showForgotPin;

  const PinInputDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onPinEntered,
    this.onCancel,
    this.showForgotPin = false,
  });

  @override
  State<PinInputDialog> createState() => _PinInputDialogState();
}

class _PinInputDialogState extends State<PinInputDialog>
    with TickerProviderStateMixin {
  String _pin = '';
  bool _isShaking = false;
  late AnimationController _shakeController;
  late AnimationController _slideController;
  late Animation<double> _shakeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    _slideController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildPinDisplay(),
            _buildKeypad(),
            _buildActionButtons(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            CupertinoIcons.lock_fill,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 20 * AACHelper.getTextSizeMultiplier(),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.subtitle,
              style: TextStyle(
                fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPinDisplay() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: index < _pin.length 
                        ? const Color(0xFF6C63FF) 
                        : Colors.grey.shade300,
                    shape: BoxShape.circle,
                    boxShadow: index < _pin.length ? [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ] : null,
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          if (index == 9) {
            // Empty space
            return const SizedBox.shrink();
          } else if (index == 10) {
            // Zero
            return _buildKeypadButton('0');
          } else if (index == 11) {
            // Delete
            return _buildDeleteButton();
          } else {
            // Numbers 1-9
            return _buildKeypadButton('${index + 1}');
          }
        },
      ),
    );
  }

  Widget _buildKeypadButton(String number) {
    return Semantics(
      label: 'Number $number',
      button: true,
      child: GestureDetector(
        onTap: () => _onNumberPressed(number),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.grey.shade100,
                Colors.grey.shade50,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 24 * AACHelper.getTextSizeMultiplier(),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Semantics(
      label: 'Delete last digit',
      button: true,
      child: GestureDetector(
        onTap: _onDeletePressed,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.red.shade100,
                Colors.red.shade50,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.red.shade300,
              width: 1,
            ),
          ),
          child: const Center(
            child: Icon(
              CupertinoIcons.delete_left,
              size: 24,
              color: Colors.red,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: CupertinoButton(
              onPressed: widget.onCancel,
              color: Colors.grey.shade300,
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16 * AACHelper.getTextSizeMultiplier(),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (widget.showForgotPin) ...[
            const SizedBox(width: 12),
            Expanded(
              child: CupertinoButton(
                onPressed: _showForgotPinDialog,
                color: Colors.orange,
                child: Text(
                  'Forgot PIN?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _onNumberPressed(String number) async {
    if (_pin.length < 4) {
      setState(() {
        _pin += number;
      });
      
      await AACHelper.accessibleHapticFeedback();
      
      if (_pin.length == 4) {
        await Future.delayed(const Duration(milliseconds: 300));
        widget.onPinEntered(_pin);
      }
    }
  }

  void _onDeletePressed() async {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
      await AACHelper.accessibleHapticFeedback();
    }
  }

  void _showForgotPinDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Forgot PIN?'),
        content: const Text(
          'Please contact your caregiver or app administrator to reset your PIN.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void showErrorAnimation() {
    _shakeController.forward().then((_) {
      _shakeController.reverse().then((_) {
        setState(() {
          _pin = '';
        });
      });
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}