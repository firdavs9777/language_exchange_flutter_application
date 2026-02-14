import 'package:flutter/material.dart';

/// A widget that wraps an avatar with a golden VIP frame
/// Only shows the frame when [isVip] is true
class VipAvatarFrame extends StatelessWidget {
  final Widget child;
  final bool isVip;
  final double size;
  final double frameWidth;
  final bool showGlow;

  const VipAvatarFrame({
    super.key,
    required this.child,
    required this.isVip,
    this.size = 56,
    this.frameWidth = 3,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVip) return child;

    return Container(
      width: size + (frameWidth * 2),
      height: size + (frameWidth * 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFD700), // Gold
            Color(0xFFFFA500), // Orange
            Color(0xFFFFD700), // Gold
            Color(0xFFFFE55C), // Light gold
            Color(0xFFFFD700), // Gold
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: const Color(0xFFFFA500).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
      padding: EdgeInsets.all(frameWidth),
      child: ClipOval(child: child),
    );
  }
}

/// A compact VIP frame for smaller avatars (like in lists)
class VipAvatarFrameCompact extends StatelessWidget {
  final Widget child;
  final bool isVip;
  final double size;

  const VipAvatarFrameCompact({
    super.key,
    required this.child,
    required this.isVip,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVip) return child;

    return Container(
      width: size + 4,
      height: size + 4,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.4),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: ClipOval(child: child),
    );
  }
}
