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
/// A candidate whose [LaunchCandidate.isDue] throws is skipped without
/// spending the budget. Once a candidate's [LaunchCandidate.show] starts, the
/// budget stays spent and the run ends, even if `show` throws (logged, never
/// crashes the launch): the dialog may already be on screen.
class LaunchModalCoordinator {
  const LaunchModalCoordinator(this.candidates);

  final List<LaunchCandidate> candidates;

  Future<void> run(
    BuildContext context, {
    required bool guidePeriod,
    required bool updateShown,
  }) async {
    if (updateShown) {
      // The update dialog was this launch's pop-up (spec §4.1).
      PopupBudget.tryConsume();
      return;
    }
    if (PopupBudget.spent) return;
    for (final candidate in candidates) {
      if (guidePeriod && !candidate.allowedForNewUsers) continue;
      bool due;
      try {
        due = await candidate.isDue();
      } catch (e) {
        debugPrint('LaunchModalCoordinator: ${candidate.id}.isDue failed: $e');
        due = false;
      }
      if (!due) continue;
      if (!context.mounted) return;
      if (!PopupBudget.tryConsume()) return;
      try {
        await candidate.show(context);
      } catch (e) {
        debugPrint('LaunchModalCoordinator: ${candidate.id}.show failed: $e');
      }
      return;
    }
  }
}
