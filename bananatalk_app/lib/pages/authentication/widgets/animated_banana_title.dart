import 'package:flutter/material.dart';

/// Bananatalk logo text with a letter-by-letter stagger entry animation
/// followed by a continuous teal shimmer sweep.
///
/// [fontSize] defaults to 38 (login screen). Pass 54 for the splash screen.
class AnimatedBananaTitle extends StatefulWidget {
  final double fontSize;
  final Duration entryDuration;
  final Duration shimmerPeriod;

  const AnimatedBananaTitle({
    super.key,
    this.fontSize = 38,
    this.entryDuration = const Duration(milliseconds: 1100),
    this.shimmerPeriod = const Duration(milliseconds: 3600),
  });

  @override
  State<AnimatedBananaTitle> createState() => _AnimatedBananaTitleState();
}

class _AnimatedBananaTitleState extends State<AnimatedBananaTitle>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _shimmerCtrl;

  static const _text = 'Bananatalk';
  static const _n = _text.length;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: widget.entryDuration);
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

    _entryCtrl.forward().then((_) {
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _shimmerCtrl.repeat(period: widget.shimmerPeriod);
      });
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_entryCtrl, _shimmerCtrl]),
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_n, (i) {
            const stagger = 0.60 / _n;
            final start = i * stagger;
            final end = (start + 0.42).clamp(0.0, 1.0);
            final t = CurvedAnimation(
              parent: _entryCtrl,
              curve: Interval(start, end, curve: Curves.easeOutBack),
            ).value.clamp(0.0, 1.0);

            // Shimmer wave: brightness peak travels left→right
            final shimmerPos = _shimmerCtrl.value * (_n + 2) - 1;
            final dist = (i - shimmerPos).abs();
            final glow = (1.0 - (dist / 2.5).clamp(0.0, 1.0)) *
                (_entryCtrl.isCompleted ? 1.0 : 0.0);

            final color = Color.lerp(
              const Color(0xFF00BFA5),
              const Color(0xFF80FFE8),
              glow,
            )!;

            return Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, 22 * (1 - t)),
                child: Text(
                  _text[i],
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
