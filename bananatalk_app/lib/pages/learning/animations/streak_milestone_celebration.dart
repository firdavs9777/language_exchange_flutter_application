import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

class StreakMilestoneCelebration {
  static const milestones = {7, 30, 100, 365};

  /// Call after streak update. If newStreak is a milestone AND wasn't
  /// already at that milestone, show celebration.
  static void showIfMilestone(
    BuildContext context, {
    required int newStreak,
    required int previousStreak,
  }) {
    if (!milestones.contains(newStreak)) return;
    if (previousStreak >= newStreak) return; // already crossed
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black54,
        pageBuilder: (_, __, ___) => _CelebrationOverlay(streak: newStreak),
      ),
    );
  }

  /// Force-show, ignoring milestone check. For debug/test.
  static void forceShow(BuildContext context, int streak) {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black54,
        pageBuilder: (_, __, ___) => _CelebrationOverlay(streak: streak),
      ),
    );
  }
}

class _CelebrationOverlay extends StatefulWidget {
  final int streak;
  const _CelebrationOverlay({required this.streak});

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _confettiController.play();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  String _milestoneLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (widget.streak) {
      7 => l10n.learningStreakMilestone7,
      30 => l10n.learningStreakMilestone30,
      100 => l10n.learningStreakMilestone100,
      365 => l10n.learningStreakMilestone365,
      _ => '${widget.streak}-day streak!',
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.04,
              numberOfParticles: 25,
              gravity: 0.3,
              colors: const [
                Colors.orange,
                Colors.red,
                Colors.yellow,
                Colors.amber,
                Colors.deepOrange,
              ],
            ),
          ),
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _scaleController,
              curve: Curves.elasticOut,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_fire_department,
                  size: 140,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                Text(
                  _milestoneLabel(context),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(blurRadius: 8, color: Colors.black54),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepOrange,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: Text(
                    l10n.learningCommonAwesome,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
