import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  @override
  void initState() {
    super.initState();
    final tab = context.findAncestorWidgetOfExactType<TabReselectScrollToTop>()?.tab;
    // Not inside a tab wrapper (a pushed route): opening it is opening it.
    if (tab == null || ref.read(selectedTabProvider) == tab) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _log());
    }
    if (tab != null) {
      ref.listenManual<int>(selectedTabProvider, (previous, next) {
        if (next == tab && previous != tab) _log();
      });
    }
  }

  void _log() {
    if (!mounted) return;
    // Reading the pack provider can start a fetch; with events off the tab
    // must send nothing new.
    final language = ref.read(studyEventsEnabledProvider)
        ? ref.read(dailyPackProvider).valueOrNull?.language
        : null;
    studyLog(StudyEvent.tabOpened, language: language);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
