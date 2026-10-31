import 'package:bananatalk_app/pages/menu_tab/TabBarMenu.dart';
import 'package:bananatalk_app/pages/menu_tab/lazy_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every top-level page was built at launch, so Community's requests (list,
/// exclusions, visitors, waves badge, voice-rooms poll) fired on app start
/// even for people who never opened Community (audit 2026-10-30). LazyTab
/// builds its page the first time it is selected and keeps it afterwards.
class _Probe extends StatefulWidget {
  const _Probe();
  static int builds = 0;
  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    _Probe.builds++;
  }

  @override
  Widget build(BuildContext context) => const Text('community');
}

void main() {
  testWidgets('builds on first selection and stays built', (tester) async {
    _Probe.builds = 0;
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: LazyTab(index: 1, child: _Probe())),
    ));
    expect(_Probe.builds, 0);
    expect(find.text('community'), findsNothing);

    container.read(selectedTabProvider.notifier).state = 1;
    await tester.pump();
    expect(_Probe.builds, 1);

    container.read(selectedTabProvider.notifier).state = 0;
    await tester.pump();
    expect(find.text('community'), findsOneWidget);
    expect(_Probe.builds, 1);
  });
}
