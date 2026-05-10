import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

/// Animated achievement unlock dialog.
/// Shows an elastic scale-in overlay when a new achievement is unlocked.
class AchievementUnlockOverlay {
  static Future<void> show(
    BuildContext context, {
    required String name,
    required String description,
    IconData fallbackIcon = Icons.emoji_events,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _UnlockDialog(
        name: name,
        description: description,
        fallbackIcon: fallbackIcon,
      ),
    );
  }
}

class _UnlockDialog extends StatefulWidget {
  final String name;
  final String description;
  final IconData fallbackIcon;

  const _UnlockDialog({
    required this.name,
    required this.description,
    required this.fallbackIcon,
  });

  @override
  State<_UnlockDialog> createState() => _UnlockDialogState();
}

class _UnlockDialogState extends State<_UnlockDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ScaleTransition(
      scale: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
      child: AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        title: Center(
          child: Text(
            l10n.learningAchievementUnlocked,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.5),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Icon(widget.fallbackIcon, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              widget.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.description,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.learningCommonContinue),
            ),
          ),
        ],
      ),
    );
  }
}
