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

  testWidgets('one bubble per run shows it, and it logs guide_shown', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const [ChatTipRow(messageId: 'a'), ChatTipRow(messageId: 'b')]),
    );
    await tester.pumpAndSettle();
    expect(find.text(_tip), findsOneWidget);
    expect(
      events.where(
        (e) => e.$1 == 'guide_shown' && e.$2['surface'] == 'chat_tip',
      ),
      hasLength(1),
    );
  });

  testWidgets('outside the guide period nothing shows', (tester) async {
    await tester.pumpWidget(
      _wrap(const [ChatTipRow(messageId: 'a')], guidePeriod: false),
    );
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
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isGuidePeriodProvider.overrideWith(
            (ref) async => throw StateError('user load failed'),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: ChatTipRow(messageId: 'a')),
        ),
      ),
    );
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
    expect(events.where((e) => e.$1 == 'guide_cta_tapped').single.$2, {
      'surface': 'chat_tip',
      'target': 'dismiss',
    });
  });

  testWidgets('a long-press anywhere retires it with target primary', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap([
        const ChatTipRow(messageId: 'a'),
        Consumer(
          builder: (_, ref, __) => TextButton(
            onPressed: () => retireChatTip(ref, target: 'primary'),
            child: const Text('long-press'),
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('long-press'));
    await tester.pumpAndSettle();
    expect(find.text(_tip), findsNothing);
    expect(events.where((e) => e.$1 == 'guide_cta_tapped').single.$2, {
      'surface': 'chat_tip',
      'target': 'primary',
    });
  });

  test('message_bubble mounts the tip and retires it on the context menu', () {
    // every_tab_has_a_guide_test skips chatTip (not a tab); this is the
    // assertion that the skip is not a blind spot.
    final src = File(
      'lib/pages/chat/message/message_bubble.dart',
    ).readAsStringSync();
    expect(src, contains('messageId: widget.message.id'));
    expect(src, contains("retireChatTip(ref, target: 'primary')"));
    final tip = File(
      'lib/pages/chat/message/chat_tip_row.dart',
    ).readAsStringSync();
    expect(tip, contains('GuideSurface.chatTip'));
  });

  testWidgets('a different conversation takes the claim over', (tester) async {
    await tester.pumpWidget(
      _wrap(const [
        ChatTipRow(messageId: 'a', chatId: 'chat1'),
        ChatTipRow(messageId: 'b', chatId: 'chat1'),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.text(_tip), findsOneWidget);
    // Open another chat: its first message takes the tip.
    await tester.pumpWidget(
      _wrap(const [
        ChatTipRow(messageId: 'c', chatId: 'chat2'),
        ChatTipRow(messageId: 'd', chatId: 'chat2'),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.text(_tip), findsOneWidget);
    expect(events.where((e) => e.$1 == 'guide_shown'), hasLength(1));
  });

  testWidgets('claimant disposed before shown releases the claim', (
    tester,
  ) async {
    late ChatTipClaim claim;
    final show = ValueNotifier(true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [isGuidePeriodProvider.overrideWith((ref) async => true)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Consumer(
              builder: (_, ref, __) {
                claim = ref.read(chatTipClaimProvider);
                return ValueListenableBuilder<bool>(
                  valueListenable: show,
                  builder: (_, v, __) => Column(
                    children: [
                      if (v)
                        const ChatTipRow(
                          key: ValueKey('a'),
                          messageId: 'a',
                          chatId: 'c',
                        ),
                      const ChatTipRow(
                        key: ValueKey('b'),
                        messageId: 'b',
                        chatId: 'c',
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    // Providers still loading: the claim is not taken yet; take it by hand
    // to model "built, then scrolled away before the shown record".
    claim.claim('c', 'a');
    expect(claim.shown, isFalse);
    show.value = false;
    await tester.pump();
    expect(claim.messageId, isNull);
    expect(claim.chatId, isNull);
    await tester.pumpAndSettle();
  });

  testWidgets('shown claim is kept when the claimant goes away', (
    tester,
  ) async {
    final claim = ChatTipClaim()..claim('c', 'a');
    claim.shown = true;
    claim.release('c', 'a');
    expect(claim.messageId, 'a');
  });

  testWidgets('past the guide period the run latch is set', (tester) async {
    await tester.pumpWidget(
      _wrap(const [ChatTipRow(messageId: 'a')], guidePeriod: false),
    );
    await tester.pumpAndSettle();
    final c = ProviderScope.containerOf(
      tester.element(find.byType(ChatTipRow)),
    );
    expect(c.read(chatTipClaimProvider).ineligible, isTrue);
  });

  testWidgets('double dismiss and dismiss then long-press log once', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap([
        const ChatTipRow(messageId: 'a'),
        Consumer(
          builder: (_, ref, __) => TextButton(
            onPressed: () => retireChatTip(ref, target: 'primary'),
            child: const Text('long-press'),
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();
    final x = find.byKey(const Key('chat_tip_dismiss'));
    final btn = tester.widget<InkResponse>(x);
    btn.onTap!();
    btn.onTap!();
    await tester.tap(find.text('long-press'));
    await tester.pumpAndSettle();
    expect(events.where((e) => e.$1 == 'guide_cta_tapped'), hasLength(1));
  });

  testWidgets('a long-press before any tip appeared does not retire it', (
    tester,
  ) async {
    late WidgetRef captured;
    await tester.pumpWidget(
      _wrap([
        Consumer(
          builder: (_, ref, __) {
            captured = ref;
            return const SizedBox();
          },
        ),
      ]),
    );
    await tester.pumpAndSettle();
    await retireChatTip(captured, target: 'primary');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(GuideSurface.chatTip.actedKey), isNull);
    expect(events.where((e) => e.$1 == 'guide_cta_tapped'), isEmpty);
  });

  testWidgets(
    'group room: rows from different senders share one claim, no flip',
    (tester) async {
      // Every row of a room carries the room id, whoever wrote the message.
      Widget rows() => _wrap(const [
        ChatTipRow(key: ValueKey('m1'), messageId: 'm1', chatId: 'room1'),
        ChatTipRow(key: ValueKey('m2'), messageId: 'm2', chatId: 'room1'),
        ChatTipRow(key: ValueKey('m3'), messageId: 'm3', chatId: 'room1'),
      ]);
      await tester.pumpWidget(rows());
      await tester.pumpAndSettle();
      expect(find.text(_tip), findsOneWidget);
      final c = ProviderScope.containerOf(
        tester.element(find.byType(ChatTipRow).first),
      );
      expect(c.read(chatTipClaimProvider).messageId, 'm1');
      for (var i = 0; i < 3; i++) {
        await tester.pumpWidget(rows());
        await tester.pumpAndSettle();
      }
      expect(find.text(_tip), findsOneWidget);
      expect(c.read(chatTipClaimProvider).messageId, 'm1');
    },
  );

  test('message list passes the room id in group mode, none means no tip', () {
    final list = File(
      'lib/pages/chat/message/messages_list.dart',
    ).readAsStringSync();
    expect(list, matches(RegExp(r'isGroup\s*\?\s*conversationId')));
    final room = File(
      'lib/pages/community/rooms/room_screen.dart',
    ).readAsStringSync();
    expect(room, contains('conversationId: _room.id'));
    final bubble = File(
      'lib/pages/chat/message/message_bubble.dart',
    ).readAsStringSync();
    expect(bubble, contains('if (widget.tipChatId != null)'));
  });
}
