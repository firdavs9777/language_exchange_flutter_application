import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

class XpGainOverlay {
  static OverlayEntry? _current;

  static void show(BuildContext context, int xp) {
    if (xp <= 0) return;
    final l10n = AppLocalizations.of(context)!;
    _current?.remove();
    final overlay = Overlay.of(context, rootOverlay: true);
    _current = OverlayEntry(
      builder: (_) => _XpGainAnimation(
        xp: xp,
        label: l10n.learningXpGained(xp),
        onComplete: () {
          _current?.remove();
          _current = null;
        },
      ),
    );
    overlay.insert(_current!);
  }
}

class _XpGainAnimation extends StatefulWidget {
  final int xp;
  final String label;
  final VoidCallback onComplete;

  const _XpGainAnimation({
    required this.xp,
    required this.label,
    required this.onComplete,
  });

  @override
  State<_XpGainAnimation> createState() => _XpGainAnimationState();
}

class _XpGainAnimationState extends State<_XpGainAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _scale = Tween<double>(begin: 0.5, end: 1.15)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_controller);
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 25),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 25),
    ]).animate(_controller);
    _offset = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1.2))
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward().whenComplete(widget.onComplete);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => Opacity(
              opacity: _opacity.value,
              child: SlideTransition(
                position: AlwaysStoppedAnimation(_offset.value),
                child: Transform.scale(
                  scale: _scale.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.45),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flash_on, color: Colors.white, size: 26),
                        const SizedBox(width: 8),
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
