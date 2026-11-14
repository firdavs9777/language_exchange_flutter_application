import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/menu_tab/TabBarMenu.dart' show selectedTabProvider;
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/provider_root/learning/daily_pack_providers.dart';
import 'package:bananatalk_app/services/study/study_tracker.dart';
import 'package:bananatalk_app/widgets/navigation/tab_reselect_scroll_to_top.dart';

/// Logs `tab_opened` each time the AI Study tab becomes the selected tab,
/// including the first time. Top-level tabs stay mounted while hidden, so the
/// selected tab (not mounting, not rebuilding) is the signal. Never logs from
/// build.
class StudyTabOpenedReporter extends ConsumerStatefulWidget {
  const StudyTabOpenedReporter({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<StudyTabOpenedReporter> createState() =>
      _StudyTabOpenedReporterState();
}

class _StudyTabOpenedReporterState extends ConsumerState<StudyTabOpenedReporter> {
  /// Null when not inside a tab wrapper (a pushed route).
  int? _tab;

  /// False until the first frame has settled. The tab bar seeds its initial
  /// tab (initialIndex / deep link) in a post-frame callback it registers in
  /// its own initState, which runs before this one is registered, so by the
  /// time ours runs the selection is final.
  bool _settled = false;

  /// A `tab_opened` has been logged (or is being held) for the current
  /// selection.
  bool _logged = false;

  /// How long a `tab_opened` waits for the pack's language on a cold start.
  static const _packWait = Duration(seconds: 3);

  /// While a `tab_opened` waits for the pack: the pack listener and the
  /// timer that gives up on it. Both go when it fires, when the tab is left
  /// and on dispose.
  ProviderSubscription<AsyncValue<DailyPack>>? _packSub;
  Timer? _packTimer;

  bool get _selected => _tab == null || ref.read(selectedTabProvider) == _tab;

  @override
  void initState() {
    super.initState();
    _tab = context.findAncestorWidgetOfExactType<TabReselectScrollToTop>()?.tab;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _settled = true;
      _maybeLog();
    });
    if (_tab != null) {
      ref.listenManual<int>(selectedTabProvider, (previous, next) {
        if (next == _tab && previous != _tab) {
          _logged = false;
          _maybeLog();
        } else if (next != _tab) {
          // Left before a held event fired: it is dropped.
          _cancelHeld();
          _logged = false;
        }
      });
    }
    // Config can arrive after the first frame: log once when the flag turns
    // on while this tab is still the selected one.
    ref.listenManual<bool>(studyEventsEnabledProvider, (previous, next) {
      if (next) _maybeLog();
    });
  }

  void _maybeLog() {
    if (!mounted || !_settled || _logged || !_selected) return;
    // The flag check also stops the pack read below from starting a fetch
    // while events are off.
    if (!ref.read(studyEventsEnabledProvider)) return;
    _logged = true;
    // The study tab is the default tab, so on a cold start this runs as soon
    // as app-config lands, usually before the pack: hold the event until the
    // pack has settled (data or error) or [_packWait] has passed, so it can
    // carry the pack's language. Never the profile's language.
    final pack = ref.read(dailyPackProvider);
    if (!_packSettled(pack)) {
      _packSub = ref.listenManual<AsyncValue<DailyPack>>(dailyPackProvider, (_, next) {
        if (_packSettled(next)) _fireHeld();
      });
      _packTimer = Timer(_packWait, _fireHeld);
      return;
    }
    studyLog(StudyEvent.tabOpened, language: pack.valueOrNull?.language);
  }

  static bool _packSettled(AsyncValue<DailyPack> pack) =>
      pack.hasValue || pack.hasError || !pack.isLoading;

  void _fireHeld() {
    _cancelHeld();
    if (!mounted || !_selected) return;
    studyLog(StudyEvent.tabOpened,
        language: ref.read(dailyPackProvider).valueOrNull?.language);
  }

  void _cancelHeld() {
    _packSub?.close();
    _packSub = null;
    _packTimer?.cancel();
    _packTimer = null;
  }

  @override
  void dispose() {
    _cancelHeld();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
