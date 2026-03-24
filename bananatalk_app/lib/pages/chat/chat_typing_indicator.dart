import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'user_avatar.dart';

class ChatTypingIndicator extends StatefulWidget {
  final String userName;
  final String? userPicture;

  const ChatTypingIndicator({
    Key? key,
    required this.userName,
    this.userPicture,
  }) : super(key: key);

  @override
  State<ChatTypingIndicator> createState() => _ChatTypingIndicatorState();
}

class _ChatTypingIndicatorState extends State<ChatTypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _appearanceController;
  late Animation<double> _appearanceAnimation;

  late AnimationController _dotController1;
  late AnimationController _dotController2;
  late AnimationController _dotController3;

  @override
  void initState() {
    super.initState();

    // Appearance animation (slide in + fade)
    _appearanceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _appearanceAnimation = CurvedAnimation(
      parent: _appearanceController,
      curve: Curves.easeOutCubic,
    );

    // Dot animations with staggered start
    _dotController1 = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _dotController2 = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _dotController3 = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _appearanceController.forward();
    _startDotAnimations();
  }

  void _startDotAnimations() async {
    // Staggered start for dots
    _dotController1.repeat(reverse: true);

    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) _dotController2.repeat(reverse: true);

    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) _dotController3.repeat(reverse: true);
  }

  @override
  void dispose() {
    _appearanceController.dispose();
    _dotController1.dispose();
    _dotController2.dispose();
    _dotController3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _appearanceAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(_appearanceAnimation),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              UserAvatar(
                profilePicture: widget.userPicture,
                userName: widget.userName,
                radius: 18,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: context.containerColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildBouncingDot(_dotController1),
                    const SizedBox(width: 4),
                    _buildBouncingDot(_dotController2),
                    const SizedBox(width: 4),
                    _buildBouncingDot(_dotController3),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'typing',
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBouncingDot(AnimationController controller) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Bounce effect with scale and position
        final value = controller.value;
        final scale = 0.6 + (value * 0.4); // Scale from 0.6 to 1.0
        final yOffset = -4.0 * value; // Move up by 4px at peak

        return Transform.translate(
          offset: Offset(0, yOffset),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Color.lerp(
                  context.textHint,
                  context.textSecondary,
                  value,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Compact typing indicator for chat list
class CompactTypingIndicator extends StatefulWidget {
  const CompactTypingIndicator({Key? key}) : super(key: key);

  @override
  State<CompactTypingIndicator> createState() => _CompactTypingIndicatorState();
}

class _CompactTypingIndicatorState extends State<CompactTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'typing',
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(width: 4),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 2),
                _buildDot(0.2),
                const SizedBox(width: 2),
                _buildDot(0.4),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildDot(double delay) {
    final progress = (_controller.value + delay) % 1.0;
    final opacity = 0.3 + (0.7 * (progress < 0.5 ? progress * 2 : (1 - progress) * 2));

    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: context.textSecondary.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}
