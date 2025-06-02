import 'package:flutter/material.dart';
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
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          UserAvatar(
            profilePicture: widget.userPicture,
            userName: widget.userName,
            radius: 16,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'typing',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Row(
                      children: [
                        _buildDot(0),
                        const SizedBox(width: 3),
                        _buildDot(0.33),
                        const SizedBox(width: 3),
                        _buildDot(0.66),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(double delay) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final value = (_animationController.value - delay).clamp(0.0, 1.0);
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey[600]?.withOpacity(0.3 + (value * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
