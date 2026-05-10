import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

class LevelUpSequence {
  /// Show level-up animation if newLevel > previousLevel.
  /// [level] is the numeric level field from LearningProgress.
  static void showIfChanged(
    BuildContext context, {
    required int newLevel,
    int? previousLevel,
  }) {
    if (previousLevel == null) return; // first observation, no prior baseline
    if (newLevel <= previousLevel) return; // ignore demotions or no-change

    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black54,
        pageBuilder: (_, __, ___) =>
            _LevelUpOverlay(newLevel: newLevel),
      ),
    );
  }
}

class _LevelUpOverlay extends StatefulWidget {
  final int newLevel;
  const _LevelUpOverlay({required this.newLevel});

  @override
  State<_LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<_LevelUpOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _rotation;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scale = Tween<double>(begin: 0, end: 1)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_controller);
    _rotation = Tween<double>(begin: 0, end: 6.28) // 2*pi
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _glow = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 30),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
    ]).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () => Navigator.of(context, rootNavigator: true).pop(),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => Transform.scale(
              scale: _scale.value,
              child: Container(
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFFB388FF),
                      Color(0xFF7C4DFF),
                      Color(0xFF651FFF),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurpleAccent
                          .withValues(alpha: 0.6 * _glow.value),
                      blurRadius: 60,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.rotate(
                      angle: _rotation.value,
                      child: const Icon(
                        Icons.star,
                        size: 80,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.learningLevelUp,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(blurRadius: 6, color: Colors.black54),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.learningLevelReached(widget.newLevel.toString()),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
