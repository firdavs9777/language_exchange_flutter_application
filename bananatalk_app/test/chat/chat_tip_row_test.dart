import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/chat/message/chat_tip_row.dart';
import 'package:bananatalk_app/services/analytics_service.dart';
import 'package:bananatalk_app/services/guide_store.dart';

const _tip = 'Long-press to translate or correct';

Widget _wrap(List<Widget> children, {bool guidePeriod = true}) => ProviderScope(
      overrides: [isGuidePeriodProvider.overrideWith((ref) async => guidePeriod)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Column(children: children)),
      ),
    );

void main() {
  final events = <(String, Map<String, Object>)>[];
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    events.clear();
    AnalyticsService.debugLogSink = (n, p) => events.add((n, p));
  });
  tearDown(() => AnalyticsService.debugLogSink = null);

  testWidgets('one bubble per run shows it, and it logs guide_shown',
      (tester) async {
    await tester.pumpWidget(_wrap(const [
      ChatTipRow(messageId: 'a'),
      ChatTipRow(messageId: 'b'),
    ]));
    await tester.pumpAndSettle();
    expect(find.text(_tip), findsOneWidget);
    expect(
        events.where((e) => e.$1 == 'guide_shown' && e.$2['surface'] == 'chat_tip'),
        hasLength(1));
  });

  testWidgets('outside the guide period nothing shows', (tester) async {
    await tester.pumpWidget(
        _wrap(const [ChatTipRow(messageId: 'a')], guidePeriod: false));
    await tester.pumpAndSettle();
    expect(find.text(_tip), findsNothing);
  });

  testWidgets('already retired: nothing shows', (tester) async {
    SharedPreferences.setMockInitialValues({'guide_acted_chat_tip': true});
    await tester.pumpWidget(_wrap(const [ChatTipRow(messageId: 'a')]));
    await tester.pumpAndSettle();
    expect(find.text(_tip), findsNothing);
  });

  testWidgets('a failed user load shows nothing (fail closed)', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        isGuidePeriodProvider
            .overrideWith((ref) async => throw StateError('user load failed')),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ChatTipRow(messageId: 'a')),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text(_tip), findsNothing);
    expect(events.where((e) => e.$1 == 'guide_shown'), isEmpty);
  });

  testWidgets('✕ retires it for good and logs target dismiss', (tester) async {
    await tester.pumpWidget(_wrap(const [ChatTipRow(messageId: 'a')]));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat_tip_dismiss')));
    await tester.pumpAndSettle();
    expect(find.text(_tip), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(GuideSurface.chatTip.actedKey), isTrue);
    expect(events.where((e) => e.$1 == 'guide_cta_tapped').single.$2,
        {'surface': 'chat_tip', 'target': 'dismiss'});
  });

  testWidgets('a long-press anywhere retires it with target primary',
      (tester) async {
    await tester.pumpWidget(_wrap([
      const ChatTipRow(messageId: 'a'),
      Consumer(
        builder: (_, ref, __) => TextButton(
          onPressed: () => retireChatTip(ref, target: 'primary'),
          child: const Text('long-press'),
        ),
      ),
    ]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('long-press'));
    await tester.pumpAndSettle();
    expect(find.text(_tip), findsNothing);
    expect(events.where((e) => e.$1 == 'guide_cta_tapped').single.$2,
        {'surface': 'chat_tip', 'target': 'primary'});
  });

  test('message_bubble mounts the tip and retires it on the context menu', () {
    // every_tab_has_a_guide_test skips chatTip (not a tab); this is the
    // assertion that the skip is not a blind spot.
    final src =
        File('lib/pages/chat/message/message_bubble.dart').readAsStringSync();
    expect(src, contains('ChatTipRow(messageId: widget.message.id)'));
    expect(src, contains("retireChatTip(ref, target: 'primary')"));
    final tip =
        File('lib/pages/chat/message/chat_tip_row.dart').readAsStringSync();
    expect(tip, contains('GuideSurface.chatTip'));
  });
}
