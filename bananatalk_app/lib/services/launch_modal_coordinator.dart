import 'package:flutter/widgets.dart';

/// One unrequested pop-up per process (spec §4.1): whichever shows first —
/// update dialog, a launch candidate, or notification priming — spends it,
/// so two never stack.
class PopupBudget {
  PopupBudget._();

  static bool _spent = false;

  static bool get spent => _spent;

  /// True if the caller may show a pop-up now (and the budget is spent).
  /// Synchronous check-and-set: two callers can never both win.
  static bool tryConsume() {
    if (_spent) return false;
    _spent = true;
    return true;
  }

  /// Gives the budget back when a pop-up that consumed it failed to show.
  static void refund() => _spent = false;

  @visibleForTesting
  static void debugReset() => _spent = false;
}

/// One launch pop-up. [isDue] keeps the pop-up's own throttle.
abstract class LaunchCandidate {
  String get id;

  /// Whether a user inside the guide period may see it (update, ads notice).
  bool get allowedForNewUsers;

  Future<bool> isDue();

  Future<void> show(BuildContext context);
}

/// Shows the first due candidate in [candidates] order, or nothing.
/// A candidate whose [LaunchCandidate.isDue] or [LaunchCandidate.show] throws
/// is skipped without spending the budget; it never crashes the launch.
class LaunchModalCoordinator {
  const LaunchModalCoordinator(this.candidates);

  final List<LaunchCandidate> candidates;

  Future<void> run(
    BuildContext context, {
    required bool guidePeriod,
    required bool updateShown,
  }) async {
    if (updateShown || PopupBudget.spent) return;
    for (final candidate in candidates) {
      if (guidePeriod && !candidate.allowedForNewUsers) continue;
      bool due;
      try {
        due = await candidate.isDue();
      } catch (_) {
        due = false;
      }
      if (!due) continue;
      if (!context.mounted) return;
      if (!PopupBudget.tryConsume()) return;
      try {
        await candidate.show(context);
        return;
      } catch (_) {
        PopupBudget.refund();
        if (!context.mounted) return;
      }
    }
  }
}
