import 'package:flutter/material.dart';

class StickerButton extends StatefulWidget {
  final String sticker;
  final VoidCallback onTap;

  const StickerButton({
    Key? key,
    required this.sticker,
    required this.onTap,
  }) : super(key: key);

  @override
  State<StickerButton> createState() => _StickerButtonState();
}

class _StickerButtonState extends State<StickerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
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

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: _isPressed ? Colors.grey[300] : Colors.grey[100],
                border: Border.all(
                  color: _isPressed ? Colors.grey[400]! : Colors.grey[200]!,
                  width: 1,
                ),
                boxShadow: _isPressed
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Center(
                child: Text(
                  widget.sticker,
                  style: const TextStyle(
                    fontSize: 24,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
