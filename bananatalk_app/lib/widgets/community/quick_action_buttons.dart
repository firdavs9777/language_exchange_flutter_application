import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Quick action buttons for community interactions
class QuickActionButtons extends StatelessWidget {
  final VoidCallback? onWave;
  final VoidCallback? onMessage;
  final VoidCallback? onCall;
  final VoidCallback? onSkip;
  final bool showSkip;
  final bool showCall;
  final bool compact;

  const QuickActionButtons({
    super.key,
    this.onWave,
    this.onMessage,
    this.onCall,
    this.onSkip,
    this.showSkip = false,
    this.showCall = false, // Disabled for now - TODO: Re-enable when call feature is ready
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CompactActionButton(
            icon: Icons.waving_hand_rounded,
            color: const Color(0xFFFFB74D),
            onTap: onWave,
            tooltip: 'Wave',
          ),
          const SizedBox(width: 8),
          _CompactActionButton(
            icon: Icons.chat_bubble_rounded,
            color: const Color(0xFF00BFA5),
            onTap: onMessage,
            tooltip: 'Message',
          ),
          if (showCall) ...[
            const SizedBox(width: 8),
            _CompactActionButton(
              icon: Icons.call_rounded,
              color: const Color(0xFF42A5F5),
              onTap: onCall,
              tooltip: 'Call',
            ),
          ],
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showSkip)
          _ActionButton(
            icon: Icons.close_rounded,
            color: Colors.grey[400]!,
            backgroundColor: Colors.grey[100]!,
            onTap: onSkip,
            size: 56,
            iconSize: 28,
            tooltip: 'Skip',
          ),
        if (showSkip) const SizedBox(width: 16),
        _ActionButton(
          icon: Icons.waving_hand_rounded,
          color: const Color(0xFFFFB74D),
          backgroundColor: const Color(0xFFFFB74D).withOpacity(0.15),
          onTap: onWave,
          size: 64,
          iconSize: 32,
          tooltip: 'Wave',
        ),
        const SizedBox(width: 16),
        _ActionButton(
          icon: Icons.chat_bubble_rounded,
          color: const Color(0xFF00BFA5),
          backgroundColor: const Color(0xFF00BFA5).withOpacity(0.15),
          onTap: onMessage,
          size: 72,
          iconSize: 36,
          isPrimary: true,
          tooltip: 'Message',
        ),
        if (showCall) ...[
          const SizedBox(width: 16),
          _ActionButton(
            icon: Icons.call_rounded,
            color: const Color(0xFF42A5F5),
            backgroundColor: const Color(0xFF42A5F5).withOpacity(0.15),
            onTap: onCall,
            size: 64,
            iconSize: 32,
            tooltip: 'Call',
          ),
        ],
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final bool isPrimary;
  final String tooltip;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    this.onTap,
    required this.size,
    required this.iconSize,
    this.isPrimary = false,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap?.call();
          },
          borderRadius: BorderRadius.circular(size / 2),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isPrimary ? color : backgroundColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(isPrimary ? 0.4 : 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: isPrimary ? Colors.white : color,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final String tooltip;

  const _CompactActionButton({
    required this.icon,
    required this.color,
    this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap?.call();
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

/// Wave button with animation
class WaveButton extends StatefulWidget {
  final VoidCallback? onTap;
  final bool compact;

  const WaveButton({
    super.key,
    this.onTap,
    this.compact = false,
  });

  @override
  State<WaveButton> createState() => _WaveButtonState();
}

class _WaveButtonState extends State<WaveButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  bool _isWaving = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (_isWaving) return;

    setState(() => _isWaving = true);
    HapticFeedback.mediumImpact();
    _controller.forward().then((_) {
      _controller.reverse().then((_) {
        setState(() => _isWaving = false);
      });
    });

    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.compact ? 40.0 : 50.0;
    final iconSize = widget.compact ? 20.0 : 24.0;

    return RotationTransition(
      turns: _rotationAnimation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(size / 2),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00BFA5), Color(0xFF00ACC1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(size / 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00BFA5).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.waving_hand_rounded,
              color: Colors.white,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}
