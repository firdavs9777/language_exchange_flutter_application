import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/pages/community/first_session/first_session_store.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/services/analytics_service.dart';

/// The four first-week actions that count as a real start (spec §3.1).
/// Recorded when they HAPPEN — a send that succeeded, a moment the server
/// created — never on a button tap.
enum ActivationAction {
  message('message'),
  moment('moment'),
  lesson('lesson'),
  profile('profile');

  const ActivationAction(this.slug);

  /// Reported to analytics and part of the pref key. Append-only.
  final String slug;

  String get prefKey => 'activation_done_$slug';
}

/// Local record of which [ActivationAction]s this user has done.
///
/// User-scoped: the keys are not device-level, so `clearUserSessionPrefs`
/// removes them on logout / account switch. Reads fail closed (an unreadable
/// store reports everything done, i.e. show no guide), like `GuideStore`.
class ActivationStore {
  static final StreamController<void> _changes =
      StreamController<void>.broadcast();

  /// Fires after an action is newly recorded.
  static Stream<void> get changes => _changes.stream;

  /// Records [action]. Returns whether it was newly set; a new set logs
  /// `activation_milestone`. Never throws.
  Future<bool> markDone(ActivationAction action) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _backfill(prefs);
      if (_read(prefs, action.prefKey)) return false;
      // setBool updates the in-memory cache synchronously, so a concurrent
      // markDone resuming after this line already sees it done.
      final write = prefs.setBool(action.prefKey, true);
      AnalyticsService.instance
          .logActivationMilestone(action.slug, _count(prefs));
      _changes.add(null);
      await write;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isDone(ActivationAction action) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _backfill(prefs);
      return _read(prefs, action.prefKey);
    } catch (_) {
      return true;
    }
  }

  Future<int> doneCount() async => (await doneSet()).length;

  Future<Set<ActivationAction>> doneSet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _backfill(prefs);
      return {
        for (final a in ActivationAction.values)
          if (_read(prefs, a.prefKey)) a,
      };
    } catch (_) {
      return ActivationAction.values.toSet();
    }
  }

  static int _count(SharedPreferences prefs) =>
      ActivationAction.values.where((a) => _read(prefs, a.prefKey)).length;

  static bool _read(SharedPreferences prefs, String key) {
    try {
      return prefs.getBool(key) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Someone who messaged before this store existed has already done it.
  /// Silent: a back-fill is not a milestone reached today.
  static void _backfill(SharedPreferences prefs) {
    final key = ActivationAction.message.prefKey;
    if (!_read(prefs, key) && _read(prefs, kPrefHasMessaged)) {
      prefs.setBool(key, true).ignore();
    }
  }
}

/// The completeness rule the Profile guide has always used: a photo AND a
/// line of bio (OAuth signups arrive with a photo already).
bool isProfileComplete(Community user) =>
    user.effectiveImageUrls.isNotEmpty && user.bio.trim().isNotEmpty;

Future<void> checkProfileComplete(Community user,
    {ActivationStore? store}) async {
  if (!isProfileComplete(user)) return;
  await (store ?? ActivationStore()).markDone(ActivationAction.profile);
}

final activationStoreProvider =
    Provider<ActivationStore>((ref) => ActivationStore());

/// Live set of done actions: re-emits whenever [ActivationStore.markDone]
/// records something, so a guide retires on the action rather than on the
/// next app run.
final activationDoneProvider = StreamProvider<Set<ActivationAction>>((ref) {
  final store = ref.watch(activationStoreProvider);
  final out = StreamController<Set<ActivationAction>>();
  void emit() => store.doneSet().then((s) {
        if (!out.isClosed) out.add(s);
      });
  final sub = ActivationStore.changes.listen((_) => emit());
  emit();
  ref.onDispose(() {
    sub.cancel();
    out.close();
  });
  return out.stream;
});
